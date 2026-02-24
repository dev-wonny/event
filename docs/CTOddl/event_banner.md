

1. 테이블 개요

항목

내용

테이블명

event_banner

논리명

이벤트 배너

용도

이벤트 배너의 노출 정책(채널, 디바이스, 위치, 링크)을 관리

성격

이벤트 도메인 하위 정책 테이블

PK

id (BIGINT IDENTITY)

FK

event_id





2. 테이블 역할 및 책임

event_banner 테이블은 이벤트에 노출되는 배너 단위의 정책 정보를 관리한다.

이벤트별 배너 노출 채널 관리 (커머스 샵, 돌쇠마당 등)

배너 노출 대상 디바이스 정책 관리 (PC / MOBILE / ALL)

배너 노출 위치 관리 (메인 홈, 상품 상세 등)

배너 클릭 시 이동할 링크 URL 관리

배너 노출 우선순위 및 활성/비활성 제어

⚠️ 본 테이블은 이미지 파일 자체를 관리하지 않는다.

배너 이미지 파일 및 변형 정보는 event_banner_image, event_image_file 테이블에서 관리한다.

책임 분리

event_banner는 배너 노출 정책(채널·디바이스·위치·링크)만 관리

이미지 파일은 리소스 자산이므로 별도 테이블에서 관리



확장성

PC/모바일/원본 등 다중 이미지 및 변형을 컬럼 추가 없이 수용

이미지 규격·포맷 변경 시 정책 테이블 스키마 영향 없음



AWS S3 구조와 정합

파일은 S3에 저장, DB에는 파일 메타데이터만 관리

파일 정보는 event_image_file의 책임



재사용 및 중복 제거

하나의 이미지 파일을 여러 배너에서 참조 가능

파일 교체·관리 범위가 명확



조회·서빙 로직 단순화

정책 판단 → 이미지 선택 → 파일 서빙의 단계적 처리 가능

배너 정책과 이미지 자산을 분리하여 유지보수성과 확장성을 확보한다.



3. 컬럼 정의

3.1 식별자 및 관계

컬럼명

타입

NULL

설명

id

BIGINT

N

이벤트 배너 식별자 (PK)

event_id

BIGINT

N

이벤트 식별자 (FK)





3.2 배너 노출 정책 정보

컬럼명

타입

NULL

설명

channel_type

VARCHAR(30)

N

배너 노출 채널 코드code_group(EVENT.CHANNEL)예: SHOP, DOLS

device_type

VARCHAR(30)

N

배너 타겟 디바이스 정책 코드code_group(EVENT.DEVICE)예: ALL, PC, MOBILE

display_location

VARCHAR(30)

N

배너 노출 위치 코드code_group(EVENT.LOCATION)예: HOME, PRODUCT





3.3 배너 링크 및 노출 제어

컬럼명

타입

NULL

설명

link_url

VARCHAR(500)

N

배너 클릭 시 이동할 URL

priority

INTEGER

N

배너 노출 우선순위 (값이 낮을수록 우선 노출)

is_active

BOOLEAN

N

배너 활성 여부

is_visible

BOOLEAN

N

전시 여부





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





4. 코드 컬럼 정의

컬럼명

코드 도메인

코드 그룹

설명

channel_type

EVENT

CHANNEL

배너 노출 채널

device_type

EVENT

DEVICE

배너 타겟 디바이스 정책

display_location

EVENT

LOCATION

배너 노출 위치

모든 코드 값은 공통 코드 테이블(code_group, code_detail)을 기준으로 관리한다.





5. 주요 설계 규칙 및 제약

5.1 기본 제약

PK: id

FK: event_id 

priority는 0 이상의 정수 값을 권장한다.

is_active = false인 배너는 프론트 노출 대상에서 제외한다.





5.2 배너 노출 판단 기준 (논리 규칙)

배너는 다음 조건을 모두 만족할 때 노출 대상이 된다.

연결된 이벤트(event)가 활성 상태일 것

event_banner.is_active = true

요청 채널이 channel_type과 일치할 것

요청 디바이스가 device_type 정책에 포함될 것

요청 위치가 display_location과 일치할 것





6. 연관 테이블 관계

테이블

관계

설명

event

N:1

배너가 소속된 이벤트

event_banner_image

1:N

배너별 이미지 매핑

event_image_file

N:M

배너 이미지 파일 메타데이터





7. 비고

배너 정책은 이벤트 단위가 아닌 “배너 단위”로 관리한다.

하나의 이벤트는 여러 개의 배너 정책을 가질 수 있다.

배너 이미지 변경 시 본 테이블은 수정하지 않는다.





DDL

CREATE TABLE event_banner (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id            BIGINT NOT NULL REFERENCES event(id),
    channel_type        VARCHAR(30) NOT NULL,
    device_type         VARCHAR(30) NOT NULL,
    display_location    VARCHAR(30) NOT NULL,
    link_url            VARCHAR(500) NOT NULL,
    priority            INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMP NOT NULL,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    updated_by          BIGINT NOT NULL
);


COMMENT ON TABLE event_banner IS '이벤트 배너 노출 정책 테이블';
COMMENT ON COLUMN event_banner.id IS '이벤트 배너 식별자(PK)';
COMMENT ON COLUMN event_banner.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_banner.channel_type IS '배너 노출 채널 코드 code_group(EVENT.CHANNEL: SHOP, DOLS)';
COMMENT ON COLUMN event_banner.device_type IS '배너 타겟 디바이스 정책 code_group(EVENT.DEVICE: ALL, PC, MOBILE)';
COMMENT ON COLUMN event_banner.display_location IS '배너 노출 위치 코드 code_group(EVENT.LOCATION: HOME, PRODUCT)';
COMMENT ON COLUMN event_banner.link_url IS '배너 클릭 시 이동 URL';
COMMENT ON COLUMN event_banner.priority IS '배너 노출 우선순위 (낮을수록 우선)';
COMMENT ON COLUMN event_banner.is_active IS '배너 활성 여부';
COMMENT ON COLUMN event_banner.created_at IS '등록 일시';
COMMENT ON COLUMN event_banner.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_banner.updated_at IS '수정 일시';
COMMENT ON COLUMN event_banner.updated_by IS '수정자 식별자';