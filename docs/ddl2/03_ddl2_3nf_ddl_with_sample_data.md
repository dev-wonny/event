# DDL2 (3NF) DDL + 예시 데이터

## 개요

- 기준: PostgreSQL
- 스키마명: `event_platform_ddl2`
- 목적: `ddl3` 도메인을 3NF 기준으로 재구성한 예시 DDL 및 샘플 데이터 제공
- 특징:
  - 코드 마스터 참조
  - 보상/랜덤 정책/로그 상세 분리
  - `event_action` : `reward_grant` = `1:N`
  - 메시지 기본값/오버라이드 분리
  - 공유 토큰/클릭 로그 분리

> 운영 환경에서는 감사 컬럼, 파티셔닝, 권한, 트리거, 함수, 인덱스 튜닝을 추가로 적용하세요.

---

## 1) DDL (3NF 기준)

```sql
CREATE SCHEMA IF NOT EXISTS event_platform_ddl2;

/* ============================================================
 * 코드/기준 테이블
 * ============================================================ */
CREATE TABLE event_platform_ddl2.code_event_type (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_event_status (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_game_type (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_reward_type (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_reward_kind (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_action_result (
    code            VARCHAR(30) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_trigger_type (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_eligibility_type (
    code            VARCHAR(30) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    value_hint      VARCHAR(30) NOT NULL, -- LIST / NUMBER / BOOLEAN / STRING
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_limit_subject (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_limit_scope (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_limit_metric (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_message_type (
    code            VARCHAR(100) PRIMARY KEY,
    code_name       VARCHAR(200) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_asset_slot_type (
    code            VARCHAR(40) PRIMARY KEY,
    code_name       VARCHAR(200) NOT NULL,
    allows_multiple BOOLEAN NOT NULL DEFAULT FALSE,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE event_platform_ddl2.code_share_channel (
    code            VARCHAR(20) PRIMARY KEY,
    code_name       VARCHAR(100) NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE
);

/* ============================================================
 * 파일/콘텐츠
 * ============================================================ */
CREATE TABLE event_platform_ddl2.file_asset (
    file_asset_id       BIGINT PRIMARY KEY,
    object_key          VARCHAR(300) NOT NULL,
    original_file_name  VARCHAR(200),
    file_size           BIGINT NOT NULL,
    mime_type           VARCHAR(100) NOT NULL,
    file_extension      VARCHAR(20) NOT NULL,
    checksum_sha256     VARCHAR(64),
    pixel_width         INTEGER,
    pixel_height        INTEGER,
    is_public           BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT NOT NULL,
    CONSTRAINT uq_file_asset_object_key UNIQUE (object_key)
);

/* ============================================================
 * 이벤트 마스터/정책
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event (
    event_id            BIGINT PRIMARY KEY,
    supplier_id         BIGINT NOT NULL,
    event_type_code     VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_event_type(code),
    event_status_code   VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_event_status(code),
    title               VARCHAR(200) NOT NULL,
    description         TEXT,
    is_visible          BOOLEAN NOT NULL DEFAULT TRUE,
    display_order       INTEGER NOT NULL DEFAULT 0,
    start_at            TIMESTAMP NOT NULL,
    end_at              TIMESTAMP NOT NULL,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT NOT NULL,
    CONSTRAINT ck_event_period CHECK (end_at > start_at)
);

CREATE INDEX idx_event_supplier_type
    ON event_platform_ddl2.event(supplier_id, event_type_code)
    WHERE is_deleted = FALSE;

CREATE INDEX idx_event_status_period
    ON event_platform_ddl2.event(event_status_code, start_at, end_at)
    WHERE is_deleted = FALSE;

CREATE TABLE event_platform_ddl2.event_attendance_policy (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    total_days              INTEGER NOT NULL,
    allow_missed_days       BOOLEAN NOT NULL DEFAULT FALSE,
    reset_time              TIME NOT NULL DEFAULT '00:00',
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT ck_attendance_total_days_positive CHECK (total_days > 0)
);

CREATE TABLE event_platform_ddl2.event_random_policy (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    game_type_code          VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_game_type(code),
    sns_retry_enabled       BOOLEAN NOT NULL DEFAULT FALSE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL
);

-- 슬롯 기반 랜덤게임(룰렛/사다리) 상세 정책
CREATE TABLE event_platform_ddl2.event_random_slot_policy (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_random_policy(event_id) ON DELETE CASCADE,
    display_slot_count      INTEGER NOT NULL,
    CONSTRAINT ck_slot_policy_count_positive CHECK (display_slot_count > 0)
);

-- 퀴즈형 랜덤게임 상세 정책
CREATE TABLE event_platform_ddl2.event_random_quiz_policy (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_random_policy(event_id) ON DELETE CASCADE,
    quiz_question           TEXT NOT NULL,
    quiz_answer             VARCHAR(200) NOT NULL
);

-- 공유 활성화 이벤트에만 존재 (존재 자체가 공유 기능 사용 의미)
CREATE TABLE event_platform_ddl2.event_share_policy (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_random_policy(event_id) ON DELETE CASCADE,
    max_share_credit        INTEGER NOT NULL DEFAULT 0,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT ck_share_credit_non_negative CHECK (max_share_credit >= 0)
);

/* ============================================================
 * 보상 카탈로그 (공통 + 타입별 상세)
 * ============================================================ */
CREATE TABLE event_platform_ddl2.reward_catalog (
    reward_catalog_id       BIGINT PRIMARY KEY,
    reward_type_code        VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_reward_type(code),
    reward_name             VARCHAR(200) NOT NULL,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL
);

CREATE INDEX idx_reward_catalog_type
    ON event_platform_ddl2.reward_catalog(reward_type_code)
    WHERE is_deleted = FALSE AND is_active = TRUE;

CREATE TABLE event_platform_ddl2.reward_catalog_point (
    reward_catalog_id       BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id) ON DELETE CASCADE,
    point_amount            INTEGER NOT NULL,
    CONSTRAINT ck_reward_point_positive CHECK (point_amount > 0)
);

CREATE TABLE event_platform_ddl2.reward_catalog_coupon (
    reward_catalog_id       BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id) ON DELETE CASCADE,
    coupon_group_id         BIGINT NOT NULL
);

CREATE TABLE event_platform_ddl2.reward_catalog_product (
    reward_catalog_id       BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id) ON DELETE CASCADE,
    external_product_id     BIGINT NOT NULL
);

/* ============================================================
 * 자격/제한 규칙
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event_eligibility_rule (
    eligibility_rule_id     BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    eligibility_type_code   VARCHAR(30) NOT NULL REFERENCES event_platform_ddl2.code_eligibility_type(code),
    rule_operator           VARCHAR(20) NOT NULL, -- IN / GTE / EQ / IS_TRUE 등
    priority                INTEGER NOT NULL DEFAULT 0,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL
);

CREATE INDEX idx_eligibility_rule_event_priority
    ON event_platform_ddl2.event_eligibility_rule(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

CREATE TABLE event_platform_ddl2.event_eligibility_rule_value (
    eligibility_rule_id     BIGINT NOT NULL REFERENCES event_platform_ddl2.event_eligibility_rule(eligibility_rule_id) ON DELETE CASCADE,
    value_seq               INTEGER NOT NULL,
    value_literal           VARCHAR(200) NOT NULL,
    PRIMARY KEY (eligibility_rule_id, value_seq)
);

CREATE TABLE event_platform_ddl2.event_participation_limit_rule (
    limit_rule_id           BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    limit_subject_code      VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_limit_subject(code),
    limit_scope_code        VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_limit_scope(code),
    limit_metric_code       VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_limit_metric(code),
    limit_value             INTEGER NOT NULL,
    priority                INTEGER NOT NULL DEFAULT 0,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT ck_limit_value_positive CHECK (limit_value > 0)
);

CREATE INDEX idx_limit_rule_event_priority
    ON event_platform_ddl2.event_participation_limit_rule(event_id, priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

/* ============================================================
 * 메시지/에셋 (기본/오버라이드 분리)
 * ============================================================ */
CREATE TABLE event_platform_ddl2.message_template (
    message_type_code       VARCHAR(100) NOT NULL REFERENCES event_platform_ddl2.code_message_type(code),
    lang_code               VARCHAR(10) NOT NULL DEFAULT 'ko',
    message_text            TEXT NOT NULL,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    PRIMARY KEY (message_type_code, lang_code)
);

CREATE TABLE event_platform_ddl2.event_message_override (
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    message_type_code       VARCHAR(100) NOT NULL REFERENCES event_platform_ddl2.code_message_type(code),
    lang_code               VARCHAR(10) NOT NULL DEFAULT 'ko',
    message_text            TEXT NOT NULL,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    PRIMARY KEY (event_id, message_type_code, lang_code)
);

CREATE TABLE event_platform_ddl2.event_display_asset_binding (
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    slot_type_code          VARCHAR(40) NOT NULL REFERENCES event_platform_ddl2.code_asset_slot_type(code),
    slot_seq                INTEGER NOT NULL DEFAULT 0,
    file_asset_id           BIGINT NOT NULL REFERENCES event_platform_ddl2.file_asset(file_asset_id),
    display_width           INTEGER,
    display_height          INTEGER,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    PRIMARY KEY (event_id, slot_type_code, slot_seq),
    CONSTRAINT ck_slot_seq_non_negative CHECK (slot_seq >= 0)
);

CREATE INDEX idx_display_asset_event
    ON event_platform_ddl2.event_display_asset_binding(event_id)
    WHERE is_deleted = FALSE AND is_active = TRUE;

/* ============================================================
 * 참여자/운영 제어
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event_participant (
    participant_id          BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    member_id               BIGINT NOT NULL,
    enrolled_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enrolled_by             BIGINT NOT NULL,
    CONSTRAINT uq_participant_event_member UNIQUE (event_id, member_id)
);

CREATE INDEX idx_participant_event ON event_platform_ddl2.event_participant(event_id);
CREATE INDEX idx_participant_member ON event_platform_ddl2.event_participant(member_id);

CREATE TABLE event_platform_ddl2.event_participant_block (
    participant_block_id    BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL,
    member_id               BIGINT NOT NULL,
    blocked_reason          TEXT NOT NULL,
    blocked_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    blocked_by              BIGINT NOT NULL,
    unblocked_at            TIMESTAMP,
    unblocked_by            BIGINT,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT fk_participant_block_participant
        FOREIGN KEY (event_id, member_id)
        REFERENCES event_platform_ddl2.event_participant(event_id, member_id)
);

CREATE INDEX idx_participant_block_active
    ON event_platform_ddl2.event_participant_block(event_id, member_id)
    WHERE unblocked_at IS NULL AND is_deleted = FALSE;

/* ============================================================
 * 출석/랜덤 보상 세팅
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event_attendance_daily_reward (
    event_id                BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_attendance_policy(event_id) ON DELETE CASCADE,
    reward_catalog_id       BIGINT NOT NULL REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id),
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL
);

CREATE TABLE event_platform_ddl2.event_attendance_bonus_reward_rule (
    bonus_reward_rule_id    BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event_attendance_policy(event_id) ON DELETE CASCADE,
    milestone_type          VARCHAR(20) NOT NULL, -- TOTAL / STREAK
    milestone_count         INTEGER NOT NULL,
    payout_rule             VARCHAR(20) NOT NULL DEFAULT 'ONCE', -- ONCE / REPEATABLE
    reward_catalog_id       BIGINT NOT NULL REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id),
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT uq_att_bonus_event_milestone UNIQUE (event_id, milestone_type, milestone_count),
    CONSTRAINT ck_att_bonus_milestone_positive CHECK (milestone_count > 0),
    CONSTRAINT ck_att_bonus_milestone_type CHECK (milestone_type IN ('TOTAL', 'STREAK')),
    CONSTRAINT ck_att_bonus_payout_rule CHECK (payout_rule IN ('ONCE', 'REPEATABLE'))
);

CREATE TABLE event_platform_ddl2.event_random_reward_pool (
    reward_pool_id          BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event_random_policy(event_id) ON DELETE CASCADE,
    reward_catalog_id       BIGINT NOT NULL REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id),
    probability_weight      INTEGER NOT NULL,
    daily_limit             INTEGER,
    total_limit             INTEGER,
    pool_priority           INTEGER NOT NULL DEFAULT 0,
    is_active               BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT NOT NULL,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT NOT NULL,
    CONSTRAINT ck_reward_pool_weight_positive CHECK (probability_weight > 0),
    CONSTRAINT ck_reward_pool_daily_limit_positive CHECK (daily_limit IS NULL OR daily_limit > 0),
    CONSTRAINT ck_reward_pool_total_limit_positive CHECK (total_limit IS NULL OR total_limit > 0)
);

CREATE INDEX idx_random_pool_event_priority
    ON event_platform_ddl2.event_random_reward_pool(event_id, pool_priority)
    WHERE is_deleted = FALSE AND is_active = TRUE;

CREATE TABLE event_platform_ddl2.event_random_reward_pool_counter (
    reward_pool_id          BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_random_reward_pool(reward_pool_id) ON DELETE CASCADE,
    daily_count             INTEGER NOT NULL DEFAULT 0,
    total_count             INTEGER NOT NULL DEFAULT 0,
    last_reset_date         DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_random_counter_non_negative CHECK (daily_count >= 0 AND total_count >= 0)
);

/* ============================================================
 * SNS 공유 (토큰/클릭 분리)
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event_share_token (
    share_token_id          BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event_share_policy(event_id) ON DELETE CASCADE,
    share_token             VARCHAR(200) NOT NULL,
    sharer_member_id        BIGINT NOT NULL,
    share_channel_code      VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_share_channel(code),
    issued_at               TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at              TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_share_token UNIQUE (share_token)
);

CREATE INDEX idx_share_token_event_sharer
    ON event_platform_ddl2.event_share_token(event_id, sharer_member_id, issued_at DESC);

CREATE TABLE event_platform_ddl2.event_share_click_log (
    share_click_id          BIGINT PRIMARY KEY,
    share_token_id          BIGINT NOT NULL REFERENCES event_platform_ddl2.event_share_token(share_token_id) ON DELETE CASCADE,
    visitor_member_id       BIGINT,
    ip_address              VARCHAR(50),
    user_agent              TEXT,
    clicked_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_share_click_token ON event_platform_ddl2.event_share_click_log(share_token_id, clicked_at);

/* ============================================================
 * 사용자 행위 로그 (공통 + 상세)
 * ============================================================ */
CREATE TABLE event_platform_ddl2.event_action (
    event_action_id         BIGINT PRIMARY KEY,
    event_id                BIGINT NOT NULL REFERENCES event_platform_ddl2.event(event_id) ON DELETE CASCADE,
    member_id               BIGINT NOT NULL,
    action_result_code      VARCHAR(30) NOT NULL REFERENCES event_platform_ddl2.code_action_result(code),
    failure_reason          TEXT,
    occurred_at             TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_event_action_event_member_occurred
    ON event_platform_ddl2.event_action(event_id, member_id, occurred_at DESC);

CREATE INDEX idx_event_action_member_occurred
    ON event_platform_ddl2.event_action(member_id, occurred_at DESC);

CREATE TABLE event_platform_ddl2.event_attendance_action_detail (
    event_action_id             BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_action(event_action_id) ON DELETE CASCADE,
    attendance_date             DATE NOT NULL,
    total_attendance_count      INTEGER,
    streak_attendance_count     INTEGER,
    CONSTRAINT ck_attendance_counts_non_negative
        CHECK (
            (total_attendance_count IS NULL OR total_attendance_count >= 0) AND
            (streak_attendance_count IS NULL OR streak_attendance_count >= 0)
        )
);

CREATE INDEX idx_attendance_action_date
    ON event_platform_ddl2.event_attendance_action_detail(attendance_date);

CREATE TABLE event_platform_ddl2.event_random_action_detail (
    event_action_id         BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.event_action(event_action_id) ON DELETE CASCADE,
    trigger_type_code       VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_trigger_type(code),
    reward_pool_id          BIGINT REFERENCES event_platform_ddl2.event_random_reward_pool(reward_pool_id)
);

CREATE INDEX idx_random_action_pool
    ON event_platform_ddl2.event_random_action_detail(reward_pool_id);

/* ============================================================
 * 보상 지급 (행위 1:N 허용) + 지급 스냅샷
 * ============================================================ */
CREATE TABLE event_platform_ddl2.reward_grant (
    reward_grant_id         BIGINT PRIMARY KEY,
    event_action_id         BIGINT NOT NULL REFERENCES event_platform_ddl2.event_action(event_action_id) ON DELETE CASCADE,
    grant_sequence          SMALLINT NOT NULL DEFAULT 1,
    reward_kind_code        VARCHAR(20) NOT NULL REFERENCES event_platform_ddl2.code_reward_kind(code),
    reward_catalog_id       BIGINT NOT NULL REFERENCES event_platform_ddl2.reward_catalog(reward_catalog_id),
    reward_status           VARCHAR(20) NOT NULL DEFAULT 'PENDING', -- PENDING/PROCESSING/SUCCESS/FAILED/CANCELLED
    retry_count             INTEGER NOT NULL DEFAULT 0,
    next_retry_at           TIMESTAMP,
    idempotency_key         VARCHAR(120) NOT NULL,
    external_transaction_id VARCHAR(120),
    error_code              VARCHAR(50),
    error_message           TEXT,
    requested_at            TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at            TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_reward_grant_idempotency UNIQUE (idempotency_key),
    CONSTRAINT uq_reward_grant_action_sequence UNIQUE (event_action_id, grant_sequence),
    CONSTRAINT ck_reward_grant_status CHECK (reward_status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED')),
    CONSTRAINT ck_reward_grant_retry_non_negative CHECK (retry_count >= 0)
);

CREATE INDEX idx_reward_grant_action_created
    ON event_platform_ddl2.reward_grant(event_action_id, created_at DESC);

CREATE INDEX idx_reward_grant_retry_queue
    ON event_platform_ddl2.reward_grant(reward_status, next_retry_at)
    WHERE reward_status IN ('PENDING', 'FAILED');

-- 지급 시점 스냅샷 (카탈로그가 변경/비활성화되더라도 이력 보존)
CREATE TABLE event_platform_ddl2.reward_grant_point_snapshot (
    reward_grant_id         BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_grant(reward_grant_id) ON DELETE CASCADE,
    point_amount            INTEGER NOT NULL,
    CONSTRAINT ck_grant_point_positive CHECK (point_amount > 0)
);

CREATE TABLE event_platform_ddl2.reward_grant_coupon_snapshot (
    reward_grant_id         BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_grant(reward_grant_id) ON DELETE CASCADE,
    coupon_group_id         BIGINT NOT NULL
);

CREATE TABLE event_platform_ddl2.reward_grant_product_snapshot (
    reward_grant_id         BIGINT PRIMARY KEY REFERENCES event_platform_ddl2.reward_grant(reward_grant_id) ON DELETE CASCADE,
    external_product_id     BIGINT NOT NULL
);
```

