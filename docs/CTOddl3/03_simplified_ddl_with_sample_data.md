# 간소화 DDL 및 예시 데이터 (CTOddl3)

## 1. 문서 목적

`docs/CTOddl/entire.sql`의 구조를 바탕으로, 복합 PK/잘못된 FK/누락 제약을 줄인 **간소화 개선안 DDL**을 제공합니다.

- 기준 DBMS: MySQL 8.x (문법 기준)
- 방향: “복잡하지 않게” 유지
- 원본 대비 차이:
  - 복합 PK 제거 (`id` 단일 PK)
  - 잘못된 FK 수정
  - 누락 FK/UNIQUE 추가
  - `event_banner_image.event_id` 제거 (중복 정보 제거)

## 2. 간단 관계 요약

| 부모 | 자식 | 설명 |
|---|---|---|
| `event` | `event_prize`, `event_draw_round`, `event_entry`, `event_win`, `event_banner`, `event_sns`, `event_applicant` | 이벤트 기준 |
| `prize` | `event_prize`, `event_entry`, `event_win` | 경품 마스터 |
| `event_banner` + `event_image_file` | `event_banner_image` | 배너-이미지 매핑 |
| `event_prize` + `event_draw_round` | `event_prize_probability` | 회차별/공통 확률 정책 |

## 3. 간소화 DDL (MySQL 8.x)

```sql
-- 1) 이벤트 마스터
CREATE TABLE event (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(30) NOT NULL,
    start_at DATETIME NOT NULL,
    end_at DATETIME NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    is_recommended BOOLEAN NOT NULL DEFAULT FALSE,
    is_auto_entry BOOLEAN NOT NULL DEFAULT FALSE,
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    is_sns_linked BOOLEAN NOT NULL DEFAULT FALSE,
    event_url VARCHAR(300) NULL,
    description TEXT NULL,
    gift_description VARCHAR(100) NULL,
    supplier_id BIGINT NOT NULL,
    is_winner_announced BOOLEAN NOT NULL DEFAULT FALSE,
    winner_announced_at DATETIME NULL,
    allow_duplicate_winner BOOLEAN NOT NULL DEFAULT FALSE,
    allow_multiple_entry BOOLEAN NOT NULL DEFAULT FALSE,
    priority INT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

-- 2) 경품 마스터
CREATE TABLE prize (
    id BIGINT NOT NULL AUTO_INCREMENT,
    prize_name VARCHAR(100) NOT NULL,
    prize_amount INT NULL,
    prize_description TEXT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    recipient_end_date DATE NULL,
    usage_end_date DATE NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

-- 3) 이벤트별 경품 정책
CREATE TABLE event_prize (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    prize_id BIGINT NOT NULL,
    prize_type VARCHAR(30) NOT NULL,   -- 예: INSTANT, DRAW
    prize_limit INT NOT NULL,
    priority INT NOT NULL DEFAULT 1,   -- 낮을수록 우선
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_prize_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_prize_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    UNIQUE KEY uq_event_prize_event_prize (event_id, prize_id)
) ENGINE=InnoDB;

-- 4) 이벤트 추첨 회차
CREATE TABLE event_draw_round (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    draw_no INT NOT NULL,
    is_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    draw_at DATETIME NULL,
    draw_start_at DATETIME NULL,
    draw_end_at DATETIME NULL,
    announcement_at DATETIME NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_draw_round_event FOREIGN KEY (event_id) REFERENCES event(id),
    UNIQUE KEY uq_draw_round_event_no (event_id, draw_no)
) ENGINE=InnoDB;

-- 5) 이벤트 참여자 기준(선택 가드 테이블)
CREATE TABLE event_applicant (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    draw_id BIGINT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_applicant_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_applicant_draw FOREIGN KEY (draw_id) REFERENCES event_draw_round(id),
    UNIQUE KEY uq_event_applicant_event_member (event_id, member_id)
) ENGINE=InnoDB;

-- 6) 이벤트 응모 이력
CREATE TABLE event_entry (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    entry_id INT NOT NULL,              -- 이벤트 내 응모 순번(업무키)
    member_id BIGINT NOT NULL,
    applied_at DATETIME NOT NULL,
    order_no VARCHAR(30) NULL,
    prize_id BIGINT NULL,               -- 당첨 반영 시 사용(선택)
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    purchase_amount INT NULL,
    order_count INT NULL,
    cancel_count INT NULL,
    description TEXT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_entry_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_entry_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    UNIQUE KEY uq_event_entry_event_entryid (event_id, entry_id),
    KEY idx_event_entry_member (event_id, member_id)
) ENGINE=InnoDB;

-- 7) 이벤트 당첨 결과/후속 처리
CREATE TABLE event_win (
    id BIGINT NOT NULL AUTO_INCREMENT,
    draw_id BIGINT NULL,
    entry_id BIGINT NULL,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    prize_id BIGINT NULL,
    sent_at DATE NULL,
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    received_at DATE NULL,
    is_received BOOLEAN NULL,
    is_email_sent BOOLEAN NOT NULL DEFAULT FALSE,
    is_sms_sent BOOLEAN NOT NULL DEFAULT FALSE,
    confirmed_at DATETIME NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_win_draw FOREIGN KEY (draw_id) REFERENCES event_draw_round(id),
    CONSTRAINT fk_event_win_entry FOREIGN KEY (entry_id) REFERENCES event_entry(id),
    CONSTRAINT fk_event_win_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_win_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    UNIQUE KEY uq_event_win_draw_entry (draw_id, entry_id),
    KEY idx_event_win_event_member (event_id, member_id)
) ENGINE=InnoDB;

-- 8) 이벤트 이미지 파일 메타
CREATE TABLE event_image_file (
    id BIGINT NOT NULL AUTO_INCREMENT,
    file_key VARCHAR(300) NOT NULL,
    original_name VARCHAR(255) NULL,
    content_type VARCHAR(100) NULL,
    file_size BIGINT NULL,
    width INT NULL,
    height INT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_event_image_file_key (file_key)
) ENGINE=InnoDB;

-- 9) 이벤트 배너
CREATE TABLE event_banner (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    channel_type VARCHAR(30) NOT NULL,
    device_type VARCHAR(30) NOT NULL,
    display_location VARCHAR(30) NOT NULL,
    link_url VARCHAR(500) NOT NULL,
    priority INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_banner_event FOREIGN KEY (event_id) REFERENCES event(id),
    KEY idx_event_banner_event_display (event_id, channel_type, device_type, display_location)
) ENGINE=InnoDB;

-- 10) 배너-이미지 매핑 (원본의 event_id 중복 컬럼 제거)
CREATE TABLE event_banner_image (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_file_id BIGINT NOT NULL,
    event_banner_id BIGINT NOT NULL,
    image_variant VARCHAR(30) NOT NULL, -- 예: ORIGINAL, PC, MOBILE
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_banner_image_file FOREIGN KEY (event_file_id) REFERENCES event_image_file(id),
    CONSTRAINT fk_banner_image_banner FOREIGN KEY (event_banner_id) REFERENCES event_banner(id),
    UNIQUE KEY uq_banner_image_variant (event_banner_id, image_variant)
) ENGINE=InnoDB;

-- 11) 이벤트 SNS 공유 메타
CREATE TABLE event_sns (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    sns_code VARCHAR(10) NOT NULL,      -- 예: KAKAO, INSTAGRAM
    title VARCHAR(200) NULL,
    content VARCHAR(1000) NOT NULL,
    sns_url VARCHAR(300) NOT NULL,
    image_url VARCHAR(300) NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at DATETIME NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_sns_event FOREIGN KEY (event_id) REFERENCES event(id),
    UNIQUE KEY uq_event_sns_event_code (event_id, sns_code)
) ENGINE=InnoDB;

-- 12) 경품 확률 정책 (원본 누락 제약 보강)
-- 원본 컬럼명 prize_id는 의미가 모호하여 event_prize_id로 명확화
CREATE TABLE event_prize_probability (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    event_prize_id BIGINT NOT NULL,
    draw_id BIGINT NULL,                 -- NULL = 전체 공통 정책
    probability DECIMAL(5,2) NOT NULL,   -- % 단위 (예: 10.50)
    weight INT NULL,                     -- 가중치 추첨 사용 시
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_prize_probability_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_prize_probability_event_prize FOREIGN KEY (event_prize_id) REFERENCES event_prize(id),
    CONSTRAINT fk_event_prize_probability_draw FOREIGN KEY (draw_id) REFERENCES event_draw_round(id),
    KEY idx_event_prize_probability_lookup (event_id, draw_id, is_active)
) ENGINE=InnoDB;
```

