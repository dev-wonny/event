-- =============================================================
-- [14] event_log
-- 역할  : 출석·랜덤 이벤트 통합 행위 로그 (append-only)
--         - 출석 로그: attendance_date, total_attendance_count, streak_attendance_count 사용
--         - 랜덤 로그: trigger_type, reward_pool_id 사용
--         - 이벤트 유형에 따라 사용하는 컬럼이 달라짐
-- 관계  :
--   - event.id → event_log.event_id (1:N)
--   - event_random_reward_pool.id → event_log.reward_pool_id (N:1, 랜덤 전용)
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
-- [랜덤 BASE 시작]
-- id=3, event_id=2, event_type='RANDOM', member_id=10001, action_result='WIN',
--        attendance_date=NULL, trigger_type='BASE', reward_pool_id=2
--
-- [랜덤 SNS 재도전]
-- id=4, event_id=2, event_type='RANDOM', member_id=10001, action_result='WIN',
--        attendance_date=NULL, trigger_type='SNS_SHARE', reward_pool_id=1
-- =============================================================

CREATE TABLE event_platform.event_log (
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
    action_result               VARCHAR(30)     NOT NULL,       -- 행위 결과 (아래 값 참고)
    -- [공통]
    -- OUT_OF_PERIOD        : 이벤트 기간 외
    -- ELIGIBILITY_REJECT   : 자격 조건 미충족
    -- LIMIT_REJECT         : 참여 횟수 제한 초과
    -- FAILED               : 시스템 오류
    -- [출석 전용]
    -- CHECK_IN             : 출석 성공
    -- ALREADY_CHECKED      : 이미 출석(중복)
    -- [랜덤 전용]
    -- WIN                  : 보상 당첨
    -- LOSE                 : 꽝

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

CREATE INDEX idx_event_log_event_member_created
    ON event_platform.event_log(event_id, member_id, created_at DESC);

CREATE INDEX idx_event_log_member_type
    ON event_platform.event_log(member_id, event_type, created_at DESC);

CREATE INDEX idx_event_log_attendance_date
    ON event_platform.event_log(event_id, attendance_date)
    WHERE event_type = 'ATTENDANCE' AND action_result = 'CHECK_IN';

COMMENT ON TABLE  event_platform.event_log IS '출석·랜덤 통합 행위 로그 (append-only) - 출석/랜덤 이벤트 유형에 따라 사용 컬럼 다름';
COMMENT ON COLUMN event_platform.event_log.event_id                 IS 'FK: event.id';
COMMENT ON COLUMN event_platform.event_log.event_type               IS '이벤트 유형 ATTENDANCE / RANDOM (조회 최적화를 위한 비정규화)';
COMMENT ON COLUMN event_platform.event_log.member_id                IS '행위를 수행한 회원 ID';
COMMENT ON COLUMN event_platform.event_log.action_result            IS '행위 결과: CHECK_IN/ALREADY_CHECKED(출석) | WIN/LOSE(랜덤) | 공통(OUT_OF_PERIOD/ELIGIBILITY_REJECT/LIMIT_REJECT/FAILED)';
COMMENT ON COLUMN event_platform.event_log.failure_reason           IS '실패 시 상세 사유 (선택)';
COMMENT ON COLUMN event_platform.event_log.attendance_date          IS '[ATTENDANCE 전용] 출석 기준 날짜 (KST)';
COMMENT ON COLUMN event_platform.event_log.total_attendance_count   IS '[ATTENDANCE 전용] 출석 성공 시 누적 출석 수 스냅샷';
COMMENT ON COLUMN event_platform.event_log.streak_attendance_count  IS '[ATTENDANCE 전용] 출석 성공 시 연속 출석 수 스냅샷';
COMMENT ON COLUMN event_platform.event_log.trigger_type             IS '[RANDOM 전용] BASE=기본 참여, SNS_SHARE=SNS공유 후 재도전';
COMMENT ON COLUMN event_platform.event_log.reward_pool_id           IS '[RANDOM WIN 전용] FK: event_random_reward_pool.id - 당첨 보상 풀';
COMMENT ON COLUMN event_platform.event_log.created_at               IS '행위 발생 일시 (append-only, 수정 없음)';
