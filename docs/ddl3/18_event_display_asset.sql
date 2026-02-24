-- =============================================================
-- [18] event_display_asset
-- 역할  : 이벤트 UI 표시용 이미지 매핑
--         각 이벤트의 상단/하단/중간/배경/버튼/룰렛 슬롯/카드(앞뒷면) 이미지 연결
-- 관계  :
--   - event.id → event_display_asset.event_id (1:N)
--   - file.id  → event_display_asset.file_id  (N:1)
-- =============================================================
-- 예시 데이터 (event_id=2, 룰렛 이벤트)
-- id=1,  event_id=2, asset_type='BACKGROUND_DESKTOP', file_id=1,  display_width=1920, display_height=600, sort_order=0
-- id=2,  event_id=2, asset_type='BACKGROUND_MOBILE',  file_id=2,  display_width=375,  display_height=667, sort_order=0
-- id=3,  event_id=2, asset_type='BUTTON_DEFAULT',     file_id=3,  display_width=200,  display_height=60,  sort_order=0
-- id=4,  event_id=2, asset_type='ROULETTE_SLOT',      file_id=4,  display_width=120,  display_height=120, sort_order=1  -- 룰렛 슬롯 1번 이미지
-- id=5,  event_id=2, asset_type='ROULETTE_SLOT',      file_id=5,  display_width=120,  display_height=120, sort_order=2  -- 룰렛 슬롯 2번 이미지
-- id=6,  event_id=3, asset_type='CARD_FRONT',         file_id=10, display_width=180,  display_height=280, sort_order=0
-- id=7,  event_id=3, asset_type='CARD_BACK',          file_id=11, display_width=180,  display_height=280, sort_order=0
-- id=8,  event_id=2, asset_type='SECTION_TOP',        file_id=6,  display_width=750,  display_height=200, sort_order=0
-- id=9,  event_id=2, asset_type='SECTION_BOTTOM',     file_id=7,  display_width=750,  display_height=200, sort_order=0
-- id=10, event_id=2, asset_type='SECTION_MIDDLE',     file_id=8,  display_width=750,  display_height=400, sort_order=0
-- =============================================================

CREATE TABLE event_platform.event_display_asset (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id

    /* =========================
     * 파일 참조
     * ========================= */
    file_id             BIGINT          NOT NULL
        REFERENCES event_platform.file(id),                     -- FK: file.id

    /* =========================
     * UI 슬롯 유형
     * ========================= */
    asset_type          VARCHAR(40)     NOT NULL,               -- UI 슬롯 유형 (아래 값 참고)
    -- BACKGROUND_DESKTOP : 데스크탑 배경 이미지
    -- BACKGROUND_MOBILE  : 모바일 배경 이미지
    -- SECTION_TOP        : 페이지 상단 이미지
    -- SECTION_MIDDLE     : 페이지 중간 이미지
    -- SECTION_BOTTOM     : 페이지 하단 이미지
    -- BUTTON_DEFAULT     : 기본 CTA 버튼 이미지
    -- BUTTON_ACTIVE      : 활성화 상태 버튼 이미지
    -- ROULETTE_SLOT      : 룰렛 슬롯 이미지 (sort_order로 칸 번호 구분)
    -- CARD_FRONT         : 카드 앞면 이미지
    -- CARD_BACK          : 카드 뒷면 이미지
    -- LADDER_BACKGROUND  : 사다리 배경 이미지

    /* =========================
     * UI 표시 크기 (CSS 기준 px)
     * ========================= */
    display_width       INTEGER,                                -- UI에서 표시할 너비 (CSS px, NULL 이면 원본 크기)
    display_height      INTEGER,                                -- UI에서 표시할 높이 (CSS px, NULL 이면 원본 크기)

    /* =========================
     * 정렬·상태
     * ========================= */
    sort_order          INTEGER         NOT NULL DEFAULT 0,     -- 동일 asset_type 복수 이미지 순서 (예: ROULETTE_SLOT 1~6번)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 UI 표시 안 함)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

-- 이벤트 조회 최적화
CREATE INDEX idx_display_asset_event
    ON event_platform.event_display_asset(event_id)
    WHERE is_deleted = FALSE AND is_active = TRUE;

-- 동일 이벤트 + 슬롯 유형 + 순서 유니크 (룰렛 슬롯 번호 중복 방지)
CREATE UNIQUE INDEX ux_display_asset_event_type_order
    ON event_platform.event_display_asset(event_id, asset_type, sort_order)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_display_asset IS '이벤트 UI 표시용 이미지 슬롯 매핑 (배경/섹션/버튼/룰렛슬롯/카드)';
COMMENT ON COLUMN event_platform.event_display_asset.event_id       IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_display_asset.file_id        IS 'FK: file.id - 실제 S3 파일 참조';
COMMENT ON COLUMN event_platform.event_display_asset.asset_type     IS 'UI 슬롯 유형: BACKGROUND_DESKTOP/BACKGROUND_MOBILE/SECTION_TOP/SECTION_MIDDLE/SECTION_BOTTOM/BUTTON_DEFAULT/BUTTON_ACTIVE/ROULETTE_SLOT/CARD_FRONT/CARD_BACK/LADDER_BACKGROUND';
COMMENT ON COLUMN event_platform.event_display_asset.display_width  IS 'UI 표시 너비 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.display_height IS 'UI 표시 높이 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.sort_order     IS '동일 asset_type 내 순서 - ROULETTE_SLOT은 1=1번째칸, 2=2번째칸 등으로 사용';
COMMENT ON COLUMN event_platform.event_display_asset.is_active      IS 'FALSE 이면 UI에서 해당 슬롯 이미지 사용 안 함';
