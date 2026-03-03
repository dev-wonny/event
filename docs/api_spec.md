# Event Platform API 명세서

> Base URL: `/api/v1`  
> 모든 요청/응답 Content-Type: `application/json`  
> 인증: Bearer Token (JWT)

---

## 목차

1. [경품(Prize) API](#1-경품prize-api)
2. [이벤트(Event) API](#2-이벤트event-api)
3. [파일(Event File) API](#3-파일event-file-api)
4. [이벤트 회차(Event Round) API](#4-이벤트-회차event-round-api)
5. [회차별 경품 정책(Event Round Prize) API](#5-회차별-경품-정책event-round-prize-api)
6. [경품 당첨 확률(Event Round Prize Probability) API](#6-경품-당첨-확률event-round-prize-probability-api)
7. [이벤트 참여자(Event Applicant) API](#7-이벤트-참여자event-applicant-api)
8. [이벤트 응모(Event Entry) API](#8-이벤트-응모event-entry-api)
9. [당첨 결과(Event Win) API](#9-당첨-결과event-win-api)
10. [이벤트 전시 에셋(Event Display Asset) API](#10-이벤트-전시-에셋event-display-asset-api)

---

## 1. 경품(Prize) API

> 기능: 이벤트와 독립적으로 재사용 가능한 경품 마스터 데이터를 관리합니다.

---

### 1-1. 경품 목록 조회

- **Method**: `GET`
- **URL**: `/prizes`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| page | Integer | N | 페이지 번호 (기본값: 0) |
| size | Integer | N | 페이지 크기 (기본값: 20) |
| rewardType | String | N | 보상 유형 필터 (POINT, COUPON, PRODUCT, ETC) |
| isActive | Boolean | N | 활성 여부 필터 |

**Response Header**

| 헤더명 | 설명 |
|---|---|
| Content-Type | `application/json` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1,
        "prizeName": "스타벅스 아메리카노",
        "rewardType": "COUPON",
        "pointAmount": null,
        "externalRefId": "COUPON-001",
        "prizeDescription": "스타벅스 아메리카노 쿠폰",
        "isActive": true,
        "createdAt": "2026-03-03T10:00:00+09:00",
        "updatedAt": "2026-03-03T10:00:00+09:00"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 100,
    "totalPages": 5
  }
}
```

---

### 1-2. 경품 단건 조회

- **Method**: `GET`
- **URL**: `/prizes/{prizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "prizeName": "스타벅스 아메리카노",
    "rewardType": "COUPON",
    "pointAmount": null,
    "externalRefId": "COUPON-001",
    "prizeDescription": "스타벅스 아메리카노 쿠폰",
    "isActive": true,
    "createdAt": "2026-03-03T10:00:00+09:00",
    "updatedAt": "2026-03-03T10:00:00+09:00"
  }
}
```

---

### 1-3. 경품 등록

- **Method**: `POST`
- **URL**: `/prizes`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "prizeName": "스타벅스 아메리카노",
  "rewardType": "COUPON",
  "pointAmount": null,
  "externalRefId": "COUPON-001",
  "prizeDescription": "스타벅스 아메리카노 쿠폰",
  "isActive": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| prizeName | String | Y | 경품명 (최대 100자) |
| rewardType | String | Y | 보상 유형 (POINT, COUPON, PRODUCT, ETC) |
| pointAmount | Integer | N | 포인트 지급액 (rewardType=POINT 시 사용) |
| externalRefId | String | N | 외부 연동 참조 ID |
| prizeDescription | String | N | 경품 설명 |
| isActive | Boolean | N | 활성 여부 (기본값: true) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "prizeName": "스타벅스 아메리카노",
    "rewardType": "COUPON",
    "pointAmount": null,
    "externalRefId": "COUPON-001",
    "prizeDescription": "스타벅스 아메리카노 쿠폰",
    "isActive": true,
    "createdAt": "2026-03-03T10:00:00+09:00"
  }
}
```

---

### 1-4. 경품 수정

- **Method**: `PATCH`
- **URL**: `/prizes/{prizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "prizeName": "스타벅스 라떼",
  "rewardType": "COUPON",
  "pointAmount": null,
  "externalRefId": "COUPON-002",
  "prizeDescription": "스타벅스 라떼 쿠폰",
  "isActive": true
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "prizeName": "스타벅스 라떼",
    "rewardType": "COUPON",
    "pointAmount": null,
    "externalRefId": "COUPON-002",
    "prizeDescription": "스타벅스 라떼 쿠폰",
    "isActive": true,
    "updatedAt": "2026-03-03T11:00:00+09:00"
  }
}
```

---

### 1-5. 경품 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/prizes/{prizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 2. 이벤트(Event) API

> 기능: 이벤트 기본 정보 및 운영 정책을 관리합니다. (이벤트 유형: ATTENDANCE, RANDOM_REWARD)

---

### 2-1. 이벤트 목록 조회

- **Method**: `GET`
- **URL**: `/events`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| page | Integer | N | 페이지 번호 (기본값: 0) |
| size | Integer | N | 페이지 크기 (기본값: 20) |
| eventType | String | N | 이벤트 유형 (ATTENDANCE, RANDOM_REWARD) |
| isActive | Boolean | N | 활성 여부 |
| isVisible | Boolean | N | 전시 여부 |
| supplierId | Long | N | 공급사 ID |

**Response Body**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1,
        "eventName": "봄맞이 출석 이벤트",
        "eventType": "ATTENDANCE",
        "startAt": "2026-03-01T00:00:00+09:00",
        "endAt": "2026-03-31T23:59:59+09:00",
        "isActive": true,
        "isVisible": true,
        "isConfirmed": true,
        "isWinnerAnnounced": false,
        "priority": 0,
        "supplierId": 100,
        "createdAt": "2026-02-20T10:00:00+09:00"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 50,
    "totalPages": 3
  }
}
```

---

### 2-2. 이벤트 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventName": "봄맞이 출석 이벤트",
    "eventType": "ATTENDANCE",
    "startAt": "2026-03-01T00:00:00+09:00",
    "endAt": "2026-03-31T23:59:59+09:00",
    "isActive": true,
    "isVisible": true,
    "isAutoEntry": false,
    "isConfirmed": true,
    "isSnsLinked": false,
    "eventUrl": "https://example.com/event/1",
    "description": "봄맞이 출석 이벤트 상세 설명",
    "supplierId": 100,
    "isWinnerAnnounced": false,
    "winnerAnnouncedAt": null,
    "allowDuplicateWinner": false,
    "allowMultipleEntry": false,
    "winnerSelectionCycle": null,
    "winnerSelectionBaseAt": null,
    "priority": 0,
    "createdAt": "2026-02-20T10:00:00+09:00",
    "updatedAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 2-3. 이벤트 등록

- **Method**: `POST`
- **URL**: `/events`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "eventName": "봄맞이 출석 이벤트",
  "eventType": "ATTENDANCE",
  "startAt": "2026-03-01T00:00:00+09:00",
  "endAt": "2026-03-31T23:59:59+09:00",
  "isActive": false,
  "isVisible": false,
  "isAutoEntry": false,
  "isSnsLinked": false,
  "eventUrl": "https://example.com/event/1",
  "description": "봄맞이 출석 이벤트 상세 설명",
  "supplierId": 100,
  "allowDuplicateWinner": false,
  "allowMultipleEntry": false,
  "winnerSelectionCycle": null,
  "winnerSelectionBaseAt": null,
  "priority": 0
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| eventName | String | Y | 이벤트명 (최대 100자) |
| eventType | String | Y | 이벤트 유형 (ATTENDANCE, RANDOM_REWARD) |
| startAt | String | Y | 이벤트 시작 일시 (ISO 8601) |
| endAt | String | Y | 이벤트 종료 일시 (ISO 8601) |
| isActive | Boolean | N | 활성 여부 (기본값: false) |
| isVisible | Boolean | N | 전시 여부 (기본값: false) |
| isAutoEntry | Boolean | N | 자동 응모 여부 (기본값: false) |
| isSnsLinked | Boolean | N | SNS 공유 연동 여부 (기본값: false) |
| eventUrl | String | N | 이벤트 URL (최대 300자) |
| description | String | N | 이벤트 상세 설명 |
| supplierId | Long | Y | 공급사 식별자 |
| allowDuplicateWinner | Boolean | N | 당첨자 중복 허용 (기본값: false) |
| allowMultipleEntry | Boolean | N | 복수 응모 허용 (기본값: false) |
| winnerSelectionCycle | Integer | N | 당첨자 선정 주기 (단위: 시간) |
| winnerSelectionBaseAt | String | N | 당첨자 선정 기준 일시 |
| priority | Integer | N | 전시 우선순위 (기본값: 0) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventName": "봄맞이 출석 이벤트",
    "eventType": "ATTENDANCE",
    "startAt": "2026-03-01T00:00:00+09:00",
    "endAt": "2026-03-31T23:59:59+09:00",
    "isActive": false,
    "isConfirmed": false,
    "createdAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 2-4. 이벤트 수정

- **Method**: `PATCH`
- **URL**: `/events/{eventId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "eventName": "봄맞이 출석 이벤트 (수정)",
  "isActive": true,
  "isVisible": true,
  "priority": 1
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventName": "봄맞이 출석 이벤트 (수정)",
    "isActive": true,
    "isVisible": true,
    "priority": 1,
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 2-5. 이벤트 승인

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/confirm`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "isConfirmed": true,
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 2-6. 당첨자 발표

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/announce-winner`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "isWinnerAnnounced": true,
    "winnerAnnouncedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 2-7. 이벤트 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 3. 파일(Event File) API

> 기능: S3 업로드 파일의 메타데이터를 저장하고 관리합니다. CDN URL은 서버에서 조합하여 반환합니다.

---

### 3-1. 파일 업로드 (Presigned URL 발급)

- **Method**: `POST`
- **URL**: `/event-files/presigned-url`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "originalFileName": "banner.png",
  "mimeType": "image/png",
  "fileSize": 204800,
  "fileExtension": "png",
  "isPublic": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| originalFileName | String | Y | 원본 파일명 (최대 200자) |
| mimeType | String | Y | MIME 타입 (최대 100자) |
| fileSize | Long | Y | 파일 크기 (bytes) |
| fileExtension | String | Y | 파일 확장자 소문자 (최대 10자) |
| isPublic | Boolean | N | CDN 공개 여부 (기본값: true) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "fileId": 1,
    "objectKey": "event/2026/03/uuid.png",
    "presignedUrl": "https://s3.ap-northeast-2.amazonaws.com/bucket/event/2026/03/uuid.png?...",
    "expiresIn": 3600
  }
}
```

---

### 3-2. 파일 메타데이터 등록 (업로드 완료 후 호출)

- **Method**: `POST`
- **URL**: `/event-files`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "objectKey": "event/2026/03/uuid.png",
  "originalFileName": "banner.png",
  "fileSize": 204800,
  "mimeType": "image/png",
  "fileExtension": "png",
  "checksumSha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "width": 1920,
  "height": 1080,
  "isPublic": true
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "objectKey": "event/2026/03/uuid.png",
    "originalFileName": "banner.png",
    "fileSize": 204800,
    "mimeType": "image/png",
    "fileExtension": "png",
    "width": 1920,
    "height": 1080,
    "isPublic": true,
    "cdnUrl": "https://cdn.example.com/event/2026/03/uuid.png",
    "createdAt": "2026-03-03T10:00:00+09:00"
  }
}
```

---

### 3-3. 파일 단건 조회

- **Method**: `GET`
- **URL**: `/event-files/{fileId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "objectKey": "event/2026/03/uuid.png",
    "originalFileName": "banner.png",
    "fileSize": 204800,
    "mimeType": "image/png",
    "fileExtension": "png",
    "checksumSha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "width": 1920,
    "height": 1080,
    "isPublic": true,
    "cdnUrl": "https://cdn.example.com/event/2026/03/uuid.png",
    "createdAt": "2026-03-03T10:00:00+09:00"
  }
}
```

---

### 3-4. 파일 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/event-files/{fileId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 4. 이벤트 회차(Event Round) API

> 기능: 이벤트 추첨 회차를 관리합니다. 하나의 이벤트에 N개의 회차가 존재할 수 있습니다.

---

### 4-1. 이벤트별 회차 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/rounds`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "eventId": 1,
      "roundNo": 1,
      "isConfirmed": false,
      "drawAt": null,
      "drawStartAt": "2026-03-01T00:00:00+09:00",
      "drawEndAt": "2026-03-10T23:59:59+09:00",
      "createdAt": "2026-02-20T10:00:00+09:00"
    }
  ]
}
```

---

### 4-2. 회차 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/rounds/{roundId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "roundNo": 1,
    "isConfirmed": false,
    "drawAt": null,
    "drawStartAt": "2026-03-01T00:00:00+09:00",
    "drawEndAt": "2026-03-10T23:59:59+09:00",
    "createdAt": "2026-02-20T10:00:00+09:00",
    "updatedAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 4-3. 회차 등록

- **Method**: `POST`
- **URL**: `/events/{eventId}/rounds`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "roundNo": 1,
  "drawStartAt": "2026-03-01T00:00:00+09:00",
  "drawEndAt": "2026-03-10T23:59:59+09:00"
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundNo | Integer | Y | 추첨 회차 번호 (1부터 시작) |
| drawStartAt | String | N | 추첨 대상 기간 시작 일시 |
| drawEndAt | String | N | 추첨 대상 기간 종료 일시 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "roundNo": 1,
    "isConfirmed": false,
    "drawStartAt": "2026-03-01T00:00:00+09:00",
    "drawEndAt": "2026-03-10T23:59:59+09:00",
    "createdAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 4-4. 회차 수정

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/rounds/{roundId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "drawStartAt": "2026-03-02T00:00:00+09:00",
  "drawEndAt": "2026-03-11T23:59:59+09:00"
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "drawStartAt": "2026-03-02T00:00:00+09:00",
    "drawEndAt": "2026-03-11T23:59:59+09:00",
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 4-5. 회차 추첨 실행

- **Method**: `POST`
- **URL**: `/events/{eventId}/rounds/{roundId}/draw`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "drawAt": "2026-03-03T12:00:00+09:00",
    "isConfirmed": true,
    "winnerCount": 10
  }
}
```

---

### 4-6. 회차 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/rounds/{roundId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 5. 회차별 경품 정책(Event Round Prize) API

> 기능: 이벤트 회차별 경품 배정 및 지급 한도 정책을 관리합니다.

---

### 5-1. 회차별 경품 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "roundId": 1,
      "prizeId": 1,
      "prizeName": "스타벅스 아메리카노",
      "dailyLimit": 100,
      "totalLimit": 1000,
      "priority": 0,
      "isActive": true,
      "createdAt": "2026-02-20T10:00:00+09:00"
    }
  ]
}
```

---

### 5-2. 회차 경품 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "roundId": 1,
    "prizeId": 1,
    "prizeName": "스타벅스 아메리카노",
    "dailyLimit": 100,
    "totalLimit": 1000,
    "priority": 0,
    "isActive": true,
    "createdAt": "2026-02-20T10:00:00+09:00",
    "updatedAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 5-3. 회차 경품 등록

- **Method**: `POST`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "prizeId": 1,
  "dailyLimit": 100,
  "totalLimit": 1000,
  "priority": 0,
  "isActive": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| prizeId | Long | Y | 경품 식별자 |
| dailyLimit | Integer | N | 일별 지급 상한 (null=무제한) |
| totalLimit | Integer | N | 총 지급 상한 (null=무제한) |
| priority | Integer | N | 경품 적용 우선순위 (기본값: 0, 낮을수록 우선) |
| isActive | Boolean | N | 경품 정책 활성 여부 (기본값: true) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "roundId": 1,
    "prizeId": 1,
    "dailyLimit": 100,
    "totalLimit": 1000,
    "priority": 0,
    "isActive": true,
    "createdAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 5-4. 회차 경품 수정

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "dailyLimit": 50,
  "totalLimit": 500,
  "priority": 1,
  "isActive": false
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "dailyLimit": 50,
    "totalLimit": 500,
    "priority": 1,
    "isActive": false,
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 5-5. 회차 경품 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 6. 경품 당첨 확률(Event Round Prize Probability) API

> 기능: 회차별 경품의 당첨 확률 또는 가중치 정책을 관리합니다. (룰렛/즉시당첨 이벤트 전용)

---

### 6-1. 경품 확률 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "eventRoundPrizeId": 1,
      "probability": 5.000,
      "weight": 10,
      "isActive": true,
      "createdAt": "2026-02-20T10:00:00+09:00"
    }
  ]
}
```

