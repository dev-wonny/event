## file

✔️ 파일 재사용 가능

✔️ CDN / S3 변경 시 테이블 안 건드림

✔️ soft delete 관리 쉬움

✔️ Admin UI 만들 때 매우 편함

```sql
CREATE TABLE event_platform.file (
    id BIGSERIAL PRIMARY KEY,

    /* =========================
     * 저장 위치 (URL은 저장 X)
     * ========================= */
     -- bucket_name 사용안함 Spring에서 application.yml에서 관리

    object_key VARCHAR(300) NOT NULL, -- 실제 파일 경로
-- event/2026/02/uuid.png
-- /data/uploads/event/2026/02/uuid.png**


-- cdn url 추가

    **storage_type** VARCHAR(20) NOT NULL DEFAULT 'S3'
        CHECK (storage_type IN ('S3')),

    /* =========================
     * 파일 메타
     * ========================= */
    **original_file_name** VARCHAR(200), -- 유저가 올린 이름

    **file_size** BIGINT NOT NULL CHECK (file_size >= 0),

    **mime_type** VARCHAR(20) NOT NULL
        CHECK (mime_type IN (
            'image/png',
            'image/jpeg',
            'image/gif'
        )),

    **file_extension** VARCHAR(10) NOT NULL
        CHECK (file_extension IN ('png','jpg','jpeg','gif')),

    /* =========================
     * 보안 / 운영
     * ========================= */
    **checksum_sha256** VARCHAR(64), -- 무결성 검증

    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL
);

CREATE UNIQUE INDEX idx_file_object
ON event_platform.file(bucket_name, object_key);

COMMENT ON TABLE event_platform.file
IS '이벤트 플랫폼 이미지 파일 저장소 (png/gif/jpeg 전용)';

```