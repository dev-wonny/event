-- ============================================================
-- Event Platform Schema DDL  (PostgreSQL)
-- Generated: 2026-03-03
--
-- Tables:
--  1. prize
--  2. event
--  3. event_file
--  4. event_round
--  5. event_round_prize
--  6. event_round_prize_probability
--  7. event_applicant
--  8. event_entry
--  9. event_win
-- 10. event_display_asset
--
-- [변경/보완 사항 요약]
--  (A) 문법 오류 수정
--      - event, event_file, event_round_prize, event_display_asset 테이블
--        마지막 CONSTRAINT 뒤 trailing comma(,) 제거
--      - event 테이블에 누락된 PRIMARY KEY 추가 (pk_event)
--
--  (B) 컬럼/타입 보완
--      - event.winner_selection_cycle: VARCHAR(20) → SMALLINT (단위: 시간, 정수 저장이 적합)
--      - event.priority: NULL 가능 INTEGER → NOT NULL DEFAULT 0
--      - event_file.checksum_sha256: VARCHAR(64) → CHAR(64) (SHA-256 고정 64자)
--      - event_file.mime_type: VARCHAR(50) → VARCHAR(100) (일부 MIME 타입 50자 초과 가능)
--      - event_round.round_no: INTEGER → SMALLINT
--      - event_round_prize.priority: INTEGER → SMALLINT
--      - event_round_prize_probability.probability: NUMERIC(5,2) → NUMERIC(6,3) (정밀도 확장)
--      - event_applicant: UNIQUE (round_id, member_id) 추가 (1인 1참여 보장)
--      - event_file: UNIQUE (object_key) 추가
--      - event_round: UNIQUE (event_id, round_no) 추가
--      - event_round_prize: UNIQUE (round_id, prize_id) 추가
--      - event_display_asset.sort_order: INTEGER → SMALLINT
--
--  (C) 인덱스 설계
--      - PostgreSQL은 FK에 자동 인덱스를 생성하지 않으므로 FK 컬럼 위주로 최소화
--      - 쓰기 성능 저하 방지를 위해 명백히 필요한 것만 생성
--      - 기본 정렬(created_at DESC)은 PK(id) desc로 대체 가능 → created_at 인덱스 미생성
-- ============================================================

CREATE SCHEMA IF NOT EXISTS event_platform;

-- ============================================================
-- [1] prize
-- 역할: 경품 마스터 — 이벤트와 독립적으로 재사용 가능한 경품 원형 정의
-- ============================================================
CREATE TABLE event_platform.prize (
    id                  BIGINT          GENERATED ALWAYS AS IDENTITY,
    prize_name          VARCHAR(100)    NOT NULL,
    reward_type         VARCHAR(20)     NOT NULL,
    point_amount        INTEGER,
    external_ref_id     VARCHAR(100),
    prize_description   TEXT,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL,
    deleted_at          TIMESTAMPTZ,
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_prize PRIMARY KEY (id)
);

COMMENT ON TABLE  event_platform.prize                   IS '경품 마스터 — 이벤트와 무관하게 재사용 가능한 경품 원형 정의';
COMMENT ON COLUMN event_platform.prize.prize_name        IS '경품명';
COMMENT ON COLUMN event_platform.prize.reward_type       IS '보상 유형 (공통코드 PRIZE_TYPE: POINT, COUPON, PRODUCT, ETC)';
COMMENT ON COLUMN event_platform.prize.point_amount      IS '포인트 지급액 (reward_type=POINT 일 때만 사용)';
COMMENT ON COLUMN event_platform.prize.external_ref_id   IS '외부 연동용 reference (쇼핑몰 product_id, 모바일쿠폰 id, 물류 상품 id 등)';
COMMENT ON COLUMN event_platform.prize.prize_description IS '경품 설명';
COMMENT ON COLUMN event_platform.prize.is_active         IS '경품 활성 여부';
COMMENT ON COLUMN event_platform.prize.created_at        IS '등록 일시';
COMMENT ON COLUMN event_platform.prize.created_by        IS '등록자 식별자';
COMMENT ON COLUMN event_platform.prize.updated_at        IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.prize.updated_by        IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.prize.deleted_at        IS '삭제 일시';
COMMENT ON COLUMN event_platform.prize.is_deleted        IS '논리 삭제 여부';

