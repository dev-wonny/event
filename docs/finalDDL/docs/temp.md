@ -0,0 +1,486 @@
### 표준 구조

```json
{
  "code": "4090302",
  "message": "이미 이번 사이클의 보상을 수령했습니다.",
  "timestamp": "2026-03-04T08:21:30Z",
  "data": null
}
```

## 필드별 설계 기준
### 1. code (String, 필수)

- HTTP Status와는 별개
- 비즈니스 코드
- 절대 숫자형 쓰지 말 것 (앞자리 0 유지 문제)
- Enum 기반 관리

2000000  → 성공
4090302  → Checkin 이미 보상 수령
4040501  → Quiz 질문 없음
5000001  → 서버 내부 오류

### 2. message (String, 필수)

- 사용자 노출용
- 다국어 대응 고려
- 서버에서 내려주는 것을 원칙으로
- 운영 로그용 상세 메시지는 별도 로그로 처리

### 3. timestamp (String, 필수)

- ISO 8601 형식
- UTC 기준
- 예: 2026-03-04T08:21:30Z
- 서버 기준 시간
- 장애 분석 시 필수
- 클라이언트 시간 의존하지 말 것

### 4. data (Object, 선택)

- 실제 응답 데이터
- 성공 시에만 포함
- 실패 시 null
- 절대 에러 정보 섞지 말 것

### Java 구현 예시 (Spring 기준)

```java
public record BaseResponse<T>(
        String code,
        String message,
        Instant timestamp,
        T data
) {

    private static final String SUCCESS_CODE = "2000000";
    private static final String SUCCESS_MESSAGE = "성공";

    public static <T> BaseResponse<T> success(T data) {
        return new BaseResponse<>(
                SUCCESS_CODE,
                SUCCESS_MESSAGE,
                Instant.now(),
                data
        );
    }

    public static <T> BaseResponse<T> error(ErrorCode error) {
        return new BaseResponse<>(
                error.getCode(),
                error.getMessage(),
                Instant.now(),
                null
        );
    }
}
```
## code 설계

### HTTP Status
| HTTP | 의미 |
| ---- | ---- |
| 200 | 성공 |
| 400 | 잘못된 요청 |
| 401 | 인증 실패 |
| 403 | 권한 없음 |
| 404 | 찾을 수 없음 |
| 409 | 상태 충돌 |
| 500 | 서버 오류 |

### DOMAIN
| DOMAIN | 의미    |
| ------ | ----- |
| EVT    | 이벤트   |
| ATT    | 출석    |
| RNDM   | 랜덤/스핀 |
| PRZ    | 경품    |
| ENTY   | 참여    |
| WIN    | 당첨    |

## ENUM
- 성공과 실패는 구분하여 관리
- 도메인별로 만든다
- interface로 공통 관리

### interface
```java
public interface ErrorCode {
    HttpStatus getStatus();
    String getCode();
    String getMessage();
}
```

### EVT (이벤트) - 실패
- 이벤트 자체 상태/기간/비활성 관련

```java
@Getter
@AllArgsConstructor
public enum EventErrorCode implements ErrorCode {

    EVENT_NOT_FOUND(HttpStatus.NOT_FOUND, "404-EVT-001", "이벤트를 찾을 수 없습니다."),
    EVENT_NOT_ACTIVE(HttpStatus.FORBIDDEN, "403-EVT-002", "현재 진행 중인 이벤트가 아닙니다."),
    EVENT_EXPIRED(HttpStatus.FORBIDDEN, "403-EVT-003", "종료된 이벤트입니다."),
    EVENT_NOT_STARTED(HttpStatus.FORBIDDEN, "403-EVT-004", "아직 시작되지 않은 이벤트입니다."),
    EVENT_DELETED(HttpStatus.GONE, "404-EVT-005", "삭제된 이벤트입니다."),

    EVENT_INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-EVT-001", "이벤트 처리 중 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### PRZ (경품) - 실패
```java 
@Getter
@AllArgsConstructor
public enum PrizeErrorCode implements ErrorCode {

    PRIZE_NOT_FOUND(HttpStatus.NOT_FOUND, "404-PRZ-001", "경품을 찾을 수 없습니다."),
    PRIZE_OUT_OF_STOCK(HttpStatus.CONFLICT, "409-PRZ-002", "경품 재고가 소진되었습니다."),
    INVALID_PRIZE_STATE(HttpStatus.CONFLICT, "409-PRZ-003", "현재 지급 불가능한 경품 상태입니다."),

