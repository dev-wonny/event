
1️⃣ CDN URL만 저장하면 생기는 문제 (실무에서 바로 터짐)
❌ 1. 인프라 종속성 증가

CDN 도메인이 바뀌는 순간 DB 전체 수정해야 합니다.

예:

https://cdn.eventkiki.com/event/2026/02/a.png
→ CloudFront → Cloudflare 교체
→ 전체 데이터 마이그레이션

반대로 object_key만 있으면:

cdnDomain + "/" + object_key

끝입니다.


❌ 2. Presigned URL 발급 불가능

이미 너 이벤트 플랫폼에서:

✔ 서버에서 Presigned URL 발급

이거 쓰고 있죠?

Presigned URL은 S3 bucket + key 기준입니다.

CDN URL만 있으면:

어디 버킷인지?
어디 key인지?

역추적해야 합니다.
(운영 중 지옥 시작)

❌ 3. 멀티 스토리지 확장성 사망

지금은 S3지만 미래에는:

S3

Local NAS

MinIO

NCP Object Storage

가능합니다.

CDN URL만 저장하면 storage abstraction 깨집니다.

❌ 4. 보안 정책 분리 불가능

지금 DDL에:

is_public

있죠?

실제 구현은:

if public → CDN URL
else → presigned URL

이 패턴인데 CDN URL만 저장하면 로직이 붕괴됩니다.

❌ bucket_name 제거 + CDN URL만 저장

이건 보통:

초기 스타트업

CDN = Storage 인 구조

에서만 씁니다.

당신 구조는 이미:

S3 + CDN + Presigned

이라서 맞지 않아요.

1️⃣ CDN 링크를 DB에 “직접 저장”하는 구조의 리스크

팀장이 말한 걸 그대로 구현하면 보통 이렇게 됩니다:

cdn_download_url VARCHAR(500)

하지만 이 방식은 몇 가지 운영 리스크가 큽니다.

❌ CDN 도메인 변경 시 전체 데이터 수정 필요

CloudFront → 다른 CDN으로 바뀌면:

UPDATE file SET cdn_url = ...

대형 테이블이면 migration 비용 큽니다.

❌ dev / prod 환경 분리 깨짐

지금 당신 의도:

application.yml 로 bucket 분리

CDN URL을 저장하면 환경 의존성이 DB에 들어갑니다.

❌ Private Asset 설계 어려워짐

이미 DDL에:

is_public

있죠.

CDN URL 고정 저장하면:

public CDN
private presigned

로직이 충돌합니다.

팀장이 말한 건 보통:

“프론트에서 바로 CDN URL 쓰게 해라”

입니다.

이건 DB 저장이 아니라 서버에서 내려주는 응답 DTO에서 해결합니다.

✔️ DB는 그대로 유지
bucket_name
object_key

만 저장.

✔️ 서버 Response에 CDN URL 생성

Spring 예시:

public String buildCdnUrl(File file) {
    return cdnDomain + "/" + file.getObjectKey();
}

API Response:

{
  "fileId": 123,
  "cdnUrl": "https://cdn.eventkiki.com/event/2026/a.png"
}

👉 팀장 요구 충족
👉 DB는 인프라 독립 유지

1️⃣ bucket 제거 시 아키텍처 전제 (반드시 명확히)

이 구조는 아래 조건이 유지된다는 가정입니다.

환경별 bucket은 application.yml에서만 관리

서비스 전체가 single bucket 전략

public/private 분리도 bucket이 아니라 policy 또는 prefix로 처리

즉, Storage Layer는 이렇게 됩니다:

application.yml (dev/prod)
        ↓
bucket = config.storage.bucket
        ↓
DB에는 object_key만 저장

3️⃣ 서버 코드 변경 방식 (Spring 기준)

bucket은 이제 config에서만 사용합니다.

storage:
  bucket: eventkiki-prod
  cdn-domain: https://cdn.eventkiki.com

서비스 코드:

public String buildCdnUrl(File file) {
    return cdnDomain + "/" + file.getObjectKey();
}

Presigned:

generatePresigned(bucketConfig, file.getObjectKey());

4️⃣ bucket 제거했을 때 반드시 지켜야 하는 룰 (실무 중요)
✔️ object_key는 반드시 prefix 포함
event/banner/2026/02/uuid.png
event/thumb/2026/02/uuid.png
admin/private/uuid.png

