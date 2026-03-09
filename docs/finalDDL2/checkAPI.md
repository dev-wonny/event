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
> 돌쇠네 쇼핑몰이 자체 회원의 `externalMemberId`를 서버 간 통신으로 전달하며, 이벤트 시스템은 이 값을 **검증 없이 식별자로 사용**.

---
## API 명세서 내용
- 접근 권한
- 기능 설명
- 메소드
- URL
- Request Header
- Request 파라미터
- Request Body
- Response Header
- Response Body
- Error Response


---

# 사용자 API
- 이벤트 참여
- 이벤트 참여 + 당첨 내역
- 참여 여부 조회
- 당첨 내역 조회


# 관리자 API
- 관리자용이지만, /admin 넣지 않음
- 이유는 api로도 생성할 수 있기 때문에

## 이벤트 (event)
- 이벤트 생성
 - event_round 1개는 무조건 생성
- 이벤트 조회
   - 목록
      - 페이징
      - 정렬
       - created_at desc
      - 검색
   - 상세
- 이벤트 수정
- 이벤트 삭제
- 이벤트 검색
 - event_name
 - event_type
 - event_id
 - 이벤트 기간
 - is_active
 - is_visible
- 상태 변경 (patch)
 - is_active
 - is_visible
 - is_deleted
 - is_auto_entry
 - is_winner_announced


## 회차 (event_round)
- 회차 생성
- 회차 조회
   - 목록
   - 상세
- 회차 수정
- 회차 삭제
- 상태 변경 (patch)
 - is_confirmed
 - is_deleted

## 경품 (prize)
- 경품 생성
- 경품 조회
   - 목록
   - 상세
- 경품 수정
- 경품 삭제
- 경품 검색
  - 경품명
  - 경품 코드
  - 경품 타입
  - 경품 상태
- 상태 변경 (patch)
 - is_active
 - is_deleted


## 회차별 경품 설정 (event_round_prize)
- 회차별 경품 설정
- 회차별 경품 설정 조회
- 회차별 경품 설정 수정
- 회차별 경품 설정 삭제
- 상태 변경 (patch)
 - is_active
 - is_deleted


## 확률 (event_round_prize_probability)
- 확률 설정
- 확률 설정 조회
- 확률 설정 수정
- 확률 설정 삭제


## 참여자 (event_applicant)
- 이벤트에 속한 참여자 생성 (수기)
- 이벤트에 속한 참여자 조회
- 이벤트에 속한 참여자 수정
- 이벤트에 속한 참여자 삭제
- 이벤트에 속한 참여자 검색
   - event_id
   - round_id
   - memberId
   - event_applicant_id

## 응모자 (event_entry)
- 이벤트에 속한 응모자 생성 (수기)
- 이벤트에 속한 응모자 조회
- 이벤트에 속한 응모자 수정
- 이벤트에 속한 응모자 삭제
- 이벤트에 속한 응모자 검색
   - event_id
   - round_id
   - memberId
   - event_applicant_id
   - event_entry_id
   - 당첨 여부
- 상태 변경 (patch)
 - is_winner
 - is_deleted

## 당첨자 (event_win)
- 이벤트에 속한 당첨자 생성 (수기)
- 이벤트에 속한 당첨자 조회
- 이벤트에 속한 당첨자 수정
- 이벤트에 속한 당첨자 삭제
- 이벤트에 속한 당첨자 검색
   - event_id
   - round_id
   - memberId
   - event_applicant_id
   - event_entry_id
   - event_win_id
   - 당첨일
   - prize_id
   - reward_type
