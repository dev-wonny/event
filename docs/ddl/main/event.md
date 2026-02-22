# 이벤트 마스터

```sql
CREATE TABLE event_platform.event (
    id BIGSERIAL PRIMARY KEY,

    /* =========================
     * 기본 식별 정보
     * ========================= */
    title VARCHAR(200) NOT NULL,        -- 이벤트 제목
    description TEXT,                   -- 이벤트 상세 설명
    supplier_id BIGINT NOT NULL,        -- 주최사 ID (FK 권장)

    /* =========================
     * 2. 이벤트 유형
     * ========================= */
    event_type VARCHAR(20) NOT NULL
        CHECK (event_type IN ('ATTENDANCE', 'RANDOM_REWARD', 'DRAW')),
        -- ATTENDANCE: 출석 체크 이벤트 (매일 방문 시 보상)
        -- RANDOM_REWARD: 즉시 추첨형 (룰렛, 퀴즈 등 참여 즉시 결과)
        -- DRAW: 응모 후 추첨형 (구매 시 응모권 발급 → 추후 추첨)

    /* ========================= 
     * 상태 및 운영 정보 
     * ========================= */
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' 
        CHECK (status IN ('DRAFT', 'ACTIVE', 'PAUSED', 'ENDED', 'CANCELLED')),
        -- DRAFT: 작성 중
        -- ACTIVE: 진행 중
        -- PAUSED: 일시 정지
        -- ENDED: 종료됨
        -- CANCELLED: 취소됨

    is_visible BOOLEAN NOT NULL DEFAULT TRUE, -- 전시 여부 (숨김 처리 가능)
    display_order INTEGER NOT NULL DEFAULT 0, -- 전시 정렬 순서 (작을수록 우선)

    /* ========================= 
     * 이벤트 기간 
     * ========================= */
    start_at TIMESTAMP NOT NULL, -- 이벤트 시작 일시
    end_at TIMESTAMP NOT NULL,   -- 이벤트 종료 일시

    /* =========================
     * 감사
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    /* =========================
     * 제약
     * ========================= */
    CONSTRAINT chk_event_period CHECK (end_at > start_at)
);

CREATE INDEX idx_event_status_period ON event_platform.event(status, start_at, end_at)
    WHERE is_deleted = FALSE;

CREATE INDEX idx_event_supplier ON event_platform.event(supplier_id)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE event_platform.event IS '이벤트 마스터(정의) 테이블';
COMMENT ON COLUMN event_platform.event.event_type IS '이벤트 유형(출석/즉시보상/추첨)';

```