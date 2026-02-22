## event_display_asset

- mobile_banner
- web_banner
- square_thumbnail

- event_display_asset = "이 이벤트에서 어떤 파일을 어떤 용도로 쓰는가"
- file = "파일 자체"

```sql
CREATE TABLE event_platform.**event_display_asset** (
    id BIGSERIAL PRIMARY KEY,

    **event_id** BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    asset_type VARCHAR(30) NOT NULL
        CHECK (asset_type IN (
            'THUMBNAIL',
            'BANNER',
            'DETAIL_IMAGE',
            '출석체크에서만 사용하는 이미지',
            '랜덤리워드에서만 사용하는 이미지'
        )),

    file_id BIGINT NOT NULL
        REFERENCES event_platform.file(id),

    display_order INTEGER NOT NULL DEFAULT 0,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    UNIQUE(event_id, asset_type)
);

CREATE INDEX idx_event_display_asset_event
ON event_platform.event_display_asset(event_id);

CREATE INDEX idx_event_display_asset_file
ON event_platform.event_display_asset(file_id);

COMMENT ON TABLE event_platform.event_display_asset
IS '이벤트 전시용 이미지 매핑 (file FK)';

```