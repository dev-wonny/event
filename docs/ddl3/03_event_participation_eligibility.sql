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