---

### 6-2. 경품 확률 등록

- **Method**: `POST`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}/probabilities`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "probability": 5.000,
  "weight": 10,
  "isActive": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| probability | Decimal | Y | 당첨 확률 (0.000 ~ 100.000 %) |
| weight | Integer | N | 가중치 기반 추첨용 값 |
| isActive | Boolean | N | 확률 정책 사용 여부 (기본값: true) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventRoundPrizeId": 1,
    "probability": 5.000,
    "weight": 10,
    "isActive": true,
    "createdAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 6-3. 경품 확률 수정

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "probability": 3.500,
  "weight": 7,
  "isActive": true
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "probability": 3.500,
    "weight": 7,
    "isActive": true,
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 6-4. 경품 확률 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/rounds/{roundId}/prizes/{roundPrizeId}/probabilities/{probabilityId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 7. 이벤트 참여자(Event Applicant) API

> 기능: 이벤트 참여 자격을 관리합니다. 회차당 1인 1참여가 보장됩니다.

---

### 7-1. 이벤트 참여자 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/applicants`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundId | Long | N | 회차 ID 필터 |
| memberId | Long | N | 회원 ID 필터 |
| page | Integer | N | 페이지 번호 |
| size | Integer | N | 페이지 크기 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1,
        "eventId": 1,
        "roundId": 1,
        "memberId": 1001,
        "createdAt": "2026-03-01T10:00:00+09:00"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 500,
    "totalPages": 25
  }
}
```

---

### 7-2. 참여자 등록 (이벤트 참여 신청)

- **Method**: `POST`
- **URL**: `/events/{eventId}/applicants`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "roundId": 1,
  "memberId": 1001
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundId | Long | Y | 추첨 회차 식별자 |
| memberId | Long | Y | 참여자 회원 식별자 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "roundId": 1,
    "memberId": 1001,
    "createdAt": "2026-03-01T10:00:00+09:00"
  }
}
```