👉 나중에 bucket 분리 대신 prefix로 정책 관리합니다.

✔️ object_key를 절대 URL로 저장하지 말 것
❌ https://cdn....
✔ event/2026/a.png

이거 안 지키면 나중에 CDN 변경 시 DB 마이그레이션 지옥 옵니다.

5️⃣ bucket 제거 구조에서 흔히 터지는 문제 (미리 방지)
⚠️ public/private 분리

bucket이 없으면 보통 이렇게 합니다:

public/
private/

prefix 정책으로 관리.

⚠️ variant 구조

나중에 file_variant 추가할 때도 동일하게:

event/2026/a.png
event/2026/a_thumb.png

prefix 규칙만 유지하면 됩니다.

1️⃣ “물리 파일 테이블”의 정확한 역할 정의

지금 당신 file 테이블은 스토리지 인덱스입니다.

즉:

file = S3에 존재하는 실제 객체 1개

의미적으로는:

object_key = 실제 파일 위치

mime_type = 실제 파일 타입

checksum = 실제 바이너리 무결성

👉 비즈니스 의미 없음
👉 이벤트 배너인지, 썸네일인지 모름

이건 아주 좋은 방향입니다.

2️⃣ 물리 파일 기준이면 절대 하면 안 되는 것
❌ variant 정보를 file 테이블에 넣는 것

예:

thumb_width
medium_width
banner_type

이건 logical asset 영역입니다.

file은 오직:

"스토리지에 있는 1개 파일"

만 표현해야 합니다.

❌ CDN URL 저장

이미 정리했지만 다시 강조:

file = storage layer
cdn = delivery layer

섞이면 책임 깨집니다.

3️⃣ 물리 파일 구조에서 전체 관계 모델 (당신 플랫폼 기준)

지금 흐름을 정리하면 이렇게 가야 합니다.

event_display_asset   ← 논리 자산 (배너, 버튼, 하단 이미지)
          │
          ▼
file_variant          ← 해상도/용도별 이미지
          │
          ▼
file                   ← 실제 S3 객체 (물리 파일)
📌 역할 분리
✔ event_display_asset

이벤트 배너

CTA 버튼 이미지

하단 이미지

즉 UI 의미
✔ file_variant

THUMB

MOBILE

DESKTOP

ADMIN_PREVIEW

즉 이미지 용도/사이즈 의미

✔ file

실제 S3 객체

즉 스토리지 의미

지금 전제는 이미 확정입니다:

file = 물리 파일 (physical storage)

bucket 제거

object_key 기반

CDN URL은 API에서 생성

❌ 구조 A — file 기준 variant (많이들 처음에 하는 설계)
file (original)
 └── file_variant (thumb)
 └── file_variant (mobile)

겉보기엔 맞아 보이지만 이벤트 플랫폼에서는 문제 생깁니다.

문제
1. 같은 원본 파일을 다른 asset에서 다르게 써야 하는 경우

예:

이벤트 A 배너 → DESKTOP 1080

이벤트 B 배너 → MOBILE 720

file 기준이면 variant가 공유되어 버립니다.

즉:

file = storage
variant = UI 의미

가 섞여버립니다.

2. asset 교체 시 파일 구조까지 영향

디자인팀이:

“이 이벤트는 썸네일 필요없어요”

하면 file_variant를 수정해야 합니다.

이건 책임 분리가 깨진 구조입니다.

✅ 구조 B — asset 기준 variant (추천)

구조는 이렇게 갑니다.

event_display_asset (논리 UI 자산)
        │
        ▼
asset_variant (DESKTOP / MOBILE / THUMB)
        │
        ▼
file (물리 파일)

핵심:

variant는 "파일 변형"이 아니라
"UI 사용 방식"

입니다.

왜 asset 기준이 당신 플랫폼에 맞냐

당신 지금 요구사항 기억하면:

배경 이미지

버튼 이미지

하단 이미지

이벤트 UI 중심

이건 전형적인 Display Asset Domain 입니다.

즉:

이미지 사이즈는 storage 개념이 아니라
UI 개념입니다.

📌 event_display_asset

이미 당신이 만든 그 테이블.

id
event_id
asset_type  -- BACKGROUND / BUTTON / FOOTER