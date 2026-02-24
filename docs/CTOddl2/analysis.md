# 이벤트 도메인 DDL 분석 문서

> 분석 대상: `CTOddl` 폴더 (12개 파일)  
> 작성일: 2026-02-24

---

## 1. 전체 테이블 구조 요약

| 테이블명 | 논리명 | 성격 | 비고 |
|---|---|---|---|
| `event` | 이벤트 마스터 | 기준 테이블 | 모든 하위 테이블의 참조 기준 |
| `prize` | 경품 마스터 | 기준 테이블 | 이벤트 무관 독립 경품 관리 |
| `event_prize` | 이벤트 경품 정책 | 정책 테이블 | 이벤트별 경품 구성/수량/우선순위 |
| `event_banner` | 이벤트 배너 | 정책 테이블 | 채널·디바이스·위치별 배너 노출 정책 |
| `event_banner_image` | 이벤트 배너 이미지 | 매핑 테이블 | 배너-이미지파일 연결 및 변형 유형 관리 |
| `event_image_file` | 이벤트 이미지 파일 | 자산 테이블 | S3 기반 파일 메타데이터 |
| `event_applicant` | 이벤트 응모자 기준 | 기준 테이블 | 이벤트 참여자 중복 방지 가드 |
| `event_entry` | 이벤트 응모 이력 | 로그 테이블 | 응모 행위 이력 기록 |
| `event_draw_round` | 이벤트 추첨 회차 | 정책 테이블 | 추첨 회차·기간·상태 관리 |
| `event_win` | 이벤트 당첨 및 경품 지급 | 결과 테이블 | 당첨 결과 및 발송/수령 상태 |
| `event_sns` | 이벤트 SNS 공유 정보 | 정책 테이블 | SNS 채널별 공유 콘텐츠 정의 |
| ~~`event_prize_probability`~~ | 경품 당첨 확률 | 확장 테이블 | `entire.sql`에만 존재, 개별 md 없음 |

---

## 2. 도메인 계층 구조

```
[기준/마스터]
  prize
  event
    │
    ├── [정책/설정]
    │     ├── event_prize       (이벤트별 경품 구성)
    │     ├── event_banner      (배너 노출 정책)
    │     ├── event_draw_round  (추첨 회차 스케줄)
    │     └── event_sns         (SNS 공유 콘텐츠)
    │
    ├── [자산]
    │     ├── event_image_file      (파일 메타)
    │     └── event_banner_image    (배너-이미지 매핑)
    │
    └── [행위/이력]
          ├── event_applicant   (참여자 기준·중복 방지)
          ├── event_entry       (응모 행위 로그)
          └── event_win         (당첨 결과 및 지급 이력)
```

---

## 3. 테이블별 핵심 분석

### 3.1 `event` (이벤트 마스터)

- **역할**: 이벤트 도메인의 루트 테이블
- **주요 컬럼**: `event_type`, `is_active`, `is_confirmed`, `is_sns_linked`, `allow_duplicate_winner`, `allow_multiple_entry`
- **설계 특징**:
  - 운영 정책 플래그가 모두 `event` 단일 테이블에 집약되어 있어 조회는 편리하나 테이블이 비대해질 수 있음
  - `winner_selection_cycle`의 타입이 `TIMESTAMP`로 설정되어 있으나 주기(예: 매주, 매월)를 표현하기에 적합하지 않음
  - `is_visible` → DDL에서 `is_displayed`로 이름이 바뀌어 있어 컬럼명 불일치 존재

### 3.2 `prize` (경품 마스터)

- **역할**: 이벤트 독립적 경품 마스터
- **설계 특징**:
  - 단일 마스터로 여러 이벤트에서 재사용 가능
  - `recipient_end_date` / `usage_end_date` 두 날짜 필드로 수령 유효기간과 사용 유효기간을 분리
  - `prize_amount`가 경품 금액인지 최소 금액인지 명확하지 않음

### 3.3 `event_prize` (이벤트 경품 정책)

- **역할**: 이벤트별 경품 구성 및 당첨 가능 수 정책
- **설계 특징**:
  - `prize` 마스터를 참조하지 않고 `prize_type` 코드만 사용 (FK 미설정)
  - `prize_no`로 이벤트 내 경품 순번 관리 (UNIQUE: event_id, prize_no)
  - `tax_amount` 컬럼으로 제세공과금을 정책 레벨에서도 관리

### 3.4 `event_banner` / `event_banner_image` / `event_image_file`

