-- =============================================================
-- Event Platform - 전체 DDL (ERDCloud Import용)
-- 생성일: 2026-02-24
-- DB: PostgreSQL
-- Schema: event_platform
-- =============================================================

CREATE SCHEMA IF NOT EXISTS event_platform;


-- =============================================================
-- [01] file
-- 역할  : S3에 업로드된 물리 파일 메타 저장소
-- 관계  :
--   - event_display_asset.file_id  → file.id   (N:1)
-- =============================================================
-- 예시 데이터
-- id=1, object_key='event/2026/01/banner.png', original_file_name='banner.png',
--        file_size=204800, mime_type='image/png', file_extension='png', width=1920, height=600
-- id=2, object_key='event/2026/01/roulette_1.png', original_file_name='roulette_1.png',
--        file_size=98304, mime_type='image/png', file_extension='png', width=200, height=200
-- =============================================================

CREATE TABLE event_platform.file (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 저장 위치
     * ========================= */
    object_key          VARCHAR(300)    NOT NULL,                    -- S3 오브젝트 키 (ex: event/2026/02/uuid.png)

    /* =========================
     * 파일 메타
     * ========================= */
    original_file_name  VARCHAR(200),                                -- 업로드 시 원본 파일명
    file_size           BIGINT          NOT NULL,                    -- 파일 크기 (byte)
    mime_type           VARCHAR(50)     NOT NULL,                    -- MIME 타입 (image/png, image/jpeg, image/gif)
    file_extension      VARCHAR(10)     NOT NULL,                    -- 파일 확장자 (png, jpg, jpeg, gif)
    checksum_sha256     VARCHAR(64),                                 -- SHA-256 해시값 (중복 감지용, 선택)
    width               INTEGER,                                     -- 이미지 실제 픽셀 너비
    height              INTEGER,                                     -- 이미지 실제 픽셀 높이

    /* =========================
     * 상태
     * ========================= */
    is_public           BOOLEAN         NOT NULL DEFAULT TRUE,       -- CDN 공개 여부

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,                    -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                     -- FK: admin.id
);

CREATE UNIQUE INDEX ux_file_object_key
    ON event_platform.file(object_key)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.file IS 'S3 업로드 파일 메타 저장소 (CDN 주소는 application.properties 관리)';
COMMENT ON COLUMN event_platform.file.object_key         IS 'S3 오브젝트 키 - CDN/S3 베이스 URL은 application.properties에서 조합';
COMMENT ON COLUMN event_platform.file.original_file_name IS '업로드 당시의 원본 파일명';
COMMENT ON COLUMN event_platform.file.file_size          IS '파일 바이트 크기';
COMMENT ON COLUMN event_platform.file.mime_type          IS 'MIME 타입 (image/png, image/jpeg, image/gif)';
COMMENT ON COLUMN event_platform.file.file_extension     IS '파일 확장자 소문자 (png, jpg, jpeg, gif)';
COMMENT ON COLUMN event_platform.file.checksum_sha256    IS 'SHA-256 체크섬 - 동일 파일 중복 업로드 감지용';
COMMENT ON COLUMN event_platform.file.width              IS '이미지 실제 픽셀 너비';
COMMENT ON COLUMN event_platform.file.height             IS '이미지 실제 픽셀 높이';
COMMENT ON COLUMN event_platform.file.is_public          IS 'CDN 공개 여부 (FALSE 이면 Presigned URL 사용)';

-- =============================================================
-- [02] event
-- 역할  : 이벤트 마스터 테이블 - 출석·랜덤 이벤트 각각 1 row
-- 관계  :
--   - event_attendance_policy.event_id       → event.id (1:1)
--   - event_random_policy.event_id           → event.id (1:1)
--   - event_participation_eligibility.event_id → event.id (1:N)
--   - event_participation_limit_policy.event_id → event.id (1:N)
--   - event_display_asset.event_id           → event.id (1:N)
--   - event_display_message.event_id         → event.id (1:N)
--   - event_reward_catalog.event_id          → event.id (1:N)
--   - event_participant.event_id             → event.id (1:N)
--   - event_entry.event_id                     → event.id (1:N)
--   - event_reward_allocation.event_id            → event.id (1:N)
--   - event_share_policy.event_id            → event.id (1:1)
--   - event_share_log.event_id               → event.id (1:N)
-- =============================================================
-- 예시 데이터
-- id=1, supplier_id=1, event_type='ATTENDANCE', title='봄맞이 30일 출석 이벤트',
--        status='ACTIVE', start_at='2026-03-01 00:00:00', end_at='2026-03-31 23:59:59'
-- id=2, supplier_id=1, event_type='RANDOM',     title='봄맞이 룰렛 이벤트',
--        status='ACTIVE', start_at='2026-03-01 00:00:00', end_at='2026-03-15 23:59:59'
-- =============================================================

CREATE TABLE event_platform.event (
    id              BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 기본 식별 정보
     * ========================= */
    supplier_id     BIGINT          NOT NULL,                    -- 주최사 ID (현재: 돌쇠네 = 1)
    event_type      VARCHAR(20)     NOT NULL,                    -- 이벤트 유형: ATTENDANCE(출석체크) / RANDOM(랜덤게임)
    title           VARCHAR(200)    NOT NULL,                    -- 이벤트 제목 (관리자/UI 표시용)
    description     TEXT,                                       -- 이벤트 상세 설명

    /* =========================
     * 상태 및 운영
     * ========================= */
    status          VARCHAR(20)     NOT NULL DEFAULT 'DRAFT',   -- DRAFT(작성중) / ACTIVE(진행중) / PAUSED(일시정지) / ENDED(종료) / CANCELLED(취소)
    is_visible      BOOLEAN         NOT NULL DEFAULT TRUE,      -- UI 노출 여부 (FALSE 이면 URL 접근 불가)
    display_order   INTEGER         NOT NULL DEFAULT 0,         -- 목록 정렬 순서 (작을수록 상단)

    /* =========================
     * 이벤트 기간
     * ========================= */
    start_at        TIMESTAMP       NOT NULL,                   -- 이벤트 시작 일시 (KST 기준 입력 권장)
    end_at          TIMESTAMP       NOT NULL,                   -- 이벤트 종료 일시 (KST 기준 입력 권장)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by      BIGINT          NOT NULL,                   -- FK: admin.id
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by      BIGINT          NOT NULL                    -- FK: admin.id
);

CREATE INDEX idx_event_supplier_type
    ON event_platform.event(supplier_id, event_type)
    WHERE is_deleted = FALSE;

CREATE INDEX idx_event_status_period
    ON event_platform.event(status, start_at, end_at)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event IS '이벤트 마스터 - 출석/랜덤 이벤트 각 1 row';
COMMENT ON COLUMN event_platform.event.supplier_id   IS '주최사 ID (현재: 돌쇠네=1, 추후 멀티 테넌트 확장 고려)';
COMMENT ON COLUMN event_platform.event.event_type    IS '이벤트 유형 ATTENDANCE(출석체크) / RANDOM(랜덤게임)';
COMMENT ON COLUMN event_platform.event.title         IS '이벤트 제목 (관리자 화면·이벤트 목록 UI 표시)';
COMMENT ON COLUMN event_platform.event.description   IS '이벤트 상세 설명 (HTML 가능)';
COMMENT ON COLUMN event_platform.event.status        IS 'DRAFT=작성중, ACTIVE=진행중, PAUSED=일시정지, ENDED=종료, CANCELLED=취소';
COMMENT ON COLUMN event_platform.event.is_visible    IS 'UI 노출 여부 - FALSE 이면 URL 직접 접근도 차단';
COMMENT ON COLUMN event_platform.event.display_order IS '목록 정렬 순서 (낮을수록 상단 노출)';
COMMENT ON COLUMN event_platform.event.start_at      IS '이벤트 시작 일시 (KST 기준 입력 권장)';
COMMENT ON COLUMN event_platform.event.end_at        IS '이벤트 종료 일시 (KST 기준 입력 권장)';

-- =============================================================
-- [03] event_participation_eligibility
-- 역할  : 이벤트 참여 자격 조건 (누가 참여할 수 있나)
-- 관계  :
--   - event.id → event_participation_eligibility.event_id (1:N)
--     하나의 이벤트는 복수의 자격 조건을 가질 수 있음
-- =============================================================
-- 예시 데이터 (event_id=1, 30일 출석 이벤트)
-- id=1, event_id=1, eligibility_type='MEMBER_TYPE', eligibility_value='["REGULAR","VIP"]', priority=0, is_active=TRUE
-- id=2, event_id=1, eligibility_type='MIN_JOIN_DAYS', eligibility_value='30',               priority=10, is_active=TRUE
-- id=3, event_id=2, eligibility_type='PHONE_VERIFIED', eligibility_value='true',            priority=0, is_active=TRUE
-- =============================================================

