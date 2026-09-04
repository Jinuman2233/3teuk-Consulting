# VERIFIED_DATA_LOAD_SPEC

이 문서는 3teuk-Consulting에서
검증된 공식 입시정보를 database에 적재할 때의
운영 규칙과 절차를 정의한다.

`docs/DATA_MODEL.md`와 `docs/DB_SCHEMA_DRAFT.md`가
구조를 정의한다면,
이 문서는 그 구조에 공식 입시정보를
어떤 절차와 규칙으로 넣는지를 정의한다.

실제 입시 규정, 일정, 제출서류, 평가방식,
자격 기준, 모집인원 등의 값은
이번 문서에 작성하지 않는다.

실제 값은 다음 단계인
KU 2027 Data Source Inventory + Row Map에서
공식 자료를 다시 검증한 뒤 추출한다.


# 1. 문서 목적

공식 입시정보를 development / production database에
입력하기 위한 운영 규칙을 확정한다.

목표:

- 정확성
- 검증 가능성
- 학년도 분리
- source provenance
- 재현 가능성
- 수정 history 보존
- 임의 추론 방지

이 문서는 다음을 하지 않는다.

- 실제 입시 규정 작성
- SQL data migration 작성
- UUID 생성
- hosted / local database 변경
- Supabase Table Editor 또는 SQL Editor로 데이터 입력


# 2. 초기 적용 대상

첫 실제 data load 대상은 다음으로 한정한다.

- 대학교: 고려대학교
- campus: 서울캠퍼스
- academic_year: 2027
- official admission program: 재외국민(정원외2%)전형

Campus는 별도 entity가 아니다.
University의 `campus_name`으로 구분한다.

이 범위 밖의 대학, 캠퍼스, 학년도, 전형은
첫 load에 포함하지 않는다.

중요:

이번 문서의 대상 지정은
적재 범위를 고정하기 위한 것이다.

지원자격, 일정, 제출서류, SAT / IB / AP,
TOEFL / IELTS, 평가방식 등의 실제 값은
여기서 작성하지 않는다.


# 3. Source hierarchy

데이터 입력의 source 우선순위:

1. 대학 입학처 공식 모집요강
2. 대학 입학처 공식 공지
3. 대학 공식 FAQ / 안내문
4. 교육부 / 정부기관
5. 대교협 등 공신력 기관
6. 신뢰 가능한 2차 자료

블로그, 학원, 카페, SNS, 커뮤니티는
공식 fact의 primary evidence로 사용하지 않는다.

공식 source가 없으면 추정하지 않는다.
해당 항목은 아래 상태 중 하나로 남긴다.

- `unknown`
- `needs_confirmation`
- `not_found_in_official_source`

2차 자료는 공식 자료를 찾는 힌트가 될 수 있으나,
공식 source를 대체하는 근거가 되지 않는다.

공식 자료와 2차 자료가 충돌하면
공식 자료를 우선한다.


# 4. Fact classification

각 정보는 가능한 경우 다음을 구분한다.

- `official_fact`
- `interpretation`
- `strategic_opinion`
- `parent_experience`
- `unverified`

초기 university admission DB에 입력하는
규정성 정보는 원칙적으로 `official_fact`다.

`interpretation`은 공식 규정과 같은 field에 섞지 않는다.

개인 경험이나 전략 의견을
`official_fact`로 바꾸지 않는다.

`unverified`는 임시 상태가 될 수 있으나,
첫 KU load의 규정성 정보는
공식 확인 전에는 insert하지 않는 것을 기본으로 한다.


# 5. Data load order

권장 적재 순서는 다음과 같다.

1. University
2. AdmissionCategory
3. SourceDocument
4. AdmissionProgram
5. AdmissionProgramSource
6. AdmissionSection
7. AdmissionSchedule
8. RequiredDocument
9. DocumentSubmission
10. RequiredDocumentChoiceGroup
11. ChoiceGroupItem
12. SourceCitation
13. entity ↔ citation relations

source-first / provenance-first 접근을 사용한다.

각 fact row를 만든 뒤
citation을 나중에 기억해서 추가하는 방식보다
source와 citation 계획을 함께 준비한다.

AdmissionProgram을 만들기 전에
사용할 SourceDocument inventory를 먼저 작성한다.

AdmissionProgramSource는
해당 program이 근거로 삼는 SourceDocument를
명시적으로 등록하는 단계다.

citation relation은
사실 확인 위치가 준비된 뒤에 연결한다.


# 6. SourceDocument 규칙

SourceDocument마다 최소한 확인한다.

- university
- academic_year
- source_type
- official title
- issuing organization
- official URL
- published date, 공식적으로 알려진 경우만
- last_checked_at
- document version label, 확인된 경우만
- revision relationship, 확인된 경우만

`source_url` 자체를 identity로 사용하지 않는다.
같은 URL이어도 개정본이면 별도 SourceDocument가 될 수 있다.

