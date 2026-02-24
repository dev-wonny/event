1. 테이블 개요

항목

내용

테이블명

event_sns

논리명

이벤트 SNS 공유 정보

용도

이벤트의 SNS 공유 콘텐츠 및 채널별 공유 정보 관리

성격

이벤트 하위 SNS 공유 정책 테이블

PK

id (BIGINT IDENTITY)

FK

event_id → event.id





2. 테이블 역할 및 책임

event_sns 테이블은 이벤트를 외부 SNS 채널로 공유하기 위한 콘텐츠 정보를 관리한다.

주요 책임

SNS 채널별(카카오, 페이스북 등) 공유 콘텐츠 관리

이벤트별 SNS 공유 문구, 제목, 이미지 정보 관리

SNS 공유 시 이동할 대상 URL 관리

동일 이벤트에 대해 SNS 채널별 1건의 공유 정보 보장

본 테이블은 실제 SNS 전송 이력을 관리하지 않으며, 공유 시 사용되는 콘텐츠 정의(메타 정보)만을 담당한다.





3. 컬럼 정의

컬럼명

논리명

데이터 타입

NULL

기본값

설명

id

이벤트 SNS ID

BIGINT

N

IDENTITY

이벤트 SNS 정보 식별자(PK)

event_id

이벤트 ID

BIGINT

N



이벤트 식별자(FK)

sns_code

SNS 코드

VARCHAR(10)

N



SNS 구분 코드

title

SNS 제목

VARCHAR(200)

Y



SNS 공유 제목

content

SNS 내용

VARCHAR(1000)

N



SNS 공유용 상세 문구

sns_url

SNS URL

VARCHAR(200)

N



SNS 공유 시 이동할 이벤트 페이지 URL

image_url

이미지 URL

VARCHAR(200)

Y



SNS 공유용 이미지 URL

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

sns_code

EVENT

SNS

SNS 구분 코드 (예: KAKAO, FACEBOOK, INSTAGRAM 등)

코드 값은 공통 코드 테이블에서 관리하며, 본 테이블에는 코드 값만 저장한다.



5. 주요 설계 규칙 및 제약

5.1 제약 조건

구분

내용

Primary Key

id

Unique Key

(event_id, sns_code)

Foreign Key

event_id → event.id



5.2 설계 규칙

하나의 이벤트는 SNS 채널별 최대 1건의 공유 정보를 가진다.

SNS 전송 성공/실패 여부는 본 테이블에서 관리하지 않는다.

콘텐츠 변경 시에도 이력 보존을 위해 논리 삭제 정책을 따른다.





6. 연관 테이블 관계

테이블명

관계

설명

event

1 : N

하나의 이벤트는 여러 SNS 공유 정보를 가질 수 있음

(외부 SNS 시스템)

-

공유 실행 대상 (DB 관리 범위 외)



7. 사용 예시 (개념)

예시 1. 카카오톡 공유 정보 등록

event_id

sns_code

title

content

1001

KAKAO

설날 이벤트

지금 참여하고 경품 받으세요!

→ 이벤트 1001에 대한 카카오톡 공유 콘텐츠 정의



예시 2. SNS 채널별 콘텐츠 분리

sns_code

content

FACEBOOK

페이스북 전용 문구

INSTAGRAM

인스타그램 해시태그 포함 문구



8. 비고

event_sns는 SNS 공유 “정책/콘텐츠” 정의 테이블이다.

실제 공유 이력, 클릭 수, 성과 분석은 별도 로그/통계 테이블에서 관리한다.

이미지 URL은 외부 CDN 또는 S3 리소스를 참조한다. (이벤트 이미지 테이블 사용여부는 고민 중)



9. 요약

event_sns는 이벤트를 SNS로 공유하기 위한 채널별 콘텐츠 정보를 관리하는 테이블로, SNS 공유 시 사용되는 제목, 문구, 이미지, URL을 일관되게 제공한다.



DDL

CREATE TABLE event_sns (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL,
    sns_code        VARCHAR(10) NOT NULL,
    title           VARCHAR(200),
    content         VARCHAR(1000) NOT NULL,
    sns_url         VARCHAR(200) NOT NULL,
    image_url       VARCHAR(200),
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP NULL,
    UNIQUE (event_id, sns_code)
);

ALTER TABLE event_sns
FOREIGN KEY (event_id) REFERENCES event(id);

COMMENT ON TABLE event_sns IS '이벤트 SNS 공유 정보 테이블';
COMMENT ON COLUMN event_sns.id IS '이벤트 SNS 정보 식별자(PK, 대체키)';
COMMENT ON COLUMN event_sns.event_id IS '이벤트 식별자';
COMMENT ON COLUMN event_sns.sns_code IS 'SNS 구분 코드 code_group(domain:EVENT, group_code:SNS)';
COMMENT ON COLUMN event_sns.title IS 'SNS 공유 제목';
COMMENT ON COLUMN event_sns.content IS 'SNS 공유용 상세 문구';
COMMENT ON COLUMN event_sns.sns_url IS 'SNS 공유 시 이동할 이벤트 페이지 URL';
COMMENT ON COLUMN event_sns.image_url IS 'SNS 공유용 이미지 URL';
COMMENT ON COLUMN event_sns.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_sns.created_at IS '등록 일시';
COMMENT ON COLUMN event_sns.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_sns.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_sns.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_sns.deleted_at IS '삭제 일시(논리 삭제 시)';





