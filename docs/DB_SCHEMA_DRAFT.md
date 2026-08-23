# DB_SCHEMA_DRAFT

이 문서는 `docs/DATA_MODEL.md`의 conceptual / logical model을
PostgreSQL에서 구현 가능한
table / column / relation / constraint 수준으로 구체화한다.

이 문서는 아직 실제 SQL DDL이 아니다.
database instance, Supabase project, migration, Prisma는
이번 단계에서 생성하지 않는다.

다음 단계에서
2027학년도 고려대학교와 연세대학교의
3년 특례 관련 공식 자료를 실제 row 형태로 대입하여
schema를 검증하기 위한 초안이다.

실제 official_program_name, source URL,
eligibility rule, 일정, 서류명, 입시 수치는
이번 문서에 작성하지 않는다.

"3년 특례"는 내부 분류 및 사용자 이해용 표현이다.
모든 대학의 official_program_name이
"3년 특례"라고 가정하지 않는다.


# 1. 문서 목적

DATA_MODEL이 답하는 질문:

"입시정보를 어떤 구조로 저장해야 하는가"

DB_SCHEMA_DRAFT가 답하는 질문:

"그 구조를 PostgreSQL table로 어떻게 옮길 수 있는가"

아직 답하지 않는 질문:

- 실제 CREATE TABLE SQL은 무엇인가
- 어떤 migration 파일을 만드는가
- Supabase를 최종 채택하는가
- 실제 2027 입시 row는 무엇인가


# 2. 설계 원칙

1. 정확성 > 편의성
2. official source traceability를 보존한다.
3. academic_year를 섞지 않는다.
4. 대학/캠퍼스를 혼동하지 않는다.
5. 확인되지 않은 값을 임의 생성하지 않는다.
6. updated_at과 verified_at은 다른 의미다.
7. source revision history를 보존한다.
8. parent experience와 official fact를 분리한다.
9. eligibility 자동 판정은 deterministic rule만 허용한다.
10. MVP에서 불필요한 normalization은 피한다.

Campus entity와 AdmissionTrack은
이번 schema draft의 필수 table이 아니다.


# 3. Primary Key 전략

모든 주요 entity의 PK는
PostgreSQL UUID를 사용하는 방향을
schema 초안의 recommended default로 둔다.

예:

id: uuid

추천 이유:

- 외부 노출 identifier로 사용하기 상대적으로 안전하다.
- 여러 환경/향후 데이터 import에서 충돌 가능성이 낮다.
- Supabase/PostgreSQL과 자연스럽게 사용할 수 있다.
- 순차 bigint를 public URL identity처럼 사용하지 않아도 된다.

UUID 사용을 최종 확정하지는 않는다.
실제 DDL 전에 한 번 더 확인한다.

slug는 PK가 아니다.
slug는 routing / human-readable lookup key다.


# 4. University

table concept:

universities

필드 초안:

- id
- name_ko
- name_en nullable
- campus_name nullable
- display_name
- slug
- official_website_url nullable
- admissions_office_url nullable
- created_at
- updated_at

검토할 constraint:

- id PK
- slug UNIQUE
- display_name을 identity로 사용하지 않음

campus 관련 원칙:

MVP에서는 별도 campuses table을 만들지 않는다.

University row는
입학전형을 정확히 귀속시킬 수 있는
대학/캠퍼스 단위로 사용한다.

서로 다른 입학처 또는 모집요강을 운영하는 캠퍼스를
하나의 University row로 무조건 합치지 않는다.

사람이 이해하는 uniqueness 관점에서는
name_ko + campus_name을 고려할 수 있다.

실제 unique constraint는 지금 확정하지 않는다.

이유와 trade-off:

- campus_name은 nullable이다.
  캠퍼스 구분이 필요 없는 대학과
  필요한 대학을 같은 unique 규칙으로 묶기 어렵다.
- 공식 캠퍼스 표기가 자료마다 다를 수 있다.
- unique를 너무 일찍 걸면
  실제 공식 명칭 확인 전에 잘못된 조합이 고정된다.
