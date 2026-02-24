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
