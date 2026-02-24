# DDL3 분석 보고서 (기준 문서)

## 1) 분석 범위

- 대상 폴더: `docs/ddl3`
- 분석 대상 파일:
  - SQL DDL: `01_file.sql` ~ `18_event_display_asset.sql` (+ `07b_event_participant_block.sql`)
  - 보조 설계 문서: `README.md`, `00_erd.md`, Flow/운영 문서들
- 목적:
  - 현재 설계의 강점/리스크 파악
  - `ddl2` 신규 설계(정규화 3NF 기준)의 입력 자료 생성
  - `ddl3`에 피드백 문서 작성 근거 확보

> 참고: `docs/ddl2`는 분석 시점에 비어 있었고, 본 문서가 첫 기준 문서임.

---

## 2) DDL3 전체 구조 요약

`ddl3`는 이벤트 플랫폼을 다음 6개 영역으로 나눈 설계다.

1. 이벤트 마스터/정책
- `event`
- `event_attendance_policy`
- `event_random_policy`
- `event_share_policy`
- `event_participation_eligibility`
- `event_participation_limit_policy`

2. 보상 정의/세팅
- `event_reward_catalog`
- `event_attendance_daily_reward`
- `event_attendance_bonus_reward`
- `event_random_reward_pool`
- `event_random_reward_counter`

3. 참여자/운영 제어
- `event_participant`
- `event_participant_block`

4. 실행/로그/지급
- `event_log`
- `event_reward_grant`
- `event_share_log`

5. UI 표시/콘텐츠
- `event_display_message`
- `event_display_asset`

6. 파일 저장소
- `file`

### 관찰된 설계 의도

- `event` 중심 FK 구조로 읽기 흐름이 명확함
- 출석/랜덤 공통 기능과 전용 기능을 구분하려는 의도가 좋음
- 운영 설명(Flow 문서)와 DDL이 함께 있어 팀 커뮤니케이션에 유리함
- 예시 데이터 주석이 풍부해서 도메인 이해 속도가 빠름

---

## 3) 강점 (좋은 점)

### A. 문서화 품질이 높음

- 대부분 SQL 파일에 역할/관계/예시 데이터/컬럼 주석이 포함됨
- `README.md`에 실행 순서와 관계 개요가 정리되어 있음
- `14_event_log_flow.md`, `15_event_reward_grant_flow.md`, `16_participation_limit_design.md` 같은 운영 문서가 있어 개발/운영 이해에 도움됨

### B. 실무 운영 관점이 반영됨

- `event_reward_grant.idempotency_key` UNIQUE로 멱등성 처리 고려
- `event_random_reward_counter`로 제한 수량 체크 성능 고려
- `event_participant`를 캐시성 참여자 테이블로 두어 자격 재평가 비용 감소
- `event_display_message` 기본/커스텀 오버라이드 개념 도입

### C. 확장 가능한 방향성이 존재함

- `event_reward_catalog`를 이벤트 비종속으로 분리해 재사용성 확보
- `file` 테이블에서 object_key만 저장하고 URL 조합을 앱에서 처리하는 방향은 적절함

---

## 4) 핵심 이슈 (정규화/정합성/운영)

아래 항목은 `ddl2` 재설계 및 `ddl3` 개선 문서에 반드시 반영할 사항이다.

### [P0] `event_display_message`의 `UNIQUE(event_id, message_type, lang_code)`는 `event_id IS NULL` 중복을 막지 못함

대상: `docs/ddl3/17_event_display_message.sql`

- PostgreSQL에서 `UNIQUE`는 `NULL`을 서로 다른 값으로 취급하므로,
  - `(NULL, 'OUTSIDE_PERIOD', 'ko')`가 여러 건 들어갈 수 있음
- 현재 설계 의도는 `기본 메시지(event_id=NULL)`가 유형+언어당 1건이어야 함
- 즉, 현재 제약만으로는 기본 메시지 중복이 발생할 수 있음

권장 개선 방향:
- 부분 유니크 인덱스 2개로 분리
  - 기본 메시지용: `WHERE event_id IS NULL`
  - 이벤트 커스텀용: `WHERE event_id IS NOT NULL`
