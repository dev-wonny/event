# API 명세서 v2

> BaseResponse: `{ code, message, timestamp, data }`

## 인증 방식

| 구분 | 호출 주체 | 인증 방식 |
|------|----------|----------|
| **사용자 API** | 돌쇠네 쇼핑몰 서버 | `X-Api-Key: {apiKey}` + `X-Member-Id: {memberId}` |
| **관리자 API** | 운영자 | `Authorization: Bearer {adminToken}` |

> - 이벤트 플랫폼은 자체 회원 없음. 돌쇠네 쇼핑몰 회원 사용.
> - `memberId`는 돌쇠네 회원 ID이며 **검증 없이 식별자로 사용**.
> - 관리자 API는 `/admin` prefix 없음 (API로도 생성 가능하기 때문).

---

## 📋 목차

### 🔗 사용자 API
1. [이벤트 응모](#1-이벤트-응모)
3. [참여 여부 조회](#3-참여-여부-조회)
4. [당첨 내역 조회](#4-당첨-내역-조회)

### 🔧 관리자 API
**이벤트 (event)**
5. [이벤트 생성](#5-이벤트-생성)
6. [이벤트 목록 조회](#6-이벤트-목록-조회)
7. [이벤트 상세 조회](#7-이벤트-상세-조회)
8. [이벤트 수정](#8-이벤트-수정)
9. [이벤트 삭제](#9-이벤트-삭제)
10. [이벤트 상태 변경](#10-이벤트-상태-변경)

**회차 (event_round)**
11. [회차 생성](#11-회차-생성)
12. [회차 목록 조회](#12-회차-목록-조회)
13. [회차 상세 조회](#13-회차-상세-조회)
14. [회차 수정](#14-회차-수정)
15. [회차 삭제](#15-회차-삭제)
16. [회차 상태 변경](#16-회차-상태-변경)

**경품 (prize)**
17. [경품 생성](#17-경품-생성)
18. [경품 목록 조회](#18-경품-목록-조회)
19. [경품 상세 조회](#19-경품-상세-조회)
20. [경품 수정](#20-경품-수정)
21. [경품 삭제](#21-경품-삭제)
22. [경품 상태 변경](#22-경품-상태-변경)

**회차별 경품 설정 (event_round_prize)**
23. [경품 설정 등록](#23-경품-설정-등록)
24. [경품 설정 조회](#24-경품-설정-조회)
25. [경품 설정 수정](#25-경품-설정-수정)
26. [경품 설정 삭제](#26-경품-설정-삭제)
27. [경품 설정 상태 변경](#27-경품-설정-상태-변경)

**확률 (event_round_prize_probability)**
28. [확률 설정 등록](#28-확률-설정-등록)
29. [확률 설정 조회](#29-확률-설정-조회)
30. [확률 설정 수정](#30-확률-설정-수정)
31. [확률 설정 삭제](#31-확률-설정-삭제)

**참여자 (event_applicant)**
32. [참여자 수기 등록](#32-참여자-수기-등록)
33. [참여자 조회 / 검색](#33-참여자-조회--검색)
34. [참여자 수정](#34-참여자-수정)
35. [참여자 삭제](#35-참여자-삭제)

**응모자 (event_entry)**
36. [응모자 수기 등록](#36-응모자-수기-등록)
37. [응모자 조회 / 검색](#37-응모자-조회--검색)
38. [응모자 수정](#38-응모자-수정)
39. [응모자 삭제](#39-응모자-삭제)
40. [응모자 상태 변경](#40-응모자-상태-변경)

**당첨자 (event_win)**
41. [추첨 실행](#41-추첨-실행)
42. [당첨자 수기 등록](#42-당첨자-수기-등록)
43. [당첨자 조회 / 검색](#43-당첨자-조회--검색)
44. [당첨자 수정](#44-당첨자-수정)
45. [당첨자 삭제](#45-당첨자-삭제)

---

## 🔗 사용자 API

---

### 1. 이벤트 응모

- **접근 권한**: 사용자 (돌쇠네 서버)
- **기능 설명**: 이벤트 회차에 참여 후 응모. 즉시 당첨 여부를 항상 응답에 포함하며, 즉시 당첨이 아니면 `isWinner: null` 로 반환
    - event_applicant 에 참여 생성
      - 이벤트 당 참여는 1개
      - 필터 용도 : 더 이상 이벤트에 참여해도 되는 사람인지 validation 안함
    - event_entry에는 응모시 매번 append-only
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries`

**Request Header**
```
X-Api-Key: {apiKey}
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

> 즉시 당첨형 이벤트: `isWinner`, `win` 포함

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

> 이무 추첨형 이벤트 (즉시 당첨 없음): `isWinner: null`, `win: null`

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

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |
| 403 | `EVT_NOT_ACTIVE` | 현재 진행 중인 이벤트가 아닙니다. |
| 403 | `EVT_EXPIRED` | 종료된 이벤트입니다. |
| 409 | `ENTY_ALREADY_ENTERED` | 이미 참여하였습니다. |
| 409 | `ENTY_LIMIT_EXCEEDED` | 참여 가능 횟수를 초과했습니다. |
| 400 | `ENTY_INVALID_CONDITION` | 참여 조건이 유효하지 않습니다. |

---

### 2. 참여 여부 조회 (event_applicant)

- **접근 권한**: 사용자 (돌쇠네 서버)
- **기능 설명**: 회원의 현재 회차 응모 여부 확인 (memberId로 event_applicant 조회)
    - 이벤트에 참여자가 참여한 경우 event_applicant에 한개 row 생김
    - event_applicant 로 참여자 여부 확인 가능 
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/participation`

**Request Header**
```
X-Api-Key: {apiKey}
X-Member-Id: {memberId}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Request Body**: 없음

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ENTY_LIST_OK",
  "message": "응모 내역을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "isApplied": true
  }
}
```

### 3. 응모 내역 조회 (event_entry)

- **접근 권한**: 사용자 (돌쇠네 서버)
- **기능 설명**: 회원의 특정 회차 응모 이력 조회
    - **참여 (event_applicant)**: 이벤트당 1개 row. 참여 여부 필터 용도
    - **응모 (event_entry)**: 응모할 때마다 append-only로 누적 (1회차에 여러 번 응모 가능한 경우)
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries`

**Request Header**
```
X-Api-Key: {apiKey}
X-Member-Id: {memberId}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Request Body**: 없음

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ENTY_LIST_OK",
  "message": "응모 내역을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "totalCount": 3,
    "entries": [
      {
        "entryId": 200,
        "appliedAt": "2026-03-09T08:00:00Z",
        "isWinner": null
      },
      {
        "entryId": 201,
        "appliedAt": "2026-03-09T09:00:00Z",
        "isWinner": true
      }
    ]
  }
}
```

> - `isWinner: null` → 즉시 당첨형이 아닌 이벤트, 또는 추첨 전
> - `isWinner: true / false` → 즉시 당첨형 이벤트 응모 결과

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 4. 당첨 내역 조회

- **접근 권한**: 사용자 (돌쇠네 서버)
- **기능 설명**: 회원의 이벤트 당첨 내역 조회
- **메소드**: `GET`
- **URL**: `/api/v1/wins`

**Request Header**
```
X-Api-Key: {apiKey}
X-Member-Id: {memberId}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | N | 이벤트 식별자 (Query) |
| `roundId` | Long | N | 회차 식별자 (Query) |

**Request Body**: 없음

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "WIN_OK",
  "message": "당첨 내역을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "wins": [
      {
        "winId": 1,
        "roundNo": 1,
        "prizeName": "스타벅스 아메리카노",
        "rewardType": "COUPON",
        "createdAt": "2026-03-08T10:00:00Z"
      }
    ]
  }
}
```

---

## 🔧 관리자 API

> `/admin` prefix 없음. API key 또는 JWT로 접근 제어.

---

## 이벤트 (event)

---

### 5. 이벤트 생성

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 생성. **생성 시 기본 event_round 1개 자동 생성.**
- **메소드**: `POST`
- **URL**: `/api/v1/events`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "eventName": "3월 출석체크 이벤트",
  "eventType": "ATTENDANCE",
  "startAt": "2026-03-01T00:00:00Z",
  "endAt": "2026-03-31T23:59:59Z",
  "supplierId": 1,
  "eventUrl": "https://...",
  "priority": 1,
  "isAutoEntry": false,
  "isSnsLinked": false,
  "isDuplicateWinner": false,
  "isMultipleEntry": false,
  "description": "매일 출석하고 경품을 받으세요!",
  "rounds": [
    {
      "roundStartAt": "2026-03-01T00:00:00Z",
      "roundEndAt": "2026-03-31T23:59:59Z",
      "drawAt": "2026-04-01T10:00:00Z"
    }
  ]
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "EVT_CREATED",
  "message": "이벤트가 생성되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "eventId": 1,
    "roundId": 1
  }
}
```

---

### 6. 이벤트 목록 조회

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 목록 조회. 페이징, 정렬(created_at desc), 다양한 조건 검색 지원
- **메소드**: `GET`
- **URL**: `/api/v1/events`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventName` | String | N | 이벤트명 검색 (부분일치) |
| `eventType` | String | N | 이벤트 유형 (`ATTENDANCE`, `RANDOM_REWARD`) |
| `eventId` | Long | N | 이벤트 번호 검색 |
| `startAtFrom` | String | N | 이벤트 시작일 범위 시작 (ISO 8601) |
| `startAtTo` | String | N | 이벤트 시작일 범위 종료 (ISO 8601) |
| `isActive` | Boolean | N | 활성 여부 |
| `isVisible` | Boolean | N | 전시 여부 |
| `page` | Integer | N | 페이지 번호 (기본값: 0) |
| `size` | Integer | N | 페이지 사이즈 (기본값: 20) |
| `sort` | String | N | 정렬 기준 (기본값: `created_at,desc`) |

**Request Body**: 없음

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "EVT_LIST_OK",
  "message": "이벤트 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "content": [
      {
        "eventId": 1,
        "eventName": "3월 출석체크 이벤트",
        "eventType": "ATTENDANCE",
        "startAt": "2026-03-01T00:00:00Z",
        "endAt": "2026-03-31T23:59:59Z",
        "isActive": true,
        "isVisible": true,
        "createdAt": "2026-02-20T10:00:00Z"
      }
    ],
    "totalElements": 10,
    "totalPages": 1,
    "page": 0,
    "size": 20
  }
}
```

---

### 7. 이벤트 상세 조회

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 단건 상세 조회
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "EVT_OK",
  "message": "이벤트를 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "eventId": 1,
    "eventName": "3월 출석체크 이벤트",
    "eventType": "ATTENDANCE",
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
    "description": "매일 출석하고 경품을 받으세요!",
    "createdAt": "2026-02-20T10:00:00Z",
    "roundIds": [1, 2, 3]
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 8. 이벤트 수정

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Request Body**
```json
{
  "eventName": "3월 출석체크 이벤트 (수정)",
  "isActive": true,
  "isVisible": true,
  "isWinnerAnnounced": false,
  "priority": 0,
  "description": "수정된 설명"
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "EVT_UPDATED",
  "message": "이벤트가 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 9. 이벤트 삭제

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 10. 이벤트 상태 변경

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 특정 상태 필드만 변경
- **메소드**: `PATCH`
- **URL**: `/api/v1/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Request Body**
```json
{
  "isActive": true,
  "isVisible": true,
  "isAutoEntry": false,
  "isWinnerAnnounced": true
}
```

> 변경할 필드만 포함하여 전송. 포함되지 않은 필드는 변경되지 않음.

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "EVT_STATUS_UPDATED",
  "message": "이벤트 상태가 변경되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

## 회차 (event_round)

---

### 10. 회차 생성

- **접근 권한**: 운영자
- **기능 설명**: 이벤트에 회차 추가 생성
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |

**Request Body**
```json
{
  "roundNo": 2,
  "roundStartAt": "2026-04-01T00:00:00Z",
  "roundEndAt": "2026-04-30T23:59:59Z",
  "drawAt": "2026-05-01T10:00:00Z"
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "ROUND_CREATED",
  "message": "회차가 생성되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "roundId": 2 }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 11. 회차 목록 조회

- **접근 권한**: 운영자
- **기능 설명**: 이벤트에 속한 회차 목록
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_LIST_OK",
  "message": "회차 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": [
    {
      "roundId": 1,
      "roundNo": 1,
      "roundStartAt": "2026-03-01T00:00:00Z",
      "roundEndAt": "2026-03-31T23:59:59Z",
      "drawAt": "2026-04-01T10:00:00Z",
      "isConfirmed": false
    }
  ]
}
```

---

### 12. 회차 상세 조회

- **접근 권한**: 운영자
- **기능 설명**: 회차 단건 상세 조회
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_OK",
  "message": "회차를 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "roundId": 1,
    "eventId": 1,
    "roundNo": 1,
    "roundStartAt": "2026-03-01T00:00:00Z",
    "roundEndAt": "2026-03-31T23:59:59Z",
    "drawAt": "2026-04-01T10:00:00Z",
    "isConfirmed": false
  }
}
```

---

### 13. 회차 수정

- **접근 권한**: 운영자
- **기능 설명**: 회차 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "roundStartAt": "2026-03-01T00:00:00Z",
  "roundEndAt": "2026-03-31T23:59:59Z",
  "drawAt": "2026-04-01T12:00:00Z",
  "isConfirmed": true
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_UPDATED",
  "message": "회차가 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 14. 회차 삭제

- **접근 권한**: 운영자
- **기능 설명**: 회차 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

### 16. 회차 상태 변경

- **접근 권한**: 운영자
- **기능 설명**: 회차 특정 상태 필드만 변경
- **메소드**: `PATCH`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Request Body**
```json
{
  "isConfirmed": true
}
```

> 변경할 필드만 포함하여 전송.

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_STATUS_UPDATED",
  "message": "회차 상태가 변경되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 경품 (prize)

---

### 17. 경품 생성

- **접근 권한**: 운영자
- **기능 설명**: 경품 마스터 등록
- **메소드**: `POST`
- **URL**: `/api/v1/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "prizeName": "스타벅스 아메리카노",
  "rewardType": "COUPON",
  "pointAmount": null,
  "couponId": 123,
  "prizeDescription": "스타벅스 아메리카노 쿠폰",
  "isActive": true
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "PRZ_CREATED",
  "message": "경품이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "prizeId": 10 }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `PRZ_INVALID_STATE` | 경품 상태가 유효하지 않습니다. |

---

### 16. 경품 목록 조회

- **접근 권한**: 운영자
- **기능 설명**: 경품 목록. 경품명 / 경품 타입 / 경품 상태 검색 지원
- **메소드**: `GET`
- **URL**: `/api/v1/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeName` | String | N | 경품명 검색 (부분일치) |
| `rewardType` | String | N | 경품 타입 (`POINT`, `COUPON`, `PRODUCT`, `ETC`) |
| `isActive` | Boolean | N | 활성 여부 |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PRZ_LIST_OK",
  "message": "경품 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "content": [
      {
        "prizeId": 10,
        "prizeName": "스타벅스 아메리카노",
        "rewardType": "COUPON",
        "isActive": true
      }
    ],
    "totalElements": 1,
    "totalPages": 1
  }
}
```

---

### 17. 경품 상세 조회

- **접근 권한**: 운영자
- **기능 설명**: 경품 단건 상세
- **메소드**: `GET`
- **URL**: `/api/v1/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PRZ_OK",
  "message": "경품을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "prizeId": 10,
    "prizeName": "스타벅스 아메리카노",
    "rewardType": "COUPON",
    "pointAmount": null,
    "couponId": 123,
    "prizeDescription": "스타벅스 아메리카노 쿠폰",
    "isActive": true
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |

---

### 18. 경품 수정

- **접근 권한**: 운영자
- **기능 설명**: 경품 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "prizeName": "스타벅스 라떼",
  "prizeDescription": "변경된 설명",
  "isActive": false
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PRZ_UPDATED",
  "message": "경품이 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |

---

### 19. 경품 삭제

- **접근 권한**: 운영자
- **기능 설명**: 경품 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

### 22. 경품 상태 변경

- **접근 권한**: 운영자
- **기능 설명**: 경품 특정 상태 필드만 변경
- **메소드**: `PATCH`
- **URL**: `/api/v1/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeId` | Long | Y | 경품 식별자 (Path) |

**Request Body**
```json
{
  "isActive": false
}
```

> 변경할 필드만 포함하여 전송.

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PRZ_STATUS_UPDATED",
  "message": "경품 상태가 변경되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |

---

## 회차별 경품 설정 (event_round_prize)

---

### 23. 경품 설정 등록

- **접근 권한**: 운영자
- **기능 설명**: 회차에 경품 정책 등록
- **메소드**: `POST`
- **URL**: `/api/v1/rounds/{roundId}/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**

> `rewardType`에 따라 필드가 달라짐

**예시 1 - COUPON (쿠폰형)**
```json
{
  "prizeId": 10,
  "priority": 1,
  "dailyLimit": 100,
  "totalLimit": 500,
  "isActive": true
}
```

**예시 2 - POINT (포인트형)**
```json
{
  "prizeId": 20,
  "priority": 2,
  "dailyLimit": 200,
  "totalLimit": 1000,
  "isActive": true
}
```

> `prizeId`는 `prize` 테이블에 등록된 경품 식별자.
> `rewardType`(`POINT` / `COUPON`)은 prize 테이블에서 결정되며 이 API에서는 별도로 지정하지 않음.

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "ROUND_PRIZE_CREATED",
  "message": "경품 설정이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "roundPrizeId": 5 }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |

---

### 21. 경품 설정 조회

- **접근 권한**: 운영자
- **기능 설명**: 회차에 등록된 경품 정책 목록
- **메소드**: `GET`
- **URL**: `/api/v1/rounds/{roundId}/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_PRIZE_LIST_OK",
  "message": "경품 설정을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": [
    {
      "roundPrizeId": 5,
      "prizeId": 10,
      "prizeName": "스타벅스 아메리카노",
      "priority": 1,
      "dailyLimit": 100,
      "totalLimit": 500,
      "isActive": true
    }
  ]
}
```

---

### 22. 경품 설정 수정

- **접근 권한**: 운영자
- **기능 설명**: 회차 경품 정책 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "dailyLimit": 50,
  "totalLimit": 200,
  "priority": 2,
  "isActive": false
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_PRIZE_UPDATED",
  "message": "경품 설정이 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 23. 경품 설정 삭제

- **접근 권한**: 운영자
- **기능 설명**: 회차 경품 정책 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

### 27. 경품 설정 상태 변경

- **접근 권한**: 운영자
- **기능 설명**: 회차별 경품 설정 특정 상태 필드만 변경
- **메소드**: `PATCH`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path) |

**Request Body**
```json
{
  "isActive": false
}
```

> 변경할 필드만 포함하여 전송.

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ROUND_PRIZE_STATUS_UPDATED",
  "message": "경품 설정 상태가 변경되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 확률 (event_round_prize_probability)

---

### 28. 확률 설정 등록

- **접근 권한**: 운영자
- **기능 설명**: 회차-경품 확률 정책 등록
- **메소드**: `POST`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "probability": 10.00,
  "weight": 1,
  "isActive": true
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "PROB_CREATED",
  "message": "확률 설정이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "probabilityId": 3 }
}
```

---

### 25. 확률 설정 조회

- **접근 권한**: 운영자
- **기능 설명**: 확률 정책 조회
- **메소드**: `GET`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PROB_LIST_OK",
  "message": "확률 설정을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": [
    { "probabilityId": 3, "probability": 10.00, "weight": 1, "isActive": true }
  ]
}
```

---

### 26. 확률 설정 수정

- **접근 권한**: 운영자
- **기능 설명**: 확률 정책 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{ "probability": 5.00, "weight": 2, "isActive": true }
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "PROB_UPDATED",
  "message": "확률 설정이 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 27. 확률 설정 삭제

- **접근 권한**: 운영자
- **기능 설명**: 확률 정책 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

## 참여자 (event_applicant)

---

### 28. 참여자 수기 등록

- **접근 권한**: 운영자
- **기능 설명**: 이벤트 회차 참여자 수기 등록
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/applicants`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "memberId": "dolsoi_user_001",
  "memo": "수기 등록 사유"
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "APPL_CREATED",
  "message": "참여자가 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "applicantId": 100 }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `ENTY_ALREADY_ENTERED` | 이미 참여하였습니다. |

---

### 29. 참여자 조회 / 검색

- **접근 권한**: 운영자
- **기능 설명**: 참여자 목록 조회 및 검색
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/applicants`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |
| `memberId` | String | N | 회원 식별자 |
| `applicantId` | Long | N | 참여자 식별자 |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "APPL_LIST_OK",
  "message": "참여자 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "content": [
      {
        "applicantId": 100,
        "memberId": "dolsoi_user_001",
        "createdAt": "2026-03-09T08:00:00Z"
      }
    ],
    "totalElements": 50,
    "totalPages": 3
  }
}
```

---

### 30. 참여자 수정

- **접근 권한**: 운영자
- **기능 설명**: 참여자 정보 수정 (오기입 정정용)
- **메소드**: `PUT`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/applicants/{applicantId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "memberId": "dolsoi_user_002",
  "memo": "회원 ID 오기입 수정"
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "APPL_UPDATED",
  "message": "참여자 정보가 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 31. 참여자 삭제

- **접근 권한**: 운영자
- **기능 설명**: 참여자 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/applicants/{applicantId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

## 응모자 (event_entry)

---

### 32. 응모자 수기 등록

- **접근 권한**: 운영자
- **기능 설명**: 응모 이력 수기 등록
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "memberId": "dolsoi_user_001",
  "memo": "수기 응모 등록 사유"
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "ENTRY_CREATED",
  "message": "응모자가 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "entryId": 200 }
}
```

---

### 33. 응모자 조회 / 검색

- **접근 권한**: 운영자
- **기능 설명**: 응모 이력 목록 조회 및 검색
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |
| `memberId` | String | N | 회원 식별자 |
| `applicantId` | Long | N | 참여자 식별자 |
| `entryId` | Long | N | 응모 식별자 |
| `isWinner` | Boolean | N | 당첨 여부 |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ENTRY_LIST_OK",
  "message": "응모자 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "content": [
      {
        "entryId": 200,
        "applicantId": 100,
        "memberId": "dolsoi_user_001",
        "appliedAt": "2026-03-09T08:00:00Z",
        "isWinner": false
      }
    ],
    "totalElements": 100,
    "totalPages": 5
  }
}
```

---

### 34. 응모자 수정

- **접근 권한**: 운영자
- **기능 설명**: 응모 이력 수정 (오기입 정정용)
- **메소드**: `PUT`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries/{entryId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{ "memo": "수정 사유" }
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ENTRY_UPDATED",
  "message": "응모자 정보가 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 35. 응모자 삭제

- **접근 권한**: 운영자
- **기능 설명**: 응모 이력 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries/{entryId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

---

### 40. 응모자 상태 변경

- **접근 권한**: 운영자
- **기능 설명**: 응모 이력 특정 상태 필드만 변경
- **메소드**: `PATCH`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/entries/{entryId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |
| `entryId` | Long | Y | 응모 식별자 (Path) |

**Request Body**
```json
{
  "isWinner": true
}
```

> 변경할 필드만 포함하여 전송.

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "ENTRY_STATUS_UPDATED",
  "message": "응모자 상태가 변경되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 당첨자 (event_win)

---

### 41. 추첨 실행

- **접근 권한**: 운영자
- **기능 설명**: 회차 추첨 실행. 응모자 중 당첨자를 선정하여 `event_win`에 결과를 저장
- **메소드**: `POST`
- **URL**: `/api/v1/rounds/{roundId}/draws`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path) |
| `roundId` | Long | Y | 회차 식별자 (Path) |

**Request Body**: 없음

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "DRAW_EXECUTED",
  "message": "추첨이 완료되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "roundId": 1,
    "totalWinnerCount": 10,
    "drawnAt": "2026-03-09T10:00:00Z"
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |
| 409 | `PRZ_OUT_OF_STOCK` | 경품 재고가 소진되었습니다. |

---

### 42. 당첨자 수기 등록

- **접근 권한**: 운영자
- **기능 설명**: 당첨자 수기 등록
- **메소드**: `POST`
- **URL**: `/api/v1/wins`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "entryId": 200,
  "prizeId": 10,
  "memo": "수기 당첨 등록 사유"
}
```

**Response Header**: `HTTP/1.1 201 Created`

**Response Body**
```json
{
  "code": "WIN_CREATED",
  "message": "당첨자가 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": { "winId": 1 }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `WIN_ALREADY_CLAIMED` | 이미 당첨 보상을 수령하였습니다. |
| 409 | `PRZ_OUT_OF_STOCK` | 경품 재고가 소진되었습니다. |

---

### 37. 당첨자 조회 / 검색

- **접근 권한**: 운영자
- **기능 설명**: 당첨자 목록 조회 및 검색
- **메소드**: `GET`
- **URL**: `/api/v1/wins`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | N | 이벤트 식별자 (Query) |
| `roundId` | Long | N | 회차 식별자 (Query) |
| `memberId` | String | N | 회원 식별자 |
| `applicantId` | Long | N | 참여자 식별자 |
| `entryId` | Long | N | 응모 식별자 |
| `winId` | Long | N | 당첨 식별자 |
| `winAtFrom` | String | N | 당첨일 범위 시작 (ISO 8601) |
| `winAtTo` | String | N | 당첨일 범위 종료 (ISO 8601) |
| `prizeId` | Long | N | 경품 식별자 |
| `rewardType` | String | N | 경품 타입 (`POINT`, `COUPON`, `PRODUCT`, `ETC`) |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "WIN_LIST_OK",
  "message": "당첨자 목록을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "content": [
      {
        "winId": 1,
        "memberId": "dolsoi_user_001",
        "roundNo": 1,
        "prizeId": 10,
        "prizeName": "스타벅스 아메리카노",
        "rewardType": "COUPON",
        "createdAt": "2026-03-08T10:00:00Z"
      }
    ],
    "totalElements": 10,
    "totalPages": 1
  }
}
```

---

### 38. 당첨자 수정

- **접근 권한**: 운영자
- **기능 설명**: 당첨 정보 수정 (오기입 정정용)
- **메소드**: `PUT`
- **URL**: `/api/v1/wins/{winId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request Body**
```json
{
  "prizeId": 11,
  "memo": "경품 변경 사유"
}
```

**Response Header**: `HTTP/1.1 200 OK`

**Response Body**
```json
{
  "code": "WIN_UPDATED",
  "message": "당첨자 정보가 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `WIN_NOT_FOUND` | 당첨 정보를 찾을 수 없습니다. |

---

### 39. 당첨자 삭제

- **접근 권한**: 운영자
- **기능 설명**: 당첨자 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/wins/{winId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Response Header**: `HTTP/1.1 204 No Content`

**Response Body**: 없음

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `WIN_NOT_FOUND` | 당첨 정보를 찾을 수 없습니다. |
