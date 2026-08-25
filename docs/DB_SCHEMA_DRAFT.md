# DB_SCHEMA_DRAFT

이 문서는 `docs/DATA_MODEL.md`의 conceptual / logical model을
PostgreSQL에서 구현 가능한
table / column / relation / constraint 수준으로 구체화한다.

이 문서는 아직 실제 SQL DDL이 아니다.
database instance, Supabase project, migration, Prisma는
이번 단계에서 생성하지 않는다.

이 문서는
`docs/DB_SCHEMA_VALIDATION_KU_2027.md`와
`docs/DB_SCHEMA_VALIDATION_YONSEI_2027.md`
두 validation에서 반복 확인된 실제 pattern을 반영한
refined logical schema다.

이전 draft의 최종 평가는
"refinement required before SQL"이었다.
이번 문서는 그 결과와 SQL 직전 open decision 정리를 반영한다.

현재 평가:

Logical schema refined after KU + Yonsei validation.
Ready for final documentation synchronization
and PostgreSQL DDL design.

DATA_MODEL 동기화와
SQL-level constraint review가 끝나기 전까지
migration-ready라고 부르지 않는다.

실제 official_program_name, source URL,
eligibility rule, 일정, 서류명, 입시 수치는
이번 문서에 작성하지 않는다.

"3년 특례"는 내부 분류 및 사용자 이해용 표현이다.
모든 대학의 official_program_name이
"3년 특례"라고 가정하지 않는다.

KU + Yonsei 두 사례만으로
모든 대한민국 대학 전형 구조를 일반화하지 않는다.


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
5. University campus와 event venue/location을 혼동하지 않는다.
6. 확인되지 않은 값을 임의 생성하지 않는다.
7. updated_at과 verified_at은 다른 의미다.
8. source revision history를 보존한다.
9. parent experience와 official fact를 분리한다.
10. eligibility 자동 판정은 deterministic rule만 허용한다.
11. MVP에서 불필요한 normalization은 피한다.
12. date-only 일정에 임의의 시각을 생성하지 않는다.
13. official source conflict를 조용히 덮어쓰지 않는다.
14. logical document requirement와 submission event를 분리한다.

Campus entity와 AdmissionTrack은
이번 schema draft의 필수 table이 아니다.

evaluation child table,
source_conflict table,
source URL alias table도
이번 initial schema에 넣지 않는다.


# 3. Primary Key 전략

주요 entity의 PK는 PostgreSQL native uuid type이다.

refined recommendation:

- PostgreSQL native uuid type
- DEFAULT gen_random_uuid()
- UUIDv4 사용
- slug는 PK가 아님

UUIDv7은 현재 initial MVP에서 사용하지 않는다.

이유:

- gen_random_uuid()는 PostgreSQL 기본 기능으로 널리 지원된다.
- Supabase/PostgreSQL 환경 호환성을 단순하게 유지한다.
- 현재 규모에서 UUIDv7 ordering optimization이 필수 요구사항이 아니다.

database identity는 UUID라는 원칙은 유지한다.

slug는 routing / human-readable lookup key다.

AdmissionProgram의 경우:

UUID id
= immutable database identity

admission_slug
= route identifier

slug가 바뀌어도 UUID identity는 유지한다.

pure join table의 PK는
UUID PK vs composite PK 중 하나를
SQL DDL 작성 시 최종 선택한다.
중복 relation은 어느 쪽이든 허용하지 않는다.


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

확정 constraint:

- id UUID PK
- slug UNIQUE
- display_name을 identity로 사용하지 않음

initial schema에서는

UNIQUE(name_ko, campus_name)

을 적용하지 않는다.

이유:

- campus_name nullable 가능
- 대학/캠퍼스 표기 normalization 문제
- 대학 명칭 변경 가능성
- 아직 5개 대학 전체 mapping 전

중복 University 생성은
초기 admin/data validation 과정에서 방지한다.

향후 실제 데이터가 충분하면
normalized uniqueness constraint를 다시 검토한다.

campus 관련 원칙:

MVP에서는 별도 campuses table을 만들지 않는다.

University row는
입학전형을 정확히 귀속시킬 수 있는
대학/캠퍼스 단위로 사용한다.

서로 다른 입학처 또는 모집요강을 운영하는 캠퍼스를
하나의 University row로 무조건 합치지 않는다.

campus_name은 입학전형 운영 단위다.
면접/시험/제출 장소는 AdmissionSchedule.location_text다.
둘을 같은 개념으로 처리하지 않는다.

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