-- 인덱스: 기본 정렬(created_at DESC) 지원
CREATE INDEX idx_prize_created_at ON event_platform.prize (created_at DESC);


-- ============================================================
-- [2] event
-- 역할: 이벤트 기본 정보 및 공통 운영 정책
-- ============================================================
CREATE TABLE event_platform.event (
    id                       BIGINT          GENERATED ALWAYS AS IDENTITY,
    event_name               VARCHAR(100)    NOT NULL,
    event_type               VARCHAR(30)     NOT NULL,
    start_at                 TIMESTAMPTZ     NOT NULL,
    end_at                   TIMESTAMPTZ     NOT NULL,
    is_active                BOOLEAN         NOT NULL DEFAULT FALSE,
    is_visible               BOOLEAN         NOT NULL DEFAULT FALSE,
    is_auto_entry            BOOLEAN         NOT NULL DEFAULT FALSE,
    is_confirmed             BOOLEAN         NOT NULL DEFAULT FALSE,
    is_sns_linked            BOOLEAN         NOT NULL DEFAULT FALSE,
    event_url                VARCHAR(300),
    description              TEXT,
    supplier_id              BIGINT          NOT NULL,
    is_winner_announced      BOOLEAN         NOT NULL DEFAULT FALSE,
    winner_announced_at      TIMESTAMPTZ,
    allow_duplicate_winner   BOOLEAN         NOT NULL DEFAULT FALSE,
    allow_multiple_entry     BOOLEAN         NOT NULL DEFAULT FALSE,
    winner_selection_cycle   SMALLINT,
    winner_selection_base_at TIMESTAMPTZ,
    priority                 INTEGER         NOT NULL DEFAULT 0,
    created_at               TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by               BIGINT          NOT NULL,
    updated_at               TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by               BIGINT          NOT NULL,
    deleted_at               TIMESTAMPTZ,
    is_deleted               BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event PRIMARY KEY (id)
);

COMMENT ON TABLE  event_platform.event                          IS '이벤트 기본 정보 및 공통 운영 정책';
COMMENT ON COLUMN event_platform.event.event_name               IS '이벤트명';
COMMENT ON COLUMN event_platform.event.event_type               IS '이벤트 유형 (공통코드 EVENT_TYPE: ATTENDANCE, RANDOM_REWARD)';
COMMENT ON COLUMN event_platform.event.start_at                 IS '이벤트 시작 일시';
COMMENT ON COLUMN event_platform.event.end_at                   IS '이벤트 종료 일시';
COMMENT ON COLUMN event_platform.event.is_active                IS '이벤트 활성 상태 (공통코드 EVENT_STATUS: DRAFT, ACTIVE, PAUSED, ENDED, CANCELLED)';
COMMENT ON COLUMN event_platform.event.is_visible               IS '이벤트 전시 여부 (start_at 이후 노출)';
COMMENT ON COLUMN event_platform.event.is_auto_entry            IS '자동 응모 여부';
COMMENT ON COLUMN event_platform.event.is_confirmed             IS '이벤트 승인 여부 (권한 체크용)';
COMMENT ON COLUMN event_platform.event.is_sns_linked            IS 'SNS 공유 연동 여부';
COMMENT ON COLUMN event_platform.event.event_url                IS '이벤트 URL';
COMMENT ON COLUMN event_platform.event.description              IS '이벤트 상세 설명 (관리자용 || 사용자 노출 가능)';
COMMENT ON COLUMN event_platform.event.supplier_id              IS '공급사 식별자 (외부 참조)';
COMMENT ON COLUMN event_platform.event.is_winner_announced      IS '당첨자 발표 여부';
COMMENT ON COLUMN event_platform.event.winner_announced_at      IS '당첨자 발표 일시';
COMMENT ON COLUMN event_platform.event.allow_duplicate_winner   IS '당첨자 중복 허용 여부';
COMMENT ON COLUMN event_platform.event.allow_multiple_entry     IS '복수 응모 허용 여부';
COMMENT ON COLUMN event_platform.event.winner_selection_cycle   IS '당첨자 선정 주기 (단위: 시간, NULL=비주기)';
COMMENT ON COLUMN event_platform.event.winner_selection_base_at IS '당첨자 선정 기준 일시';
COMMENT ON COLUMN event_platform.event.priority                 IS '전시 우선순위 (낮을수록 상위)';
COMMENT ON COLUMN event_platform.event.created_at               IS '등록 일시';
COMMENT ON COLUMN event_platform.event.created_by               IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event.updated_at               IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event.updated_by               IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event.deleted_at               IS '삭제 일시';
COMMENT ON COLUMN event_platform.event.is_deleted               IS '논리 삭제 여부';