## 4. 예시 데이터 (INSERT)

```sql
-- 이벤트
INSERT INTO event (
    id, event_name, event_type, start_at, end_at,
    is_active, is_visible, is_recommended, is_auto_entry, is_confirmed, is_sns_linked,
    event_url, description, gift_description, supplier_id,
    is_winner_announced, allow_duplicate_winner, allow_multiple_entry, priority
) VALUES
(1001, '봄맞이 럭키드로우', 'DRAW', '2026-03-01 00:00:00', '2026-03-31 23:59:59',
 TRUE, TRUE, TRUE, FALSE, TRUE, TRUE,
 'https://example.com/events/1001', '구매 고객 대상 추첨 이벤트', '참여만 해도 쿠폰 지급', 501,
 FALSE, FALSE, TRUE, 10);

-- 경품 마스터
INSERT INTO prize (id, prize_name, prize_amount, prize_description, is_active, is_deleted)
VALUES
(2001, '5천원 할인쿠폰', 5000, '온라인몰 전용 할인쿠폰', TRUE, FALSE),
(2002, '브랜드 텀블러', 15000, '한정판 굿즈 텀블러', TRUE, FALSE);

-- 이벤트별 경품 정책
INSERT INTO event_prize (id, event_id, prize_id, prize_type, prize_limit, priority, is_active, is_deleted)
VALUES
(3001, 1001, 2001, 'DRAW', 100, 1, TRUE, FALSE),
(3002, 1001, 2002, 'DRAW', 10, 2, TRUE, FALSE);

-- 추첨 회차
INSERT INTO event_draw_round (
    id, event_id, draw_no, is_confirmed, draw_at, draw_start_at, draw_end_at, announcement_at, is_deleted
) VALUES
(4001, 1001, 1, FALSE, NULL, '2026-03-01 00:00:00', '2026-03-15 23:59:59', '2026-03-16 10:00:00', FALSE),
(4002, 1001, 2, FALSE, NULL, '2026-03-16 00:00:00', '2026-03-31 23:59:59', '2026-04-01 10:00:00', FALSE);

-- 참여자 기준(선택)
INSERT INTO event_applicant (id, event_id, member_id, draw_id, is_deleted)
VALUES
(9001, 1001, 30001, NULL, FALSE),
(9002, 1001, 30002, NULL, FALSE);

-- 응모 이력
INSERT INTO event_entry (
    id, event_id, entry_id, member_id, applied_at, order_no, prize_id, is_winner,
    purchase_amount, order_count, cancel_count, description, is_deleted
) VALUES
(10001, 1001, 1, 30001, '2026-03-05 14:10:00', 'ORD202603050001', 2001, TRUE,
 45000, 1, 0, '첫 구매 응모', FALSE),
(10002, 1001, 2, 30002, '2026-03-05 14:15:00', 'ORD202603050002', NULL, FALSE,
 32000, 1, 0, '일반 응모', FALSE);

-- 이미지 파일 메타
INSERT INTO event_image_file (id, file_key, original_name, content_type, file_size, width, height)
VALUES
(5001, 'event/banner/2026/03/event1001_pc.png', 'spring_draw_pc.png', 'image/png', 245120, 1200, 400),
(5002, 'event/banner/2026/03/event1001_mobile.png', 'spring_draw_mobile.png', 'image/png', 128512, 720, 360);

-- 배너 정책
INSERT INTO event_banner (
    id, event_id, channel_type, device_type, display_location, link_url, priority, is_active, is_visible
) VALUES
(6001, 1001, 'SHOP', 'ALL', 'HOME_MAIN', 'https://example.com/events/1001', 1, TRUE, TRUE);

-- 배너 이미지 매핑
INSERT INTO event_banner_image (id, event_file_id, event_banner_id, image_variant)
VALUES
(7001, 5001, 6001, 'PC'),
(7002, 5002, 6001, 'MOBILE');

-- SNS 공유 메타
INSERT INTO event_sns (id, event_id, sns_code, title, content, sns_url, image_url, is_deleted)
VALUES
(8001, 1001, 'KAKAO', '봄맞이 럭키드로우', '지금 참여하고 경품 받아가세요!', 'https://example.com/events/1001', 'https://cdn.example.com/banner1001.png', FALSE),
(8002, 1001, 'INSTA', '봄맞이 럭키드로우', '댓글 참여하고 추첨 혜택 받기', 'https://example.com/events/1001', 'https://cdn.example.com/banner1001.png', FALSE);

-- 경품 확률 정책 (회차별/공통)
INSERT INTO event_prize_probability (
    id, event_id, event_prize_id, draw_id, probability, weight, is_active
) VALUES
(11001, 1001, 3001, 4001, 90.00, 90, TRUE),
(11002, 1001, 3002, 4001, 10.00, 10, TRUE),
(11003, 1001, 3001, 4002, 95.00, 95, TRUE),
(11004, 1001, 3002, 4002, 5.00, 5, TRUE);

-- 당첨 결과
INSERT INTO event_win (
    id, draw_id, entry_id, event_id, member_id, prize_id,
    sent_at, is_sent, received_at, is_received, is_email_sent, is_sms_sent, confirmed_at, is_deleted
) VALUES
(12001, 4001, 10001, 1001, 30001, 2001,
 NULL, FALSE, NULL, NULL, TRUE, TRUE, '2026-03-16 10:10:00', FALSE);
```

## 5. 원본 대비 핵심 개선 요약

| 항목 | 원본 | 개선안 |
|---|---|---|
| PK 설계 | 일부 복합 PK | 전 테이블 단일 PK(`id`) |
| `event_applicant` FK | `id -> event.id` (오류) | `event_id -> event.id` |
| `event_banner_image` | `event_id` 중복 보유 + FK 문제 | `event_id` 제거, `event_banner_id`만 참조 |
| `event_win` | FK 일부 누락 | `draw_id`, `entry_id`, `event_id`, `prize_id` FK 보강 |
| `event_prize_probability` | 제약 누락 | PK/FK/조회 인덱스 추가 |

## 6. 적용 시 참고

1. 운영 DB에 바로 적용하기 전, 원본 데이터와 컬럼 매핑표를 먼저 작성하세요.
2. `event_prize_probability.draw_id IS NULL` 중복 허용 정책은 서비스 로직에서 추가 검증하는 것이 안전합니다.
3. 감사 컬럼(`created_by`, `updated_by`)이 필요하면 현재 DDL에 쉽게 추가할 수 있습니다.

