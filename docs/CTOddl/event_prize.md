1. 테이블 개요

항목

내용

테이블명

event_prize

논리명

이벤트 경품 정책

용도

이벤트별 경품 구성 및 당첨 가능 수, 우선순위 관리

성격

이벤트 하위 경품 정책 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → evnet.id





2. 테이블 역할 및 책임

event_prize 테이블은 하나의 이벤트에 대해 경품 단위의 정책 정보를 관리한다.

주요 책임

이벤트별 경품 구성 관리

경품별 당첨 가능 최대 수량(prize_limit) 관리

경품 간 우선순위(priority) 관리

경품 사용 여부 및 정책 변경 관리

추첨(event_draw) 및 당첨(event_win) 처리 시 경품 선정 기준 데이터 제공



실제 당첨자 정보, 지급 상태, 세무 처리 이력은 event_win 테이블에서 관리한다.





3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 경품 ID

BIGINT

N

IDENTITY

이벤트 경품 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자(FK)

prize_no

경품 번호

INTEGER

N



이벤트 내 경품 번호

prize_type

경품 유형

VARCHAR(30)

N



경품 유형 코드

prize_limit

당첨 가능 수

INTEGER

N



해당 경품의 당첨 가능 최대 인원 수

priority

우선순위

INTEGER

N



경품 우선순위(낮을수록 우선)

tax_amount

제세공과금

INTEGER

Y



경품 관련 제세공과금 금액

is_active

사용 여부

BOOLEAN

N

TRUE

경품 사용 여부

is_deleted

삭제 여부

BOOLEAN

N

FALSE

논리 삭제 여부

created_at

등록 일시

TIMESTAMP

N



등록 일시

created_by

등록자

BIGINT

N



등록자 식별자

updated_at

수정 일시

TIMESTAMP

N



최종 수정 일시

updated_by

수정자

BIGINT

N



최종 수정자 식별자

deleted_at

삭제 일시

TIMESTAMP

Y



논리 삭제 일시





4. 코드 컬럼 정의

컬럼명

코드 도메인

코드 그룹

설명

prize_type

EVENT

PRIZE_TYPE

경품 유형 코드 (예: PRODUCT, COUPON, POINT 등)

코드 값은 공통 코드 테이블에서 관리하며, 본 테이블에는 코드 값만 저장한다.



5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id

Unique Key

(event_id, prize_no)

Foreign Key

event_id → event.id





5.2 설계 규칙

하나의 이벤트는 여러 개의 경품 정책을 가질 수 있다.

prize_no는 이벤트 내에서 경품을 구분하는 업무 식별자이다.

prize_limit은 경품별 최대 당첨 가능 수량을 의미하며, 당첨 처리 시 초과할 수 없다.

priority 값이 낮을수록 당첨 우선순위가 높다.

본 테이블은 물리 삭제를 하지 않고 논리 삭제 정책을 따른다.





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

이벤트별 경품 정책

prize

1 : N

경품 마스터 – 이벤트별 경품 정책의 기준

event_win

1 : 0..N

경품별 당첨 결과 및 지급 관리





7. 사용 예시 (개념)

예시 1. 이벤트 경품 정책 구성

event_id

prize_no

prize_type

prize_limit

priority

1001

1

PRODUCT

10

1

1001

2

COUPON

100

2

→ 이벤트 1001은 경품 2종을 운영하며, 1번 경품이 우선 선정 대상





예시 2. 경품 소진 기준

prize_no = 1의 당첨자 수가 prize_limit(10) 도달 시

해당 경품은 더 이상 당첨 대상에서 제외





8. 비고

event_prize는 이벤트 경품 운영의 정책 기준 테이블이다.

실제 경품 지급, 제세공과금 처리, 수령 여부는 event_win에서 관리한다.

경품 정책 변경 시에도 당첨 이력에는 영향을 주지 않는다.





9. 요약

event_prize는 이벤트별 경품 구성과 당첨 정책을 정의하는 테이블로, 경품 수량·우선순위·유형을 기준으로 추첨 및 당첨 처리를 제어한다.





DDL

CREATE TABLE event_prize (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    prize_no        INTEGER NOT NULL,
    prize_type      VARCHAR(30) NOT NULL,
    prize_limit     INTEGER NOT NULL,
    priority        INTEGER NOT NULL,
    tax_amount      INTEGER,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP NULL,
    UNIQUE (event_id, prize_no)
);

COMMENT ON TABLE event_prize IS '이벤트 경품 정책 테이블';

COMMENT ON COLUMN event_prize.id IS '이벤트 경품 식별자(PK, 대체키)';
COMMENT ON COLUMN event_prize.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_prize.prize_no IS '이벤트 내 경품 번호';
COMMENT ON COLUMN event_prize.prize_type IS '경품 유형 코드 code_group(domain:EVENT, group_code:PRIZE_TYPE)';
COMMENT ON COLUMN event_prize.prize_limit IS '해당 경품의 당첨 가능 최대 인원 수';
COMMENT ON COLUMN event_prize.priority IS '경품 우선순위(낮을수록 우선)';
COMMENT ON COLUMN event_prize.tax_amount IS '경품 관련 제세공과금 금액';
COMMENT ON COLUMN event_prize.is_active IS '경품 사용 여부';
COMMENT ON COLUMN event_prize.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_prize.created_at IS '등록 일시';
COMMENT ON COLUMN event_prize.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_prize.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_prize.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_prize.deleted_at IS '삭제 일시(논리 삭제 시)';

