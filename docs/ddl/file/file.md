# file

✔️ 파일 재사용 가능

✔️ CDN / S3 변경 시 테이블 안 건드림

✔️ soft delete 관리 쉬움

✔️ Admin UI 만들 때 매우 편함

```sql
CREATE TABLE event_platform.file (
    id BIGSERIAL PRIMARY KEY,

    /* =========================
     * 저장 위치
     * ========================= */
    object_key VARCHAR(300) NOT NULL,
    -- ex) event/2026/02/uuid.png

    /* =========================
     * 파일 메타
     * ========================= */
    original_file_name VARCHAR(200),

    file_size BIGINT NOT NULL CHECK (file_size >= 0),

    mime_type VARCHAR(50) NOT NULL
        CHECK (mime_type IN (
            'image/png',
            'image/jpeg',
            'image/gif'
        )),

    file_extension VARCHAR(10) NOT NULL
        CHECK (file_extension IN ('png','jpg','jpeg','gif')),

    checksum_sha256 VARCHAR(64),

    -- 이미지 자체의 해상도 (진짜 픽셀)
    width INTEGER,
    height INTEGER,

    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

CREATE UNIQUE INDEX idx_file_object_key
ON event_platform.file(object_key);

```