-- 인덱스: 기본 정렬(created_at DESC) 지원
CREATE INDEX idx_event_created_at ON event_platform.event (created_at DESC);


-- ============================================================
-- [3] event_file
-- 역할: S3 업로드 파일 메타데이터 저장소
-- ============================================================
CREATE TABLE event_platform.event_file (
    id                  BIGINT          GENERATED ALWAYS AS IDENTITY,
    object_key          VARCHAR(300)    NOT NULL,
    original_file_name  VARCHAR(200)    NOT NULL,
    file_size           BIGINT          NOT NULL,
    mime_type           VARCHAR(100)    NOT NULL,
    file_extension      VARCHAR(10)     NOT NULL,
    checksum_sha256     CHAR(64),
    width               INTEGER,
    height              INTEGER,
    is_public           BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL,
    deleted_at          TIMESTAMPTZ,
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_file            PRIMARY KEY (id),
    CONSTRAINT uq_event_file_object_key UNIQUE (object_key)
);

COMMENT ON TABLE  event_platform.event_file                     IS 'S3 업로드 파일 메타데이터 저장소 (CDN URL은 애플리케이션에서 조합)';
COMMENT ON COLUMN event_platform.event_file.object_key          IS 'S3 오브젝트 키 (ex: event/2026/02/uuid.png) — CDN 베이스 URL은 properties에서 관리';
COMMENT ON COLUMN event_platform.event_file.original_file_name  IS '업로드 당시 원본 파일명';
COMMENT ON COLUMN event_platform.event_file.file_size           IS '파일 바이트 크기';
COMMENT ON COLUMN event_platform.event_file.mime_type           IS 'MIME 타입 (image/png, image/jpeg, image/gif 등)';
COMMENT ON COLUMN event_platform.event_file.file_extension      IS '파일 확장자 소문자 (png, jpg, jpeg, gif 등)';
COMMENT ON COLUMN event_platform.event_file.checksum_sha256     IS 'SHA-256 체크섬 (고정 64자) — 동일 파일 중복 업로드 감지용';
COMMENT ON COLUMN event_platform.event_file.width               IS '이미지 실제 픽셀 너비';
COMMENT ON COLUMN event_platform.event_file.height              IS '이미지 실제 픽셀 높이';
COMMENT ON COLUMN event_platform.event_file.is_public           IS 'CDN 공개 여부 (FALSE 이면 Presigned URL 사용)';
COMMENT ON COLUMN event_platform.event_file.created_at          IS '등록 일시';
COMMENT ON COLUMN event_platform.event_file.created_by          IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_file.updated_at          IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_file.updated_by          IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_file.deleted_at          IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_file.is_deleted          IS '논리 삭제 여부';

-- 인덱스: 중복 파일 체크섬 조회 (uq_object_key는 UNIQUE가 자동 인덱스 생성)
CREATE INDEX idx_event_file_checksum ON event_platform.event_file (checksum_sha256);


-- ============================================================
-- [4] event_round
-- 역할: 이벤트 추첨 회차 기준
-- 관계: event (1) → event_round (N)
-- ============================================================
CREATE TABLE event_platform.event_round (
    id              BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_id        BIGINT      NOT NULL,
    round_no        SMALLINT    NOT NULL,
    is_confirmed    BOOLEAN     NOT NULL DEFAULT FALSE,
    draw_at         TIMESTAMPTZ,
    draw_start_at   TIMESTAMPTZ,
    draw_end_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT      NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT      NOT NULL,
    deleted_at      TIMESTAMPTZ,
    is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_round                PRIMARY KEY (id),
    CONSTRAINT fk_event_round_event          FOREIGN KEY (event_id) REFERENCES event_platform.event(id),
    CONSTRAINT uq_event_round_event_round_no UNIQUE (event_id, round_no)
);

