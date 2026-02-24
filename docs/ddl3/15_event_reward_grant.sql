-- =============================================================
-- [15] event_reward_grant
-- 역할  : 보상 지급 내역 - 출석·랜덤 이벤트 모두 이 테이블에 기록
--         외부 시스템(포인트 API, 쿠폰 API) 연동 재시도 상태 관리 포함
-- 관계  :
--   - event.id → event_reward_grant.event_id (1:N)
--   - event_log.id → event_reward_grant.event_log_id (1:1)
--   - event_reward_catalog.id → event_reward_grant.reward_catalog_id (N:1)
-- =============================================================
-- 예시 데이터
-- [출석 일일 보상]
-- id=1, event_id=1, event_type='ATTENDANCE', reward_kind='DAILY',   member_id=10001,
--        reward_type='POINT', point_amount=30, reward_status='SUCCESS', idempotency_key='att-1-10001-2026-03-05-DAILY'
--
-- [출석 보너스 보상]
-- id=2, event_id=1, event_type='ATTENDANCE', reward_kind='BONUS',   member_id=10001,
--        reward_type='COUPON', coupon_group_id=400, reward_status='SUCCESS', idempotency_key='att-1-10001-2026-03-07-BONUS'
--
-- [랜덤 당첨 보상]
-- id=3, event_id=2, event_type='RANDOM',     reward_kind='RANDOM',  member_id=10001,
--        reward_type='POINT', point_amount=100, reward_status='SUCCESS', idempotency_key='rand-2-10001-log-3'
-- =============================================================

CREATE TABLE event_platform.event_reward_grant (
    id                          BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·회원 식별
     * ========================= */
    event_id                    BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    event_type                  VARCHAR(20)     NOT NULL,       -- ATTENDANCE / RANDOM (조회 최적화 비정규화)
    member_id                   BIGINT          NOT NULL,       -- 보상 수령 회원 ID

    /* =========================
     * 행위 로그 참조 (1:1)
     * ========================= */
    event_log_id                BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event_log(id),                -- FK: event_log.id (1 로그 = 최대 1 보상지급)

    /* =========================
     * 보상 구분
     * ========================= */
    reward_kind                 VARCHAR(20)     NOT NULL,       -- DAILY(출석일일보상) / BONUS(출석보너스보상) / RANDOM(랜덤보상)

    /* =========================
     * 보상 카탈로그 참조 (선택)
     * ========================= */
    reward_catalog_id           BIGINT
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (선택)

    /* =========================
     * 보상 스냅샷 (지급 시점 기준 고정)
     * ========================= */
    reward_type                 VARCHAR(20)     NOT NULL,       -- POINT / COUPON / PRODUCT / NONE / ONEMORE
    point_amount                INTEGER,                        -- POINT 전용: 지급 포인트 수량 스냅샷
    coupon_group_id             BIGINT,                         -- COUPON 전용: 쿠폰 그룹 ID 스냅샷
    external_ref_id             BIGINT,                         -- PRODUCT 전용: 외부 상품 ID 스냅샷

    /* =========================
     * 지급 처리 상태
     * ========================= */
    reward_status               VARCHAR(20)     NOT NULL DEFAULT 'PENDING', -- PENDING / PROCESSING / SUCCESS / FAILED / CANCELLED
    retry_count                 INTEGER         NOT NULL DEFAULT 0, -- 외부 API 재시도 횟수
    next_retry_at               TIMESTAMP,                      -- 다음 재시도 예정 시각 (PENDING/FAILED 일 때만 사용)

    /* =========================
     * 외부 연동 추적
     * ========================= */
    idempotency_key             VARCHAR(120)    NOT NULL,       -- 외부 API 중복 호출 방지 키 (멱등성 보장)
    external_transaction_id     VARCHAR(120),                   -- 외부 포인트·쿠폰 시스템 트랜잭션 ID

    /* =========================
     * 오류 정보
     * ========================= */
    error_code                  VARCHAR(50),                    -- 오류 코드 (외부 API 응답 코드)
    error_message               TEXT,                           -- 오류 메시지 상세

    /* =========================
     * 처리 시각
     * ========================= */
    requested_at                TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 보상 지급 요청 일시
    processed_at                TIMESTAMP,                      -- 보상 지급 완료(또는 최종 실패) 일시

    /* =========================
     * 감사 정보
     * ========================= */
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_reward_grant_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX idx_reward_grant_event_member
    ON event_platform.event_reward_grant(event_id, member_id, created_at DESC);

CREATE INDEX idx_reward_grant_retry_queue
    ON event_platform.event_reward_grant(reward_status, next_retry_at)
    WHERE reward_status IN ('PENDING', 'FAILED');

COMMENT ON TABLE  event_platform.event_reward_grant IS '보상 지급 내역 - 출석·랜덤 이벤트 통합 (외부 API 재시도 상태 관리 포함)';
COMMENT ON COLUMN event_platform.event_reward_grant.event_id               IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_reward_grant.event_type             IS '이벤트 유형 ATTENDANCE/RANDOM (비정규화, 조회 최적화)';
COMMENT ON COLUMN event_platform.event_reward_grant.member_id              IS '보상 수령 회원 ID';
COMMENT ON COLUMN event_platform.event_reward_grant.event_log_id           IS 'FK: event_log.id - 1 로그 행위당 최대 1개 보상지급 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_grant.reward_kind            IS 'DAILY=출석 일일보상, BONUS=출석 보너스보상, RANDOM=랜덤 당첨보상';
COMMENT ON COLUMN event_platform.event_reward_grant.reward_catalog_id      IS 'FK: event_reward_catalog.id (선택)';
COMMENT ON COLUMN event_platform.event_reward_grant.reward_type            IS 'POINT / COUPON / PRODUCT / NONE / ONEMORE';
COMMENT ON COLUMN event_platform.event_reward_grant.point_amount           IS 'POINT 전용 지급 포인트 (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_grant.coupon_group_id        IS 'COUPON 전용 쿠폰 그룹 ID (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_grant.external_ref_id        IS 'PRODUCT 전용 외부 상품 ID (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_grant.reward_status          IS 'PENDING=대기, PROCESSING=처리중, SUCCESS=성공, FAILED=실패, CANCELLED=취소';
COMMENT ON COLUMN event_platform.event_reward_grant.retry_count            IS '외부 API 재시도 횟수';
COMMENT ON COLUMN event_platform.event_reward_grant.next_retry_at          IS '다음 재시도 예정 시각 (PENDING/FAILED 상태에서만 사용)';
COMMENT ON COLUMN event_platform.event_reward_grant.idempotency_key        IS '외부 API 중복 호출 방지 멱등성 키 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_grant.external_transaction_id IS '외부 포인트·쿠폰 시스템이 반환한 트랜잭션 ID';
COMMENT ON COLUMN event_platform.event_reward_grant.error_code             IS '외부 API 오류 코드';
COMMENT ON COLUMN event_platform.event_reward_grant.error_message          IS '외부 API 오류 메시지 상세';
COMMENT ON COLUMN event_platform.event_reward_grant.requested_at           IS '보상 지급 최초 요청 일시';
COMMENT ON COLUMN event_platform.event_reward_grant.processed_at           IS '보상 지급 완료 또는 최종 실패 처리 일시';
