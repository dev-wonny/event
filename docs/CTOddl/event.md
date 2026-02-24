1. 테이블 개요

항목

내용

테이블명

event

논리명

이벤트 마스터

용도

이벤트의 기본 정보 및 운영 정책을 관리하는 마스터 테이블

성격

이벤트 도메인의 최상위 기준 테이블

PK

id (대체키, BIGINT IDENTITY)





2. 테이블 역할 및 책임

event 테이블은 이벤트 도메인의 기본 엔티티로서 다음 책임을 가진다.

이벤트의 기본 속성 관리 (이벤트명, 유형, 기간, 설명)

이벤트 운영 정책 관리 (전시 여부, 추천 여부, 자동 응모 여부 등)

당첨자 및 응모 관련 정책 관리

이벤트의 활성/비활성 및 우선순위 제어

이벤트 하위 테이블(배너, 이미지, 응모, 상품 등)의 기준 참조 테이블

⚠️ 배너, 이미지, 파일, 응모 데이터 등은 본 테이블에서 직접 관리하지 않으며 별도의 하위 테이블에서 관리한다.





3. 컬럼 정의

3.1 기본 식별자

컬럼명

타입

NULL

설명

id

BIGINT

N

이벤트 식별자 (PK, 대체키, IDENTITY)





3.2 이벤트 기본 정보

컬럼명

타입

NULL

설명

event_name

VARCHAR(100)

N

이벤트명

event_type

VARCHAR(30)

N

이벤트 구분 코드 code_group(EVENT.TYPE: 일반, 전시, 출석 등등)';

description

TEXT

Y

이벤트 상세 설명

gift_description

VARCHAR(100)

Y

증정 내용 설명

event_url

VARCHAR(300)

Y

이벤트 대표 URL 또는 쇼츠 URL





3.3 이벤트 기간 정보

컬럼명

타입

NULL

설명

start_at

TIMESTAMP

N

이벤트 시작 일시

end_at

TIMESTAMP

N

이벤트 종료 일시

이벤트 유효 기간은 start_at ≤ 현재시각 ≤ end_at 조건으로 판단한다.





3.4 이벤트 상태 및 전시 정책

컬럼명

타입

NULL

설명

is_active

BOOLEAN

N

이벤트 사용 여부

is_visible

BOOLEAN

N

이벤트 전시 여부

is_recommended

BOOLEAN

N

추천 이벤트 여부

priority

INTEGER

Y

전시 우선순위 (낮을수록 우선 노출)





3.5 응모 및 승인 정책

컬럼명

타입

NULL

설명

is_auto_entry

BOOLEAN

N

자동 응모 여부

is_confirmed

BOOLEAN

N

이벤트 승인 여부

is_sns_linked

BOOLEAN

N

SNS 연계 사용 여부





3.6 당첨자 정책

컬럼명

타입

NULL

설명

is_winner_announced

BOOLEAN

N

당첨자 발표 여부

winner_announced_at

TIMESTAMP

Y

당첨자 발표 일시

allow_duplicate_winner

BOOLEAN

N

당첨자 중복 허용 여부

allow_multiple_entry

BOOLEAN

N

복수 응모 허용 여부

winner_selection_cycle

TIMESTAMP

Y

당첨자 선정 주기

winner_selection_base_at

TIMESTAMP

Y

당첨자 선정 기준 일시





3.7 업체 및 관리 정보

컬럼명

타입

NULL

설명

supplier_id

BIGINT

N

이벤트 주관 업체 식별자





3.8 이력 관리 컬럼

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





4. 주요 제약 및 설계 규칙

4.1 기본 제약

PK: id

모든 BOOLEAN 컬럼은 명시적으로 값이 존재해야 한다.

이벤트 기간은 반드시 시작일 ≤ 종료일이어야 한다. (CHECK 제약 또는 애플리케이션 검증)





4.2 코드 컬럼 규칙

컬럼

코드 그룹

event_type

EVENT / TYPE

코드 값은 공통 코드 테이블(code_group, code_detail)을 기준으로 관리한다.





5. 연관 테이블 관계

테이블

관계

설명

event_banner

1:N

이벤트별 배너 정책

