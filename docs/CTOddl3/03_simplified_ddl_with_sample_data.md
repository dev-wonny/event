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

## 7. 랜덤/출석 정책 확장 설계 (추가안)

### 7.1 설계 방향 (복잡하지 않게)

기존 공통 테이블은 유지하고, 이벤트 유형별 정책만 서브테이블로 분리합니다.

- 공통 유지: `event`, `event_entry`, `event_win`, `prize`
- 랜덤 전용: `event_random_policy`, `event_random_reward_pool` (+ 운영 로그/카운터)
- 출석 전용: `event_attendance_policy`, `event_attendance_daily_reward`, `event_attendance_bonus_reward` (+ 참여/출석 로그)

권장 `event.event_type` 값 확장:

- `DRAW` (기존 추첨형)
- `RANDOM_REWARD` (룰렛/사다리/스크래치 등 즉시 랜덤 보상)
- `ATTENDANCE` (출석 체크형)

주의:

- `event_type`와 서브 정책 테이블 정합성(`RANDOM_REWARD`이면 random policy 1건 필수 등)은 **DB 단독으로 강제하기 어렵기 때문에 애플리케이션 + 배치 검증**으로 관리하는 것이 현실적입니다.

### 7.2 공통 테이블과 연결 방식

| 기능 | 사용하는 공통 테이블 | 설명 |
|---|---|---|
| 랜덤 참여 시도 | `event_entry` (선택) | 스핀/게임 참여 이력 공통화 가능 |
| 랜덤 당첨 결과 | `event_win` (선택) | 실물/발송 대상 보상일 때만 저장 권장 |
| 출석 참여자 관리 | `event_applicant` 또는 별도 `event_attendance_participant` | 출석은 상태/누적치가 있어 별도 테이블 권장 |
| 출석 로그 | 별도 `event_attendance_log` | 하루 1회 체크 인덱스 필요 |

## 8. 랜덤 정책 확장 DDL (MySQL 8.x)

### 8.1 랜덤 이벤트 정책 (1:1)

```sql
CREATE TABLE event_random_policy (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    game_type VARCHAR(20) NOT NULL,      -- ROULETTE, LADDER, SCRATCH, SLOT ...
    draw_mode VARCHAR(20) NOT NULL DEFAULT 'WEIGHT', -- WEIGHT 고정 사용 권장
    per_member_daily_limit INT NOT NULL DEFAULT 1,
    per_member_total_limit INT NULL,     -- NULL = 무제한
    allow_retry BOOLEAN NOT NULL DEFAULT FALSE,
    retry_trigger_type VARCHAR(20) NULL, -- 예: SNS_SHARE, AD_VIEW
    reset_time TIME NOT NULL DEFAULT '00:00:00',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_random_policy_event FOREIGN KEY (event_id) REFERENCES event(id),
    UNIQUE KEY uq_event_random_policy_event (event_id)
) ENGINE=InnoDB;
```

### 8.2 랜덤 보상 풀 (가중치/수량 제한)

설계 포인트:

- `reward_type`으로 꽝/한번더/실물경품/포인트/쿠폰을 단순 구분
- 실물경품은 `prize_id`로 연결 가능
- 포인트/쿠폰은 컬럼 값으로 간단히 표현

```sql
CREATE TABLE event_random_reward_pool (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    reward_name VARCHAR(100) NOT NULL,        -- UI 표시명
    reward_type VARCHAR(20) NOT NULL,         -- PRIZE, POINT, COUPON, NONE, ONEMORE
    prize_id BIGINT NULL,                     -- reward_type=PRIZE일 때 사용
    point_amount INT NULL,                    -- reward_type=POINT일 때 사용
    coupon_group_id BIGINT NULL,              -- reward_type=COUPON일 때 사용
    one_more_count INT NULL,                  -- reward_type=ONEMORE일 때 사용
    probability_weight INT NOT NULL,          -- 가중치 (예: 60, 30, 10)
    daily_limit INT NULL,                     -- 일일 지급 제한
    total_limit INT NULL,                     -- 전체 지급 제한
    priority INT NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_random_reward_pool_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_random_reward_pool_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    KEY idx_random_reward_pool_event (event_id, is_active, priority)
) ENGINE=InnoDB;
```

### 8.3 랜덤 보상 카운터 (운영 성능용, 권장)

```sql
CREATE TABLE event_random_reward_counter (
    id BIGINT NOT NULL AUTO_INCREMENT,
    reward_pool_id BIGINT NOT NULL,
    daily_count INT NOT NULL DEFAULT 0,
    total_count INT NOT NULL DEFAULT 0,
    last_reset_date DATE NOT NULL,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_random_reward_counter_pool FOREIGN KEY (reward_pool_id) REFERENCES event_random_reward_pool(id),
    UNIQUE KEY uq_event_random_reward_counter_pool (reward_pool_id)
) ENGINE=InnoDB;
```

