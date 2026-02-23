# event_attendance_reward_log

- event_attendance_log는 출석 시도 로그
- event_attendance_history는 출석 성공 확정
- event_attendance_reward_log는 보상 지급 실행/재시도 로그

```sql
CREATE TABLE event_platform.event_attendance_reward_log (
    id BIGSERIAL PRIMARY KEY,

    -- 출석 성공 확정 row (1일 1회 성공)
    attendance_history_id BIGINT NOT NULL
        REFERENCES event_platform.event_attendance_history(id) ON DELETE CASCADE,

    -- 추적/조회 편의용 (denormalized snapshot)
    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,
    member_id BIGINT NOT NULL,
    attendance_date DATE NOT NULL,

    -- DAILY / BONUS 각각 1개씩 가능
    reward_kind VARCHAR(20) NOT NULL
        CHECK (reward_kind IN ('DAILY', 'BONUS')),

    -- 실제 지급 대상 보상 타입 (NONE 은 row 생성 안 하는 방식 권장)
    reward_type VARCHAR(20) NOT NULL
        CHECK (reward_type IN ('POINT', 'COUPON')),

    -- 정책/카탈로그 추적 (선택)
    reward_catalog_id BIGINT
        REFERENCES event_platform.event_reward_catalog(id),

    /* reward snapshot */
    point_amount INTEGER,
    coupon_group_id BIGINT,

    CONSTRAINT chk_att_reward_payload_match CHECK (
        (reward_type = 'POINT'
            AND point_amount IS NOT NULL
            AND point_amount > 0
            AND coupon_group_id IS NULL)
        OR
        (reward_type = 'COUPON'
            AND coupon_group_id IS NOT NULL
            AND point_amount IS NULL)
    ),

    -- 지급 실행 상태 (외부 API 포함)
    reward_status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (reward_status IN ('PENDING', 'PROCESSING', 'SUCCESS', 'FAILED', 'CANCELLED')),

    retry_count INTEGER NOT NULL DEFAULT 0 CHECK (retry_count >= 0),
    next_retry_at TIMESTAMP,

    -- 외부 연동 추적/중복 방지
    idempotency_key VARCHAR(120) NOT NULL,
    external_transaction_id VARCHAR(120),

    error_code VARCHAR(50),
    error_message TEXT,

    requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 하루 출석 1건(history)당 DAILY/BONUS 각 1건만 허용
    CONSTRAINT uq_att_reward_history_kind
        UNIQUE (attendance_history_id, reward_kind),

    -- 외부 API 재시도 중복 방지 핵심
    CONSTRAINT uq_att_reward_idempotency_key
        UNIQUE (idempotency_key)
);

CREATE INDEX idx_att_reward_event_member
    ON event_platform.event_attendance_reward_log(event_id, member_id, created_at DESC);

CREATE INDEX idx_att_reward_retry_queue
    ON event_platform.event_attendance_reward_log(reward_status, next_retry_at)
    WHERE reward_status IN ('PENDING', 'FAILED');

CREATE INDEX idx_att_reward_history
    ON event_platform.event_attendance_reward_log(attendance_history_id);

```