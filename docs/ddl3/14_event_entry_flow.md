# event_entry 데이터 적재 Flow

## 역할

출석·랜덤 이벤트의 **게임 실행 결과만 append-only로 기록**하는 통합 로그 테이블.

| 상황 | event_entry |
|------|-----------|
| 기간 외 | ❌ 응답만 반환 |
| 자격 미충족 | ❌ 응답만 반환 |
| 횟수 제한 초과 | ❌ 응답만 반환 |
| 이미 출석 (중복) | ❌ 응답만 반환 |
| 출석 성공 (CHECK_IN) | ✅ 기록 |
| 랜덤 당첨 (WIN) | ✅ 기록 |
| 랜덤 꽝 (LOSE) | ✅ 기록 |

---

## 출석 이벤트 Flow

```
유저 출석 버튼 클릭
  │
  ├─ 기간 외           → 응답만 반환 (미기록)
  ├─ 자격 미충족        → 응답만 반환 (미기록)
  ├─ 이미 출석         → 응답만 반환 (미기록)
  └─ 출석 성공
       → event_entry INSERT (CHECK_IN, attendance_date, total_count, streak_count)
       → event_reward_allocation INSERT (일일 보상 PENDING)
       → 누적/연속 조건 달성 시 event_reward_allocation INSERT (보너스 PENDING)
```

### 출석 성공 시 저장 예시

```sql
id=1,
event_id=1, event_type='ATTENDANCE', member_id=10001,
action_result='CHECK_IN',
attendance_date='2026-03-05',
total_attendance_count=5,
streak_attendance_count=3,
trigger_type=NULL, reward_pool_id=NULL
```

---

## 랜덤 이벤트 Flow

```
유저 참여 버튼 클릭 (trigger_type: BASE or SNS_SHARE)
  │
  ├─ 기간 외           → 응답만 반환 (미기록)
  ├─ 자격 미충족        → 응답만 반환 (미기록)
  ├─ 횟수 제한 초과     → 응답만 반환 (미기록)
  └─ 추첨 실행
       ├─ 꽝 (LOSE)  → event_entry INSERT (LOSE, reward_pool_id, trigger_type)
       └─ 당첨 (WIN) → event_entry INSERT (WIN, reward_pool_id, trigger_type)
                    → event_random_reward_counter UPDATE (+1)
                    → event_reward_allocation INSERT (보상 PENDING)
```

### trigger_type 구분

| trigger_type | 의미 |
|---|---|
| `BASE` | 기본 참여 |
| `SNS_SHARE` | SNS 공유 후 추가 참여 |

### 랜덤 저장 예시

```sql
-- BASE 당첨
id=2, event_id=2, event_type='RANDOM', member_id=10001,
action_result='WIN', trigger_type='BASE', reward_pool_id=2

-- SNS_SHARE 꽝
id=3, event_id=2, event_type='RANDOM', member_id=10001,
action_result='LOSE', trigger_type='SNS_SHARE', reward_pool_id=5
```

---

## UML (Sequence Diagram)

### 출석 이벤트

```mermaid
sequenceDiagram
    actor User
    participant App
    participant DB
    participant ExtAPI as 외부 API / 쇼핑몰 DB
    participant SQS as AWS SQS
    participant DLQ as Dead Letter Queue
    participant Slack

    User->>App: 출석 버튼 클릭

    App->>App: 기간 체크 (event.start_at ~ end_at)
    alt 기간 외
        App-->>User: 응답 반환 (미기록)
    else 기간 내
        App->>DB: SELECT event_participation_eligibility WHERE event_id=?
        alt 자격 미충족
            App-->>User: 응답 반환 (미기록)
        else 자격 통과
            App->>DB: SELECT event_participant WHERE event_id=? AND member_id=?
            alt 신규 참여자
                App->>DB: INSERT event_participant (event_id, member_id)
            end
            App->>DB: SELECT event_entry WHERE event_id=? AND member_id=? AND attendance_date=today
            alt 이미 출석
                App-->>User: 응답 반환 (미기록)
            else 출석 성공
                rect rgb(220, 240, 255)
                    Note over App,DB: 🔒 트랜잭션 1 시작
                    App->>DB: INSERT event_entry (CHECK_IN, attendance_date, total_count, streak_count)
                    App->>DB: INSERT event_reward_allocation (일일 보상, status=PENDING)
                    opt 누적/연속 보너스 조건 달성
                        App->>DB: INSERT event_reward_allocation (보너스 보상, status=PENDING)
                    end
                    Note over App,DB: 🔒 트랜잭션 1 끝
                end
                App-->>User: 출석 성공 + 보상 정보 반환
                rect rgb(220, 255, 220)
                    Note over App,ExtAPI: 🔒 트랜잭션 2 시작
                    App->>ExtAPI: 보상 지급 API 호출 (포인트/쿠폰/상품)
                    alt 성공
                        ExtAPI-->>App: 지급 완료
                        App->>DB: UPDATE event_reward_allocation SET status=SUCCESS
                        Note over App,ExtAPI: 🔒 트랜잭션 2 끝
                    else 실패
                        App->>SQS: 메시지 발행 (재시도 요청)
                        Note over App,ExtAPI: 🔒 트랜잭션 2 끝 (PENDING 유지)
                        loop 최대 3회 재시도
                            SQS->>App: 메시지 수신 → 보상 지급 재시도
                            App->>ExtAPI: 보상 지급 API 재호출
                            alt 재시도 성공
                                ExtAPI-->>App: 지급 완료
                                App->>DB: UPDATE event_reward_allocation SET status=SUCCESS
                            end
                        end
                        App->>DLQ: 3회 모두 실패 → DLQ 적재
                        App->>Slack: 🚨 알림 전송 (수동 처리 요청)
                        App->>DB: UPDATE event_reward_allocation SET status=FAILED
                    end
                end
            end
        end
    end
```