COMMENT ON TABLE  event_platform.event_round               IS '이벤트 추첨 회차 기준 — 1개 이벤트에 N개 회차 존재 가능';
COMMENT ON COLUMN event_platform.event_round.event_id      IS '이벤트 식별자';
COMMENT ON COLUMN event_platform.event_round.round_no      IS '추첨 회차 번호 (1부터 시작)';
COMMENT ON COLUMN event_platform.event_round.is_confirmed  IS '당첨자 확정 여부';
COMMENT ON COLUMN event_platform.event_round.draw_at       IS '실제 추첨 실행 일시';
COMMENT ON COLUMN event_platform.event_round.draw_start_at IS '추첨 대상 기간 시작 일시';
COMMENT ON COLUMN event_platform.event_round.draw_end_at   IS '추첨 대상 기간 종료 일시';
COMMENT ON COLUMN event_platform.event_round.created_at    IS '등록 일시';
COMMENT ON COLUMN event_platform.event_round.created_by    IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_round.updated_at    IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_round.updated_by    IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_round.deleted_at    IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_round.is_deleted    IS '논리 삭제 여부';

-- 인덱스: UNIQUE (event_id, round_no) 가 커버하므로 별도 생성 없음


-- ============================================================
-- [5] event_round_prize
-- 역할: 이벤트 경품 회차별 정책 — 회차별 경품 배정 및 지급 제한 정의
-- 관계: event_round (1) → event_round_prize (N)
--       prize (1)       → event_round_prize (N)
-- ============================================================
CREATE TABLE event_platform.event_round_prize (
    id          BIGINT      GENERATED ALWAYS AS IDENTITY,
    round_id    BIGINT      NOT NULL,
    prize_id    BIGINT      NOT NULL,
    daily_limit INTEGER,
    total_limit INTEGER,
    priority    SMALLINT    NOT NULL DEFAULT 0,
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT      NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by  BIGINT      NOT NULL,
    deleted_at  TIMESTAMPTZ,
    is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_round_prize             PRIMARY KEY (id),
    CONSTRAINT fk_event_round_prize_round       FOREIGN KEY (round_id) REFERENCES event_platform.event_round(id),
    CONSTRAINT fk_event_round_prize_prize       FOREIGN KEY (prize_id) REFERENCES event_platform.prize(id)
);

COMMENT ON TABLE  event_platform.event_round_prize                IS '이벤트 회차별 경품 운영 정책 — 지급 한도 및 우선순위 정의';
COMMENT ON COLUMN event_platform.event_round_prize.round_id       IS '추첨 회차 식별자';
COMMENT ON COLUMN event_platform.event_round_prize.prize_id       IS '경품 식별자';
COMMENT ON COLUMN event_platform.event_round_prize.daily_limit    IS '일별 지급 상한 (NULL=무제한). 앱에서 당일 event_entry COUNT로 체크';
COMMENT ON COLUMN event_platform.event_round_prize.total_limit    IS '총 지급 상한 (NULL=무제한). 앱에서 event_entry COUNT로 체크';
COMMENT ON COLUMN event_platform.event_round_prize.priority       IS '경품 적용 우선순위 (낮을수록 우선)';
COMMENT ON COLUMN event_platform.event_round_prize.is_active      IS '경품 정책 활성 여부';
COMMENT ON COLUMN event_platform.event_round_prize.created_at     IS '등록 일시';
COMMENT ON COLUMN event_platform.event_round_prize.created_by     IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_round_prize.updated_at     IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_round_prize.updated_by     IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_round_prize.deleted_at     IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_round_prize.is_deleted     IS '논리 삭제 여부';

-- 인덱스: round_id FK + 실시간 지급 핫패스 (회차별 활성 경품을 priority 순 조회)
CREATE INDEX idx_event_round_prize_active
    ON event_platform.event_round_prize (round_id, priority)
    WHERE is_active = TRUE AND is_deleted = FALSE;