수정본을 발견해도
기존 SourceDocument를 overwrite하지 않는다.
이전 source history를 보존한다.

확인된 후속본은
`supersedes_source_document_id`로
이전 SourceDocument를 가리킬 수 있다.
자기 자신을 supersede하지 않는다.

`published_at`은 공식 게시일이 날짜로만 알려진 경우
시각을 임의로 만들지 않는다.

`last_checked_at`은 source를 마지막으로 확인한 시점이다.
내용이 재검증되었다는 뜻이 아니며
`updated_at` / `verified_at`과 같지 않다.


# 7. SourceCitation 규칙

Citation은 실제 source에서
fact가 확인되는 정확한 위치를 나타낸다.

PDF:

- `file_page_number` = physical PDF page, 1-based
- `printed_page_label` = 문서 내부 표시 page

둘을 혼동하지 않는다.

가능하면 다음을 함께 기록한다.

- physical page
- printed page
- section
- anchor description

`file_page_number`가 있으면 1 이상이어야 한다.
페이지를 모르면 0이나 음수를 넣지 않고 NULL로 둔다.

Citation이 가리키는 SourceDocument는
해당 AdmissionProgram의
`admission_program_sources`에도 등록되어야 한다.
자세한 검사는 8절을 따른다.


# 8. Program ↔ Source consistency

현재 DB는
Entity → Citation → SourceDocument가 존재한다고 해서
AdmissionProgram ↔ SourceDocument 관계가
반드시 존재하는 것을 constraint로 강제하지 않는다.

이것은 known limitation이며
schema를 우회하는 trigger로 메우지 않는다.

따라서 data load validation에서 다음을
mandatory rule로 적용한다.

모든 citation의 SourceDocument가
해당 AdmissionProgram의
`admission_program_sources`에도 등록되어 있어야 한다.

검사 대상:

- AdmissionSectionCitation
- RequiredDocumentCitation
- DocumentSubmissionCitation
- AdmissionScheduleCitation

하나라도 program source 목록에 없는
SourceDocument를 가리키면 load를 통과시키지 않는다.

AdmissionProgramSource는
citation보다 먼저 준비하는 것을 기본으로 한다.


# 9. Verification rules

`verified_at`은
실제 공식 source 확인이 수행된 시각만 기록한다.

row insert 시 자동으로 verified 처리하지 않는다.
`set_updated_at` trigger는 `verified_at`을 건드리지 않는다.

AdmissionProgram.verified_at은
program 전체의 주요 항목을 검토했을 때만 변경한다.

child entity 하나만 확인했다고
program 전체 `verified_at`을 갱신하지 않는다.

예:

DocumentSubmission.verified_at을 갱신해도
RequiredDocument 또는 AdmissionProgram이
자동 재검증된 것으로 보지 않는다.

`updated_at`은 기술 수정 시각이다.
오타 수정이나 내부 분류 변경은
`updated_at`만 바뀌고 `verified_at`은 유지될 수 있다.


# 10. Unknown / absence handling

공식 자료에 정보가 없다고 해서
다음처럼 추론하지 않는다.

- 없음
- 제출 불필요
- 요구하지 않음

상황에 따라 다음을 구분한다.

- `not_found_in_official_source`
- `unknown`
- `needs_confirmation`
- `not_applicable`

`not_applicable`은
공식 자료가 해당 항목이 적용되지 않는다고
명시한 경우에만 사용한다.

특히 다음 항목은
공식 근거 없이 임의 값을 넣지 않는다.

- SAT
- IB
- AP
- TOEFL
- IELTS
- 제출서류
- 지원자격
- 일정

확인되지 않은 항목은 비워 두거나
위 상태 중 하나로 표시한다.


# 11. Same academic year rule

2027 data에는
2026 / 2025 모집요강 내용을 섞지 않는다.

같은 program 이름이어도
`academic_year`가 다르면 별도 dataset이다.

과거 학년도 source는
현재 학년도 규정 보완용으로 추론에 사용하지 않는다.

과거 source는
개정 이력이나 참고 맥락으로만 남길 수 있다.
그 내용을 2027 규정 field에 복사하지 않는다.


# 12. Conflict handling

공식 source끼리 충돌하면:

1. 양쪽 SourceDocument를 보존한다.
2. 더 구체적이고 authoritative한 official source를 우선 검토한다.
3. 선택 근거를 notes / provenance에 기록한다.
4. `needs_review`를 사용할 수 있다.
5. 임의로 "오타"라고 단정하지 않는다.
6. correction notice가 있으면 별도 SourceDocument로 보존한다.

충돌을 숨기기 위해
한쪽 source를 삭제하거나 overwrite하지 않는다.


# 13. Data mutation policy

이미 적용된 migration 파일을
나중에 수정하지 않는다.

검증 데이터 수정이 필요하면
새 data migration을 생성한다.

기존 migration history를 rewrite하지 않는다.

