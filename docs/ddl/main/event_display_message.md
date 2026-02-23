## event_display_message

```sql
CREATE TABLE event_platform.event_display_message (
    id BIGSERIAL PRIMARY KEY,

    -- NOT_LOGGED_IN, DUPLICATE_PARTICIPATION, OUTSIDE_PERIOD, CONDITION_NOT_MET
    message_type VARCHAR(100) NOT NULL,
    text TEXT NOT NULL,

    is_default BOOLEAN NOT NULL DEFAULT TRUE,
    -- 기본 메시지 여부

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    UNIQUE(message_type)
);

COMMENT ON TABLE event_platform.event_display_message
IS '이벤트 공통 안내 메시지 (Default Dictionary)';

```