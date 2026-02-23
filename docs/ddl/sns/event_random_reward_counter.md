### 보상 풀 당첨 카운터 (제한 관리용)

```sql
    event_random_reward_pool.**daily_limit** INTEGER,  -- 일일 당첨 제한
    event_random_reward_pool.**total_limit** INTEGER,  -- 전체 당첨 제한
```

event_random_reward_pool 에서 위에처럼 존재하기 때문에 아래처럼 생성됨

```sql
CREATE TABLE event_platform.**event_random_reward_counter** (
    reward_pool_id BIGINT PRIMARY KEY
        REFERENCES event_platform.event_random_reward_pool(id) ON DELETE CASCADE,

    daily_count INTEGER NOT NULL DEFAULT 0,  -- 오늘 당첨 수
    total_count INTEGER NOT NULL DEFAULT 0,  -- 전체 당첨 수

    -- Optimistic Lock
    version BIGINT NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL DEFAULT CURRENT_DATE,

    /* =========================
     * 감사
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,
);

COMMENT ON TABLE event_platform.event_random_reward_counter IS 'RANDOM 보상 풀별 당첨 집계(제한 관리)';
```