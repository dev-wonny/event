# event_share_log 공유 로그

- sns → 다시 한번 더!
- append only
- **jwt token**

SNS 공유 보상 구조면:
- event_id + member_id + share_token UNIQUE

✅ SNS append-only

👉 여기에는 절대 reward 정보 안 들어감.

- 여기서 카운트 셀거임
- 1보다 많으면 랜덤 리워드 실행할거임

👉 COUNT = 4

👉 참여권 계산 정상

SNS 공유 횟수 >= event_share_policy.**max_share_credit** → 랜덤 실행

```sql
INSERT INTO event_share_log (event_id, member_id, share_token)
VALUES
(1001, 30001, 'abc-1'),
(1001, 30001, 'abc-1'), -- 동일 token 허용
(1001, 30001, 'abc-2'),
(1001, 30001, NULL);
```

### 🔥 참여권 계산 인덱스

```sql
COUNT(*) WHERE event_id=? AND member_id=?
```

```sql
CREATE TABLE event_platform.**event_share_log** (
    id BIGSERIAL PRIMARY KEY,

    event_id BIGINT NOT NULL
        REFERENCES event_platform.event(id) ON DELETE CASCADE,

    member_id BIGINT NOT NULL,
    
    share_channel VARCHAR(20) NOT NULL
    CHECK (share_channel IN ('KAKAO', 'FACEBOOK', 'INSTAGRAM', 'TWITTER', 'LINK_COPY')),

    share_token VARCHAR(100),
        -- 중복 공유 방지/검증에 사용(가능하면 UNIQUE 고려)

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- member_id + event_id 인덱스
CREATE INDEX idx_share_event_member
ON event_platform.event_share_log(event_id, member_id, created_at);

COMMENT ON TABLE event_platform.event_share_log IS
'SNS 공유 append-only 로그 (reward 정보 없음)';
```

SNS는 실행 트리거가 아니라
"참여권 발생 이벤트"

```sql
    trigger_result VARCHAR(20)
        CHECK (trigger_result IN ('EXECUTED','LIMIT_REJECT','FAILED')),
        -- EXECUTED : 랜덤 실행됨
        -- LIMIT_REJECT : 제한 정책 때문에 실행 안됨
        -- FAILED : 서버 오류 / 검증 실패

    failure_reason TEXT,

    -- 한 IP에서 공유 스팸, VPN abuse, 매크로
    ip_address VARCHAR(50),
    
    -- 봇 탐지, 특정 SDK 오류 추적, iOS WebView 문제 분석
    user_agent TEXT,
```