---

### 7-3. 참여자 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/applicants/{applicantId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 8. 이벤트 응모(Event Entry) API

> 기능: 응모 행위 성공 이력을 관리합니다. 복수 응모가 허용된 경우 한 참여자가 여러 응모 기록을 가질 수 있습니다.

---

### 8-1. 이벤트 응모 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/entries`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundId | Long | N | 회차 ID 필터 |
| memberId | Long | N | 회원 ID 필터 |
| isWinner | Boolean | N | 당첨 여부 필터 |
| page | Integer | N | 페이지 번호 |
| size | Integer | N | 페이지 크기 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1,
        "eventId": 1,
        "roundId": 1,
        "memberId": 1001,
        "isWinner": false,
        "appliedAt": "2026-03-01T10:05:00+09:00",
        "createdAt": "2026-03-01T10:05:00+09:00"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 1000,
    "totalPages": 50
  }
}
```

---

### 8-2. 응모 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/entries/{entryId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "roundId": 1,
    "memberId": 1001,
    "isWinner": false,
    "appliedAt": "2026-03-01T10:05:00+09:00",
    "createdAt": "2026-03-01T10:05:00+09:00",
    "updatedAt": "2026-03-01T10:05:00+09:00"
  }
}
```

---

### 8-3. 응모 등록

