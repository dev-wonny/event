# DDL3 보완/개선점 피드백 (ddl2 분석 기반)

## 목적

- `docs/ddl2/01_ddl3_analysis.md` 분석 결과를 바탕으로 `ddl3`에 대한 개선 포인트를 정리한다.
- 본 문서는 **기존 ddl3를 즉시 수정할 수 있는 항목**과 **구조 재설계(ddl2)로 넘길 항목**을 구분한다.

---

## 1) 즉시 반영 권장 (DDL3 Patch 레벨)

### 1. `event_display_message` 기본 메시지 중복 방지 제약 보강 (중요)

대상: `17_event_display_message.sql`

현재 문제:
- `UNIQUE(event_id, message_type, lang_code)`는 `event_id IS NULL`인 기본 메시지 중복을 막지 못함
- PostgreSQL의 `UNIQUE` + `NULL` 동작 특성 때문

권장 패치 예시:

```sql
-- 기존 CONSTRAINT는 유지해도 되지만, NULL 케이스 보호를 위해 아래 인덱스를 추가 권장

-- 기본 메시지(event_id IS NULL) 중복 방지
CREATE UNIQUE INDEX ux_display_message_default_type_lang
    ON event_platform.event_display_message(message_type, lang_code)
    WHERE event_id IS NULL AND is_deleted = FALSE;

-- 이벤트 커스텀(event_id IS NOT NULL) 중복 방지
CREATE UNIQUE INDEX ux_display_message_event_type_lang
    ON event_platform.event_display_message(event_id, message_type, lang_code)
    WHERE event_id IS NOT NULL AND is_deleted = FALSE;
```

메모:
- `is_deleted`를 고려한 유니크 정책인지(소프트삭제 후 재등록 허용 여부)는 운영 정책에 맞춰 확정 필요

### 2. `event_reward_grant.event_log_id UNIQUE` 재검토 (중요)

대상: `15_event_reward_grant.sql`

현재 문제:
- 출석 1회 CHECK_IN에서 `DAILY + BONUS` 동시 지급 시 동일 로그에 복수 지급 row가 필요할 수 있음
- 현재 `event_log_id UNIQUE`로는 표현 불가

권장 패치 방향(최소 변경):

```sql
-- 1) UNIQUE 제거
-- ALTER TABLE event_platform.event_reward_grant DROP CONSTRAINT ... ;

-- 2) 중복 지급 방지용 대체 제약 추가 (예시)
CREATE UNIQUE INDEX ux_reward_grant_log_kind_catalog
    ON event_platform.event_reward_grant(event_log_id, reward_kind, reward_catalog_id);
```

주의:
- `reward_catalog_id`가 NULL일 수 있는 정책(예: NONE/ONEMORE)이 있으면 별도 중복 방지 키 설계 필요
- 더 근본적으로는 `grant_reason_type/grant_reason_id` 도입이 좋음

### 3. `02_event.sql` 파일 상단 관계 주석 수정

대상: `02_event.sql`

현재 문제:
- 주석에 `event_reward_catalog.event_id` 참조 관계가 있으나 실제 테이블에는 `event_id` 없음

조치:
- 주석에서 해당 줄 제거 또는 `event_reward_catalog`는 독립 테이블임을 명시

---

## 2) ddl3 유지 시 운영 규칙으로 보완해야 하는 항목

### 1. `event_log.event_type` / `event_reward_grant.event_type` 정합성 보장

대상:
- `14_event_log.sql`
- `15_event_reward_grant.sql`

문제:
- `event_id`로부터 유도 가능한 값을 별도 저장 (조회 최적화용 비정규화)
- DB 제약만으로는 `event.event_type`과 불일치 가능

운영 보완안:
- 저장 서비스 레이어에서 강제 (`event_id` 조회 후 `event_type` 세팅)
- 정합성 점검 배치 쿼리 운영

점검 쿼리 예시:

```sql
SELECT l.id, l.event_id, l.event_type, e.event_type AS actual_event_type
FROM event_platform.event_log l
JOIN event_platform.event e ON e.id = l.event_id
WHERE l.event_type <> e.event_type;
```

### 2. `event_random_reward_counter` 동시성/정합성 운영 가이드 명시

대상: `11_event_random_reward_counter.sql`, `11_event_random_reward_counter.md`

문제:
- 카운터는 집계 캐시 테이블이므로 경쟁 상황에서 UPDATE 경합/정합성 이슈 가능