CREATE TABLE event_platform.event_participation_eligibility (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id

    /* =========================
     * 자격 조건
     * ========================= */
    eligibility_type    VARCHAR(30)     NOT NULL,                -- 자격 조건 유형 (아래 값 목록 참고)
    -- MEMBER_TYPE           : 회원 유형 필터 ex) '["NEW","REGULAR","VIP"]'
    -- MEMBER_GRADE          : 회원 등급 필터 ex) '["SILVER","GOLD","VIP"]'
    -- MIN_JOIN_DAYS         : 가입 후 최소 일수 ex) '30'
    -- PHONE_VERIFIED        : 휴대폰 인증 필수 ex) 'true'
    -- EMAIL_VERIFIED        : 이메일 인증 필수 ex) 'true'
    -- ADDRESS_REGISTERED    : 주소 등록 필수   ex) 'true'
    -- MIN_ORDER_AMOUNT      : 최소 누적 주문금액 ex) '50000'
    -- EXCLUDE_WINNER_PERIOD : 최근 N일 내 당첨자 제외 ex) '90'

    eligibility_value   VARCHAR(200),                           -- 자격 조건 값 (위 유형별 포맷으로 저장)
    priority            INTEGER         NOT NULL DEFAULT 0,     -- 조건 평가 우선순위 (낮을수록 먼저 평가)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 조건 무시)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_eligibility_event_priority
    ON event_platform.event_participation_eligibility(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_participation_eligibility IS '이벤트 참여 자격 조건 (누가 참여할 수 있나 - 자격 판단 전용, 수량 계산 없음)';
COMMENT ON COLUMN event_platform.event_participation_eligibility.event_id           IS 'FK: event.id - 1 이벤트 N 자격 조건';
COMMENT ON COLUMN event_platform.event_participation_eligibility.eligibility_type   IS '자격 조건 유형 (MEMBER_TYPE/MEMBER_GRADE/MIN_JOIN_DAYS/PHONE_VERIFIED/EMAIL_VERIFIED/ADDRESS_REGISTERED/MIN_ORDER_AMOUNT/EXCLUDE_WINNER_PERIOD)';
COMMENT ON COLUMN event_platform.event_participation_eligibility.eligibility_value  IS '자격 조건 값 - 유형에 따라 JSON 배열 또는 단일 숫자/문자열';
COMMENT ON COLUMN event_platform.event_participation_eligibility.priority           IS '조건 평가 순서 (낮을수록 먼저 평가)';
COMMENT ON COLUMN event_platform.event_participation_eligibility.is_active          IS 'FALSE 이면 해당 조건 무시 (삭제 없이 비활성화)';

-- =============================================================
-- [04] event_attendance_policy
-- 역할  : 출석 이벤트 전용 정책 (몇 일짜리, 누락 허용, 초기화 시각)
-- 관계  :
--   - event.id → event_attendance_policy.event_id (1:1)
--     출석 이벤트 1개당 정책 1개만 허용
--   - event_type='ATTENDANCE' 인 event 에만 생성
-- =============================================================
-- 예시 데이터
-- id=1, event_id=1, total_days=30, allow_missed_days=TRUE, reset_time='00:00'
--   → 30일짜리, 중간 누락해도 계속 출석 가능, 자정 기준 초기화
-- =============================================================

CREATE TABLE event_platform.event_attendance_policy (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조 (1:1)
     * ========================= */
    event_id            BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (1이벤트 = 1정책)

    /* =========================
     * 출석 기본 규칙
     * ========================= */
    total_days          INTEGER         NOT NULL,               -- 이벤트 총 출석 목표 일수 (예: 7, 15, 30)
    allow_missed_days   BOOLEAN         NOT NULL DEFAULT FALSE, -- 중간 누락 허용 여부 (FALSE 이면 연속 출석만 허용)
    reset_time          TIME            NOT NULL DEFAULT '00:00', -- KST 기준 출석 초기화 시각 (예: 00:00, 08:00)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

COMMENT ON TABLE  event_platform.event_attendance_policy IS '출석 이벤트 전용 정책 (KST 고정, 월드타임 미지원)';
COMMENT ON COLUMN event_platform.event_attendance_policy.event_id          IS 'FK: event.id - 출석 이벤트 1개당 정책 1개 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_attendance_policy.total_days        IS '이벤트 총 출석 목표 일수 (예: 7일, 15일, 30일)';
COMMENT ON COLUMN event_platform.event_attendance_policy.allow_missed_days IS 'TRUE=누락일이 있어도 누적 카운트 계속, FALSE=연속 실패 시 이벤트 종료';
COMMENT ON COLUMN event_platform.event_attendance_policy.reset_time        IS 'KST 기준 출석 날짜 초기화 시각 (예: 00:00 = 자정 기준)';

-- =============================================================
-- [05] event_random_policy
-- 역할  : 랜덤 이벤트 전용 정책 (게임 유형, 노출 슬롯 수, 퀴즈 내용, SNS 재도전 여부)
-- 관계  :
--   - event.id → event_random_policy.event_id (1:1)
--     랜덤 이벤트 1개당 정책 1개만 허용
--   - event_type='RANDOM' 인 event 에만 생성
-- =============================================================
-- 예시 데이터
-- id=1, event_id=2, game_type='ROULETTE',  display_slot_count=6, quiz_question=NULL, quiz_answer=NULL, sns_retry_enabled=TRUE
--   → 6칸 룰렛, SNS 공유 시 재도전 1회 허용
-- id=2, event_id=3, game_type='LADDER',    display_slot_count=4, quiz_question=NULL, quiz_answer=NULL, sns_retry_enabled=FALSE
--   → 4칸 사다리타기
-- id=3, event_id=4, game_type='QUIZ',      display_slot_count=NULL, quiz_question='ㅎ으ㅅ의 초성은?', quiz_answer='한글', sns_retry_enabled=FALSE
--   → 초성 퀴즈
-- =============================================================

CREATE TABLE event_platform.event_random_policy (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조 (1:1)
     * ========================= */
    event_id            BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (1이벤트 = 1정책)

    /* =========================
     * 게임 유형
     * ========================= */
    game_type           VARCHAR(20)     NOT NULL,               -- 게임 유형 (아래 값 참고)
    -- ROULETTE : 룰렛 (display_slot_count 사용)
    -- LADDER   : 사다리타기 (display_slot_count 사용)
    -- QUIZ     : 초성 게임 (quiz_question, quiz_answer 사용)
    -- CARD     : 카드 뒤집기

    /* =========================
     * 노출 슬롯 수 (ROULETTE · LADDER 전용)
     * ========================= */
    display_slot_count  INTEGER,                                -- UI에서 보여주는 상품 슬롯 수 (예: 룰렛 6칸, 사다리 4칸) - QUIZ 이면 NULL

    /* =========================
     * 퀴즈 설정 (QUIZ 전용)
     * ========================= */
    quiz_question       TEXT,                                   -- 퀴즈 문제 (QUIZ 게임 전용, 예: "ㅎ으ㅅ 초성 단어는?")
    quiz_answer         VARCHAR(200),                           -- 퀴즈 정답 (QUIZ 게임 전용, 대소문자 무시 처리)

    /* =========================
     * SNS 재도전 허용
     * ========================= */
    sns_retry_enabled   BOOLEAN         NOT NULL DEFAULT FALSE, -- SNS 공유 시 랜덤 재도전 1회 허용 여부

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

COMMENT ON TABLE  event_platform.event_random_policy IS '랜덤 이벤트 전용 정책 (게임 유형·슬롯·퀴즈·SNS 재도전)';
COMMENT ON COLUMN event_platform.event_random_policy.event_id           IS 'FK: event.id - 랜덤 이벤트 1개당 1개 정책 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_random_policy.game_type          IS '게임 유형: ROULETTE(룰렛) / LADDER(사다리타기) / QUIZ(초성게임) / CARD(카드뒤집기)';
COMMENT ON COLUMN event_platform.event_random_policy.display_slot_count IS 'UI 노출 슬롯 수 - ROULETTE(최대 6칸) / LADDER(칸 수), QUIZ이면 NULL';
COMMENT ON COLUMN event_platform.event_random_policy.quiz_question      IS '초성 게임 문제 - game_type=QUIZ 일 때만 사용';
COMMENT ON COLUMN event_platform.event_random_policy.quiz_answer        IS '초성 게임 정답 - game_type=QUIZ 일 때만 사용';
COMMENT ON COLUMN event_platform.event_random_policy.sns_retry_enabled  IS 'TRUE 이면 SNS 공유 후 랜덤 게임 재도전 1회 허용';

-- =============================================================
-- [06] event_reward_catalog
-- 역할  : 보상 카탈로그 - 쿠폰·포인트·상품·꽝·다시한번더 등록
--         event에 종속되지 않는 독립 테이블.
--         쇼핑몰 연동(external_ref_id) 또는 자체 등록 모두 지원.
--         여러 이벤트에서 동일 카탈로그 항목을 재사용 가능.
-- 관계  :
--   - event_random_reward_pool.reward_catalog_id → event_reward_catalog.id (N:1)
--   - event_attendance_daily_reward.reward_catalog_id → event_reward_catalog.id (N:1)
--   - event_attendance_bonus_reward.reward_catalog_id → event_reward_catalog.id (N:1)
-- =============================================================
-- 예시 데이터
-- id=1, reward_type='POINT',   reward_name='포인트 100P',   point_amount=100,  coupon_group_id=NULL, external_ref_id=NULL
-- id=2, reward_type='COUPON',  reward_name='5% 할인 쿠폰',  point_amount=NULL, coupon_group_id=400,  external_ref_id=NULL
-- id=3, reward_type='NONE',    reward_name='꽝',            point_amount=NULL, coupon_group_id=NULL, external_ref_id=NULL
-- id=4, reward_type='ONEMORE', reward_name='한번더',         point_amount=NULL, coupon_group_id=NULL, external_ref_id=NULL
-- id=5, reward_type='PRODUCT', reward_name='아이패드 프로',   point_amount=NULL, coupon_group_id=NULL, external_ref_id=9001
--   → id=1~5는 여러 이벤트에서 reward_catalog_id로 참조해 재사용 가능
-- =============================================================

CREATE TABLE event_platform.event_reward_catalog (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 보상 기본 정보
     * ========================= */
    reward_type         VARCHAR(20)     NOT NULL,               -- POINT(포인트) / COUPON(쿠폰) / PRODUCT(상품) / NONE(꽝) / ONEMORE(다시한번더)
    reward_name         VARCHAR(200)    NOT NULL,               -- UI 표시 보상 이름 (예: '포인트 100P', '5% 할인쿠폰', '꽝')

    /* =========================
     * 보상 세부 정보
     * ========================= */
    point_amount        INTEGER,                                -- POINT 타입 전용: 지급 포인트 수량
    coupon_group_id     BIGINT,                                 -- COUPON 타입 전용: 쿠폰 그룹 ID (외부 시스템 참조)
    external_ref_id     BIGINT,                                 -- PRODUCT 타입 전용: 쇼핑몰 product_id / 물류 상품 id 등 외부 참조

    /* =========================
     * 상태
     * ========================= */
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 보상 풀/세팅에서 선택 불가)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_reward_catalog_type
    ON event_platform.event_reward_catalog(reward_type)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_reward_catalog IS '보상 카탈로그 - event에 독립적인 공통 보상 목록 (여러 이벤트에서 재사용 가능)';
COMMENT ON COLUMN event_platform.event_reward_catalog.reward_type     IS 'POINT=포인트, COUPON=쿠폰, PRODUCT=상품(쇼핑몰/자체등록), NONE=꽝, ONEMORE=다시한번더';
COMMENT ON COLUMN event_platform.event_reward_catalog.reward_name     IS 'UI에 노출되는 보상 이름 (예: 포인트 100P, 5% 할인쿠폰)';
COMMENT ON COLUMN event_platform.event_reward_catalog.point_amount    IS 'POINT 전용: 지급 포인트 수량';
COMMENT ON COLUMN event_platform.event_reward_catalog.coupon_group_id IS 'COUPON 전용: 외부 쿠폰 시스템 그룹 ID';
COMMENT ON COLUMN event_platform.event_reward_catalog.external_ref_id IS 'PRODUCT 전용: 쇼핑몰 상품 ID 또는 물류 상품 ID (자체 등록 시 NULL)';
COMMENT ON COLUMN event_platform.event_reward_catalog.is_active       IS 'FALSE 이면 보상 풀/세팅에서 선택 불가';

-- =============================================================
-- [07] event_participant
-- 역할  : 이벤트 참여자 명단 - 최초 자격 통과 사실만 기록 (append-only)
--         매번 eligibility 테이블을 체크하지 않도록 사전 등록.
--         - 출석 이벤트: 30일짜리도 참여 등록은 1 row
--         - 랜덤 이벤트: 최초 1회 참여 기준 1 row
--
-- ※ append-only: INSERT만 발생, UPDATE 없음
-- ※ 차단/운영 제어 → event_participant_block 참조
-- ※ 마지막 출석일    → event_entry에서 MAX(attendance_date) 파생
-- 관계  :
--   - event.id → event_participant.event_id (1:N)
--   - (event_id, member_id) UNIQUE
-- =============================================================
-- 예시 데이터
-- id=1, event_id=1, member_id=10001, eligibility_policy_version=1, created_at='2026-03-01 09:10:00'
--   → 출석 이벤트 자격 통과, 참여 등록
-- id=2, event_id=2, member_id=10001, eligibility_policy_version=1, created_at='2026-03-01 10:00:00'
--   → 랜덤 이벤트 자격 통과, 참여 등록
-- =============================================================

CREATE TABLE event_platform.event_participant (
    id                          BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·회원 식별
     * ========================= */
    event_id                    BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    member_id                   BIGINT          NOT NULL,       -- 참여 회원 ID

    /* =========================
     * 감사 정보
     * ========================= */
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 자격 통과 및 등록 일시 (enrolled_at 겸용)
    created_by                  BIGINT          NOT NULL,       -- FK: admin.id (NULL 불가, 시스템 등록 시 system admin id 사용)

    CONSTRAINT uq_participant_event_member UNIQUE (event_id, member_id)
);

CREATE INDEX idx_participant_event
    ON event_platform.event_participant(event_id);

CREATE INDEX idx_participant_member
    ON event_platform.event_participant(member_id);

COMMENT ON TABLE  event_platform.event_participant IS '이벤트 참여자 명단 - 최초 자격 통과 시 1 row INSERT (append-only, UPDATE 없음)';
COMMENT ON COLUMN event_platform.event_participant.event_id                   IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_participant.member_id                  IS '참여 회원 ID';
COMMENT ON COLUMN event_platform.event_participant.created_at                 IS '자격 통과 및 참여 등록 일시 (enrolled_at 겸용)';
COMMENT ON COLUMN event_platform.event_participant.created_by                 IS 'FK: admin.id - 시스템 자동 등록 시 system admin id 사용';

-- =============================================================
-- [07b] event_participant_block
-- 역할  : 참여자 차단 기록 - 운영자가 특정 회원을 이벤트에서 차단할 때 INSERT
--         차단 여부 확인: SELECT EXISTS(... WHERE event_id=? AND member_id=? AND unblocked_at IS NULL)
--
-- ※ 차단 해제: unblocked_at, unblocked_by UPDATE (예외적 UPDATE 허용)
-- 관계  :
--   - event_participant.event_id + member_id → event_participant_block (논리 참조)
-- =============================================================
-- 예시 데이터
-- id=1, event_id=1, member_id=10002, blocked_reason='매크로 의심', created_by=9001, created_at='2026-03-03 00:00:00', unblocked_at=NULL
--   → 현재 차단 중
-- id=2, event_id=1, member_id=10003, blocked_reason='테스트 계정', created_by=9001, created_at='2026-03-01', unblocked_at='2026-03-02', unblocked_by=9001
--   → 차단 해제됨
-- =============================================================

CREATE TABLE event_platform.event_participant_block (
    id              BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·회원 식별
     * ========================= */
    event_id        BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    member_id       BIGINT          NOT NULL,                   -- 차단 대상 회원 ID

    /* =========================
     * 차단 정보
     * ========================= */
    blocked_reason  TEXT            NOT NULL,                   -- 차단 사유 (운영 메모)

    /* =========================
     * 차단 해제 (NULL 이면 현재 차단 중)
     * ========================= */
    unblocked_at    TIMESTAMP,                                  -- 차단 해제 일시 (NULL=차단 유지)
    unblocked_by    BIGINT,                                     -- FK: admin.id (해제 처리 관리자)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted      BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 차단 처리 일시 (blocked_at 겨용)
    created_by      BIGINT          NOT NULL,                   -- FK: admin.id (차단 처리 관리자, blocked_by 겨용)
    updated_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 최종 수정 일시
    updated_by      BIGINT          NOT NULL                    -- FK: admin.id
);

-- 현재 차단 중인 회원 빠른 조회
CREATE INDEX idx_participant_block_active
    ON event_platform.event_participant_block(event_id, member_id)
    WHERE unblocked_at IS NULL;

COMMENT ON TABLE  event_platform.event_participant_block IS '참여자 차단 기록 - 운영 차단 시 INSERT, 해제 시 unblocked_at UPDATE';
COMMENT ON COLUMN event_platform.event_participant_block.event_id      IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_participant_block.member_id     IS '차단 대상 회원 ID';
COMMENT ON COLUMN event_platform.event_participant_block.blocked_reason IS '차단 사유 (운영 메모)';
COMMENT ON COLUMN event_platform.event_participant_block.unblocked_at  IS '차단 해제 일시 - NULL 이면 현재 차단 중';
COMMENT ON COLUMN event_platform.event_participant_block.unblocked_by  IS 'FK: admin.id - 차단 해제한 관리자 (NULL 이면 미해제)';
COMMENT ON COLUMN event_platform.event_participant_block.created_at    IS '차단 처리 일시 (blocked_at 겨용)';
COMMENT ON COLUMN event_platform.event_participant_block.created_by    IS 'FK: admin.id - 차단 처리한 관리자 (blocked_by 겨용)';

-- =============================================================
-- [08] event_attendance_daily_reward
-- 역할  : 출석 이벤트 - 일일 보상 세팅
--         매일 출석 시 지급할 기본 보상을 1 row로 정의
--         (모든 날짜 동일 포인트 지급 정책)
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_attendance_daily_reward.event_id (1:1)
--   - event_reward_catalog.id → event_attendance_daily_reward.reward_catalog_id (N:1)
--   - event_type='ATTENDANCE' 인 event 에만 생성
-- =============================================================
-- 예시 데이터
-- id=1, event_id=1, reward_catalog_id=1, is_active=TRUE
--   → 매일 포인트 30p 지급 (카탈로그 id=1 참조: POINT 30P)
-- =============================================================

CREATE TABLE event_platform.event_attendance_daily_reward (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조 (1:1)
     * ========================= */
    event_id            BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (출석 이벤트 1개 = 1 row)

    /* =========================
     * 보상 카탈로그 참조
     * ========================= */
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 정보는 카탈로그 조인으로 조회)

    /* =========================
     * 상태
     * ========================= */
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 보상 지급 중단, 이벤트는 유지)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_att_daily_reward_event
    ON event_platform.event_attendance_daily_reward(event_id)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_attendance_daily_reward IS '출석 이벤트 일일 보상 세팅 - 이벤트당 1 row, 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.event_id          IS 'FK: event.id - 출석 이벤트 1개당 1 row (UNIQUE)';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.reward_catalog_id IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, point_amount 등)는 카탈로그 조인으로 조회';
COMMENT ON COLUMN event_platform.event_attendance_daily_reward.is_active         IS 'FALSE 이면 보상 지급 중단 (이벤트는 유지)';

-- =============================================================
-- [09] event_attendance_bonus_reward
-- 역할  : 출석 이벤트 - 누적/연속 보너스 보상 세팅 (복수 row)
--         누적(TOTAL) N일 출석 또는 연속(STREAK) N일 달성 시 추가 지급
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_attendance_bonus_reward.event_id (1:N)
--   - event_reward_catalog.id → event_attendance_bonus_reward.reward_catalog_id (N:1)
--   - (event_id, milestone_type, milestone_count) UNIQUE
-- =============================================================
-- 예시 데이터 (event_id=1, 30일 출석 이벤트)
-- id=1, event_id=1, milestone_type='TOTAL',  milestone_count=7,  payout_rule='ONCE',       reward_catalog_id=6
--   → 누적 7일 달성 시 포인트 500 1회 지급 (카탈로그 id=6 참조)
-- id=2, event_id=1, milestone_type='TOTAL',  milestone_count=15, payout_rule='ONCE',       reward_catalog_id=2
--   → 누적 15일 달성 시 할인쿠폰 1회 지급 (카탈로그 id=2 참조)
-- id=3, event_id=1, milestone_type='STREAK', milestone_count=3,  payout_rule='REPEATABLE', reward_catalog_id=7
--   → 3일 연속 출석할 때마다 포인트 100 반복 지급 (카탈로그 id=7 참조)
-- =============================================================

CREATE TABLE event_platform.event_attendance_bonus_reward (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (1 이벤트 N 보너스 보상)

    /* =========================
     * 달성 조건
     * ========================= */
    milestone_type      VARCHAR(20)     NOT NULL,               -- TOTAL(누적 출석) / STREAK(연속 출석)
    milestone_count     INTEGER         NOT NULL,               -- 달성 기준 일수 (예: 7, 14, 30)
    payout_rule         VARCHAR(20)     NOT NULL DEFAULT 'ONCE', -- ONCE=전체 이벤트 기간 1회 / REPEATABLE=조건 재달성 시 반복 지급

    /* =========================
     * 보상 카탈로그 참조
     * ========================= */
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 상세는 카탈로그 조인으로 조회)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL,               -- FK: admin.id

    CONSTRAINT uq_att_bonus_event_type_count UNIQUE (event_id, milestone_type, milestone_count)
);

CREATE INDEX idx_att_bonus_reward_event
    ON event_platform.event_attendance_bonus_reward(event_id, milestone_type, milestone_count)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_attendance_bonus_reward IS '출석 이벤트 누적/연속 보너스 보상 세팅 (이벤트당 N row), 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.event_id          IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.milestone_type    IS 'TOTAL=누적 N일 달성 / STREAK=연속 N일 달성';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.milestone_count   IS '달성 기준 일수 (예: 7, 14, 30)';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.payout_rule       IS 'ONCE=이벤트 통틀어 1회, REPEATABLE=조건 재달성마다 반복 지급';
COMMENT ON COLUMN event_platform.event_attendance_bonus_reward.reward_catalog_id IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, point_amount 등)는 카탈로그 조인으로 조회';

