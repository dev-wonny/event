

1. 테이블 개요

항목

내용

테이블명

event_draw_round

논리명

이벤트 추첨 회차

용도

이벤트별 추첨 회차 및 추첨 대상 기간/실행/발표/확정 상태 관리

성격

이벤트 하위 추첨 회차(스케줄/상태) 관리 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → event.id





2. 테이블 역할 및 책임

event_draw_round 테이블은 이벤트에 대해 추첨 회차(1차, 2차, 재추첨 등) 정보를 관리한다.

주요 책임

이벤트 내 추첨 회차 단위 기준 데이터 관리

회차별 추첨 대상 기간(draw_start_at ~ draw_end_at) 관리

추첨 실행 시점(draw_at) 및 발표 시점(announcement_at) 관리

회차별 당첨 확정 여부(is_confirmed) 관리

추첨/당첨 처리(event_win)를 위한 기준 데이터 제공



추첨 “대상(사람/응모)” 자체는 본 테이블이 저장하지 않는다.

추첨 대상은 event_applicant(참여자 기준) 및 event_entry(응모 이력)를 통해 구성된다.



3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 추첨 ID

BIGINT

N

IDENTITY

이벤트 추첨 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자(FK)

draw_no

추첨 회차 번호

INTEGER

N



이벤트 내 추첨 회차(업무 식별자)

is_confirmed

당첨 확정 여부

BOOLEAN

N

FALSE

당첨자 확정 여부

draw_at

추첨 실행 일시

TIMESTAMP

Y



추첨 실행 시점

draw_start_at

추첨 대상 시작 일시

TIMESTAMP

Y



추첨 대상 기간 시작

draw_end_at

추첨 대상 종료 일시

TIMESTAMP

Y



추첨 대상 기간 종료

announcement_at

당첨 발표 일시

TIMESTAMP

Y



당첨자 발표 일시

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

본 테이블은 코드 테이블을 참조하는 컬럼을 포함하지 않는다.

상태/여부는 BOOLEAN 컬럼(is_confirmed, is_deleted)으로 관리한다.





5. 주요 설계 규칙 및 제약

5.1 제약 조건



구분

내용

Primary Key

id

Unique Key

(event_id, draw_no)

Foreign Key

event_id → event.id



5.2 설계 규칙

이벤트는 다수의 추첨 회차를 가질 수 있다. (1차/2차/재추첨 등)

draw_no는 이벤트 내에서 회차를 구분하는 업무 식별자이며 이벤트 범위 내 유일해야 한다.

추첨 실행 전/후 상태 관리를 위해 is_confirmed, draw_at, announcement_at를 사용한다.

본 테이블은 물리 삭제 금지, 논리 삭제(is_deleted)를 기본으로 한다.





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

하나의 이벤트는 여러 추첨 회차를 가질 수 있음

event_applicant

1 : N

추첨 대상이 되는 이벤트 참여자 기준(중복 참여/대상 집합의 기준)

event_entry

1 : N

추첨/선정의 근거가 되는 응모 이력(행위 로그)

event_win

1 : N

회차별 당첨 결과 및 후속 처리(지급/발송/수령 등)

추첨 대상 집합은 event_applicant를 기준으로 형성되므로 연관 테이블에 포함되어야 한다.





7. 사용 예시 (개념)

예시 1) 1차 추첨 회차 등록

이벤트 1001의 1차 추첨 대상 기간: 1/1~1/7

event_id

draw_no

draw_start_at

draw_end_at

is_confirmed

1001

1

2026-01-01 00:00

2026-01-07 23:59

FALSE



예시 2) 1차 추첨 실행 및 발표

추첨 실행 후 발표일 등록, 확정 처리

event_id

draw_no

draw_at

announcement_at

is_confirmed

1001

1

2026-01-08 10:00

2026-01-09 09:00

TRUE





8. 비고

event_draw_round는 추첨 회차의 스케줄/상태 기준을 관리한다.

추첨 대상은 event_applicant/event_entry를 기준으로 구성되며, 본 테이블에 대상자 리스트를 저장하지 않는다.

당첨 결과 및 지급/발송/수령 등 후속 처리 데이터는 event_win에서 관리한다.





9. 요약

event_draw_round는 이벤트별 추첨 회차 기준 정보를 관리하며, 대상 기간·실행·발표·확정 상태를 통합 관리하는 추첨 운영의 기준 테이블이다.

추첨 대상 집합은 event_applicant와 event_entry를 통해 구성된다.





DDL

CREATE TABLE event_draw_round (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id         BIGINT NOT NULL REFERENCES event(id),
    draw_no          INTEGER NOT NULL,
    is_confirmed     BOOLEAN NOT NULL DEFAULT FALSE,
    draw_at          TIMESTAMP,
    draw_start_at    TIMESTAMP,
    draw_end_at      TIMESTAMP,
    announcement_at  TIMESTAMP,
    is_deleted       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at       TIMESTAMP NOT NULL,
    created_by       BIGINT NOT NULL,
    updated_at       TIMESTAMP NOT NULL,
    updated_by       BIGINT NOT NULL,
    deleted_at       TIMESTAMP NULL,
    UNIQUE (event_id, draw_no)
);

COMMENT ON TABLE event_draw IS '이벤트 추첨 회차';

COMMENT ON COLUMN event_draw_round.id IS '이벤트 추첨 식별자(PK, 대체키)';
COMMENT ON COLUMN event_draw_round.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_draw_round.draw_no IS '이벤트 내 추첨 회차 번호';
COMMENT ON COLUMN event_draw_round.is_confirmed IS '당첨자 확정 여부';
COMMENT ON COLUMN event_draw_round.draw_at IS '추첨 실행 일시';
COMMENT ON COLUMN event_draw_round.draw_start_at IS '추첨 대상 기간 시작 일시';
COMMENT ON COLUMN event_draw_round.draw_end_at IS '추첨 대상 기간 종료 일시';
COMMENT ON COLUMN event_draw_round.announcement_at IS '당첨자 발표 일시';
COMMENT ON COLUMN event_draw_round.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_draw_round.created_at IS '등록 일시';
COMMENT ON COLUMN event_draw_round.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_draw_round.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_draw_round.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_draw_round.deleted_at IS '삭제 일시(논리 삭제 시)';



