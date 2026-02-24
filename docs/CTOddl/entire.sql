CREATE TABLE `prize` (
	`id`	BIGINT	NULL,
	`prize_name`	VARCHAR(100)	NOT NULL	COMMENT '경품명',
	`prize_amount`	INTEGER	NULL	COMMENT '경품',
	`prize_description`	TEXT	NULL	COMMENT '경품',
	`is_active`	BOOLEAN	NOT NULL	COMMENT '경품',
	`is_deleted`	BOOLEAN	NOT NULL,
	`recipient_end_date`	DATE	NULL	COMMENT '경품',
	`usage_end_date`	DATE	NULL	COMMENT '경품',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL
);

CREATE TABLE `event_banner_image` (
	`id`	BIGINT	NULL,
	`event_file_id`	BIGINT	NULL,
	`event_banner_id`	BIGINT	NULL,
	`event_id`	BIGINT	NULL,
	`image_variant`	VARCHAR(30)	NOT NULL	COMMENT '이미지',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '수정',
	`updated_by`	BIGINT	NOT NULL	COMMENT '수정자'
);

CREATE TABLE `event_prize` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL,
	`prize_id`	BIGINT	NOT NULL,
	`prize_type`	VARCHAR(30)	NOT NULL	COMMENT 'code_group(domain:EVENT, group_code:PRIZE_TYPE)',
	`prize_limit`	INTEGER	NOT NULL,
	`priority`	INTEGER	NOT NULL	COMMENT '낮을수록 우선',
	`is_active`	BOOLEAN	NOT NULL,
	`is_deleted`	BOOLEAN	NOT NULL,
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

CREATE TABLE `event_entry` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL	COMMENT '이벤트',
	`entry_id`	INTEGER	NOT NULL	COMMENT '이벤트',
	`member_id`	BIGINT	NOT NULL	COMMENT '응모자(회원)',
	`applied_at`	TIMESTAMP	NOT NULL	COMMENT '이벤트',
	`order_no`	VARCHAR(30)	NULL	COMMENT '연관',
	`prize_id`	BIGINT	NULL	COMMENT '당첨된',
	`is_winner`	BOOLEAN	NOT NULL	COMMENT '당첨',
	`purchase_amount`	INTEGER	NULL	COMMENT '응모',
	`order_count`	INTEGER	NULL	COMMENT '응모',
	`cancel_count`	INTEGER	NULL	COMMENT '응모',
	`description`	TEXT	NULL	COMMENT '응모',
	`is_deleted`	BOOLEAN	NOT NULL	COMMENT '논리',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

CREATE TABLE `event_prize_probability` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL	COMMENT '이벤트식별자',
	`prize_id`	BIGINT	NOT NULL	COMMENT '이벤트경품식별자',
	`draw_id`	BIGINT	NULL	COMMENT '적용추첨회차식별자(NULL시전체공통)',
	`probability`	NUMERIC(5,2)	NOT NULL	COMMENT '당첨확률(%)',
	`weight`	INTEGER	NULL	COMMENT '가중치기반추첨용값',
	`is_active`	BOOLEAN	NOT NULL	COMMENT '확률정책사용여부',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록일시',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자식별자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '수정일시',
	`updated_by`	BIGINT	NOT NULL	COMMENT '수정자식별자'
);

CREATE TABLE `event_applicant` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL	COMMENT '이벤트',
	`member_id`	BIGINT	NOT NULL	COMMENT '참여자(회원)',
	`draw_id`	BIGINT	NULL,
	`is_deleted`	BOOLEAN	NOT NULL	COMMENT '참여자',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