권장 문서 보강:
- 트랜잭션 격리 수준/락 전략 명시 (`SELECT ... FOR UPDATE` 또는 원자 UPDATE 패턴)
- 로그 기반 재계산 배치(복구 절차) 명시

### 3. `event_participation_eligibility.eligibility_value` 포맷 표준화 문서 추가

대상: `03_event_participation_eligibility.sql`

문제:
- 문자열/JSON/불린 문자열 포맷 혼합으로 구현체마다 파싱 규칙 달라질 위험

권장 문서 보강:
- 유형별 저장 포맷 표준 문서(예: JSON 배열은 공백 없는 문자열, boolean은 소문자 `true/false`, 숫자는 정수 문자열)
- validation 예시 추가

---

## 3) ddl2(구조 재설계)로 이관 권장 항목

다음 항목은 ddl3를 억지로 고치기보다 `ddl2`에서 3NF 기준으로 재설계하는 편이 비용 대비 효과가 좋다.

### A. 보상 카탈로그 타입별 상세 분리

대상: `06_event_reward_catalog.sql`

현재:
- `POINT/COUPON/PRODUCT/NONE/ONEMORE`를 단일 테이블에 혼합

ddl2 권장:
- `reward_catalog` (공통)
- `reward_catalog_point`
- `reward_catalog_coupon`
- `reward_catalog_product`

효과:
- 타입별 NULL 컬럼 감소
- 제약/검증 명확화
- 향후 reward type 추가 시 확장 용이

### B. 랜덤 정책의 게임 타입별 상세 분리

대상: `05_event_random_policy.sql`

현재:
- `display_slot_count`, `quiz_question`, `quiz_answer` 혼재

ddl2 권장:
- `event_random_policy` (공통)
- `event_random_policy_slot_game` (ROULETTE/LADDER)
- `event_random_policy_quiz` (QUIZ)

### C. 통합 로그의 타입별 nullable 컬럼 분리

대상: `14_event_log.sql`

현재:
- 출석 전용 컬럼 + 랜덤 전용 컬럼이 같은 테이블에 공존

ddl2 권장:
- `event_action` (공통 로그)
- `event_attendance_action_detail`
- `event_random_action_detail`

효과:
- nullable column 과다 완화
- 컬럼 의미 명확화
- 타입별 제약 강화 가능

### D. 보상 지급 스냅샷의 타입별 상세 분리 + 행위:지급 1:N 모델

대상: `15_event_reward_grant.sql`

ddl2 권장:
- `reward_grant` (공통)
- `reward_grant_point_snapshot`
- `reward_grant_coupon_snapshot`
- `reward_grant_product_snapshot`
- `event_action` 대비 `reward_grant` 1:N 허용

### E. 공유 토큰과 클릭 로그 분리

대상: `13_event_share_log.sql`

ddl2 권장:
- `event_share_token`
- `event_share_click_log`

효과:
- 토큰 메타 중복 제거
- 클릭 분석/어뷰징 분석 확장 용이

### F. 기본 메시지/이벤트 오버라이드 분리

대상: `17_event_display_message.sql`

ddl2 권장:
- `message_template`
- `event_message_override`

효과:
- `NULL` 의미 제거
- 유니크 제약 단순화
- 다국어/메시지 버전 관리 확장 용이

---

## 4) 제안 우선순위 (실행 순서)

### Phase 1 (즉시)

1. `event_display_message` 유니크 인덱스 보강
2. `02_event.sql` 주석 정정
3. `event_reward_grant` 다중 지급 가능 여부 도메인 확정

### Phase 2 (ddl3 유지 보완)

1. 정합성 점검 쿼리/배치 운영 문서화
2. `eligibility_value` 저장 포맷 표준 문서 추가
3. 카운터 재계산 절차 문서화

### Phase 3 (ddl2 적용)

1. 3NF 스키마 설계 승인
2. 샘플 데이터/조회 쿼리 검증
3. 마이그레이션 전략 수립 (dual-write 또는 배치 이관)

---

## 5) 관련 문서

- 분석 기준 문서: `docs/ddl2/01_ddl3_analysis.md`
- 신규 3NF 설계 설명: `docs/ddl2/02_ddl2_3nf_design.md`
- 신규 3NF DDL + 예시 데이터: `docs/ddl2/03_ddl2_3nf_ddl_with_sample_data.md`
