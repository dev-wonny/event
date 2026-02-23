# 공통: 이벤트 참여 자격 (Eligibility)

- event_entry_eligibility 일반화

모든 이벤트에 적용함

- 랜덤 리워드 이벤트
- 출석 이벤트
- 응모 추첨 이벤트

“**누가 참여할 수 있나**” (회원 자격 / 이력 조건)

> ❗ 수량 계산 ❌
> 
> 
> ❗ 오직 **자격 판단만**
> 

```sql
CREATE TABLE event_platform.event_participation_eligibility (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    eligibility_type VARCHAR(30) NOT NULL
        CHECK (eligibility_type IN (
            'MEMBER_TYPE',
            'MEMBER_GRADE',
            'MIN_JOIN_DAYS',
            'PHONE_VERIFIED',
            'EMAIL_VERIFIED',
            'ADDRESS_REGISTERED',
            'MIN_ORDER_AMOUNT',         -- 공통: 최소 주문금액(필요 시)
            'EXCLUDE_WINNER_PERIOD'     -- 공통: 최근 당첨자 제외(일수)
        )),

    eligibility_value VARCHAR(200),
        -- MEMBER_TYPE            : '["NEW","REGULAR","VIP"]'
        -- MEMBER_GRADE           : '["SILVER","GOLD","VIP"]'
        -- MIN_JOIN_DAYS: '30'
        -- MIN_ORDER_AMOUNT: '50000'
        -- PHONE_VERIFIED         : 'true'
        -- EMAIL_VERIFIED         : 'true'
        -- ADDRESS_REGISTERED     : 'true'
        -- EXCLUDE_WINNER_PERIOD  : '90'  (최근 90일 이내 당첨자 제외)

    priority INTEGER NOT NULL DEFAULT 0,   -- 우선순위(낮을수록 우선)
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

CREATE INDEX idx_part_eligibility_event
    ON event_platform.event_participation_eligibility(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE event_platform.event_participation_eligibility IS '이벤트 공통 참여 자격 조건';

```