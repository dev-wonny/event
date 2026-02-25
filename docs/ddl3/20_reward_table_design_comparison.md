# 보상 조건 테이블 설계 비교

세 가지 이벤트 타입(출석체크, 랜덤 룰렛, 응모권 추첨)을 예시 데이터와 함께 각 설계 방향에서 어떻게 표현되는지 비교합니다.

---

## 이벤트 시나리오

| 이벤트 | 설명 |
|--------|------|
| **출석체크** | 30일 이벤트 / 매일 포인트 30P / 7일 누적 시 쿠폰 1장 추가 / 3일 연속마다 포인트 100P 추가 |
| **랜덤 룰렛** | 6칸 룰렛 / 포인트·쿠폰·아이패드·다시한번·꽝 확률 배분 / 일·전체 수량 제한 |
| **응모권 추첨** | 2회차 추첨 / 1등 1명(아이패드) / 2등 5명(쿠폰) / 3등 50명(포인트) |

---

## 방향 A — 이벤트 타입별 분리 테이블 (현행 유지)

> 각 이벤트 타입마다 전용 테이블을 둔다. 도메인 용어가 명확하고 쿼리가 단순하다.

### 출석체크

**`event_attendance_daily_reward`** — 매일 지급 보상 (이벤트당 1 row)

```sql
id=1, event_id=10, reward_catalog_id=1
-- reward_catalog: POINT 30P
```

**`event_attendance_bonus_reward`** — 마일스톤 보상 (이벤트당 N row)

```sql
id=1, event_id=10, milestone_type='TOTAL',  milestone_count=7,  payout_rule='ONCE',       reward_catalog_id=2
-- → 누적 7일 달성 시 할인쿠폰 1장 (1회)

id=2, event_id=10, milestone_type='STREAK', milestone_count=3,  payout_rule='REPEATABLE', reward_catalog_id=3
-- → 3일 연속 출석마다 포인트 100P (반복)
```

---

### 랜덤 룰렛

**`event_random_reward_pool`** — 확률 풀 (이벤트당 N row)

```sql
id=1, event_id=20, reward_catalog_id=4,  probability_weight=60, daily_limit=NULL, total_limit=NULL,  priority=1
-- → 포인트 100P, 60% 확률, 무제한

id=2, event_id=20, reward_catalog_id=5,  probability_weight=20, daily_limit=50,   total_limit=500,   priority=2
-- → 5% 할인쿠폰, 20% 확률, 일 50개·전체 500개

id=3, event_id=20, reward_catalog_id=6,  probability_weight=5,  daily_limit=1,    total_limit=10,    priority=3
-- → 아이패드 프로, 5% 확률, 일 1개·전체 10개

id=4, event_id=20, reward_catalog_id=7,  probability_weight=10, daily_limit=NULL, total_limit=NULL,  priority=4
-- → 다시한번(ONEMORE), 10% 확률

id=5, event_id=20, reward_catalog_id=8,  probability_weight=5,  daily_limit=NULL, total_limit=NULL,  priority=5
-- → 꽝(NONE), 5% 확률
```

---

### 응모권 추첨

**`event_draw_prize`** — 추첨 등수별 보상 (이벤트당 N row)

```sql
-- 1회차
id=1, event_id=30, draw_round_id=1, prize_rank=1, winner_count=1,  reward_type='PRODUCT', product_id=101
-- → 1등 1명, 아이패드 프로

id=2, event_id=30, draw_round_id=1, prize_rank=2, winner_count=5,  reward_type='COUPON',  coupon_group_id=200
-- → 2등 5명, 5% 할인쿠폰

id=3, event_id=30, draw_round_id=1, prize_rank=3, winner_count=50, reward_type='POINT',   point_amount=500
-- → 3등 50명, 포인트 500P

-- 2회차 (별도 prize_rank 세트)
id=4, event_id=30, draw_round_id=2, prize_rank=1, winner_count=1,  reward_type='PRODUCT', product_id=102
-- → 1등 1명, 갤럭시 탭

id=5, event_id=30, draw_round_id=2, prize_rank=2, winner_count=10, reward_type='POINT',   point_amount=1000
-- → 2등 10명, 포인트 1000P
```

