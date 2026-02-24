-- =============================================================
-- [12] event_share_policy
-- 역할  : SNS 공유 정책 - 공유가 참여권을 만드는지, 몇 번까지 허용하는지
-- 관계  :
--   - event_random_policy.event_id → event_share_policy.event_id (0:1 선택적)
--     event_random_policy.sns_retry_enabled=TRUE 인 랜덤 이벤트에만 row 존재
--     row 없음 = SNS 공유 기능 미사용
-- =============================================================
-- 예시 데이터
-- event_id=2, max_share_credit=1
--   → SNS 공유 1회당 참여권 1회 추가
-- event_id=3, max_share_credit=3
--   → SNS 공유 최대 3회까지 참여권 추가
-- =============================================================

CREATE TABLE event_platform.event_share_policy (
    event_id                BIGINT          PRIMARY KEY
        REFERENCES event_platform.event_random_policy(event_id) ON DELETE CASCADE,
        -- FK: event_random_policy.event_id
        -- sns_retry_enabled=TRUE 인 랜덤 이벤트에만 생성 가능
        -- 종속성 체인: event → event_random_policy → event_share_policy

    /* =========================
     * 공유로 얻는 최대 참여권 수
     * ========================= */
    max_share_credit        INTEGER         NOT NULL DEFAULT 0,  -- 공유로 얻을 수 있는 최대 추가 참여 횟수 (0=참여권 증가 없음)


    /* =========================
     * 감사 정보
     * ========================= */
    created_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by              BIGINT          NOT NULL,           -- FK: admin.id
    updated_at              TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by              BIGINT          NOT NULL            -- FK: admin.id
);

COMMENT ON TABLE  event_platform.event_share_policy IS 'SNS 공유 정책 - row 존재 자체가 공유 활성화를 의미, 최대 참여권 수 설정';
COMMENT ON COLUMN event_platform.event_share_policy.event_id         IS 'FK(PK): event_random_policy.event_id - sns_retry_enabled=TRUE 인 랜덤 이벤트에만 존재 (0:1 선택적)';
COMMENT ON COLUMN event_platform.event_share_policy.max_share_credit IS '공유로 얻을 수 있는 최대 추가 참여 횟수 (0이면 기록만 하고 참여권 없음)';
