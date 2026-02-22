# event_entry_revoke_policy (회수 정책) (선택)

“**언제 회수하나**” (회수 정책 전용)

> ❗ 계산 ❌
> 
> 
> ❗ 제한 ❌
> 
> ❗ 회수 타이밍만
> 

```sql
CREATE TABLE event_entry_revoke_policy (
    id BIGSERIAL PRIMARY KEY,
    
    
    event_id BIGINT 
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    /* 회수 조건 */
    revoke_on_order_cancel BOOLEAN NOT NULL DEFAULT TRUE,
        -- 주문 취소 시 회수

    revoke_on_return BOOLEAN NOT NULL DEFAULT TRUE,
        -- 반품 시 회수

    /* 유예 기간 */
    revoke_grace_period_hours INTEGER NOT NULL DEFAULT 0,
        -- 0: 즉시 회수
        -- 24: 24시간 후 회수

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

COMMENT ON TABLE event_entry_revoke_policy IS '응모권 회수 정책';
COMMENT ON COLUMN event_entry_revoke_policy.revoke_grace_period_hours IS '회수 유예 시간 (0=즉시)';

```