## event_display_message

```sql
CREATE TABLE event_platform.**event_display_message** (
    id BIGSERIAL PRIMARY KEY,
    
    event_id BIGINT PRIMARY KEY
        REFERENCES event(id) ON DELETE CASCADE,

    /* =========================
     * UX 안내 메시지
     * ========================= */
    message_not_logged_in TEXT,
    message_duplicate_participation TEXT,
    message_outside_period TEXT,
    message_condition_not_met TEXT,

    /* =========================
     * 감사
     * ========================= */
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    UNIQUE(event_id)
);

COMMENT ON TABLE event_platform.event_display_message
IS '이벤트 전시용 안내 메시지';

```