# event_draw_round (회차)

```sql
-- 예시 데이터
-- 매주 월요일 추첨 이벤트 → 1회차, 2회차, 3회차...
-- INSERT INTO event_draw_round VALUES 
--   (1, 1, 1, 'COMPLETED', '2024-01-08 12:00:00', '2024-01-08 12:05:23', 1500, 10, ...),
--   (2, 1, 2, 'SCHEDULED', '2024-01-15 12:00:00', NULL, 0, 0, ...);

CREATE TABLE event_platform.event_draw_round (
    id BIGSERIAL PRIMARY KEY,
    
    event_id BIGINT NOT NULL REFERENCES event_platform.event(id) ON DELETE CASCADE,
    event_draw_policy_id BIGINT NOT NULL REFERENCES event_platform.event_draw_policy(id) ON DELETE CASCADE,
    draw_no INTEGER NOT NULL, -- 회차 번호 (1회차, 2회차...)

    /* ========================= 
     * 추첨 상태 
     * ========================= */
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED'
        CHECK (status IN ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')),
        -- SCHEDULED: 예정됨
        -- IN_PROGRESS: 추첨 진행 중
        -- COMPLETED: 완료됨
        -- CANCELLED: 취소됨
    
    scheduled_at TIMESTAMP NOT NULL, -- 예정 추첨 일시
    executed_at TIMESTAMP,           -- 실제 추첨 실행 일시
        
    /* ========================= 
     * 추첨 결과 요약 
     * ========================= */
    target_entry_count INTEGER NOT NULL DEFAULT 0, -- 추첨 대상 응모권 수
    winner_count INTEGER NOT NULL DEFAULT 0,       -- 실제 당첨자 수

    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,
    
    UNIQUE (event_id, draw_no)
);

CREATE INDEX idx_draw_round_event_status ON event_draw_round(event_id, status) 
    WHERE is_deleted = FALSE;

COMMENT ON TABLE event_draw_round IS '추첨 회차 정보';
```