확정 constraint:

- university_id FK → universities.id
- admission_category_id FK → admission_categories.id, nullable
- academic_year NOT NULL
- official_program_name NOT NULL
- admission_slug NOT NULL
- UNIQUE(university_id, academic_year, admission_slug)

display_name은 공식 의미를 바꾸거나
새로운 전형을 만들지 않는다.


## AdmissionProgram routing UNIQUE

initial schema에 다음 constraint를 적용한다.

UNIQUE(
  university_id,
  academic_year,
  admission_slug
)

의미:

routing uniqueness only.

UUID
= immutable identity

admission_slug
= route identifier

위 UNIQUE는 semantic/historical identity가 아니다.

slug가 바뀌더라도
AdmissionProgram의 UUID identity는 유지한다.

official_program_name unique는
표기 차이 때문에 사용하지 않는다.


# 7. AdmissionSection

table concept:

admission_sections

필드 초안:

- id
- admission_program_id
- section_type
- title
- content
- applicability_text nullable
- information_type
- availability_status
- verification_status
- verified_at nullable
- display_order
- created_at
- updated_at

관계:

admission_programs 1 → N admission_sections


## same-type section 복수

같은 AdmissionProgram 안에
동일한 section_type이 여러 개 존재할 수 있다.

예: eligibility를
공통 조건 / 학생 조건 / 부모 조건처럼
여러 section row로 나눌 수 있다.

위 예는 구조만 보여 주기 위한 것이며
실제 입시조건 예시가 아니다.

따라서 다음 constraint는 금지한다.

UNIQUE(admission_program_id, section_type)

대신 display_order를 사용해 순서를 관리한다.
title로 같은 section_type 안의 의미를 구분할 수 있다.

향후 stable internal identifier가 필요하면
section_key 등을 검토할 수 있다.
이번에는 넣지 않는다.


## applicability_text

같은 AdmissionProgram 안에서도
특정 계열 / 모집단위 / 대상에게만
해당 section이 적용될 수 있다.

applicability_text는
사람이 읽는 적용범위/조건 설명이다.

EligibilityRule과 다른 개념이다.

- applicability_text:
  사람이 읽는 적용범위/조건 설명
- EligibilityRule:
  deterministic 자동 판정 logic

이번 MVP에서는
별도의 applicability table이나 JSON 구조를 만들지 않는다.

향후 반복 query/filter가 필요해지면
structured applicability model을 검토할 수 있다.


# 8. RequiredDocument

table concept:

required_documents

역할:

"무엇을 제출해야 하는가"

라는 logical document requirement.

제출 단계, 제출 방식, 원본/사본, 기한은
RequiredDocument가 아니라
DocumentSubmission에 둔다.


## submission_phase 제거

required_documents.submission_phase는
최종 schema 후보에서 제거한다.

submission_phase는 DocumentSubmission에만 존재한다.

한 logical document를
제출 단계 때문에 복제하지 않는다.


필드 초안:

- id
- admission_program_id
- name
- description nullable
- requirement_status
- condition nullable
- document_subject_text nullable
- display_order
- verification_status
- verified_at nullable
- created_at
- updated_at

관계:

admission_programs 1 → N required_documents


## document_subject_text

recommended final naming:

document_subject_text

의미:

이 document requirement가
누구에 관한 서류인지 / 누구에게 요구되는지
공식 의미를 사람이 읽을 수 있게 보존한다.

physical submitter와 동일 개념이라고 가정하지 않는다.

실제 submission 방식은
DocumentSubmission에서 관리한다.

structured subject enum/lookup은 만들지 않는다.
향후 확장으로 유지한다.

실제 production value는 이번 문서에 만들지 않는다.


# 9. DocumentSubmission

table concept:

document_submissions

목적:

RequiredDocument 자체와
실제 제출 행위를 분리한다.

RequiredDocument
= 무엇을 제출해야 하는가

DocumentSubmission
= 언제 / 어떻게 / 어떤 형태로 제출하는가

KU와 Yonsei 모두에서
같은 logical document가
여러 submission event를 가질 수 있음이 확인되었다.

관계:

RequiredDocument
1 → N DocumentSubmission

이 구조는 initial schema의 core다.


필드 초안:

- id
- required_document_id
- submission_phase
- submission_method nullable
- submission_format nullable
- admission_schedule_id nullable
- instructions nullable
- display_order
- verification_status
- verified_at nullable
- created_at
- updated_at

