1. 테이블 개요

항목

내용

테이블명

event_banner_image

논리명

이벤트 배너 이미지

용도

이벤트 배너와 이미지 파일 간의 매핑 및 이미지 변형 유형 관리

성격

이벤트 배너 하위 리소스 매핑 테이블

PK

id (BIGINT IDENTITY)

FK

event_banner_id → event_banner.idevent_file_id → event_image_file.id





2. 테이블 역할 및 책임

event_banner_image 테이블은 이벤트 배너와 이미지 파일 간의 연결 관계를 관리하며,

하나의 배너에 대해 여러 이미지 변형(원본, PC용, 모바일용 등) 을 표현하기 위한 테이블이다.

배너 1건에 연결된 이미지 파일 목록 관리

이미지 변형 유형(Variant) 관리

PC/모바일/원본 등 디바이스·용도별 이미지 매핑

배너 정책(event_banner)과 파일 자산(event_image_file) 간의 연결 역할 수행



⚠️ 본 테이블은 파일의 메타데이터를 직접 관리하지 않는다.

파일 정보(S3 key, 해상도, 용량 등)는 event_image_file 테이블의 책임이다.





3. 컬럼 정의

3.1 식별자 및 관계



컬럼명

타입

NULL

설명

id

BIGINT

N

배너 이미지 매핑 식별자 (PK)

event_banner_id

BIGINT

N

이벤트 배너 식별자 (FK, event_banner.id)

event_file_id

BIGINT

N

이벤트 이미지 파일 식별자 (FK, event_image_file.id)





3.2 이미지 변형 정보 (다소 오버엔지리어닝 일 수 있음)

컬럼명

타입

NULL

설명

image_variant

VARCHAR(30)

N

이미지 변형 유형 코드 code_group(EVENT.VARIANT) 예: ORIGINAL, PC, MOBILE



image_variant 의미

ORIGINAL : 업로드된 원본 이미지

PC : PC 화면에 최적화된 리사이즈 이미지

MOBILE : 모바일 화면에 최적화된 리사이즈 이미지

배너 정책과 이미지 자산의 책임 분리

배너 노출 대상 디바이스(event_banner.device_type)는 정책 정보

image_variant는 파일의 변형/서빙 목적을 나타내는 자산 정보

mage_variant는 이미지가 “어떤 변형본인지”를 명확히 구분하여 배너 이미지 관리의 유연성, 확장성, 서빙 안정성을 확보하기 위한 핵심 컬럼이다.





3.3 이력 관리 컬럼

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





4. 코드 컬럼 정의

컬럼명

코드 도메인

코드 그룹

설명

image_variant

EVENT

VARIANT

이미지 변형 유형

이미지 변형 유형은 공통 코드 테이블(code_group, code_detail)을 기준으로 관리한다.



5. 주요 설계 규칙 및 제약

5.1 기본 제약

PK: id

FK:

event_banner_id → event_banner.id

event_file_id → event_image_file.id

하나의 배너(event_banner_id)는 여러 개의 이미지 변형을 가질 수 있다.

동일 배너 내에서 image_variant는 중복되지 않도록 관리하는 것을 권장한다. (예: PC 이미지 1건, MOBILE 이미지 1건)





6. 연관 테이블 관계

테이블

관계

설명

event_banner

1:N

배너별 이미지 매핑

event_image_file

N:1

이미지 파일 메타데이터





7. 사용 예시 (개념)

예시: 메인 홈 배너 이미지 구성

event_banner

SHOP / ALL / HOME

event_banner_image

ORIGINAL

PC

MOBILE

→ 하나의 배너에 대해 디바이스별 최적화 이미지 제공 가능





8. 비고

이미지 변형 정책(자동 리사이징 / 수동 업로드)은 애플리케이션 로직에서 결정한다.

신규 디바이스 유형 추가 시, 코드 데이터만 확장하면 된다.

본 테이블은 배너 이미지 관리의 확장 지점(extension point) 역할을 한다.





9. 요약

event_banner_image 테이블은 이벤트 배너와 이미지 파일을 연결하고, 이미지의 변형 유형을 정의하는 매핑 테이블로서, 배너 정책과 파일 자산을 분리하여 유연한 이미지 관리 구조를 제공한다.





DDL

CREATE TABLE event_banner_image (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_banner_id     BIGINT NOT NULL REFERENCES event_banner(id),
    event_file_id       BIGINT NOT NULL REFERENCES event_image_file(id),
    image_variant       VARCHAR(30) NOT NULL,
    created_at          TIMESTAMP NOT NULL,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    updated_by          BIGINT NOT NULL
);


COMMENT ON TABLE event_banner_image IS '이벤트 배너와 이미지 파일 매핑 테이블';
COMMENT ON COLUMN event_banner_image.id IS '배너 이미지 매핑 식별자(PK)';
COMMENT ON COLUMN event_banner_image.event_banner_id IS '이벤트 배너 식별자(FK)';
COMMENT ON COLUMN event_banner_image.event_file_id IS '이벤트 이미지 파일 식별자(FK)';
COMMENT ON COLUMN event_banner_image.image_variant IS '이미지 변형 유형 code_group(EVENT.variant : ORIGINAL: 원본, PC: PC용 리사이즈, MOBILE: 모바일용 리사이즈)';
COMMENT ON COLUMN event_banner_image.created_at IS '등록 일시';
COMMENT ON COLUMN event_banner_image.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_banner_image.updated_at IS '수정 일시';
COMMENT ON COLUMN event_banner_image.updated_by IS '수정자 식별자';