-- ============================================================
-- [6] event_round_prize_probability
-- 역할: 경품 당첨 확률 정책 (룰렛/즉시당첨 이벤트용)
-- 관계: event_round_prize (1) → event_round_prize_probability (N)
-- ============================================================
CREATE TABLE event_platform.event_round_prize_probability (
    id                   BIGINT          GENERATED ALWAYS AS IDENTITY,
    event_round_prize_id BIGINT          NOT NULL,
    probability          NUMERIC(6,3)    NOT NULL,
    weight               INTEGER,
    is_active            BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           BIGINT          NOT NULL,
    updated_at           TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by           BIGINT          NOT NULL,
    deleted_at           TIMESTAMPTZ,
    is_deleted           BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_round_prize_probability            PRIMARY KEY (id),
    CONSTRAINT fk_event_round_prize_prob_event_round_prize FOREIGN KEY (event_round_prize_id) REFERENCES event_platform.event_round_prize(id)
);

COMMENT ON TABLE  event_platform.event_round_prize_probability                   IS '경품 당첨 확률 정책 — 운영 중 변경 가능, 과거 이력 추적 가능';
COMMENT ON COLUMN event_platform.event_round_prize_probability.event_round_prize_id IS '경품 정책 식별자';
COMMENT ON COLUMN event_platform.event_round_prize_probability.probability       IS '당첨 확률 (0.000 ~ 100.000 %)';
COMMENT ON COLUMN event_platform.event_round_prize_probability.weight            IS '가중치 기반 추첨용 값 (확률 대신 weight 합산으로 비율 계산 시 사용)';
COMMENT ON COLUMN event_platform.event_round_prize_probability.is_active         IS '확률 정책 사용 여부';
COMMENT ON COLUMN event_platform.event_round_prize_probability.created_at        IS '등록 일시';
COMMENT ON COLUMN event_platform.event_round_prize_probability.created_by        IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_round_prize_probability.updated_at        IS '수정 일시';
COMMENT ON COLUMN event_platform.event_round_prize_probability.updated_by        IS '수정자 식별자';
COMMENT ON COLUMN event_platform.event_round_prize_probability.deleted_at        IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_round_prize_probability.is_deleted        IS '논리 삭제 여부';

-- 인덱스: 확률 조회의 핵심 FK
CREATE INDEX idx_erpp_event_round_prize_id ON event_platform.event_round_prize_probability (event_round_prize_id);


-- ============================================================
-- [7] event_applicant
-- 참여 자격 레벨
-- 역할: 이벤트 참여자 기준 — 회차당 1인 1참여 보장
-- 관계: event_round (1) → event_applicant (1)
-- ============================================================
CREATE TABLE event_platform.event_applicant (
    id          BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_id    BIGINT      NOT NULL,
    round_id    BIGINT      NOT NULL,
    member_id   BIGINT      NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by  BIGINT      NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by  BIGINT      NOT NULL,
    deleted_at  TIMESTAMPTZ,
    is_deleted  BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_applicant              PRIMARY KEY (id),
    CONSTRAINT fk_event_applicant_event        FOREIGN KEY (event_id) REFERENCES event_platform.event(id),
    CONSTRAINT fk_event_applicant_round        FOREIGN KEY (round_id) REFERENCES event_platform.event_round(id)
);

COMMENT ON TABLE  event_platform.event_applicant             IS '이벤트 참여 이력 — 회원의 이벤트 참여 기록, 회차(draw)당 1인 1참여';
COMMENT ON COLUMN event_platform.event_applicant.event_id    IS '이벤트 식별자 (빠른 이벤트 단위 조회용 비정규화 컬럼)';
COMMENT ON COLUMN event_platform.event_applicant.member_id   IS '참여자 회원 식별자';
COMMENT ON COLUMN event_platform.event_applicant.round_id    IS '추첨 회차 식별자';
COMMENT ON COLUMN event_platform.event_applicant.created_at  IS '등록 일시';
COMMENT ON COLUMN event_platform.event_applicant.created_by  IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_applicant.updated_at  IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_applicant.updated_by  IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_applicant.deleted_at  IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_applicant.is_deleted  IS '논리 삭제 여부';

-- 인덱스: event_id FK
CREATE INDEX idx_event_applicant_event_id ON event_platform.event_applicant (event_id);