-- =============================================================
-- [10] event_random_reward_pool
-- 역할  : 랜덤 이벤트 보상 풀 - 카탈로그 등록 + 확률 가중치 + 제한 수량 설정
--         보상 세부 정보는 reward_catalog_id 조인으로 조회
-- 관계  :
--   - event.id → event_random_reward_pool.event_id (1:N)
--   - event_reward_catalog.id → event_random_reward_pool.reward_catalog_id (N:1)
--   - event_random_reward_pool.id → event_random_reward_counter.reward_pool_id (1:1)
--   - event_random_reward_pool.id → event_entry.reward_pool_id (1:N)
-- =============================================================
-- 예시 데이터 (event_id=2, 룰렛 이벤트 6칸)
-- id=1, event_id=2, reward_catalog_id=1, probability_weight=60, daily_limit=NULL, total_limit=NULL,  priority=1
--   → 포인트 100P, 60% 확률, 무제한
-- id=2, event_id=2, reward_catalog_id=2, probability_weight=25, daily_limit=50,   total_limit=500,  priority=2
--   → 5% 할인쿠폰, 25% 확률, 일 50개·전체 500개 제한
-- id=3, event_id=2, reward_catalog_id=5, probability_weight=5,  daily_limit=1,    total_limit=10,   priority=3
--   → 아이패드 프로, 5% 확률, 일 1개·전체 10개 제한
-- id=4, event_id=2, reward_catalog_id=4, probability_weight=5,  daily_limit=NULL, total_limit=NULL, priority=4
--   → 다시한번더(ONEMORE), 5% 확률
-- id=5, event_id=2, reward_catalog_id=3, probability_weight=5,  daily_limit=NULL, total_limit=NULL, priority=5
--   → 꽝(NONE), 5% 확률
-- =============================================================