    DELIVERY_INFO_REQUIRED(HttpStatus.BAD_REQUEST, "400-PRZ-004", "배송 정보가 필요합니다."),
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-PRZ-001", "경품 처리 중 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```
### ENTY (참여) - 실패
```java
@Getter
@AllArgsConstructor
public enum EntryErrorCode implements ErrorCode {

    ENTRY_NOT_ALLOWED(HttpStatus.FORBIDDEN, "403-ENTY-001", "참여가 허용되지 않습니다."),
    ALREADY_ENTERED(HttpStatus.CONFLICT, "409-ENTY-002", "이미 참여하였습니다."),
    ENTRY_LIMIT_EXCEEDED(HttpStatus.CONFLICT, "409-ENTY-003", "참여 가능 횟수를 초과했습니다."),
    INVALID_ENTRY_CONDITION(HttpStatus.BAD_REQUEST, "400-ENTY-004", "참여 조건이 유효하지 않습니다."),

    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-ENTY-001", "참여 처리 중 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### WIN (당첨) - 실패
```java
@Getter
@AllArgsConstructor
public enum WinErrorCode implements ErrorCode {

    NOT_WINNER(HttpStatus.FORBIDDEN, "403-WIN-001", "당첨 대상이 아닙니다."),
    ALREADY_CLAIMED(HttpStatus.CONFLICT, "409-WIN-002", "이미 당첨 보상을 수령하였습니다."),
    CLAIM_PERIOD_EXPIRED(HttpStatus.FORBIDDEN, "403-WIN-003", "당첨 수령 기간이 만료되었습니다."),
    WIN_NOT_FOUND(HttpStatus.NOT_FOUND, "404-WIN-004", "당첨 정보를 찾을 수 없습니다."),

    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-WIN-001", "당첨 처리 중 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```


### ATT (출석) - 실패

```java
@Getter
@AllArgsConstructor
public enum AttendanceErrorCode implements ErrorCode {

    NOT_ELIGIBLE(HttpStatus.FORBIDDEN, "403-ATT-001", "출석 보상 대상이 아닙니다."),
    ALREADY_CHECKED_IN(HttpStatus.CONFLICT, "409-ATT-002", "이미 오늘 출석 처리되었습니다."),
    REWARD_ALREADY_GRANTED(HttpStatus.CONFLICT, "409-ATT-003", "이미 해당 사이클 보상을 수령했습니다."),
    DAILY_LIMIT_EXCEEDED(HttpStatus.CONFLICT, "409-ATT-004", "일일 출석 제한을 초과했습니다."),

    LOCK_CONFLICT(HttpStatus.CONFLICT, "409-ATT-005", "출석 처리 중 충돌이 발생했습니다."),
    SYSTEM_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-ATT-001", "출석 처리 중 서버 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### RNDM (스핀 / 랜덤)
```java
@Getter
@AllArgsConstructor
public enum RandomErrorCode implements ErrorCode {

    SPIN_NOT_ALLOWED(HttpStatus.FORBIDDEN, "403-RNDM-001", "현재 스핀 참여가 불가능합니다."),
    NO_REWARD_AVAILABLE(HttpStatus.CONFLICT, "409-RNDM-002", "현재 지급 가능한 보상이 없습니다."),
    ALREADY_SPUN(HttpStatus.CONFLICT, "409-RNDM-003", "이미 참여하였습니다."),
    PROBABILITY_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "500-RNDM-001", "확률 계산 중 오류가 발생했습니다."),