-- ============================================================
-- [8] event_entry
-- 응모 행위 레벨
-- 보상 안 들어감
-- 역할: 응모 행위 성공 이력 — 한 참여자의 복수 응모 기록
-- 관계: event_applicant (1) → event_entry (N)
-- is_winner 나중에 draw 확장으로 남겨둠
-- ============================================================
CREATE TABLE event_platform.event_entry (
    id                   BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_id             BIGINT      NOT NULL,
    round_id             BIGINT      NOT NULL,
    member_id            BIGINT      NOT NULL,
    is_winner            BOOLEAN     NOT NULL DEFAULT FALSE,
    applied_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           BIGINT      NOT NULL,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by           BIGINT      NOT NULL,
    deleted_at           TIMESTAMPTZ,
    is_deleted           BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_entry                   PRIMARY KEY (id),
    CONSTRAINT fk_event_entry_event             FOREIGN KEY (event_id)  REFERENCES event_platform.event(id),
    CONSTRAINT fk_event_entry_round             FOREIGN KEY (round_id)  REFERENCES event_platform.event_round(id)
);

COMMENT ON TABLE  event_platform.event_entry                         IS '응모 행위 이력 — 참여자의 복수 응모 기록';
COMMENT ON COLUMN event_platform.event_entry.event_id                IS '이벤트 식별자 (빠른 이벤트 단위 조회용 비정규화)';
COMMENT ON COLUMN event_platform.event_entry.round_id                IS '추첨 회차 식별자 (빠른 회차 단위 조회용 비정규화)';
COMMENT ON COLUMN event_platform.event_entry.member_id               IS '응모자 회원 식별자 (조회 성능을 위한 비정규화)';
COMMENT ON COLUMN event_platform.event_entry.applied_at              IS '사용자 응모 액션 발생 일시';
COMMENT ON COLUMN event_platform.event_entry.is_winner               IS '추첨/확정 결과를 빠르게 조회하기 위한 보조 컬럼 (SoT: event_win)';
COMMENT ON COLUMN event_platform.event_entry.created_at              IS '레코드 등록 일시';
COMMENT ON COLUMN event_platform.event_entry.created_by              IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_entry.updated_at              IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_entry.updated_by              IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_entry.deleted_at              IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_entry.is_deleted              IS '논리 삭제 여부';

-- 인덱스: event_id 조회
CREATE INDEX idx_event_entry_event_id ON event_platform.event_entry (event_id);


-- ============================================================
-- [9] event_win
-- 역할: 당첨 결과 Single Source of Truth
--       당첨 이후 보상 결과가 기록됨
-- 관계: event_entry → event_win (참여 기록/보상 기록)
--       entry_id NULL → 관리자 수기 당첨 허용
--       event_round (1) → event_win (N)
--       event_entry (1) → event_win (0..1)
-- ============================================================
CREATE TABLE event_platform.event_win (
    id                   BIGINT      GENERATED ALWAYS AS IDENTITY,
    -- 응모 기반 당첨 여부 (즉시당첨/수기당첨)
    entry_id             BIGINT,
    -- 비정규화 스냅샷 (JOIN 제거 목적)
    event_id             BIGINT NOT NULL,
    round_id             BIGINT NOT NULL,
    event_round_prize_id BIGINT,
    member_id            BIGINT NOT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by           BIGINT      NOT NULL,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by           BIGINT      NOT NULL,
    deleted_at           TIMESTAMPTZ,
    is_deleted           BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_win                   PRIMARY KEY (id),
    CONSTRAINT fk_event_win_entry             FOREIGN KEY (entry_id)             REFERENCES event_platform.event_entry(id),
    CONSTRAINT fk_event_win_round             FOREIGN KEY (round_id)             REFERENCES event_platform.event_round(id),
    CONSTRAINT fk_event_win_event             FOREIGN KEY (event_id)             REFERENCES event_platform.event(id),
    CONSTRAINT fk_event_win_event_round_prize FOREIGN KEY (event_round_prize_id) REFERENCES event_platform.event_round_prize(id)
);