CREATE TABLE event_platform.event_random_reward_pool (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·카탈로그 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    reward_catalog_id   BIGINT          NOT NULL
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (보상 상세는 카탈로그 조인으로 조회)

    /* =========================
     * 확률 가중치
     * ========================= */
    probability_weight  INTEGER         NOT NULL,               -- 가중치 (실제확률 = 이 값 / 이벤트 전체 가중치 합, 예: 60이면 60%)

    /* =========================
     * 수량 제한
     * ========================= */
    daily_limit         INTEGER,                                -- 일일 최대 당첨 수량 (NULL = 무제한)
    total_limit         INTEGER,                                -- 전체 기간 최대 당첨 수량 (NULL = 무제한)

    /* =========================
     * 정렬·상태
     * ========================= */
    priority            INTEGER         NOT NULL DEFAULT 0,     -- UI 슬롯 표시 순서 (낮을수록 앞)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 당첨 대상 제외)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_random_pool_event_priority
    ON event_platform.event_random_reward_pool(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_random_reward_pool IS '랜덤 이벤트 보상 풀 - 확률 가중치·일일/전체 제한 수량 설정, 보상 상세는 reward_catalog 조인';
COMMENT ON COLUMN event_platform.event_random_reward_pool.event_id           IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_random_reward_pool.reward_catalog_id  IS 'FK: event_reward_catalog.id - 보상 상세 정보(reward_type, 금액 등)는 카탈로그 조인으로 조회';
COMMENT ON COLUMN event_platform.event_random_reward_pool.probability_weight IS '가중치 - 실제확률 = 이 값 / 이벤트 전체 가중치 합 (예: 60)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.daily_limit        IS '일일 최대 당첨 수량 (NULL=무제한)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.total_limit        IS '전체 기간 최대 당첨 수량 (NULL=무제한)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.priority           IS 'UI 슬롯 표시 순서 (낮을수록 앞)';
COMMENT ON COLUMN event_platform.event_random_reward_pool.is_active          IS 'FALSE 이면 당첨 풀에서 제외';

-- =============================================================
-- [11] event_random_reward_counter
-- 역할  : 랜덤 보상 풀 당첨 카운터 - 일일·전체 제한 관리
--         daily_limit / total_limit 초과 여부를 빠르게 조회하기 위한 집계 테이블
-- 관계  :
--   - event_random_reward_pool.id → event_random_reward_counter.reward_pool_id (1:1)
-- =============================================================
-- 예시 데이터
-- reward_pool_id=2 (5% 할인쿠폰), daily_count=12, total_count=87, last_reset_date='2026-03-05'
--   → 오늘 12개 당첨, 전체 87개 당첨
-- reward_pool_id=3 (아이패드 프로), daily_count=1, total_count=3, last_reset_date='2026-03-05'
--   → daily_limit=1 초과로 오늘 더 이상 당첨 불가
-- =============================================================

CREATE TABLE event_platform.event_random_reward_counter (
    reward_pool_id      BIGINT          PRIMARY KEY
        REFERENCES event_platform.event_random_reward_pool(id) ON DELETE CASCADE, -- FK: event_random_reward_pool.id (1:1)

    /* =========================
     * 카운터
     * ========================= */
    daily_count         INTEGER         NOT NULL DEFAULT 0,     -- 오늘(last_reset_date 기준) 당첨 수량
    total_count         INTEGER         NOT NULL DEFAULT 0,     -- 이벤트 전체 기간 누적 당첨 수량
    last_reset_date     DATE            NOT NULL DEFAULT CURRENT_DATE, -- daily_count 마지막 초기화 날짜

    /* =========================
     * 갱신 시각
     * ========================= */
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP -- 마지막 카운터 갱신 일시
);

COMMENT ON TABLE  event_platform.event_random_reward_counter IS '랜덤 보상 풀 당첨 카운터 (일일·전체 제한 관리용)';
COMMENT ON COLUMN event_platform.event_random_reward_counter.reward_pool_id  IS 'FK(PK): event_random_reward_pool.id - 1:1 대응';
COMMENT ON COLUMN event_platform.event_random_reward_counter.daily_count     IS '오늘 당첨된 수량 (last_reset_date 기준, 자정마다 0으로 초기화)';
COMMENT ON COLUMN event_platform.event_random_reward_counter.total_count     IS '이벤트 전체 기간 누적 당첨 수량';
COMMENT ON COLUMN event_platform.event_random_reward_counter.last_reset_date IS 'daily_count가 마지막으로 0으로 초기화된 날짜';
COMMENT ON COLUMN event_platform.event_random_reward_counter.updated_at      IS '카운터 마지막 업데이트 일시';

-- =============================================================
-- [12] event_share_policy
-- 역할  : SNS 공유 정책 - 공유가 참여권을 만드는지, 몇 번까지 허용하는지
-- 관계  :
--   - event_random_policy.event_id → event_share_policy.event_id (0:1 선택적)
--     event_random_policy.sns_retry_enabled=TRUE 인 랜덤 이벤트에만 row 존재
--     row 없음 = SNS 공유 기능 미사용
-- =============================================================
-- 예시 데이터
-- event_id=2, max_share_credit=1
--   → SNS 공유 1회당 참여권 1회 추가
-- event_id=3, max_share_credit=3
--   → SNS 공유 최대 3회까지 참여권 추가
-- =============================================================

CREATE TABLE event_platform.event_share_policy (
    event_id                BIGINT          PRIMARY KEY
        REFERENCES event_platform.event_random_policy(event_id) ON DELETE CASCADE,
        -- FK: event_random_policy.event_id
        -- sns_retry_enabled=TRUE 인 랜덤 이벤트에만 생성 가능
        -- 종속성 체인: event → event_random_policy → event_share_policy

    /* =========================
     * 공유로 얻는 최대 참여권 수
     * ========================= */
    max_share_credit        INTEGER         NOT NULL DEFAULT 0,  -- 공유로 얻을 수 있는 최대 추가 참여 횟수 (0=참여권 증가 없음)


    /* =========================
     * 감사 정보
     * ========================= */
    created_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT          NOT NULL,           -- FK: admin.id
    updated_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT          NOT NULL            -- FK: admin.id
);

COMMENT ON TABLE  event_platform.event_share_policy IS 'SNS 공유 정책 - row 존재 자체가 공유 활성화를 의미, 최대 참여권 수 설정';
COMMENT ON COLUMN event_platform.event_share_policy.event_id         IS 'FK(PK): event_random_policy.event_id - sns_retry_enabled=TRUE 인 랜덤 이벤트에만 존재 (0:1 선택적)';
COMMENT ON COLUMN event_platform.event_share_policy.max_share_credit IS '공유로 얻을 수 있는 최대 추가 참여 횟수 (0이면 기록만 하고 참여권 없음)';

-- =============================================================
-- [13] event_share_log
-- 역할  : SNS 공유 링크 클릭 append-only 로그
--
-- 흐름:
--   1. 공유자(sharer_member_id)가 공유 버튼 클릭 → share_token 발급
--   2. 공유자가 임의 채널로 URL 공유 (token이 URL에 포함됨)
--   3. 수신자가 링크 클릭 → 서버에 share_token 전달 → 이 테이블에 INSERT
--   4. 잔여 참여권 계산:
--      COUNT(*) WHERE event_id=? AND sharer_member_id=? >= max_share_credit?
--      → 아니면 공유자에게 랜덤 1회 추가 실행 권한 부여
--
-- 관계  :
--   - event_share_policy.event_id → event_share_log.event_id (1:N)
--     SNS 공유 정책이 있는 랜덤 이벤트에만 로그 생성 가능
--
-- =============================================================
-- 예시 데이터 (event_id=2, max_share_credit=2)
-- ─ 공유자: member_id=10001, share_token='tok-A' 발급 후 카카오 공유
-- id=1, event_id=2, share_token='tok-A', sharer_member_id=10001, visitor_member_id=20002, created_at='2026-03-05 11:00'
--   → 10001이 공유한 링크를 20002가 클릭 (클릭 1회)
-- id=2, event_id=2, share_token='tok-A', sharer_member_id=10001, visitor_member_id=20003, created_at='2026-03-05 11:05'
--   → 20003도 클릭 (클릭 2회)
-- → COUNT(*) WHERE share_token='tok-A' = 2 >= max_share_credit(2) → 참여권 2개 달성
-- =============================================================

CREATE TABLE event_platform.event_share_log (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 식별
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event_share_policy(event_id) ON DELETE CASCADE,
        -- FK: event_share_policy.event_id
        -- SNS 공유 정책이 존재하는 랜덤 이벤트에만 로그 생성 가능

    /* =========================
     * 공유 토큰 (공유자 식별)
     * ========================= */
    share_token         VARCHAR(200)    NOT NULL,               -- 공유자의 JWT 토큰 (공유 링크 URL에 포함)
                                                                -- 같은 token이 여러 row 가능 (클릭할 때마다 INSERT)
    sharer_member_id    BIGINT          NOT NULL,               -- 링크를 공유한 회원 ID (token에서 파싱)

    /* =========================
     * 방문자 정보
     * ========================= */
    visitor_member_id   BIGINT,                                 -- 링크를 클릭한 회원 ID (NULL=비회원 방문자)

    /* =========================
     * 채널 정보
     * ========================= */
    share_channel       VARCHAR(20)     NOT NULL,               -- 공유 채널: KAKAO / FACEBOOK / INSTAGRAM / TWITTER / LINK_COPY

    /* =========================
     * 보안·디버그 정보
     * ========================= */
    ip_address          VARCHAR(50),                            -- 방문자 IP (어뷰징·VPN 감지용)
    user_agent          TEXT,                                   -- 방문자 User-Agent (봇 탐지)

    /* =========================
     * 감사 정보
     * ========================= */
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP  -- 클릭 발생 일시 (append-only, 수정 없음)
);

-- 참여권 집계용 (share_token 기준 COUNT)
CREATE INDEX idx_share_log_token
    ON event_platform.event_share_log(share_token);

-- 공유자 기준 조회
CREATE INDEX idx_share_log_sharer
    ON event_platform.event_share_log(event_id, sharer_member_id, created_at);

COMMENT ON TABLE  event_platform.event_share_log IS 'SNS 공유 링크 클릭 로그 - 누군가 공유 링크를 클릭할 때마다 INSERT (append-only)';
COMMENT ON COLUMN event_platform.event_share_log.event_id         IS 'FK: event_share_policy.event_id - SNS 공유 정책이 있는 랜덤 이벤트에만 로그 생성 가능';
COMMENT ON COLUMN event_platform.event_share_log.share_token      IS '공유자의 JWT 토큰 - 같은 token이 여러 row 가능 (클릭자마다 행 생성)';
COMMENT ON COLUMN event_platform.event_share_log.sharer_member_id IS '공유 링크를 발행한 회원 ID (참여권 수혜자)';
COMMENT ON COLUMN event_platform.event_share_log.visitor_member_id IS '링크를 클릭한 회원 ID (NULL=비회원)';
COMMENT ON COLUMN event_platform.event_share_log.share_channel    IS '공유 채널: KAKAO / FACEBOOK / INSTAGRAM / TWITTER / LINK_COPY';
COMMENT ON COLUMN event_platform.event_share_log.ip_address       IS '클릭 요청 IP - 어뷰징·VPN 감지용';
COMMENT ON COLUMN event_platform.event_share_log.user_agent       IS '클릭 요청 User-Agent - 봇 탐지용';
COMMENT ON COLUMN event_platform.event_share_log.created_at       IS '링크 클릭 발생 일시 (append-only, 이후 수정 없음)';

-- =============================================================
-- [14] event_entry
-- 역할  : 출석·랜덤 이벤트 통합 행위 로그 (append-only)
--         - 실제 참여 시도만 기록 (CHECK_IN / WIN / LOSE / ALREADY_CHECKED / LIMIT_REJECT / FAILED)
--         - 기간 외(OUT_OF_PERIOD), 자격 미충족(ELIGIBILITY_REJECT)은 응답만 반환, 로그 미기록
--         - 출석 로그: attendance_date, total_attendance_count, streak_attendance_count 사용
--         - 랜덤 로그: trigger_type, reward_pool_id 사용
--         - 이벤트 유형에 따라 사용하는 컬럼이 달라짐
-- 관계  :
--   - event.id → event_entry.event_id (1:N)
--   - event_random_reward_pool.id → event_entry.reward_pool_id (N:1, 랜덤 전용)
-- =============================================================
-- 예시 데이터
-- [출석 성공]
-- id=1, event_id=1, event_type='ATTENDANCE', member_id=10001, action_result='CHECK_IN',
--        attendance_date='2026-03-05', total_attendance_count=5, streak_attendance_count=5,
--        trigger_type=NULL, reward_pool_id=NULL
--
-- [출석 중복]
-- id=2, event_id=1, event_type='ATTENDANCE', member_id=10001, action_result='ALREADY_CHECKED',
--        attendance_date='2026-03-05', failure_reason='이미 출석 완료'
--
-- [랜덤 BASE 당첨]
-- id=3, event_id=2, event_type='RANDOM', member_id=10001, action_result='WIN',
--        attendance_date=NULL, trigger_type='BASE', reward_pool_id=2
--
-- [랜덤 SNS 재도전 당첨]
-- id=4, event_id=2, event_type='RANDOM', member_id=10001, action_result='WIN',
--        attendance_date=NULL, trigger_type='SNS_SHARE', reward_pool_id=1
-- =============================================================

CREATE TABLE event_platform.event_entry (
    id                          BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·회원 식별
     * ========================= */
    event_id                    BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    event_type                  VARCHAR(20)     NOT NULL,       -- 이벤트 유형 (ATTENDANCE / RANDOM) - 조회 최적화용 비정규화
    member_id                   BIGINT          NOT NULL,       -- 행위를 수행한 회원 ID

    /* =========================
     * 행위 결과
     * ========================= */
    action_result               VARCHAR(30)     NOT NULL,       -- 실제 참여 시도 결과만 기록
    -- [공통]
    -- LIMIT_REJECT         : 참여 횟수 제한 초과
    -- FAILED               : 시스템 오류
    -- [출석 전용]
    -- CHECK_IN             : 출석 성공
    -- ALREADY_CHECKED      : 이미 출석 (중복 시도)
    -- [랜덤 전용]
    -- WIN                  : 보상 당첨
    -- LOSE                 : 꽝
    --
    -- ※ 기간 외(OUT_OF_PERIOD), 자격 미충족(ELIGIBILITY_REJECT)은 로그 미기록
    --   → Application에서 응답만 반환

    failure_reason              TEXT,                           -- 실패 사유 상세 설명 (선택, 실패 시만 사용)

    /* =========================
     * 출석 이벤트 전용 컬럼 (ATTENDANCE)
     * ========================= */
    attendance_date             DATE,                           -- 출석 기준 날짜 (KST 기준, ATTENDANCE 전용)
    total_attendance_count      INTEGER,                        -- 출석 성공 시 누적 출석 수 스냅샷 (ATTENDANCE 전용)
    streak_attendance_count     INTEGER,                        -- 출석 성공 시 연속 출석 수 스냅샷 (ATTENDANCE 전용)

    /* =========================
     * 랜덤 이벤트 전용 컬럼 (RANDOM)
     * ========================= */
    trigger_type                VARCHAR(20),                    -- 게임 시작 트리거 (BASE=기본, SNS_SHARE=SNS공유후 재도전, RANDOM 전용)
    reward_pool_id              BIGINT
        REFERENCES event_platform.event_random_reward_pool(id), -- FK: 당첨 보상 풀 (RANDOM WIN 전용, 그 외 NULL)

    /* =========================
     * 감사 정보
     * ========================= */
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP -- 행위 발생 일시 (append-only)
);

CREATE INDEX idx_event_entry_event_member_created
    ON event_platform.event_entry(event_id, member_id, created_at DESC);

CREATE INDEX idx_event_entry_member_type
    ON event_platform.event_entry(member_id, event_type, created_at DESC);

CREATE INDEX idx_event_entry_attendance_date
    ON event_platform.event_entry(event_id, attendance_date)
    WHERE event_type = 'ATTENDANCE' AND action_result = 'CHECK_IN';

COMMENT ON TABLE  event_platform.event_entry IS '출석·랜덤 통합 행위 로그 (append-only) - 실제 참여 시도만 기록, 기간외/자격미충족은 응답만 반환';
COMMENT ON COLUMN event_platform.event_entry.event_id                 IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_entry.event_type               IS '이벤트 유형 ATTENDANCE / RANDOM (조회 최적화를 위한 비정규화)';
COMMENT ON COLUMN event_platform.event_entry.member_id                IS '행위를 수행한 회원 ID';
COMMENT ON COLUMN event_platform.event_entry.action_result            IS '참여 시도 결과: CHECK_IN/ALREADY_CHECKED(출석) | WIN/LOSE(랜덤) | LIMIT_REJECT/FAILED(공통) ※ OUT_OF_PERIOD/ELIGIBILITY_REJECT는 미기록';
COMMENT ON COLUMN event_platform.event_entry.failure_reason           IS '실패 시 상세 사유 (선택)';
COMMENT ON COLUMN event_platform.event_entry.attendance_date          IS '[ATTENDANCE 전용] 출석 기준 날짜 (KST)';
COMMENT ON COLUMN event_platform.event_entry.total_attendance_count   IS '[ATTENDANCE 전용] 출석 성공 시 누적 출석 수 스냅샷';
COMMENT ON COLUMN event_platform.event_entry.streak_attendance_count  IS '[ATTENDANCE 전용] 출석 성공 시 연속 출석 수 스냅샷';
COMMENT ON COLUMN event_platform.event_entry.trigger_type             IS '[RANDOM 전용] BASE=기본 참여, SNS_SHARE=SNS공유 후 재도전';
COMMENT ON COLUMN event_platform.event_entry.reward_pool_id           IS '[RANDOM WIN 전용] FK: event_random_reward_pool.id - 당첨 보상 풀';
COMMENT ON COLUMN event_platform.event_entry.created_at               IS '행위 발생 일시 (append-only, 수정 없음)';

-- =============================================================
-- [15] event_reward_allocation
-- 역할  : 보상 지급 내역 - 출석·랜덤 이벤트 모두 이 테이블에 기록
--         외부 시스템(포인트 API, 쿠폰 API) 연동 재시도 상태 관리 포함
-- 관계  :
--   - event.id → event_reward_allocation.event_id (1:N)
--   - event_entry.id → event_reward_allocation.event_entry_id (1:1)
--   - event_reward_catalog.id → event_reward_allocation.reward_catalog_id (N:1)
-- =============================================================
-- 예시 데이터
-- [출석 일일 보상]
-- id=1, event_id=1, event_type='ATTENDANCE', reward_kind='DAILY',   member_id=10001,
--        reward_type='POINT', point_amount=30, reward_status='SUCCESS', idempotency_key='att-1-10001-2026-03-05-DAILY'
--
-- [출석 보너스 보상]
-- id=2, event_id=1, event_type='ATTENDANCE', reward_kind='BONUS',   member_id=10001,
--        reward_type='COUPON', coupon_group_id=400, reward_status='SUCCESS', idempotency_key='att-1-10001-2026-03-07-BONUS'
--
-- [랜덤 당첨 보상]
-- id=3, event_id=2, event_type='RANDOM',     reward_kind='RANDOM',  member_id=10001,
--        reward_type='POINT', point_amount=100, reward_status='SUCCESS', idempotency_key='rand-2-10001-log-3'
-- =============================================================

CREATE TABLE event_platform.event_reward_allocation (
    id                          BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트·회원 식별
     * ========================= */
    event_id                    BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id
    event_type                  VARCHAR(20)     NOT NULL,       -- ATTENDANCE / RANDOM (조회 최적화 비정규화)
    member_id                   BIGINT          NOT NULL,       -- 보상 수령 회원 ID

    /* =========================
     * 행위 로그 참조 (1:1)
     * ========================= */
    event_entry_id                BIGINT          NOT NULL UNIQUE
        REFERENCES event_platform.event_entry(id),                -- FK: event_entry.id (1 로그 = 최대 1 보상지급)

    /* =========================
     * 보상 구분
     * ========================= */
    reward_kind                 VARCHAR(20)     NOT NULL,       -- DAILY(출석일일보상) / BONUS(출석보너스보상) / RANDOM(랜덤보상)

    /* =========================
     * 보상 카탈로그 참조 (선택)
     * ========================= */
    reward_catalog_id           BIGINT
        REFERENCES event_platform.event_reward_catalog(id),     -- FK: event_reward_catalog.id (선택)

    /* =========================
     * 보상 스냅샷 (지급 시점 기준 고정)
     * ========================= */
    reward_type                 VARCHAR(20)     NOT NULL,       -- POINT / COUPON / PRODUCT / NONE / ONEMORE
    point_amount                INTEGER,                        -- POINT 전용: 지급 포인트 수량 스냅샷
    coupon_group_id             BIGINT,                         -- COUPON 전용: 쿠폰 그룹 ID 스냅샷
    external_ref_id             BIGINT,                         -- PRODUCT 전용: 외부 상품 ID 스냅샷

    /* =========================
     * 지급 처리 상태
     * ========================= */
    reward_status               VARCHAR(20)     NOT NULL DEFAULT 'PENDING', -- PENDING / PROCESSING / SUCCESS / FAILED / CANCELLED
    retry_count                 INTEGER         NOT NULL DEFAULT 0, -- 외부 API 재시도 횟수
    next_retry_at               TIMESTAMP,                      -- 다음 재시도 예정 시각 (PENDING/FAILED 일 때만 사용)

    /* =========================
     * 외부 연동 추적
     * ========================= */
    idempotency_key             VARCHAR(120)    NOT NULL,       -- 외부 API 중복 호출 방지 키 (멱등성 보장)
    external_transaction_id     VARCHAR(120),                   -- 외부 포인트·쿠폰 시스템 트랜잭션 ID

    /* =========================
     * 오류 정보
     * ========================= */
    error_code                  VARCHAR(50),                    -- 오류 코드 (외부 API 응답 코드)
    error_message               TEXT,                           -- 오류 메시지 상세

    /* =========================
     * 처리 시각
     * ========================= */
    requested_at                TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP, -- 보상 지급 요청 일시
    processed_at                TIMESTAMP,                      -- 보상 지급 완료(또는 최종 실패) 일시

    /* =========================
     * 감사 정보
     * ========================= */
    created_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_reward_grant_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX idx_reward_grant_event_member
    ON event_platform.event_reward_allocation(event_id, member_id, created_at DESC);

CREATE INDEX idx_reward_grant_retry_queue
    ON event_platform.event_reward_allocation(reward_status, next_retry_at)
    WHERE reward_status IN ('PENDING', 'FAILED');

COMMENT ON TABLE  event_platform.event_reward_allocation IS '보상 지급 내역 - 출석·랜덤 이벤트 통합 (외부 API 재시도 상태 관리 포함)';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_id               IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_type             IS '이벤트 유형 ATTENDANCE/RANDOM (비정규화, 조회 최적화)';
COMMENT ON COLUMN event_platform.event_reward_allocation.member_id              IS '보상 수령 회원 ID';
COMMENT ON COLUMN event_platform.event_reward_allocation.event_entry_id           IS 'FK: event_entry.id - 1 로그 행위당 최대 1개 보상지급 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_kind            IS 'DAILY=출석 일일보상, BONUS=출석 보너스보상, RANDOM=랜덤 당첨보상';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_catalog_id      IS 'FK: event_reward_catalog.id (선택)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_type            IS 'POINT / COUPON / PRODUCT / NONE / ONEMORE';
COMMENT ON COLUMN event_platform.event_reward_allocation.point_amount           IS 'POINT 전용 지급 포인트 (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.coupon_group_id        IS 'COUPON 전용 쿠폰 그룹 ID (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.external_ref_id        IS 'PRODUCT 전용 외부 상품 ID (지급 시점 스냅샷)';
COMMENT ON COLUMN event_platform.event_reward_allocation.reward_status          IS 'PENDING=대기, PROCESSING=처리중, SUCCESS=성공, FAILED=실패, CANCELLED=취소';
COMMENT ON COLUMN event_platform.event_reward_allocation.retry_count            IS '외부 API 재시도 횟수';
COMMENT ON COLUMN event_platform.event_reward_allocation.next_retry_at          IS '다음 재시도 예정 시각 (PENDING/FAILED 상태에서만 사용)';
COMMENT ON COLUMN event_platform.event_reward_allocation.idempotency_key        IS '외부 API 중복 호출 방지 멱등성 키 (UNIQUE)';
COMMENT ON COLUMN event_platform.event_reward_allocation.external_transaction_id IS '외부 포인트·쿠폰 시스템이 반환한 트랜잭션 ID';
COMMENT ON COLUMN event_platform.event_reward_allocation.error_code             IS '외부 API 오류 코드';
COMMENT ON COLUMN event_platform.event_reward_allocation.error_message          IS '외부 API 오류 메시지 상세';
COMMENT ON COLUMN event_platform.event_reward_allocation.requested_at           IS '보상 지급 최초 요청 일시';
COMMENT ON COLUMN event_platform.event_reward_allocation.processed_at           IS '보상 지급 완료 또는 최종 실패 처리 일시';

-- =============================================================
-- [16] event_participation_limit_policy
-- 역할  : 이벤트 공통 참여 제한 정책 (얼마까지 허용하나 - 수량 제한 전용)
-- 관계  :
--   - event.id → event_participation_limit_policy.event_id (1:N)
-- =============================================================
-- 예시 데이터 (event_id=2, 랜덤 이벤트)
-- id=1, event_id=2, limit_subject='USER',   limit_scope='DAY',    limit_metric='EXECUTION',      limit_value=1, priority=0
--   → 회원 1인당 하루 1회 실행 제한
-- id=2, event_id=2, limit_subject='USER',   limit_scope='USER',   limit_metric='EXECUTION',      limit_value=5, priority=10
--   → 회원 1인당 전체 기간 5회 실행 제한
-- id=3, event_id=2, limit_subject='GLOBAL', limit_scope='TOTAL',  limit_metric='UNIQUE_MEMBER',  limit_value=10000, priority=0
--   → 이벤트 전체 기간 최대 1만명 참여 제한
-- =============================================================

CREATE TABLE event_platform.event_participation_limit_policy (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id

    /* =========================
     * 제한 대상
     * ========================= */
    limit_subject       VARCHAR(20)     NOT NULL,               -- USER(회원 기준) / GLOBAL(이벤트 전체 기준)

    /* =========================
     * 제한 범위
     * ========================= */
    limit_scope         VARCHAR(20)     NOT NULL,               -- USER=전체기간 개인당 / DAY=일별 개인당 / HOUR=시간별 / TOTAL=이벤트 전체

    /* =========================
     * 제한 기준
     * ========================= */
    limit_metric        VARCHAR(20)     NOT NULL,               -- EXECUTION=실행 횟수 기준 / UNIQUE_MEMBER=참여 인원 기준

    /* =========================
     * 제한 값
     * ========================= */
    limit_value         INTEGER         NOT NULL,               -- 해당 scope 내 최대 허용 횟수 또는 수량 (양수만 허용)

    /* =========================
     * 우선순위·활성화
     * ========================= */
    priority            INTEGER         NOT NULL DEFAULT 0,     -- 동일 scope 복수 제한 시 적용 우선순위 (낮을수록 먼저)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 임시 비활성화 가능 (삭제 없이 끄기)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

CREATE INDEX idx_part_limit_event_priority
    ON event_platform.event_participation_limit_policy(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

CREATE INDEX idx_part_limit_scope
    ON event_platform.event_participation_limit_policy(event_id, limit_scope)
    WHERE is_deleted = FALSE AND is_active = TRUE;

COMMENT ON TABLE  event_platform.event_participation_limit_policy IS '이벤트 공통 참여 제한 정책 (수량 제한 전용, 자격 판단 없음)';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.event_id      IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.limit_subject IS 'USER=회원 기준 제한, GLOBAL=이벤트 전체 기준 제한';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.limit_scope   IS 'USER=전체기간 개인당, DAY=일별 개인당, HOUR=시간별, TOTAL=이벤트 전체 합산';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.limit_metric  IS 'EXECUTION=실행 횟수 기준, UNIQUE_MEMBER=참여 인원 기준';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.limit_value   IS '최대 허용 횟수 또는 수량 (양수)';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.priority      IS '동일 scope에 복수 제한 적용 시 평가 순서 (낮을수록 먼저)';
COMMENT ON COLUMN event_platform.event_participation_limit_policy.is_active     IS 'FALSE 이면 해당 제한 무시 (삭제 없이 끄기 가능)';

-- =============================================================
-- [17] event_display_message
-- 역할  : 안내 메시지 사전 + 이벤트별 오버라이드
--         - event_id=NULL  → 시스템 기본 메시지 (Default)
--         - event_id=있음  → 이벤트 커스텀 메시지 (Default 덮어쓰기)
--
-- 조회 전략 (Application):
--   1순위: event_id = :eventId AND message_type = ?
--   2순위: event_id IS NULL   AND message_type = ?  (폴백)
--
-- 관계  :
--   - event.id → event_display_message.event_id (0:N, 선택적)
-- =============================================================
-- 예시 데이터
-- [기본 메시지]
-- id=1, event_id=NULL, message_type='NOT_LOGGED_IN',          text='로그인이 필요한 서비스입니다.'
-- id=2, event_id=NULL, message_type='DUPLICATE_PARTICIPATION', text='이미 참여하셨습니다.'
-- id=3, event_id=NULL, message_type='OUTSIDE_PERIOD',          text='이벤트 기간이 아닙니다.'
-- id=4, event_id=NULL, message_type='CONDITION_NOT_MET',       text='참여 조건을 충족하지 않습니다.'
-- id=5, event_id=NULL, message_type='REWARD_EXHAUSTED',        text='보상이 모두 소진되었습니다.'
--
-- [이벤트 커스텀 - CONDITION_NOT_MET 오버라이드]
-- id=6, event_id=2, message_type='CONDITION_NOT_MET', text='VIP 회원만 참여 가능한 이벤트입니다.'
--   → event_id=2 조회 시 id=4 대신 id=6 반환
-- =============================================================

CREATE TABLE event_platform.event_display_message (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조 (선택)
     * ========================= */
    event_id            BIGINT
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id (NULL=기본 메시지, 값=이벤트 커스텀)

    /* =========================
     * 메시지 유형·내용
     * ========================= */
    message_type        VARCHAR(100)    NOT NULL,               -- 메시지 식별 키 (NOT_LOGGED_IN / DUPLICATE_PARTICIPATION / OUTSIDE_PERIOD / CONDITION_NOT_MET / REWARD_EXHAUSTED 등)
    text                TEXT            NOT NULL,               -- 사용자에게 표시할 메시지 본문
    lang_code           VARCHAR(10)     NOT NULL DEFAULT 'ko',  -- 언어 코드 (현재 ko 단일, 추후 다국어 확장 대비)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL,               -- FK: admin.id

    -- 동일 이벤트(또는 공통) + 메시지 유형 + 언어 중복 방지
    CONSTRAINT uq_display_message_event_type_lang UNIQUE (event_id, message_type, lang_code)
);

-- 이벤트 커스텀 + 기본 메시지 동시 조회용
CREATE INDEX idx_display_message_lookup
    ON event_platform.event_display_message(message_type, lang_code, event_id)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_display_message IS '안내 메시지 사전 - event_id=NULL 기본, event_id 있음=이벤트 커스텀 오버라이드';
COMMENT ON COLUMN event_platform.event_display_message.event_id      IS 'NULL=시스템 기본 메시지, 값=해당 이벤트 커스텀 메시지 (기본 메시지 오버라이드)';
COMMENT ON COLUMN event_platform.event_display_message.message_type  IS '메시지 유형 키: NOT_LOGGED_IN / DUPLICATE_PARTICIPATION / OUTSIDE_PERIOD / CONDITION_NOT_MET / REWARD_EXHAUSTED 등';
COMMENT ON COLUMN event_platform.event_display_message.text          IS '사용자 화면에 표시할 메시지 본문';
COMMENT ON COLUMN event_platform.event_display_message.lang_code     IS '언어 코드 (현재 ko 고정, 추후 다국어 확장 대비)';

-- =============================================================
-- [18] event_display_asset
-- 역할  : 이벤트 UI 표시용 이미지 매핑
--         각 이벤트의 상단/하단/중간/배경/버튼/룰렛 슬롯/카드(앞뒷면) 이미지 연결
-- 관계  :
--   - event.id → event_display_asset.event_id (1:N)
--   - file.id  → event_display_asset.file_id  (N:1)
-- =============================================================
-- 예시 데이터 (event_id=2, 룰렛 이벤트)
-- id=1,  event_id=2, asset_type='BACKGROUND_DESKTOP', file_id=1,  display_width=1920, display_height=600, sort_order=0
-- id=2,  event_id=2, asset_type='BACKGROUND_MOBILE',  file_id=2,  display_width=375,  display_height=667, sort_order=0
-- id=3,  event_id=2, asset_type='BUTTON_DEFAULT',     file_id=3,  display_width=200,  display_height=60,  sort_order=0
-- id=4,  event_id=2, asset_type='ROULETTE_SLOT',      file_id=4,  display_width=120,  display_height=120, sort_order=1  -- 룰렛 슬롯 1번 이미지
-- id=5,  event_id=2, asset_type='ROULETTE_SLOT',      file_id=5,  display_width=120,  display_height=120, sort_order=2  -- 룰렛 슬롯 2번 이미지
-- id=6,  event_id=3, asset_type='CARD_FRONT',         file_id=10, display_width=180,  display_height=280, sort_order=0
-- id=7,  event_id=3, asset_type='CARD_BACK',          file_id=11, display_width=180,  display_height=280, sort_order=0
-- id=8,  event_id=2, asset_type='SECTION_TOP',        file_id=6,  display_width=750,  display_height=200, sort_order=0
-- id=9,  event_id=2, asset_type='SECTION_BOTTOM',     file_id=7,  display_width=750,  display_height=200, sort_order=0
-- id=10, event_id=2, asset_type='SECTION_MIDDLE',     file_id=8,  display_width=750,  display_height=400, sort_order=0
-- =============================================================

CREATE TABLE event_platform.event_display_asset (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 참조
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,  -- FK: event.id

    /* =========================
     * 파일 참조
     * ========================= */
    file_id             BIGINT          NOT NULL
        REFERENCES event_platform.file(id),                     -- FK: file.id

    /* =========================
     * UI 슬롯 유형
     * ========================= */
    asset_type          VARCHAR(40)     NOT NULL,               -- UI 슬롯 유형 (아래 값 참고)
    -- BACKGROUND_DESKTOP : 데스크탑 배경 이미지
    -- BACKGROUND_MOBILE  : 모바일 배경 이미지
    -- SECTION_TOP        : 페이지 상단 이미지
    -- SECTION_MIDDLE     : 페이지 중간 이미지
    -- SECTION_BOTTOM     : 페이지 하단 이미지
    -- BUTTON_DEFAULT     : 기본 CTA 버튼 이미지
    -- BUTTON_ACTIVE      : 활성화 상태 버튼 이미지
    -- ROULETTE_SLOT      : 룰렛 슬롯 이미지 (sort_order로 칸 번호 구분)
    -- CARD_FRONT         : 카드 앞면 이미지
    -- CARD_BACK          : 카드 뒷면 이미지
    -- LADDER_BACKGROUND  : 사다리 배경 이미지

    /* =========================
     * UI 표시 크기 (CSS 기준 px)
     * ========================= */
    display_width       INTEGER,                                -- UI에서 표시할 너비 (CSS px, NULL 이면 원본 크기)
    display_height      INTEGER,                                -- UI에서 표시할 높이 (CSS px, NULL 이면 원본 크기)

    /* =========================
     * 정렬·상태
     * ========================= */
    sort_order          INTEGER         NOT NULL DEFAULT 0,     -- 동일 asset_type 복수 이미지 순서 (예: ROULETTE_SLOT 1~6번)
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,  -- 활성화 여부 (FALSE 이면 UI 표시 안 함)

    /* =========================
     * 감사 정보
     * ========================= */
    is_deleted          BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT          NOT NULL,               -- FK: admin.id
    updated_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT          NOT NULL                -- FK: admin.id
);

-- 이벤트 조회 최적화
CREATE INDEX idx_display_asset_event
    ON event_platform.event_display_asset(event_id)
    WHERE is_deleted = FALSE AND is_active = TRUE;

-- 동일 이벤트 + 슬롯 유형 + 순서 유니크 (룰렛 슬롯 번호 중복 방지)
CREATE UNIQUE INDEX ux_display_asset_event_type_order
    ON event_platform.event_display_asset(event_id, asset_type, sort_order)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE  event_platform.event_display_asset IS '이벤트 UI 표시용 이미지 슬롯 매핑 (배경/섹션/버튼/룰렛슬롯/카드)';
COMMENT ON COLUMN event_platform.event_display_asset.event_id       IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_display_asset.file_id        IS 'FK: file.id - 실제 S3 파일 참조';
COMMENT ON COLUMN event_platform.event_display_asset.asset_type     IS 'UI 슬롯 유형: BACKGROUND_DESKTOP/BACKGROUND_MOBILE/SECTION_TOP/SECTION_MIDDLE/SECTION_BOTTOM/BUTTON_DEFAULT/BUTTON_ACTIVE/ROULETTE_SLOT/CARD_FRONT/CARD_BACK/LADDER_BACKGROUND';
COMMENT ON COLUMN event_platform.event_display_asset.display_width  IS 'UI 표시 너비 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.display_height IS 'UI 표시 높이 (CSS px 기준, NULL=파일 원본 크기)';
COMMENT ON COLUMN event_platform.event_display_asset.sort_order     IS '동일 asset_type 내 순서 - ROULETTE_SLOT은 1=1번째칸, 2=2번째칸 등으로 사용';
COMMENT ON COLUMN event_platform.event_display_asset.is_active      IS 'FALSE 이면 UI에서 해당 슬롯 이미지 사용 안 함';
