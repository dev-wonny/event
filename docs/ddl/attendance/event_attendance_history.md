## event_attendance_history (성공 1일 1회 + reward snapshot + 리트라이 가능)

여기서 운영적으로 제일 중요한 포인트 3개:

1. **유저-일자 유니크로 “최초 성공만” 확정** (이미 함)
2. **외부 사이드이펙트(포인트/쿠폰)와 DB 사이의 “재처리” 설계**
3. **보너스 REPEATABLE을 지원하려면 “이번 지급이 몇 번째 사이클인지”를 남길 방법**이 필요

### 5-1. 기본 형태(네 모델 유지 + 카운트 컬럼 추가)

`total_attendance_count`, `streak_attendance_count`를 history row에 넣는 건 OK.

(다만 동시성 때문에 “이전 history 조회”는 반드시 같은 락 범위에서.)

```sql
CREATE TABLE event_platform.**event_attendance_history** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,

    attendance_log_id BIGINT NOT NULL
        REFERENCES event_platform.event_attendance_log(id),

    attendance_date DATE NOT NULL,

    total_attendance_count INTEGER NOT NULL CHECK (total_attendance_count > 0),
    streak_attendance_count INTEGER NOT NULL CHECK (streak_attendance_count > 0),

    reward_transaction_id BIGINT,

    /* daily snapshot */
    daily_reward_type VARCHAR(20)
        CHECK (daily_reward_type IN ('POINT', 'COUPON', 'NONE')),
    daily_point_amount INTEGER,
    daily_coupon_group_id BIGINT,
    daily_rewarded_at TIMESTAMP,

    /* bonus snapshot */
    bonus_reward_type VARCHAR(20)
        CHECK (bonus_reward_type IN ('POINT', 'COUPON')),
    bonus_point_amount INTEGER,
    bonus_coupon_group_id BIGINT,
    bonus_rewarded_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    UNIQUE(event_id, member_id, attendance_date),
    UNIQUE(attendance_log_id),

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
);

CREATE INDEX idx_att_hist_member_event_date
    ON event_platform.event_attendance_history(member_id, event_id, attendance_date DESC);

CREATE INDEX idx_att_hist_lookup
    ON event_platform.event_attendance_history(event_id, member_id, attendance_date);

COMMENT ON TABLE event_platform.event_attendance_history IS
'출석 성공 이력 + 보상 스냅샷 (UI/정산 기준)';

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