# event_draw_entry_rule (발급 규칙)

💡 응모권 발급 **계산 공식**

> **“조건이 맞으면, 몇 장을 준다”**
> 

### 책임

- 응모권 **기본 산식**
- 주문 / 참여 / 자동 이벤트 구분

### ❌ 여기 넣으면 안 되는 것

- 일일 제한
- 유저 제한
- 회차 정보
- 당첨 여부

👉 **순수 계산 로직만**

1️⃣ event_draw_entry_rule 유지

2️⃣ SNS는 따로 관리 : event_share_log → SNS 성공 → 서버가 entry_issued INSERT

```sql
CREATE TABLE **event_draw_entry_rule** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    /* ========================= 
     * 응모권 발급 방식
     * ========================= */
    issue_type VARCHAR(20) NOT NULL DEFAULT 'ORDER_BASED'
        CHECK (issue_type IN ('ORDER_BASED', 'FIXED', 'MANUAL')),
        -- ORDER_BASED: 주문 금액/수량 기반 자동 발급
        -- FIXED: 참여 시 고정 수량 발급 (예: 버튼 클릭 시 1장)
        -- MANUAL: 관리자 수동 발급

    /* ========================= 
     * ORDER_BASED 발급 규칙
     * ========================= */
    calculation_type VARCHAR(20)
        CHECK (calculation_type IN ('PER_QUANTITY', 'PER_AMOUNT', 'PER_ORDER')),
        -- PER_QUANTITY: 구매 수량 기반 (상품 1개당 N장)
        -- PER_AMOUNT: 구매 금액 기반 (1만원당 N장)
        -- PER_ORDER: 주문 1건당 N장 (금액/수량 무관)
 
    entry_per_unit INTEGER,
        -- PER_QUANTITY: 상품 1개당 응모권 N장
        -- PER_AMOUNT: 1만원당 응모권 N장
        -- PER_ORDER: 주문당 응모권 N장
    
    amount_unit DECIMAL(10,2),
        -- PER_AMOUNT인 경우 기준 금액 (예: 10000 → 1만원당)
    
    min_order_amount DECIMAL(10,2),
        -- 최소 주문 금액 (예: 50000 → 5만원 이상 구매 시만 발급)
    
    /* ========================= 
     * FIXED 발급 규칙
     * ========================= */
    fixed_entry_count INTEGER,
        -- FIXED인 경우 고정 발급 수량
        
  CHECK (
    (issue_type='ORDER_BASED' 
       AND calculation_type IS NOT NULL 
       AND entry_per_unit IS NOT NULL)
    OR
    (issue_type='FIXED' 
       AND fixed_entry_count IS NOT NULL)
    OR
    (issue_type='MANUAL' 
       AND calculation_type IS NULL 
       AND entry_per_unit IS NULL 
       AND fixed_entry_count IS NULL)
)

    /* ========================= 
     * 감사 컬럼
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

COMMENT ON TABLE event_draw_entry_rule IS '응모권 발급 규칙 (얼마를 주나)';
COMMENT ON COLUMN event_draw_entry_rule.calculation_type IS '수량 기반 / 금액 기반 / 주문 기반';
COMMENT ON COLUMN event_draw_entry_rule.entry_per_unit IS '단위당 발급 응모권 수';
```