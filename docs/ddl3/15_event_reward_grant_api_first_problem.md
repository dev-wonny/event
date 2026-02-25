# API 호출 후 INSERT 방식의 문제점

## 제안된 흐름

```
1. INSERT event_entry (행위 기록)
2. 외부 API 호출 → 성공 시
3. INSERT event_reward_grant (SUCCESS)
```

---

## 문제 1. API 성공 후 INSERT 실패 → 유령 지급

```
1. INSERT event_entry          ✅
2. 외부 포인트 API 호출       ✅ (포인트 실제 지급됨)
3. INSERT event_reward_grant ❌ (DB 장애 / 네트워크 순단)

결과:
  - 고객: 포인트 받음
  - DB: 기록 없음
  - 운영: 지급 사실 파악 불가 → 감사(Audit) 불가
```

---

## 문제 2. API 실패 시 재시도 불가

```
1. INSERT event_entry          ✅
2. 외부 API 호출             ❌ (타임아웃 / 일시 장애)
3. INSERT 하지 않음

결과:
  - 보상 미지급
  - "재시도해야 한다"는 사실을 어디에도 남기지 못함
  - 배치가 재시도 대상을 찾을 방법 없음 → 영구 미지급
```

---

## 문제 3. 동시 요청 시 이중 지급

```
[요청 A] INSERT event_entry → API 호출 중...
[요청 B] INSERT event_entry → API 호출 중...  ← 중복 요청 방어 불가

결과:
  - API 두 번 호출 → 포인트 이중 지급
  - PENDING INSERT가 없으므로 UNIQUE 제약으로 막을 수도 없음
```

---

## PENDING 선 INSERT 방식이 필요한 이유

```
                 ┌──────────────────────────────────┐
                 │                                  │
1. INSERT event_entry          같은 DB 트랜잭션        │
2. INSERT event_reward_grant (PENDING)              │
                 │                                  │
                 └──────────────────────────────────┘

3. 외부 API 호출
4. UPDATE reward_status = 'SUCCESS' or 'FAILED'
```

| 상황 | PENDING 방식 | API 후 INSERT 방식 |
|------|-------------|-----------------|
| API 성공 + INSERT 실패 | PENDING row 남음 → 재처리 가능 | 기록 없음 → 감사 불가 |
| API 타임아웃 | PENDING row로 배치 재시도 | 재시도 방법 없음 |
| 동시 요청 이중 지급 | UNIQUE(idempotency_key)로 차단 | 차단 불가 |
| 운영 감사 | PENDING 이력 확인 가능 | 이력 없음 |

---

## 결론

`event_reward_grant`의 PENDING 선 INSERT는 **Outbox Pattern**의 핵심입니다.

> "외부 API를 신뢰하지 말고, DB에 의도를 먼저 기록하라."

API 호출 결과와 무관하게 `event_reward_grant`에 **지급 의뢰 사실**이 남아있어야
- 재시도 배치가 작동하고
- 운영 감사가 가능하며
- 이중 지급이 방지됩니다.