- **역할**: 배너 노출 정책과 이미지 자산을 3계층으로 분리
- **설계 특징**:
  - 책임 분리가 명확: 정책(event_banner) → 매핑(event_banner_image) → 자산(event_image_file)
  - `event_banner.is_visible` 컬럼이 `entire.sql`에는 있으나 개별 md DDL에는 없음 (누락)
  - 배너 PK가 `entire.sql`에서 `(id, event_id)` 복합키로 정의되어 있으나 개별 md에서는 `id` 단일키

### 3.5 `event_applicant` (이벤트 응모자 기준)

- **역할**: 중복 참여 방지 가드 테이블
- **설계 특징**:
  - `UNIQUE (event_id, member_id)` 제약으로 이벤트 단위 중복 참여 방지
  - `draw_id` 컬럼이 NULL 허용으로 존재하나 FK 미적용, 사용 목적 불명확

### 3.6 `event_entry` (이벤트 응모 이력)

- **역할**: 응모 행위 로그 테이블
- **설계 특징**:
  - 응모 시 구매 조건 스냅샷 (`purchase_amount`, `order_count`, `cancel_count`) 저장
  - `is_winner` 컬럼이 조회 편의를 위한 비정규화 컬럼 (event_win 기준 데이터와 이중 관리)
  - `prize_id`가 event_entry에 포함되어 있어 응모-경품 연결이 entry와 win 양쪽에 존재

### 3.7 `event_draw_round` (이벤트 추첨 회차)

- **역할**: 추첨 일정 및 상태 관리
- **설계 특징**:
  - `UNIQUE (event_id, draw_no)` 제약으로 이벤트 내 회차 유일성 보장
  - `draw_at` (실행 일시), `draw_start_at/end_at` (대상 기간), `announcement_at` (발표 일시) 세분화

### 3.8 `event_win` (당첨 및 경품 지급)

- **역할**: 당첨 결과 및 지급 전 과정 관리
- **설계 특징**:
  - `UNIQUE (event_id, member_id, draw_id, entry_id)` 복합 유니크로 중복 당첨 방지
  - `is_sent`, `is_received`, `is_email_sent`, `is_sms_sent` 4개의 상태 플래그
  - FK가 `event_id → event.id` 하나뿐이고 `draw_id`, `entry_id`는 FK 미적용
  - DDL COMMENT에 `is_recorded` 컬럼이 참조되나 실제 DDL에 존재하지 않는 오류

### 3.9 `event_sns` (SNS 공유 정보)

- **역할**: SNS 채널별 공유 콘텐츠 정의
- **설계 특징**:
  - `UNIQUE (event_id, sns_code)`로 채널별 1건 보장
  - `image_url`이 자유 텍스트 URL로 `event_image_file` 미연동 (비고에 고민 중 기록됨)
  - 공유 이력(발송 성공/실패)은 별도 관리가 필요하나 해당 테이블 미존재

---

## 4. 공통 설계 패턴

| 패턴 | 내용 |
|---|---|
| 대체키 PK | 모든 테이블이 `BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY` 사용 |
| 논리 삭제 | `is_deleted` + `deleted_at` 조합으로 논리 삭제 통일 |
| 이력 관리 | `created_at`, `created_by`, `updated_at`, `updated_by` 4컬럼 전 테이블 공통 |
| 코드 참조 | 코드성 컬럼은 `VARCHAR`로 값만 저장, 공통 코드 테이블(`code_group`) 참조 |
| FK 정책 | 핵심 관계는 `REFERENCES` 명시, 일부는 논리적 관계로만 표현 |

---

## 5. 이슈 및 불일치 요약

| 항목 | 내용 |
|---|---|
| 컬럼명 불일치 | `event.is_visible` (md) vs `is_displayed` (DDL) |
| PK 불일치 | `event_banner`, `event_sns` 등: entire.sql은 복합PK, 개별 md는 단일PK |
| DDL 오류 | `event_win` COMMENT에 `is_recorded` 컬럼 참조하나 실제 컬럼 없음 |
| FK 미적용 | `event_prize` → `prize`, `event_win`의 `draw_id`, `entry_id` 등 |
| 타입 의문 | `event.winner_selection_cycle`: 주기값에 TIMESTAMP 부적절 |
| 누락 테이블 | `event_prize_probability`가 entire.sql에 존재하나 개별 md 없음 |
| SNS 공유 이력 | 공유 실행 이력/성과 테이블 미정의 |

---

## 6. ERD 관계 요약

```
prize ──────────── event_prize ◄──── event
                                        │
                    event_banner ───────┤
                    event_draw_round ───┤
                    event_sns ──────────┤
                    event_applicant ────┤
                    event_entry ────────┤
                    event_win ──────────┘
                         │
                    event_image_file ◄── event_banner_image ◄── event_banner
```
