-- =============================================================
-- [10] event_random_reward_pool
-- 역할  : 랜덤 이벤트 보상 풀 - 카탈로그 등록 + 확률 가중치 + 제한 수량 설정
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_random_reward_pool.event_id (1:N)
--   - event_reward_catalog.id → event_random_reward_pool.reward_catalog_id (N:1)
--   - event_random_reward_pool.id → event_random_reward_counter.reward_pool_id (1:1)
--   - event_random_reward_pool.id → event_log.reward_pool_id (1:N)
-- =============================================================
-- 예시 데이터 (event_id=2, 룰렛 이벤트 6칸)
-- id=1, event_id=2, reward_catalog_id=1, probability_weight=60, daily_limit=NULL, total_limit=NULL,  priority=1
--   → 포인트 100P, 60% 확률, 무제한
-- id=2, event_id=2, reward_catalog_id=2, probability_weight=25, daily_limit=50,   total_limit=500,  priority=2
--   → 5% 할인쿠폰, 25% 확률, 일 50개·전체 500개 제한
-- id=3, event_id=2, reward_catalog_id=5, probability_weight=5,  daily_limit=1,    total_limit=10,   priority=3
--   → 아이패드 프로, 5% 확률, 일 1개·전체 10개 제한
-- id=4, event_id=2, reward_catalog_id=4, probability_weight=5,  daily_limit=NULL, total_limit=NULL, priority=4
--   → 다시한번더(ONEMORE), 5% 확률
-- id=5, event_id=2, reward_catalog_id=3, probability_weight=5,  daily_limit=NULL, total_limit=NULL, priority=5
--   → 꽝(NONE), 5% 확률
-- =============================================================

CREATE TABLE event_platform.event_random_reward_pool (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·카탈로그 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 상세는 카탈로그 조인으로 조회)

    /* =========================
     * 확률 가중치
     * ========================= */
    probability_weight  INTEGER         NOT NULL,               -- 가중치 (실제확률 = 이 값 / 이벤트 전체 가중치 합, 예: 60이면 60%)

    /* =========================
     * 수량 제한
     * ========================= */
    daily_limit         INTEGER,                                -- 일일 최대 당첨 수량 (NULL = 무제한)
    total_limit         INTEGER,                                -- 전체 기간 최대 당첨 수량 (NULL = 무제한)

    /* =========================
     * 정렬·상태
     * ========================= */
    priority            INTEGER         NOT NULL DEFAULT 0,     -- UI 슬롯 표시 순서 (낮을수록 앞)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 당첨 대상 제외)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_random_pool_event_priority
    ON event_platform.event_random_reward_pool(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_random_reward_pool IS '랜덤 이벤트 보상 풀 - 확률 가중치·일일/전체 제한 수량 설정, 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_random_reward_pool.event_id           IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_random_reward_pool.reward_catalog_id  IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, 금액 등)는 카탈로그 조인으로 조회';
COMMENT ON COLUMN event_platform.event_random_reward_pool.probability_weight IS '가중치 - 실제확률 = 이 값 / 이벤트 전체 가중치 합 (예: 60)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.daily_limit        IS '일일 최대 당첨 수량 (NULL=무제한)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.total_limit        IS '전체 기간 최대 당첨 수량 (NULL=무제한)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.priority           IS 'UI 슬롯 표시 순서 (낮을수록 앞)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.is_active          IS 'FALSE 이면 당첨 풀에서 제외';