### 8.4 랜덤 보상 로그 (운영/통계용, 권장)

`event_entry`로도 기본 참여 이력은 남길 수 있지만, 랜덤 이벤트는 꽝/재시도/트리거 유형까지 추적해야 하므로 별도 로그를 두는 편이 운영에 유리합니다.

```sql
CREATE TABLE event_random_reward_log (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    entry_id BIGINT NULL,                     -- event_entry.id 연결 (선택)
    trigger_type VARCHAR(20) NOT NULL DEFAULT 'BASE', -- BASE, SNS_SHARE, RETRY
    reward_pool_id BIGINT NOT NULL,
    reward_type VARCHAR(20) NOT NULL,         -- 결과 스냅샷
    prize_id BIGINT NULL,
    point_amount INT NULL,
    coupon_group_id BIGINT NULL,
    is_winner BOOLEAN NOT NULL DEFAULT FALSE, -- NONE 제외 편의 플래그
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_random_reward_log_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_random_reward_log_entry FOREIGN KEY (entry_id) REFERENCES event_entry(id),
    CONSTRAINT fk_event_random_reward_log_pool FOREIGN KEY (reward_pool_id) REFERENCES event_random_reward_pool(id),
    CONSTRAINT fk_event_random_reward_log_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    KEY idx_event_random_reward_log_event_member (event_id, member_id, created_at)
) ENGINE=InnoDB;
```

## 9. 출석 정책 확장 DDL (MySQL 8.x)

### 9.1 출석 정책 (1:1)

```sql
CREATE TABLE event_attendance_policy (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    total_days INT NOT NULL,                  -- 7일, 15일, 30일
    allow_missed_days BOOLEAN NOT NULL DEFAULT FALSE,
    reset_time TIME NOT NULL DEFAULT '00:00:00',
    timezone_code VARCHAR(40) NOT NULL DEFAULT 'Asia/Seoul',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_policy_event FOREIGN KEY (event_id) REFERENCES event(id),
    UNIQUE KEY uq_event_attendance_policy_event (event_id)
) ENGINE=InnoDB;
```

### 9.2 출석 일일 보상 (기본 보상, 1:1)

```sql
CREATE TABLE event_attendance_daily_reward (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    reward_type VARCHAR(20) NOT NULL,         -- POINT, COUPON, PRIZE, NONE
    prize_id BIGINT NULL,
    point_amount INT NULL,
    coupon_group_id BIGINT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_daily_reward_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_attendance_daily_reward_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    UNIQUE KEY uq_event_attendance_daily_reward_event (event_id)
) ENGINE=InnoDB;
```

### 9.3 출석 보너스 보상 (누적/연속)

```sql
CREATE TABLE event_attendance_bonus_reward (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    milestone_count INT NOT NULL,             -- 예: 3, 7, 30
    milestone_type VARCHAR(20) NOT NULL,      -- TOTAL, STREAK
    payout_rule VARCHAR(20) NOT NULL DEFAULT 'ONCE', -- ONCE, REPEATABLE
    reward_type VARCHAR(20) NOT NULL,         -- POINT, COUPON, PRIZE
    prize_id BIGINT NULL,
    point_amount INT NULL,
    coupon_group_id BIGINT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_bonus_reward_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_attendance_bonus_reward_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    UNIQUE KEY uq_event_attendance_bonus_reward (event_id, milestone_type, milestone_count),
    KEY idx_event_attendance_bonus_reward_event (event_id, is_active, milestone_type, milestone_count)
) ENGINE=InnoDB;
```

### 9.4 출석 참여자 상태 (권장)

출석은 “현재 연속일수/누적일수”를 빠르게 조회해야 하므로 `event_applicant` 재사용보다 별도 테이블이 단순합니다.

```sql
CREATE TABLE event_attendance_participant (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    enroll_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, BLOCKED, CANCELLED
    enrolled_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    first_attendance_date DATE NULL,
    last_attendance_date DATE NULL,
    total_attendance_count INT NOT NULL DEFAULT 0,
    current_streak_count INT NOT NULL DEFAULT 0,
    max_streak_count INT NOT NULL DEFAULT 0,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_participant_event FOREIGN KEY (event_id) REFERENCES event(id),
    UNIQUE KEY uq_event_attendance_participant (event_id, member_id),
    KEY idx_event_attendance_participant_status (event_id, enroll_status)
) ENGINE=InnoDB;
```

### 9.5 출석 로그 (하루 1회 체크)

