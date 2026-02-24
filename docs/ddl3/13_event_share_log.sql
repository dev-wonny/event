-- =============================================================
-- [13] event_share_log
-- 역할  : SNS 공유 링크 클릭 append-only 로그
--
-- 흐름:
--   1. 공유자(sharer_member_id)가 공유 버튼 클릭 → share_token 발급
--   2. 공유자가 임의 채널로 URL 공유 (token이 URL에 포함됨)
--   3. 수신자가 링크 클릭 → 서버에 share_token 전달 → 이 테이블에 INSERT
--   4. 잔여 참여권 계산:
--      COUNT(*) WHERE event_id=? AND sharer_member_id=? >= max_share_credit?
--      → 아니면 공유자에게 랜덤 1회 추가 실행 권한 부여
--
-- 관계  :
--   - event_share_policy.event_id → event_share_log.event_id (1:N)
--     SNS 공유 정책이 있는 랜덤 이벤트에만 로그 생성 가능
--
-- =============================================================
-- 예시 데이터 (event_id=2, max_share_credit=2)
-- ─ 공유자: member_id=10001, share_token='tok-A' 발급 후 카카오 공유
-- id=1, event_id=2, share_token='tok-A', sharer_member_id=10001, visitor_member_id=20002, created_at='2026-03-05 11:00'
--   → 10001이 공유한 링크를 20002가 클릭 (클릭 1회)
-- id=2, event_id=2, share_token='tok-A', sharer_member_id=10001, visitor_member_id=20003, created_at='2026-03-05 11:05'
--   → 20003도 클릭 (클릭 2회)
-- → COUNT(*) WHERE share_token='tok-A' = 2 >= max_share_credit(2) → 참여권 2개 달성
-- =============================================================

CREATE TABLE event_platform.event_share_log (
    id                  BIGSERIAL       PRIMARY KEY,

    /* =========================
     * 이벤트 식별
     * ========================= */
    event_id            BIGINT          NOT NULL
        REFERENCES event_platform.event_share_policy(event_id) ON DELETE CASCADE,
        -- FK: event_share_policy.event_id
        -- SNS 공유 정책이 존재하는 랜덤 이벤트에만 로그 생성 가능

    /* =========================
     * 공유 토큰 (공유자 식별)
     * ========================= */
    share_token         VARCHAR(200)    NOT NULL,               -- 공유자의 JWT 토큰 (공유 링크 URL에 포함)
                                                                -- 같은 token이 여러 row 가능 (클릭할 때마다 INSERT)
    sharer_member_id    BIGINT          NOT NULL,               -- 링크를 공유한 회원 ID (token에서 파싱)

    /* =========================
     * 방문자 정보
     * ========================= */
    visitor_member_id   BIGINT,                                 -- 링크를 클릭한 회원 ID (NULL=비회원 방문자)

    /* =========================
     * 채널 정보
     * ========================= */
    share_channel       VARCHAR(20)     NOT NULL,               -- 공유 채널: KAKAO / FACEBOOK / INSTAGRAM / TWITTER / LINK_COPY

    /* =========================
     * 보안·디버그 정보
     * ========================= */
    ip_address          VARCHAR(50),                            -- 방문자 IP (어뷰징·VPN 감지용)
    user_agent          TEXT,                                   -- 방문자 User-Agent (봇 탐지)

    /* =========================
     * 감사 정보
     * ========================= */
    created_at          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP  -- 클릭 발생 일시 (append-only, 수정 없음)
);

-- 참여권 집계용 (share_token 기준 COUNT)
CREATE INDEX idx_share_log_token
    ON event_platform.event_share_log(share_token);

-- 공유자 기준 조회
CREATE INDEX idx_share_log_sharer
    ON event_platform.event_share_log(event_id, sharer_member_id, created_at);

COMMENT ON TABLE  event_platform.event_share_log IS 'SNS 공유 링크 클릭 로그 - 누군가 공유 링크를 클릭할 때마다 INSERT (append-only)';
COMMENT ON COLUMN event_platform.event_share_log.event_id         IS 'FK: event_share_policy.event_id - SNS 공유 정책이 있는 랜덤 이벤트에만 로그 생성 가능';
COMMENT ON COLUMN event_platform.event_share_log.share_token      IS '공유자의 JWT 토큰 - 같은 token이 여러 row 가능 (클릭자마다 행 생성)';
COMMENT ON COLUMN event_platform.event_share_log.sharer_member_id IS '공유 링크를 발행한 회원 ID (참여권 수혜자)';
COMMENT ON COLUMN event_platform.event_share_log.visitor_member_id IS '링크를 클릭한 회원 ID (NULL=비회원)';
COMMENT ON COLUMN event_platform.event_share_log.share_channel    IS '공유 채널: KAKAO / FACEBOOK / INSTAGRAM / TWITTER / LINK_COPY';
COMMENT ON COLUMN event_platform.event_share_log.ip_address       IS '클릭 요청 IP - 어뷰징·VPN 감지용';
COMMENT ON COLUMN event_platform.event_share_log.user_agent       IS '클릭 요청 User-Agent - 봇 탐지용';
COMMENT ON COLUMN event_platform.event_share_log.created_at       IS '링크 클릭 발생 일시 (append-only, 이후 수정 없음)';