의미:

submission_phase
= 어느 제출 단계인가

submission_method
= 온라인 업로드 / 우편 / 방문 등 제출 방식 개념

submission_format
= 원본 / 사본 / 스캔 등 제출 형태 개념

instructions
= 구조화하기 어려운 공식 제출 조건/안내

admission_schedule_id
= 이 제출 event가 연결되는 일정. nullable

submission_phase / submission_method / submission_format의
실제 vocabulary는 아직 CHECK로 고정하지 않는다.

추가 대학 입력 과정에서 패턴을 확인한 후 결정한다.

PostgreSQL ENUM은 사용하지 않는다.
값이 확정되면 TEXT + CHECK 방향이다.


# 10. DocumentSubmission ↔ Schedule

RequiredDocument → AdmissionSchedule
직접 FK는 만들지 않는다.

initial schema에서는 다음을 확정한다.

document_submissions.admission_schedule_id nullable

single FK.

구조:

RequiredDocument
    ↓
DocumentSubmission
    ↓
AdmissionSchedule

장점:

- 같은 document의 여러 제출 단계 표현
- 각 단계별 기한 표현
- logical document 중복 방지
- submission별 citation/verification 가능

향후 실제 사례에서
한 submission이 여러 schedule을 필요로 하면
join table로 확장한다.


# 11. RequiredDocument choice / alternative

KU와 Yonsei 모두에서
A 또는 B, 여러 서류 중 대체 가능,
조건부 alternative pattern이 반복되었다.

단순 description/condition 문자열만으로는
문서 간 alternative 관계를 알기 어렵다.

이번 MVP에서 복잡한 rule engine은 만들지 않는다.


## required_document_choice_groups

table concept:

required_document_choice_groups

필드 초안:

- id
- admission_program_id
- title nullable
- rule_text
- condition nullable
- display_order
- verification_status
- verified_at nullable
- created_at
- updated_at


## required_document_choice_group_items

join table:

required_document_choice_group_items

- choice_group_id
- required_document_id

목적:

"이 문서들이 하나의 alternative/choice 관계에 있다"
는 구조를 표현한다.

정확한 선택 규칙은
rule_text에 공식 의미대로 보존한다.

any_of / exactly_one / at_least_n
같은 rule enum은 만들지 않는다.
rule engine도 만들지 않는다.

KU + Yonsei 모두에서
alternative/choice document pattern이 반복되었으므로
이 두 table은 initial core schema에 포함한다.

더 이상 "강한 후보"가 아니다.
initial migration에 넣는다.

향후 데이터가 충분히 쌓이면
rule_text를 구조화할 수 있다.


# 12. AdmissionSchedule

table concept:

admission_schedules

필드 초안:

- id
- admission_program_id
- event_name
- temporal_precision
- start_date nullable
- end_date nullable
- start_at nullable
- end_at nullable
- timezone nullable
- location_text nullable
- description nullable
- verification_status
- verified_at nullable
- display_order
- created_at
- updated_at

관계:

admission_programs 1 → N admission_schedules


## temporal_precision

initial conceptual values는 다음 두 개다.

- date
- datetime

PostgreSQL ENUM은 사용하지 않는다.
TEXT + CHECK 방향이다.
이 두 값만 initial CHECK 대상이다.

timestamptz-only 구조는 사용하지 않는다.
date-only 값을 00:00 timestamp로 변환하지 않는다.


원칙:

temporal_precision = date
→ date fields만 사용
→ timestamp fields는 NULL

temporal_precision = datetime
→ timestamp fields만 사용
→ date fields는 NULL


## cross-field CHECK 정책

SQL 단계에서 반드시 구현한다.
정확한 CHECK syntax는 SQL DDL 작성 시 확정한다.

date:

- start_date / end_date 둘 다 NULL 금지
- start_at / end_at은 모두 NULL
- 두 date가 모두 존재하면 start_date <= end_date

datetime:

- start_at / end_at 둘 다 NULL 금지
- start_date / end_date는 모두 NULL
- 두 timestamp가 모두 존재하면 start_at <= end_at

한쪽 boundary만 공식적으로 확인되는 경우는
NULL 허용.

point event는 가능한 경우 start = end 방식 사용.

date-only 단일 이벤트:
start_date = end_date

datetime 단일 이벤트:
start_at = end_at

이를 통해 end NULL이

- 단일 일정
- 종료시각 미확인

두 의미를 동시에 갖는 문제를 줄인다.