DB row를 Table Editor에서
직접 수정하는 방식은 원칙적으로 사용하지 않는다.


# 14. Initial MVP data deployment strategy

초기 5개 대학 MVP에서는
verified official admissions data를
version-controlled SQL data migration으로
관리하는 방향을 recommended initial strategy로 한다.

Schema migration과 data migration은
파일 이름과 목적을 구분한다.

예:

- `*_initial_schema.sql`
- `*_load_ku_2027_reentry.sql`

실제 파일명은 다음 단계에서 결정한다.

`supabase/seed.sql`은
production verified admission data의
source of truth로 사용하지 않는다.

seed는 local / demo fixture 용도로만 검토한다.
실제 대학 입시 규정은 seed에 넣지 않는다.


# 15. Data migration principle

data migration은 다음을 지킨다.

- 공식 검증된 값만 포함
- transaction-safe 방향
- 필요한 FK dependency order 준수
- production admissions data 외 test fixture 포함 금지
- destructive delete 금지
- 기존 row를 조용히 overwrite 금지

초기 data load는 insert-oriented approach를 기본으로 한다.

이미 데이터가 존재하면
무조건 UPDATE / UPSERT하지 말고
conflict를 검토하게 설계한다.

synthetic fixture 이름
(Test University A 등)을
verified admission data migration에 섞지 않는다.


# 16. Technical ID rule

UUID는 기술적 identity일 뿐
입시 규정 의미가 없다.

slug / official program name을 PK처럼 사용하지 않는다.

데이터 migration에서 ID reference 전략은
SQL 작성 단계에서 결정한다.

이번 문서에서는 구체 UUID 값을 생성하지 않는다.


# 17. Pre-import checklist

data migration 작성 전 최소 확인:

- academic year
- university
- campus
- official program name
- source URLs
- source version
- verified date
- page mappings
- required sections
- schedules
- documents
- submission phases
- choice relationships
- source citations

확인되지 않은 항목은 억지로 채우지 않는다.


# 18. Post-import validation

DB 적용 후 최소 확인:

1. expected University 존재
2. expected Program 존재
3. academic_year 정확
4. source_documents 존재
5. admission_program_sources 연결
6. sections count / 내용
7. schedules
8. documents
9. submissions
10. choice groups
11. citations
12. citation source page
13. orphan relation 없음
14. provenance consistency
    (모든 citation SourceDocument가 program sources에 등록됨)
15. unexpected data 없음

첫 KU load에서는
이 범위 밖의 대학 / 전형 / 학년도 row가
함께 들어가면 실패로 본다.


# 19. Rollback / correction principle

입시 data가 잘못 입력됐다고 해서
기존 migration 파일을 수정하거나 삭제하지 않는다.

아직 development only이고 적용 직후 오류가 발견되더라도
어떻게 수정할지는 별도 review 후 결정한다.

운영 환경에서는
새 correction migration을 기본 방향으로 한다.

historical provenance를 보존한다.


# 20. Manual editing policy

Supabase Table Editor는
조회 / 검증 용도로 사용할 수 있다.

verified production admission facts를
직접 수동 입력 / 수정하는 기본 경로로 사용하지 않는다.

SQL Editor에서 ad-hoc INSERT / UPDATE도
기본 운영 경로로 사용하지 않는다.

예외가 필요하면
별도 review 후 data migration으로 남긴다.


# 21. KU first-load workflow

첫 데이터 적재 workflow:

Step 1.
2027 KU official sources 다시 확인

Step 2.
Source inventory 작성

Step 3.
row-level data map 작성

Step 4.
citation map 작성

Step 5.
data completeness / conflict review

Step 6.
version-controlled data migration 작성

Step 7.
static review

Step 8.
PostgreSQL runtime validation

Step 9.
hosted dry-run

Step 10.
development DB apply

Step 11.
read-only post-import validation

Step 6 이전에는
실제 admissions data SQL을 작성하지 않는다.


# 22. Expansion order

KU 성공 후 같은 ingestion workflow를 적용한다.

1. Yonsei
2. Sogang
3. Hanyang
4. SKKU

두 대학에서 검증된 구조라고 해서
나머지 대학의 pattern을 추정하지 않는다.

각 대학의 공식 2027 자료를
그 대학 적재 직전에 다시 확인한다.


# 23. 다음 단계

이 문서가 완료되면 다음 작업은
KU 2027 Data Source Inventory + Row Map 작성이다.

그 단계에서 처음으로
공식 KU 2027 자료를 다시 열고
실제 row 단위 값을 추출 / 검증한다.

그 다음에만 data migration SQL을 작성한다.


# 24. 관련 문서

- `AGENTS.md`
- `docs/DATA_MODEL.md`
- `docs/DB_SCHEMA_DRAFT.md`
- `docs/MVP_DATA_SCOPE.md`
- `docs/DATA_MODEL_VALIDATION_2027.md`
- `docs/DB_SCHEMA_VALIDATION_KU_2027.md`
