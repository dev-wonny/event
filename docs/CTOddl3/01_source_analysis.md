# CTOddl 원본 분석 문서 (CTOddl3)

## 1. 분석 대상

- 원본 DDL: `docs/CTOddl/entire.sql`
- 원본 설명 문서: `docs/CTOddl/*.md`

## 2. 소스 구성 요약

| 구분 | 개수 | 비고 |
|---|---:|---|
| DDL 파일 | 1 | `entire.sql` |
| 설명 문서(md) | 11 | 테이블별 설명 |
| 실제 테이블 수 | 12 | `event_prize_probability` 포함 |
| 문서 누락 테이블 | 1 | `event_prize_probability` 문서 없음 |

## 3. 테이블 구조 요약 (원본 기준)

| 테이블 | 역할 | 주요 참조 |
|---|---|---|
| `event` | 이벤트 마스터 | 상위 기준 |
| `prize` | 경품 마스터 | `event_prize`에서 참조 |
| `event_prize` | 이벤트별 경품 정책 | `event`, `prize` |
| `event_draw_round` | 추첨 회차 관리 | `event` |
| `event_entry` | 응모 이력 | `event` |
| `event_win` | 당첨/발송/수령 결과 | `event_draw_round`, (실제론 `event`, `entry`, `prize`도 필요) |
| `event_applicant` | 참여자 기준(가드) | `event` |
| `event_sns` | SNS 공유 메타 정보 | `event` |
| `event_banner` | 배너 노출 정책 | `event` |
| `event_image_file` | 이미지 파일 메타 | 배너/이벤트 리소스 |
| `event_banner_image` | 배너-파일 매핑 | `event_banner`, `event_image_file` |
| `event_prize_probability` | 경품 확률 정책 | 원본에 제약 정의 누락 |

## 4. 도메인 흐름 해석 (원본 의도)

1. `event`에서 이벤트 기본 정책 관리
2. `prize` + `event_prize`로 이벤트별 경품 구성
3. `event_draw_round`로 회차/발표 일정 관리
4. `event_entry`로 응모 이력 저장
5. `event_win`으로 당첨 결과 및 발송/수령 상태 관리
6. `event_banner`, `event_image_file`, `event_banner_image`로 노출 리소스 관리
7. `event_sns`로 채널별 공유 메타 정보 관리

## 5. 원본 DDL의 주요 문제점 (핵심)

### 5.1 제약조건/관계 오류

| 항목 | 문제 | 영향 |
|---|---|---|
| `event_applicant` FK | `event_id`가 아니라 `id`가 `event.id`를 참조하도록 정의됨 | 잘못된 참조 관계, 데이터 무결성 붕괴 |
| `event_banner_image` FK (`event_id`) | `event_banner(event_id)`만 참조 (원본 PK는 `(id, event_id)`) | MySQL 기준 FK 생성 실패 가능성 큼 |
| `event_win` FK 부족 | `event`, `event_entry`, `prize`(또는 `event_prize`) FK 없음 | 당첨 데이터 정합성 검증 불가 |
| `event_prize_probability` 제약 누락 | PK/FK/UNIQUE 정의 없음 | 중복/고아 데이터 발생 가능 |

### 5.2 PK 설계 복잡도 과다 (불필요한 복합 PK)

원본은 `id` 컬럼이 있음에도 아래 테이블에서 복합 PK를 사용합니다.

- `event_banner_image`: `(id, event_file_id, event_banner_id, event_id)`
- `event_prize`: `(id, event_id, prize_id)`
- `event_sns`: `(id, event_id)`
- `event_banner`: `(id, event_id)`
- `event_win`: `(id, draw_id)`

문제점:

- `id` 단일 PK로 충분한데 복합 PK로 인해 FK 정의가 어려워짐
- 쿼리/인덱스/ORM 매핑 복잡도 증가
- 컬럼 의미(식별자 vs 관계키)가 섞여 관리 난이도 상승

### 5.3 NULL 허용/필수값 불일치

원본 DDL에서 여러 테이블의 `id`가 `NULL`로 선언되어 있음:

- 예: `event.id`, `prize.id`, `event_entry.id` 등

실제 PK 추가로 인해 결과적으로는 NOT NULL이 되지만, DDL 가독성과 설계 의도 표현 측면에서 좋지 않습니다.

또한 논리적으로 필수인 컬럼이 NULL 허용인 사례가 있음:

- `event_banner.event_id` (설명 문서상 FK인데 원본 DDL은 NULL 허용)
- `event_banner_image.event_file_id`, `event_banner_id` (매핑 테이블인데 NULL 허용)

## 6. 원본 DDL vs 설명 문서 불일치

| 대상 | 불일치 내용 |
|---|---|
| `event_prize.md` | 설명 문서에 `prize_no`가 나오나 원본 DDL은 `prize_id` 사용 |
| `event_prize.md` | FK 설명에 `evnet.id` 오타 |
| `event_draw.md` | 문서 파일명은 `event_draw.md`, 실제 테이블명은 `event_draw_round` |
| `event_banner_image.md` | FK 설명 문구가 붙어 있어 가독성 낮음 (`event_banner.id` + `event_file_id` 구분 불명확) |
| 전체 문서 | 컬럼/제약/기본값 설명 수준이 테이블마다 들쭉날쭉 |

## 7. 설계 개선 방향 (간소화 원칙)

다음 문서(`03_simplified_ddl_with_sample_data.md`)는 아래 원칙으로 재작성하는 것이 적절합니다.

1. 모든 테이블은 `id` 단일 PK 사용 (복합 PK 제거)
2. FK 컬럼은 논리적으로 필수인 경우 `NOT NULL`
3. 중복 방지는 `UNIQUE KEY`로 표현 (예: `event_id + sns_code`)
4. 중복 정보 제거 (예: `event_banner_image`에서 불필요한 `event_id` 제거)
5. 누락된 FK/PK 보강 (`event_win`, `event_prize_probability`)
6. 예시 데이터 INSERT 포함 (테스트/이해용)

## 8. 우선 개선 대상 (실행 우선순위)

| 우선순위 | 대상 | 이유 |
|---:|---|---|
| 1 | `event_applicant` FK 수정 | 명백한 관계 오류 |
| 2 | 복합 PK 제거 (`event_banner`, `event_sns`, `event_prize`, `event_win`, `event_banner_image`) | 전체 구조 단순화 핵심 |
| 3 | `event_win` FK 보강 | 당첨 결과 정합성 확보 |
| 4 | `event_prize_probability` 제약/문서 추가 | 누락 영역 보완 |
| 5 | 문서명/컬럼명/오타 정리 | 운영/협업 가독성 향상 |

