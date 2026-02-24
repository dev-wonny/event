1. 테이블 개요

항목

내용

테이블명

prize

논리명

경품 마스터

용도

이벤트 및 기타 프로모션에서 사용되는 경품의 기본 정보 관리

성격

경품 도메인 마스터 테이블

PK

id (BIGINT IDENTITY)

FK

없음





2. 테이블 역할 및 책임

prize 테이블은 경품 자체의 정적(기본) 정보를 관리하는 마스터 테이블이다.



주요 책임

경품 명칭, 금액, 설명 등 기본 속성 관리

경품의 사용 가능 여부 및 유효 기간 관리

이벤트별 경품 정책(event_prize)의 기준 데이터 제공

경품 재사용 및 다수 이벤트에서의 공통 참조 지원



본 테이블은 이벤트 운영 정책이나 당첨 결과를 직접 관리하지 않는다.



3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

경품 ID

BIGINT

N

IDENTITY

경품 식별자(PK)

prize_name

경품명

VARCHAR(100)

N



경품명

prize_amount

경품 금액

INTEGER

Y



경품 금액(가격)

prize_description

경품 설명

TEXT

Y



경품 상세 설명

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

recipient_end_date

수령 유효 종료일

DATE

Y



경품 수령 유효 기간

usage_end_date

사용 유효 종료일

DATE

Y



경품 사용 유효 기간

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

경품 유형, 지급 방식 등 코드성 정보는

이벤트별 정책 테이블(event_prize) 또는 별도 확장 테이블에서 관리한다.







5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id





5.2 설계 규칙

본 테이블은 경품의 공통 마스터로 사용된다.

하나의 경품은 여러 이벤트에서 재사용될 수 있다.

물리 삭제를 하지 않고 논리 삭제(is_deleted) 정책을 적용한다.

유효 기간(recipient_end_date, usage_end_date)은 정책 판단용 기준 정보이며, 실제 지급/수령 여부는 결과 테이블에서 관리한다.





6. 연관 테이블 관계

테이블명

관계

설명

event_prize

1 : N

이벤트별 경품 정책에서 참조

event_win

1 : 0..N

당첨 결과 및 지급 이력에서 참조







7. 사용 예시 (개념)

예시 1. 경품 마스터 등록

prize_name

prize_amount

recipient_end_date

usage_end_date

스타벅스 기프티콘

5000

2026-03-31

2026-06-30

→ 여러 이벤트에서 공통으로 사용 가능한 경품 등록



예시 2. 이벤트 경품 정책에서 참조

이벤트 A, 이벤트 B에서 동일 prize.id를 참조

이벤트별 당첨 수량·우선순위는 event_prize에서 별도 관리





8. 비고

prize는 경품 자체의 정의에 집중한 마스터 테이블이다.

이벤트 운영 정책, 추첨 회차, 당첨 처리와 책임을 명확히 분리한다.

향후 이미지, 외부 연동 정보가 필요할 경우 확장 테이블 추가를 고려한다.





9. 요약

prize는 이벤트 및 프로모션에서 사용되는 경품의 기본 정보를 관리하는 마스터 테이블로, 이벤트별 경품 정책(event_prize)과 당첨 결과(event_win)의 기준 데이터 역할을 수행한다.





DDL



CREATE TABLE prize (
    id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prize_name            VARCHAR(100) NOT NULL,
    prize_amount          INTEGER,
    prize_description     TEXT,
    is_active             BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted            BOOLEAN NOT NULL DEFAULT FALSE,
    recipient_end_date    DATE,
    usage_end_date        DATE,
    created_at            TIMESTAMP NOT NULL,
    created_by            BIGINT NOT NULL,
    updated_at            TIMESTAMP NOT NULL,
    updated_by            BIGINT NOT NULL,
    deleted_at            TIMESTAMP NULL
);

COMMENT ON TABLE prize IS '경품 마스터 테이블';

COMMENT ON COLUMN prize.id IS '경품 식별자(PK, 대체키)';
COMMENT ON COLUMN prize.prize_name IS '경품명';
COMMENT ON COLUMN prize.prize_amount IS '경품 금액(가격)';
COMMENT ON COLUMN prize.prize_description IS '경품 상세 설명';
COMMENT ON COLUMN prize.is_active IS '경품 사용 여부';
COMMENT ON COLUMN prize.recipient_end_date IS '경품 수령 유효 기간';
COMMENT ON COLUMN prize.usage_end_date IS '경품 사용 유효 기간';
COMMENT ON COLUMN prize.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN prize.created_at IS '등록 일시';
COMMENT ON COLUMN prize.created_by IS '등록자 식별자';
COMMENT ON COLUMN prize.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN prize.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN prize.deleted_at IS '삭제 일시(논리 삭제 시)';



