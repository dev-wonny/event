### 정책

👉 "랜덤 게임 자체의 룰"만 담아야 한다.

확률 ❌ (reward_pool)
참여횟수 ❌ (limit_policy)
SNS ❌ (share_log)
보상 ❌ (reward_pool)

- event_type = RANDOM_REWARD 인 event만 policy 생성 가능하도록
- application + DB constraint 둘 다 방어

```sql
CREATE TABLE event_platform.**event_random_policy** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
        
    game_type VARCHAR(20) 
        -- ROULETTE: 룰렛 게임
        -- QUIZ: 퀴즈 참여
        -- SCRATCH: 스크래치 카드
        -- SLOT: 슬롯머신
        -- FIRST_COME: 선착순
        -- SURVEY: 설문조사
        -- ※ event_type이 'RANDOM_REWARD'일 때만 사용

    /* 당첨 정책 */
    -- 1️⃣ 중복 당첨 허용 여부
    allow_duplicate_win BOOLEAN NOT NULL DEFAULT FALSE,

    -- 2️⃣ RETRY 자동 실행 여부
    -- AUTO: 자동으로 재시도
    -- MANUAL: 수동으로 재시도
    retry_mode VARCHAR(20),
    
    -- 3️⃣ RETRY 최대 연속 횟수
    max_retry_count INTEGER,
    
    CHECK (
    (retry_mode IS NULL AND max_retry_count IS NULL)
    OR
    (retry_mode IS NOT NULL AND max_retry_count IS NOT NULL)
)

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

UNIQUE(event_id)

COMMENT ON TABLE event_platform.event_random_policy IS 'RANDOM_REWARD 이벤트 정책(랜덤게임 전용)';

```