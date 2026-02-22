# 참여 로그 → s3에 적재 가능

- 참여 로그 테이블은 시간 기반 파티셔닝 권장
- 모든 사람
- 행위로 insert
    - 꽝도 보상임

```sql
CREATE TABLE **event_random_reward_log** (
    ...
) PARTITION BY RANGE (created_at);

CREATE TABLE event_random_reward_log_2024_01 
    PARTITION OF event_random_participation
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
```

```sql
CREATE TABLE event_platform.**event_random_reward_log** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,
    
    -- sns 공유 후, 랜덤 돌리기 함
    trigger_type VARCHAR(20)
        CHECK (trigger_type IN ('BASE', 'SNS_SHARE', 'RETRY')),

  
    
    /* 결과 */
    reward_pool_id BIGINT NOT NULL
        REFERENCES event_platform.event_random_reward_pool(id),

    /*  reward 컬럼 스냅샷 범위 */
    reward_type VARCHAR(20) NOT NULL
        CHECK (reward_type IN ('POINT', 'COUPON', 'ENTRY', 'NONE')),
        -- POINT: 포인트
        -- COUPON: 쿠폰
        -- ENTRY: 다른 이벤트의 응모권
        -- NONE: 꽝
        -- PRODUCT: 없음
        
        
    /* ===== POINT ===== */
    point_amount INTEGER,

    /* ===== COUPON ===== */
    coupon_group_id BIGINT,
    
    /* ===== ENTRY ===== */
    target_event_id BIGINT,  -- ENTRY: 타 이벤트 참여권 지급(예: DRAW 응모권 지급)

    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_random_reward_event_member
    ON event_platform.event_random_reward_log(event_id, member_id, created_at);

COMMENT ON TABLE event_platform.event_random_reward_log IS 'RANDOM REWARD 로그(LOG)';
```