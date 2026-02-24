# 이벤트 도메인 DDL 개선 사항

> 기반 문서: `analysis.md`  
> 작성일: 2026-02-24

---

## 1. 버그 / 오류 수정 (즉시 수정 권고)

### 1-1. `event_win` COMMENT 오류 - `is_recorded` 존재하지 않는 컬럼 참조

**문제**: DDL COMMENT에 `is_recorded` 컬럼이 기술되어 있으나 실제 DDL 컬럼 정의가 없음

```sql
-- 오류: is_recorded 컬럼이 테이블 정의에 없음
COMMENT ON COLUMN event_win.is_recorded IS '응모 이력 저장 여부';
```

**조치**: COMMENT 행 제거 또는 컬럼 추가

---

### 1-2. `event` 테이블 컬럼명 불일치

**문제**: 문서(`event.md`)에는 `is_visible`, DDL에는 `is_displayed`로 표기

| 위치 | 컬럼명 |
|---|---|
| 문서(event.md) | `is_visible` |
| DDL (event.md) | `is_displayed` |
| entire.sql | `is_visible` |

**조치**: 팀 협의 후 하나의 이름으로 통일 (`is_displayed` 권고 - 의미가 명확)

---

### 1-3. `event_banner` PK 정의 불일치

**문제**: `entire.sql`에서 `(id, event_id)` 복합 PK, 개별 DDL에서 `id` 단일 PK

**조치**: `id` 단일 PK로 통일 (복합PK는 실익이 없고 JOIN 복잡도 증가)

---

### 1-4. `event_sns` FK 누락

**문제**: DDL에서 `event_sns.event_id`의 `REFERENCES event(id)` 누락  
`ALTER TABLE ... ADD FOREIGN KEY` 문법 오류 (ADD CONSTRAINT 키워드 누락)

```sql
-- 잘못된 구문
ALTER TABLE event_sns FOREIGN KEY (event_id) REFERENCES event(id);

-- 올바른 구문
ALTER TABLE event_sns ADD CONSTRAINT fk_event_sns_event
    FOREIGN KEY (event_id) REFERENCES event(id);
```

---

## 2. 설계 개선 (중요도 순)

### 2-1. `event_prize` ↔ `prize` FK 연결 추가

**현재**: `event_prize`에 `prize_no` + `prize_type` 코드만 있고 `prize.id` 참조 없음  
**문제**: 어느 마스터 경품인지 추적 불가, 경품명·금액 재조회 시 JOIN 불가

**개선안**:
```sql
-- event_prize에 prize_id 추가
ALTER TABLE event_prize ADD COLUMN prize_id BIGINT REFERENCES prize(id);
```

> 단, prize 없이도 이벤트 경품을 운영하는 경우라면 NULL 허용 유지

---

### 2-2. `event.winner_selection_cycle` 타입 변경

**현재**: `TIMESTAMP` 타입 → 주기(예: "매주", "7일마다") 표현 불가  
**개선안**: `VARCHAR(30)` 또는 `INTEGER`(일 단위) + 코드 컬럼 조합

```sql
-- 옵션 A: 주기 코드 + 간격 숫자 분리
winner_selection_cycle_type  VARCHAR(30),  -- DAILY, WEEKLY, MONTHLY 등
winner_selection_cycle_days  INTEGER,      -- 간격(일 수)

-- 옵션 B: 단순화 - 주기 코드만
winner_selection_cycle       VARCHAR(30)   -- WEEKLY, EVERY_2WEEKS 등
```

---

### 2-3. `event_win`의 `draw_id`, `entry_id` FK 추가

**현재**: `event_id`만 FK 적용, `draw_id`, `entry_id`는 논리적 관계만 존재  
**문제**: 데이터 정합성 보장 없음, 참조하는 행이 삭제(논리 삭제 제외)될 경우 고아 데이터 발생

**개선안**:
```sql
ALTER TABLE event_win ADD CONSTRAINT fk_event_win_draw
    FOREIGN KEY (draw_id) REFERENCES event_draw_round(id);

ALTER TABLE event_win ADD CONSTRAINT fk_event_win_entry
    FOREIGN KEY (entry_id) REFERENCES event_entry(id);
```

---

### 2-4. `event_applicant.draw_id` 컬럼 목적 명확화

**현재**: `draw_id` NULL 허용으로 존재하나 FK 없고 사용 목적 불명확  
**문제**: 추첨 회차와 응모자 기준을 연결하는 의도라면 FK 필요, 아니면 컬럼 제거 고려

