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
