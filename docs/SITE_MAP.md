# SITE_MAP

이 문서는 3teuk-Consulting MVP의 사이트 구조와
사용자 이동 흐름을 정의한다.

구현 전에 어떤 페이지를 만들고
페이지 간에 어떻게 이동할지를 판단하는 기준으로 사용한다.

이 문서는 `docs/MVP_SPEC.md`와 `AGENTS.md`의
제품 범위 및 정보 신뢰 원칙과 충돌하지 않도록 작성한다.

아직 애플리케이션 코드, UI, database는 구현하지 않는다.


# 1. 사이트 구조 개요

MVP의 핵심 기능은 다음 5개이다.

1. 대학전형 DB
2. 대학비교
3. 자격진단
4. FAQ
5. 학부모 경험 콘텐츠

기본 route 구조는 다음과 같다.

| Route | 페이지 |
| --- | --- |
| `/` | 홈 |
| `/universities` | 대학전형 탐색 |
| `/universities/[slug]` | 대학 상세 |
| `/universities/[slug]/admissions/[academicYear]/[admissionSlug]` | 대학 전형 상세 |
| `/compare` | 대학/전형 비교 |
| `/eligibility` | 자격진단 |
| `/faq` | FAQ 목록 |
| `/faq/[slug]` | FAQ 상세 |
| `/stories` | 학부모 경험 콘텐츠 목록 |
| `/stories/[slug]` | 학부모 경험 콘텐츠 상세 |

MVP에서는 다음 route를 만들지 않는다.

- login
- signup
- community
- comments
- messages
- payment
- subscription
- AI chatbot
- public admin

`/admin`은 향후 운영도구로 필요할 수 있지만
현재 사용자용 MVP 사이트맵에서는 제외한다.


# 2. 글로벌 네비게이션

Desktop 상단 navigation의 기본 항목:

1. 대학전형 → `/universities`
2. 자격진단 → `/eligibility`
3. 대학비교 → `/compare`
4. FAQ → `/faq`
5. 학부모 경험 → `/stories`

왼쪽 또는 시작 영역에는
향후 확정할 서비스명/로고 영역을 둔다.

서비스명이 아직 확정되지 않았으므로
실제 브랜드명을 임의로 만들지 않는다.

회원가입/로그인은 MVP navigation에 포함하지 않는다.


# 3. 홈 페이지

Route:

`/`

목적:

처음 방문한 사용자가
자신이 원하는 행동으로 빠르게 이동할 수 있게 한다.

홈에서 가장 중요한 세 가지 primary action은 다음 순서로 둔다.

1. 대학전형 찾기 → `/universities`
2. 내 자격 확인 → `/eligibility`
3. 대학 비교하기 → `/compare`

FAQ와 학부모 경험 콘텐츠는 secondary content로 둔다.


## 홈 화면 정보 구조

### A. Hero

핵심 메시지의 방향:

"해외에서 준비하는 한국 대학 입시 정보를
공식 출처 기준으로 찾고 비교한다"

정확한 marketing copy는 아직 확정하지 않는다.

Primary CTA:
대학전형 찾기 → `/universities`

Secondary CTA:
내 자격 확인 → `/eligibility`


### B. 핵심 기능 3개

대학전형 찾기
- 대학별/학년도별/전형별 정보 확인
- 이동: `/universities`

내 자격 확인
- 해외 재학과 체류 조건 구조적으로 점검
- 이동: `/eligibility`

대학 비교하기
- 관심 전형을 동일 기준으로 비교
- 이동: `/compare`


### C. 신뢰 구조 소개

사용자에게 다음 세 가지를 강조한다.

- 학년도
- 공식 출처
- 최종 확인일

"공식 확인 정보"와
"경험 콘텐츠"가 서로 다른 종류의 정보라는 점도 표현한다.


### D. 자주 묻는 질문

대표 FAQ 일부 노출
→ 전체 FAQ 보기 → `/faq`


### E. 학부모 경험

최근 또는 대표 경험 콘텐츠 일부 노출
→ 전체 경험 콘텐츠 보기 → `/stories`


# 4. 대학전형 탐색 페이지

