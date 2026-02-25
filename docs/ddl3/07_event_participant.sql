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
