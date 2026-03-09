# 출석체크 외부 API 명세 (v1)

> BaseResponse: `{ code, message, timestamp, data }` (참조: `docs/finalDDL/docs/BaseResponse.md`)  
> 대상 스키마: `docs/finalDDL/postgres_ddl.sql` (`event`, `event_applicant`, `event_entry`)

---

## 1. 공통

- Base URL: `/api/v1`
- 인증: `X-Api-Key`
- Content-Type: `application/json`
- 회원 식별: 쇼핑몰 `externalMemberId` → 이벤트 플랫폼 `member_id`로 매핑 (검증 없음)
- 출석 대상 이벤트 조건
  - `event.event_type = 'ATTENDANCE'`
  - `event.is_active = TRUE`
  - 현재 시각 ∈ [`event.start_at`, `event.end_at`]

---

## 2. 출석 체크 실행

- 메소드/URL: `POST /events/{eventId}/rounds/{roundId}/attendance/check-in`
- 기능: 회차별 1회 출석 기록 및 로그 적재

### Request

Headers
```
X-Api-Key: {apiKey}
Content-Type: application/json
```

Path
| name | type | required | desc |
|---|---|---|---|
| eventId | Long | Y | 이벤트 ID |
| roundId | Long | Y | 회차 ID |

Body
```json
{
  "externalMemberId": "shop_user_10001"
}
```

### Response (201)
```json
{
  "code": "ATT_CHECKED_IN",
  "message": "출석이 완료되었습니다.",
  "timestamp": "2026-03-09T09:00:00Z",
  "data": {
    "applicantId": 101,
    "entryId": 2201,
    "eventId": 1,
    "roundId": 12,
    "externalMemberId": "shop_user_10001",
    "checkedInAt": "2026-03-09T09:00:00Z"
  }
}
```

### 처리 규칙
- 성공 시
  - `event_applicant` upsert: (event_id, round_id, member_id)
  - `event_entry` insert: (event_id, round_id, member_id, applied_at)
- 중복 체크: 동일 (event_id, round_id, member_id) 출석 존재 시 `ATT_ALREADY_CHECKED_IN`

### Error
| HTTP | code | message |
|---|---|---|
| 404 | EVT_NOT_FOUND | 이벤트를 찾을 수 없습니다. |
| 403 | EVT_NOT_ACTIVE | 현재 진행 중인 이벤트가 아닙니다. |
| 403 | EVT_EXPIRED | 종료된 이벤트입니다. |
| 403 | ATT_NOT_ELIGIBLE | 출석 보상 대상이 아닙니다. |
| 409 | ATT_ALREADY_CHECKED_IN | 이미 오늘 출석했습니다. |
| 409 | ATT_REWARD_ALREADY_GRANTED | 이미 출석 보상을 수령했습니다. |

---

## 3. 출석 상태 조회

- 메소드/URL: `GET /events/{eventId}/rounds/{roundId}/attendance/status`
- 기능: 특정 회차 기준 회원의 당일 출석 여부 조회

### Request

Headers
```
X-Api-Key: {apiKey}
```

Path & Query
| name | type | required | in | desc |
|---|---|---|---|---|
| eventId | Long | Y | Path | 이벤트 ID |
| roundId | Long | Y | Path | 회차 ID |
| externalMemberId | String | Y | Query | 쇼핑몰 회원 ID |

### Response (200)
```json
{
  "code": "ATT_STATUS_OK",
  "message": "출석 상태를 조회했습니다.",
  "timestamp": "2026-03-09T09:05:00Z",
  "data": {
    "checkedIn": true,
    "eventId": 1,
    "roundId": 12,
    "externalMemberId": "shop_user_10001",
    "entryId": 2201,
    "checkedInAt": "2026-03-09T09:00:00Z"
  }
}
```

### Error
| HTTP | code | message |
|---|---|---|
| 404 | EVT_NOT_FOUND | 이벤트를 찾을 수 없습니다. |
| 403 | EVT_NOT_ACTIVE | 현재 진행 중인 이벤트가 아닙니다. |
| 403 | EVT_EXPIRED | 종료된 이벤트입니다. |

---

## 4. DB 매핑 메모

- `event` : 출석 이벤트 여부/기간/활성 상태 확인
- `event_applicant` : `UNIQUE(event_id, round_id, member_id)`로 중복 출석 방지
- `event_entry` : 출석 성공 로그 append (`applied_at`, `is_winner` 기본 FALSE)

> 참고: 응답 코드 `ATT_STATUS_OK`가 코드 enum에 없다면 `BaseResponse`의 AttendanceCode에 추가 필요.
