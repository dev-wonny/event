# 공통: 참여 제한 정책 (Limit)

```sql
    /* 참여 제한(추가로 공통 limit_policy와 함께 사용 가능) */
    daily_participation_limit INTEGER,
    total_participation_limit INTEGER,
```

- 기존 event_entry_limit 일반화

“**얼마까지 허용하나**” (수량 제한 전용)

> ❗ 회원 조건 / 회수 정책 ❌
> 
> 
> ❗ 오직 **수량 제한만** 담당
> 

1️⃣ eligibility  → 누가 참여 가능?
2️⃣ user limit   → 개인당 몇 번?
3️⃣ global limit → 이벤트 전체 몇 번?

```sql
ORDER / 10  / priority 0   → 주문당 최대 10장 == max_entry_per_order
DAY   / 5   / priority 10  → 하루 최대 5장 == max_entry_per_day
USER  / 100 / priority 20  → 전체 최대 100장 == max_entry_per_user
```

```sql
CREATE TABLE event_platform.**event_participation_limit_policy** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
        
    /* ========================= 
     * 제한 범위
     * ========================= */
     
    /* 제한 대상 */
    limit_subject VARCHAR(20) NOT NULL
        CHECK (limit_subject IN ('USER','GLOBAL')),
        -- USER   : 회원 기준
        -- GLOBAL : 이벤트 전체 기준
     
     
        /* 제한 범위 */
    limit_scope VARCHAR(20) NOT NULL
        CHECK (limit_scope IN ('USER','DAY','HOUR','ORDER','ROUND','TOTAL')),
        -- USER : 이벤트 전체 기간 회원당
        -- DAY  : 일자 기준 회원당 (자정 초기화)
        -- HOUR : 시간 기준 회원당
        -- ORDER: 주문건당(주로 DRAW)
        -- ROUND: 회차당(주로 DRAW)
        -- TOTAL : 이벤트 전체 1000명 제한
        
    limit_metric VARCHAR(20) NOT NULL
        CHECK (limit_metric IN ('EXECUTION','UNIQUE_MEMBER')),
        -- EXECUTION     : 실행 횟수 기준
        -- UNIQUE_MEMBER : 참여 인원 기준

    limit_value INTEGER NOT NULL,          
    -- 해당 scope 내 최대 허용 횟수/수량
    -- CHECK (limit_value > 0)

    /* ========================= 
     * 우선순위 (선택적 조건부 제한용)
     * ========================= */
    priority INTEGER NOT NULL DEFAULT 0,
        -- 낮을수록 먼저 적용
        -- 동일 scope에 여러 제한이 있을 때 사용
        -- 예: VIP DAY 제한(0) → 일반 DAY 제한(10)
        
    /* ========================= 
     * 활성화 제어
     * ========================= */
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
        -- 임시 비활성화 가능 (삭제하지 않고 끄기)

    /* ========================= 
     * 감사 컬럼
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

CREATE INDEX idx_part_limit_event
    ON event_platform.event_participation_limit_policy(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

CREATE INDEX idx_part_limit_scope
    ON event_platform.event_participation_limit_policy(event_id, limit_scope)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE event_platform.event_participation_limit_policy IS '이벤트 공통 참여 제한 정책';
```