## location_text

University campus identity와
면접/시험 venue는 다른 개념이다.

location_text는
시험 장소, 면접 장소, 제출 장소 등
공식 일정의 venue를 표현한다.

별도 Location entity는 만들지 않는다.
MVP에서는 free text가 적절한 방향이다.


# 13. SourceDocument

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
→ source_documents.id nullable self-reference

원칙:

- revision predecessor 자동 삭제 금지
- CASCADE 금지
- RESTRICT / NO ACTION 방향
- 이전 source history 보존
- source revision 발견 시 기존 row overwrite 금지
- latest published_at = current source라고 단정하지 않음
- 새 revision이 발견됐다고
  연결된 AdmissionProgram 전체가
  자동 재검증된 것으로 처리하지 않음

is_current boolean은 아직 두지 않는다.

직접 자기 자신을 supersede하는 관계는
허용하지 않는 constraint가 필요하다.

장기 cycle 전체 방지는
초기 DB constraint보다
data validation/application logic에서 검토한다.

exact self-FK syntax는 SQL DDL 작성 시 확정한다.


## source_url UNIQUE

source_url UNIQUE는 두지 않는 방향을 계속 추천한다.

이유:

- revision
- 동일 logical source의 access surface
- 향후 동일 URL 파일 교체 가능성

SourceDocument alias table은 현재 만들지 않는다.

Yonsei G-Y-02는
multiple official access surfaces 관찰 수준이다.
동일 PDF binary의 복수 URL alias를
확정된 schema 요구로 취급하지 않는다.


## official-source conflict 처리

별도 source_conflicts table은 만들지 않는다.

official sources가 서로 다른 값을 제공할 경우:

1. source 각각을 SourceDocument로 보존한다.
2. production fact 선택 근거를 notes/provenance에 기록한다.
3. 필요한 child fact에 needs_review를 사용할 수 있다.
4. 더 구체적이고 authoritative한 official source를 우선한다.
5. 충돌 사실을 삭제하거나 조용히 덮어쓰지 않는다.

별도 conflict entity는
반복적인 운영 필요성이 확인될 때만 향후 검토한다.


# 14. SourceCitation

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

resolved decision:

file_page_number
= PDF physical page, 1-based integer

printed_page_label
= 문서 내부에 표시된 페이지 번호/문자열

둘은 별도 개념이다.

PDF library/API의 0-based index는
application implementation detail이며
DB citation에 저장하지 않는다.

HTML source에서는
section / anchor_description 중심으로 사용 가능하다.

기존 단일 page 개념은 사용하지 않는다.


# 15. Citation 연결 방식

polymorphic table
(entity_type + entity_id)
형태는 referential integrity가 약해질 수 있다.

explicit join table 방식을 recommended default로 둔다.


## Initial/core citation candidates

admission_section_citations
- admission_section_id
- source_citation_id

required_document_citations
- required_document_id
- source_citation_id

document_submission_citations
- document_submission_id
- source_citation_id

admission_schedule_citations
- admission_schedule_id
- source_citation_id

각 join table은
(target_id, source_citation_id)
composite UNIQUE 또는 composite PK 후보를 검토한다.

같은 절을 여러 item이 공유하는 경우
하나의 SourceCitation을 여러 join row가 참조할 수 있다.
모든 RequiredDocument 항목에
개별 citation을 강제하지 않는다.


## citation 역할 구분

RequiredDocument citation
= "이 서류가 요구된다"의 근거

DocumentSubmission citation
= "이 단계에서 이 방식/형태로 제출한다"의 근거

두 역할은 다르다.


## Program-level source

Program-level source는 citation join이 아니라
admission_program_sources로 별도 관리한다.


## Deferred citation joins

eligibility_rule_citations
= EligibilityRule을 도입할 때 추가

faq_citations
= FAQ table 도입 때 추가

사용하지 않는 미래 join table을
initial migration에서 모두 만들지 않는다.


# 16. AdmissionProgram ↔ SourceDocument

AdmissionProgram과 SourceDocument는 1:1이 아니다.

하나의 SourceDocument
→ 여러 AdmissionProgram 가능

하나의 AdmissionProgram
→ 여러 SourceDocument 가능

KU + Yonsei 결과를 반영해
direct N:N relation을 initial schema로 확정한다.


## admission_program_sources

table concept:

admission_program_sources

필드 초안:

- admission_program_id
- source_document_id
- source_role nullable
- display_order
- notes nullable
- created_at

관계:

AdmissionProgram N ↔ N SourceDocument

Composite uniqueness:

UNIQUE(
  admission_program_id,
  source_document_id
)

또는 composite PK 후보.

정확한 PK vs UNIQUE 선택은
SQL 작성 시 결정 가능하지만
중복 relation은 허용하지 않는다.

source_role의 실제 값과 구조는
SQL 작성 시 최종 결정한다.
예시 enum을 production 값처럼 만들지 않는다.


## semantic purpose

Program ↔ SourceDocument
= 이 official source가 어느 AdmissionProgram에 적용되는가

Entity ↔ SourceCitation
= 특정 fact의 정확한 근거 위치가 어디인가

둘은 중복된 source of truth가 아니라
서로 다른 provenance layer다.


# 17. EligibilityRule

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

공식 source에서 deterministic하게
표현 가능한 규칙만 EligibilityRule로 만든다.

모호한 규정이나 예외 조건을
억지로 자동 Rule로 만들지 않는다.

DATA_MODEL implementation priority에서
EligibilityRule은 P2다.

MVP 초기 schema에는 포함하지 않는다.
후속 migration이다.

이유:

- 먼저 사람에게 보여줄 공식 지원자격
  (AdmissionSection)을 정확하게 구조화한다.
- 초기 데이터 구축 단계에서
  EligibilityRule 완성률을 목표로 하지 않는다.
- 자격진단 개인정보는 MVP에서
  기본적으로 영구 저장하지 않는다.

EligibilityRule을 초기 migration에 넣지 않는다고
자격진단 기능 자체를 포기한다는 뜻은 아니다.


# 18. FAQ

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
FAQ table은 deferred다.


# 19. ParentStory

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

ParentStory table은 deferred다.


# 20. Status / Enum 전략

initial schema의 TEXT + CHECK value set:

information_type:

- official_fact
- interpretation
- strategic_opinion
- parent_experience
- unverified

verification_status:

- verified
- partially_verified
- needs_review
- unverified

availability_status:

- available
- not_found_in_official_source
- not_applicable
- unknown
- needs_confirmation

publication_status:

- draft
- published
- archived

이것은 실제 입시 규정 값이 아니라
서비스 내부 데이터 상태 taxonomy다.

PostgreSQL ENUM은 초기 migration에서 사용하지 않는다.

KU + Yonsei validation에서
새 status 추가 필요성은 확인되지 않았다.

"공식자료에서 찾지 못함"을
"요구하지 않음"으로 해석하지 않는다.
not_found_in_official_source와
not_applicable을 같은 값으로 두지 않는다.

submission_phase / submission_method / submission_format의 값은
아직 CHECK로 고정하지 않는다.
추가 대학 입력 과정에서 패턴을 확인한 후 결정한다.

temporal_precision CHECK 값은 별도다.

- date
- datetime


# 21. academic_year type

recommended default:

integer
예: 2027

UI에서:

"2027학년도"

형태로 formatting한다.

"2027학년도" 같은 UI text를
DB에 그대로 저장하지 않는다.

KU + Yonsei validation에서
integer 방식의 문제는 발견되지 않았다.

다른 academic_year의 데이터를
하나의 비교표나 하나의 AdmissionProgram에 섞지 않는다.


# 22. Timestamp 원칙

created_at
= row가 처음 생성된 시점
= database DEFAULT now()

updated_at
= row가 기술적으로 수정된 시점
= database DEFAULT now()
+ 공통 DB trigger로 row update 시 자동 갱신

각 application mutation에서
updated_at 설정을 기억하도록 의존하지 않는다.

verified_at
= 공식 자료와 대조하여 내용이 검증된 시점

verified_at은 자동 trigger 대상이 아니다.
공식 source 검증이 실제로 수행됐을 때만
명시적으로 변경한다.

published_at
= 공식 자료 또는 콘텐츠가 게시된 시점

last_checked_at
= source를 마지막으로 확인한 시점.
  내용이 재검증되었다는 뜻은 아니다.
  자동 updated_at과 동일하게 취급하지 않는다.

특히:

updated_at
≠
verified_at

오타 수정이나 내부 분류 변경은
updated_at만 바뀌고 verified_at은 유지될 수 있다.

AdmissionProgram.verified_at은
전형 전체 검토가 완료된 경우에만 갱신한다.

child entity는 별도의 verified_at을 가질 수 있다.

DocumentSubmission.verified_at을 갱신했다고
RequiredDocument 또는 AdmissionProgram이
자동 재검증된 것으로 보지 않는다.

