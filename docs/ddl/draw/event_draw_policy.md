# **event_draw_policy (추첨 정책)**

```sql
CREATE TABLE **event_draw_policy** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
        
    /* ========================= 
     * 추첨 방식 
     * ========================= */
    draw_type VARCHAR(20) NOT NULL DEFAULT 'SINGLE'
        CHECK (draw_type IN ('SINGLE', 'MULTIPLE')),
        -- SINGLE: 1회 추첨 (이벤트 종료 후 1번만)
        -- MULTIPLE: 다회차 추첨 (주간/일간 등 여러 번)
        
    -- 다회차인 경우 cron 표현식 (예: '0 0 12 * * MON')
    draw_schedule_cron VARCHAR(100) NOT NULL,

    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

COMMENT ON TABLE event_entry_policy IS '응모권 이벤트 발급 정책';

```