-- =============================================================
-- 이벤트 도메인 예시 데이터 (Sample Data)
-- 작성일: 2026-02-24
-- 순서: FK 의존성 순서대로 INSERT
-- =============================================================

-- =============================================================
-- [1] prize - 경품 마스터
-- =============================================================
INSERT INTO prize (prize_name, prize_amount, prize_description, is_active, is_deleted,
                   recipient_end_date, usage_end_date, created_at, created_by, updated_at, updated_by)
VALUES
    ('스타벅스 기프티콘 1만원',  10000, '스타벅스 아메리카노 등 1만원 상당 음료 교환권', TRUE, FALSE, '2026-06-30', '2026-12-31', NOW(), 1, NOW(), 1),
    ('신세계 상품권 3만원',      30000, '신세계 백화점/이마트 사용 가능 상품권',           TRUE, FALSE, '2026-06-30', '2026-12-31', NOW(), 1, NOW(), 1),
    ('삼성 갤럭시워치 7',       500000, '삼성 갤럭시워치 7 스마트워치 (블랙)',              TRUE, FALSE, '2026-03-31', '2026-06-30', NOW(), 1, NOW(), 1),
    ('포인트 1000P',              1000, '서비스 내 사용 가능 포인트',                       TRUE, FALSE, NULL,         NULL,         NOW(), 1, NOW(), 1);

