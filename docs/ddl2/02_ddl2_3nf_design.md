# DDL2 (3NF) 설계 설명서

## 1) 목적

`ddl3`의 도메인 의도를 유지하면서, 아래 항목을 개선한 `ddl2` 설계를 정의한다.

- 정규화 수준: **3NF 기준**
- 목표:
  - 타입별 nullable 컬럼 축소
  - 문자열/JSON 인코딩 값의 구조화
  - 행위(Action)와 보상지급(Grant)의 관계 명확화 (1:N 허용)
  - 기본/오버라이드 모델의 `NULL` 의미 제거
  - 토큰 발급/클릭 로그 분리

> 본 설계는 운영 성능 최적화(캐시/집계)는 별도 레이어로 보고, 스키마 정합성과 확장성을 우선한다.

---

## 2) ddl3 → ddl2 핵심 변경 요약

### A. 보상 카탈로그 분해 (폴리모픽 → 공통 + 타입별 상세)

`ddl3`
- `event_reward_catalog` 단일 테이블에 `point_amount`, `coupon_group_id`, `external_ref_id` 혼재

`ddl2`
- `reward_catalog` (공통)
- `reward_catalog_point`
- `reward_catalog_coupon`
- `reward_catalog_product`

효과:
- 타입별 컬럼 null 남발 감소
- 타입별 제약/확장 용이

### B. 랜덤 정책 분해 (게임 타입별 상세)

`ddl3`
- `event_random_policy`에 `display_slot_count`, `quiz_question`, `quiz_answer` 혼재

`ddl2`
- `event_random_policy` (공통)
- `event_random_slot_policy` (ROULETTE/LADDER 계열)
- `event_random_quiz_policy` (QUIZ)

### C. 통합 로그 분해 (공통 로그 + 상세)

`ddl3`
- `event_log`에 출석/랜덤 전용 컬럼 동시 보관

`ddl2`
- `event_action` (공통)
- `event_attendance_action_detail`
- `event_random_action_detail`

효과:
- 컬럼 의미 명확화
- nullable 전용 컬럼 축소
- 타입별 제약 확장성 향상

### D. 보상 지급의 다중 지급 허용

`ddl3`
- `event_reward_grant.event_log_id UNIQUE`로 1행위=1지급 강제

`ddl2`
- `reward_grant`가 `event_action`을 참조하되 UNIQUE 제거
- `grant_sequence`로 동일 행위 내 다중 지급 순번 관리

효과:
- 출석 1회에 일일+보너스 동시 지급 가능

### E. 공유 토큰/클릭 로그 분리

`ddl3`
- `event_share_log` 1테이블에서 토큰 발급 정보 + 클릭 로그 반복 저장

`ddl2`
- `event_share_token`
- `event_share_click_log`

효과:
- 토큰 메타 중복 제거
- 클릭 분석 및 어뷰징 탐지 확장 용이

### F. 메시지 기본값/오버라이드 분리 (`NULL` 제거)

`ddl3`
- `event_display_message.event_id=NULL`이 기본 메시지 의미

`ddl2`
- `message_template` (시스템 기본)
- `event_message_override` (이벤트별 오버라이드)

효과:
- 유니크 제약 단순화
- `NULL` 의미 해석 제거

---

## 3) 정규화(3NF) 적용 포인트

### 3.1 다중값 문자열 제거

`ddl3`의 `event_participation_eligibility.eligibility_value`는 문자열/JSON으로 여러 의미를 담고 있었다.

`ddl2`에서는 다음처럼 분리한다.

- `event_eligibility_rule`: 규칙 헤더 (타입, 연산자, 우선순위)
- `event_eligibility_rule_value`: 규칙 값 (행 단위, 순번 관리)

예:
- `MEMBER_TYPE IN (REGULAR, VIP)`
  - 헤더 1건 + 값 2건(`REGULAR`, `VIP`)

### 3.2 타입별 상세 속성 분리

- 랜덤 정책의 퀴즈/슬롯 속성 분리
- 보상 카탈로그의 타입별 속성 분리
- 행위 로그 상세 분리

### 3.3 코드 마스터 참조

문자열 열거값을 가능한 한 코드 테이블로 이동한다.

예:
- `event_type`
- `event_status`
- `reward_type`
- `game_type`
- `message_type`
- `asset_slot_type`
- `share_channel`

장점:
- 허용값 관리 일원화
- 변경 영향도 파악 용이
- 설명 컬럼/운영 사용 여부 추가 가능

---

## 4) 테이블 그룹 구성 (ddl2)

### 4.1 코드/기준정보

- `code_event_type`
- `code_event_status`
- `code_game_type`
- `code_reward_type`
- `code_reward_kind`
- `code_action_result`
- `code_trigger_type`
- `code_eligibility_type`
- `code_limit_subject`
- `code_limit_scope`
- `code_limit_metric`
- `code_message_type`
- `code_asset_slot_type`
- `code_share_channel`

