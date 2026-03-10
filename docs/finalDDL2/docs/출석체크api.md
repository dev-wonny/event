# API 명세서 v3

> BaseResponse: `{ code, message, timestamp, data }`

- 이벤트 플랫폼은 자체 회원 없음. 돌쇠네 쇼핑몰 회원 사용.
- 관리자 API는 `/admin` prefix 없음 (API로도 생성 가능하기 때문).

## 인증 방식

| 구분 | 호출 주체 | 인증 방식 |
|------|----------|----------|
| **사용자 API** | 돌쇠네 쇼핑몰 서버 | `X-Api-Key: {apiKey}` + `X-Member-Id: {memberId}` |
| **관리자 API** | 운영자 | `Authorization: Bearer {adminToken}` |

## MVP 인증 구조

돌쇠네 쇼핑몰 서버만 이 API를 호출할 수 있도록 **두 가지**로 막습니다.

### 1. X-Api-Key

- 쇼핑몰 서버 ↔ 이벤트 서버 간 사전 발급된 고정 API Key
- 이벤트 플랫폼 API 호출 시 서버 인증 용도
- 서버는 키가 맞는지 확인하고, 틀리면 요청을 거부합니다.

#### 예시

X-Api-Key: dolsoeh-event-server-key

#### 서버 검증 예시
```java
if (!apiKey.equals(expectedKey)) {
    throw new UnauthorizedException();
}
```

### 2. IP 차단 (가능하면)

쇼핑몰 서버 IP만 API 접근 허용하여, 외부에서 아예 호출이 안 되게 막습니다.

#### IP Allowlist

쇼핑몰 서버 IP만 API 접근 허용

### 3. 향후 인증 확장 계획

API Key 대신 **HMAC 서명 토큰**으로 전환합니다.
- 요청마다 서버가 서명을 검증하기 때문에 위조가 불가능해집니다.
```java
X-Api-Key: base64(eventId:memberId:expireTime:signature)
signature = HMAC(secret, eventId:memberId:expireTime)
```



---

## 📋 목차

### 🔗 사용자 API
1. [이벤트 응모](#1-이벤트-응모)
2. [이벤트 상세 및 참여 상태 조회](#2-출석체크-전체-내역-조회)


---

# 🔗 사용자 API

## 1. 이벤트 응모

- **접근 권한**: 사용자 (돌쇠네 서버)
- **기능 설명**: 이벤트 회차에 응모
    - `event_applicant` — 이벤트 참여자 등록 
      - (`event_id + member_id` unique). 
      - 최초 참여 시 생성, 이후 재사용
    - `event_entry` 
      - 실제 응모 기록. 
      - 응모시마다 append-only로 누적 
      - (`applicant_id + round_id` unique)
      - 즉시 당첨 여부를 항상 응답에 포함. 즉시 당첨이 아니면 `isWinner: null`
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries`

**Request Header**
```
X-Api-Key: {apiKey}
X-Member-Id: {memberId}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Request Body**
```json
{}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**

> 출석체크형 이벤트 (`ATTENDANCE`): `roundId` = 해당 날짜 회차 → 출석 + 응모 + 즉시 포인트 지급 결과 포함

```json
{
  "code": "ENTY_APPLIED",
  "message": "출석 체크가 완료되었습니다.",
  "timestamp": "2026-02-02T10:00:00Z",
  "data": {
    "entryId": 200,
    "appliedAt": "2026-02-02T10:00:00Z",
    "roundNo": 2,
    "isWinner": true,
    "win": {
      "winId": 1,
      "prizeName": "2월 출석 체크 포인트 기본 세팅",
      "rewardType": "POINT",
      "pointAmount": 30
    },
    "attendance": {
      "attendedDays": 2,
      "totalDays": 28
    }
  }
}
```

> 즉시 당첨형 이벤트 — **당첨** (`isWinner: true`)

```json
{
  "code": "ENTY_APPLIED",
  "message": "응모가 완료되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "entryId": 200,
    "appliedAt": "2026-03-09T08:00:00Z",
    "isWinner": true,
    "win": {
      "winId": 1,
      "prizeName": "스타벅스 아메리카노",
      "rewardType": "COUPON"
    }
  }
}
```

> 즉시 당첨형 이벤트 — **꽝** (`isWinner: false`)

```json
{
  "code": "ENTY_APPLIED",
  "message": "응모가 완료되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "entryId": 201,
    "appliedAt": "2026-03-09T08:00:00Z",
    "isWinner": false,
    "win": null
  }
}
```

> 추첨형 이벤트 (즉시 결과 없음) — **추첨 전** (`isWinner: null`)

```json
{
  "code": "ENTY_APPLIED",
  "message": "응모가 완료되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "entryId": 200,
    "appliedAt": "2026-03-09T08:00:00Z",
    "isWinner": null,
    "win": null
  }
}
```

### **`isWinner` 값 정의**

| 값 | 의미 |
|------|------|
| `true` | 당첨 |
| `false` | 꽝 |
| `null` | 추첨형 이벤트 (결과 나중에 발표) |



 ### **`win` 객체 필드** (`rewardType`에 따라 다름)

| 필드 | 타입 | 설명 |
|------|------|------|
| `winId` | Long | 당첨 식별자 |
| `prizeName` | String | 경품명 |
| `rewardType` | String | `POINT` / `COUPON` |
| `pointAmount` | Integer | POINT 타입일 때만 포함 |
| `couponCode` | String | COUPON 타입일 때만 포함 (선택) |

 ### **`attendance` 객체** — `eventType: ATTENDANCE` 일 때만 포함

| 필드 | 타입 | 설명 |
|------|------|------|
| `attendedDays` | Integer | 이번 달 누적 출석 일수 |
| `totalDays` | Integer | 이벤트 전체 일수 |

### **Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |
| 403 | `EVT_NOT_ACTIVE` | 현재 진행 중인 이벤트가 아닙니다. |
| 403 | `EVT_EXPIRED` | 종료된 이벤트입니다. |
| 409 | `ENTY_ALREADY_ENTERED` | 이미 참여하였습니다. |
| 409 | `ENTY_LIMIT_EXCEEDED` | 참여 가능 횟수를 초과했습니다. |
| 400 | `ENTY_INVALID_CONDITION` | 참여 조건이 유효하지 않습니다. |

---

## 2. 이벤트 상세 및 참여 상태 조회

- 출석 이벤트의 전체 회차 목록과 출석 상태를 조회합니다.

- **접근 권한**: 돌쇠네 쇼핑몰 서버
- **기능 설명**: 출석체크 이벤트의 전체 회차(날짜) 목록 및 출석 현황 조회. `eventType: ATTENDANCE`일 때 동작
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}`

