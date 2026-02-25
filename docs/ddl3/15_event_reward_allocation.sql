-- =============================================================
-- [15] event_reward_allocation
-- 역할  : 보상 지급 의뢰 기록 (append-only)
--         "어떤 보상을 큐에 넣었다"는 사실 + 의뢰 시점 정책 스냅샷을 함께 기록
--         실제 지급 성공/실패 상태는 외부 Queue(SQS)에서 관리
-- 관계  :
--   - event.id                       → event_reward_allocation.event_id (1:N)
--   - event_entry.id                 → event_reward_allocation.event_entry_id (1:1)
--   - event_attendance_daily_reward  → daily_reward_id (DAILY 전용, FK 스냅샷)
--   - event_attendance_bonus_reward  → bonus_reward_id (BONUS 전용, FK 스냅샷)
--   - event_random_reward_pool       → reward_pool_id  (RANDOM 전용, FK 스냅샷)
-- =============================================================
-- 예시 데이터
--
-- [출석 일일 보상]
-- id=1, event_id=1, event_type='ATTENDANCE', reward_kind='DAILY', member_id=10001,
--        daily_reward_id=1,                               ← 어떤 일일 보상 정책이었는지
--        reward_type='POINT', point_amount=30,            ← 정책에서 복사한 스냅샷
--        idempotency_key='att-1-10001-2026-03-05-DAILY'
--
-- [출석 보너스 보상]
-- id=2, event_id=1, event_type='ATTENDANCE', reward_kind='BONUS', member_id=10001,
--        bonus_reward_id=2,                              ← 어떤 마일스톤 보너스 정책이었는지
--        milestone_type='TOTAL', milestone_count=7,      ← 트리거된 마일스톤 스냅샷
--        reward_type='COUPON', coupon_group_id=400,      ← 정책에서 복사한 스냅샷
--        idempotency_key='att-1-10001-2026-03-07-BONUS-7'
--
-- [랜덤 당첨 보상]
-- id=3, event_id=2, event_type='RANDOM', reward_kind='RANDOM', member_id=10001,
--        reward_pool_id=2,                               ← 어떤 확률 풀이었는지
--        probability_weight=25,                          ← 당시 가중치 스냅샷
--        reward_type='POINT', point_amount=100,          ← 정책에서 복사한 스냅샷
--        idempotency_key='rand-2-10001-entry-3'
-- =============================================================

CREATE TABLE event_platform.event_reward_allocation (
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
    event_entry_id              BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event_entry(id),             -- FK: event_entry.id (1 행위 = 최대 1 보상 의뢰)

    /* =========================
     * 보상 구분
     * ========================= */
    reward_kind                 VARCHAR(20)     NOT NULL,       -- DAILY / BONUS / RANDOM

    /* -------------------------------------------------------
     * [DAILY 전용] 일일 보상 정책 참조
     * ------------------------------------------------------- */
    daily_reward_id             BIGINT
        REFERENCES event_platform.event_attendance_daily_reward(id),
        -- FK: event_attendance_daily_reward.id (DAILY일 때만 NOT NULL)

    /* -------------------------------------------------------
     * [BONUS 전용] 보너스 보상 정책 참조 + 마일스톤 스냅샷
     * ------------------------------------------------------- */
    bonus_reward_id             BIGINT
        REFERENCES event_platform.event_attendance_bonus_reward(id),
        -- FK: event_attendance_bonus_reward.id (BONUS일 때만 NOT NULL)
    milestone_type              VARCHAR(20),                    -- 트리거된 마일스톤 유형 스냅샷: TOTAL / STREAK
    milestone_count             INTEGER,                        -- 트리거된 마일스톤 기준값 스냅샷: 예) 7, 15, 30

    /* -------------------------------------------------------
     * [RANDOM 전용] 보상 풀 참조 + 확률 스냅샷
     * ------------------------------------------------------- */
    reward_pool_id              BIGINT
        REFERENCES event_platform.event_random_reward_pool(id),
        -- FK: event_random_reward_pool.id (RANDOM일 때만 NOT NULL)
    probability_weight          INTEGER,                        -- 당첨 시점 확률 가중치 스냅샷 (풀 변경 대비 이력 보존)

    /* =========================
     * 보상 스냅샷 (의뢰 시점 기준 고정)
     * 출처 테이블의 reward_catalog 정보를 의뢰 시점에 복사
     * ========================= */
    reward_type                 VARCHAR(20)     NOT NULL,       -- POINT / COUPON / PRODUCT / NONE / ONEMORE
    point_amount                INTEGER,                        -- POINT 전용: 지급 포인트 수량 스냅샷
    coupon_group_id             BIGINT,                         -- COUPON 전용: 쿠폰 그룹 ID 스냅샷
    external_ref_id             BIGINT,                         -- PRODUCT 전용: 외부 상품 ID 스냅샷

    /* =========================
     * 멱등성 키
     * ========================= */
    idempotency_key             VARCHAR(120)    NOT NULL,       -- Queue 중복 발행 방지 키

    /* =========================
     * 감사 정보 (append-only)
     * ========================= */
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_reward_allocation_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX idx_reward_allocation_event_member
    ON event_platform.event_reward_allocation(event_id, member_id, created_at DESC);

