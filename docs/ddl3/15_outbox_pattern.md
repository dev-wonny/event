# Outbox Pattern 설명

## 개념

DB 트랜잭션과 외부 시스템 호출의 **원자성 보장** 문제를 해결하는 패턴.

---

## 문제

```
[순진한 구현]
1. event_log INSERT          ─┐ DB 트랜잭션
2. 외부 포인트 API 호출         ─┘ ← 두 작업을 하나의 트랜잭션으로 묶을 수 없음

실패 시나리오:
  ① DB 저장 성공 + API 실패  → 보상 누락
  ② API 성공 + DB 롤백       → 이중 지급
```

---

## Outbox Pattern 해결

```
[1단계] 같은 DB 트랜잭션 안에서 두 행 INSERT
  event_log INSERT (행위 기록)
  event_reward_grant INSERT, reward_status='PENDING'  ← Outbox 역할

  → 트랜잭션 커밋 = "보상 지급 의뢰서" 확실히 저장

[2단계] 별도 Worker가 PENDING 행을 읽어 외부 API 호출
  SELECT ... WHERE reward_status IN ('PENDING', 'FAILED')
  UPDATE ... SET reward_status='PROCESSING'  ← 낙관적 락
  외부 API 호출
  UPDATE ... SET reward_status='SUCCESS' or 'FAILED'
```

---

## 현재 설계에 적용된 형태

| Outbox 개념 | 현재 구현 |
|-------------|-----------|
| Outbox 테이블 | `event_reward_grant` (PENDING행) |
| Outbox Worker | 재시도 배치 (매 1분 실행) |
| 중복 방지 | `idempotency_key UNIQUE` |
| 낙관적 락 | `WHERE reward_status='PENDING'` |

---

## Kafka 도입 시 전환 경로

```
현재 (DB 배치)
  event_reward_grant (PENDING)
    ↓ 1분 배치가 폴링
  외부 API 호출

Kafka 도입 후
  event_reward_grant (PENDING)
    ↓ Debezium/Transactional Outbox → Kafka Producer
  Kafka Topic: reward.grant.requested
    ↓ Kafka Consumer
  외부 API 호출 → 결과 DB 업데이트
```

> 도입 시점: 동시 보상 처리량이 배치 주기(1분)로는 감당 안 될 때,  
> 또는 포인트/쿠폰 API에 초당 처리량 제한이 있어 평탄화가 필요할 때.

---

## 요약

- **지금**: DB Outbox(PENDING) + 배치 Worker → 단순, 운영 부담 낮음
- **나중**: PENDING 행을 Kafka로 발행 → Consumer가 처리 (전환 비용 낮음)
