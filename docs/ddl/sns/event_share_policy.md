## event_share_policy

책임

- SNS 공유가 참여권을 만들어내는지
- 몇 번까지 허용하는지”만

```sql
CREATE TABLE event_platform.event_share_policy (
    event_id BIGINT PRIMARY KEY
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    /* =========================
     * SNS 공유 기능 사용 여부
     * ========================= */
    share_enabled BOOLEAN NOT NULL DEFAULT FALSE,
        -- TRUE  : SNS 공유 시 참여권 증가 가능
        -- FALSE : SNS 공유 기능 사용 안 함

    /* =========================
     * SNS로 얻을 수 있는 최대 추가 참여 횟수
     * ========================= */
    max_share_credit INTEGER NOT NULL DEFAULT 0,
        -- 예: 1 → 공유로 1회 추가 참여 가능
        -- 예: 3 → 최대 3회까지 추가 참여 가능
        -- 0이면 공유는 기록만 하고 참여권은 증가 안 함

    /* =========================
     * 공유 시 즉시 랜덤 실행 여부
     * ========================= */
    auto_execute_random BOOLEAN NOT NULL DEFAULT FALSE,
        -- TRUE  : SNS 성공 → 즉시 랜덤 실행
        -- FALSE : SNS 성공 → 참여권만 증가 (유저가 버튼 눌러 실행)

    /* =========================
     * 감사 컬럼
     * ========================= */
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by BIGINT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by BIGINT NOT NULL
);

COMMENT ON TABLE event_platform.event_share_policy IS
'SNS 공유 정책 (추가 참여 횟수 및 자동 실행 여부 설정)';

```