- 또는 `message_template` / `event_message_override`로 테이블 분리 (3NF 관점에서 더 좋음)

### [P0] `event_reward_grant.event_log_id UNIQUE`는 1회 행위에서 다중 보상 지급을 막음

대상: `docs/ddl3/15_event_reward_grant.sql`

- 현재 제약: `event_log_id BIGINT NOT NULL UNIQUE`
- 출석 이벤트의 1회 체크인에서
  - 일일 보상(`DAILY`)
  - 보너스 보상(`BONUS`)
  가 동시에 발생할 수 있음
- 이 경우 동일 `event_log_id`로 2건 이상 지급 레코드가 필요할 수 있는데, 현재 제약은 이를 막음
- `README.md`의 미결 사항과도 연결됨 (보너스 보상 row 매핑 문제)

권장 개선 방향:
- `event_log_id UNIQUE` 제거
- 필요 시 다음과 같이 재정의
  - `UNIQUE(event_log_id, reward_kind, reward_catalog_id)` 또는
  - 지급 원인 식별 컬럼 추가 후 `UNIQUE(event_log_id, grant_reason_type, grant_reason_id)`
- 더 좋은 구조: `event_action(행위)` : `reward_grant(지급)` = 1:N 명시

### [P1] `event_log.event_type`, `event_reward_grant.event_type`는 `event_id`로부터 유도 가능한 중복 컬럼 (비정규화)

대상:
- `docs/ddl3/14_event_log.sql`
- `docs/ddl3/15_event_reward_grant.sql`

- 둘 다 `event_id`가 이미 있으므로 `event_type`은 `event` 조인으로 결정 가능
- 장점(조회 최적화)은 있으나, 정합성 제약이 없어 불일치 위험 존재
  - 예: `event_id=랜덤 이벤트`인데 `event_type='ATTENDANCE'`

권장 개선 방향:
- 3NF 스키마(`ddl2`)에서는 제거하고 조인으로 해석
- 성능이 필요하면 뷰/머티리얼라이즈드 뷰/조회용 캐시에서 비정규화
- 유지 시에는 trigger 또는 application invariant로 강제 필요

### [P1] `event_reward_catalog`의 타입별 속성 혼합(폴리모픽 단일 테이블)로 null 컬럼 과다

대상: `docs/ddl3/06_event_reward_catalog.sql`

- `reward_type`에 따라 사용하는 컬럼이 달라짐
  - `POINT` → `point_amount`
  - `COUPON` → `coupon_group_id`
  - `PRODUCT` → `external_ref_id`
- 결과적으로 타입별 NULL 컬럼이 많이 생기고, DB 레벨 정합성 검증이 어려움

권장 개선 방향:
- `reward_catalog` (공통) + 타입별 상세 테이블 분리
  - `reward_catalog_point`
  - `reward_catalog_coupon`
  - `reward_catalog_product`
- `NONE`, `ONEMORE`는 공통 테이블만으로 충분

### [P1] `event_participation_eligibility.eligibility_value` 문자열/JSON 인코딩은 검색·검증·변경 비용이 큼

대상: `docs/ddl3/03_event_participation_eligibility.sql`

- 하나의 컬럼에 다양한 타입을 문자열로 저장
  - JSON 배열, 숫자 문자열, boolean 문자열
- 문제점:
  - DB 제약 검증 어려움
  - 조건별 검색/통계/변경 이력 추적 어려움
  - 값 의미가 `eligibility_type`에 종속되어 해석 비용 증가

권장 개선 방향:
- 규칙 헤더 + 규칙 값 테이블 분리 (`1:N`)
- 조건 타입 코드 테이블 도입
- 값 다건(예: 회원등급 목록)을 행 단위로 저장

### [P1] `event_random_policy`에 게임 타입별 전용 컬럼이 혼재 (`display_slot_count`, `quiz_question`, `quiz_answer`)

대상: `docs/ddl3/05_event_random_policy.sql`

- `game_type`에 따라 서로 다른 컬럼을 사용
- `QUIZ` 전용/ROULETTE 전용 속성이 한 테이블에 공존