- unique를 두지 않으면
  같은 대학/캠퍼스가 중복 row로 들어갈 위험이 있다.
- 현재는 slug UNIQUE와
  운영 규칙(다른 입학처/요강은 다른 University row)으로 충분할 수 있다.

실제 구축 대상 campus는
각 대학 공식 입학처와 2027학년도 모집요강을
검증한 뒤에 명시한다.
확인되지 않은 campus 정보는 추측하지 않는다.


# 5. AdmissionCategory

table concept:

admission_categories

목적:

사이트 내부 탐색/분류를 위한 taxonomy.

예를 들어 MVP에서 사용자가 이해하는
"3년 특례 관련" 같은 분류를 표현할 수 있다.

중요:

실제 대학의 official_program_name과
동일 개념이 아니다.

필드 초안:

- id
- code
- label
- description nullable
- created_at
- updated_at

constraint 검토:

- code UNIQUE

실제 code 값은 아직 정하지 않는다.
실제 production category data도 만들지 않는다.


# 6. AdmissionProgram

table concept:

admission_programs

DATA_MODEL의 핵심 정의를 유지한다.

AdmissionProgram =
지원자격, 평가방법, 제출서류, 대학비교,
대학별 자격진단을 독립적으로 적용할 수 있는
가장 작은 공식 전형 단위.

하나의 모집요강 문서 자체가
비교 또는 자격판정 단위가 아니다.

필드 초안:

- id
- university_id
- admission_category_id nullable
- academic_year
- official_program_name
- display_name
- admission_slug
- information_type
- verification_status
- verified_at nullable
- notes nullable
- created_at
- updated_at

검토할 constraint:

- university_id FK → universities.id
- admission_category_id FK → admission_categories.id, nullable
- academic_year NOT NULL
- official_program_name NOT NULL
- admission_slug NOT NULL

slug를 historical identity로 사용하지 않는다.
slug가 바뀌어도 전형의 역사적 identity는
immutable PK(id)로 유지한다.

display_name은 공식 의미를 바꾸거나
새로운 전형을 만들지 않는다.


## AdmissionProgram UNIQUE 후보

다음 조합은 routing convenience에는 유용할 수 있다.

(university_id, academic_year, admission_slug)

그러나 이 조합이
semantic identity를 뜻하지는 않는다.

실제 unique constraint를 확정하기 전에
고려대학교와 연세대학교의
2027학년도 3년 특례 관련 실제 data 검증이 필요하다.

검토 이유:

- admission_slug 변경 시 unique를 유지하려면
  과거 URL 처리가 필요하다.
- 같은 대학/학년도에
  slug는 다르지만 공식 전형명이 유사한 경우가
  있는지 확인해야 한다.
- official_program_name unique는
  표기 차이 때문에 위험할 수 있다.


# 7. AdmissionSection

table concept:

admission_sections

필드 초안:

- id
- admission_program_id
- section_type
- title
- content
- information_type
- availability_status
- verification_status
- verified_at nullable
- display_order
- created_at
- updated_at

관계:

admission_programs 1 → N admission_sections

중요:

같은 AdmissionProgram 안에
동일한 section_type이 여러 개 존재할 수 있다.

예: eligibility를
공통 조건 / 학생 조건 / 부모 조건처럼
여러 section row로 나눌 수 있다.

위 예는 구조만 보여 주기 위한 것이며
실제 입시조건 예시가 아니다.

따라서 다음 constraint는 금지 후보다.

UNIQUE(admission_program_id, section_type)

대신 display_order를 사용해 순서를 관리한다.
title로 같은 section_type 안의 의미를 구분할 수 있다.

향후 stable internal identifier가 필요하면
section_key 등을 검토할 수 있다.
이번에는 넣지 않는다.


# 8. RequiredDocument

table concept:

required_documents

필드 초안:

- id
- admission_program_id
- name
- description nullable
- requirement_status
- condition nullable
- submission_phase nullable
- display_order
- verification_status
- verified_at nullable
- created_at
- updated_at