timezone이 필요한 timestamp의
정확한 DB type은 SQL 작성 시 확정한다.

date-only official 일정은
AdmissionSchedule의 date fields를 사용한다.
임의의 00:00 시각을 만들지 않는다.

generic updated_at trigger implementation은
SQL DDL 작성 시 확정한다.


# 23. Delete 정책

각 주요 relation에서
무조건 CASCADE를 사용하지 않는다.

SQL 전에 relation을 두 그룹으로 구분한다.


## A. dependent component

부모 없이는 의미가 없는 component relation은
ON DELETE CASCADE 후보.

예:

AdmissionProgram
→ AdmissionSection

AdmissionProgram
→ RequiredDocument

RequiredDocument
→ DocumentSubmission

AdmissionProgram
→ RequiredDocumentChoiceGroup

ChoiceGroup
→ ChoiceGroupItem

Join table row 자체는
부모 relation이 삭제될 경우 CASCADE 가능.

단 SourceDocument 본체까지 cascade되지 않도록 한다.


## B. provenance / independent history

SourceDocument
SourceCitation
revision lineage

등은 자동 cascade deletion을 피한다.

RESTRICT / NO ACTION 중심.

revision predecessor 자동 삭제 금지.
CASCADE 금지.


## production 운영 원칙

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

production admissions data는
hard delete보다 archive/status가 더 적합할 수 있다.

exact ON DELETE action per FK는
SQL DDL 작성 시 최종 결정한다.


# 24. Index 전략

SQL 단계의 initial index 대상이다.
아직 index를 생성하지 않는다.

UNIQUE constraint로 이미 index가 생기는 것은
중복 생성하지 않는다.

index를 무조건 많이 만들지 않는다.


universities
- slug UNIQUE로 충분하면 별도 중복 index 없음

admission_programs
- university_id
- academic_year
- admission_category_id
- routing UNIQUE(university_id, academic_year, admission_slug)

admission_sections
- admission_program_id
- (admission_program_id, section_type)

required_documents
- admission_program_id

document_submissions
- required_document_id
- admission_schedule_id

admission_schedules
- admission_program_id

source_documents
- university_id
- academic_year
- supersedes_source_document_id

source_citations
- source_document_id

N:N join tables
- composite PK/UNIQUE의 첫 column과
  반대 방향 lookup이 자주 필요하면
  두 번째 FK column index도 검토

대상:

- admission_program_sources
- citation join tables
- required_document_choice_group_items

required_document_choice_groups
- admission_program_id

exact index names는 SQL 작성 시 확정한다.


# 25. Evaluation / Track / Campus defer

KU + Yonsei에서 단계별/조건부 평가가 있었지만
MVP 표시 목적에서는 AdmissionSection으로 표현 가능했다.

따라서:

evaluation_stage
evaluation_component

별도 table은 initial migration에서 만들지 않는다.

향후 비교/정렬/필터 요구가 실제로 생기면
structured evaluation model을 검토한다.
현재는 defer다.


AdmissionTrack은 여전히
initial schema에 넣지 않는다.

KU와 Yonsei 모두
AdmissionProgram + conditional sections/documents 구조로
표현 가능했다.

향후 실제 중복이 과도할 경우만 검토한다.


별도 Campus table은
initial schema에서 만들지 않는다.

University.campus_name 전략을 유지한다.

campus와 venue/location은
절대 같은 개념으로 처리하지 않는다.


# 26. P0 / P1 / P2 / P3

이것은 제품 기능 우선순위가 아니라
DB schema build sequence다.


## P0

- universities
- admission_categories
- admission_programs
- admission_sections
- source_documents
- source_citations
- admission_program_sources
- admission_section_citations

P0 설계 시 이미 반영된 것:

- campus discriminator
- source revision 개념
- citation page 1-based physical page
- same-type AdmissionSection 허용
- applicability_text
- Program ↔ Source direct N:N


## P1

- required_documents
- document_submissions
- admission_schedules
- required_document_citations
- document_submission_citations
- admission_schedule_citations
- required_document_choice_groups
- required_document_choice_group_items


## P2

- eligibility_rules


## P3

- faqs
- parent_stories


# 27. MVP 최초 migration 후보

실제 migration은 만들지 않는다.


## Core initial

