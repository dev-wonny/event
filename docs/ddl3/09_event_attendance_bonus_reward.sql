-- =============================================================
-- [09] event_attendance_bonus_reward
-- 역할  : 출석 이벤트 - 누적/연속 보너스 보상 세팅 (복수 row)
--         누적(TOTAL) N일 출석 또는 연속(STREAK) N일 달성 시 추가 지급
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_attendance_bonus_reward.event_id (1:N)
--   - event_reward_catalog.id → event_attendance_bonus_reward.reward_catalog_id (N:1)
--   - (event_id, milestone_type, milestone_count) UNIQUE
-- =============================================================
-- 예시 데이터 (event_id=1, 30일 출석 이벤트)
-- id=1, event_id=1, milestone_type='TOTAL',  milestone_count=7,  payout_rule='ONCE',       reward_catalog_id=6
--   → 누적 7일 달성 시 포인트 500 1회 지급 (카탈로그 id=6 참조)
-- id=2, event_id=1, milestone_type='TOTAL',  milestone_count=15, payout_rule='ONCE',       reward_catalog_id=2
--   → 누적 15일 달성 시 할인쿠폰 1회 지급 (카탈로그 id=2 참조)
-- id=3, event_id=1, milestone_type='STREAK', milestone_count=3,  payout_rule='REPEATABLE', reward_catalog_id=7
--   → 3일 연속 출석할 때마다 포인트 100 반복 지급 (카탈로그 id=7 참조)
-- =============================================================

CREATE TABLE event_platform.event_attendance_bonus_reward (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (1 이벤트 N 보너스 보상)

    /* =========================
     * 달성 조건
     * ========================= */
    milestone_type      VARCHAR(20)     NOT NULL,               -- TOTAL(누적 출석) / STREAK(연속 출석)
    milestone_count     INTEGER         NOT NULL,               -- 달성 기준 일수 (예: 7, 14, 30)
    payout_rule         VARCHAR(20)     NOT NULL DEFAULT 'ONCE', -- ONCE=전체 이벤트 기간 1회 / REPEATABLE=조건 재달성 시 반복 지급

    /* =========================
     * 보상 카탈로그 참조
     * ========================= */
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 상세는 카탈로그 조인으로 조회)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL,               -- FK: admin.id

    CONSTRAINT uq_att_bonus_event_type_count UNIQUE (event_id, milestone_type, milestone_count)
);

CREATE INDEX idx_att_bonus_reward_event
    ON event_platform.event_attendance_bonus_reward(event_id, milestone_type, milestone_count)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_attendance_bonus_reward IS '출석 이벤트 누적/연속 보너스 보상 세팅 (이벤트당 N row), 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.event_id          IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.milestone_type    IS 'TOTAL=누적 N일 달성 / STREAK=연속 N일 달성';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.milestone_count   IS '달성 기준 일수 (예: 7, 14, 30)';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.payout_rule       IS 'ONCE=이벤트 통틀어 1회, REPEATABLE=조건 재달성마다 반복 지급';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.reward_catalog_id IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, point_amount 등)는 카탈로그 조인으로 조회';
