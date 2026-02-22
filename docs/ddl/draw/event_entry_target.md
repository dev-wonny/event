# **event_entry_target (응모 대상 정의)**

- 책임: 무엇을 사야 응모권을 주는가
- 대상 정의(What)
    - 상품인가?
    - 카테고리인가?
    - 포함/제외 조건

어떤 상품/카테고리가 응모 대상인가?

- PRODUCT / CATEGORY 확장 가능
- 나중에 BRAND, SELLER도 여기 붙이면 끝
- 🔥 “포함 / 제외 / 최소 조건”까지 고려

```sql
- - 예시 데이터
-- 스니커즈 카테고리(ID:100) 상품 구매 시 응모권 발급, 단 아울렛 상품(ID:999)은 제외
-- INSERT INTO **event_entry_target** VALUES
-- (1, 1, 'CATEGORY', 100, 'INCLUDE', ...),
-- (2, 1, 'PRODUCT', 999, 'EXCLUDE', ...);

CREATE TABLE **event_entry_target** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    /* ========================= 
     * 대상 유형 
     * ========================= */
    target_type VARCHAR(20) NOT NULL
        CHECK (target_type IN ('PRODUCT', 'CATEGORY', 'BRAND')),
        -- PRODUCT: 특정 상품 구매 시
        -- CATEGORY: 특정 카테고리 상품 구매 시
        -- BRAND: 특정 브랜드 상품 구매 시

    target_id BIGINT NOT NULL,
        -- PRODUCT  → product.id
        -- CATEGORY → category.id
        -- BRAND    → brand.id
   
    /* ========================= 
     * 포함/제외 규칙 
     * ========================= */
    rule_type VARCHAR(20) NOT NULL
        CHECK (rule_type IN ('INCLUDE', 'EXCLUDE')),
        -- INCLUDE: 이 대상 구매 시 응모권 발급
        -- EXCLUDE: 이 대상은 응모권 발급 제외

    /* =========================
     * 감사 컬럼
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    UNIQUE (event_id, target_type, target_id)
);

CREATE INDEX idx_entry_target_event ON **event_entry_target**(event_id) 
    WHERE is_deleted = FALSE;

COMMENT ON TABLE **event_entry_target** IS '응모권 발급 대상 (상품/카테고리/브랜드)';
```