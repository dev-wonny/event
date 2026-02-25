-- =============================================================
-- [01] S3 파일 메타
-- =============================================================
CREATE TABLE `S3 파일 메타` (
	`id`	BIGSERIAL	NOT NULL,
	`object_key`	VARCHAR(300)	NOT NULL,
	`original_file_name`	VARCHAR(200)	NULL,
	`file_size`	BIGINT	NOT NULL,
	`mime_type`	VARCHAR(50)	NOT NULL,
	`file_extension`	VARCHAR(10)	NOT NULL,
	`checksum_sha256`	VARCHAR(64)	NULL,
	`width`	INTEGER	NULL,
	`height`	INTEGER	NULL,
	`is_public`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [02] 이벤트
-- =============================================================
CREATE TABLE `이벤트` (
	`id`	BIGSERIAL	NOT NULL,
	`supplier_id`	BIGINT	NOT NULL,
	`event_type`	VARCHAR(20)	NOT NULL,
	`title`	VARCHAR(200)	NOT NULL,
	`description`	TEXT	NULL,
	`status`	VARCHAR(20)	NOT NULL	DEFAULT 'DRAFT',
	`is_visible`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`display_order`	INTEGER	NOT NULL	DEFAULT 0,
	`start_at`	TIMESTAMP	NOT NULL,
	`end_at`	TIMESTAMP	NOT NULL,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [03] 이벤트 참여 자격 조건
-- =============================================================
CREATE TABLE `이벤트 참여 자격 조건` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`eligibility_type`	VARCHAR(30)	NOT NULL,
	`eligibility_value`	VARCHAR(200)	NULL,
	`priority`	INTEGER	NOT NULL	DEFAULT 0,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [04] 출석 정책
-- =============================================================
CREATE TABLE `출석 정책` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`total_days`	INTEGER	NOT NULL,
	`allow_missed_days`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`reset_time`	TIME	NOT NULL	DEFAULT '00:00',
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [05] 랜덤 게임 정책
-- =============================================================
CREATE TABLE `랜덤 게임 정책` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`game_type`	VARCHAR(20)	NOT NULL,
	`display_slot_count`	INTEGER	NULL,
	`quiz_question`	TEXT	NULL,
	`quiz_answer`	VARCHAR(200)	NULL,
	`sns_retry_enabled`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [06] 이벤트 보상 카탈로그 (POINT, COUPON, PRODUCT, 꽝, 한번더)
-- =============================================================
CREATE TABLE `이벤트 보상 카탈로그` (
	`id`	BIGSERIAL	NOT NULL,
	`reward_type`	VARCHAR(20)	NOT NULL,
	`reward_name`	VARCHAR(200)	NOT NULL,
	`point_amount`	INTEGER	NULL,
	`coupon_group_id`	BIGINT	NULL,
	`external_ref_id`	BIGINT	NULL,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [07] 이벤트 참여자 (자격 통과 명단)
-- =============================================================
CREATE TABLE `이벤트 참여자` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`member_id`	BIGINT	NOT NULL,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [07b] 이벤트 참여자 차단
-- =============================================================
CREATE TABLE `이벤트 참여자 차단` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`member_id`	BIGINT	NOT NULL,
	`blocked_reason`	TEXT	NOT NULL,
	`unblocked_at`	TIMESTAMP	NULL,
	`unblocked_by`	BIGINT	NULL,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [08] 출석 일일 보상 설정
-- =============================================================
CREATE TABLE `출석 일일 보상 설정` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`reward_catalog_id`	BIGINT	NOT NULL,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [09] 출석 보너스 보상 설정 (누적/연속 마일스톤)
-- =============================================================
CREATE TABLE `출석 보너스 보상 설정` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`milestone_type`	VARCHAR(20)	NOT NULL,
	`milestone_count`	INTEGER	NOT NULL,
	`payout_rule`	VARCHAR(20)	NOT NULL	DEFAULT 'ONCE',
	`reward_catalog_id`	BIGINT	NOT NULL,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [10] 랜덤 보상 풀 (확률 가중치, 수량 제한)
-- =============================================================
CREATE TABLE `랜덤 보상 풀` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`reward_catalog_id`	BIGINT	NOT NULL,
	`probability_weight`	INTEGER	NOT NULL,
	`daily_limit`	INTEGER	NULL,
	`total_limit`	INTEGER	NULL,
	`priority`	INTEGER	NOT NULL	DEFAULT 0,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [11] 랜덤 보상 풀 당첨 카운터 (일일/전체 제한 추적)
-- =============================================================
CREATE TABLE `랜덤 보상 풀 당첨 카운터` (
	`reward_pool_id`	BIGINT	NOT NULL,
	`daily_count`	INTEGER	NOT NULL	DEFAULT 0,
	`total_count`	INTEGER	NOT NULL	DEFAULT 0,
	`last_reset_date`	DATE	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	PRIMARY KEY (`reward_pool_id`)
);

-- =============================================================
-- [12] SNS 공유 정책
-- =============================================================
CREATE TABLE `SNS 공유 정책` (
	`event_id`	BIGINT	NOT NULL,
	`max_share_credit`	INTEGER	NOT NULL	DEFAULT 0,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`event_id`)
);

-- =============================================================
-- [13] SNS 공유 링크 클릭 로그
-- =============================================================
CREATE TABLE `SNS 공유 링크 클릭 로그` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`share_token`	VARCHAR(200)	NOT NULL,
	`sharer_member_id`	BIGINT	NOT NULL,
	`visitor_member_id`	BIGINT	NULL,
	`share_channel`	VARCHAR(20)	NOT NULL,
	`ip_address`	VARCHAR(50)	NULL,
	`user_agent`	TEXT	NULL,
	`created_at`	TIMESTAMP	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [14] 이벤트 참여 행위 로그 - 출석/랜덤 통합 (append-only)
-- =============================================================
CREATE TABLE `이벤트 참여 행위 로그` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`event_type`	VARCHAR(20)	NOT NULL,
	`member_id`	BIGINT	NOT NULL,
	`action_result`	VARCHAR(30)	NOT NULL,
	`failure_reason`	TEXT	NULL,
	`attendance_date`	DATE	NULL,
	`total_attendance_count`	INTEGER	NULL,
	`streak_attendance_count`	INTEGER	NULL,
	`trigger_type`	VARCHAR(20)	NULL,
	`reward_pool_id`	BIGINT	NULL,
	`created_at`	TIMESTAMP	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [15] 보상 지급 의뢰 (Queue 발행 기록, append-only)
-- =============================================================
CREATE TABLE `보상 지급 의뢰` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`event_type`	VARCHAR(20)	NOT NULL,
	`member_id`	BIGINT	NOT NULL,
	`event_entry_id`	BIGINT	NOT NULL,
	`reward_kind`	VARCHAR(20)	NOT NULL,
	`daily_reward_id`	BIGINT	NULL,
	`bonus_reward_id`	BIGINT	NULL,
	`milestone_type`	VARCHAR(20)	NULL,
	`milestone_count`	INTEGER	NULL,
	`reward_pool_id`	BIGINT	NULL,
	`probability_weight`	INTEGER	NULL,
	`reward_type`	VARCHAR(20)	NOT NULL,
	`point_amount`	INTEGER	NULL,
	`coupon_group_id`	BIGINT	NULL,
	`external_ref_id`	BIGINT	NULL,
	`idempotency_key`	VARCHAR(120)	NOT NULL,
	`created_at`	TIMESTAMP	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [16] 이벤트 참여 제한 정책 (횟수/인원 제한)
-- =============================================================
CREATE TABLE `이벤트 참여 제한 정책` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`limit_subject`	VARCHAR(20)	NOT NULL,
	`limit_scope`	VARCHAR(20)	NOT NULL,
	`limit_metric`	VARCHAR(20)	NOT NULL,
	`limit_value`	INTEGER	NOT NULL,
	`priority`	INTEGER	NOT NULL	DEFAULT 0,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [17] 이벤트 안내 메시지
-- =============================================================
CREATE TABLE `이벤트 안내 메시지` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NULL,
	`message_type`	VARCHAR(100)	NOT NULL,
	`text`	TEXT	NOT NULL,
	`lang_code`	VARCHAR(10)	NOT NULL	DEFAULT 'ko',
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);

-- =============================================================
-- [18] 이벤트 UI 이미지 에셋
-- =============================================================
CREATE TABLE `이벤트 UI 이미지 에셋` (
	`id`	BIGSERIAL	NOT NULL,
	`event_id`	BIGINT	NOT NULL,
	`file_id`	BIGINT	NOT NULL,
	`asset_type`	VARCHAR(40)	NOT NULL,
	`display_width`	INTEGER	NULL,
	`display_height`	INTEGER	NULL,
	`sort_order`	INTEGER	NOT NULL	DEFAULT 0,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT TRUE,
	`is_deleted`	BOOLEAN	NOT NULL	DEFAULT FALSE,
	`created_at`	TIMESTAMP	NOT NULL,
	`created_by`	BIGINT	NOT NULL,
	`updated_at`	TIMESTAMP	NOT NULL,
	`updated_by`	BIGINT	NOT NULL,
	PRIMARY KEY (`id`)
);
