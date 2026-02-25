# event_reward_allocation Flow

## 상태 전이

```
INSERT(PENDING) → PROCESSING → SUCCESS
                             → FAILED → (재시도) → PROCESSING → SUCCESS
                                                              → FAILED (최종)
                             → CANCELLED
```

| status | 의미 |
|--------|------|
| `PENDING` | 지급 요청 대기 중 |
| `PROCESSING` | 외부 API 호출 중 |
| `SUCCESS` | 지급 완료 |
| `FAILED` | 외부 API 실패 (재시도 대상) |
| `CANCELLED` | 이벤트 취소 등 운영 처리 |

---

## 정상 지급 흐름

```
1. 사용자가 출석/랜덤 게임 완료
   → event_entry INSERT (행위 기록)

2. 보상 지급 시작
   → event_reward_allocation INSERT (reward_status='PENDING')
      idempotency_key = 'rand-{event_id}-{member_id}-log-{log_id}'  등

3. 외부 API 호출 전 상태 전이
   UPDATE event_reward_allocation
   SET reward_status = 'PROCESSING'
   WHERE id = ? AND reward_status = 'PENDING'   ← 중복 처리 방지
   -- affected rows = 0 → 이미 다른 프로세스가 처리 중, 스킵

4. 외부 포인트/쿠폰 API 호출

5a. API 성공
   → UPDATE SET reward_status='SUCCESS',
               external_transaction_id='외부TX-xxx',
               processed_at=NOW()

5b. API 실패
   → UPDATE SET reward_status='FAILED',
               retry_count = retry_count + 1,
               next_retry_at = NOW() + interval '5 minutes',
               error_code='ERR_001',
               error_message='포인트 API timeout'
```

---

## 재시도 흐름 (배치)

```
[매 1분 실행되는 재시도 배치]

1. 재시도 대상 조회
   SELECT * FROM event_reward_allocation
   WHERE reward_status IN ('PENDING', 'FAILED')
     AND next_retry_at <= NOW()
   ORDER BY next_retry_at ASC
   LIMIT 100;

2. 각 row: PENDING → PROCESSING 상태 전이 (낙관적 락)
   UPDATE ... WHERE id=? AND reward_status IN ('PENDING','FAILED')
   -- affected rows = 0 → 스킵

3. 외부 API 재호출 (idempotency_key로 중복 방지)

4. 성공/실패 상태 업데이트 (정상 흐름과 동일)
```

---

## 동시성 문제가 없는 이유

```
회원 10001 보상 → id=1 row UPDATE  ─┐
회원 10002 보상 → id=2 row UPDATE  ─┼── 각자 다른 row, 락 충돌 없음
회원 10003 보상 → id=3 row UPDATE  ─┘

재시도 배치 + 원래 요청이 id=1 동시 접근
  → WHERE reward_status='PENDING' 조건으로 하나만 성공
  → affected rows=0 인 쪽은 자동 스킵
```

---

## 중복 지급 방지 (idempotency_key)

```sql
-- 동일 idempotency_key는 UNIQUE 제약으로 INSERT 자체가 차단
INSERT INTO event_reward_allocation (..., idempotency_key)
VALUES (..., 'rand-2-10001-log-3')
ON CONFLICT (idempotency_key) DO NOTHING;
-- → affected rows=0 이면 이미 지급 요청 있음, 무시
```

**idempotency_key 생성 규칙:**

| 보상 종류 | 형식 | 예시 |
|-----------|------|------|
| 출석 일일 | `att-{event_id}-{member_id}-{date}-DAILY` | `att-1-10001-2026-03-05-DAILY` |
| 출석 보너스 | `att-{event_id}-{member_id}-{date}-BONUS-{milestone}` | `att-1-10001-2026-03-07-BONUS-7` |
| 랜덤 | `rand-{event_id}-{member_id}-log-{log_id}` | `rand-2-10001-log-3` |

---

## 재시도 인덱스

```sql
-- 재시도 배치가 사용하는 인덱스
CREATE INDEX idx_reward_grant_retry_queue
    ON event_reward_allocation(reward_status, next_retry_at)
    WHERE reward_status IN ('PENDING', 'FAILED');
```