COMMENT ON TABLE  event_platform.event_reward_allocation IS '보상 지급 의뢰 기록 (append-only) - 큐 발행 사실 + 의뢰 시점 정책 스냅샷, 지급 상태는 외부 Queue에서 관리';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_id           IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_type         IS '이벤트 유형 ATTENDANCE/RANDOM (비정규화, 조회 최적화)';
COMMENT ON COLUMN event_platform.event_reward_allocation.member_id          IS '보상 수령 회원 ID';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_entry_id     IS 'FK: event_entry.id - 1 행위당 최대 1개 보상 의뢰 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_kind        IS 'DAILY=출석 일일보상, BONUS=출석 보너스보상, RANDOM=랜덤 당첨보상';
COMMENT ON COLUMN event_platform.event_reward_allocation.daily_reward_id    IS '[DAILY 전용] FK: event_attendance_daily_reward.id - 어떤 일일 보상 정책에서 발생했는지 이력';
COMMENT ON COLUMN event_platform.event_reward_allocation.bonus_reward_id    IS '[BONUS 전용] FK: event_attendance_bonus_reward.id - 어떤 마일스톤 보너스 정책에서 발생했는지 이력';
COMMENT ON COLUMN event_platform.event_reward_allocation.milestone_type     IS '[BONUS 전용] 트리거 마일스톤 유형 스냅샷: TOTAL(누적) / STREAK(연속)';
COMMENT ON COLUMN event_platform.event_reward_allocation.milestone_count    IS '[BONUS 전용] 트리거 마일스톤 기준값 스냅샷 (예: 7일, 15일)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_pool_id     IS '[RANDOM 전용] FK: event_random_reward_pool.id - 당첨된 보상 풀 이력';
COMMENT ON COLUMN event_platform.event_reward_allocation.probability_weight IS '[RANDOM 전용] 당첨 시점 확률 가중치 스냅샷 (풀 변경 이후에도 이력 보존)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_type        IS 'POINT / COUPON / PRODUCT / NONE / ONEMORE (의뢰 시점 reward_catalog 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.point_amount       IS 'POINT 전용 지급 포인트 (의뢰 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.coupon_group_id    IS 'COUPON 전용 쿠폰 그룹 ID (의뢰 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.external_ref_id   IS 'PRODUCT 전용 외부 상품 ID (의뢰 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.idempotency_key    IS 'Queue 중복 발행 방지 멱등성 키 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_allocation.created_at         IS '보상 의뢰(큐 발행) 일시 (append-only, 수정 없음)';
