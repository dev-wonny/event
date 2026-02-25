-- =============================================================
-- [02] event
-- 역할  : 이벤트 마스터 테이블 - 출석·랜덤 이벤트 각각 1 row
-- 관계  :
--   - event_attendance_policy.event_id       → event.id (1:1)
--   - event_random_policy.event_id           → event.id (1:1)
--   - event_participation_eligibility.event_id → event.id (1:N)
--   - event_participation_limit_policy.event_id → event.id (1:N)
--   - event_display_asset.event_id           → event.id (1:N)
--   - event_display_message.event_id         → event.id (1:N)
--   - event_reward_catalog.event_id          → event.id (1:N)
--   - event_participant.event_id             → event.id (1:N)
--   - event_entry.event_id                     → event.id (1:N)
--   - event_reward_allocation.event_id            → event.id (1:N)
--   - event_share_policy.event_id            → event.id (1:1)
--   - event_share_log.event_id               → event.id (1:N)
-- =============================================================
-- 예시 데이터
-- id=1, supplier_id=1, event_type='ATTENDANCE', title='봄맞이 30일 출석 이벤트',
--        status='ACTIVE', start_at='2026-03-01 00:00:00', end_at='2026-03-31 23:59:59'
-- id=2, supplier_id=1, event_type='RANDOM',     title='봄맞이 룰렛 이벤트',
--        status='ACTIVE', start_at='2026-03-01 00:00:00', end_at='2026-03-15 23:59:59'
-- =============================================================

CREATE TABLE event_platform.event (
    id              BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 기본 식별 정보
     * ========================= */
    supplier_id     BIGINT          NOT NULL,                    -- 주최사 ID (현재: 돌쇠네 = 1)
    event_type      VARCHAR(20)     NOT NULL,                    -- 이벤트 유형: ATTENDANCE(출석체크) / RANDOM(랜덤게임)
    title           VARCHAR(200)    NOT NULL,                    -- 이벤트 제목 (관리자/UI 표시용)
    description     TEXT,                                       -- 이벤트 상세 설명

    /* =========================
     * 상태 및 운영
     * ========================= */
    status          VARCHAR(20)     NOT NULL DEFAULT 'DRAFT',   -- DRAFT(작성중) / ACTIVE(진행중) / PAUSED(일시정지) / ENDED(종료) / CANCELLED(취소)
    is_visible      BOOLEAN         NOT NULL DEFAULT TRUE,      -- UI 노출 여부 (FALSE 이면 URL 접근 불가)
    display_order   INTEGER         NOT NULL DEFAULT 0,         -- 목록 정렬 순서 (작을수록 상단)

    /* =========================
     * 이벤트 기간
     * ========================= */
    start_at        TIMESTAMP       NOT NULL,                   -- 이벤트 시작 일시 (KST 기준 입력 권장)
    end_at          TIMESTAMP       NOT NULL,                   -- 이벤트 종료 일시 (KST 기준 입력 권장)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT          NOT NULL,                   -- FK: admin.id
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL                    -- FK: admin.id
);

CREATE INDEX idx_event_supplier_type
    ON event_platform.event(supplier_id, event_type)
    WHERE is_deleted = FALSE;

CREATE INDEX idx_event_status_period
    ON event_platform.event(status, start_at, end_at)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event IS '이벤트 마스터 - 출석/랜덤 이벤트 각 1 row';
COMMENT ON COLUMN event_platform.event.supplier_id   IS '주최사 ID (현재: 돌쇠네=1, 추후 멀티 테넌트 확장 고려)';
COMMENT ON COLUMN event_platform.event.event_type    IS '이벤트 유형 ATTENDANCE(출석체크) / RANDOM(랜덤게임)';
COMMENT ON COLUMN event_platform.event.title         IS '이벤트 제목 (관리자 화면·이벤트 목록 UI 표시)';
COMMENT ON COLUMN event_platform.event.description   IS '이벤트 상세 설명 (HTML 가능)';
COMMENT ON COLUMN event_platform.event.status        IS 'DRAFT=작성중, ACTIVE=진행중, PAUSED=일시정지, ENDED=종료, CANCELLED=취소';
COMMENT ON COLUMN event_platform.event.is_visible    IS 'UI 노출 여부 - FALSE 이면 URL 직접 접근도 차단';
COMMENT ON COLUMN event_platform.event.display_order IS '목록 정렬 순서 (낮을수록 상단 노출)';
COMMENT ON COLUMN event_platform.event.start_at      IS '이벤트 시작 일시 (KST 기준 입력 권장)';
COMMENT ON COLUMN event_platform.event.end_at        IS '이벤트 종료 일시 (KST 기준 입력 권장)';