**개선안 A** (추첨 회차 연결 목적이라면):
```sql
ALTER TABLE event_applicant ADD CONSTRAINT fk_event_applicant_draw
    FOREIGN KEY (draw_id) REFERENCES event_draw_round(id);
```

**개선안 B** (불필요하다면 컬럼 제거):
```sql
ALTER TABLE event_applicant DROP COLUMN draw_id;
```

---

### 2-5. `event_entry.is_winner` 비정규화 관리 강화

**현재**: `is_winner`가 `event_entry`에 존재하고 `event_win`에도 당첨 여부가 간접 표현됨  
**문제**: 두 테이블 간 데이터 불일치 가능성

**권고**: 트리거 또는 애플리케이션 레벨에서 `event_win` INSERT 시 `event_entry.is_winner = TRUE` 동기화 로직 명시화, 문서화

---

### 2-6. `event_sns.image_url` → `event_image_file` 연동 검토

**현재**: `image_url VARCHAR(200)` 자유 텍스트, 파일 자산 테이블 미연동  
**문제**: 이미지 관리 이원화, CDN 경로 변경 시 수동 업데이트 필요

**개선안**:
```sql
-- image_url 대신 event_image_file 참조
ALTER TABLE event_sns ADD COLUMN image_file_id BIGINT REFERENCES event_image_file(id);
-- image_url은 하위 호환성 유지 목적으로 병행 운영 후 deprecated
```

---

### 2-7. SNS 공유 이력 테이블 추가

**현재**: SNS 공유 실행 이력 테이블 없음  
**필요성**: 공유 성공/실패 이력, 중복 공유 방지, 마케팅 성과 분석

**신규 테이블 제안** (`event_sns_share_log`):

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | BIGINT | PK |
| event_id | BIGINT | 이벤트 ID (FK) |
| member_id | BIGINT | 공유 실행 회원 |
| sns_code | VARCHAR(10) | 공유 채널 |
| shared_at | TIMESTAMP | 공유 일시 |
| is_success | BOOLEAN | 공유 성공 여부 |

---

### 2-8. `event_prize_probability` 문서화

**현재**: `entire.sql`에만 존재하고 개별 md 파일 없음  
**조치**: 해당 테이블 설계 문서 및 DDL 개별 파일 생성 필요

---

## 3. 인덱스 설계 권고

현재 DDL에 인덱스 정의가 없음. 주요 조회 패턴 기반 인덱스 추가 권고:

| 테이블 | 인덱스 컬럼 | 이유 |
|---|---|---|
| `event` | `is_active, is_displayed, start_at, end_at` | 진행 중 이벤트 목록 조회 |
| `event_entry` | `event_id, member_id` | 이벤트별 회원 응모 이력 조회 |
| `event_win` | `event_id, member_id` | 당첨자 조회 |
| `event_sns` | `event_id` | 이벤트별 SNS 정보 조회 |
| `event_applicant` | `event_id, member_id` | UNIQUE 자체가 인덱스 역할 |

---

## 4. 명명 규칙 통일

| 현황 | 권고 |
|---|---|
| `is_visible` vs `is_displayed` | `is_displayed`로 통일 (더 명확한 의미) |
| `draw_id` (event_win) COMMENT에 "추첨 회차 번호" | "추첨 회차 식별자"로 수정 (ID는 식별자) |
| `entry_id` (event_win): 타입 BIGINT, 원본은 INTEGER | BIGINT로 통일 |

---

## 5. 개선 우선순위 요약

| 우선순위 | 항목 | 난이도 |
|---|---|---|
| 🔴 즉시 | is_recorded COMMENT 오류 제거 | 낮음 |
| 🔴 즉시 | event_sns FK 구문 수정 | 낮음 |
| 🔴 즉시 | event 컬럼명(is_visible/is_displayed) 통일 | 낮음 |
| 🟡 단기 | event_prize ↔ prize FK 연결 | 중간 |
| 🟡 단기 | event_win draw_id, entry_id FK 추가 | 중간 |
| 🟡 단기 | winner_selection_cycle 타입 변경 | 중간 |
| 🟢 중기 | SNS 공유 이력 테이블 추가 | 높음 |
| 🟢 중기 | event_sns 이미지 파일 연동 | 중간 |
| 🟢 중기 | 인덱스 설계 및 적용 | 중간 |
