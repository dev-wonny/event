-- =============================================================
-- [01] file
-- 역할  : S3에 업로드된 물리 파일 메타 저장소
-- 관계  :
--   - event_display_asset.file_id  → file.id   (N:1)
-- =============================================================
-- 예시 데이터
-- id=1, object_key='event/2026/01/banner.png', original_file_name='banner.png',
--        file_size=204800, mime_type='image/png', file_extension='png', width=1920, height=600
-- id=2, object_key='event/2026/01/roulette_1.png', original_file_name='roulette_1.png',
--        file_size=98304, mime_type='image/png', file_extension='png', width=200, height=200
-- =============================================================

CREATE TABLE event_platform.file (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 저장 위치
     * ========================= */
    object_key          VARCHAR(300)    NOT NULL,                    -- S3 오브젝트 키 (ex: event/2026/02/uuid.png)

    /* =========================
     * 파일 메타
     * ========================= */
    original_file_name  VARCHAR(200),                                -- 업로드 시 원본 파일명
    file_size           BIGINT          NOT NULL,                    -- 파일 크기 (byte)
    mime_type           VARCHAR(50)     NOT NULL,                    -- MIME 타입 (image/png, image/jpeg, image/gif)
    file_extension      VARCHAR(10)     NOT NULL,                    -- 파일 확장자 (png, jpg, jpeg, gif)
    checksum_sha256     VARCHAR(64),                                 -- SHA-256 해시값 (중복 감지용, 선택)
    width               INTEGER,                                     -- 이미지 실제 픽셀 너비
    height              INTEGER,                                     -- 이미지 실제 픽셀 높이

    /* =========================
     * 상태
     * ========================= */
    is_public           BOOLEAN         NOT NULL DEFAULT TRUE,       -- CDN 공개 여부

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,                    -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                     -- FK: admin.id
);

CREATE UNIQUE INDEX ux_file_object_key
    ON event_platform.file(object_key)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.file IS 'S3 업로드 파일 메타 저장소 (CDN 주소는 application.properties 관리)';
COMMENT ON COLUMN event_platform.file.object_key         IS 'S3 오브젝트 키 - CDN/S3 베이스 URL은 application.properties에서 조합';
COMMENT ON COLUMN event_platform.file.original_file_name IS '업로드 당시의 원본 파일명';
COMMENT ON COLUMN event_platform.file.file_size          IS '파일 바이트 크기';
COMMENT ON COLUMN event_platform.file.mime_type          IS 'MIME 타입 (image/png, image/jpeg, image/gif)';
COMMENT ON COLUMN event_platform.file.file_extension     IS '파일 확장자 소문자 (png, jpg, jpeg, gif)';
COMMENT ON COLUMN event_platform.file.checksum_sha256    IS 'SHA-256 체크섬 - 동일 파일 중복 업로드 감지용';
COMMENT ON COLUMN event_platform.file.width              IS '이미지 실제 픽셀 너비';
COMMENT ON COLUMN event_platform.file.height             IS '이미지 실제 픽셀 높이';
COMMENT ON COLUMN event_platform.file.is_public          IS 'CDN 공개 여부 (FALSE 이면 Presigned URL 사용)';