### 랜덤 이벤트

```mermaid
sequenceDiagram
    actor User
    participant App
    participant DB
    participant ExtAPI as 외부 API / 쇼핑몰 DB
    participant SQS as AWS SQS
    participant DLQ as Dead Letter Queue
    participant Slack

    User->>App: 참여 버튼 클릭 (trigger_type: BASE or SNS_SHARE)

    App->>App: 기간 체크 (event.start_at ~ end_at)
    alt 기간 외
        App-->>User: 응답 반환 (미기록)
    else 기간 내
        App->>DB: SELECT event_participation_eligibility WHERE event_id=?
        alt 자격 미충족
            App-->>User: 응답 반환 (미기록)
        else 자격 통과
            App->>DB: SELECT event_participant WHERE event_id=? AND member_id=?
            alt 신규 참여자
                App->>DB: INSERT event_participant (event_id, member_id)
            end
            App->>DB: SELECT event_participation_limit_policy WHERE event_id=?
            App->>DB: SELECT COUNT(*) FROM event_entry WHERE event_id=? AND member_id=? AND DATE=today
            alt 횟수 초과
                App-->>User: 응답 반환 (미기록)
            else 추첨 실행
                App->>DB: SELECT event_random_reward_pool WHERE event_id=?
                App->>DB: SELECT event_random_reward_counter WHERE event_id=?
                App->>App: 확률 계산 → 보상 추첨
                alt 꽝 (LOSE)
                    rect rgb(220, 240, 255)
                        Note over App,DB: 🔒 트랜잭션 1 시작
                        App->>DB: INSERT event_entry (LOSE, reward_pool_id, trigger_type)
                        Note over App,DB: 🔒 트랜잭션 1 끝
                    end
                    App-->>User: 꽝 결과 반환
                else 당첨 (WIN)
                    rect rgb(220, 240, 255)
                        Note over App,DB: 🔒 트랜잭션 1 시작
                        App->>DB: INSERT event_entry (WIN, reward_pool_id, trigger_type)
                        App->>DB: UPDATE event_random_reward_counter SET daily_count+1, total_count+1
                        App->>DB: INSERT event_reward_allocation (보상, status=PENDING)
                        Note over App,DB: 🔒 트랜잭션 1 끝
                    end
                    App-->>User: 당첨 결과 + 보상 정보 반환
                    rect rgb(220, 255, 220)
                        Note over App,ExtAPI: 🔒 트랜잭션 2 시작
                        App->>ExtAPI: 보상 지급 API 호출 (포인트/쿠폰/상품)
                        alt 성공
                            ExtAPI-->>App: 지급 완료
                            App->>DB: UPDATE event_reward_allocation SET status=SUCCESS
                            Note over App,ExtAPI: 🔒 트랜잭션 2 끝
                        else 실패
                            App->>SQS: 메시지 발행 (재시도 요청)
                            Note over App,ExtAPI: 🔒 트랜잭션 2 끝 (PENDING 유지)
                            loop 최대 3회 재시도
                                SQS->>App: 메시지 수신 → 보상 지급 재시도
                                App->>ExtAPI: 보상 지급 API 재호출
                                alt 재시도 성공
                                    ExtAPI-->>App: 지급 완료
                                    App->>DB: UPDATE event_reward_allocation SET status=SUCCESS
                                end
                            end
                            App->>DLQ: 3회 모두 실패 → DLQ 적재
                            App->>Slack: 🚨 알림 전송 (수동 처리 요청)
                            App->>DB: UPDATE event_reward_allocation SET status=FAILED
                        end
                    end
                end
            end
        end
    end
```

---

## 컬럼 사용 매핑

| 컬럼 | ATTENDANCE | RANDOM |
|------|-----------|--------|
| `attendance_date` | ✅ | ❌ NULL |
| `total_attendance_count` | ✅ | ❌ NULL |
| `streak_attendance_count` | ✅ | ❌ NULL |
| `trigger_type` | ❌ NULL | ✅ |
| `reward_pool_id` | ❌ NULL | ✅ (WIN/LOSE) |