```sql
CREATE TABLE event_attendance_log (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    participant_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,            -- 정책 timezone 기준 날짜
    checked_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,   -- 운영 보정 대비
    note VARCHAR(255) NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_log_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_attendance_log_participant FOREIGN KEY (participant_id) REFERENCES event_attendance_participant(id),
    UNIQUE KEY uq_event_attendance_log_once_per_day (event_id, member_id, attendance_date),
    KEY idx_event_attendance_log_event_member (event_id, member_id, checked_at)
) ENGINE=InnoDB;
```

### 9.6 출석 보상 지급 로그 (중복 방지/감사용, 권장)

`bonus_reward.payout_rule = ONCE`를 정확히 보장하려면 지급 로그가 있으면 운영이 쉬워집니다.

```sql
CREATE TABLE event_attendance_reward_log (
    id BIGINT NOT NULL AUTO_INCREMENT,
    event_id BIGINT NOT NULL,
    member_id BIGINT NOT NULL,
    attendance_log_id BIGINT NULL,            -- DAILY 보상 지급 근거
    bonus_reward_id BIGINT NULL,              -- BONUS 보상 지급 근거
    reward_source_type VARCHAR(20) NOT NULL,  -- DAILY, BONUS
    reward_type VARCHAR(20) NOT NULL,         -- PRIZE, POINT, COUPON
    prize_id BIGINT NULL,
    point_amount INT NULL,
    coupon_group_id BIGINT NULL,
    granted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_event_attendance_reward_log_event FOREIGN KEY (event_id) REFERENCES event(id),
    CONSTRAINT fk_event_attendance_reward_log_att_log FOREIGN KEY (attendance_log_id) REFERENCES event_attendance_log(id),
    CONSTRAINT fk_event_attendance_reward_log_bonus FOREIGN KEY (bonus_reward_id) REFERENCES event_attendance_bonus_reward(id),
    CONSTRAINT fk_event_attendance_reward_log_prize FOREIGN KEY (prize_id) REFERENCES prize(id),
    KEY idx_event_attendance_reward_log_member (event_id, member_id, granted_at),
    UNIQUE KEY uq_attendance_daily_reward_once (attendance_log_id),
    UNIQUE KEY uq_attendance_bonus_reward_once (member_id, bonus_reward_id, reward_source_type)
) ENGINE=InnoDB;
```

## 10. 랜덤/출석 정책 예시 데이터 (추가)

아래 예시는 기존 `event`, `prize` 테이블에 랜덤 이벤트/출석 이벤트를 추가하는 샘플입니다.

