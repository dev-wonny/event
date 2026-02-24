-- =============================================================
-- [11] event_random_reward_counter
-- 역할  : 랜덤 보상 풀 당첨 카운터 - 일일·전체 제한 관리
--         daily_limit / total_limit 초과 여부를 빠르게 조회하기 위한 집계 테이블
-- 관계  :
--   - event_random_reward_pool.id → event_random_reward_counter.reward_pool_id (1:1)
-- =============================================================
-- 예시 데이터
-- reward_pool_id=2 (5% 할인쿠폰), daily_count=12, total_count=87, last_reset_date='2026-03-05'
--   → 오늘 12개 당첨, 전체 87개 당첨
-- reward_pool_id=3 (아이패드 프로), daily_count=1, total_count=3, last_reset_date='2026-03-05'
--   → daily_limit=1 초과로 오늘 더 이상 당첨 불가
-- =============================================================

CREATE TABLE event_platform.event_random_reward_counter (
    reward_pool_id      BIGINT          PRIMARY KEY
        REFERENCES event_platform.event_random_reward_pool(id) ON DELETE CASCADE, -- FK: event_random_reward_pool.id (1:1)

    /* =========================
     * 카운터
     * ========================= */
    daily_count         INTEGER         NOT NULL DEFAULT 0,     -- 오늘(last_reset_date 기준) 당첨 수량
    total_count         INTEGER         NOT NULL DEFAULT 0,     -- 이벤트 전체 기간 누적 당첨 수량
    last_reset_date     DATE            NOT NULL DEFAULT CURRENT_DATE, -- daily_count 마지막 초기화 날짜

    /* =========================
     * 갱신 시각
     * ========================= */
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP -- 마지막 카운터 갱신 일시
);

COMMENT ON TABLE  event_platform.event_random_reward_counter IS '랜덤 보상 풀 당첨 카운터 (일일·전체 제한 관리용)';
COMMENT ON COLUMN event_platform.event_random_reward_counter.reward_pool_id  IS 'FK(PK): event_random_reward_pool.id - 1:1 대응';
COMMENT ON COLUMN event_platform.event_random_reward_counter.daily_count     IS '오늘 당첨된 수량 (last_reset_date 기준, 자정마다 0으로 초기화)';
COMMENT ON COLUMN event_platform.event_random_reward_counter.total_count     IS '이벤트 전체 기간 누적 당첨 수량';
COMMENT ON COLUMN event_platform.event_random_reward_counter.last_reset_date IS 'daily_count가 마지막으로 0으로 초기화된 날짜';
COMMENT ON COLUMN event_platform.event_random_reward_counter.updated_at      IS '카운터 마지막 업데이트 일시';
