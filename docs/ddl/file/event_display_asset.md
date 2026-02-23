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

    /* =========================
     * UI Slot (Aspect Ratio 기준)
     * ========================= */
    asset_type VARCHAR(40) NOT NULL
        CHECK (asset_type IN (
            'BACKGROUND_DESKTOP',
            'BACKGROUND_MOBILE',
            'BUTTON',
            'FOOTER'
        )),
    -- React에서 사용하는 UI 슬롯 개념

    -- UI에서 보여줄 크기
    display_width INTEGER,
    display_height INTEGER,

    /* =========================
     * 물리 파일 참조
     * ========================= */
    file_id BIGINT NOT NULL
        REFERENCES event_platform.file(id),

    /* =========================
     * 표시 제어
     * ========================= */
    sort_order INTEGER NOT NULL DEFAULT 0,
    -- 여러 버튼/이미지 순서 제어용

    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- 관리자 OFF 처리 가능

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    UNIQUE(event_id, asset_type)
);

-- event_display_asset_variant
CREATE UNIQUE INDEX ux_event_asset_variant
ON event_platform.event_display_asset(
    event_id,
    asset_type
);

-- 이벤트 조회 최적화
CREATE INDEX idx_event_display_asset_event
ON event_platform.event_display_asset(event_id);

COMMENT ON TABLE event_platform.event_display_asset
IS '이벤트 전시용 이미지 매핑 (file FK)';

```