권장 개선 방향:
- 공통 정책 + 게임 타입별 상세 테이블 분리
  - `event_random_policy`
  - `event_random_policy_quiz`
  - `event_random_policy_slot_game` (ROULETTE/LADDER 공통)

### [P1] `event_share_log`가 토큰 발급과 클릭 이벤트 정보를 한 테이블에서 반복 저장

대상: `docs/ddl3/13_event_share_log.sql`

- `share_token`, `sharer_member_id`, `share_channel`가 클릭 row마다 반복됨
- 토큰 발급 단위와 클릭 이벤트 단위가 분리되지 않음

권장 개선 방향:
- `event_share_token` (발급/공유 단위)
- `event_share_click_log` (클릭 로그 단위)
로 분리

### [P2] `event_display_asset.asset_type + sort_order` 조합으로 UI 슬롯 의미를 문자열에 과도하게 인코딩

대상: `docs/ddl3/18_event_display_asset.sql`

- 슬롯 의미(배경, 버튼, 룰렛 슬롯, 카드 앞/뒤)를 `asset_type` 문자열로 관리
- 다중 슬롯 여부/허용 개수/플랫폼 구분 규칙이 메타로 분리되어 있지 않음

권장 개선 방향:
- 슬롯 타입 코드 마스터(`code_asset_slot_type`) 도입
- 이벤트별 슬롯 매핑 테이블에서 `(event_id, slot_type_code, slot_seq)` 관리

### [P2] 문서/주석 불일치 1건 확인 (`event_reward_catalog.event_id` 참조 표기)

대상: `docs/ddl3/02_event.sql`

- 파일 상단 관계 주석에 `event_reward_catalog.event_id`가 등장함
- 실제 `event_reward_catalog`는 `event_id`를 가지지 않는 독립 테이블
- 주석만 보고 개발하면 잘못된 FK를 가정할 수 있음

권장 개선 방향:
- 관계 주석 정정
- README/ERD/SQL 주석 동기화 점검 체크리스트 운영

---

## 5) 정규화(3NF) 관점 평가 요약

### 상대적으로 양호 (의도적으로 단순화된 형태)

- `file`
- `event`
- `event_attendance_policy`
- `event_attendance_daily_reward`
- `event_attendance_bonus_reward` (코드값 컬럼 제외 시 구조는 비교적 명확)
- `event_random_reward_pool`
- `event_random_reward_counter` (운영 집계 테이블 성격)
- `event_participant`
- `event_participant_block`

### 부분 비정규화 / 폴리모픽 혼합 (개선 필요)

- `event_reward_catalog`
- `event_random_policy`
- `event_log`
- `event_reward_grant`
- `event_share_log`
- `event_participation_eligibility`
- `event_display_message`
- `event_display_asset`

---

## 6) ddl2(신규) 설계 방향 제안 (3NF 목표)

### 핵심 원칙

1. 공통 엔터티와 타입별 상세 엔터티 분리
- 예: 보상/랜덤게임/행위로그 상세

2. 코드값 문자열은 코드 마스터 참조로 전환
- `event_type`, `reward_type`, `message_type`, `trigger_type` 등

3. `NULL` 기반 기본/오버라이드 모델 최소화
- 기본 메시지/이벤트 오버라이드 분리

4. 행위(Action)와 지급(Grant)를 1:N 모델로 재정의
- 출석 일일 + 보너스 동시 지급 허용

5. 값 묶음(JSON 문자열) 대신 행 단위 저장 우선
- 자격 조건, 공유 토큰/클릭 이벤트 분리

### 성능 전략 (정규화와 별개)

- `ddl2`는 정규화 우선
- 조회 최적화는 인덱스/뷰/캐시/집계 테이블로 해결
- `event_random_reward_counter` 같은 운영 집계 테이블은 유지 가능 (단, 원본 로그와 정합성 운영 절차 필요)

---

## 7) 다음 작업 연결

이 문서를 기준으로 다음 2개 결과물을 작성한다.

1. `docs/ddl3` 피드백 문서
- ddl3에서 바로 적용 가능한 개선점과 마이그레이션 포인트 정리

2. `docs/ddl2` 신규 3NF 설계 문서 + DDL/예시 데이터
- 설명 문서(`md`)와 DDL/샘플(`md`) 분리