CREATE TABLE `event` (
	`id`	BIGINT	NULL,
	`event_name`	VARCHAR(100)	NOT NULL	COMMENT '이벤트명',
	`event_type`	VARCHAR(30)	NOT NULL	COMMENT '이벤트',
	`start_at`	TIMESTAMP	NOT NULL	COMMENT '이벤트',
	`end_at`	TIMESTAMP	NOT NULL	COMMENT '이벤트',
	`is_active`	BOOLEAN	NOT NULL	COMMENT '이벤트',
	`is_visible`	BOOLEAN	NOT NULL	COMMENT '전시',
	`is_recommended`	BOOLEAN	NOT NULL	COMMENT '추천',
	`is_auto_entry`	BOOLEAN	NOT NULL	COMMENT '자동',
	`is_confirmed`	BOOLEAN	NOT NULL	COMMENT '이벤트',
	`is_sns_linked`	BOOLEAN	NOT NULL	COMMENT 'SNS',
	`event_url`	VARCHAR(300)	NULL	COMMENT '이벤트',
	`description`	TEXT	NULL	COMMENT '이벤트',
	`gift_description`	VARCHAR(100)	NULL	COMMENT '증정',
	`supplier_id`	BIGINT	NOT NULL	COMMENT '업체번호',
	`is_winner_announced`	BOOLEAN	NOT NULL	COMMENT '당첨자',
	`winner_announced_at`	TIMESTAMP	NULL	COMMENT '당첨자',
	`allow_duplicate_winner`	BOOLEAN	NOT NULL	COMMENT '당첨자',
	`allow_multiple_entry`	BOOLEAN	NOT NULL	COMMENT '복수',
	`winner_selection_cycle`	TIMESTAMP	NULL	COMMENT '당첨자',
	`winner_selection_base_at`	TIMESTAMP	NULL	COMMENT '당첨자',
	`priority`	INTEGER	NULL	COMMENT '전시',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종'
);

CREATE TABLE `event_image_file` (
	`id`	BIGINT	NULL,
	`file_key`	VARCHAR(300)	NOT NULL	COMMENT 'S3',
	`original_name`	VARCHAR(255)	NULL	COMMENT '업로드',
	`content_type`	VARCHAR(30)	NULL	COMMENT '파일',
	`file_size`	BIGINT	NULL	COMMENT '파일',
	`width`	INTEGER	NULL	COMMENT '이미지',
	`height`	INTEGER	NULL	COMMENT '이미지',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '수정',
	`updated_by`	BIGINT	NOT NULL	COMMENT '수정자'
);

CREATE TABLE `event_sns` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL,
	`sns_code`	VARCHAR(10)	NOT NULL	COMMENT 'SNS',
	`title`	VARCHAR(200)	NULL	COMMENT 'SNS',
	`content`	VARCHAR(1000)	NOT NULL	COMMENT 'SNS',
	`sns_url`	VARCHAR(200)	NOT NULL	COMMENT 'SNS',
	`image_url`	VARCHAR(200)	NULL	COMMENT 'SNS',
	`is_deleted`	BOOLEAN	NOT NULL,
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

CREATE TABLE `event_banner` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NULL,
	`channel_type`	VARCHAR(30)	NOT NULL	COMMENT '배너',
	`device_type`	VARCHAR(30)	NOT NULL	COMMENT '배너',
	`display_location`	VARCHAR(30)	NOT NULL	COMMENT '배너',
	`link_url`	VARCHAR(500)	NOT NULL	COMMENT '배너',
	`priority`	INTEGER	NOT NULL	COMMENT '배너',
	`is_active`	BOOLEAN	NOT NULL	COMMENT '배너',
	`is_visible`	BOOLEAN	NULL,
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '수정',
	`updated_by`	BIGINT	NOT NULL	COMMENT '수정자'
);

