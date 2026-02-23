### 예시 조건

**3일에는 100을 주게**

7일에는 500을 주게

### 상황1

**policy : 중간 누락 허용 여부 true**

**bonus reward : TOTAL**

1 V → 30

2 V → 30

3 빠져서

4 V → 30 + 100 (누적 3일 보상)

5 V → 30

6 V → 30

7 V → 30 + 없음

### 상황1-2

**policy : 중간 누락 허용 여부 true**

**bonus reward : TOTAL**

1 V → 30 (1)

2 V → 30 (2)

3 빠져서

4 V → 30 + 100 (3: 누적 보상 100)

5 V → 30 (4)

6 V → 30 (5)

7 V → 30 (6)

8 빠짐

9 V → 30 (7 : 누적보상 500)

10

11

12

13

14

### 상황2

**policy : 중간 누락 허용 여부 true**

**bonus reward : STREAK**

1 V → 30

2 V → 30

3 빠져서

4 V → 30 + (steak 연속성 없음 0으로 시작)

5 V → 30

6 V → 30  +  100 얻음(3일 연속 출석 얻음)

7 V → 30

### 상황2-1

**policy : 중간 누락 허용 여부 true**

**bonus reward : STREAK**

1 V → 30

2 V → 30

3 빠짐

4 V → 30 + (steak 연속성 없음 0으로 시작)

5 V → 30

6 V → 30  +  100 얻음(3일 연속 출석 얻음)

7 V → 30

8 빠짐

9 V → 30  + (steak 연속성 없음 0으로 시작)

10 V → 30

11 V → 30 +  100 얻음(3일 연속 출석 얻음) ←이거 중복으로 3일누적 또 줄건지 여부 → idDuplicateReward

## event_attendance_bonus_reward    -- 누적 보너스 보상 정의

- 여러개의 row 생성

```sql
CREATE TABLE event_attendance_bonus_reward (
    id BIGSERIAL PRIMARY KEY,
    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
    
    milestone_count INTEGER NOT NULL,
        -- 예: 7일, 14일, 30일

    milestone_type VARCHAR(20) NOT NULL
        -- TOTAL: 누적 출석
        -- STREAK: 연속 출석
        
    payout_rule VARCHAR(20) NOT NULL DEFAULT 'ONCE'
        -- ONCE: 이벤트 전체 1회
        -- REPEATABLE: 조건 재달성 시 반복 지급    
    -- idDuplicateReward -- 중복 지급 여부
    
    /* ========================= 
     * 보상 정보 
     * ========================= */
     
    reward_catalog_id BIGINT NULL
       REFERENCES event_platform.event_reward_catalog(id),
    
    
    reward_type VARCHAR(20) NOT NULL
    -- 'POINT', 'COUPON'
    
    point_amount INTEGER,
    coupon_group_id BIGINT,

    

    /* ========================= 
     * 감사 컬럼 
     * ========================= */
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,
    
   UNIQUE(event_id, milestone_type, milestone_count)
);

CREATE INDEX idx_attendance_bonus_event ON event_attendance_bonus_reward(event_id) 
    WHERE is_deleted = FALSE;
CREATE INDEX idx_att_bonus_reward_event
    ON event_platform.event_attendance_bonus_reward(event_id, milestone_type, milestone_count)
    WHERE is_deleted = FALSE;

COMMENT ON TABLE event_platform.event_attendance_bonus_reward IS '출석 이벤트 누적/연속 보너스 보상 정의';  
COMMENT ON TABLE event_attendance_bonus_reward IS '출석 이벤트 누적 보너스 보상';

```

제약사항은 db로하면 느려지기때문에 application에서 처리
```
    CONSTRAINT chk_bonus_reward_match
    CHECK (
        (reward_type = 'POINT' 
            AND point_amount IS NOT NULL 
            AND coupon_group_id IS NULL)
        OR
        (reward_type = 'COUPON' 
            AND coupon_group_id IS NOT NULL 
            AND point_amount IS NULL)
    ),
```