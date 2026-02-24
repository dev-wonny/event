1. 테이블 개요

항목

내용

테이블명

event_applicant

논리명

이벤트 응모자 기준

용도

이벤트에 참여(응모)한 사용자 기준 정보 관리

성격

이벤트 참여 기준(가드) 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → event.id





2. 테이블 역할 및 책임

event_applicant 테이블은 이벤트 단위로 응모에 참여한 사용자 기준 정보를 관리한다.

이벤트별 참여자 기준 관리

동일 이벤트 내 중복 응모 방지

실제 응모 이력(event_entry) 생성 전 참여 자격 판단

당첨 결과(event_win)의 논리적 상위 기준 데이터 제공



⚠️ 본 테이블은 정책/기준 성격의 테이블로, 응모 행위나 당첨 결과 자체는 저장하지 않는다.







3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 응모자 ID

BIGINT

N

IDENTITY

이벤트 응모자 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자(FK)

member_id

회원 ID

BIGINT

N



참여자(회원) 식별자

draw_id

추첨 ID

BIGINT

Y



연관된 이벤트 추첨 식별자

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

상태/여부 표현은 BOOLEAN 컬럼(is_deleted)으로 관리한다.

이벤트 유형, 추첨 유형 등 코드성 데이터는 상위/연관 테이블에서 관리한다.





5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id

Unique Key

(event_id, member_id)

Foreign Key

event_id → event.id





5.2 설계 규칙

동일 이벤트 내 동일 회원은 1건의 응모자 기준만 허용한다.

본 테이블은 물리 삭제를 수행하지 않으며, 논리 삭제(is_deleted)만 허용한다.

당첨 결과(event_win)와는 직접적인 FK를 두지 않는다. (이력 보존 및 운영 유연성 확보 목적)





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

하나의 이벤트는 여러 응모자 기준을 가질 수 있음

event_entry

1 : N

응모자 기준 1건은 여러 응모 이력을 가질 수 있음

event_win

1 : 0..N

응모자 기준 1건은 당첨 결과가 없거나 여러 건 존재 가능





7. 사용 예시 (개념)

예시 1. 이벤트 참여자 기준 생성

event_id

member_id

is_deleted

1001

20001

FALSE

→ 회원 20001은 이벤트 1001에 참여한 이력이 있음



예시 2. 중복 응모 방지 처리

동일 (event_id=1001, member_id=20001)로 추가 응모 요청 시

event_applicant 존재 여부로 응모 차단





8. 비고

event_applicant는 응모/당첨 이력의 기준 테이블로 사용된다.

실제 응모 행위(event_entry)와 결과(event_win)는 이 테이블을 참조하여 생성된다.

추후 비회원 응모, 외부 사용자 식별자 확장 시에도 기준 테이블로 활용 가능하다.





9. 요약

event_applicant는 이벤트 단위로 참여한 사용자 기준 정보를 관리하며, 중복 응모 방지와 참여 자격 판단을 위한 가드 역할을 수행하는 테이블이다.





DDL

CREATE TABLE event_applicant (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    member_id       BIGINT NOT NULL,
    draw_id         BIGINT,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP NULL,
    UNIQUE (event_id, member_id)
);

COMMENT ON TABLE event_applicant IS '이벤트 응모자 기준 테이블';
COMMENT ON COLUMN event_applicant.id IS '이벤트 응모자 식별자(PK)';
COMMENT ON COLUMN event_applicant.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_applicant.member_id IS '참여자(회원) 식별자';
COMMENT ON COLUMN event_applicant.draw_id IS '연관된 이벤트 추첨 식별자';
COMMENT ON COLUMN event_applicant.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_applicant.created_at IS '등록 일시';
COMMENT ON COLUMN event_applicant.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_applicant.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_applicant.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_applicant.deleted_at IS '논리 삭제 일시';