- universities
- admission_categories
- admission_programs
- admission_sections
- required_documents
- document_submissions
- admission_schedules
- source_documents
- source_citations
- admission_program_sources
- admission_section_citations
- required_document_citations
- document_submission_citations
- admission_schedule_citations
- required_document_choice_groups
- required_document_choice_group_items

이 구성은 DATA_MODEL의 P0+P1을
KU + Yonsei validation 결과에 맞게 확장한 것이다.

choice group tables는 이제
"강한 후보"가 아니라 initial core schema다.
rule engine은 포함하지 않는다.


## Deferred

- eligibility_rules
- faqs
- parent_stories
- AdmissionTrack
- Campus
- evaluation child tables
- source conflict table
- source URL alias table

EligibilityRule을 초기 migration에 넣지 않는다고
자격진단 기능 자체를 포기한다는 뜻은 아니다.
사람용 eligibility section을 먼저 구축한다.


# 28. Relationship Summary

University
1 → N AdmissionProgram

AdmissionCategory
1 → N AdmissionProgram

AdmissionProgram
1 → N AdmissionSection

AdmissionProgram
1 → N RequiredDocument

RequiredDocument
1 → N DocumentSubmission

DocumentSubmission
N → 0..1 AdmissionSchedule

AdmissionProgram
1 → N AdmissionSchedule

AdmissionProgram
N ↔ N SourceDocument

SourceDocument
1 → N SourceCitation

AdmissionSection
N ↔ N SourceCitation

RequiredDocument
N ↔ N SourceCitation

DocumentSubmission
N ↔ N SourceCitation

AdmissionSchedule
N ↔ N SourceCitation

Choice groups:

AdmissionProgram
1 → N RequiredDocumentChoiceGroup

RequiredDocumentChoiceGroup
N ↔ N RequiredDocument


# 29. Data Invariant

기존 정확성 원칙에 더해 다음을 지킨다.

1. 동일 logical RequiredDocument를
   submission phase 때문에 복제하지 않는다.

2. submission-specific 정보는
   DocumentSubmission에 저장한다.

3. date-only schedule에
   임의의 시간 값을 생성하지 않는다.

4. temporal_precision과 맞지 않는
   date/timestamp field를 동시에 사용하지 않는다.

5. University campus와 event location을 혼동하지 않는다.

6. alternative document 관계를
   단순히 이름 문자열로만 추론하지 않는다.

7. Program↔Source 적용 관계와
   Entity↔Citation 근거 관계를 동일 개념으로 취급하지 않는다.

8. official source conflict를
   확인되지 않은 추론으로 조용히 해소하지 않는다.

9. UNIQUE(admission_program_id, section_type)를 두지 않는다.

10. AdmissionProgram.verified_at을
    child 재확인만으로 자동 갱신하지 않는다.

11. verified_at과 last_checked_at을
    updated_at trigger로 자동 갱신하지 않는다.

12. UNIQUE(name_ko, campus_name)에
    University uniqueness를 맡기지 않는다.


# 30. Open Decisions


## Resolved for initial schema

- UUID PK + DEFAULT gen_random_uuid() (UUIDv4)
- UUIDv7 미사용
- slug는 PK가 아님
- academic_year integer
- University: id UUID PK + slug UNIQUE
- UNIQUE(name_ko, campus_name) 미적용
- UNIQUE(university_id, academic_year, admission_slug) 적용
  (routing uniqueness only)
- same-type section 복수
- UNIQUE(admission_program_id, section_type) 금지
- applicability_text 필요
- document_subject_text naming
- DocumentSubmission 분리
- required_documents.submission_phase 제거
- DocumentSubmission → Schedule nullable single FK
- RequiredDocument → AdmissionSchedule 직접 FK 없음
- date / datetime temporal_precision
- TEXT + CHECK, PostgreSQL ENUM 미사용
- schedule cross-field CHECK 정책
- timestamptz-only + 임의 00:00 금지
- location_text 필요
- Program ↔ SourceDocument direct N:N
- admission_program_sources uniqueness
- file_page_number 1-based physical PDF page
- explicit citation joins
- source_url UNIQUE 두지 않음
- source_conflict table 두지 않음
- revision self-FK: RESTRICT / NO ACTION, no self-supersede
- evaluation child deferred
- Campus deferred
- AdmissionTrack deferred
- EligibilityRule initial migration deferred
- status TEXT + CHECK value set
- temporal_precision CHECK: date, datetime
- choice groups initial core
- created_at / updated_at DEFAULT now()
- updated_at DB trigger
- verified_at / last_checked_at은 자동 trigger 아님
- ON DELETE: component CASCADE 후보 vs provenance RESTRICT/NO ACTION