    LOCK_CONFLICT(HttpStatus.CONFLICT, "409-RNDM-004", "동시성 충돌이 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```



## success

### SuccessCode enum 설계

```java
@Getter
@AllArgsConstructor
public enum SuccessCode {

    OK("2000000", "성공"),
    CREATED("2010000", "생성 성공");

    private final String code;
    private final String message;
}
```


### GET 성공 예시

```java 
Controller
@GetMapping("/checkin")
public ResponseEntity<BaseResponse<CheckinResult>> checkin() {

    CheckinResult result = service.checkin();

    return ResponseEntity.ok(
            BaseResponse.success(result)
    );
}

@PostMapping("/events")
public ResponseEntity<BaseResponse<EventCreateResponse>> create(
        @RequestBody EventCreateRequest request
) {

    EventCreateResponse response = service.create(request);

    return ResponseEntity
            .status(HttpStatus.CREATED)
            .body(BaseResponse.success(response));
}

@DeleteMapping("/events/{id}")
public ResponseEntity<BaseResponse<Void>> delete(@PathVariable Long id) {

    service.delete(id);

    return ResponseEntity.ok(
            BaseResponse.success(null)
    );
}
```

### 성공 응답

```json
header: { "HTTP Status" : "200 OK" }
body: {
  "code": "2000000",
  "message": "성공",
  "timestamp": "2026-03-04T08:40:11Z",
  "data": {
    "checkinDate": "2026-03-04",
    "rewardType": "POINT",
    "rewardAmount": 100,
    "totalCheckins": 5,
    "attendanceCount": 7,
    "rewardGranted": true,
    "rewardName": "7일 출석 보상"
  }
}
// 데이터 없는 성공 (DELETE 등)
{
  "code": "2000000",
  "message": "성공",
  "timestamp": "...",
  "data": null
}

// 페이징 성공 예시
{
  "code": "2000000",
  "message": "성공",
  "timestamp": "...",
  "data": {
    "items": [
      { "eventId": 1, "title": "출석 이벤트" }
    ],
    "page": 1,
    "size": 20,
    "total": 150
  }
}
```



## error
| 계층         | 역할      |
| ---------- | ------- |
| Service    | 비즈니스 판단 |
| Exception  | 흐름 중단   |
| Advice     | 응답 통일   |
| Controller | 성공만 처리  |

### 실패 flow

```text
Controller
   ↓
Service
   ↓ (비즈니스 실패)
throw CustomException(ErrorCode)
   ↓
GlobalExceptionHandler
   ↓
BaseResponse.error(...)
```

### ErrorCode Enum 설계

```java
@Getter
@AllArgsConstructor
public enum ErrorCode {

    // Checkin
    CHECKIN_ALREADY_REWARDED(HttpStatus.CONFLICT, "4090302", "이미 이번 사이클의 보상을 수령했습니다."),
    CHECKIN_NOT_ELIGIBLE(HttpStatus.FORBIDDEN, "4030301", "보상 대상이 아닙니다."),

    // Server
    INTERNAL_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "5000001", "서버 오류가 발생했습니다.");

    private final HttpStatus status;
    private final String code;
    private final String message;
}

```


### CustomException
```java
@Getter
public class CustomException extends RuntimeException {

    private final ErrorCode errorCode;

    public CustomException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }
}
```


### GlobalExceptionHandler

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(CustomException.class)
    public ResponseEntity<BaseResponse<Void>> handle(CustomException e) {
        ErrorCode error = e.getErrorCode();

        return ResponseEntity
                .status(error.getStatus())
                .body(BaseResponse.error(
                        error.getCode(),
                        error.getMessage()
                ));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<BaseResponse<Void>> handleUnknown(Exception e) {

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(BaseResponse.error(ErrorCode.INTERNAL_ERROR));
    }
}
```

### BaseResponse.error()
```java
public static <T> BaseResponse<T> error(String code, String message) {
    return new BaseResponse<>(code, message, Instant.now(), null);
}

public static <T> BaseResponse<T> error(ErrorCode error) {
    return new BaseResponse<>(error.getCode(), error.getMessage(), Instant.now(), null);
}
```



### Service에서 실패 처리
```java
public CheckinResult checkin(Long memberId) {

    if (!isEligible(memberId)) {
        throw new CustomException(ErrorCode.CHECKIN_NOT_ELIGIBLE);
    }

    if (alreadyRewarded(memberId)) {
        throw new CustomException(ErrorCode.CHECKIN_ALREADY_REWARDED);
    }

    return reward(memberId);
}

```

### 실패 응답 예시
- 이미 보상 수령

```json
header: { "HTTP Status" : "409 Conflict" }
body: {
  "code": "4090302",
  "message": "이미 이번 사이클의 보상을 수령했습니다.",
  "timestamp": "2026-03-04T08:40:11Z",
  "data": null
}

```




### 성공 응답 예시

```java
@GetMapping("/checkin")
public ResponseEntity<BaseResponse<CheckinResult>> checkin() {
    CheckinResult result = service.checkin();

    return ResponseEntity.ok(
            BaseResponse.success(
                    SuccessCode.OK.getCode(),
                    SuccessCode.OK.getMessage(),
                    result
            )
    );
}
```