-- =============================================================
-- [2] event - 이벤트 마스터
-- =============================================================
INSERT INTO event (event_name, event_type, start_at, end_at,
                   is_active, is_displayed, is_recommended, is_auto_entry, is_confirmed,
                   is_sns_linked, event_url, description, gift_description,
                   supplier_id, is_winner_announced, allow_duplicate_winner,
                   allow_multiple_entry, winner_selection_cycle, priority,
                   created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1: 설날 응모 이벤트 (SNS 연동, 1회 추첨)
    ('2026 설날 경품 이벤트', 'RAFFLE',
     '2026-02-01 00:00:00', '2026-02-16 23:59:59',
     TRUE, TRUE, TRUE, FALSE, TRUE,
     TRUE, 'https://event.example.com/lunar2026', '이 이벤트에 응모하고 푸짐한 경품을 받아가세요!', '스타벅스 기프티콘 등',
     100, FALSE, FALSE,
     FALSE, NULL, 1,
     NOW(), 1, NOW(), 1),

    -- 이벤트 2: 구매 기반 자동 응모 이벤트 (주간 추첨)
    ('봄 시즌 구매 이벤트', 'PURCHASE',
     '2026-03-01 00:00:00', '2026-03-31 23:59:59',
     TRUE, TRUE, FALSE, TRUE, TRUE,
     FALSE, 'https://event.example.com/spring2026', '3만원 이상 구매 시 자동 응모!', '신세계 상품권',
     200, FALSE, FALSE,
     TRUE, 'WEEKLY', 2,
     NOW(), 1, NOW(), 1),

    -- 이벤트 3: SNS 공유 이벤트 (비활성)
    ('SNS 공유 경품 이벤트', 'SNS',
     '2026-04-01 00:00:00', '2026-04-30 23:59:59',
     FALSE, FALSE, FALSE, FALSE, FALSE,
     TRUE, NULL, 'SNS 공유 후 경품 응모', NULL,
     100, FALSE, FALSE,
     FALSE, NULL, 3,
     NOW(), 1, NOW(), 1);

-- =============================================================
-- [3] event_prize - 이벤트 경품 정책
-- =============================================================
INSERT INTO event_prize (event_id, prize_id, prize_no, prize_type, prize_limit, priority,
                          tax_amount, is_active, is_deleted, created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1 경품 구성
    (1, 3, 1, 'PRODUCT', 1,   1, 150000, TRUE, FALSE, NOW(), 1, NOW(), 1),  -- 갤럭시워치 (1명, 1등)
    (1, 2, 2, 'PRODUCT', 5,   2, NULL,   TRUE, FALSE, NOW(), 1, NOW(), 1),  -- 신세계상품권 (5명, 2등)
    (1, 1, 3, 'PRODUCT', 50,  3, NULL,   TRUE, FALSE, NOW(), 1, NOW(), 1),  -- 스타벅스 (50명, 3등)
    -- 이벤트 2 경품 구성
    (2, 2, 1, 'PRODUCT', 10,  1, NULL,   TRUE, FALSE, NOW(), 1, NOW(), 1),  -- 신세계상품권 (10명)
    (2, 4, 2, 'POINT',   500, 2, NULL,   TRUE, FALSE, NOW(), 1, NOW(), 1);  -- 포인트 (500명)

-- =============================================================
-- [4] event_image_file - 이미지 파일 메타데이터
-- =============================================================
INSERT INTO event_image_file (file_key, original_name, content_type, file_size, width, height,
                               created_at, created_by, updated_at, updated_by)
VALUES
    ('event/banner/2026/02/lunar-main-orig.png', 'lunar_banner_original.png', 'image/png',  1540200, 1920, 800, NOW(), 1, NOW(), 1),
    ('event/banner/2026/02/lunar-main-pc.png',   'lunar_banner_pc.png',       'image/png',   720500, 1200, 500, NOW(), 1, NOW(), 1),
    ('event/banner/2026/02/lunar-main-mo.png',   'lunar_banner_mobile.png',   'image/png',   380000,  750, 400, NOW(), 1, NOW(), 1),
    ('event/banner/2026/03/spring-main-orig.png','spring_banner_original.png','image/png',  1200000, 1920, 800, NOW(), 1, NOW(), 1);

-- =============================================================
-- [5] event_banner - 배너 노출 정책
-- =============================================================
INSERT INTO event_banner (event_id, channel_type, device_type, display_location,
                           link_url, priority, is_active, is_displayed,
                           created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1 배너 (SHOP 채널, 전체 디바이스, 홈 메인)
    (1, 'SHOP', 'ALL',    'HOME',    'https://event.example.com/lunar2026', 1, TRUE, TRUE, NOW(), 1, NOW(), 1),
    -- 이벤트 1 배너 (SHOP 채널, 모바일, 상품 상세)
    (1, 'SHOP', 'MOBILE', 'PRODUCT', 'https://event.example.com/lunar2026', 2, TRUE, TRUE, NOW(), 1, NOW(), 1),
    -- 이벤트 2 배너
    (2, 'SHOP', 'ALL',    'HOME',    'https://event.example.com/spring2026', 1, TRUE, TRUE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [6] event_banner_image - 배너-이미지 매핑
-- =============================================================
INSERT INTO event_banner_image (event_banner_id, event_file_id, image_variant,
                                 created_at, created_by, updated_at, updated_by)
VALUES
    -- 배너 1 (이벤트1, SHOP/ALL/HOME): 원본+PC+모바일
    (1, 1, 'ORIGINAL', NOW(), 1, NOW(), 1),
    (1, 2, 'PC',       NOW(), 1, NOW(), 1),
    (1, 3, 'MOBILE',   NOW(), 1, NOW(), 1),
    -- 배너 2 (이벤트1, SHOP/MOBILE/PRODUCT): 모바일만
    (2, 3, 'MOBILE',   NOW(), 1, NOW(), 1),
    -- 배너 3 (이벤트2): 원본
    (3, 4, 'ORIGINAL', NOW(), 1, NOW(), 1);

-- =============================================================
-- [7] event_sns - SNS 공유 정보
-- =============================================================
INSERT INTO event_sns (event_id, sns_code, title, content, sns_url, image_url,
                        is_deleted, created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1 카카오 공유
    (1, 'KAKAO', '2026 설날 경품 이벤트',
     '새해 복 많이 받으세요! 설날 경품 이벤트에 응모하고 풍성한 선물 받아가세요. 지금 바로 참여하세요!',
     'https://event.example.com/lunar2026',
     'https://cdn.example.com/event/lunar2026-share.jpg',
     FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 1 페이스북 공유
    (1, 'FACEBOOK', '설날 경품 이벤트',
     '🎁 설날 경품 이벤트! 갤럭시워치, 신세계상품권, 스타벅스 기프티콘 등 푸짐한 경품! 지금 응모하세요.',
     'https://event.example.com/lunar2026',
     'https://cdn.example.com/event/lunar2026-share.jpg',
     FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 3 인스타그램 공유
    (3, 'INSTAGRAM', NULL,
     '공유하고 경품 받자! #이벤트 #경품 #구매혜택',
     'https://event.example.com/sns2026', NULL,
     FALSE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [8] event_applicant - 이벤트 응모자 기준
-- =============================================================
INSERT INTO event_applicant (event_id, member_id, draw_id, is_deleted,
                              created_at, created_by, updated_at, updated_by)
VALUES
    (1, 20001, NULL, FALSE, NOW(), 1, NOW(), 1),
    (1, 20002, NULL, FALSE, NOW(), 1, NOW(), 1),
    (1, 20003, NULL, FALSE, NOW(), 1, NOW(), 1),
    (2, 20001, NULL, FALSE, NOW(), 1, NOW(), 1),
    (2, 20004, NULL, FALSE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [9] event_entry - 이벤트 응모 이력
-- =============================================================
INSERT INTO event_entry (event_id, entry_id, member_id, applied_at, order_no,
                          prize_id, is_winner, purchase_amount, order_count, cancel_count,
                          is_deleted, created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1 응모
    (1, 1, 20001, '2026-02-03 10:15:00', NULL,         NULL, FALSE, NULL,  NULL, NULL, FALSE, NOW(), 1, NOW(), 1),
    (1, 2, 20002, '2026-02-05 14:30:00', NULL,         NULL, FALSE, NULL,  NULL, NULL, FALSE, NOW(), 1, NOW(), 1),
    (1, 3, 20003, '2026-02-10 09:00:00', NULL,         NULL, FALSE, NULL,  NULL, NULL, FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 2 응모 (구매 기반)
    (2, 1, 20001, '2026-03-05 16:20:00', 'ORD-2026030501', NULL, FALSE, 55000, 2, 0, FALSE, NOW(), 1, NOW(), 1),
    (2, 2, 20004, '2026-03-07 11:00:00', 'ORD-2026030702', NULL, FALSE, 32000, 1, 0, FALSE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [10] event_draw_round - 이벤트 추첨 회차
-- =============================================================
INSERT INTO event_draw_round (event_id, draw_no, is_confirmed,
                               draw_at, draw_start_at, draw_end_at, announcement_at,
                               is_deleted, created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1: 단일 추첨 회차
    (1, 1, TRUE,
     '2026-02-17 10:00:00', '2026-02-01 00:00:00', '2026-02-16 23:59:59', '2026-02-18 09:00:00',
     FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 2: 주간 추첨 2회차
    (2, 1, TRUE,
     '2026-03-08 10:00:00', '2026-03-01 00:00:00', '2026-03-07 23:59:59', '2026-03-09 09:00:00',
     FALSE, NOW(), 1, NOW(), 1),
    (2, 2, FALSE,
     NULL,                  '2026-03-08 00:00:00', '2026-03-14 23:59:59', NULL,
     FALSE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [11] event_win - 이벤트 당첨 결과
-- =============================================================
INSERT INTO event_win (event_id, member_id, draw_id, entry_id, prize_id,
                        sent_at, is_sent, received_at, is_received,
                        is_email_sent, is_sms_sent, confirmed_at,
                        is_deleted, created_at, created_by, updated_at, updated_by)
VALUES
    -- 이벤트 1 당첨자: 회원 20001 → 갤럭시워치 (1등)
    (1, 20001, 1, 1, 3,
     '2026-02-20', TRUE, '2026-02-22', TRUE,
     TRUE, TRUE, '2026-02-17 11:00:00',
     FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 1 당첨자: 회원 20002 → 신세계상품권 (2등)
    (1, 20002, 1, 2, 2,
     '2026-02-20', TRUE, NULL, FALSE,
     TRUE, TRUE, '2026-02-17 11:00:00',
     FALSE, NOW(), 1, NOW(), 1),
    -- 이벤트 2 1차 추첨 당첨자: 회원 20001 → 신세계상품권
    (2, 20001, 2, 4, 2,
     NULL, FALSE, NULL, FALSE,
     FALSE, FALSE, NULL,
     FALSE, NOW(), 1, NOW(), 1);

-- =============================================================
-- [12] event_sns_share_log - SNS 공유 이력 (신규)
-- =============================================================
INSERT INTO event_sns_share_log (event_id, member_id, sns_code, shared_at, is_success,
                                  created_at, created_by)
VALUES
    (1, 20001, 'KAKAO',    '2026-02-04 09:30:00', TRUE,  NOW(), 1),
    (1, 20002, 'FACEBOOK', '2026-02-06 15:00:00', TRUE,  NOW(), 1),
    (1, 20001, 'FACEBOOK', '2026-02-07 10:00:00', FALSE, NOW(), 1),
    (3, 20003, 'INSTAGRAM','2026-04-05 20:00:00', TRUE,  NOW(), 1);