Route:

`/universities`

목적:

사용자가 대학 또는 조건을 기준으로
원하는 전형을 찾는 핵심 DB 탐색 화면이다.

하나의 페이지 안에서 다음 두 탐색 방식을 지원하도록 설계한다.


## A. 대학으로 찾기

- 대학명 검색
- 대학 목록
- 대학 선택 → `/universities/[slug]`


## B. 조건으로 찾기

MVP에서 고려할 필터:

- academic_year
- admission_type
- 대학명

다른 필터는 데이터 모델이 확정된 뒤 추가한다.

지원 가능 여부를 추정하는 필터는
자격진단과 혼동될 수 있으므로
현재 검색 필터에 넣지 않는다.


검색 결과 카드 또는 목록에서 최소한 다음 정보를 보여줄 수 있도록 한다.

- 대학명
- academic_year
- admission_type
- 전형명
- verified_date
- 정보 상태

정보 상태는 향후 예를 들어

- 공식 확인
- 일부 확인 필요
- 업데이트 필요

등을 표현할 수 있어야 하지만,
구체적인 enum은 DATA_MODEL 단계에서 확정한다.

CTA:

전형 상세 보기
→ `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`


# 5. 대학 상세 페이지

Route:

`/universities/[slug]`

목적:

특정 대학의 수록된 입시정보를
학년도와 전형 기준으로 탐색한다.

화면에 포함할 정보:

- 대학명
- 공식 입학처 링크
- 현재 사이트에 수록된 학년도
- 해당 학년도의 전형 목록
- 각 전형의 정보 상태
- verified_date

학년도 선택 기능을 제공한다.

서로 다른 학년도 정보를
하나의 전형 정보처럼 섞지 않는다.

전형 선택 시 해당 전형 상세 페이지로 이동한다.

→ `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`


# 6. 전형 상세 페이지

Route:

`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`

이 페이지를 MVP의 가장 중요한 정보 페이지 중 하나로 정의한다.

비교 데이터는 이 페이지가 읽는
대학전형 DB를 source of truth로 사용한다.
비교용 데이터를 별도로 복제하지 않는다.


상단에서 사용자가 즉시 확인할 수 있어야 하는 정보:

- 대학명
- academic_year
- admission_type
- 전형명
- verified_date
- 정보 확인 상태


본문 기본 섹션:

1. 지원자격
2. 평가방법
3. 제출서류
4. 원서/전형 일정
5. 어학 관련 공식 규정
6. 표준시험 관련 공식 규정
7. 기타 공식 조건
8. 주의사항
9. 공식 출처


자료가 없는 항목은
빈 공간을 가짜 정보로 채우지 않는다.

예:

- 공식자료 미확인
- 자료 없음
- 추가 확인 필요


공식 출처 영역에는 가능하면:

- source_document
- source_url
- source_page 또는 section
- verified_date

를 보여준다.


주요 CTA:

- 비교에 추가 → `/compare`
- 이 전형 자격 확인 → `/eligibility`

두 번째 CTA는 자격진단의
대학별 자격 확인으로 연결한다.

진입 시 다음 값을 context로 전달할 수 있도록 설계한다.

- university
- academic_year
- admission_type


# 7. 대학비교 페이지

Route:

`/compare`

목적:

2~3개의 대학 전형을
동일한 기준으로 비교한다.

중요 정책:

MVP에서는 동일 academic_year끼리만 비교한다.

다른 학년도 전형을 선택하려는 경우
동일 비교표에 섞지 않는다.

연도별 규정 변화 비교 기능은
현재 site map에 포함하지 않는다.


비교 항목:

- 대학
- 전형명
- 지원자격
- 평가방법
- 제출서류
- 일정
- 어학 공식 규정
- 표준시험 공식 규정
- verified_date

비교 화면은 대학전형 DB의 동일한 데이터를 읽는다.

각 전형에 대해 공식 출처로 이동할 수 있어야 한다.

비교 화면은
"어느 대학이 더 좋다"
또는
"어느 대학이 더 쉽다"
와 같은 자동 평가를 제공하지 않는다.