---

## 2) 예시 데이터 (샘플 INSERT)

> 예시는 출석 이벤트 + 랜덤(룰렛) 이벤트 + SNS 공유 + 다중 보상 지급 시나리오를 포함한다.

```sql
/* ============================================================
 * 코드 데이터 (샘플에 필요한 값만 우선 등록)
 * ============================================================ */
INSERT INTO event_platform_ddl2.code_event_type (code, code_name) VALUES
('ATTENDANCE', '출석 이벤트'),
('RANDOM', '랜덤 이벤트');

INSERT INTO event_platform_ddl2.code_event_status (code, code_name) VALUES
('DRAFT', '작성중'),
('ACTIVE', '진행중'),
('PAUSED', '일시정지'),
('ENDED', '종료'),
('CANCELLED', '취소');

INSERT INTO event_platform_ddl2.code_game_type (code, code_name) VALUES
('ROULETTE', '룰렛'),
('LADDER', '사다리타기'),
('QUIZ', '퀴즈'),
('CARD', '카드뒤집기');

INSERT INTO event_platform_ddl2.code_reward_type (code, code_name) VALUES
('POINT', '포인트'),
('COUPON', '쿠폰'),
('PRODUCT', '상품'),
('NONE', '꽝'),
('ONEMORE', '한번더');

INSERT INTO event_platform_ddl2.code_reward_kind (code, code_name) VALUES
('DAILY', '출석 일일 보상'),
('BONUS', '출석 보너스 보상'),
('RANDOM', '랜덤 당첨 보상');

INSERT INTO event_platform_ddl2.code_action_result (code, code_name) VALUES
('CHECK_IN', '출석 성공'),
('ALREADY_CHECKED', '출석 중복'),
('WIN', '랜덤 당첨'),
('LOSE', '랜덤 꽝'),
('LIMIT_REJECT', '제한 초과'),
('FAILED', '시스템 실패');

INSERT INTO event_platform_ddl2.code_trigger_type (code, code_name) VALUES
('BASE', '기본 참여'),
('SNS_SHARE', 'SNS 공유 재도전');

INSERT INTO event_platform_ddl2.code_eligibility_type (code, code_name, value_hint) VALUES
('MEMBER_TYPE', '회원 유형', 'LIST'),
('MIN_JOIN_DAYS', '최소 가입일수', 'NUMBER'),
('PHONE_VERIFIED', '휴대폰 인증 여부', 'BOOLEAN');

INSERT INTO event_platform_ddl2.code_limit_subject (code, code_name) VALUES
('USER', '회원 기준'),
('GLOBAL', '전체 기준');

INSERT INTO event_platform_ddl2.code_limit_scope (code, code_name) VALUES
('DAY', '일별'),
('USER', '개인 전체기간'),
('TOTAL', '이벤트 전체기간');

INSERT INTO event_platform_ddl2.code_limit_metric (code, code_name) VALUES
('EXECUTION', '실행 횟수'),
('UNIQUE_MEMBER', '참여 회원 수');

INSERT INTO event_platform_ddl2.code_message_type (code, code_name) VALUES
('NOT_LOGGED_IN', '로그인 필요'),
('DUPLICATE_PARTICIPATION', '중복 참여'),
('OUTSIDE_PERIOD', '기간 외'),
('CONDITION_NOT_MET', '조건 미충족'),
('REWARD_EXHAUSTED', '보상 소진');

INSERT INTO event_platform_ddl2.code_asset_slot_type (code, code_name, allows_multiple) VALUES
('BACKGROUND_DESKTOP', '데스크탑 배경', FALSE),
('BACKGROUND_MOBILE', '모바일 배경', FALSE),
('BUTTON_DEFAULT', '기본 버튼', FALSE),
('ROULETTE_SLOT', '룰렛 슬롯 이미지', TRUE),
('SECTION_TOP', '상단 섹션', FALSE),
('SECTION_MIDDLE', '중간 섹션', FALSE),
('SECTION_BOTTOM', '하단 섹션', FALSE);

INSERT INTO event_platform_ddl2.code_share_channel (code, code_name) VALUES
('KAKAO', '카카오'),
('FACEBOOK', '페이스북'),
('INSTAGRAM', '인스타그램'),
('TWITTER', '트위터'),
('LINK_COPY', '링크복사');

/* ============================================================
 * 파일/이벤트 마스터
 * ============================================================ */
INSERT INTO event_platform_ddl2.file_asset (
    file_asset_id, object_key, original_file_name, file_size, mime_type, file_extension,
    checksum_sha256, pixel_width, pixel_height, is_public, created_by, updated_by
) VALUES
(1001, 'event/2026/03/banner_desktop.png', 'banner_desktop.png', 204800, 'image/png', 'png', NULL, 1920, 600, TRUE, 9001, 9001),
(1002, 'event/2026/03/banner_mobile.png',  'banner_mobile.png',   98304, 'image/png', 'png', NULL,  375, 667, TRUE, 9001, 9001),
(1003, 'event/2026/03/cta_btn.png',        'cta_btn.png',         40211, 'image/png', 'png', NULL,  200,  60, TRUE, 9001, 9001),
(1004, 'event/2026/03/roulette_slot_1.png','roulette_slot_1.png', 50123, 'image/png', 'png', NULL,  120, 120, TRUE, 9001, 9001),
(1005, 'event/2026/03/roulette_slot_2.png','roulette_slot_2.png', 50321, 'image/png', 'png', NULL,  120, 120, TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event (
    event_id, supplier_id, event_type_code, event_status_code, title, description,
    is_visible, display_order, start_at, end_at, created_by, updated_by
) VALUES
(2001, 1, 'ATTENDANCE', 'ACTIVE', '봄맞이 30일 출석 이벤트', '30일 출석 체크 이벤트', TRUE, 10, '2026-03-01 00:00:00', '2026-03-31 23:59:59', 9001, 9001),
(2002, 1, 'RANDOM',     'ACTIVE', '봄맞이 룰렛 이벤트',     '하루 1회 룰렛 이벤트',  TRUE, 20, '2026-03-01 00:00:00', '2026-03-15 23:59:59', 9001, 9001);

/* ============================================================
 * 이벤트 정책
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_attendance_policy (
    event_id, total_days, allow_missed_days, reset_time, created_by, updated_by
) VALUES
(2001, 30, TRUE, '00:00', 9001, 9001);

INSERT INTO event_platform_ddl2.event_random_policy (
    event_id, game_type_code, sns_retry_enabled, created_by, updated_by
) VALUES
(2002, 'ROULETTE', TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event_random_slot_policy (
    event_id, display_slot_count
) VALUES
(2002, 6);

INSERT INTO event_platform_ddl2.event_share_policy (
    event_id, max_share_credit, created_by, updated_by
) VALUES
(2002, 2, 9001, 9001);

/* ============================================================
 * 자격/참여 제한 규칙
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_eligibility_rule (
    eligibility_rule_id, event_id, eligibility_type_code, rule_operator, priority,
    is_active, created_by, updated_by
) VALUES
(2101, 2001, 'MEMBER_TYPE', 'IN', 0, TRUE, 9001, 9001),
(2102, 2001, 'MIN_JOIN_DAYS', 'GTE', 10, TRUE, 9001, 9001),
(2103, 2002, 'PHONE_VERIFIED', 'EQ', 0, TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event_eligibility_rule_value (
    eligibility_rule_id, value_seq, value_literal
) VALUES
(2101, 1, 'REGULAR'),
(2101, 2, 'VIP'),
(2102, 1, '30'),
(2103, 1, 'true');

INSERT INTO event_platform_ddl2.event_participation_limit_rule (
    limit_rule_id, event_id, limit_subject_code, limit_scope_code, limit_metric_code,
    limit_value, priority, is_active, created_by, updated_by
) VALUES
(2201, 2002, 'USER',   'DAY',   'EXECUTION',     1,     0, TRUE, 9001, 9001),
(2202, 2002, 'USER',   'USER',  'EXECUTION',     5,    10, TRUE, 9001, 9001),
(2203, 2002, 'GLOBAL', 'TOTAL', 'UNIQUE_MEMBER', 10000, 0, TRUE, 9001, 9001);

/* ============================================================
 * 보상 카탈로그 + 타입 상세
 * ============================================================ */
INSERT INTO event_platform_ddl2.reward_catalog (
    reward_catalog_id, reward_type_code, reward_name, is_active, created_by, updated_by
) VALUES
(3001, 'POINT',   '포인트 30P',     TRUE, 9001, 9001),
(3002, 'COUPON',  '5% 할인 쿠폰',   TRUE, 9001, 9001),
(3003, 'NONE',    '꽝',             TRUE, 9001, 9001),
(3004, 'ONEMORE', '한번더',         TRUE, 9001, 9001),
(3005, 'POINT',   '포인트 100P',    TRUE, 9001, 9001),
(3006, 'POINT',   '포인트 500P',    TRUE, 9001, 9001),
(3007, 'PRODUCT', '아이패드 프로',  TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.reward_catalog_point (reward_catalog_id, point_amount) VALUES
(3001, 30),
(3005, 100),
(3006, 500);

INSERT INTO event_platform_ddl2.reward_catalog_coupon (reward_catalog_id, coupon_group_id) VALUES
(3002, 400);

INSERT INTO event_platform_ddl2.reward_catalog_product (reward_catalog_id, external_product_id) VALUES
(3007, 9001);

/* ============================================================
 * 출석/랜덤 보상 세팅
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_attendance_daily_reward (
    event_id, reward_catalog_id, is_active, created_by, updated_by
) VALUES
(2001, 3001, TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event_attendance_bonus_reward_rule (
    bonus_reward_rule_id, event_id, milestone_type, milestone_count, payout_rule,
    reward_catalog_id, created_by, updated_by
) VALUES
(2301, 2001, 'TOTAL', 7,  'ONCE',       3006, 9001, 9001),
(2302, 2001, 'TOTAL', 15, 'ONCE',       3002, 9001, 9001),
(2303, 2001, 'STREAK', 3, 'REPEATABLE', 3005, 9001, 9001);

INSERT INTO event_platform_ddl2.event_random_reward_pool (
    reward_pool_id, event_id, reward_catalog_id, probability_weight, daily_limit, total_limit,
    pool_priority, is_active, created_by, updated_by
) VALUES
(2401, 2002, 3005, 60, NULL, NULL, 1, TRUE, 9001, 9001),
(2402, 2002, 3002, 25, 50,   500,  2, TRUE, 9001, 9001),
(2403, 2002, 3007,  5, 1,    10,   3, TRUE, 9001, 9001),
(2404, 2002, 3004,  5, NULL, NULL, 4, TRUE, 9001, 9001),
(2405, 2002, 3003,  5, NULL, NULL, 5, TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event_random_reward_pool_counter (
    reward_pool_id, daily_count, total_count, last_reset_date, updated_at
) VALUES
(2402, 12, 87, '2026-03-05', '2026-03-05 11:10:00'),
(2403,  1,  3, '2026-03-05', '2026-03-05 10:55:00');

/* ============================================================
 * 메시지 기본값 + 이벤트 오버라이드
 * ============================================================ */
INSERT INTO event_platform_ddl2.message_template (
    message_type_code, lang_code, message_text, is_active, created_by, updated_by
) VALUES
('NOT_LOGGED_IN',          'ko', '로그인이 필요한 서비스입니다.', TRUE, 9001, 9001),
('DUPLICATE_PARTICIPATION','ko', '이미 참여하셨습니다.',         TRUE, 9001, 9001),
('OUTSIDE_PERIOD',         'ko', '이벤트 기간이 아닙니다.',      TRUE, 9001, 9001),
('CONDITION_NOT_MET',      'ko', '참여 조건을 충족하지 않습니다.', TRUE, 9001, 9001),
('REWARD_EXHAUSTED',       'ko', '보상이 모두 소진되었습니다.',  TRUE, 9001, 9001);

INSERT INTO event_platform_ddl2.event_message_override (
    event_id, message_type_code, lang_code, message_text, is_active, created_by, updated_by
) VALUES
(2002, 'CONDITION_NOT_MET', 'ko', 'VIP 회원만 참여 가능한 룰렛 이벤트입니다.', TRUE, 9001, 9001);

/* ============================================================
 * 이벤트 UI 에셋 매핑
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_display_asset_binding (
    event_id, slot_type_code, slot_seq, file_asset_id, display_width, display_height,
    is_active, created_by, updated_by
) VALUES
(2002, 'BACKGROUND_DESKTOP', 0, 1001, 1920, 600, TRUE, 9001, 9001),
(2002, 'BACKGROUND_MOBILE',  0, 1002,  375, 667, TRUE, 9001, 9001),
(2002, 'BUTTON_DEFAULT',     0, 1003,  200,  60, TRUE, 9001, 9001),
(2002, 'ROULETTE_SLOT',      1, 1004,  120, 120, TRUE, 9001, 9001),
(2002, 'ROULETTE_SLOT',      2, 1005,  120, 120, TRUE, 9001, 9001);

/* ============================================================
 * 참여자/차단 예시
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_participant (
    participant_id, event_id, member_id, enrolled_at, enrolled_by
) VALUES
(4001, 2001, 10001, '2026-03-01 09:10:00', 9001),
(4002, 2002, 10001, '2026-03-01 10:00:00', 9001),
(4003, 2001, 10002, '2026-03-02 08:00:00', 9001);

INSERT INTO event_platform_ddl2.event_participant_block (
    participant_block_id, event_id, member_id, blocked_reason, blocked_at, blocked_by,
    created_by, updated_by
) VALUES
(4101, 2001, 10002, '매크로 의심', '2026-03-03 00:00:00', 9001, 9001, 9001);

/* ============================================================
 * SNS 공유 토큰/클릭 로그 (토큰/클릭 분리)
 * ============================================================ */
INSERT INTO event_platform_ddl2.event_share_token (
    share_token_id, event_id, share_token, sharer_member_id, share_channel_code, issued_at
) VALUES
(7001, 2002, 'tok-A', 10001, 'KAKAO', '2026-03-05 10:50:00');

INSERT INTO event_platform_ddl2.event_share_click_log (
    share_click_id, share_token_id, visitor_member_id, ip_address, user_agent, clicked_at
) VALUES
(7101, 7001, 20002, '203.0.113.10', 'Mozilla/5.0', '2026-03-05 11:00:00'),
(7102, 7001, 20003, '203.0.113.11', 'Mozilla/5.0', '2026-03-05 11:05:00');

/* ============================================================
 * 사용자 행위 로그 + 상세
 * ============================================================ */
-- [출석 성공] 7일차 체크인
INSERT INTO event_platform_ddl2.event_action (
    event_action_id, event_id, member_id, action_result_code, failure_reason, occurred_at
) VALUES
(5001, 2001, 10001, 'CHECK_IN', NULL, '2026-03-07 09:00:00');

INSERT INTO event_platform_ddl2.event_attendance_action_detail (
    event_action_id, attendance_date, total_attendance_count, streak_attendance_count
) VALUES
(5001, '2026-03-07', 7, 7);

-- [랜덤 당첨] 기본 참여(BASE)
INSERT INTO event_platform_ddl2.event_action (
    event_action_id, event_id, member_id, action_result_code, failure_reason, occurred_at
) VALUES
(5002, 2002, 10001, 'WIN', NULL, '2026-03-05 10:55:00');

INSERT INTO event_platform_ddl2.event_random_action_detail (
    event_action_id, trigger_type_code, reward_pool_id
) VALUES
(5002, 'BASE', 2402);

/* ============================================================
 * 보상 지급 (행위 1:N 허용 예시 포함)
 * ============================================================ */
-- 출석 1회(action=5001)에서 일일보상 + 7일 보너스보상 두 건 지급
INSERT INTO event_platform_ddl2.reward_grant (
    reward_grant_id, event_action_id, grant_sequence, reward_kind_code,
    reward_catalog_id, reward_status, retry_count, idempotency_key, requested_at, processed_at
) VALUES
(6001, 5001, 1, 'DAILY', 3001, 'SUCCESS', 0, 'att-2001-10001-2026-03-07-daily', '2026-03-07 09:00:01', '2026-03-07 09:00:02'),
(6002, 5001, 2, 'BONUS', 3006, 'SUCCESS', 0, 'att-2001-10001-2026-03-07-bonus-total7', '2026-03-07 09:00:02', '2026-03-07 09:00:03');

INSERT INTO event_platform_ddl2.reward_grant_point_snapshot (
    reward_grant_id, point_amount
) VALUES
(6001, 30),
(6002, 500);

-- 랜덤 당첨 보상 지급
INSERT INTO event_platform_ddl2.reward_grant (
    reward_grant_id, event_action_id, grant_sequence, reward_kind_code,
    reward_catalog_id, reward_status, retry_count, idempotency_key, requested_at, processed_at, external_transaction_id
) VALUES
(6003, 5002, 1, 'RANDOM', 3002, 'SUCCESS', 0, 'rand-2002-10001-action-5002', '2026-03-05 10:55:01', '2026-03-05 10:55:03', 'coupon-tx-90001');

INSERT INTO event_platform_ddl2.reward_grant_coupon_snapshot (
    reward_grant_id, coupon_group_id
) VALUES
(6003, 400);
```

