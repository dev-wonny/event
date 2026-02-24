-- =============================================================
-- [06] event_reward_catalog
-- 역할  : 보상 카탈로그 - 쿠폰·포인트·상품·꽝·다시한번더 등록
--         event에 종속되지 않는 독립 테이블.
--         쇼핑몰 연동(external_ref_id) 또는 자체 등록 모두 지원.
--         여러 이벤트에서 동일 카탈로그 항목을 재사용 가능.
-- 관계  :
--   - event_random_reward_pool.reward_catalog_id → event_reward_catalog.id (N:1)
--   - event_attendance_daily_reward.reward_catalog_id → event_reward_catalog.id (N:1)
--   - event_attendance_bonus_reward.reward_catalog_id → event_reward_catalog.id (N:1)
-- =============================================================
-- 예시 데이터
-- id=1, reward_type='POINT',   reward_name='포인트 100P',   point_amount=100,  coupon_group_id=NULL, external_ref_id=NULL
-- id=2, reward_type='COUPON',  reward_name='5% 할인 쿠폰',  point_amount=NULL, coupon_group_id=400,  external_ref_id=NULL
-- id=3, reward_type='NONE',    reward_name='꽝',            point_amount=NULL, coupon_group_id=NULL, external_ref_id=NULL
-- id=4, reward_type='ONEMORE', reward_name='한번더',         point_amount=NULL, coupon_group_id=NULL, external_ref_id=NULL
-- id=5, reward_type='PRODUCT', reward_name='아이패드 프로',   point_amount=NULL, coupon_group_id=NULL, external_ref_id=9001
--   → id=1~5는 여러 이벤트에서 reward_catalog_id로 참조해 재사용 가능
-- =============================================================

CREATE TABLE event_platform.event_reward_catalog (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 보상 기본 정보
     * ========================= */
    reward_type         VARCHAR(20)     NOT NULL,               -- POINT(포인트) / COUPON(쿠폰) / PRODUCT(상품) / NONE(꽝) / ONEMORE(다시한번더)
    reward_name         VARCHAR(200)    NOT NULL,               -- UI 표시 보상 이름 (예: '포인트 100P', '5% 할인쿠폰', '꽝')

    /* =========================
     * 보상 세부 정보
     * ========================= */
    point_amount        INTEGER,                                -- POINT 타입 전용: 지급 포인트 수량
    coupon_group_id     BIGINT,                                 -- COUPON 타입 전용: 쿠폰 그룹 ID (외부 시스템 참조)
    external_ref_id     BIGINT,                                 -- PRODUCT 타입 전용: 쇼핑몰 product_id / 물류 상품 id 등 외부 참조

    /* =========================
     * 상태
     * ========================= */
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 보상 풀/세팅에서 선택 불가)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_reward_catalog_type
    ON event_platform.event_reward_catalog(reward_type)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_reward_catalog IS '보상 카탈로그 - event에 독립적인 공통 보상 목록 (여러 이벤트에서 재사용 가능)';
COMMENT ON COLUMN event_platform.event_reward_catalog.reward_type     IS 'POINT=포인트, COUPON=쿠폰, PRODUCT=상품(쇼핑몰/자체등록), NONE=꽝, ONEMORE=다시한번더';
COMMENT ON COLUMN event_platform.event_reward_catalog.reward_name     IS 'UI에 노출되는 보상 이름 (예: 포인트 100P, 5% 할인쿠폰)';
COMMENT ON COLUMN event_platform.event_reward_catalog.point_amount    IS 'POINT 전용: 지급 포인트 수량';
COMMENT ON COLUMN event_platform.event_reward_catalog.coupon_group_id IS 'COUPON 전용: 외부 쿠폰 시스템 그룹 ID';
COMMENT ON COLUMN event_platform.event_reward_catalog.external_ref_id IS 'PRODUCT 전용: 쇼핑몰 상품 ID 또는 물류 상품 ID (자체 등록 시 NULL)';
COMMENT ON COLUMN event_platform.event_reward_catalog.is_active       IS 'FALSE 이면 보상 풀/세팅에서 선택 불가';