합격 가능성 예측, 합격선 예측, 경쟁률 예측,
자동 대학 추천도 제공하지 않는다.


# 8. 자격진단 페이지

Route:

`/eligibility`

두 가지 진단 목적을 명확하게 구분한다.

자격진단은 AI가 임의로 가능/불가능을 판단하는 기능이 아니다.
가능하면 공식 모집요강을 근거로 한
결정론적 rule 기반으로 설계한다.


## A. 기초 자격 점검

대학을 특정하지 않고
사용자의 교육 및 체류 이력을 구조화한다.

university, academic_year, admission_type이
특정되지 않은 상태에서는
특정 대학 전형의 최종 "지원 가능" 판정을 하지 않는다.

예상 Step:

Step 1
학생 기본 정보

Step 2
해외 재학 이력

Step 3
학교 학제 및 학기 정보

Step 4
부모 체류/근무 관련 정보

Step 5
전학, 월반, 유급 등 예외사항

Step 6
점검 결과

결과는 다음과 같은 형태를 기본으로 한다.

- 확인된 조건
- 잠재적 미충족 조건
- 입력 정보 부족
- 추가 확인 필요

특정 대학 지원 가능 여부를
이 단계에서 확정하지 않는다.


## B. 대학별 자격 확인

특정 전형에 대한 확인에는 반드시

- university
- academic_year
- admission_type

이 필요하다.

전형 상세 페이지의
"이 전형 자격 확인" CTA로 진입할 경우
해당 세 값을 context로 전달할 수 있도록 설계한다.

결과 화면에는 가능하면:

- 조건별 판정
- 입력값
- 적용된 rule
- 공식 근거
- 확인 필요 항목
- 해당 전형 상세 링크
- 대학 공식 확인 필요 안내

를 보여준다.

결과는 단순한 가능/불가능만으로 제한하지 않는다.

자격진단 결과는 대학의 공식 지원자격 판정을 대신하지 않는다.

MVP에서는
합격 가능성 예측이나 대학 추천을 하지 않는다.


# 9. FAQ 목록

Route:

`/faq`

목적:

공식 입시 규정과 용어에 관한 반복적인 질문을
쉽게 찾도록 한다.

FAQ는 official_fact와
공식 자료를 바탕으로 한 설명 중심으로 구성한다.

기능:

- FAQ 검색
- 카테고리 필터
- 질문 목록

예상 카테고리:

- 재외국민
- 3년 특례
- 전교육과정 해외이수
- 해외학교 학제
- 학기
- 부모 체류
- 제출서류
- 표준시험
- 대학별 절차

전략적 의견, 개인 경험, 준비 노하우는
FAQ 목록에 섞지 않는다.


# 10. FAQ 상세

Route:

`/faq/[slug]`

화면 구조:

- 질문
- 공식자료 기반 답변
- academic_year (해당되는 경우)
- source
- source page/section
- verified_date
- 관련 FAQ
- 관련 대학전형 또는 자격진단 CTA

핵심 FAQ에는 가능하면
academic_year, official source, source page/section, verified_date를 표시한다.

전략적 의견 또는 개인 경험을
FAQ 공식 설명과 섞지 않는다.

개인 경험과 노하우는
학부모 경험 콘텐츠 영역(`/stories`)에서 다룬다.


# 11. 학부모 경험 콘텐츠 목록

Route:

`/stories`

목적:

공식 모집요강으로 알기 어려운
실제 준비 과정과 경험을 탐색한다.

가능한 카테고리:

- 학교생활
- 입시준비
- 시험준비
- 서류준비
- 대학지원
- 귀국
- 시행착오

모든 경험 콘텐츠 영역에서는
공식 입시정보가 아니라는 점을
사용자가 인지할 수 있도록 설계한다.

자유게시판, 실시간 커뮤니티,
사용자 간 메시지 기능은 포함하지 않는다.


# 12. 학부모 경험 콘텐츠 상세

Route:

`/stories/[slug]`

기본 구성:

- 제목
- 작성일
- 콘텐츠 유형
- 본문
- 개인 경험/의견 안내
- 관련 콘텐츠

