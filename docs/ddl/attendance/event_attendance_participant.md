# event_attendance_participant

- 최초 1회 eligibility 통과한 회원을 등록
- 이후 출석은 이 테이블 존재 여부로 진입 허용
- 중간에 회원 상태가 바뀌어도 이벤트 진행을 끊지 않음(정책 의도일 때)

```sql
CREATE TABLE event_platform.event_attendance_participant (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,

    enroll_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (enroll_status IN ('ACTIVE', 'BLOCKED', 'CANCELLED')),

    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enrolled_by BIGINT, -- system or admin id (optional)

    first_attendance_date DATE,
    last_attendance_date DATE,

    -- 최초 통과 시점 기준 스냅샷/버전 (정책 변경 추적용)
    eligibility_policy_version INTEGER NOT NULL DEFAULT 1,
    eligibility_checked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- 운영 제어용 (강제 차단 시)
    blocked_reason TEXT,
    blocked_at TIMESTAMP,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL,

    CONSTRAINT uq_attendance_participant_event_member
        UNIQUE (event_id, member_id),

    CONSTRAINT chk_att_participant_block_fields CHECK (
        (enroll_status <> 'BLOCKED')
        OR
        (enroll_status = 'BLOCKED' AND blocked_at IS NOT NULL)
    )
);

CREATE INDEX idx_att_participant_event_status
    ON event_platform.event_attendance_participant(event_id, enroll_status);

CREATE INDEX idx_att_participant_member
    ON event_platform.event_attendance_participant(member_id);

```