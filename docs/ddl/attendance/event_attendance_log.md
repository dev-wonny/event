# event_attendance_log             -- 출석 행위 로그

- 출석 시도 기록 (성공 + 실패)
- 디버깅 / 감사 / 부정행위 추적
- 절대 reward snapshot 넣지 않음

```sql
CREATE TABLE event_platform.event_attendance_log (
    id BIGSERIAL PRIMARY KEY,
    
    /* =========================
     * 이벤트 / 회원 식별
     * ========================= */
    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,

    /* =========================
     * 출석 시도 정보
     * ========================= */
    attendance_date DATE NOT NULL,
        -- 유저가 시도한 출석 기준 날짜 (timezone 정책 기준)

    action_result VARCHAR(30) NOT NULL,
            -- 'CHECK_IN',            -- 출석 성공
            -- 'ALREADY_CHECKED',     -- 이미 출석함
            -- 'LIMIT_REJECT',        -- 제한 정책에 의해 실패
            -- 'ELIGIBILITY_REJECT',  -- 참여 자격 실패
            -- 'OUT_OF_PERIOD',       -- 이벤트 기간 아님
            -- 'FAILED'               -- 시스템 오류 등
        
    
    failure_reason TEXT,
        -- 실패 시 상세 사유 (옵션)
   
    
    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
);

CREATE INDEX idx_att_log_event_member
    ON event_platform.event_attendance_log(event_id, member_id, created_at DESC);

CREATE INDEX idx_att_log_date
    ON event_platform.event_attendance_log(attendance_date);

COMMENT ON TABLE event_platform.event_attendance_log IS
'출석 이벤트 시도 로그 (성공/실패 모두 기록, append-only)';
```