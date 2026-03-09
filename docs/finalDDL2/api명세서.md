# API 명세서

> BaseResponse 구조: `{ code, message, timestamp, data }`

---

## 인증 방식 정리

| 구분 | 호출 주체 | 인증 방식 |
|------|----------|----------|
| **외부 연동 API** | 돌쇠네 쇼핑몰 서버 | API Key (`X-Api-Key` 헤더) |
| **어드민 API** | 돌쇠네 쇼핑몰 운영자 | Admin JWT (`Authorization: Bearer {adminToken}`) |

> 이벤트 플랫폼은 회원이 없음.
> 돌쇠네 쇼핑몰 회원을 사용할 예정.
> 돌쇠네 쇼핑몰이 자체 회원의 `memberId`를 서버 간 통신으로 전달하며, 이벤트 시스템은 이 값을 **검증 없이 식별자로 사용**.

---

## 📋 목차

### 🔗 사용자 API (외부 연동 - 돌쇠네 서버 → 이벤트 서버)
1. [이벤트 참여](#1-이벤트-참여)
2. [참여 여부 조회](#2-참여-여부-조회)
3. [당첨 내역 조회](#3-당첨-내역-조회)

### 🔧 관리자 API

**이벤트**
4. [이벤트 생성](#4-이벤트-생성)
5. [이벤트 목록 조회](#5-이벤트-목록-조회)
6. [이벤트 상세 조회](#6-이벤트-상세-조회)
7. [이벤트 수정](#7-이벤트-수정)
8. [이벤트 삭제](#8-이벤트-삭제)

**회차**
9. [회차 생성](#9-회차-생성)
10. [회차 목록 조회](#10-회차-목록-조회)
11. [회차 상세 조회](#11-회차-상세-조회)
12. [회차 수정](#12-회차-수정)
13. [회차 삭제](#13-회차-삭제)

**경품**
14. [경품 생성](#14-경품-생성)
15. [경품 목록 조회](#15-경품-목록-조회)
16. [경품 상세 조회](#16-경품-상세-조회)
17. [경품 수정](#17-경품-수정)
18. [경품 삭제](#18-경품-삭제)

**회차별 경품 설정**
19. [회차별 경품 설정 등록](#19-회차별-경품-설정-등록)
20. [회차별 경품 설정 조회](#20-회차별-경품-설정-조회)
21. [회차별 경품 설정 수정](#21-회차별-경품-설정-수정)
22. [회차별 경품 설정 삭제](#22-회차별-경품-설정-삭제)

**확률**
23. [확률 설정 등록](#23-확률-설정-등록)
24. [확률 설정 조회](#24-확률-설정-조회)
25. [확률 설정 수정](#25-확률-설정-수정)
26. [확률 설정 삭제](#26-확률-설정-삭제)

**참여자**
27. [참여자 수기 등록](#27-참여자-수기-등록)
28. [참여자 조회 / 검색](#28-참여자-조회--검색)
29. [참여자 수정](#29-참여자-수정)
30. [참여자 삭제](#30-참여자-삭제)

**당첨자**
31. [당첨자 수기 등록](#31-당첨자-수기-등록)
32. [당첨자 조회 / 검색](#32-당첨자-조회--검색)
33. [당첨자 수정](#33-당첨자-수정)
34. [당첨자 삭제](#34-당첨자-삭제)

---

## 🔗 사용자 API

---

### 1. 이벤트 참여

- **접근 권한**: 외부 연동 (돌쇠네 서버)
- **기능 설명**: 돌쇠네 회원이 이벤트 회차에 응모 (출석체크 참여)
- **메소드**: `POST`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/apply`

**Request Header**
```
X-Api-Key: {apiKey}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**
```json
{
  "memberId": "dolsoi_user_001"
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ENTY_APPLIED",
  "message": "응모가 완료되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "applicantId": 100,
    "entryId": 200,
    "appliedAt": "2026-03-09T08:00:00Z"
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |
| 403 | `EVT_NOT_ACTIVE` | 현재 진행 중인 이벤트가 아닙니다. |
| 403 | `EVT_EXPIRED` | 종료된 이벤트입니다. |
| 403 | `ENTY_NOT_ALLOWED` | 참여가 허용되지 않습니다. |
| 409 | `ENTY_ALREADY_ENTERED` | 이미 참여하였습니다. |
| 409 | `ENTY_LIMIT_EXCEEDED` | 참여 가능 횟수를 초과했습니다. |
| 400 | `ENTY_INVALID_CONDITION` | 참여 조건이 유효하지 않습니다. |

---

### 2. 참여 여부 조회

- **접근 권한**: 외부 연동 (돌쇠네 서버)
- **기능 설명**: 돌쇠네 회원의 현재 회차 참여 여부 확인
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/rounds/{roundId}/apply/status`

**Request Header**
```
X-Api-Key: {apiKey}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `memberId` | String | Y | 외부 회원 식별자 (Query String) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ENTY_STATUS_OK",
  "message": "참여 상태를 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "isApplied": true,
    "appliedAt": "2026-03-09T08:00:00Z",
    "entryCount": 1
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 3. 당첨 내역 조회

- **접근 권한**: 외부 연동 (돌쇠네 서버)
- **기능 설명**: 돌쇠네 회원의 이벤트 당첨 내역 조회
- **메소드**: `GET`
- **URL**: `/api/v1/events/{eventId}/wins`

**Request Header**
```
X-Api-Key: {apiKey}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `memberId` | String | Y | 외부 회원 식별자 (Query String) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `WIN_NOT_FOUND` | 당첨 정보를 찾을 수 없습니다. |

---

## 🔧 관리자 API

---

## 이벤트

---

### 4. 이벤트 생성

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 새 이벤트 생성
- **메소드**: `POST`
- **URL**: `/api/v1/admin/events`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**: 없음

**Request Body**
```json
{
  "eventName": "3월 출석체크 이벤트",
  "eventType": "ATTENDANCE",
  "startAt": "2026-03-01T00:00:00Z",
  "endAt": "2026-03-31T23:59:59Z",
  "supplierId": 1,
  "eventUrl": "https://...",
  "winnerSelectionCycle": 168,
  "priority": 1,
  "isAutoEntry": false,
  "isSnsLinked": false,
  "isDuplicateWinner": false,
  "isMultipleEntry": false,
  "description": "매일 출석하고 경품을 받으세요!"
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "EVT_CREATED",
  "message": "이벤트가 생성되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "eventId": 1
  }
}
```

---

### 5. 이벤트 목록 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 목록 조회. 이름 / 이벤트 번호 / 기간 검색 지원
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventName` | String | N | 이벤트명 검색 (부분일치) |
| `eventId` | Long | N | 이벤트 번호 검색 |
| `startAtFrom` | String | N | 이벤트 시작일 범위 시작 (ISO 8601) |
| `startAtTo` | String | N | 이벤트 시작일 범위 종료 (ISO 8601) |
| `isActive` | Boolean | N | 활성 여부 필터 |
| `eventType` | String | N | 이벤트 유형 필터 (`ATTENDANCE`, `RANDOM_REWARD`) |
| `page` | Integer | N | 페이지 번호 (기본값: 0) |
| `size` | Integer | N | 페이지 사이즈 (기본값: 20) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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
        "isVisible": true
      }
    ],
    "totalElements": 1,
    "totalPages": 1
  }
}
```

---

### 6. 이벤트 상세 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 단건 상세 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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
    "description": "매일 출석하고 경품을 받으세요!"
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 7. 이벤트 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |

**Request Body**
```json
{
  "eventName": "3월 출석체크 이벤트 (수정)",
  "startAt": "2026-03-01T00:00:00Z",
  "endAt": "2026-03-31T23:59:59Z",
  "isActive": true,
  "isVisible": true,
  "isWinnerAnnounced": false,
  "priority": 0,
  "description": "수정된 설명"
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 8. 이벤트 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/events/{eventId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "EVT_DELETED",
  "message": "이벤트가 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

## 회차

---

### 9. 회차 생성

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트에 회차 생성
- **메소드**: `POST`
- **URL**: `/api/v1/admin/events/{eventId}/rounds`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |

**Request Body**
```json
{
  "roundNo": 1,
  "roundStartAt": "2026-03-01T00:00:00Z",
  "roundEndAt": "2026-03-07T23:59:59Z",
  "drawAt": "2026-03-08T10:00:00Z"
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_CREATED",
  "message": "회차가 생성되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "roundId": 1
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 10. 회차 목록 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트에 속한 회차 목록 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events/{eventId}/rounds`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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
      "roundEndAt": "2026-03-07T23:59:59Z",
      "drawAt": "2026-03-08T10:00:00Z",
      "isConfirmed": false
    }
  ]
}
```

---

### 11. 회차 상세 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차 단건 상세 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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
    "roundEndAt": "2026-03-07T23:59:59Z",
    "drawAt": "2026-03-08T10:00:00Z",
    "isConfirmed": false,
    "isDeleted": false
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `EVT_NOT_FOUND` | 이벤트를 찾을 수 없습니다. |

---

### 12. 회차 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**
```json
{
  "roundStartAt": "2026-03-01T00:00:00Z",
  "roundEndAt": "2026-03-07T23:59:59Z",
  "drawAt": "2026-03-08T12:00:00Z",
  "isConfirmed": true
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 13. 회차 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_DELETED",
  "message": "회차가 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 경품

---

### 14. 경품 생성

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 경품 마스터 등록
- **메소드**: `POST`
- **URL**: `/api/v1/admin/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**: 없음

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

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "PRZ_CREATED",
  "message": "경품이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "prizeId": 10
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `PRZ_INVALID_STATE` | 경품 상태가 유효하지 않습니다. |

---

### 15. 경품 목록 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 경품 목록 조회. 경품명 / 경품 타입 / 경품 상태 검색 지원
- **메소드**: `GET`
- **URL**: `/api/v1/admin/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeName` | String | N | 경품명 검색 (부분일치) |
| `rewardType` | String | N | 경품 타입 (`POINT`, `COUPON`, `PRODUCT`, `ETC`) |
| `isActive` | Boolean | N | 경품 상태 (활성 여부) |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 16. 경품 상세 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 경품 단건 상세 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeId` | Long | Y | 경품 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 17. 경품 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 경품 정보 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeId` | Long | Y | 경품 식별자 (Path Variable) |

**Request Body**
```json
{
  "prizeName": "스타벅스 라떼",
  "prizeDescription": "변경된 설명",
  "isActive": false
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 18. 경품 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 경품 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/prizes/{prizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `prizeId` | Long | Y | 경품 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "PRZ_DELETED",
  "message": "경품이 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |

---

## 회차별 경품 설정

---

### 19. 회차별 경품 설정 등록

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 특정 회차에 경품 정책 등록 (`event_round_prize`)
- **메소드**: `POST`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**
```json
{
  "prizeId": 10,
  "priority": 1,
  "dailyLimit": 100,
  "totalLimit": 500,
  "isActive": true
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_PRIZE_CREATED",
  "message": "회차 경품 설정이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "roundPrizeId": 5
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `PRZ_NOT_FOUND` | 경품을 찾을 수 없습니다. |
| 409 | `PRZ_OUT_OF_STOCK` | 경품 재고가 소진되었습니다. |

---

### 20. 회차별 경품 설정 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 특정 회차의 경품 정책 목록 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_PRIZE_LIST_OK",
  "message": "회차 경품 설정을 조회했습니다.",
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

### 21. 회차별 경품 설정 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차 경품 정책 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |

**Request Body**
```json
{
  "dailyLimit": 50,
  "totalLimit": 200,
  "priority": 2,
  "isActive": false
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_PRIZE_UPDATED",
  "message": "회차 경품 설정이 수정되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

### 22. 회차별 경품 설정 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차 경품 정책 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "ROUND_PRIZE_DELETED",
  "message": "회차 경품 설정이 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 확률

---

### 23. 확률 설정 등록

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차-경품 확률 정책 등록 (`event_round_prize_probability`)
- **메소드**: `POST`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |

**Request Body**
```json
{
  "probability": 10.00,
  "weight": 1,
  "isActive": true
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "PROB_CREATED",
  "message": "확률 설정이 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "probabilityId": 3
  }
}
```

---

### 24. 확률 설정 조회

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차-경품 확률 정책 조회
- **메소드**: `GET`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "PROB_LIST_OK",
  "message": "확률 설정을 조회했습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": [
    {
      "probabilityId": 3,
      "probability": 10.00,
      "weight": 1,
      "isActive": true
    }
  ]
}
```

---

### 25. 확률 설정 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차-경품 확률 수정
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |
| `probabilityId` | Long | Y | 확률 식별자 (Path Variable) |

**Request Body**
```json
{
  "probability": 5.00,
  "weight": 2,
  "isActive": true
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 26. 확률 설정 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 회차-경품 확률 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `roundPrizeId` | Long | Y | 회차경품 식별자 (Path Variable) |
| `probabilityId` | Long | Y | 확률 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "PROB_DELETED",
  "message": "확률 설정이 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 참여자

---

### 27. 참여자 수기 등록

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 회차에 참여자 수기 등록 (`event_applicant` + `event_entry`)
- **메소드**: `POST`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/applicants`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**
```json
{
  "memberId": "dolsoi_user_001",
  "memo": "수기 등록 사유"
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "APPL_CREATED",
  "message": "참여자가 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "applicantId": 100,
    "entryId": 200
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `ENTY_ALREADY_ENTERED` | 이미 참여하였습니다. |

---

### 28. 참여자 조회 / 검색

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 회차 참여자 목록 조회 및 검색
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/applicants`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `memberId` | String | N | 외부 회원 ID 검색 |
| `isWinner` | Boolean | N | 당첨 여부 필터 |
| `prizeName` | String | N | 경품명 검색 |
| `rewardType` | String | N | 경품 타입 필터 |
| `appliedAtFrom` | String | N | 응모일 범위 시작 |
| `appliedAtTo` | String | N | 응모일 범위 종료 |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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
        "entryId": 200,
        "memberId": "dolsoi_user_001",
        "appliedAt": "2026-03-09T08:00:00Z",
        "isWinner": true,
        "prizeName": "스타벅스 아메리카노",
        "rewardType": "COUPON"
      }
    ],
    "totalElements": 50,
    "totalPages": 3
  }
}
```

---

### 29. 참여자 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 참여자 정보 수정 (수기 데이터 오류 정정용)
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/applicants/{applicantId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `applicantId` | Long | Y | 참여자 식별자 (Path Variable) |

**Request Body**
```json
{
  "memberId": "dolsoi_user_002",
  "memo": "회원 ID 오기입 수정"
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 30. 참여자 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 참여자 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/applicants/{applicantId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `applicantId` | Long | Y | 참여자 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "APPL_DELETED",
  "message": "참여자가 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

---

## 당첨자

---

### 31. 당첨자 수기 등록

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 회차 당첨자 수기 등록 (`event_win`)
- **메소드**: `POST`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/wins`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |

**Request Body**
```json
{
  "entryId": 200,
  "eventRoundPrizeId": 5,
  "memo": "수기 당첨 등록 사유"
}
```

**Response Header**
```
HTTP/1.1 201 Created
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "WIN_CREATED",
  "message": "당첨자가 등록되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": {
    "winId": 1
  }
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 409 | `WIN_ALREADY_CLAIMED` | 이미 당첨 보상을 수령하였습니다. |
| 409 | `PRZ_OUT_OF_STOCK` | 경품 재고가 소진되었습니다. |

---

### 32. 당첨자 조회 / 검색

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 이벤트 회차 당첨자 목록 조회 및 검색
- **메소드**: `GET`
- **URL**: `/api/v1/admin/events/{eventId}/wins`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | N | 회차 필터 |
| `memberId` | String | N | 외부 회원 ID 검색 |
| `prizeName` | String | N | 경품명 검색 |
| `rewardType` | String | N | 경품 타입 필터 (`POINT`, `COUPON`, `PRODUCT`, `ETC`) |
| `winAtFrom` | String | N | 당첨일 범위 시작 |
| `winAtTo` | String | N | 당첨일 범위 종료 |
| `page` | Integer | N | 페이지 번호 |
| `size` | Integer | N | 페이지 사이즈 |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 33. 당첨자 수정

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 당첨자 정보 수정 (수기 오류 정정용)
- **메소드**: `PUT`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/wins/{winId}`

**Request Header**
```
Authorization: Bearer {adminToken}
Content-Type: application/json
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `winId` | Long | Y | 당첨 식별자 (Path Variable) |

**Request Body**
```json
{
  "eventRoundPrizeId": 6,
  "memo": "경품 변경 사유"
}
```

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

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

### 34. 당첨자 삭제

- **접근 권한**: 운영자 (admin)
- **기능 설명**: 당첨자 논리 삭제
- **메소드**: `DELETE`
- **URL**: `/api/v1/admin/events/{eventId}/rounds/{roundId}/wins/{winId}`

**Request Header**
```
Authorization: Bearer {adminToken}
```

**Request 파라미터**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `eventId` | Long | Y | 이벤트 식별자 (Path Variable) |
| `roundId` | Long | Y | 회차 식별자 (Path Variable) |
| `winId` | Long | Y | 당첨 식별자 (Path Variable) |

**Request Body**: 없음

**Response Header**
```
HTTP/1.1 200 OK
Content-Type: application/json
```

**Response Body**
```json
{
  "code": "WIN_DELETED",
  "message": "당첨자가 삭제되었습니다.",
  "timestamp": "2026-03-09T08:00:00Z",
  "data": null
}
```

**Error Response**
| HTTP Status | code | message |
|-------------|------|---------|
| 404 | `WIN_NOT_FOUND` | 당첨 정보를 찾을 수 없습니다. |