- **Method**: `POST`
- **URL**: `/events/{eventId}/entries`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "roundId": 1,
  "memberId": 1001,
  "appliedAt": "2026-03-01T10:05:00+09:00"
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundId | Long | Y | 추첨 회차 식별자 |
| memberId | Long | Y | 응모자 회원 식별자 |
| appliedAt | String | N | 응모 액션 발생 일시 (기본값: 현재 시각) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "roundId": 1,
    "memberId": 1001,
    "isWinner": false,
    "appliedAt": "2026-03-01T10:05:00+09:00",
    "createdAt": "2026-03-01T10:05:00+09:00"
  }
}
```

---

### 8-4. 응모 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/entries/{entryId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 9. 당첨 결과(Event Win) API

> 기능: 이벤트 당첨 결과를 관리합니다. 응모 기반 자동 당첨과 관리자 수기 당첨 모두 지원합니다. (entry_id=null이면 수기 당첨)

---

### 9-1. 당첨 결과 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/wins`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| roundId | Long | N | 회차 ID 필터 |
| memberId | Long | N | 회원 ID 필터 |
| page | Integer | N | 페이지 번호 |
| size | Integer | N | 페이지 크기 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "content": [
      {
        "id": 1,
        "entryId": 1,
        "eventId": 1,
        "roundId": 1,
        "eventRoundPrizeId": 1,
        "memberId": 1001,
        "prizeName": "스타벅스 아메리카노",
        "createdAt": "2026-03-10T12:00:00+09:00"
      }
    ],
    "page": 0,
    "size": 20,
    "totalElements": 100,
    "totalPages": 5
  }
}
```

---

### 9-2. 당첨 결과 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/wins/{winId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "entryId": 1,
    "eventId": 1,
    "roundId": 1,
    "eventRoundPrizeId": 1,
    "memberId": 1001,
    "prizeName": "스타벅스 아메리카노",
    "createdAt": "2026-03-10T12:00:00+09:00",
    "updatedAt": "2026-03-10T12:00:00+09:00"
  }
}
```

