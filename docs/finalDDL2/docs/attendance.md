# 출석체크

2월 28일짜리 출석체크 이벤트 생성 과정 (출석시 매일 똑같은 30포인트 줌)
1. event insert
* event_round에 
* round_start_at 2026년 2월 1일 00:00  - round_end_at 2월 1일 23시 59:59
* round_start_at 2026년 2월 2일 00:00  - round_end_at 2월 2일 23시 59:59
* .. 총 28개 row 쌓음

각각의 event_round row는 event_round_prize에서 매핑함
- event_round_prize 도 28 row 생김
- event_round_prize는 똑같은 포인트를 설정하므로 공통적으로 event_round_prize. prize_id = 1 ; 세팅 됨

prize는 재활용을 위해(수정 안된다고 규칙정함, 이유는 추적때 스냅샷 안사용하고 prize. id 로 리워드 추적하려고)
prize. id =1;
prize.name = 2월 출석 체크 포인트 기본 세팅;
prize. reward_type = POINT
prize. point_amount = 30;


event_applicant
- 이벤트 최초 참여 시 생성
- (event_id, member_id) unique
- 참여자 식별 목적

event_entry
- 응모 기록 저장
- append-only
- 참여 횟수 관리