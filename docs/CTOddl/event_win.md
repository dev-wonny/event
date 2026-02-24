1. 테이블 개요

항목

내용

테이블명

event_win

논리명

이벤트 당첨 및 경품 지급

용도

이벤트 당첨 결과 및 경품 발송/수령/안내 상태 관리

성격

이벤트 당첨 결과 및 후속 처리 이력 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → event.id





2. 테이블 역할 및 책임

event_win 테이블은 이벤트 추첨 결과로 당첨된 사용자에 대한 최종 결과와 후속 처리 상태를 관리한다.



 주요 책임

이벤트 추첨 결과에 따른 당첨자 관리

당첨 경품(prize)과의 매핑

경품 발송/수령 상태 관리

당첨 안내(이메일, SMS) 발송 이력 관리

회원별 당첨 확정 시점 관리

이벤트 이력 보존 및 감사(Audit) 대응



본 테이블은 이벤트 도메인에서 가장 최종 단계의 결과 테이블이다.





3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 당첨 ID

BIGINT

N

IDENTITY

이벤트 당첨 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자

member_id

회원 ID

BIGINT

N



당첨자(회원) 식별자

draw_id

추첨 회차 ID

BIGINT

N



이벤트 추첨 회차 식별자

entry_id

응모 ID

BIGINT

N



이벤트 응모 식별자

prize_id

경품 ID

BIGINT

Y



당첨 경품 식별자

sent_at

발송 일자

DATE

Y



경품 발송 일자

is_sent

발송 여부

BOOLEAN

N

FALSE

경품 발송 여부

received_at

수령 일자

DATE

Y



경품 수령 일자

is_received

수령 여부

BOOLEAN

Y



경품 수령 여부

is_email_sent

이메일 발송 여부

BOOLEAN

N

FALSE

당첨 안내 이메일 발송 여부

is_sms_sent

SMS 발송 여부

BOOLEAN

N

FALSE

당첨 안내 SMS 발송 여부

confirmed_at

당첨 확정 일시

TIMESTAMP

Y



회원별 당첨 확정 일시

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

상태 관리 컬럼은 BOOLEAN으로 명확히 표현한다.

발송/수령/안내 여부는 각각 독립적으로 관리한다.





5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id

Unique Key

(event_id, member_id, draw_id, entry_id)

Foreign Key

event_id → event.id





5.2 설계 규칙

하나의 응모(event_entry)는 최대 1건의 당첨 결과를 가진다.

is_sent, is_received는 실제 처리 완료 여부를 기준으로 갱신한다.

안내 발송(is_email_sent, is_sms_sent)은 발송 시점과 무관하게 성공 여부 기준이다.

본 테이블은 물리 삭제를 금지하고 논리 삭제 정책을 따른다.





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

이벤트별 당첨 결과

event_draw

1 : N

추첨 회차별 당첨 결과

event_entry

1 : 1

응모 이력에 대한 당첨 결과

event_prize

1 : N

경품별 당첨 결과

prize

1 : N

실제 경품 마스터 정보





7. 사용 예시 (개념)

예시 1. 이벤트 당첨 결과 생성

event_id

member_id

draw_id

entry_id

prize_id

1001

20001

1

15

3

→ 이벤트 1001의 1차 추첨에서 회원 20001이 경품 3번에 당첨





예시 2. 경품 발송 및 수령 처리

경품 발송 완료 → is_sent = TRUE, sent_at 기록

경품 수령 완료 → is_received = TRUE, received_at 기록

경품 구분에 따라 데이타 입력 시점이 달라진다.





8. 비고

event_win은 이벤트 운영에서 가장 중요하고 민감한 데이터를 포함한다.

정산, CS, 감사 대응을 위해 수정 이력 관리가 필수적이다.

추후 오프라인 지급, 외부 시스템 연동 시 확장 컬럼 추가 가능성이 있다.





9. 요약

event_win은 이벤트 추첨 결과로 발생한 당첨 정보와 경품 지급 전 과정을 관리하는 최종 결과 테이블이다.

이벤트 운영, 사용자 안내, 경품 지급의 모든 상태를 단일 테이블에서 추적할 수 있도록 설계되었다.





DDL

CREATE TABLE event_win (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL,
    member_id       BIGINT NOT NULL,
    draw_id         BIGINT NOT NULL,
    entry_id        BIGINT NOT NULL,
    prize_id        BIGINT,
    sent_at         DATE,
    is_sent         BOOLEAN NOT NULL DEFAULT FALSE,
    received_at     DATE,
    is_received     BOOLEAN,
    is_email_sent   BOOLEAN NOT NULL DEFAULT FALSE,
    is_sms_sent     BOOLEAN NOT NULL DEFAULT FALSE,
    confirmed_at    TIMESTAMP,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP NULL,
    UNIQUE (event_id, member_id, draw_id, entry_id)
);

ALTER TABLE event_win
FOREIGN KEY (event_id) REFERENCES event(id);

COMMENT ON TABLE event_win IS '이벤트 당첨 및 경품 지급 관리 테이블';
COMMENT ON COLUMN event_win.id IS '이벤트 당첨 식별자(PK, 대체키)';
COMMENT ON COLUMN event_win.event_id IS '이벤트 식별자';
COMMENT ON COLUMN event_win.member_id IS '당첨자(회원) 식별자';
COMMENT ON COLUMN event_win.draw_id IS '이벤트 추첨 회차 번호';
COMMENT ON COLUMN event_win.entry_id IS '이벤트 응모 번호';
COMMENT ON COLUMN event_win.prize_id IS '당첨 경품 번호';
COMMENT ON COLUMN event_win.sent_at IS '경품 발송 일자';
COMMENT ON COLUMN event_win.is_sent IS '경품 발송 여부';
COMMENT ON COLUMN event_win.received_at IS '경품 수령 일자';
COMMENT ON COLUMN event_win.is_received IS '경품 수령 여부';
COMMENT ON COLUMN event_win.is_email_sent IS '당첨 안내 이메일 발송 여부';
COMMENT ON COLUMN event_win.is_sms_sent IS '당첨 안내 SMS 발송 여부';
COMMENT ON COLUMN event_win.is_recorded IS '응모 이력 저장 여부';
COMMENT ON COLUMN event_win.confirmed_at IS '회원별 당첨 확정 일시';
COMMENT ON COLUMN event_win.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_win.created_at IS '등록 일시';
COMMENT ON COLUMN event_win.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_win.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_win.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_win.deleted_at IS '삭제 일시(논리 삭제 시)';