```sql
-- 랜덤 이벤트 / 출석 이벤트 추가
INSERT INTO event (
    id, event_name, event_type, start_at, end_at,
    is_active, is_visible, is_recommended, is_auto_entry, is_confirmed, is_sns_linked,
    event_url, description, gift_description, supplier_id,
    is_winner_announced, allow_duplicate_winner, allow_multiple_entry, priority
) VALUES
(1002, '룰렛 랜덤 리워드', 'RANDOM_REWARD', '2026-04-01 00:00:00', '2026-04-30 23:59:59',
 TRUE, TRUE, FALSE, FALSE, TRUE, FALSE,
 'https://example.com/events/1002', '룰렛 참여형 랜덤 보상 이벤트', '참여 즉시 보상 지급', 501,
 FALSE, TRUE, TRUE, 20),
(1003, '7일 출석 체크', 'ATTENDANCE', '2026-04-01 00:00:00', '2026-04-30 23:59:59',
 TRUE, TRUE, TRUE, FALSE, TRUE, FALSE,
 'https://example.com/events/1003', '매일 출석 시 포인트 + 보너스 지급', '7일 연속/누적 보너스', 501,
 FALSE, FALSE, FALSE, 30);

-- 랜덤/출석용 경품(필요 시)
INSERT INTO prize (id, prize_name, prize_amount, prize_description, is_active, is_deleted)
VALUES
(2003, '랜덤 굿즈 박스', 30000, '랜덤 이벤트 실물 경품', TRUE, FALSE),
(2004, '출석 완주 기념 쿠폰', 10000, '출석 보너스 쿠폰', TRUE, FALSE);

-- 랜덤 정책 (룰렛)
INSERT INTO event_random_policy (
    id, event_id, game_type, draw_mode, per_member_daily_limit, per_member_total_limit,
    allow_retry, retry_trigger_type, reset_time, is_active, is_deleted
) VALUES
(13001, 1002, 'ROULETTE', 'WEIGHT', 3, 30, TRUE, 'SNS_SHARE', '00:00:00', TRUE, FALSE);

-- 랜덤 보상 풀 (포인트/실물/꽝)
INSERT INTO event_random_reward_pool (
    id, event_id, reward_name, reward_type, prize_id, point_amount, coupon_group_id, one_more_count,
    probability_weight, daily_limit, total_limit, priority, is_active, is_deleted
) VALUES
(13101, 1002, '포인트 100P', 'POINT', NULL, 100, NULL, NULL, 60, NULL, NULL, 1, TRUE, FALSE),
(13102, 1002, '랜덤 굿즈 박스', 'PRIZE', 2003, NULL, NULL, NULL, 10, 5, 50, 2, TRUE, FALSE),
(13103, 1002, '한번 더!', 'ONEMORE', NULL, NULL, NULL, 1, 10, NULL, NULL, 3, TRUE, FALSE),
(13104, 1002, '꽝', 'NONE', NULL, NULL, NULL, NULL, 20, NULL, NULL, 4, TRUE, FALSE);

-- 랜덤 카운터 초기화
INSERT INTO event_random_reward_counter (
    id, reward_pool_id, daily_count, total_count, last_reset_date
) VALUES
(13201, 13101, 0, 0, '2026-04-01'),
(13202, 13102, 0, 0, '2026-04-01'),
(13203, 13103, 0, 0, '2026-04-01'),
(13204, 13104, 0, 0, '2026-04-01');

-- 출석 정책 (7일)
INSERT INTO event_attendance_policy (
    id, event_id, total_days, allow_missed_days, reset_time, timezone_code,
    is_active, is_deleted
) VALUES
(14001, 1003, 7, FALSE, '00:00:00', 'Asia/Seoul', TRUE, FALSE);

-- 출석 일일 보상 (매일 30P)
INSERT INTO event_attendance_daily_reward (
    id, event_id, reward_type, prize_id, point_amount, coupon_group_id, is_active, is_deleted
) VALUES
(14101, 1003, 'POINT', NULL, 30, NULL, TRUE, FALSE);

-- 출석 보너스 보상 (3일 누적 100P, 7일 완주 쿠폰)
INSERT INTO event_attendance_bonus_reward (
    id, event_id, milestone_count, milestone_type, payout_rule,
    reward_type, prize_id, point_amount, coupon_group_id, is_active, is_deleted
) VALUES
(14201, 1003, 3, 'TOTAL', 'ONCE', 'POINT', NULL, 100, NULL, TRUE, FALSE),
(14202, 1003, 7, 'TOTAL', 'ONCE', 'PRIZE', 2004, NULL, NULL, TRUE, FALSE);

-- 출석 참여자/출석 로그 예시
INSERT INTO event_attendance_participant (
    id, event_id, member_id, enroll_status, enrolled_at,
    first_attendance_date, last_attendance_date,
    total_attendance_count, current_streak_count, max_streak_count, is_deleted
) VALUES
(14301, 1003, 30001, 'ACTIVE', '2026-04-01 09:00:00',
 '2026-04-01', '2026-04-02', 2, 2, 2, FALSE);

INSERT INTO event_attendance_log (
    id, event_id, member_id, participant_id, attendance_date, checked_at, is_valid, note
) VALUES
(14401, 1003, 30001, 14301, '2026-04-01', '2026-04-01 09:01:00', TRUE, NULL),
(14402, 1003, 30001, 14301, '2026-04-02', '2026-04-02 08:55:00', TRUE, NULL);

-- 출석 보상 지급 로그 예시 (일일 보상 + 3일 보너스는 아직 미도달)
INSERT INTO event_attendance_reward_log (
    id, event_id, member_id, attendance_log_id, bonus_reward_id, reward_source_type,
    reward_type, prize_id, point_amount, coupon_group_id, granted_at
) VALUES
(14501, 1003, 30001, 14401, NULL, 'DAILY', 'POINT', NULL, 30, NULL, '2026-04-01 09:01:01'),
(14502, 1003, 30001, 14402, NULL, 'DAILY', 'POINT', NULL, 30, NULL, '2026-04-02 08:55:01');
```

## 11. 구현 시 결정해야 할 항목 (중요)

랜덤/출석 정책을 실제로 넣을 때 아래는 먼저 확정해야 합니다.

1. 랜덤 참여 로그를 `event_entry`로 통합할지, `event_random_reward_log`만 사용할지
2. 랜덤 보상에서 `POINT`/`COUPON` 지급을 별도 결제/쿠폰 시스템과 어떻게 연동할지
3. 출석 이벤트의 누락 허용(`allow_missed_days`) 시 보너스 계산 기준을 `TOTAL`/`STREAK` 각각 어떻게 적용할지
4. 출석 보너스 `REPEATABLE` 허용 시 `event_attendance_reward_log` 중복 키 전략을 더 세분화할지

실무에서는 1번과 4번을 먼저 정하면 나머지 테이블/인덱스 설계가 훨씬 안정됩니다.
