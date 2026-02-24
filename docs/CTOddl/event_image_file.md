1. 테이블 개요

항목

내용

테이블명

event_image_file

논리명

이벤트 이미지 파일

용도

이벤트에서 사용되는 이미지/영상 파일의 메타데이터 관리

성격

이벤트 도메인 공통 파일 자산 테이블

PK

id (BIGINT IDENTITY)





2. 테이블 역할 및 책임

event_image_file 테이블은 이벤트 도메인에서 사용되는 파일 자산의 메타데이터를 관리한다.

AWS S3에 저장된 파일의 식별 정보 관리

이미지/영상 파일의 기본 속성 관리 (파일 크기, MIME 타입, 해상도 등)

이벤트 배너 및 기타 이벤트 관련 테이블에서 공통 참조 대상 역할 수행

파일 자체(Binary)는 저장하지 않고 메타데이터만 관리

⚠️ 본 테이블은 파일 자산의 물리적 정보만 관리하며, 배너 노출 정책이나 이미지 변형 정책은 관리하지 않는다.





3. 컬럼 정의

3.1 식별자

컬럼명

타입

NULL

설명

id

BIGINT

N

이벤트 이미지 파일 식별자 (PK)





3.2 파일 식별 및 경로 정보

컬럼명

타입

NULL

설명

file_key

VARCHAR(300)

N

S3 객체 키 (버킷 내 유일 경로) 예: event/banner/2026/01/uuid.png

original_name

VARCHAR(255)

Y

업로드 당시 원본 파일명





3.3 파일 속성 정보

컬럼명

타입

NULL

설명

content_type

VARCHAR(30)

Y

파일 MIME 타입예: image/jpeg, image/png, image/svg+xml, video/mp4

file_size

BIGINT

Y

파일 크기(Byte)

width

INTEGER

Y

이미지 가로 픽셀 크기

height

INTEGER

Y

이미지 세로 픽셀 크기

⚠️ 영상 파일 등 이미지가 아닌 경우 width, height는 NULL이 될 수 있다.





3.4 이력 관리 컬럼

컬럼명

타입

NULL

설명

created_at

TIMESTAMP

N

등록 일시

created_by

BIGINT

N

등록자 식별자

updated_at

TIMESTAMP

N

최종 수정 일시

updated_by

BIGINT

N

최종 수정자 식별자





4. 주요 설계 규칙 및 제약

4.1 기본 제약

PK: id

file_key는 버킷 내에서 유일해야 하며, 논리적으로 중복 등록되지 않도록 관리한다.

파일 삭제 시, 이를 참조하는 테이블(event_banner_image 등)의 참조 무결성을 고려해야 한다.





4.2 파일 관리 정책

실제 파일(Binary)은 AWS S3에 저장한다.

접근 URL(Signed/Presigned URL)은 애플리케이션 계층에서 동적으로 생성한다.





5. 연관 테이블 관계

테이블

관계

설명

event_banner_image

1:N

배너 이미지 매핑

event

간접

이벤트 배너를 통해 간접 참조





6. 사용 예시 (개념)

예시: 배너 이미지 파일 관리 흐름

파일 업로드 → S3 저장

event_image_file에 파일 메타데이터 등록

event_banner_image를 통해 배너와 파일 매핑

프론트 요청 시 S3 key 기반 URL 생성 후 서빙





7. 비고

파일 확장자 및 MIME 타입 검증은 애플리케이션 계층에서 수행한다.

이미지 리사이징 정책 변경 시 본 테이블 스키마는 변경되지 않는다.

동일 파일을 여러 배너에서 재사용할 수 있다.





8. 요약

event_image_file 테이블은 이벤트 이미지/영상 파일의 메타데이터를 관리하는 자산 테이블이며, AWS S3 기반 파일 저장 구조와 정합되도록 설계되었다.





DDL

CREATE TABLE event_image_file (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_key            VARCHAR(300) NOT NULL,     -- S3 key (e.g. event/banner/2026/01/uuid.png)
    original_name       VARCHAR(255),
    content_type        VARCHAR(30),     -- image/jpeg, image/png, image/svg+xml, video/mp4 등
    file_size           BIGINT,
    width               INTEGER,
    height              INTEGER,
    created_at          TIMESTAMP NOT NULL,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    updated_by          BIGINT NOT NULL
);


COMMENT ON TABLE event_image_file IS '이벤트 이미지 파일 메타데이터';
COMMENT ON COLUMN event_image_file.id IS '이벤트 이미지 파일 식별자(PK)';
COMMENT ON COLUMN event_image_file.file_key IS 'S3 객체 키 (버킷 내 유일 경로)';
COMMENT ON COLUMN event_image_file.original_name IS '업로드 당시 원본 파일명';
COMMENT ON COLUMN event_image_file.content_type IS '파일 MIME 타입';
COMMENT ON COLUMN event_image_file.file_size IS '파일 크기(Byte)';
COMMENT ON COLUMN event_image_file.width IS '이미지 가로 픽셀 크기';
COMMENT ON COLUMN event_image_file.height IS '이미지 세로 픽셀 크기';
COMMENT ON COLUMN event_image_file.created_at IS '등록 일시';
COMMENT ON COLUMN event_image_file.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_image_file.updated_at IS '수정 일시';
COMMENT ON COLUMN event_image_file.updated_by IS '수정자 식별자';
