# DDL3 - 이벤트 플랫폼 테이블 설계

> **전략**: `event` 테이블을 중심으로 종속성·연관성이 보이도록 FK를 구성.  
> 모든 테이블은 `event_platform` 스키마 하에 정의됨.

---

## 실행 순서 (FK 의존성 순)

```
01_file.sql
02_event.sql
03_event_participation_eligibility.sql
04_event_attendance_policy.sql
05_event_random_policy.sql
06_event_reward_catalog.sql
07_event_participant.sql
08_event_attendance_daily_reward.sql
09_event_attendance_bonus_reward.sql
10_event_random_reward_pool.sql
11_event_random_reward_counter.sql
12_event_share_policy.sql
13_event_share_log.sql
14_event_log.sql
15_event_reward_grant.sql
16_event_participation_limit_policy.sql
17_event_display_message.sql
18_event_display_asset.sql
```

---

## 테이블 목록 및 관계

| # | 파일 | 테이블 | 이벤트 유형 | event와 관계 | 비고 |
|---|------|--------|-------------|-------------|------|
| 01 | 01_file.sql | `file` | 공통 | - | S3 파일 메타 |
| 02 | 02_event.sql | `event` | 공통 | 중심(Master) | 출석/랜덤 각 1 row |
| 03 | 03_event_participation_eligibility.sql | `event_participation_eligibility` | 공통 | **1:N** | 참여 자격 조건 |
| 04 | 04_event_attendance_policy.sql | `event_attendance_policy` | 출석 전용 | **1:1** | 출석 정책 |
| 05 | 05_event_random_policy.sql | `event_random_policy` | 랜덤 전용 | **1:1** | 랜덤 게임 정책 |
| 06 | 06_event_reward_catalog.sql | `event_reward_catalog` | 공통 | **독립** | 보상 카탈로그 (event 미종속, 재사용 가능) |
| 07 | 07_event_participant.sql | `event_participant` | 공통 | **1:N** | 참여자 명단 캐시 |
| 08 | 08_event_attendance_daily_reward.sql | `event_attendance_daily_reward` | 출석 전용 | **1:1** | 일일 보상 세팅 |
| 09 | 09_event_attendance_bonus_reward.sql | `event_attendance_bonus_reward` | 출석 전용 | **1:N** | 누적/연속 보너스 보상 |
| 10 | 10_event_random_reward_pool.sql | `event_random_reward_pool` | 랜덤 전용 | **1:N** | 랜덤 보상 풀 |
| 11 | 11_event_random_reward_counter.sql | `event_random_reward_counter` | 랜덤 전용 | pool 기준 **1:1** | 일일·전체 당첨 카운터 |
| 12 | 12_event_share_policy.sql | `event_share_policy` | 랜덤 전용 | **1:1** | SNS 공유 정책 |
| 13 | 13_event_share_log.sql | `event_share_log` | 랜덤 전용 | **1:N** | SNS 공유 로그 |
| 14 | 14_event_log.sql | `event_log` | **공통 통합** | **1:N** | 출석·랜덤 행위 로그 |
| 15 | 15_event_reward_grant.sql | `event_reward_grant` | **공통 통합** | **1:N** | 보상 지급 내역 |
| 16 | 16_event_participation_limit_policy.sql | `event_participation_limit_policy` | 공통 | **1:N** | 참여 제한 정책 |
| 17 | 17_event_display_message.sql | `event_display_message` | 공통 | **1:N 또는 NULL** | 안내 메시지 사전 |
| 18 | 18_event_display_asset.sql | `event_display_asset` | 공통 | **1:N** | UI 이미지 슬롯 |

---

## 핵심 설계 결정 사항

### 1. event 중심 FK 구성
- `event_type='ATTENDANCE'` 전용: `event_attendance_policy`(1:1), `event_attendance_daily_reward`(1:1), `event_attendance_bonus_reward`(1:N)
- `event_type='RANDOM'` 전용: `event_random_policy`(1:1), `event_random_reward_pool`(1:N), `event_share_policy`(1:1)
- 공통 통합: `event_participant`, `event_log`, `event_reward_grant`, `event_participation_eligibility`, `event_participation_limit_policy`
- **독립(event 미종속)**: `event_reward_catalog` — 여러 이벤트에서 `reward_catalog_id`로 참조해 재사용

### 2. 출석·랜덤 로그 통합 (`event_log`)
- 하나의 테이블에서 `event_type` 컬럼으로 구분
- 출석 전용 컬럼(attendance_date, total/streak_count)과 랜덤 전용 컬럼(trigger_type, reward_pool_id)을 nullable로 공존
- `event_reward_grant.event_log_id` FK로 로그 ↔ 보상지급 1:1 연결

### 3. 보상 지급 통합 (`event_reward_grant`)
- 출석 일일(DAILY), 출석 보너스(BONUS), 랜덤(RANDOM) 모두 이 테이블에 기록
- `idempotency_key` UNIQUE로 외부 API 중복 호출 방지

### 4. event_display_message
- event와 1:1이 **아님**
- `event_id=NULL` → 시스템 공통 기본 메시지
- `event_id=특정값` → 해당 이벤트 커스텀 메시지

### 5. DB CHECK 제약 제외
- 보상 유형별 필드(point vs coupon) 매칭 제약은 Application 레이어에서 처리
- 이벤트 기간 유효성(end > start) 등도 Application에서 처리

---

## 감사(Audit) 컬럼 표준

모든 마스터·설정 테이블에 아래 컬럼 포함:

```sql
is_deleted  BOOLEAN   NOT NULL DEFAULT FALSE,
created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
created_by  BIGINT    NOT NULL,  -- FK: admin.id
updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
updated_by  BIGINT    NOT NULL   -- FK: admin.id
```

> Append-only 로그 테이블(`event_log`, `event_share_log`)은 `created_at`만 보유.

---

## 질문 / 미결 사항

1. **event_reward_grant의 BONUS row**: 출석 보너스 보상은 출석 1회 CHECK_IN 로그와 매핑되는지, 별도 로그 row를 생성하는지 확인 필요
2. **랜덤 ONEMORE 처리**: `reward_type='ONEMORE'` 당첨 시 `event_reward_grant`에 기록 후 자동으로 추가 시도가 생성되는 플로우 구체화 필요
3. **event_display_message 커스텀**: 이벤트별 커스텀 메시지 키를 자유롭게 추가하는 방식인지, 정해진 유형 내에서만 오버라이드 가능한지 확인 필요