---

### A 방향 ER 구조

```
event
 ├── event_attendance_daily_reward   (1:1, 출석 전용)
 ├── event_attendance_bonus_reward   (1:N, 출석 전용)
 ├── event_random_reward_pool        (1:N, 랜덤 전용)
 │    └── event_random_reward_counter (1:1, 랜덤 전용)
 └── event_draw_prize                (1:N, 추첨 전용)  ← 추가만 하면 됨
```

**결론**: 새 이벤트 타입 추가 = 전용 테이블 추가. 기존 테이블 무변경.

---

## 방향 B — 통합 단일 테이블

> 모든 보상 조건을 하나의 테이블에 담는다. `condition_type`으로 이벤트 타입 구분.

```sql
CREATE TABLE event_platform.event_reward_condition (
    id                  BIGSERIAL PRIMARY KEY,
    event_id            BIGINT NOT NULL,
    condition_type      VARCHAR(30) NOT NULL,
    -- DAILY / ATTENDANCE_BONUS / RANDOM_POOL / DRAW_PRIZE
    reward_catalog_id   BIGINT,           -- A방향의 catalog 참조 (선택)

    -- ATTENDANCE_BONUS 전용
    milestone_type      VARCHAR(20),      -- TOTAL / STREAK
    milestone_count     INTEGER,
    payout_rule         VARCHAR(20),      -- ONCE / REPEATABLE

    -- RANDOM_POOL 전용
    probability_weight  INTEGER,
    daily_limit         INTEGER,
    total_limit         INTEGER,

    -- DRAW_PRIZE 전용
    draw_round_id       BIGINT,
    prize_rank          INTEGER,
    winner_count        INTEGER,
    reward_type         VARCHAR(20),      -- POINT / COUPON / PRODUCT
    point_amount        INTEGER,
    coupon_group_id     BIGINT,
    product_id          BIGINT,

    -- 공통
    priority            INTEGER NOT NULL DEFAULT 0,
    is_active           BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by          BIGINT NOT NULL,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by          BIGINT NOT NULL
);
```

### 출석체크 데이터 (B)

```sql
-- 매일 보상
id=1, event_id=10, condition_type='DAILY',              reward_catalog_id=1
-- milestone_type=NULL, probability_weight=NULL, prize_rank=NULL, ...

-- 마일스톤 보상
id=2, event_id=10, condition_type='ATTENDANCE_BONUS',   reward_catalog_id=2,
      milestone_type='TOTAL', milestone_count=7, payout_rule='ONCE'

id=3, event_id=10, condition_type='ATTENDANCE_BONUS',   reward_catalog_id=3,
      milestone_type='STREAK', milestone_count=3, payout_rule='REPEATABLE'
```

### 랜덤 룰렛 데이터 (B)

```sql
id=4, event_id=20, condition_type='RANDOM_POOL', reward_catalog_id=4,
      probability_weight=60, daily_limit=NULL, total_limit=NULL, priority=1
-- milestone_type=NULL, prize_rank=NULL, ...

id=5, event_id=20, condition_type='RANDOM_POOL', reward_catalog_id=5,
      probability_weight=20, daily_limit=50, total_limit=500, priority=2
```

### 응모권 추첨 데이터 (B)

```sql
id=6, event_id=30, condition_type='DRAW_PRIZE',
      draw_round_id=1, prize_rank=1, winner_count=1, reward_type='PRODUCT', product_id=101
-- reward_catalog_id=NULL, probability_weight=NULL, milestone_type=NULL, ...

id=7, event_id=30, condition_type='DRAW_PRIZE',
      draw_round_id=1, prize_rank=2, winner_count=5, reward_type='COUPON', coupon_group_id=200
```

### B 방향 문제점

```
event_reward_condition
  id=4 (RANDOM_POOL)
   └── event_random_reward_counter.reward_pool_id = ?
       → pool_id가 event_reward_condition.id를 가리켜야 하는데,
         테이블 의미가 불명확해짐

condition_type='DAILY' row는
  milestone_type, probability_weight, draw_round_id, prize_rank
  → 모두 NULL → 스파스 컬럼 다수 발생
```

