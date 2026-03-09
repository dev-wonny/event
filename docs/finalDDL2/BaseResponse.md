## code pakage 구조

- 구조
```text
response
 ├─ BaseResponse
 ├─ ResponseCode
 │
 ├─ BusinessException
 ├─ GlobalExceptionHandler
 │
 ├─ event
 │   └─ EventCode
 │
 ├─ attendance
 │   └─ AttendanceCode
 │
 ├─ random
 │   └─ RandomCode
 │
 ├─ prize
 │   └─ PrizeCode
 │
 ├─ entry
 │   └─ EntryCode
 │
 └─ win
     └─ WinCode
 ```

## 1. BaseResponse 구조
```java
public record BaseResponse<T>(
        String code,
        String message,
        Instant timestamp,
        T data
) {

    public static <T> BaseResponse<T> of(ResponseCode code, T data) {

        return new BaseResponse<>(
                code.getCode(),
                code.getMessage(),
                Instant.now(),
                data
        );
    }
}
```

## ResponseCode 하나로 통합
- ErrorCode, SuccessCode를 따로 두지 않고 ResponseCode 하나로 통합
- 이유는 status, code, message를 하나로 관리하기 위함
```java
public interface ResponseCode {

    HttpStatus getStatus();

    String getCode();

    String getMessage();
}
```

### AttendanceCode (ATT)
```java
@Getter
@AllArgsConstructor
public enum AttendanceCode implements ResponseCode {

    ATT_NOT_ELIGIBLE(
            HttpStatus.FORBIDDEN,
            "ATT_NOT_ELIGIBLE",
            "출석 보상 대상이 아닙니다."
    ),

    ATT_ALREADY_CHECKED_IN(
            HttpStatus.CONFLICT,
            "ATT_ALREADY_CHECKED_IN",
            "이미 오늘 출석했습니다."
    ),

    ATT_REWARD_ALREADY_GRANTED(
            HttpStatus.CONFLICT,
            "ATT_REWARD_ALREADY_GRANTED",
            "이미 출석 보상을 수령했습니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```
### AttendanceCode
```java
@Getter
@AllArgsConstructor
public enum AttendanceCode implements ResponseCode {

    ATT_CHECKED_IN(
            "ATT_CHECKED_IN",
            "출석이 완료되었습니다."
    ),

    ATT_REWARD_GRANTED(
            "ATT_REWARD_GRANTED",
            "출석 보상이 지급되었습니다."
    );

    private final String code;
    private final String message;
}
```




### EventCode (EVT)
```java
@Getter
@AllArgsConstructor
public enum EventCode implements ResponseCode {

    EVT_NOT_FOUND(
            HttpStatus.NOT_FOUND,
            "EVT_NOT_FOUND",
            "이벤트를 찾을 수 없습니다."
    ),

    EVT_NOT_ACTIVE(
            HttpStatus.FORBIDDEN,
            "EVT_NOT_ACTIVE",
            "현재 진행 중인 이벤트가 아닙니다."
    ),

    EVT_EXPIRED(
            HttpStatus.FORBIDDEN,
            "EVT_EXPIRED",
            "종료된 이벤트입니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### PrizeCode (PRZ)
```java
@Getter
@AllArgsConstructor
public enum PrizeCode implements ResponseCode {

    PRZ_NOT_FOUND(
            HttpStatus.NOT_FOUND,
            "PRZ_NOT_FOUND",
            "경품을 찾을 수 없습니다."
    ),

    PRZ_OUT_OF_STOCK(
            HttpStatus.CONFLICT,
            "PRZ_OUT_OF_STOCK",
            "경품 재고가 소진되었습니다."
    ),