### 4.2 이벤트/정책

- `event`
- `event_attendance_policy`
- `event_random_policy`
- `event_random_slot_policy`
- `event_random_quiz_policy`
- `event_share_policy`

### 4.3 보상 정의/세팅

- `reward_catalog`
- `reward_catalog_point`
- `reward_catalog_coupon`
- `reward_catalog_product`
- `event_attendance_daily_reward`
- `event_attendance_bonus_reward_rule`
- `event_random_reward_pool`
- `event_random_reward_pool_counter` (운영 집계 테이블)

### 4.4 조건/제한

- `event_eligibility_rule`
- `event_eligibility_rule_value`
- `event_participation_limit_rule`

### 4.5 UI/콘텐츠

- `file_asset`
- `message_template`
- `event_message_override`
- `event_display_asset_binding`

### 4.6 참여자/운영 제어

- `event_participant`
- `event_participant_block`

### 4.7 실행/로그/보상지급

- `event_share_token`
- `event_share_click_log`
- `event_action`
- `event_attendance_action_detail`
- `event_random_action_detail`
- `reward_grant`
- `reward_grant_point_snapshot`
- `reward_grant_coupon_snapshot`
- `reward_grant_product_snapshot`

---

## 5) 설계 원칙 (운영 규칙 포함)

### 5.1 `event` 유형 중복 저장 제거

- `ddl2`에서는 `event_action`, `reward_grant`에 `event_type`를 저장하지 않는다.
- `reward_grant`는 `event_action_id`만 저장하고, `event_id`/`member_id`는 `event_action` 조인으로 해석한다.
- 필요 시 `event` 조인으로 해석한다.
- 조회 최적화가 필요하면 읽기 모델(View/캐시)에서 해결한다.

### 5.2 카탈로그 변경 정책

- `reward_catalog`는 발급에 사용된 후에는 **수정 대신 비활성화/신규 등록**을 권장한다.
- 이유: `reward_grant`는 `reward_catalog_id`를 참조하고, 이력 의미 보존을 위해 카탈로그의 사실상 불변성이 유리하다.

### 5.3 행위와 지급의 관계

- `event_action`은 실제 사용자 행위를 표현한다.
- `reward_grant`는 그 결과 발생한 지급(복수 가능)을 표현한다.
- 예:
  - 출석 성공 1건 → 일일 보상 1건 + 보너스 보상 1건

### 5.4 집계 테이블(`event_random_reward_pool_counter`)의 위치

- 엄밀한 원본 사실은 `event_action`/`reward_grant` 쪽에 있음
- 카운터 테이블은 제한 판단 성능을 위한 운영 집계 테이블로 유지
- 재계산/복구 절차를 별도 배치로 운영하는 것을 전제

---

## 6) ddl3 대비 개선 체크리스트 대응표

- `event_display_message` NULL+UNIQUE 문제: 해결 (`message_template` / `event_message_override` 분리)
- `event_reward_grant.event_log_id UNIQUE` 문제: 해결 (`event_action` : `reward_grant` = 1:N)
- `event_log`의 타입별 nullable 컬럼: 해결 (상세 테이블 분리)
- `event_reward_catalog` 폴리모픽 혼합: 완화/해결 (타입 상세 분리)
- `eligibility_value` 문자열/JSON 혼합: 완화/해결 (룰 헤더+값 행 분리)
- `event_share_log` 토큰/클릭 혼합: 해결 (2테이블 분리)
- `event_display_asset` 슬롯 메타 문자열 의존: 완화 (`code_asset_slot_type` 참조)

---

## 7) 샘플 시나리오 (DDL 샘플 데이터에 반영)

`03_ddl2_3nf_ddl_with_sample_data.md`에 아래 예시를 포함한다.

1. 출석 이벤트
- 30일 출석 정책
- 일일 보상 + 7일 보너스 보상
- 7일차 출석 1회 행위에서 **2건 지급** 발생 예시

2. 랜덤 이벤트(룰렛)
- 보상 카탈로그 + 랜덤 보상풀 + 카운터
- 랜덤 당첨 행위 + 보상 지급 예시

3. SNS 공유 재도전
- `event_share_token` 발급
- `event_share_click_log` 클릭 2건 예시

4. UI 메시지/에셋
- 시스템 기본 메시지 + 이벤트 오버라이드
- 이벤트 UI 슬롯별 파일 매핑 예시

---

## 8) 결과물 파일 구성 (ddl2)

- 분석 문서: `docs/ddl2/01_ddl3_analysis.md`
- 설계 설명 문서: `docs/ddl2/02_ddl2_3nf_design.md`
- DDL + 예시 데이터 문서: `docs/ddl2/03_ddl2_3nf_ddl_with_sample_data.md`