## SQL DDL 작성 시 최종 결정

- composite PK vs UUID PK for pure join tables
- exact ON DELETE action per FK
- exact CHECK constraint syntax
- exact index names
- generic updated_at trigger implementation
- SourceDocument self-FK exact syntax
- timestamp/timezone DB types
- source_role 구조
- submission phase/method/format vocabulary


## 추가 대학까지 미뤄도 되는 것

- University normalized name/campus uniqueness
- structured document subject lookup
- structured applicability
- source URL alias
- normalized evaluation model
- Campus entity
- AdmissionTrack


# 31. KU + Yonsei Validation Summary

2027 고려대 서울캠퍼스
재외국민(정원외2%)전형

+

2027 연세대 서울캠퍼스
재외국민전형[중·고교과정 해외 이수자]

두 사례에서 반복 확인되어
이번 refinement에 반영된 구조:

- applicability
- choice/alternative document
- submitter/subject
- document multi-phase
- date-only vs datetime
- program-source relation
- schedule location as venue, not campus identity

기존 schema draft의 최종 평가는
"refinement required before SQL"이었다.

이번 문서는 그 validation 결과를 반영한
refined logical schema다.

현재 평가는 문서 말미
Final schema readiness를 따른다.

이 구조가 모든 대학에 일반화된다는 뜻은 아니다.
limitation을 유지한다.


# 32. DATA_MODEL divergence

DB_SCHEMA_DRAFT는 KU + Yonsei validation을 통해
DATA_MODEL.md보다 구체적으로 발전했다.

현재 중요한 divergence:

DATA_MODEL.md:
RequiredDocument.submission_phase

Refined schema:
RequiredDocument와 DocumentSubmission 분리

이것은 오류가 아니라
KU + Yonsei validation 이후 나온 refinement다.

그 외 주요 시점 차이 예:

- document_subject_text
- applicability_text
- AdmissionSchedule date / datetime 분리
- admission_program_sources
- required_document_choice_groups

SQL 작성 전에
DATA_MODEL.md도 이 구조에 맞춰 동기화해야 한다.

이번 작업에서는 DATA_MODEL.md를 수정하지 않는다.


# 33. Schema Validation Checklist

refined schema가 두 validation 결과를
표현할 수 있는지 확인하는 점검 목록이다.

1. 한 대학/campus를 정확히 식별 가능한가?
2. campus와 event location을 혼동하지 않는가?
3. 2027 academic_year가 다른 연도와 섞이지 않는가?
4. 공식 전형명을 손실 없이 저장 가능한가?
5. 하나의 source document가 여러 program을 지원할 수 있는가?
6. 하나의 program이 여러 source document를 사용할 수 있는가?
7. eligibility section을 여러 개 저장 가능한가?
8. section applicability를 표현 가능한가?
9. required document의 logical requirement와
   submission event를 분리 가능한가?
10. submitter/subject를 공식 의미 손실 없이 표현 가능한가?
11. alternative/choice document 관계를 표현 가능한가?
12. date-only와 datetime 일정을 구분 가능한가?
13. date-only에 임의 시각을 만들지 않는가?
14. PDF file page / printed page를 모두 추적 가능한가?
15. 수정 모집요강 lineage를 추적 가능한가?
16. section/document/submission/schedule별 source citation이 가능한가?
17. verified_at을 program과 child별로 분리 가능한가?
18. 공식자료 미확인 상태를 false 또는 not required로 오해하지 않는가?
19. official source conflict를 보존 가능한가?
20. AdmissionTrack 없이 실제 구조가 자연스럽게 들어가는가?


# 34. 다음 단계

1. DATA_MODEL.md를 refined schema에 맞춰 동기화
2. PostgreSQL DDL 설계
3. SQL-level constraint / ON DELETE / CHECK review
4. initial migration 작성
5. Supabase project/database 구축
6. KU + Yonsei verified sample data 입력
7. Sogang 추가 검증/입력
8. Hanyang
9. SKKU
10. application read layer
11. 대학전형 UI

이번 작업에서는 SQL, migration, database,
Supabase, application code를 만들지 않는다.


# 35. Final schema readiness

Logical schema refined after KU + Yonsei validation.
Ready for final documentation synchronization
and PostgreSQL DDL design.

DATA_MODEL 동기화와
SQL-level constraint review가 끝나기 전까지
migration-ready라고 표현하지 않는다.