**결론**: 한 테이블에 전부 담으면 nullable 컬럼이 쌓이고, 타입별 CHECK constraint가 복잡해진다.  
어드민 공통 목록 API가 필요한 경우 View로 해결하는 편이 낫다.

---

## 방향 C — 공통 슬롯 + 타입별 extension 테이블 (상속 패턴)

> 공통 메타(event_reward_slot)를 두고, 타입별 상세는 1:1 extension 테이블로 분리.

### 테이블 구조

```sql
-- 공통 껍데기
CREATE TABLE event_platform.event_reward_slot (
    id                BIGSERIAL PRIMARY KEY,
    event_id          BIGINT NOT NULL REFERENCES event_platform.event(id),
    slot_type         VARCHAR(30) NOT NULL,
    -- DAILY / ATTENDANCE_BONUS / RANDOM_POOL / DRAW_PRIZE
    reward_catalog_id BIGINT REFERENCES event_platform.event_reward_catalog(id),
    priority          INTEGER NOT NULL DEFAULT 0,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted        BOOLEAN NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by        BIGINT NOT NULL,
    updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by        BIGINT NOT NULL
);

-- 마일스톤 extension
CREATE TABLE event_platform.event_reward_slot_bonus (
    slot_id         BIGINT PRIMARY KEY REFERENCES event_platform.event_reward_slot(id),
    milestone_type  VARCHAR(20) NOT NULL,   -- TOTAL / STREAK
    milestone_count INTEGER NOT NULL,
    payout_rule     VARCHAR(20) NOT NULL    -- ONCE / REPEATABLE
);

-- 랜덤 풀 extension
CREATE TABLE event_platform.event_reward_slot_random (
    slot_id            BIGINT PRIMARY KEY REFERENCES event_platform.event_reward_slot(id),
    probability_weight INTEGER NOT NULL,
    daily_limit        INTEGER,
    total_limit        INTEGER
);

-- 추첨 등수 extension
CREATE TABLE event_platform.event_reward_slot_draw (
    slot_id       BIGINT PRIMARY KEY REFERENCES event_platform.event_reward_slot(id),
    draw_round_id BIGINT,
    prize_rank    INTEGER NOT NULL,
    winner_count  INTEGER NOT NULL
);
```

### 출석체크 데이터 (C)

```sql
-- event_reward_slot
id=1, event_id=10, slot_type='DAILY',             reward_catalog_id=1
id=2, event_id=10, slot_type='ATTENDANCE_BONUS',  reward_catalog_id=2
id=3, event_id=10, slot_type='ATTENDANCE_BONUS',  reward_catalog_id=3

-- event_reward_slot_bonus (id=2, id=3 에 대응)
slot_id=2, milestone_type='TOTAL',  milestone_count=7,  payout_rule='ONCE'
slot_id=3, milestone_type='STREAK', milestone_count=3,  payout_rule='REPEATABLE'
```

### 랜덤 룰렛 데이터 (C)

```sql
-- event_reward_slot
id=4, event_id=20, slot_type='RANDOM_POOL', reward_catalog_id=4, priority=1
id=5, event_id=20, slot_type='RANDOM_POOL', reward_catalog_id=5, priority=2
id=6, event_id=20, slot_type='RANDOM_POOL', reward_catalog_id=6, priority=3

-- event_reward_slot_random
slot_id=4, probability_weight=60, daily_limit=NULL, total_limit=NULL
slot_id=5, probability_weight=20, daily_limit=50,   total_limit=500
slot_id=6, probability_weight=5,  daily_limit=1,    total_limit=10

-- event_random_reward_counter 는 slot_id=4,5,6 참조
```

### 응모권 추첨 데이터 (C)

```sql
-- event_reward_slot
id=7, event_id=30, slot_type='DRAW_PRIZE', reward_catalog_id=NULL  -- 보상 스펙 inline
id=8, event_id=30, slot_type='DRAW_PRIZE', reward_catalog_id=NULL
id=9, event_id=30, slot_type='DRAW_PRIZE', reward_catalog_id=NULL

-- event_reward_slot_draw
slot_id=7, draw_round_id=1, prize_rank=1, winner_count=1
slot_id=8, draw_round_id=1, prize_rank=2, winner_count=5
slot_id=9, draw_round_id=1, prize_rank=3, winner_count=50

-- 보상 스펙(POINT/COUPON/PRODUCT)은 reward_catalog_id 조인 or
-- event_draw_prize 방식처럼 slot_draw 안에 reward_type 컬럼 추가
```

