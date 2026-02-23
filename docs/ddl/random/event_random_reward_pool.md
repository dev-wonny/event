# event_random_**reward_pool** 추첨 보상 풀 (당첨 시 지급할 보상 정의) : reward 전용

```sql
-- 예시 데이터
-- 룰렛: 포인트 100점(가중치 60), 쿠폰(가중치 30), 꽝(가중치 10)
-- 실제 확률: 포인트 60%, 쿠폰 30%, 꽝 10%
-- INSERT INTO event_random_reward_pool VALUES 
--   (1, 1, '포인트 100점', 'POINT', '{"amount": 100}', 60, NULL, NULL, 1, TRUE, ...),
--   (2, 1, '할인쿠폰', 'COUPON', '{"coupon_group_id": 400}', 30, 100, 500, 2, TRUE, ...),
--   (3, 1, '꽝', 'NONE', NULL, 10, NULL, NULL, 3, TRUE, ...);
```

```sql
CREATE TABLE event_platform.**event_random_reward_pool** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
        
        
    /* ========================= 
     * 보상 정보 
     * ========================= */
    reward_catalog_id BIGINT NULL
        REFERENCES event_platform.event_reward_catalog(id),

    reward_name VARCHAR(100) NOT NULL, -- 보상 이름 (UI 표시용)
    reward_type VARCHAR(20) NOT NULL
        -- POINT: 포인트
        -- COUPON: 쿠폰
        -- ENTRY: 다른 이벤트의 응모권
        -- NONE: 꽝
        -- ONEMORE: 한번 더
        -- PRODUCT: 사용 안함

    /* JSON 금지: 통계/정합성 위해 컬럼화 */
    
    /* ===== POINT ===== */
    point_amount INTEGER,

    /* ===== COUPON ===== */
    coupon_group_id BIGINT,
    
    /* ===== ENTRY ===== */
    target_event_id BIGINT,  -- ENTRY: 타 이벤트 참여권 지급(예: DRAW 응모권 지급)

    /* ========================= 
     * 확률 가중치 -> 랜덤 리워드만 사용, 출석체크, 응모 추첨에서는 사용 안함
     * ========================= */
    probability_weight INTEGER NOT NULL, -- 가중치 (예: 10, 30, 60)
        -- 실제 확률 = (이 가중치) / (모든 보상 가중치의 합)

    /* 보상 개수 제한(보상 단위) */
    daily_limit INTEGER,  -- 일일 상품 당첨 제한
    total_limit INTEGER,  -- 전체 상품 당첨 제한

    priority INTEGER NOT NULL DEFAULT 0, -- 우선순위 (낮을수록 높음)
    is_active BOOLEAN NOT NULL DEFAULT TRUE, -- 활성화 여부
    
    /* ========================= 
     * 감사 컬럼 
     * ========================= */

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

CREATE INDEX idx_random_pool_event
    ON event_platform.event_random_reward_pool(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE event_platform.event_random_reward_pool IS 'RANDOM 보상 풀(확률 가중치 기반)';

```