event_banner_image

1:N

이벤트 배너 이미지

event_image_file

N:M

이벤트 이미지 파일

event_entry

1:N

이벤트 응모 정보 (예정)

event_winner

1:N

이벤트 당첨자 정보 (예정)





6. 비고

본 테이블은 이벤트 도메인의 기준 테이블이며, 이벤트와 관련된 모든 하위 데이터는 event.id를 기준으로 참조한다.

배너/이미지/파일 정보는 본 테이블에 컬럼 추가하지 않는다.

운영 정책 변경 시 본 테이블의 스키마 변경 여부를 우선 검토한다.



DDL


CREATE TABLE event (
    id                          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_name                  VARCHAR(100) NOT NULL,
    event_type                  VARCHAR(30) NOT NULL,
    start_at                    TIMESTAMP NOT NULL,
    end_at                      TIMESTAMP NOT NULL,
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
    is_displayed                BOOLEAN NOT NULL,
    is_recommended              BOOLEAN NOT NULL,
    is_auto_entry               BOOLEAN NOT NULL,
    is_confirmed                BOOLEAN NOT NULL,
    is_sns_linked               BOOLEAN NOT NULL DEFAULT FALSE,
    event_url                   VARCHAR(300),
    description                 TEXT,
    gift_description            VARCHAR(100),
    supplier_id                 BIGINT NOT NULL,
    is_winner_announced         BOOLEAN NOT NULL,
    winner_announced_at         TIMESTAMP,
    allow_duplicate_winner      BOOLEAN NOT NULL,
    allow_multiple_entry        BOOLEAN NOT NULL,
    winner_selection_cycle      TIMESTAMP,
    winner_selection_base_at    TIMESTAMP,
    priority                    INTEGER,
    created_at                  TIMESTAMP NOT NULL,
    created_by                  BIGINT NOT NULL,
    updated_at                  TIMESTAMP NOT NULL,
    updated_by                  BIGINT NOT NULL
);



COMMENT ON TABLE event IS '이벤트 마스터';
COMMENT ON COLUMN event.id IS '이벤트 식별자(PK, 대체키)';
COMMENT ON COLUMN event.event_name IS '이벤트명';
COMMENT ON COLUMN event.event_type IS '이벤트 구분 코드 code_group(domain:EVENT/group_code:TYPE)';
COMMENT ON COLUMN event.start_at IS '이벤트 시작 일시';
COMMENT ON COLUMN event.end_at IS '이벤트 종료 일시';
COMMENT ON COLUMN event.is_active IS '이벤트 사용 여부';
COMMENT ON COLUMN event.is_displayed IS '전시 여부';
COMMENT ON COLUMN event.is_recommended IS '추천 이벤트 여부';
COMMENT ON COLUMN event.is_auto_entry IS '자동 응모 여부';
COMMENT ON COLUMN event.is_confirmed IS '이벤트 승인 여부';
COMMENT ON COLUMN event.is_sns_linked IS 'SNS 연계 사용 여부';
COMMENT ON COLUMN event.event_url IS '이벤트 URL';
COMMENT ON COLUMN event.description IS '이벤트 상세 설명';
COMMENT ON COLUMN event.gift_description IS '증정 내용';
COMMENT ON COLUMN event.supplier_id IS '업체번호';
COMMENT ON COLUMN event.is_winner_announced IS '당첨자 발표 여부';
COMMENT ON COLUMN event.winner_announced_at IS '당첨자 발표 일시';
COMMENT ON COLUMN event.allow_duplicate_winner IS '당첨자 중복 허용 여부';
COMMENT ON COLUMN event.allow_multiple_entry IS '복수 응모 허용 여부';
COMMENT ON COLUMN event.winner_selection_cycle IS '당첨자 선정 주기';
COMMENT ON COLUMN event.winner_selection_base_at IS '당첨자 선정 기준 일시';
COMMENT ON COLUMN event.priority IS '전시 우선순위';
COMMENT ON COLUMN event.created_at IS '등록 일시';
COMMENT ON COLUMN event.created_by IS '등록자 식별자';
COMMENT ON COLUMN event.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event.updated_by IS '최종 수정자 식별자';

