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
