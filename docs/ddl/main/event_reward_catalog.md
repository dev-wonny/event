# event_reward_catalog (이벤트 전용 상품)

```sql
CREATE TABLE event_platform.**event_reward_catalog** (
    id BIGSERIAL PRIMARY KEY,

    reward_name VARCHAR(200) NOT NULL,
        -- "아이패드 프로 11"

    reward_type VARCHAR(20) NOT NULL
        CHECK (reward_type IN ('PRODUCT','COUPON','POINT','EXTERNAL')),

    /* 외부 연동용 reference */
    external_ref_id BIGINT,
        -- 쇼핑몰 product_id
        -- 모바일쿠폰 id
        -- 물류 상품 id 등

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    /* ========================= 
     * 감사 컬럼
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

```