**Request Header**
```
X-Api-Key: {apiKey}
X-Member-Id: {memberId}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**


### 출석체크 이벤트 (`ATTENDANCE`): 
- 전체 회차(날짜) 반환. 페이지네이션 없음.
- 2월 출석체크 이벤트의 경우 
  - 2월 1일 ~ 2월 28일까지, 28개 회차 반환

```json
{
  "code": "EVT_OK",
  "message": "이벤트를 조회했습니다.",
  "timestamp": "2026-02-09T10:00:00Z",
  "data": {
    "eventId": 1,
    "eventName": "2월 출석체크 이벤트",
    "eventType": "ATTENDANCE",
    "startAt": "2026-02-01T00:00:00Z",
    "endAt": "2026-02-28T23:59:59Z",
    "supplierId": 1,
    "eventUrl": "https://...",
    "priority": 1,
    "isActive": true,
    "isVisible": true,
    "description": "매일 출석하고 포인트를 받으세요!",
    "createdAt": "2026-01-20T10:00:00Z",
    "totalCount": 28,
    "rounds": [
      { "roundId": 1, "roundNo": 1, "roundDate": "2026-02-01", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 2, "roundNo": 2, "roundDate": "2026-02-02", "status": "MISSED",   "win": null },
      { "roundId": 3, "roundNo": 3, "roundDate": "2026-02-03", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 4, "roundNo": 4, "roundDate": "2026-02-04", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 5, "roundNo": 5, "roundDate": "2026-02-05", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 6, "roundNo": 6, "roundDate": "2026-02-06", "status": "MISSED",   "win": null },
      { "roundId": 7, "roundNo": 7, "roundDate": "2026-02-07", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 8, "roundNo": 8, "roundDate": "2026-02-08", "status": "ATTENDED", "win": { "prizeName": "출석 포인트", "rewardType": "POINT", "pointAmount": 30 } },
      { "roundId": 9, "roundNo": 9, "roundDate": "2026-02-09", "status": "TODAY",    "win": null },
      { "roundId": 10, "roundNo": 10, "roundDate": "2026-02-10", "status": "FUTURE", "win": null },
      { "comment": "...이하 동일..." },
      { "roundId": 28, "roundNo": 28, "roundDate": "2026-02-28", "status": "FUTURE", "win": null }
    ],
    "attendanceSummary": {
      "attendedDays": 7,
      "totalDays": 28,
      "currentDay": 9
    }
  }
}
```

### `rounds[].status` 값 정의

| status | 조건 | 설명 |
|--------|------|------|
| `ATTENDED` | 과거 날짜 + 출석 완료 | 출석 완료 |
| `MISSED` | 과거 날짜 + 미출석 | 출석 누락 |
| `TODAY` | 오늘 날짜 | 현재 진행 중인 회차 |
| `FUTURE` | 오늘 이후 날짜 | 잠김, 내용 없음 |



### 일반 이벤트

```json
{
  "code": "EVT_OK",
  "message": "이벤트를 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "eventId": 1,
    "eventName": "3월 경품 이벤트",
    "eventType": "RANDOM_REWARD",
    "startAt": "2026-03-01T00:00:00Z",
    "endAt": "2026-03-31T23:59:59Z",
    "supplierId": 1,
    "eventUrl": "https://...",
    "priority": 1,
    "isActive": true,
    "isVisible": true,
    "isAutoEntry": false,
    "isSnsLinked": false,
    "isDuplicateWinner": false,
    "isMultipleEntry": false,
    "isWinnerAnnounced": false,
    "description": "경품 이벤트 설명",
    "createdAt": "2026-02-20T10:00:00Z",
    "rounds": [
      {
        "roundId": 1,
        "roundNo": 1,
        "startAt": "2026-03-01T00:00:00Z",
        "endAt": "2026-03-31T23:59:59Z",
        "prizes": [
          { "prizeId": 1, "prizeName": "스타벅스 아메리카노", "rewardType": "COUPON", "quantity": 100 },
          { "prizeId": 2, "prizeName": "네이버 페이 3만원 쿠폰", "rewardType": "COUPON", "quantity": 10 }
        ]
      },
      {
        "roundId": 2,
        "roundNo": 2,
        "startAt": "2026-04-01T00:00:00Z",
        "endAt": "2026-04-30T23:59:59Z",
        "prizes": [
          { "prizeId": 3, "prizeName": "스타복 기프티콘 5만원", "rewardType": "COUPON", "quantity": 50 }
        ]
      }
    ]
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---