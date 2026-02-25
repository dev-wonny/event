# event_share_log.share_token 설계

## 핵심 원칙

- share_token은 **공유자(sharer)에게 발급** (공유 링크 URL에 포함)
- 누군가 그 링크를 클릭할 때마다 → `event_share_log` INSERT
- **credit 수 = `COUNT(*)` WHERE share_token = ?**
- `COUNT(*) >= max_share_credit` → 공유자에게 추가 랜덤 참여 불가

---

## 공유 흐름

```
1. 공유자(A)가 "공유하기" 클릭
   → Server: A의 share_token 발급 (JWT, 24h 유효)

2. A가 KAKAO / NAVER / 링크복사 등으로 URL 공유
   URL: https://event.com/share?token=eyJhbG...

3. 수신자(B)가 링크 클릭 → Server 수신
   → event_share_log INSERT (sharer=A, visitor=B)
   → COUNT(*) WHERE share_token=A's token ++

4. COUNT(*) < max_share_credit
   → A에게 랜덤 1회 추가 실행 권한 생성 (event_entry trigger_type='SNS_SHARE')

5. COUNT(*) >= max_share_credit
   → A의 추가 참여권 한도 도달, 더 이상 부여 안 함
```

---

## share_token 구조 (JWT)

```json
Payload: {
    "event_id":        2,
    "member_id":       10001,    // sharer
    "iat": 1709776800,
    "exp": 1709863200            // 24시간 후 만료
}
```

---

## credit 계산 쿼리

```sql
-- 공유자 A의 링크가 몇 번 클릭됐는지 (= 획득한 참여권 수)
SELECT COUNT(*) AS click_count
FROM event_platform.event_share_log
WHERE share_token = 'A의 token';

-- click_count < max_share_credit → 추가 참여 가능
-- click_count >= max_share_credit → 한도 도달
```

---

## 요약

| 항목 | 내용 |
|------|------|
| token 발급 대상 | 공유자(sharer) |
| token 동일 row 허용 | O (클릭자마다 새 row) |
| UNIQUE 제약 | 없음 |
| credit 계산 기준 | `COUNT(*) WHERE share_token=?` |
| 만료 검증 | JWT exp, Application 처리 (DB X) |
