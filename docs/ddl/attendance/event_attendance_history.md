# event_attendance_history (성공 1일 1회 + reward snapshot + 리트라이 가능)

핵심 정의

- event_attendance_history = "출석 성공 확정 이력(1일 1회)"
- INSERT로 확정하고 끝 (가급적 UPDATE 하지 않음)
- 보상 지급 결과/재시도는 event_attendance_reward_log로 분리
- 이 테이블에 넣을 것

출석 성공 사실
- 출석 기준일(attendance_date)
- 누적/연속 카운트 스냅샷 (total, streak)
- 어떤 attendance_log에서 성공했는지 추적용 FK

이 테이블에서 뺄 것 (추천)

- daily_rewarded_at, bonus_rewarded_at
- reward_transaction_id
- 보상 지급 성공/실패 상태
- 보상 재시도 관련 컬럼
위 값들은 event_attendance_reward_log가 담당.

- created_at: 저장 시각
- attendance_date: 정책 기준으로 확정된 출석일

```sql
CREATE TABLE event_platform.event_attendance_history (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,

    attendance_log_id BIGINT NOT NULL
        REFERENCES event_platform.event_attendance_log(id),

    -- 정책 timezone 기준으로 계산된 출석일
    attendance_date DATE NOT NULL,

    -- 출석 성공 시점의 진행 상태 스냅샷
    total_attendance_count INTEGER NOT NULL CHECK (total_attendance_count > 0),
    streak_attendance_count INTEGER NOT NULL CHECK (streak_attendance_count > 0),
    CONSTRAINT chk_attendance_count_order
        CHECK (streak_attendance_count <= total_attendance_count),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 같은 이벤트에서 같은 회원의 같은 날짜 출석은 1회만 성공
    CONSTRAINT uq_att_history_event_member_date
        UNIQUE (event_id, member_id, attendance_date),

    -- 하나의 성공 log는 하나의 history로만 연결
    CONSTRAINT uq_att_history_log
        UNIQUE (attendance_log_id)
);

CREATE INDEX idx_att_history_event_member_date_desc
    ON event_platform.event_attendance_history(event_id, member_id, attendance_date DESC);

CREATE INDEX idx_att_history_member_event_date_desc
    ON event_platform.event_attendance_history(member_id, event_id, attendance_date DESC);

COMMENT ON TABLE event_platform.event_attendance_history IS
'출석 성공 확정 이력 (1일 1회, append-only)';

);

CREATE INDEX idx_att_hist_member_event_date
    ON event_platform.event_attendance_history(member_id, event_id, attendance_date DESC);

CREATE INDEX idx_att_hist_lookup
    ON event_platform.event_attendance_history(event_id, member_id, attendance_date);

COMMENT ON TABLE event_platform.event_attendance_history IS
'출석 성공 이력 + 보상 스냅샷 (UI/정산 기준)';

- 아래는 db로 하지않고 application으로 처리, 느리지 않게
```

    CONSTRAINT chk_daily_reward_match CHECK (
        daily_reward_type IS NULL
        OR
        (daily_reward_type = 'POINT'
            AND daily_point_amount IS NOT NULL
            AND daily_coupon_group_id IS NULL)
        OR
        (daily_reward_type = 'COUPON'
            AND daily_coupon_group_id IS NOT NULL
            AND daily_point_amount IS NULL)
        OR
        (daily_reward_type = 'NONE')
    ),

    CONSTRAINT chk_bonus_reward_match CHECK (
        bonus_reward_type IS NULL
        OR
        (bonus_reward_type = 'POINT'
            AND bonus_point_amount IS NOT NULL
            AND bonus_coupon_group_id IS NULL)
        OR
        (bonus_reward_type = 'COUPON'
            AND bonus_coupon_group_id IS NOT NULL
            AND bonus_point_amount IS NULL)
    )
```

### 운영 플로우

```
1️⃣ redis lock 획득 (event_id + member_id)

2️⃣ eligibility / limit 체크

3️⃣ 실패
    **→ event_attendance_log INSERT (FAIL)**
    → unlock
    **→ return

4️⃣** e**vent_attendance_log INSERT (CHECK_IN)**
    → log_id 확보

5️⃣ hi**story INSERT 먼저 시도  ⭐⭐⭐ 핵심
    →** UNIQUE(event_id, member_id, attendance_date)

    성공하면:
        → 내가 최초 출석자
    실패하면:
        → 이미 출석됨
        → reward skip
        → unlock
        **→ return

6️⃣ re**w**ard 지급 (POINT / COUPON API)
    →** external side effect

**7️⃣ history.daily_rewarded_at, reward_transaction_id UPDATE**

8️⃣ unlock
```