향후 작성자 정보를 제공할 수 있지만
MVP에서 실명 또는 개인정보 공개를 전제로 하지 않는다.

댓글은 제공하지 않는다.

관련 공식정보로 연결할 경우
공식정보와 개인 경험을 명확하게 구분한다.


# 13. 정보 신뢰 UI 원칙

입시정보 페이지에는 가능한 한
다음 정보를 일관된 위치에 표시한다.

- academic_year
- verified_date
- source

특히 전형 상세와 FAQ 상세에서는
공식 출처에 접근하기 어렵게 숨기지 않는다.

학년도와 출처가 없는 데이터를
확정된 공식정보처럼 사용자에게 보여주지 않는다.

정보 상태를 시각적으로 구분할 수 있도록 설계하지만
실제 색상과 디자인은 UI 단계에서 결정한다.


# 14. 모바일 원칙

해외 거주 학부모가 모바일에서도 사용할 가능성을 고려한다.

모바일에서 특히 우선할 것:

- 검색
- 학년도 확인
- 전형명 확인
- 출처 확인
- 비교
- 자격진단 진행 상태

Desktop용 복잡한 표를
그대로 작은 화면에 축소하는 방식은 피한다.

구체적인 responsive UI는 디자인 단계에서 결정한다.

모바일 앱과 다국어 UI는 MVP 범위에 포함하지 않는다.


# 15. 주요 cross-link

사용자가 사이트 안에서 자연스럽게 이동하도록
다음 연결을 정의한다.

전형 상세
→ 대학비교 (`/compare`)

전형 상세
→ 해당 전형 자격 확인 (`/eligibility`, university / academic_year / admission_type context 전달)

자격진단 결과
→ 관련 전형 상세 (`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`)

FAQ
→ 관련 전형 상세

FAQ
→ 자격진단

홈
→ 대학전형 / 자격진단 / 비교

학부모 경험 콘텐츠는
공식정보를 대신하지 않으며,
관련 공식정보로 연결할 경우
두 정보 유형을 명확하게 구분한다.


# 16. MVP Navigation Priority

Primary:

1. 대학전형
2. 자격진단
3. 대학비교

Secondary:

4. FAQ
5. 학부모 경험

홈페이지의 시각적 중요도 역시
Primary 기능을 우선한다.


# 17. 핵심 사용자 흐름과 route 연결

`docs/MVP_SPEC.md`의 핵심 사용자 흐름은
다음 route와 연결한다.


Flow A:

`/`
→ `/universities`
→ `/universities/[slug]`
→ `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`
→ 공식 출처 확인


Flow B:

`/universities`
→ 동일 academic_year의 2~3개 전형 선택
→ `/compare`
→ 차이 확인
→ 각각의 공식 출처 확인


Flow C:

`/eligibility`
→ 학생/가족/학교 이력 입력
→ 기초 자격 점검
→ 조건별 상태 / 누락 정보 / 추가 확인사항 확인
→ 특정 university / academic_year / admission_type 선택
→ 대학별 자격 확인
→ 근거와 공식 출처 확인
→ `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`


Flow D:

`/faq`
→ `/faq/[slug]`
→ academic_year 및 official source 확인
→ 관련 전형 상세 또는 `/eligibility`


Flow E:

`/stories`
→ `/stories/[slug]`
→ 해당 내용이 개인 경험임을 명확히 인지


# 18. 향후 기능

현재 site map에서는 제외하지만
향후 검토할 수 있는 항목:

- 회원가입
- 북마크
- 진단 결과 저장
- 알림
- 관리자 UI
- 검색 고도화
- 연도별 규정 변화 비교
- 개인화
- 상담 연결
- 커뮤니티
- 수익화 기능


# 19. 결정하지 않을 사항

이번 SITE_MAP 단계에서는 다음을 확정하지 않는다.

- 구체적인 색상
- font
- 로고
- 서비스명
- 상세 디자인
- database schema
- Supabase 구조
- authentication
- 실제 대학 목록
- 실제 입시 데이터
- 세부 eligibility rule
- 정보 상태 enum
- 정확한 marketing copy