submission_phase는
같은 전형에서 서류가
서로 다른 제출 단계에 요구될 수 있음을 표현한다.

실제 submission_phase enum 값은 아직 확정하지 않는다.

확인되지 않은 제출 단계를 임의로 생성하지 않는다.

한 RequiredDocument가
여러 submission phase 또는 여러 schedule event와
연결되는 실제 사례가 반복되면
별도 submission entity 또는 join structure를 검토할 수 있다.

이번 schema draft에서는
새 submission table을 만들지 않는다.


# 9. AdmissionSchedule

table concept:

admission_schedules

필드 초안:

- id
- admission_program_id
- event_name
- start_at nullable
- end_at nullable
- timezone nullable
- description nullable
- verification_status
- verified_at nullable
- display_order
- created_at
- updated_at

단일 날짜 표현 후보:

A. start_at만 사용하고 end_at는 null
B. start_at = end_at

A의 장점:

- 기간이 아닌 event를 명확히 구분하기 쉽다.

A의 단점:

- end_at null이 "미정"인지 "단일 날짜"인지
  다른 상태와 겹칠 수 있다.

B의 장점:

- 조회 시 start/end 범위 조건이 단순하다.

B의 단점:

- 진짜 기간과 단일 날짜가 같은 모양으로 보인다.

아직 확정하지 않는다.

date-only event와
time-specific event가 모두 존재할 수 있다.
timestamp type도 schema validation 후 확정한다.


# 10. RequiredDocument ↔ AdmissionSchedule

DATA_MODEL은 optional relation 가능성을 열어 두었다.

이번 draft에서는 바로 FK를 넣지 않는다.

두 후보를 비교한다.


## A. required_documents.admission_schedule_id nullable

장점:

- table이 늘지 않는다.
- 한 document가 대표 일정 하나에 묶이는 경우 단순하다.
- 한 일정에 여러 documents를 연결할 수 있다.

단점:

- 한 document가 여러 일정/제출 단계와 연결되면 부족하다.
- schedule이 없는 document와
  schedule이 아직 확인되지 않은 document를
  같은 null로 오해할 수 있다.


## B. required_document_schedule_links join table

장점:

- 한 document ↔ 여러 schedule
- 한 schedule ↔ 여러 document
- 이후 제출 단계가 복잡해져도 확장하기 쉽다.

단점:

- MVP 초기에 table과 운영 규칙이 늘어난다.
- 실제 사례가 거의 1:1이면 과도할 수 있다.


## 현재 추천안

고려대학교/연세대학교 실제 data 검증 전에는
어느 쪽도 최종 확정하지 않는다.

현재 recommended draft:

1. 최초 core schema에는 이 relation을 넣지 않는다.
2. 검증에서 한 document가 대표 일정 하나에만 묶이면 A를 검토한다.
3. 한 document가 여러 schedule/phase와 반복 연결되면 B를 검토한다.

평가 기준:

- 한 document가 여러 일정과 연결될 가능성
- 한 일정에 여러 documents가 연결될 가능성
- MVP simplicity
- future extensibility


# 11. SourceDocument

table concept:

source_documents

필드 초안:

- id
- university_id nullable
- academic_year nullable
- source_type
- title
- issuing_organization
- source_url
- published_at nullable
- last_checked_at
- document_version_label nullable
- supersedes_source_document_id nullable
- notes nullable
- created_at
- updated_at

university_id가 null일 수 있는 이유:
특정 대학에 속하지 않는 공식 자료가 있을 수 있다.

academic_year가 null일 수 있는 이유:
학년도를 특정하지 않는 일반 안내가 있을 수 있다.
학년도 없는 자료를
특정 학년도 공식정보처럼 표시하지 않는다.


## revision lineage

supersedes_source_document_id
→ source_documents.id self-reference 후보

의미:

현재 SourceDocument가
이전 공식 SourceDocument를 대체/수정하는 관계를 표현한다.

원칙:

- 수정본이 나와도 이전 source row 삭제 금지
- 기존 source row 덮어쓰기 금지
- latest published_at = current source라고 단정하지 않음
- version lineage 추적 가능
- 새 revision이 발견됐다고
  연결된 AdmissionProgram 전체가
  자동 재검증된 것으로 처리하지 않음

is_current boolean은 아직 두지 않는다.

실제 self-referencing FK 여부와 이름은
SQL 단계에서 최종 확정한다.


## source_url UNIQUE

source_url UNIQUE를 두면 안 될 가능성이 있다.

이유:

- 동일 URL의 PDF가 교체될 수 있다.
- 같은 URL이 다른 시점의 다른 내용을 가리킬 수 있다.
- revision을 별도 row로 보존하려면
  같은 URL이 여러 row에 등장할 수 있다.

실제 unique 전략은 아직 확정하지 않는다.


# 12. SourceCitation

table concept:

source_citations

필드 초안:

- id
- source_document_id
- file_page_number nullable
- printed_page_label nullable
- section nullable
- anchor_description nullable
- verified_at nullable
- created_at

의미:

file_page_number
= PDF 파일 자체의 page position

printed_page_label
= 문서 내부에 표시된 page number/label

PDF에서는 두 값이 다를 수 있다.
둘을 동일 개념으로 가정하지 않는다.

HTML source에서는
section / anchor_description 중심으로 사용 가능하다.

기존 단일 page 개념은 사용하지 않는 방향을
recommended draft로 둔다.

실제 PostgreSQL field type과 최종 field 이름은
아직 결정하지 않는다.


# 13. Citation 연결 방식

SourceCitation을 다음 entity에 연결할 필요가 있다.

- AdmissionSection
- RequiredDocument
- AdmissionSchedule
- EligibilityRule
- FAQ
- 필요 시 AdmissionProgram-level source

polymorphic table
(entity_type + entity_id)
형태는 referential integrity가 약해질 수 있다.

이번 draft에서도
explicit join table 방식을 recommended default로 둔다.

예:

admission_section_citations
- admission_section_id
- source_citation_id

required_document_citations
- required_document_id
- source_citation_id

admission_schedule_citations
- admission_schedule_id
- source_citation_id

eligibility_rule_citations
- eligibility_rule_id
- source_citation_id

faq_citations
- faq_id
- source_citation_id

필요한 경우
admission_program_citations
- admission_program_id
- source_citation_id

중요:

실제 모든 join table을 반드시
MVP 최초 migration에 넣는다고 확정하지 않는다.

schema 검증을 통해 필요한 것만 결정한다.

각 join table은
(target_id, source_citation_id)
composite UNIQUE 또는 composite PK 후보를 검토한다.

같은 절을 여러 item이 공유하는 경우
하나의 SourceCitation을 여러 join row가 참조할 수 있다.
모든 RequiredDocument 항목에
개별 citation을 강제하지 않는다.


# 14. AdmissionProgram ↔ SourceDocument

AdmissionProgram과 SourceDocument는 1:1이 아니다.

하나의 SourceDocument
→ 여러 AdmissionProgram 가능

하나의 AdmissionProgram
→ 여러 SourceDocument 가능

두 구현 후보를 비교한다.


## A. 간접 관계만 사용

AdmissionProgram → SourceCitation → SourceDocument

장점:

- source의 정확한 위치(citation)가 기본 단위가 된다.
- program-source 직접 join이 없어 중복이 적다.

단점:

- program 전체의 대표 모집요강을
  바로 조회하기 어렵다.
- section citation이 아직 없는 program은
  source 연결이 비어 보일 수 있다.


## B. 직접 join table도 추가

admission_program_sources

- admission_program_id
- source_document_id

장점:

- program 전체의 대표 source를 명확히 표시하기 쉽다.
- 대학전형 상세 상단의 source 목록 query가 단순하다.
- citation보다 거친 단위의 연결을 보존할 수 있다.

단점:

- program-source와 section-citation이 중복될 수 있다.
- 두 경로의 불일치가 생기면
  어느 쪽이 source of truth인지 정해야 한다.


## 현재 추천안

아직 최종 확정하지 않는다.