---

### 9-3. 당첨 결과 수기 등록 (관리자)

- **Method**: `POST`
- **URL**: `/events/{eventId}/wins`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "entryId": null,
  "roundId": 1,
  "eventRoundPrizeId": 1,
  "memberId": 1001
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| entryId | Long | N | 응모 식별자 (null=관리자 수기 당첨) |
| roundId | Long | Y | 추첨 회차 식별자 |
| eventRoundPrizeId | Long | N | 당첨된 경품 식별자 |
| memberId | Long | Y | 당첨자 회원 식별자 |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "entryId": null,
    "eventId": 1,
    "roundId": 1,
    "eventRoundPrizeId": 1,
    "memberId": 1001,
    "createdAt": "2026-03-10T12:00:00+09:00"
  }
}
```

---

### 9-4. 당첨 결과 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/wins/{winId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 10. 이벤트 전시 에셋(Event Display Asset) API

> 기능: 이벤트 UI에 표시되는 이미지 슬롯을 관리합니다. (배경/섹션/버튼/룰렛슬롯/카드 등)
> asset_type 코드: `BACKGROUND_DESKTOP`, `BACKGROUND_MOBILE`, `SECTION_TOP`, `SECTION_MIDDLE`, `SECTION_BOTTOM`, `BUTTON_DEFAULT`, `BUTTON_ACTIVE`, `ROULETTE_SLOT`, `CARD_FRONT`, `CARD_BACK`, `LADDER_BACKGROUND`

---

### 10-1. 이벤트 전시 에셋 목록 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/display-assets`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Request (Query Parameter)**

