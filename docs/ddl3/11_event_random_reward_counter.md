# event_random_reward_counter 운영 방식

## 역할

`event_random_reward_pool`의 `daily_limit` / `total_limit` 초과 여부를 빠르게 판단하기 위한 **집계 카운터 테이블**.

---

## UPDATE 방식 (현재 설계)

이 테이블은 **INSERT가 아니라 UPDATE**로 운영한다.  
`reward_pool_id` 1개당 항상 **1 row만 존재**하며, 당첨 시마다 카운터를 `+1` UPDATE한다.

### 당첨 처리 쿼리

```sql
UPDATE event_random_reward_counter
SET
    daily_count     = CASE
                          WHEN last_reset_date < CURRENT_DATE THEN 1   -- 날짜 바뀌면 리셋
                          ELSE daily_count + 1
                      END,
    total_count     = total_count + 1,
    last_reset_date = CURRENT_DATE,
    updated_at      = CURRENT_TIMESTAMP
WHERE reward_pool_id = ?;
```

> `last_reset_date < CURRENT_DATE` 조건으로 별도 배치 없이 **자정 일일 초기화**를 처리한다.

---

## 실행 흐름

```
1. SELECT ... FROM event_random_reward_counter
   WHERE reward_pool_id = ?
   FOR UPDATE                    ← 동시 당첨 방지 비관적 락

2. daily_limit / total_limit 초과 여부 체크 (application)
   ├── 초과 → LIMIT_REJECT (당첨 취소)
   └── 정상 → 다음 단계

3. event_entry INSERT (WIN + reward_pool_id 기록)

4. event_reward_allocation INSERT (보상 지급 요청)

5. event_random_reward_counter UPDATE (+1)
```

---

## INSERT 방식과 비교

| 항목 | UPDATE (현재) | INSERT (로그 누적) |
|------|---------------|-------------------|
| 제한 체크 속도 | 단일 row 읽기 → **빠름** | `COUNT(*)` 집계 → **느림** |
| 동시성 제어 | `FOR UPDATE` 락 | 집계 시점 race condition 발생 가능 |
| 구현 복잡도 | 낮음 | 낮음 |
| 데이터 보존 | 최신 집계만 유지 | 이력 전부 보존 |

> 제한 체크가 핵심 목적이므로 **집계 속도 우선 → UPDATE 방식** 채택.  
> 당첨 이력 자체는 `event_entry`에 append-only로 보존된다.

---

## Redis 도입 시 대체 가능

Redis를 사용하면 이 테이블 없이 원자적으로 처리 가능하다.

```
# 일일 카운터
INCR  event:pool:{id}:daily:{yyyyMMdd}
EXPIRE event:pool:{id}:daily:{yyyyMMdd} 86400

# 전체 카운터
INCR  event:pool:{id}:total
```

> Redis 도입 시 `event_random_reward_counter` 테이블은 **제거 대상**.  
> 현재 설계는 DB only 환경 기준이다.