### C 방향 ER 구조

```
event
 └── event_reward_slot  (slot_type으로 구분)
      ├── event_reward_slot_bonus    (1:1)
      ├── event_reward_slot_random   (1:1)
      │    └── event_random_reward_counter (1:1, slot_id 참조)
      └── event_reward_slot_draw     (1:1)
```

**새 이벤트 타입 추가** = `event_reward_slot_xxx` 테이블 1개 추가 + `slot_type` ENUM 값 추가.  
`event_reward_slot` 자체는 변경 없음.

---

## 3방향 총 비교

| 항목 | A (분리형) | B (통합형) | C (상속형) |
|------|-----------|-----------|-----------|
| 새 타입 추가 | 테이블 추가 | nullable 컬럼 증가 | extension 테이블 추가 |
| 쿼리 단순성 | ⭐⭐⭐ 전용 테이블 단건 조회 | ⭐⭐⭐ 단일 테이블 | ⭐⭐ slot + extension JOIN |
| 도메인 명확성 | ⭐⭐⭐ 용어 그대로 | ⭐ condition_type에 의존 | ⭐⭐⭐ slot_type + 전용 테이블 |
| 어드민 공통 목록 | ⭐ UNION 필요 | ⭐⭐⭐ 단일 테이블 스캔 | ⭐⭐⭐ slot 테이블만 스캔 |
| 스파스 컬럼 | ⭐⭐⭐ 없음 | ⭐ 타입마다 NULL 컬럼 多 | ⭐⭐⭐ 없음 |
| 마이그레이션 비용 | ⭐⭐⭐ 현행 유지 | ⭐ 전면 재설계 | ⭐⭐ 중간 |

### 언제 무엇을 선택할까?

```
이벤트 타입이 3~4개, 각 타입 설정 화면이 독립적
  → A (현행 유지)

이벤트 타입이 5개 이상, 어드민에서 "모든 이벤트 보상 목록" 단일 조회 필요
  → C (상속형) 로 마이그레이션

빠른 프로토타이핑, 타입 확정 전 탐색 단계
  → B (통합형) 으로 시작 후 C로 리팩터
```

현 시점은 A, 미래 계획이 있다면 C로 처음부터 시작하는 게 낫습니다.

### A가 나은 경우
지금 ddl3 구조를 보면 이벤트 타입이 출석 / 랜덤 / 추첨 3개입니다. 이 3개가 사실상 확정이고, 추후 4~5번째 타입이 올 가능성이 낮거나 불확실하다면 A가 더 좋습니다.

- 쿼리가 직관적 (SELECT * FROM event_random_reward_pool WHERE event_id = ?)
- 각 팀원이 테이블 이름만 봐도 역할을 바로 이해
- 롤아웃·디버깅·모니터링 전부 쉬움
- 테이블 구조 변경이 다른 이벤트 타입에 영향 없음

### C가 나은 경우
반대로 어드민 백오피스 개발이 중요한 프로젝트라면 C가 낫습니다.

- "이벤트별 보상 세팅 목록" 같은 화면에서 event_reward_slot 테이블 하나만 조회하면 전체 타입을 리스팅할 수 있음
- 새 이벤트 타입 추가 시 기존 어드민 API를 건드리지 않아도 됨
- slot_type 기준으로 공통 CRUD 레이어를 하나로 만들 수 있음

### 제 결론
지금 당장 만든다면 A, 단 event_draw_prize 추가가 확정됐다면 그 시점에 C로 가는 게 맞습니다.

이유는 C의 구조는 "슬롯 조회 후 extension JOIN"이 항상 붙어야 해서 애플리케이션 코드 복잡도가 올라갑니다. 타입이 3개일 때 이 비용을 치를 필요가 없어요. 타입이 4~5개 넘어가면서 어드민 공통화 요구가 생기는 시점에 C로 마이그레이션하는 게 가장 현실적인 로드맵입니다.