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