| 파라미터 | 타입 | 필수 | 설명 |
|---|---|---|---|
| assetType | String | N | 에셋 유형 필터 |
| isActive | Boolean | N | 활성 여부 필터 |

**Response Body**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "eventId": 1,
      "fileId": 1,
      "assetType": "BACKGROUND_DESKTOP",
      "displayWidth": 1920,
      "displayHeight": 1080,
      "sortOrder": 0,
      "isActive": true,
      "cdnUrl": "https://cdn.example.com/event/2026/03/uuid.png",
      "createdAt": "2026-02-20T10:00:00+09:00"
    }
  ]
}
```

---

### 10-2. 전시 에셋 단건 조회

- **Method**: `GET`
- **URL**: `/events/{eventId}/display-assets/{assetId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "fileId": 1,
    "assetType": "BACKGROUND_DESKTOP",
    "displayWidth": 1920,
    "displayHeight": 1080,
    "sortOrder": 0,
    "isActive": true,
    "cdnUrl": "https://cdn.example.com/event/2026/03/uuid.png",
    "createdAt": "2026-02-20T10:00:00+09:00",
    "updatedAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 10-3. 전시 에셋 등록

- **Method**: `POST`
- **URL**: `/events/{eventId}/display-assets`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "fileId": 1,
  "assetType": "BACKGROUND_DESKTOP",
  "displayWidth": 1920,
  "displayHeight": 1080,
  "sortOrder": 0,
  "isActive": true
}
```

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| fileId | Long | Y | 파일 식별자 (FK: event_file) |
| assetType | String | Y | UI 슬롯 유형 코드 |
| displayWidth | Integer | N | UI 표시 너비 (px, null=원본 크기) |
| displayHeight | Integer | N | UI 표시 높이 (px, null=원본 크기) |
| sortOrder | Integer | N | 동일 asset_type 내 순서 (기본값: 0) |
| isActive | Boolean | N | 활성화 여부 (기본값: true) |

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "eventId": 1,
    "fileId": 1,
    "assetType": "BACKGROUND_DESKTOP",
    "displayWidth": 1920,
    "displayHeight": 1080,
    "sortOrder": 0,
    "isActive": true,
    "createdAt": "2026-02-20T10:00:00+09:00"
  }
}
```

