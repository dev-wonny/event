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