현재 recommended draft:

- section/document/schedule의 정확한 근거는 citation join을 사용한다.
- program 단위 대표 source가 필요하면
  admission_program_sources를 추가로 검토한다.

평가 기준:

- program 전체의 대표 source 표시
- section-level 정확한 citation
- 중복
- query simplicity
- referential clarity


# 15. EligibilityRule

table concept:

eligibility_rules

필드 초안:

- id
- admission_program_id
- rule_key
- description
- logic
- logic_schema_version
- result_effect
- requires_manual_review
- information_type
- verification_status
- verified_at nullable
- created_at
- updated_at

logic의 실제 JSON schema는 아직 정의하지 않는다.

PostgreSQL JSONB 후보로 기록할 수 있으나
아직 확정하지 않는다.

공식 source에서 deterministic하게
표현 가능한 규칙만 EligibilityRule로 만든다.

모호한 규정이나 예외 조건을
억지로 자동 Rule로 만들지 않는다.

DATA_MODEL implementation priority에서
EligibilityRule은 P2다.

MVP 초기 schema에 table을 포함할지,
후속 migration으로 미룰지:

현재 추천안은 후속 migration이다.

이유:

- 먼저 사람에게 보여줄 공식 지원자격
  (AdmissionSection)을 정확하게 구조화한다.
- 초기 데이터 구축 단계에서
  EligibilityRule 완성률을 목표로 하지 않는다.
- 자격진단 개인정보는 MVP에서
  기본적으로 영구 저장하지 않는다.


# 16. FAQ

table concept:

faqs

필드 초안:

- id
- slug
- question
- answer
- category nullable
- academic_year nullable
- information_type
- verification_status
- verified_at nullable
- publication_status
- created_at
- updated_at

slug UNIQUE 후보.

official_fact 또는 interpretation 성격의 FAQ는
citation 연결이 가능해야 한다.

학년도와 출처가 없는 FAQ를
확정된 공식정보처럼 표시하지 않는다.

실제 FAQ data는 이번 단계에서 만들지 않는다.


# 17. ParentStory

table concept:

parent_stories

필드 초안:

- id
- slug
- title
- summary nullable
- body
- category nullable
- publication_status
- published_at nullable
- created_at
- updated_at

official admissions data와
절대로 같은 information_type으로 취급하지 않는다.

실명 author schema는 MVP에서 가정하지 않는다.

ParentStory는 citation 대상이 아니다.
개인 경험을 official_fact로 변환하지 않는다.


# 18. Status / Enum 전략

현재 conceptual status 후보:

information_type:

- official_fact
- interpretation
- strategic_opinion
- parent_experience
- unverified

verification_status 후보:

- verified
- partially_verified
- needs_review
- unverified

availability_status 후보:

- available
- not_found_in_official_source
- not_applicable
- unknown
- needs_confirmation

publication_status 후보:

- draft
- published
- archived

구현 후보를 비교한다.


## PostgreSQL ENUM

장점:

- 값이 제한되어 무결성이 강하다.
- query와 문서가 명확하다.

단점:

- 값 추가/이름 변경의 migration 비용이 크다.
- 초기 후보가 아직 확정되지 않았다.


## lookup table

장점:

- 라벨, 설명, 정렬을 데이터로 관리할 수 있다.
- 값 추가가 ENUM보다 쉽다.

단점:

- table과 join이 늘어난다.
- 단순 status에는 과도할 수 있다.


## TEXT + CHECK constraint

장점:

- migration으로 허용 값을 비교적 쉽게 바꿀 수 있다.
- 초기 후보가 바뀔 가능성이 있는 MVP에 맞다.
- lookup table보다 단순하다.

단점:

- 값 목록이 여러 table에 반복될 수 있다.
- ENUM보다 문서화 부담이 애플리케이션/문서 쪽으로 간다.


## MVP 추천안

TEXT + CHECK constraint를
schema 초안의 recommended default로 둔다.

이유:

- 현재 status 후보는 conceptual이며 최종 enum이 아니다.
- ENUM 변경 비용을 초기에 지지 않는다.
- lookup table은 라벨 관리가 필요해질 때 검토한다.

아직 SQL은 작성하지 않는다.

"공식자료에서 찾지 못함"을
"요구하지 않음"으로 해석하지 않는다.
not_found_in_official_source와
not_applicable을 같은 값으로 두지 않는다.


# 19. academic_year type

후보:

A. integer
예: 2027

B. text
예: "2027"

A의 장점:

- 정렬, 비교, 동일 학년도 필터가 단순하다.
- 대학비교에서 같은 academic_year끼리만 묶기 쉽다.

A의 단점:

- "2027-1" 같은 세부 cycle이 생기면 부족할 수 있다.

B의 장점:

- 표기 변형을 받아들이기 쉽다.

B의 단점:

- "2027", "2027학년도", "27"이
  서로 다른 값으로 들어갈 위험이 있다.

MVP 추천안:

integer를 recommended default로 둔다.

"2027학년도" 같은 UI text를
DB에 그대로 저장하지 않는다.

UI 표시는 application에서 만든다.

실제 type은
고려대/연세대 schema validation 후 최종 확정한다.

다른 academic_year의 데이터를
하나의 비교표나 하나의 AdmissionProgram에 섞지 않는다.


# 20. Timestamp 원칙

created_at
= row가 처음 생성된 시점

updated_at
= row가 기술적으로 수정된 시점

verified_at
= 공식 자료와 대조하여 내용이 검증된 시점

published_at
= 공식 자료 또는 콘텐츠가 게시된 시점

last_checked_at
= source를 마지막으로 확인한 시점.
  내용이 재검증되었다는 뜻은 아니다.

특히:

updated_at
≠
verified_at

오타 수정이나 내부 분류 변경은
updated_at만 바뀌고 verified_at은 유지될 수 있다.

AdmissionProgram.verified_at은
전형 전체 검토가 완료된 경우에만 갱신한다.

child entity는 별도의 verified_at을 가질 수 있다.

timezone이 필요한 timestamp에는
PostgreSQL timestamptz를 사용하는 방향을 검토한다.

date-only official 일정에 대해서는
별도 date field가 필요한지
schema validation에서 확인할 항목으로 남긴다.


# 21. Delete 정책

각 주요 relation에서
무조건 CASCADE를 사용하지 않는다.

특히 source history가 삭제되는 것을 방지해야 한다.

검토 기준:

University 삭제
= 연결된 program/source가 많으므로
  production에서 hard delete를 기본으로 두지 않는다.

AdmissionProgram 삭제
= 과거 학년도 program을 삭제하지 않는다.
  새 학년도가 발표되어도 이전 program을 보존한다.

SourceDocument 삭제
= 수정본이 생겨도 이전 source를 삭제하거나 덮어쓰지 않는다.

Citation 삭제
= 근거 추적이 사라지지 않도록
  신중하게 제한한다.

child entity 삭제
= program을 유지한 채 개별 section/document/schedule을
  정리할 수는 있으나
  검증 이력 손실을 고려해야 한다.

production admissions data는
hard delete보다 archive/status가 더 적합할 수 있다.

실제 ON DELETE 정책은
SQL 단계에서 확정한다.


# 22. Index 후보

아직 index를 생성하지 않는다.
query 기준의 후보만 적는다.

universities
- slug

admission_programs
- university_id
- academic_year
- admission_category_id
- (university_id, academic_year)

admission_sections
- admission_program_id
- (admission_program_id, section_type)

required_documents
- admission_program_id

admission_schedules
- admission_program_id

source_documents
- university_id
- academic_year

source_citations
- source_document_id

citation join tables
- target entity id
- source_citation_id

실제 index는
UI/query pattern 확인 후 최소한으로 확정한다.


# 23. P0 / P1 / P2 / P3

이것은 제품 기능 우선순위가 아니라
DB schema build sequence다.


## P0

- universities
- admission_categories
- admission_programs
- admission_sections
- source_documents
- source_citations
- 필요한 citation relation

