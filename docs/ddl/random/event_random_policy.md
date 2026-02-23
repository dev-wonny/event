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
        -- LADDER: 사다리 타기
        -- CARD: 카드 뽑기
        ---------------------
        -- SCRATCH: 스크래치 카드
        -- SLOT: 슬롯머신
        ---------------------
        -- QUIZ: 퀴즈 참여 --> 문제, 정답 필수
        -- FIRST_COME: 선착순
        -- SURVEY: 설문조사
        -- ※ event_type이 'RANDOM_REWARD'일 때만 사용

        -- todo: reward 세팅 개수
        
        
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