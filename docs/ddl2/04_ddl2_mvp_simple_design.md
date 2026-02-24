# DDL2 단순 버전 (MVP) 설계안

## 목적

- `ddl3`의 도메인 구조는 유지한다.
- 테이블 수를 최소화한다.
- 운영상 치명적인 정합성 이슈만 우선 수정한다.
- 과도한 3NF 분해는 나중 단계로 미룬다.

> 결론: 지금은 `ddl3 + 최소 수정`이 가장 현실적이다.

---

## 1) 설계 원칙 (단순 버전)

### 유지할 것 (테이블 추가 안 함)

- `event_log` 통합 테이블 유지
- `event_reward_catalog` 단일 테이블 유지
- `event_random_policy` 단일 테이블 유지
- `event_share_log` 단일 테이블 유지
- `event_type` 같은 조회용 비정규화 컬럼 유지
- 문자열 enum(`VARCHAR`) 유지 (`code_*` 테이블 안 만듦)

### 꼭 수정할 것 (필수)

1. `event_reward_grant.event_log_id UNIQUE` 제거
- 출석 1회에 일일 보상 + 보너스 보상 동시 지급 가능하게 변경

2. `event_display_message`의 기본 메시지 중복 방지 보강
- `event_id IS NULL`인 기본 메시지는 기존 UNIQUE로 중복 차단이 안 됨 (PostgreSQL NULL 특성)

3. `02_event.sql` 관계 주석 오류 수정
- `event_reward_catalog.event_id` 참조로 보이는 잘못된 설명 제거

---

## 2) 단순 버전 테이블 구성 (권장)

`ddl3` 테이블을 거의 그대로 사용한다.

### 그대로 사용

- `file`
- `event`
- `event_participation_eligibility`
- `event_attendance_policy`
- `event_random_policy`
- `event_reward_catalog`
- `event_participant`
- `event_participant_block`
- `event_attendance_daily_reward`
- `event_attendance_bonus_reward`
- `event_random_reward_pool`
- `event_random_reward_counter`
- `event_share_policy`
- `event_share_log`
- `event_log`
- `event_reward_grant`
- `event_participation_limit_policy`
- `event_display_message`
- `event_display_asset`

### 추가 테이블

- 없음 (MVP 기준)

---

## 3) 왜 이 정도만 고치면 되는가

### A. 현재 ddl3는 이미 실무형 구조임

- 문서화가 좋고, 도메인 의도가 명확함
- 운영 고려(`idempotency_key`, 카운터 테이블, 참여자 캐시)도 들어가 있음

### B. 진짜 문제는 “정규화 부족”보다 “정합성 구멍” 몇 개

특히 아래 2개는 실제 장애/운영 이슈로 이어질 가능성이 큼.

- `event_reward_grant.event_log_id UNIQUE`
  - 정상 케이스(출석+보너스 동시지급)를 막을 수 있음

- `event_display_message` 기본 메시지 중복
  - 운영자가 실수로 기본 메시지를 중복 등록해도 DB가 못 막음

### C. 나머지는 운영 규칙으로 충분히 커버 가능

- `event_type` 비정규화 컬럼: 저장 시 서비스 레이어에서 강제
- `eligibility_value` 문자열 포맷: 문서 표준으로 통일
- `event_random_policy` 타입 혼합 컬럼: 초기엔 허용, 복잡해지면 분리

---

## 4) 필수 수정안 (SQL 패치 예시)

### 4.1 `event_reward_grant` - 1행위 다중 지급 허용

현재 문제:
- `event_log_id UNIQUE` 때문에 출석 1회에서 `DAILY` + `BONUS` 2건 지급이 어려움

권장 수정:

```sql
-- 1) 기존 UNIQUE 제약 제거 (제약명은 실제 DB 기준 확인 필요)
-- ALTER TABLE event_platform.event_reward_grant
--   DROP CONSTRAINT event_reward_grant_event_log_id_key;

-- 2) 대체 유니크 인덱스 (중복 지급 방지용)
-- reward_catalog_id가 NULL일 수 있으면 운영 규칙/키 설계 추가 필요
CREATE UNIQUE INDEX IF NOT EXISTS ux_reward_grant_log_kind_catalog
    ON event_platform.event_reward_grant(event_log_id, reward_kind, reward_catalog_id);
```

