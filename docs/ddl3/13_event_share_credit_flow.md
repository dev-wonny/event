# SNS 공유 추가 참여권 Flow

## 관련 테이블

| 테이블 | 역할 |
|--------|------|
| `event_random_policy` | `sns_retry_enabled` 여부 |
| `event_share_policy` | 최대 참여권 수(`max_share_credit`) |
| `event_share_log` | 링크 클릭마다 row INSERT |
| `event_log` | SNS 참여권으로 게임 실행 시 `trigger_type='SNS_SHARE'` |

---

## 전체 Flow

```
[1단계] 공유자 A, 공유 버튼 클릭
        → Server: A의 share_token (JWT) 발급
        → 공유 URL: https://event.com/share?token=eyJhbG...

[2단계] A가 임의 채널(KAKAO/NAVER 등)로 URL 공유

[3단계] 수신자 B, C ... 가 링크 클릭
        → event_share_log INSERT 1 row씩
           sharer_member_id = A, visitor_member_id = B(or C)

[4단계] A가 나중에 게임 화면 접속
        → 잔여 참여권 계산 (2 COUNT 쿼리)
        → 잔여 > 0 이면 "추가 참여권 N개" 버튼 활성화

[5단계] A가 버튼 클릭 → 랜덤 게임 실행
        → event_log INSERT (trigger_type='SNS_SHARE')
        → event_reward_grant INSERT (보상 지급)
```

---

## 예시 (max_share_credit = 2)

### 상황

| 시각 | 이벤트 |
|------|--------|
| 10:00 | A, 공유 버튼 클릭 → share_token='tok-A' 발급 |
| 10:05 | A, 카카오로 URL 공유 |
| 10:10 | B가 링크 클릭 → share_log id=1 INSERT |
| 10:15 | A, 게임 화면 접속 |
| 10:16 | A, 추가 참여권 사용 → 게임 실행 → event_log INSERT |
| 11:00 | C가 링크 클릭 → share_log id=2 INSERT |
| 11:10 | A, 게임 화면 재접속 |
| 11:11 | A, 추가 참여권 사용 → 게임 실행 → event_log INSERT |
| 12:00 | D가 링크 클릭 → share_log id=3 INSERT |
| 12:10 | A, 게임 화면 재접속 → 잔여 0개 → 버튼 비활성화 |

---

### 10:15 A 접속 시 잔여 계산

```sql
-- ① 획득 (B가 1번 클릭, max=2 → LEAST(1,2)=1)
earned = 1

-- ② 사용 (아직 SNS_SHARE 실행 없음)
used   = 0

-- ③ 잔여
remaining = 1 - 0 = 1  →  버튼 활성화 ✅
```

### 11:10 A 접속 시 잔여 계산

```sql
-- ① 획득 (B,C 클릭 2회, max=2 → LEAST(2,2)=2)
earned = 2

-- ② 사용 (10:16에 SNS_SHARE 1회 실행)
used   = 1

-- ③ 잔여
remaining = 2 - 1 = 1  →  버튼 활성화 ✅
```

### 12:10 A 접속 시 잔여 계산

```sql
-- ① 획득 (B,C,D 클릭 3회, max=2 → LEAST(3,2)=2)
earned = 2

-- ② 사용 (10:16, 11:11에 SNS_SHARE 2회 실행)
used   = 2

-- ③ 잔여
remaining = 2 - 2 = 0  →  버튼 비활성화 ❌
```

---

## 잔여 참여권 계산 쿼리

```sql
SELECT
    (LEAST(share_clicks.cnt, esp.max_share_credit) - sns_used.cnt) AS remaining
FROM
    event_share_policy esp,
    (
        SELECT COUNT(*) AS cnt
        FROM event_share_log
        WHERE event_id = :eventId
          AND sharer_member_id = :memberId
    ) share_clicks,
    (
        SELECT COUNT(*) AS cnt
        FROM event_log
        WHERE event_id = :eventId
          AND member_id = :memberId
          AND trigger_type = 'SNS_SHARE'
    ) sns_used
WHERE esp.event_id = :eventId;
```

---

## 핵심 포인트

- `share_token`은 클릭을 **공유자에게 귀속**시키는 수단 (`sharer_member_id` 기록용)
- 잔여 참여권은 `member_id`만 알면 **언제든지 계산 가능** (token 불필요)
- `event_log.trigger_type = 'SNS_SHARE'` 가 "사용한 참여권" 추적의 핵심
