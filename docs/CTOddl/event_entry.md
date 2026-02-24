1. 테이블 개요

항목

내용

테이블명

event_entry

논리명

이벤트 응모 이력

용도

이벤트에 대한 개별 응모 행위(이력) 관리

성격

이벤트 응모 행위 로그 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → event.id





2. 테이블 역할 및 책임

event_entry 테이블은 이벤트에 대한 개별 응모 행위 이력을 관리한다.



주요 책임

이벤트 응모 시점의 행위 로그 기록

응모 시점의 주문/구매 조건 스냅샷 저장

추첨(event_draw) 및 당첨(event_win) 처리를 위한 근거 데이터 제공

통계, 감사, CS 대응을 위한 이력 보존



본 테이블은 응모 “결과”가 아닌 응모 “행위” 자체를 기록하는 테이블이다.





3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 응모 ID

BIGINT

N

IDENTITY

이벤트 응모 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자(FK)

entry_id

응모 순번

INTEGER

N



이벤트 내 응모 순번

member_id

회원 ID

BIGINT

N



응모자(회원) 식별자

applied_at

응모 일시

TIMESTAMP

N



이벤트 응모 일시

order_no

주문 번호

VARCHAR(30)

Y



연관 주문 번호

prize_id

경품 ID

BIGINT

Y



당첨된 경품 식별자

is_winner

당첨 여부

BOOLEAN

N

FALSE

당첨 여부

purchase_amount

구매 금액

INTEGER

Y



응모 기준 구매 금액

order_count

주문 수량

INTEGER

Y



응모 기준 주문 수량

cancel_count

취소 수량

INTEGER

Y



응모 기준 취소 수량

description

비고

TEXT

Y



응모 관련 추가 설명

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

본 테이블은 코드 테이블을 직접 참조하는 컬럼을 포함하지 않는다.

당첨 여부, 삭제 여부는 BOOLEAN 컬럼으로 관리한다.

이벤트 유형, 추첨 유형 등은 상위 이벤트/추첨 테이블에서 관리한다.





5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id

Unique Key

(event_id, entry_id, member_id)

Foreign Key

event_id → event.id

※ 이벤트 내 동일 응모 순번(entry_id)은 회원 단위로 유일해야 한다.





5.2 설계 규칙

event_entry는 물리 삭제를 하지 않고 논리 삭제 정책을 따른다.

응모 이력은 생성 이후 수정되지 않는 것을 원칙으로 하며, 상태 변경은 상위(추첨/당첨) 테이블에서 관리한다.

응모 행위의 주체 식별을 위해 member_id는 반드시 유지한다.





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

하나의 이벤트는 여러 응모 이력을 가질 수 있음

event_applicant

1 : N

응모 이력의 참여자 기준

event_draw

1 : N

추첨 대상 응모 이력

event_win

1 : 0..N

응모 이력에 대한 당첨 결과





7. 사용 예시 (개념)

예시 1. 이벤트 응모 이력 생성

event_id

entry_id

member_id

applied_at

1001

1

20001

2026-01-05 10:30

→ 회원 20001이 이벤트 1001에 1번째 응모



예시 2. 구매 조건 기반 응모

purchase_amount

order_count

cancel_count

50000

1

0

→ 5만원 이상 구매 조건 충족으로 응모





8. 비고

event_entry는 이벤트 응모 처리의 가장 핵심적인 로그 테이블이다.

통계/분석/CS 조회 시 가장 빈번하게 사용된다.

당첨 여부(is_winner)는 추첨/확정 결과를 빠르게 조회하기 위한 보조 컬럼이다.





9. 요약

event_entry는 이벤트에 대한 개별 응모 행위를 이력 형태로 기록하며, 추첨·당첨·통계 처리의 근거가 되는 핵심 로그 테이블이다.





DDL

CREATE TABLE event_entry (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    entry_id        INTEGER NOT NULL,
    member_id       BIGINT NOT NULL,
    applied_at      TIMESTAMP NOT NULL,
    order_no        VARCHAR(30),
    prize_id        BIGINT,
    is_winner       BOOLEAN NOT NULL DEFAULT FALSE,
    purchase_amount INTEGER,
    order_count     INTEGER,
    cancel_count    INTEGER,
    description     TEXT,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP NULL,
    UNIQUE (event_id, entry_id, member_id)
);

COMMENT ON TABLE event_entry IS '이벤트 응모 이력';

COMMENT ON COLUMN event_entry.id IS '이벤트 응모 식별자(PK, 대체키)';
COMMENT ON COLUMN event_entry.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_entry.entry_id IS '이벤트 내 응모 순번';
COMMENT ON COLUMN event_entry.member_id IS '응모자(회원) 식별자';
COMMENT ON COLUMN event_entry.applied_at IS '이벤트 응모 일시';
COMMENT ON COLUMN event_entry.order_no IS '연관 주문 번호';
COMMENT ON COLUMN event_entry.prize_id IS '당첨된 경품 식별자';
COMMENT ON COLUMN event_entry.is_winner IS '당첨 여부';
COMMENT ON COLUMN event_entry.purchase_amount IS '응모 기준 구매 금액';
COMMENT ON COLUMN event_entry.order_count IS '응모 기준 주문 수량';
COMMENT ON COLUMN event_entry.cancel_count IS '응모 기준 취소 수량';
COMMENT ON COLUMN event_entry.description IS '응모 관련 추가 설명 또는 메모';
COMMENT ON COLUMN event_entry.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_entry.created_at IS '등록 일시';
COMMENT ON COLUMN event_entry.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_entry.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_entry.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_entry.deleted_at IS '삭제 일시(논리 삭제 시)';





