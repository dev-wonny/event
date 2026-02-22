# event_draw_prize

DRAW 전용: 등수 + 상품 + 당첨 인원

이름 고민

- **event_draw_prize**
    - cto님이 처음 만든 이름 살리기
- event_draw_reward_pool
    - 다른 거랑 이름 맞추기

```sql
-- 1등: 아이패드 1명
INSERT INTO **event_draw_prize**
(event_id, prize_rank, winner_count, reward_type, product_id)
VALUES (1001, 1, 1, 'PRODUCT', 9001);

-- 2등: 쿠폰 5명
INSERT INTO event_draw_prize
(event_id, prize_rank, winner_count, reward_type, coupon_group_id)
VALUES (1001, 2, 5, 'COUPON', 300);

-- 3등: 포인트 100명
INSERT INTO event_draw_prize
(event_id, prize_rank, winner_count, reward_type, point_amount)
VALUES (1001, 3, 100, 'POINT', 1000);

```

```sql
CREATE TABLE event_platform.**event_draw_prize** (
    id BIGSERIAL PRIMARY KEY,

    /* =========================
     * 이벤트 / 회차
     * ========================= */
    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    draw_round_id BIGINT
        REFERENCES event_platform.event_draw_round(id) ON DELETE CASCADE,
        -- NULL이면 전체 회차 공통
        -- 값 있으면 특정 회차 전용

    /* =========================
     * 등수 정보
     * ========================= */
    prize_rank INTEGER NOT NULL,
        -- 1, 2, 3 ...
        -- 1등, 2등, 3등

    winner_count INTEGER NOT NULL,
        -- 해당 등수 당첨자 수
        -- 예: 1등 1명, 2등 5명

    /* =========================
     * 보상 정보
     * ========================= */
    reward_type VARCHAR(20) NOT NULL
        CHECK (reward_type IN ('POINT','COUPON','PRODUCT')),

    /* POINT */
    point_amount INTEGER,

    /* COUPON */
    coupon_group_id BIGINT,

    /* PRODUCT */
    product_id BIGINT,

    /* =========================
     * 상태
     * ========================= */
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    /* =========================
     * 감사 컬럼
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    /* =========================
     * 제약
     * ========================= */
    UNIQUE(event_id, draw_round_id, prize_rank),

    CONSTRAINT chk_draw_prize_reward_match CHECK (
        (reward_type = 'POINT'
            AND point_amount IS NOT NULL
            AND coupon_group_id IS NULL
            AND product_id IS NULL)
        OR
        (reward_type = 'COUPON'
            AND coupon_group_id IS NOT NULL
            AND point_amount IS NULL
            AND product_id IS NULL)
        OR
        (reward_type = 'PRODUCT'
            AND product_id IS NOT NULL
            AND point_amount IS NULL
            AND coupon_group_id IS NULL)
    )
);

```