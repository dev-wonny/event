# file 테이블 - S3 / CloudFront 설계

## 환경별 S3 Bucket

```properties
# application-dev.properties
cloud.aws.s3.bucket=dolfood-event-assets-dev
cloud.aws.cloudfront.domain=https://dev-cdn.dolfood.com

# application-stg.properties
cloud.aws.s3.bucket=dolfood-event-assets-stg
cloud.aws.cloudfront.domain=https://stg-cdn.dolfood.com

# application-prod.properties
cloud.aws.s3.bucket=dolfood-event-assets-prod
cloud.aws.cloudfront.domain=https://cdn.dolfood.com
```

---

## file 테이블에 저장하는 값

```sql
-- DB에는 object_key (S3 경로)만 저장
object_key = 'event/2/banner/main.webp'

-- 실제 URL은 Application에서 조합
cdn_url = cloudfront.domain + "/" + object_key
        = "https://cdn.dolfood.com/event/2/banner/main.webp"
```

---

## DB에 full URL을 저장하면 안 되는 이유

### 1. 환경 전환 시 데이터 마이그레이션 필요

```
DB에 저장된 값:
  "https://dev-cdn.dolfood.com/event/2/banner/main.webp"

→ 운영(prod) 배포 시 모든 row를 UPDATE해야 함
  UPDATE file SET url = REPLACE(url, 'dev-cdn', 'cdn');  ← 위험
```

### 2. CDN 도메인 변경 시 데이터 오염

```
CloudFront 도메인이 바뀌면?
  AS-IS: https://dev-cdn.dolfood.com/...
  TO-BE: https://assets.dolfood.com/...

→ DB의 수만 건 url 컬럼을 전부 수정해야 함
→ 누락 시 일부는 깨진 URL
```

### 3. S3 직접 접근 vs CDN 접근 전환 불가

```
S3 직접:    https://s3.ap-northeast-2.amazonaws.com/dolfood-event-assets-prod/...
CloudFront: https://cdn.dolfood.com/...

URL이 DB에 고정되어 있으면 전환 순간 기존 데이터 전부 무효화
```

### 4. 서명 URL(Presigned URL) 등 확장 불가

```
private 버킷으로 전환 시 Presigned URL이 필요 → DB 값 쓸모없음
```

---

## 올바른 흐름

```
[업로드]
1. 파일 업로드
2. S3에 저장 → object_key = 'event/2/banner/main.webp'
3. DB INSERT: file.object_key = 'event/2/banner/main.webp'

[조회]
1. DB SELECT: file.object_key 조회
2. Application:
   url = env.cloudfront.domain + "/" + file.object_key
       = "https://cdn.dolfood.com/event/2/banner/main.webp"
3. Response에 url 포함
```

---

## 요약

| 항목 | DB 저장 | Application 생성 |
|------|---------|-----------------|
| object_key | ✅ 저장 | - |
| bucket | ❌ 저장 안 함 | properties에서 읽음 |
| CDN domain | ❌ 저장 안 함 | properties에서 읽음 |
| full URL | ❌ 저장 안 함 | 런타임에 조합 |