---

## 3) 검증용 조회 예시 (선택)

```sql
-- 1) 메시지 조회: 이벤트 오버라이드 우선, 없으면 기본값
SELECT
    COALESCE(eo.message_text, mt.message_text) AS resolved_message
FROM event_platform_ddl2.message_template mt
LEFT JOIN event_platform_ddl2.event_message_override eo
  ON eo.event_id = 2002
 AND eo.message_type_code = mt.message_type_code
 AND eo.lang_code = mt.lang_code
WHERE mt.message_type_code = 'CONDITION_NOT_MET'
  AND mt.lang_code = 'ko';

-- 2) 공유 토큰 클릭 수 (추가 참여권 계산 기초)
SELECT st.event_id, st.share_token, COUNT(cl.share_click_id) AS click_count
FROM event_platform_ddl2.event_share_token st
LEFT JOIN event_platform_ddl2.event_share_click_log cl
  ON cl.share_token_id = st.share_token_id
WHERE st.share_token = 'tok-A'
GROUP BY st.event_id, st.share_token;

-- 3) 출석 1회에서 다중 보상 지급 확인 (action=5001)
SELECT rg.event_action_id, rg.grant_sequence, rg.reward_kind_code, rc.reward_name
FROM event_platform_ddl2.reward_grant rg
JOIN event_platform_ddl2.reward_catalog rc
  ON rc.reward_catalog_id = rg.reward_catalog_id
WHERE rg.event_action_id = 5001
ORDER BY rg.grant_sequence;
```

---

## 4) 비고

- 본 DDL은 `ddl3`의 도메인 의도를 유지하면서 정규화한 예시안이다.
- 운영 최적화가 필요하면 다음을 별도로 추가한다.
  - 파티셔닝(`event_action`, `reward_grant`, `event_share_click_log`)
  - 머티리얼라이즈드 뷰/캐시
  - 동시성 제어 함수(랜덤 보상 카운터 업데이트)
  - 감사/이력 트리거