P0 설계 시 schema 전에 반드시 검토할 것:

- campus discriminator
- source revision
- citation page representation
- same-type AdmissionSection 허용


## P1

- required_documents
- admission_schedules
- 관련 citation relation

P1 구현 시 submission_phase를 함께 검토한다.


## P2

- eligibility_rules


## P3

- faqs
- parent_stories


# 24. MVP 최초 migration 후보

실제 migration은 만들지 않는다.


## Initial core 후보

- universities
- admission_categories
- admission_programs
- admission_sections
- source_documents
- source_citations
- 필요한 source/citation join tables
- required_documents
- admission_schedules

이 구성은 DATA_MODEL의 P0+P1과 맞다.

MVP_SPEC / MVP_DATA_SCOPE 기준으로도
대학전형 탐색, 비교, 출처 표시에
필요한 최소 데이터 영역이다.


## Deferred 후보

- eligibility_rules
- faqs
- parent_stories

이 구성은 DATA_MODEL의 P2+P3와 맞다.

자격진단 자동 Rule과
FAQ / 학부모 경험은
공식 전형 데이터가 먼저 안정된 뒤 연결하는 편이 안전하다.

EligibilityRule을 초기 migration에 넣지 않는다고
자격진단 기능 자체를 포기한다는 뜻은 아니다.
사람용 eligibility section을 먼저 구축한다.


# 25. Schema Validation Checklist

2027학년도 고려대학교와 연세대학교의
3년 특례 관련 공식 자료를
실제 row 형태로 대입할 때 사용한다.

전교육과정 해외이수자 전형은
제품 전체 범위에서는 고려할 수 있으나
이번 production mapping 범위에서는 제외한다.

1. 한 대학/campus를 정확히 식별 가능한가?
2. 2027 academic_year가 다른 연도와 섞이지 않는가?
3. 공식 전형명을 손실 없이 저장 가능한가?
4. 하나의 source document가 여러 program을 지원할 수 있는가?
5. 하나의 program이 여러 source document를 사용할 수 있는가?
6. eligibility section을 여러 개 저장 가능한가?
7. required document 조건을 저장 가능한가?
8. document submission phase를 표현 가능한가?
9. 일정 단일 날짜/기간을 표현 가능한가?
10. PDF file page / printed page를 모두 추적 가능한가?
11. 수정 모집요강 lineage를 추적 가능한가?
12. section/document/schedule별 source citation이 가능한가?
13. verified_at을 program과 child별로 분리 가능한가?
14. 공식자료 미확인 상태를 false 또는 not required로 오해하지 않는가?
15. 다른 campus source를 잘못 연결하는 것을 방지 가능한가?
16. 불필요한 duplicate가 과도하게 발생하지 않는가?
17. AdmissionTrack 없이 실제 구조가 자연스럽게 들어가는가?


# 26. Open Decisions

schema validation 전에 아직 확정하지 않은 사항:

- UUID 최종 확정
- University uniqueness constraint
- AdmissionProgram UNIQUE 전략
- RequiredDocument ↔ Schedule relation 방식
- SourceDocument current/revision 표현
- AdmissionProgram ↔ Source 직접 join 필요 여부
- status 구현 방식
- academic_year DB type 최종 확정
- date-only vs timestamptz 일정
- EligibilityRule 초기 migration 포함 여부
- ON DELETE 정책
- index 최종 구성
- source_url unique 여부
- citation join table의 최초 migration 범위
- submission_phase 허용 값
- campuses table 도입 여부
- AdmissionTrack 도입 여부


# 27. 다음 단계

1. DB_SCHEMA_DRAFT 리뷰
2. 2027 고려대학교 3년 특례 관련 공식 자료를
   schema row 구조에 mapping
3. schema gap 기록
4. 2027 연세대학교 동일 범위로 반대 검증
5. schema 수정
6. SQL DDL/migration 설계
7. Supabase project/database 구축

실제 schema를 확정하기 전에
고려대와 연세대 공식 자료를 이용해
최소 한 번 더 검증한다.
