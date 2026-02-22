7일 출석체크

### 상황1

중간 누락 허용 여부 true

1 V → 30

2 V → 30

3

4

5 V → 30

6 V → 30

7 V → 30

### 상황2

중간 누락 허용 여부 false

1 V → 30

2 V → 30

3 한 번 빠져서

**출석이벤트 참여 못함**

## event_attendance_policy          -- 출석 정책 (총 일수, 누락 허용 등)

출석체크 이벤트 규칙

- 몇 일짜리 출석인지? (7일, 15일, 30일)

```sql
CREATE TABLE **event_attendance_policy** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
    
    /* ========================= 
     * 출석 기본 규칙 
     * ========================= */
    total_days INTEGER NOT NULL, -- 총 출석 목표 일수 (예: 30일)
    
    allow_missed_days BOOLEAN NOT NULL DEFAULT FALSE, -- 중간 누락 허용 여부
        
    timezone VARCHAR(50) NOT NULL DEFAULT 'Asia/Seoul', -- 출석 기준 타임존
    
    reset_time TIME NOT NULL DEFAULT '00:00', -- 08:00 초기화 시간
    
    cycle_type VARCHAR(20)
       CHECK (cycle_type IN ('DAILY','WEEKLY')), -- 24시간, 일주일에 한번
    
    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

COMMENT ON TABLE event_attendance_policy IS '출석 이벤트 기본 정책';
```