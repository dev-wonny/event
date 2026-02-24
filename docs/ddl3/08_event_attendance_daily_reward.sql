-- =============================================================
-- [08] event_attendance_daily_reward
-- 역할  : 출석 이벤트 - 일일 보상 세팅
--         매일 출석 시 지급할 기본 보상을 1 row로 정의
--         (모든 날짜 동일 포인트 지급 정책)
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_attendance_daily_reward.event_id (1:1)
--   - event_reward_catalog.id → event_attendance_daily_reward.reward_catalog_id (N:1)
--   - event_type='ATTENDANCE' 인 event 에만 생성
-- =============================================================
-- 예시 데이터
-- id=1, event_id=1, reward_catalog_id=1, is_active=TRUE
--   → 매일 포인트 30p 지급 (카탈로그 id=1 참조: POINT 30P)
-- =============================================================

CREATE TABLE event_platform.event_attendance_daily_reward (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조 (1:1)
     * ========================= */
    event_id            BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (출석 이벤트 1개 = 1 row)

    /* =========================
     * 보상 카탈로그 참조
     * ========================= */
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 정보는 카탈로그 조인으로 조회)

    /* =========================
     * 상태
     * ========================= */
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 보상 지급 중단, 이벤트는 유지)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_att_daily_reward_event
    ON event_platform.event_attendance_daily_reward(event_id)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_attendance_daily_reward IS '출석 이벤트 일일 보상 세팅 - 이벤트당 1 row, 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.event_id          IS 'FK: event.id - 출석 이벤트 1개당 1 row (UNIQUE)';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.reward_catalog_id IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, point_amount 등)는 카탈로그 조인으로 조회';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.is_active         IS 'FALSE 이면 보상 지급 중단 (이벤트는 유지)';