운영 메모:
- `reward_catalog_id IS NULL` 케이스(`NONE`, `ONEMORE`)까지 정확히 막으려면
  - `idempotency_key` 규칙 강화 또는
  - 별도 `grant_reason_key` 컬럼 추가를 다음 단계에서 검토

---

### 4.2 `event_display_message` - 기본 메시지 중복 방지

현재 문제:
- `UNIQUE(event_id, message_type, lang_code)`는 `event_id=NULL` 중복 허용

권장 수정:

```sql
-- 기본 메시지(event_id IS NULL) 중복 방지
CREATE UNIQUE INDEX IF NOT EXISTS ux_display_message_default_type_lang
    ON event_platform.event_display_message(message_type, lang_code)
    WHERE event_id IS NULL AND is_deleted = FALSE;

-- 이벤트별 커스텀 메시지 중복 방지 (명시적으로 분리)
CREATE UNIQUE INDEX IF NOT EXISTS ux_display_message_event_type_lang
    ON event_platform.event_display_message(event_id, message_type, lang_code)
    WHERE event_id IS NOT NULL AND is_deleted = FALSE;
```

운영 메모:
- 기존 `CONSTRAINT uq_display_message_event_type_lang`는 남겨도 되지만,
  실질적 보호는 위 2개 부분 유니크 인덱스가 담당함

---

### 4.3 `02_event.sql` 문서 주석 정정

현재 문제:
- 관계 설명에 `event_reward_catalog.event_id`가 있는 것처럼 보이는 주석이 있음
- 실제 `event_reward_catalog`는 이벤트 독립 테이블

권장 수정:
- `02_event.sql` 상단 관계 주석에서 해당 줄 삭제
- README 관계 표와 함께 재확인

---

## 5) 운영 규칙만 추가하면 충분한 항목 (테이블 추가 없이)

### 5.1 `event_log.event_type`, `event_reward_grant.event_type`

정책:
- 저장 시 `event_id`로 `event.event_type` 조회 후 동일 값만 저장
- 배치 점검 쿼리로 불일치 검사

점검 쿼리 예시:

```sql
SELECT l.id, l.event_id, l.event_type, e.event_type AS actual_event_type
FROM event_platform.event_log l
JOIN event_platform.event e ON e.id = l.event_id
WHERE l.event_type <> e.event_type;
```

### 5.2 `event_participation_eligibility.eligibility_value`

정책:
- 타입별 값 포맷 표준만 문서로 고정
- 예:
  - 배열: JSON 문자열 (`["REGULAR","VIP"]`)
  - 숫자: 정수 문자열 (`"30"`)
  - boolean: 소문자 (`"true"`, `"false"`)

### 5.3 `event_random_reward_counter`

정책:
- 카운터는 성능용 집계 테이블로 간주
- 원본 로그(`event_log`, `event_reward_grant`)와 불일치 시 재계산 배치 운영

---

## 6) 단순 버전 적용 순서 (추천)

1. DB 패치 적용
- `event_reward_grant` 유니크 제약 재정의
- `event_display_message` 부분 유니크 인덱스 추가

2. 문서 수정
- `02_event.sql` 주석 정정
- `README.md`에 “기본 메시지 유니크는 부분 인덱스로 보완” 메모 추가

3. 서비스 규칙 보강
- `event_type` 정합성 저장 규칙
- `eligibility_value` 포맷 표준 문서화

4. 추후 확장 시점에만 분해
- 공유 로그/토큰 분리, 보상 카탈로그 상세 분리 등은 트래픽/기능 복잡도 증가 시 진행

---

## 7) 결론

지금 단계에서는 **테이블을 늘리지 않는 것이 맞다**.

- `ddl3`는 기본 뼈대가 이미 좋음
- 치명도 높은 제약/인덱스 문제만 먼저 수정
- 나머지는 운영 규칙으로 관리
- 복잡도가 실제로 증가할 때만 단계적으로 분해

이 문서는 `3NF 정석안`이 아니라, **팀 생산성과 유지보수성을 우선한 MVP 설계안**이다.