CREATE TABLE `event_draw_round` (
	`id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL	COMMENT '이벤트',
	`draw_no`	INTEGER	NOT NULL	COMMENT '이벤트',
	`is_confirmed`	BOOLEAN	NOT NULL	COMMENT '당첨자',
	`draw_at`	TIMESTAMP	NULL	COMMENT '추첨',
	`draw_start_at`	TIMESTAMP	NULL	COMMENT '추첨',
	`draw_end_at`	TIMESTAMP	NULL	COMMENT '추첨',
	`announcement_at`	TIMESTAMP	NULL	COMMENT '당첨자',
	`is_deleted`	BOOLEAN	NOT NULL	COMMENT '논리',
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

CREATE TABLE `event_win` (
	`id`	BIGINT	NULL,
	`draw_id`	BIGINT	NULL,
	`entry_id`	BIGINT	NULL,
	`event_id`	BIGINT	NOT NULL	COMMENT '이벤트',
	`member_id`	BIGINT	NOT NULL	COMMENT '당첨자(회원)',
	`prize_id`	BIGINT	NULL	COMMENT '당첨',
	`sent_at`	DATE	NULL	COMMENT '경품',
	`is_sent`	BOOLEAN	NOT NULL	COMMENT '경품',
	`received_at`	DATE	NULL	COMMENT '경품',
	`is_received`	BOOLEAN	NULL	COMMENT '경품',
	`is_email_sent`	BOOLEAN	NOT NULL	COMMENT '당첨',
	`is_sms_sent`	BOOLEAN	NOT NULL	COMMENT '당첨',
	`confirmed_at`	TIMESTAMP	NULL	COMMENT '회원별',
	`is_deleted`	BOOLEAN	NOT NULL,
	`created_at`	TIMESTAMP	NOT NULL	COMMENT '등록',
	`created_by`	BIGINT	NOT NULL	COMMENT '등록자',
	`updated_at`	TIMESTAMP	NOT NULL	COMMENT '최종',
	`updated_by`	BIGINT	NOT NULL	COMMENT '최종',
	`deleted_at`	TIMESTAMP	NULL	COMMENT '삭제'
);

ALTER TABLE `prize` ADD CONSTRAINT `PK_PRIZE` PRIMARY KEY (
	`id`
);

ALTER TABLE `event_banner_image` ADD CONSTRAINT `PK_EVENT_BANNER_IMAGE` PRIMARY KEY (
	`id`,
	`event_file_id`,
	`event_banner_id`,
	`event_id`
);

ALTER TABLE `event_prize` ADD CONSTRAINT `PK_EVENT_PRIZE` PRIMARY KEY (
	`id`,
	`event_id`,
	`prize_id`
);

ALTER TABLE `event_entry` ADD CONSTRAINT `PK_EVENT_ENTRY` PRIMARY KEY (
	`id`
);

ALTER TABLE `event_applicant` ADD CONSTRAINT `PK_EVENT_APPLICANT` PRIMARY KEY (
	`id`
);

ALTER TABLE `event` ADD CONSTRAINT `PK_EVENT` PRIMARY KEY (
	`id`
);

ALTER TABLE `event_image_file` ADD CONSTRAINT `PK_EVENT_IMAGE_FILE` PRIMARY KEY (
	`id`
);

ALTER TABLE `event_sns` ADD CONSTRAINT `PK_EVENT_SNS` PRIMARY KEY (
	`id`,
	`event_id`
);

ALTER TABLE `event_banner` ADD CONSTRAINT `PK_EVENT_BANNER` PRIMARY KEY (
	`id`,
	`event_id`
);

ALTER TABLE `event_draw_round` ADD CONSTRAINT `PK_EVENT_DRAW_ROUND` PRIMARY KEY (
	`id`
);

ALTER TABLE `event_win` ADD CONSTRAINT `PK_EVENT_WIN` PRIMARY KEY (
	`id`,
	`draw_id`
);

ALTER TABLE `event_banner_image` ADD CONSTRAINT `FK_event_image_file_TO_event_banner_image_1` FOREIGN KEY (
	`event_file_id`
)
REFERENCES `event_image_file` (
	`id`
);

ALTER TABLE `event_banner_image` ADD CONSTRAINT `FK_event_banner_TO_event_banner_image_1` FOREIGN KEY (
	`event_banner_id`
)
REFERENCES `event_banner` (
	`id`
);

ALTER TABLE `event_banner_image` ADD CONSTRAINT `FK_event_banner_TO_event_banner_image_2` FOREIGN KEY (
	`event_id`
)
REFERENCES `event_banner` (
	`event_id`
);

ALTER TABLE `event_prize` ADD CONSTRAINT `FK_event_TO_event_prize_1` FOREIGN KEY (
	`event_id`
)
REFERENCES `event` (
	`id`
);

ALTER TABLE `event_prize` ADD CONSTRAINT `FK_prize_TO_event_prize_1` FOREIGN KEY (
	`prize_id`
)
REFERENCES `prize` (
	`id`
);

ALTER TABLE `event_applicant` ADD CONSTRAINT `FK_event_TO_event_applicant_1` FOREIGN KEY (
	`id`
)
REFERENCES `event` (
	`id`
);

ALTER TABLE `event_sns` ADD CONSTRAINT `FK_event_TO_event_sns_1` FOREIGN KEY (
	`event_id`
)
REFERENCES `event` (
	`id`
);

ALTER TABLE `event_banner` ADD CONSTRAINT `FK_event_TO_event_banner_1` FOREIGN KEY (
	`event_id`
)
REFERENCES `event` (
	`id`
);

ALTER TABLE `event_win` ADD CONSTRAINT `FK_event_draw_round_TO_event_win_1` FOREIGN KEY (
	`draw_id`
)
REFERENCES `event_draw_round` (
	`id`
);

