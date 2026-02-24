-- =============================================================
-- 이벤트 도메인 개선 DDL
-- 기반: CTOddl 분석 + improvements.md 반영
-- 작성일: 2026-02-24
-- DB: PostgreSQL (BIGINT IDENTITY, COMMENT ON 구문 사용)
-- =============================================================

-- =============================================================
-- [1] prize (경품 마스터)
-- =============================================================
CREATE TABLE prize (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    prize_name          VARCHAR(100) NOT NULL,
    prize_amount        INTEGER,
    prize_description   TEXT,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    recipient_end_date  DATE,
    usage_end_date      DATE,
    created_at          TIMESTAMP NOT NULL,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    updated_by          BIGINT NOT NULL,
    deleted_at          TIMESTAMP
);

COMMENT ON TABLE prize IS '경품 마스터 테이블';
COMMENT ON COLUMN prize.id IS '경품 식별자(PK, 대체키)';
COMMENT ON COLUMN prize.prize_name IS '경품명';
COMMENT ON COLUMN prize.prize_amount IS '경품 금액(가격)';
COMMENT ON COLUMN prize.prize_description IS '경품 상세 설명';
COMMENT ON COLUMN prize.is_active IS '경품 사용 여부';
COMMENT ON COLUMN prize.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN prize.recipient_end_date IS '경품 수령 유효 종료일';
COMMENT ON COLUMN prize.usage_end_date IS '경품 사용 유효 종료일';
COMMENT ON COLUMN prize.created_at IS '등록 일시';
COMMENT ON COLUMN prize.created_by IS '등록자 식별자';
COMMENT ON COLUMN prize.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN prize.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN prize.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [2] event (이벤트 마스터)
-- 개선: is_visible → is_displayed 통일
--       winner_selection_cycle: TIMESTAMP → VARCHAR(30)
-- =============================================================
CREATE TABLE event (
    id                          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_name                  VARCHAR(100) NOT NULL,
    event_type                  VARCHAR(30) NOT NULL,
    start_at                    TIMESTAMP NOT NULL,
    end_at                      TIMESTAMP NOT NULL,
    is_active                   BOOLEAN NOT NULL DEFAULT TRUE,
    is_displayed                BOOLEAN NOT NULL DEFAULT TRUE,
    is_recommended              BOOLEAN NOT NULL DEFAULT FALSE,
    is_auto_entry               BOOLEAN NOT NULL DEFAULT FALSE,
    is_confirmed                BOOLEAN NOT NULL DEFAULT FALSE,
    is_sns_linked               BOOLEAN NOT NULL DEFAULT FALSE,
    event_url                   VARCHAR(300),
    description                 TEXT,
    gift_description            VARCHAR(100),
    supplier_id                 BIGINT NOT NULL,
    is_winner_announced         BOOLEAN NOT NULL DEFAULT FALSE,
    winner_announced_at         TIMESTAMP,
    allow_duplicate_winner      BOOLEAN NOT NULL DEFAULT FALSE,
    allow_multiple_entry        BOOLEAN NOT NULL DEFAULT FALSE,
    winner_selection_cycle      VARCHAR(30),
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
COMMENT ON COLUMN event.event_type IS '이벤트 구분 코드 code_group(domain:EVENT, group_code:TYPE)';
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
COMMENT ON COLUMN event.supplier_id IS '이벤트 주관 업체 식별자';
COMMENT ON COLUMN event.is_winner_announced IS '당첨자 발표 여부';
COMMENT ON COLUMN event.winner_announced_at IS '당첨자 발표 일시';
COMMENT ON COLUMN event.allow_duplicate_winner IS '당첨자 중복 허용 여부';
COMMENT ON COLUMN event.allow_multiple_entry IS '복수 응모 허용 여부';
COMMENT ON COLUMN event.winner_selection_cycle IS '당첨자 선정 주기 code_group(domain:EVENT, group_code:SELECTION_CYCLE: DAILY, WEEKLY, MONTHLY 등)';
COMMENT ON COLUMN event.winner_selection_base_at IS '당첨자 선정 기준 일시';
COMMENT ON COLUMN event.priority IS '전시 우선순위(낮을수록 우선)';
COMMENT ON COLUMN event.created_at IS '등록 일시';
COMMENT ON COLUMN event.created_by IS '등록자 식별자';
COMMENT ON COLUMN event.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event.updated_by IS '최종 수정자 식별자';

-- =============================================================
-- [3] event_prize (이벤트 경품 정책)
-- 개선: prize_id 추가 (prize 마스터 FK 연결)
-- =============================================================
CREATE TABLE event_prize (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id    BIGINT NOT NULL REFERENCES event(id),
    prize_id    BIGINT REFERENCES prize(id),
    prize_no    INTEGER NOT NULL,
    prize_type  VARCHAR(30) NOT NULL,
    prize_limit INTEGER NOT NULL,
    priority    INTEGER NOT NULL DEFAULT 1,
    tax_amount  INTEGER,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL,
    created_by  BIGINT NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    updated_by  BIGINT NOT NULL,
    deleted_at  TIMESTAMP,
    UNIQUE (event_id, prize_no)
);

COMMENT ON TABLE event_prize IS '이벤트 경품 정책 테이블';
COMMENT ON COLUMN event_prize.id IS '이벤트 경품 식별자(PK, 대체키)';
COMMENT ON COLUMN event_prize.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_prize.prize_id IS '경품 마스터 식별자(FK, NULL 허용: 경품 미연동 이벤트 가능)';
COMMENT ON COLUMN event_prize.prize_no IS '이벤트 내 경품 번호(업무 식별자)';
COMMENT ON COLUMN event_prize.prize_type IS '경품 유형 코드 code_group(domain:EVENT, group_code:PRIZE_TYPE: PRODUCT, COUPON, POINT 등)';
COMMENT ON COLUMN event_prize.prize_limit IS '해당 경품의 당첨 가능 최대 인원 수';
COMMENT ON COLUMN event_prize.priority IS '경품 우선순위(낮을수록 우선)';
COMMENT ON COLUMN event_prize.tax_amount IS '경품 관련 제세공과금 금액';
COMMENT ON COLUMN event_prize.is_active IS '경품 사용 여부';
COMMENT ON COLUMN event_prize.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_prize.created_at IS '등록 일시';
COMMENT ON COLUMN event_prize.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_prize.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_prize.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_prize.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [4] event_image_file (이벤트 이미지 파일 - 자산)
-- =============================================================
CREATE TABLE event_image_file (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    file_key        VARCHAR(300) NOT NULL,
    original_name   VARCHAR(255),
    content_type    VARCHAR(30),
    file_size       BIGINT,
    width           INTEGER,
    height          INTEGER,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL
);

COMMENT ON TABLE event_image_file IS '이벤트 이미지 파일 메타데이터';
COMMENT ON COLUMN event_image_file.id IS '이벤트 이미지 파일 식별자(PK)';
COMMENT ON COLUMN event_image_file.file_key IS 'S3 객체 키 (버킷 내 유일 경로, 예: event/banner/2026/01/uuid.png)';
COMMENT ON COLUMN event_image_file.original_name IS '업로드 당시 원본 파일명';
COMMENT ON COLUMN event_image_file.content_type IS '파일 MIME 타입 (image/jpeg, image/png, video/mp4 등)';
COMMENT ON COLUMN event_image_file.file_size IS '파일 크기(Byte)';
COMMENT ON COLUMN event_image_file.width IS '이미지 가로 픽셀 크기';
COMMENT ON COLUMN event_image_file.height IS '이미지 세로 픽셀 크기';
COMMENT ON COLUMN event_image_file.created_at IS '등록 일시';
COMMENT ON COLUMN event_image_file.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_image_file.updated_at IS '수정 일시';
COMMENT ON COLUMN event_image_file.updated_by IS '수정자 식별자';

-- =============================================================
-- [5] event_banner (이벤트 배너 노출 정책)
-- 개선: PK 단일 id로 통일, is_visible 컬럼 명확화
-- =============================================================
CREATE TABLE event_banner (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id            BIGINT NOT NULL REFERENCES event(id),
    channel_type        VARCHAR(30) NOT NULL,
    device_type         VARCHAR(30) NOT NULL,
    display_location    VARCHAR(30) NOT NULL,
    link_url            VARCHAR(500) NOT NULL,
    priority            INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_displayed        BOOLEAN NOT NULL DEFAULT TRUE,
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
COMMENT ON COLUMN event_banner.priority IS '배너 노출 우선순위(낮을수록 우선)';
COMMENT ON COLUMN event_banner.is_active IS '배너 활성 여부';
COMMENT ON COLUMN event_banner.is_displayed IS '배너 전시 여부';
COMMENT ON COLUMN event_banner.created_at IS '등록 일시';
COMMENT ON COLUMN event_banner.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_banner.updated_at IS '수정 일시';
COMMENT ON COLUMN event_banner.updated_by IS '수정자 식별자';

-- =============================================================
-- [6] event_banner_image (배너-이미지 매핑)
-- =============================================================
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
COMMENT ON COLUMN event_banner_image.image_variant IS '이미지 변형 유형 code_group(EVENT.VARIANT: ORIGINAL, PC, MOBILE)';
COMMENT ON COLUMN event_banner_image.created_at IS '등록 일시';
COMMENT ON COLUMN event_banner_image.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_banner_image.updated_at IS '수정 일시';
COMMENT ON COLUMN event_banner_image.updated_by IS '수정자 식별자';

-- =============================================================
-- [7] event_sns (이벤트 SNS 공유 정보)
-- 개선: FK 구문 수정, image_file_id 추가 (선택적)
-- =============================================================
CREATE TABLE event_sns (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    sns_code        VARCHAR(10) NOT NULL,
    title           VARCHAR(200),
    content         VARCHAR(1000) NOT NULL,
    sns_url         VARCHAR(200) NOT NULL,
    image_url       VARCHAR(200),
    image_file_id   BIGINT REFERENCES event_image_file(id),
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP,
    UNIQUE (event_id, sns_code)
);

COMMENT ON TABLE event_sns IS '이벤트 SNS 공유 정보 테이블';
COMMENT ON COLUMN event_sns.id IS '이벤트 SNS 정보 식별자(PK, 대체키)';
COMMENT ON COLUMN event_sns.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_sns.sns_code IS 'SNS 구분 코드 code_group(domain:EVENT, group_code:SNS: KAKAO, FACEBOOK, INSTAGRAM 등)';
COMMENT ON COLUMN event_sns.title IS 'SNS 공유 제목';
COMMENT ON COLUMN event_sns.content IS 'SNS 공유용 상세 문구';
COMMENT ON COLUMN event_sns.sns_url IS 'SNS 공유 시 이동할 이벤트 페이지 URL';
COMMENT ON COLUMN event_sns.image_url IS 'SNS 공유용 이미지 URL (외부 CDN 직접 입력, image_file_id 미연동 시 사용)';
COMMENT ON COLUMN event_sns.image_file_id IS 'SNS 공유용 이미지 파일 식별자(FK, NULL 허용: image_url 사용 시)';
COMMENT ON COLUMN event_sns.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_sns.created_at IS '등록 일시';
COMMENT ON COLUMN event_sns.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_sns.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_sns.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_sns.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [8] event_applicant (이벤트 응모자 기준)
-- =============================================================
CREATE TABLE event_applicant (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id    BIGINT NOT NULL REFERENCES event(id),
    member_id   BIGINT NOT NULL,
    draw_id     BIGINT,
    is_deleted  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL,
    created_by  BIGINT NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    updated_by  BIGINT NOT NULL,
    deleted_at  TIMESTAMP,
    UNIQUE (event_id, member_id)
);

COMMENT ON TABLE event_applicant IS '이벤트 응모자 기준 테이블';
COMMENT ON COLUMN event_applicant.id IS '이벤트 응모자 식별자(PK)';
COMMENT ON COLUMN event_applicant.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_applicant.member_id IS '참여자(회원) 식별자';
COMMENT ON COLUMN event_applicant.draw_id IS '연관 추첨 회차 식별자(NULL: 전체 이벤트 단위 참여자)';
COMMENT ON COLUMN event_applicant.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_applicant.created_at IS '등록 일시';
COMMENT ON COLUMN event_applicant.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_applicant.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_applicant.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_applicant.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [9] event_entry (이벤트 응모 이력)
-- =============================================================
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
    deleted_at      TIMESTAMP,
    UNIQUE (event_id, entry_id, member_id)
);

COMMENT ON TABLE event_entry IS '이벤트 응모 이력';
COMMENT ON COLUMN event_entry.id IS '이벤트 응모 식별자(PK, 대체키)';
COMMENT ON COLUMN event_entry.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_entry.entry_id IS '이벤트 내 응모 순번(업무 식별자)';
COMMENT ON COLUMN event_entry.member_id IS '응모자(회원) 식별자';
COMMENT ON COLUMN event_entry.applied_at IS '이벤트 응모 일시';
COMMENT ON COLUMN event_entry.order_no IS '연관 주문 번호';
COMMENT ON COLUMN event_entry.prize_id IS '당첨된 경품 식별자';
COMMENT ON COLUMN event_entry.is_winner IS '당첨 여부(event_win와 동기화 필요)';
COMMENT ON COLUMN event_entry.purchase_amount IS '응모 기준 구매 금액(스냅샷)';
COMMENT ON COLUMN event_entry.order_count IS '응모 기준 주문 수량(스냅샷)';
COMMENT ON COLUMN event_entry.cancel_count IS '응모 기준 취소 수량(스냅샷)';
COMMENT ON COLUMN event_entry.description IS '응모 관련 추가 설명 또는 메모';
COMMENT ON COLUMN event_entry.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_entry.created_at IS '등록 일시';
COMMENT ON COLUMN event_entry.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_entry.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_entry.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_entry.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [10] event_draw_round (이벤트 추첨 회차)
-- =============================================================
CREATE TABLE event_draw_round (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    draw_no         INTEGER NOT NULL,
    is_confirmed    BOOLEAN NOT NULL DEFAULT FALSE,
    draw_at         TIMESTAMP,
    draw_start_at   TIMESTAMP,
    draw_end_at     TIMESTAMP,
    announcement_at TIMESTAMP,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP,
    UNIQUE (event_id, draw_no)
);

COMMENT ON TABLE event_draw_round IS '이벤트 추첨 회차';
COMMENT ON COLUMN event_draw_round.id IS '이벤트 추첨 회차 식별자(PK, 대체키)';
COMMENT ON COLUMN event_draw_round.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_draw_round.draw_no IS '이벤트 내 추첨 회차 번호(업무 식별자)';
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
COMMENT ON COLUMN event_draw_round.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [11] event_win (이벤트 당첨 및 경품 지급)
-- 개선: draw_id, entry_id FK 추가, is_recorded COMMENT 오류 제거
-- =============================================================
CREATE TABLE event_win (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    member_id       BIGINT NOT NULL,
    draw_id         BIGINT NOT NULL REFERENCES event_draw_round(id),
    entry_id        BIGINT NOT NULL REFERENCES event_entry(id),
    prize_id        BIGINT,
    sent_at         DATE,
    is_sent         BOOLEAN NOT NULL DEFAULT FALSE,
    received_at     DATE,
    is_received     BOOLEAN NOT NULL DEFAULT FALSE,
    is_email_sent   BOOLEAN NOT NULL DEFAULT FALSE,
    is_sms_sent     BOOLEAN NOT NULL DEFAULT FALSE,
    confirmed_at    TIMESTAMP,
    is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    updated_at      TIMESTAMP NOT NULL,
    updated_by      BIGINT NOT NULL,
    deleted_at      TIMESTAMP,
    UNIQUE (event_id, member_id, draw_id, entry_id)
);

COMMENT ON TABLE event_win IS '이벤트 당첨 및 경품 지급 관리 테이블';
COMMENT ON COLUMN event_win.id IS '이벤트 당첨 식별자(PK, 대체키)';
COMMENT ON COLUMN event_win.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_win.member_id IS '당첨자(회원) 식별자';
COMMENT ON COLUMN event_win.draw_id IS '이벤트 추첨 회차 식별자(FK)';
COMMENT ON COLUMN event_win.entry_id IS '이벤트 응모 식별자(FK)';
COMMENT ON COLUMN event_win.prize_id IS '당첨 경품 식별자';
COMMENT ON COLUMN event_win.sent_at IS '경품 발송 일자';
COMMENT ON COLUMN event_win.is_sent IS '경품 발송 여부';
COMMENT ON COLUMN event_win.received_at IS '경품 수령 일자';
COMMENT ON COLUMN event_win.is_received IS '경품 수령 여부';
COMMENT ON COLUMN event_win.is_email_sent IS '당첨 안내 이메일 발송 여부';
COMMENT ON COLUMN event_win.is_sms_sent IS '당첨 안내 SMS 발송 여부';
COMMENT ON COLUMN event_win.confirmed_at IS '회원별 당첨 확정 일시';
COMMENT ON COLUMN event_win.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_win.created_at IS '등록 일시';
COMMENT ON COLUMN event_win.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_win.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_win.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_win.deleted_at IS '논리 삭제 일시';

-- =============================================================
-- [12] event_sns_share_log (신규: SNS 공유 이력)
-- =============================================================
CREATE TABLE event_sns_share_log (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id    BIGINT NOT NULL REFERENCES event(id),
    member_id   BIGINT NOT NULL,
    sns_code    VARCHAR(10) NOT NULL,
    shared_at   TIMESTAMP NOT NULL,
    is_success  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL,
    created_by  BIGINT NOT NULL
);

COMMENT ON TABLE event_sns_share_log IS 'SNS 공유 실행 이력 테이블';
COMMENT ON COLUMN event_sns_share_log.id IS 'SNS 공유 이력 식별자(PK)';
COMMENT ON COLUMN event_sns_share_log.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_sns_share_log.member_id IS '공유 실행 회원 식별자';
COMMENT ON COLUMN event_sns_share_log.sns_code IS 'SNS 채널 코드 code_group(EVENT.SNS)';
COMMENT ON COLUMN event_sns_share_log.shared_at IS '공유 실행 일시';
COMMENT ON COLUMN event_sns_share_log.is_success IS '공유 성공 여부';
COMMENT ON COLUMN event_sns_share_log.created_at IS '등록 일시';
COMMENT ON COLUMN event_sns_share_log.created_by IS '등록자 식별자';

-- =============================================================
-- ★ 확장 정책 A: 랜덤 추첨 정책
-- =============================================================

-- [A-1] event_draw_round에 추첨 방식 컬럼 추가
-- draw_method: RANDOM(단순 무작위) | WEIGHTED(가중치 기반) | PROBABILITY(확률 기반)
-- 기존 테이블에 ALTER로 추가하거나 초기 DDL에 포함 가능
ALTER TABLE event_draw_round
    ADD COLUMN draw_method     VARCHAR(20) NOT NULL DEFAULT 'RANDOM',
    ADD COLUMN draw_seed       VARCHAR(100),
    ADD COLUMN draw_batch_size INTEGER;

COMMENT ON COLUMN event_draw_round.draw_method IS '추첨 방식 코드 code_group(EVENT.DRAW_METHOD: RANDOM, WEIGHTED, PROBABILITY)';
COMMENT ON COLUMN event_draw_round.draw_seed IS '추첨 재현용 시드값 (감사/검증 목적, 예: UUID or timestamp 기반)';
COMMENT ON COLUMN event_draw_round.draw_batch_size IS '한 회차 최대 추첨 처리 건수 (배치 분할 추첨 시 사용)';

-- [A-2] event_prize_probability (경품별 당첨 확률 정책)
-- draw_method = PROBABILITY 일 때 이 테이블로 확률을 제어
-- draw_id NULL → 전체 회차 공통 적용, NOT NULL → 특정 회차 한정 적용
CREATE TABLE event_prize_probability (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id    BIGINT NOT NULL REFERENCES event(id),
    prize_id    BIGINT NOT NULL REFERENCES event_prize(id),
    draw_id     BIGINT REFERENCES event_draw_round(id),
    probability NUMERIC(5,2) NOT NULL,
    weight      INTEGER,
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMP NOT NULL,
    created_by  BIGINT NOT NULL,
    updated_at  TIMESTAMP NOT NULL,
    updated_by  BIGINT NOT NULL
);

COMMENT ON TABLE event_prize_probability IS '이벤트 경품 당첨 확률 정책 테이블';
COMMENT ON COLUMN event_prize_probability.id IS '확률 정책 식별자(PK)';
COMMENT ON COLUMN event_prize_probability.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_prize_probability.prize_id IS '이벤트 경품 식별자(FK)';
COMMENT ON COLUMN event_prize_probability.draw_id IS '적용 추첨 회차 식별자(FK, NULL: 전체 회차 공통 적용)';
COMMENT ON COLUMN event_prize_probability.probability IS '당첨 확률(%, 예: 5.00 = 5%)';
COMMENT ON COLUMN event_prize_probability.weight IS '가중치 기반 추첨용 값(draw_method=WEIGHTED 일 때 사용)';
COMMENT ON COLUMN event_prize_probability.is_active IS '확률 정책 사용 여부';
COMMENT ON COLUMN event_prize_probability.created_at IS '등록 일시';
COMMENT ON COLUMN event_prize_probability.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_prize_probability.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_prize_probability.updated_by IS '최종 수정자 식별자';

-- =============================================================
-- ★ 확장 정책 B: 출석 정책
-- =============================================================

-- [B-1] event_attendance_policy (출석 보상 정책)
-- 이벤트 타입이 ATTENDANCE 일 때 이 테이블로 보상 조건을 정의
-- 보상 유형: TOTAL(누적 출席), STREAK(연속 출席), MILESTONE(특정일 달성)
CREATE TABLE event_attendance_policy (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id            BIGINT NOT NULL REFERENCES event(id),
    policy_no           INTEGER NOT NULL,
    reward_type         VARCHAR(20) NOT NULL,
    required_days       INTEGER NOT NULL,
    is_streak_required  BOOLEAN NOT NULL DEFAULT FALSE,
    prize_id            BIGINT REFERENCES event_prize(id),
    reward_point        INTEGER,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL,
    updated_by          BIGINT NOT NULL,
    deleted_at          TIMESTAMP,
    UNIQUE (event_id, policy_no)
);

COMMENT ON TABLE event_attendance_policy IS '이벤트 출석 보상 정책 테이블';
COMMENT ON COLUMN event_attendance_policy.id IS '출석 정책 식별자(PK)';
COMMENT ON COLUMN event_attendance_policy.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_attendance_policy.policy_no IS '이벤트 내 출석 정책 번호(업무 식별자)';
COMMENT ON COLUMN event_attendance_policy.reward_type IS '보상 유형 code_group(EVENT.ATTENDANCE_REWARD: TOTAL, STREAK, MILESTONE)';
COMMENT ON COLUMN event_attendance_policy.required_days IS '보상 조건 출석일 수 (예: 7 → 7일 출석 시 보상)';
COMMENT ON COLUMN event_attendance_policy.is_streak_required IS '연속 출석 조건 여부 (TRUE: 연속, FALSE: 누적)';
COMMENT ON COLUMN event_attendance_policy.prize_id IS '보상 경품 식별자(FK, NULL: 포인트 보상)';
COMMENT ON COLUMN event_attendance_policy.reward_point IS '보상 포인트 (prize_id NULL 시 사용)';
COMMENT ON COLUMN event_attendance_policy.is_active IS '정책 사용 여부';
COMMENT ON COLUMN event_attendance_policy.is_deleted IS '논리 삭제 여부';
COMMENT ON COLUMN event_attendance_policy.created_at IS '등록 일시';
COMMENT ON COLUMN event_attendance_policy.created_by IS '등록자 식별자';
COMMENT ON COLUMN event_attendance_policy.updated_at IS '최종 수정 일시';
COMMENT ON COLUMN event_attendance_policy.updated_by IS '최종 수정자 식별자';
COMMENT ON COLUMN event_attendance_policy.deleted_at IS '논리 삭제 일시';

-- [B-2] event_attendance_log (회원별 출석 이력)
-- 하루 1회만 출석 가능: UNIQUE (event_id, member_id, attend_date)
-- is_rewarded: 해당 출석으로 보상이 지급되었는지 (MILESTONE 도달 시 TRUE)
CREATE TABLE event_attendance_log (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id        BIGINT NOT NULL REFERENCES event(id),
    member_id       BIGINT NOT NULL,
    attend_date     DATE NOT NULL,
    streak_count    INTEGER NOT NULL DEFAULT 1,
    total_count     INTEGER NOT NULL DEFAULT 1,
    is_rewarded     BOOLEAN NOT NULL DEFAULT FALSE,
    policy_id       BIGINT REFERENCES event_attendance_policy(id),
    created_at      TIMESTAMP NOT NULL,
    created_by      BIGINT NOT NULL,
    UNIQUE (event_id, member_id, attend_date)
);

COMMENT ON TABLE event_attendance_log IS '이벤트 출석 이력 테이블';
COMMENT ON COLUMN event_attendance_log.id IS '출석 이력 식별자(PK)';
COMMENT ON COLUMN event_attendance_log.event_id IS '이벤트 식별자(FK)';
COMMENT ON COLUMN event_attendance_log.member_id IS '출석 회원 식별자';
COMMENT ON COLUMN event_attendance_log.attend_date IS '출석 일자(1일 1회 제한 기준)';
COMMENT ON COLUMN event_attendance_log.streak_count IS '현재 연속 출석일 수 (전일 미출석 시 1로 초기화)';
COMMENT ON COLUMN event_attendance_log.total_count IS '이벤트 기간 내 누적 출석일 수';
COMMENT ON COLUMN event_attendance_log.is_rewarded IS '보상 지급 여부 (정책 조건 달성 시 TRUE)';
COMMENT ON COLUMN event_attendance_log.policy_id IS '적용된 출석 보상 정책 식별자(FK, NULL: 보상 미발생)';
COMMENT ON COLUMN event_attendance_log.created_at IS '출석 등록 일시';
COMMENT ON COLUMN event_attendance_log.created_by IS '등록자 식별자';
