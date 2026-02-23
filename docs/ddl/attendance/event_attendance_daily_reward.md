# event_attendance_daily_reward    -- 일별 보상 정의

**✅ daily_reward = "그 날 출석하면 주는 기본 보상"**

- 30일
    - row 1개 → 30일 똑같은 포인트 줌
    - 매일 포인트는 똑같은걸로 약속하는걸로

```sql
CREATE TABLE event_attendance_daily_reward (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
        
    /* ========================= 
     * 보상 정보 
     * ========================= */
     reward_catalog_id BIGINT NULL
    REFERENCES event_platform.event_reward_catalog(id),
    
    reward_type VARCHAR(20) NOT NULL
        -- POINT: 포인트 : point_amount 사용
        -- COUPON: 쿠폰 : coupon_group_id 사용
        -- NONE: 보상 없음 (출석만 체크)
        
    point_amount INTEGER,
    coupon_group_id BIGINT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,
    
    UNIQUE(event_id)
);

CREATE INDEX idx_attendance_daily_event ON event_attendance_daily_reward(event_id) 
    WHERE is_deleted = FALSE;

COMMENT ON TABLE event_attendance_daily_reward IS '출석 이벤트 일별 보상';
```