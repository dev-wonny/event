# BaseResponse (숫자 코드 버전)
## 공통 응답 구조
- HTTP Status Code는 헤더에서만 사용
- BaseResponse.code는 비즈니스 전용 커스텀 코드
- HTTP와 BaseResponse.code는 분리

## 계층 구조
- HTTP Status  → 전송 계층 상태 (기술적 의미)
- Business Code → 도메인 의미 (비즈니스 실패 원인)

```text
HTTP Status (Header)
    └─ 200 / 400 / 401 / 403 / 404 / 409 / 500

Body
    └─ BaseResponse.code (비즈니스 코드)
```


## BaseResponse 구조
```json
header
{
  "status": 200
}
body
{
  "code": 20015,
  "message": "참여가 완료되었습니다.",
  "timestamp": "2026-03-03T17:20:00Z",
  "data": { ... }
}
```
## 코드 구조

### [HTTP 그룹]-[도메인]-[번호]
- 400-CHECKIN-001
- 409-WELCOME-002
- 404-QUIZ-001


## 코드 체계 설계안 (권장)

HTTP Status Code != BaseResponse.code

```text
HTTP Status Code  →  BaseResponse.code
```

## BaseResponse.code 구조
| 구간     | 설명                                      |
| ------ | --------------------------------------- |
| HTTP   | 200 / 400 / 401 / 403 / 404 / 409 / 500 |
| DOMAIN | EVT / ATT / RNDM / PRZ / ENTY / WIN     |
| NNN    | 세부 번호                                   |



## BaseResponse.code 세부 정의
### HTTP Status (표준 의미 유지)
HTTP | 의미
------|------
200 | 요청 정상 처리
201 | 생성 성공
400 | 요청 오류
401 | 인증 오류
403 | 권한 오류
404 | 리소스 없음
409 | 상태 충돌
500 | 서버 오류

### DOMAIN
| DOMAIN | 의미    |
| ------ | ----- |
| EVT    | 이벤트   |
| ATT    | 출석    |
| RNDM   | 랜덤/스핀 |
| PRZ    | 경품    |
| ENTY   | 참여    |
| WIN    | 당첨    |


### 예시
```json
{
  "code": "409-CHK-002",
  "message": "이미 이번 사이클의 보상을 수령했습니다.",
  "timestamp": "2026-03-04T09:21:11Z",
  "data": null
}
```

## 요약

- HTTP Status Code: 헤더에서만 사용, 표준 의미 유지
- BaseResponse.code: 본문에서 사용, 비즈니스 전용 커스텀 코드
- HTTP와 BaseResponse.code는 분리
- 이 구조를 사용하면 HTTP 표준을 준수하면서도 비즈니스 로직을 명확하게 표현할 수 있습니다.