---

### 10-4. 전시 에셋 수정

- **Method**: `PATCH`
- **URL**: `/events/{eventId}/display-assets/{assetId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |
| Content-Type | Y | `application/json` |

**Request Body**

```json
{
  "fileId": 2,
  "displayWidth": 1280,
  "displayHeight": 720,
  "sortOrder": 1,
  "isActive": false
}
```

**Response Body**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "fileId": 2,
    "displayWidth": 1280,
    "displayHeight": 720,
    "sortOrder": 1,
    "isActive": false,
    "updatedAt": "2026-03-03T12:00:00+09:00"
  }
}
```

---

### 10-5. 전시 에셋 삭제 (논리 삭제)

- **Method**: `DELETE`
- **URL**: `/events/{eventId}/display-assets/{assetId}`

**Request Header**

| 헤더명 | 필수 | 설명 |
|---|---|---|
| Authorization | Y | `Bearer {accessToken}` |

**Response Body**

```json
{
  "success": true,
  "data": null
}
```

---

## 공통 에러 응답

```json
{
  "success": false,
  "error": {
    "code": "EVENT_NOT_FOUND",
    "message": "이벤트를 찾을 수 없습니다.",
    "timestamp": "2026-03-03T12:00:00+09:00"
  }
}
```

| HTTP Status | 에러 코드 | 설명 |
|---|---|---|
| 400 | INVALID_REQUEST | 요청 파라미터 유효성 오류 |
| 401 | UNAUTHORIZED | 인증 토큰 없음 또는 만료 |
| 403 | FORBIDDEN | 권한 없음 |
| 404 | NOT_FOUND | 리소스 없음 |
| 409 | DUPLICATE_ENTRY | 중복 응모 (1인 1참여 정책 위반) |
| 500 | INTERNAL_SERVER_ERROR | 서버 내부 오류 |
