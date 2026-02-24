# 참여 제한 설계

## 제한 레이어 구분

이벤트의 참여 제한은 **목적이 다른 3개 레이어**로 나뉩니다.

| 레이어 | 테이블 | 제한 대상 |
|--------|--------|-----------|
| 1. 이벤트 참여 제한 | `event_participation_limit_policy` | 유저가 이벤트에 참여 할 수 있는 횟수 |
| 2. SNS 보너스 상한 | `event_share_policy.max_share_credit` | SNS 공유로 얻는 추가 참여권 최대 수 |
| 3. 보상 수량 제한 | `event_random_reward_pool.daily_limit / total_limit` | 특정 보상의 당첨 가능 수량 |

---

## 1. 이벤트 참여 제한 (`event_participation_limit_policy`)

> "이 유저가 이벤트에 참여 할 수 있는가?"

```sql
-- 예시: 하루 1회 + 전체 기간 5회
id=1, event_id=2, limit_subject='USER', limit_scope='DAY',   limit_metric='EXECUTION', limit_value=1
id=2, event_id=2, limit_subject='USER', limit_scope='USER',  limit_metric='EXECUTION', limit_value=5
```

**체크 시점:** 이벤트 참여 버튼 클릭 시

---

## 2. SNS 보너스 상한 (`event_share_policy.max_share_credit`)

> "SNS 공유로 얼마나 추가 참여권을 줄 것인가?"

```sql
-- 예시: SNS 공유로 최대 2회 추가 참여 가능
event_id=2, max_share_credit=2
```

**`participation_limit_policy`에 넣지 않는 이유:**
- SNS 공유는 "게임 실행 제한"이 아니라 "보너스 획득 상한" 개념
- `limit_scope='SNS_SHARE'` 같은 도메인 특화 값이 들어가면 범용성 깨짐
- `event_share_policy` row가 없으면(SNS 미사용) 이 제한도 의미 없음 → 정합성 위험

**체크 시점:** A가 게임 화면 재접속 시 잔여 참여권 계산

---

## 3. 보상 수량 제한 (`event_random_reward_pool`)

> "이 보상이 아직 남아있는가?"

```sql
-- 예시: 아이패드 하루 1개, 전체 10개 한정
daily_limit=1, total_limit=10  (event_random_reward_counter로 추적)
```

**체크 시점:** 랜덤 추첨 후 당첨 보상 확정 시

---

## Application 체크 순서

```
[게임 실행 요청]

Step 1. participation_limit_policy 확인
        → 오늘 실행 횟수 >= limit_value? → 참여 거부

Step 2. (SNS 경로인 경우) share_credit 잔여 확인
        → earned - used <= 0? → 추가 참여권 없음

Step 3. 추첨 실행 → 당첨 보상 선정

Step 4. reward_pool.daily_limit / total_limit 확인
        (event_random_reward_counter 기준)
        → 소진됐으면 next 보상으로 fallback 또는 꽝 처리

Step 5. 당첨 확정 → event_log + event_reward_grant INSERT
```