    PRZ_INVALID_STATE(
            HttpStatus.CONFLICT,
            "PRZ_INVALID_STATE",
            "경품 상태가 유효하지 않습니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### EntryCode (ENTY)
```java
@Getter
@AllArgsConstructor
public enum EntryCode implements ResponseCode {

    ENTY_NOT_ALLOWED(
            HttpStatus.FORBIDDEN,
            "ENTY_NOT_ALLOWED",
            "참여가 허용되지 않습니다."
    ),

    ENTY_ALREADY_ENTERED(
            HttpStatus.CONFLICT,
            "ENTY_ALREADY_ENTERED",
            "이미 참여하였습니다."
    ),

    ENTY_LIMIT_EXCEEDED(
            HttpStatus.CONFLICT,
            "ENTY_LIMIT_EXCEEDED",
            "참여 가능 횟수를 초과했습니다."
    ),

    ENTY_INVALID_CONDITION(
            HttpStatus.BAD_REQUEST,
            "ENTY_INVALID_CONDITION",
            "참여 조건이 유효하지 않습니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### WinCode (WIN)
```java
@Getter
@AllArgsConstructor
public enum WinCode implements ResponseCode {

    WIN_NOT_FOUND(
            HttpStatus.NOT_FOUND,
            "WIN_NOT_FOUND",
            "당첨 정보를 찾을 수 없습니다."
    ),

    WIN_NOT_ELIGIBLE(
            HttpStatus.FORBIDDEN,
            "WIN_NOT_ELIGIBLE",
            "당첨 대상이 아닙니다."
    ),

    WIN_ALREADY_CLAIMED(
            HttpStatus.CONFLICT,
            "WIN_ALREADY_CLAIMED",
            "이미 당첨 보상을 수령하였습니다."
    ),

    WIN_CLAIM_PERIOD_EXPIRED(
            HttpStatus.FORBIDDEN,
            "WIN_CLAIM_PERIOD_EXPIRED",
            "당첨 수령 기간이 만료되었습니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### RandomCode (RNDM)
```java
@Getter
@AllArgsConstructor
public enum RandomCode implements ResponseCode {

    RNDM_NOT_ALLOWED(
            HttpStatus.FORBIDDEN,
            "RNDM_NOT_ALLOWED",
            "현재 스핀 참여가 불가능합니다."
    ),

    RNDM_NO_REWARD_AVAILABLE(
            HttpStatus.CONFLICT,
            "RNDM_NO_REWARD_AVAILABLE",
            "현재 지급 가능한 보상이 없습니다."
    ),

    RNDM_ALREADY_SPUN(
            HttpStatus.CONFLICT,
            "RNDM_ALREADY_SPUN",
            "이미 참여하였습니다."
    ),

    RNDM_LOCK_CONFLICT(
            HttpStatus.CONFLICT,
            "RNDM_LOCK_CONFLICT",
            "동시성 충돌이 발생했습니다."
    );

    private final HttpStatus status;
    private final String code;
    private final String message;
}
```

### GlobalExceptionHandler
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<BaseResponse<Void>> handleBusinessException(
            BusinessException e) {

        ResponseCode code = e.getCode();

        return ResponseEntity
                .status(code.getStatus())
                .body(BaseResponse.of(code, null));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<BaseResponse<Void>> handleException(Exception e) {

        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(BaseResponse.of(CommonCode.INTERNAL_ERROR, null));
    }
}
```

### Controller
```java
return ResponseEntity
        .status(AttendanceSuccessCode.ATT_CHECKED_IN.getStatus())
        .body(BaseResponse.of(
                AttendanceSuccessCode.ATT_CHECKED_IN,
                result
        ));
```

### 응답 예시
- 성공
```json
"header" : HttpStatus.OK
"body" : 
{
  "code": "ATT_CHECKED_IN",
  "message": "출석이 완료되었습니다.",
  "timestamp": "2026-03-04T10:55:11Z",
  "data": {
    "attendanceCount": 5
  }
}
```

- 실패
```json
"header" : HttpStatus.CONFLICT
"body" : 
{
  "code": "ATT_ALREADY_CHECKED_IN",
  "message": "이미 오늘 출석했습니다.",
  "timestamp": "2026-03-04T10:55:11Z",
  "data": null
}
```