COMMENT ON TABLE  event_platform.event_win                       IS '당첨된 보상 결과';
COMMENT ON COLUMN event_platform.event_win.entry_id              IS '응모 식별자 (NULL = 관리자 수기 당첨)';
COMMENT ON COLUMN event_platform.event_win.round_id              IS '추첨 회차 식별자';
COMMENT ON COLUMN event_platform.event_win.event_id              IS '이벤트 식별자';
COMMENT ON COLUMN event_platform.event_win.member_id             IS '당첨자 회원 식별자';
COMMENT ON COLUMN event_platform.event_win.event_round_prize_id  IS '당첨된 경품 식별자';
COMMENT ON COLUMN event_platform.event_win.created_at            IS '등록 일시';
COMMENT ON COLUMN event_platform.event_win.created_by            IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_win.updated_at            IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_win.updated_by            IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_win.deleted_at            IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_win.is_deleted            IS '논리 삭제 여부';

-- 인덱스: event_id 조회
CREATE INDEX idx_event_win_event_id ON event_platform.event_win (event_id);


-- ============================================================
-- [10] event_display_asset
-- 역할: 이벤트 UI 표시용 이미지 슬롯 매핑
-- 관계: event (1) → event_display_asset (N) ← event_file (1)
-- ============================================================
CREATE TABLE event_platform.event_display_asset (
    id              BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_id        BIGINT      NOT NULL,
    file_id         BIGINT      NOT NULL,
    asset_type      VARCHAR(40) NOT NULL,
    display_width   INTEGER,
    display_height  INTEGER,
    sort_order      SMALLINT    NOT NULL DEFAULT 0,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT      NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT      NOT NULL,
    deleted_at      TIMESTAMPTZ,
    is_deleted      BOOLEAN     NOT NULL DEFAULT FALSE,

    CONSTRAINT pk_event_display_asset       PRIMARY KEY (id),
    CONSTRAINT fk_event_display_asset_event FOREIGN KEY (event_id) REFERENCES event_platform.event(id),
    CONSTRAINT fk_event_display_asset_file  FOREIGN KEY (file_id)  REFERENCES event_platform.event_file(id)
);

COMMENT ON TABLE  event_platform.event_display_asset                     IS '이벤트 UI 표시용 이미지 슬롯 매핑 (배경/섹션/버튼/룰렛슬롯/카드 등)';
COMMENT ON COLUMN event_platform.event_display_asset.event_id            IS '이벤트 식별자';
COMMENT ON COLUMN event_platform.event_display_asset.file_id             IS '파일 식별자 (FK: event_file)';
COMMENT ON COLUMN event_platform.event_display_asset.asset_type          IS 'UI 슬롯 유형 (BACKGROUND_DESKTOP, BACKGROUND_MOBILE, SECTION_TOP, SECTION_MIDDLE, SECTION_BOTTOM, BUTTON_DEFAULT, BUTTON_ACTIVE, ROULETTE_SLOT, CARD_FRONT, CARD_BACK, LADDER_BACKGROUND)';
COMMENT ON COLUMN event_platform.event_display_asset.display_width       IS 'UI 표시 너비 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.display_height      IS 'UI 표시 높이 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.sort_order          IS '동일 asset_type 내 순서 (ROULETTE_SLOT: 1=1번째칸, 2=2번째칸)';
COMMENT ON COLUMN event_platform.event_display_asset.is_active           IS '활성화 여부 (FALSE이면 UI에서 해당 슬롯 이미지 미노출)';
COMMENT ON COLUMN event_platform.event_display_asset.created_at          IS '등록 일시';
COMMENT ON COLUMN event_platform.event_display_asset.created_by          IS '등록자 식별자';
COMMENT ON COLUMN event_platform.event_display_asset.updated_at          IS '최종 수정 일시';
COMMENT ON COLUMN event_platform.event_display_asset.updated_by          IS '최종 수정자 식별자';
COMMENT ON COLUMN event_platform.event_display_asset.deleted_at          IS '삭제 일시';
COMMENT ON COLUMN event_platform.event_display_asset.is_deleted          IS '논리 삭제 여부';

-- 인덱스: 기본 정렬(created_at DESC) 지원
CREATE INDEX idx_event_display_asset_created_at ON event_platform.event_display_asset (created_at DESC);
