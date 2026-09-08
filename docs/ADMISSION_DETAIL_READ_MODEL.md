# Admission Detail Read Model

이 문서는 전형 상세 페이지가 읽을 **FACT + STATUS + PROVENANCE** 조립 모델을 설계한다.

문서 안의 문장은 다음 세 종류로 구분한다.

- **CURRENT FACT** — 현재 schema, migration, 기존 코드가 실제로 지원하는 내용
- **DESIGN DECISION** — 이번 read model에서 추천하는 선택
- **DEFERRED** — 아직 결정하지 않는 내용

추측을 CURRENT FACT처럼 쓰지 않는다. 존재하지 않는 column을 만들지 않는다.


# 1. Purpose

사용자가 전형 상세 페이지에서 필요한 것은 단순한 입시 정보 요약이 아니다.

다음을 추적 가능해야 한다.

- 어떤 공식 자료를 근거로 하는지
- 어느 페이지(또는 HTML locator)에 근거가 있는지
- 어떤 내용이 검증되었는지
- 어떤 내용이 추가 확인이 필요한지
- 서로 다른 공식 자료의 citation이 같은 fact에 남아 있는지

충돌 여부 자체는 현재 schema에 `source_conflicts`가 없으므로
read model이 boolean으로 계산하지 않는다. 9절.

따라서 read model의 핵심은 편리한 nested object가 아니라
**FACT + STATUS + PROVENANCE 보존**이다.

이 문서는 향후 route

`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`

가 서버에서 한 번의 loader 호출로 받을 데이터 경계를 정의한다.

이번 작업에서는 production TypeScript, UI, migration, dependency를 구현하지 않는다.


# 2. Scope / Non-goals

## In scope

- 실제 Postgres schema 기준 entity / FK / cardinality 정리
- 전형 상세용 read-model DTO 경계
- citation → source 연결 방법
- ProgramSource inventory 경계
- query / in-memory assembly 전략
- KU 2027 acceptance case
- 향후 구현 PR 분할

## Out of scope (이번 문서에서 구현하지 않음)

- `lib/admissions` production 코드 변경
- App Router UI
- schema / migration 변경
- 새 dependency
- write path, admin, CMS
- eligibility 판정
- compare 정규화

## Non-goals of the read model itself

- 학생 개인 상황으로 “지원 가능”을 판정하지 않는다
- 충돌하는 공식 자료 중 하나를 고르지 않는다
- 복수 citation 또는 `needs_review`만으로 `hasConflict`를 계산하지 않는다
- NULL timezone을 KST로 채우지 않는다
- date-only 값을 00:00 timestamp로 바꾸지 않는다
- historical source를 current inventory처럼 보여주지 않는다
- inventory 밖 SourceDocument를 cited-union fallback으로 payload에 넣지 않는다
- FAQ / 학부모 경험 콘텐츠를 전형 상세 graph에 섞지 않는다


# 3. Existing Schema

근거:

- `supabase/migrations/20260825155343_initial_schema.sql`
- `supabase/migrations/20260905160000_load_ku_2027_reentry.sql`
- `docs/VERIFIED_DATA_LOAD_SPEC.md`
- `docs/data/ku/2027/ROW_MAP.md`
- `docs/data/ku/2027/SOURCE_INVENTORY.md`
- `lib/admissions/select.ts`

## 3.1 Existing loader (CURRENT FACT)

`getAdmissionProgramDetail(universitySlug, academicYear, admissionSlug)`는
university row + program row만 로드하는 **route lookup**이다.

- year는 exact `.eq`, default year 없음
- `admission_slug`만으로 lookup하지 않음
- sections / schedules / documents / citations / sources를 로드하지 않음

기존 함수를 거대한 graph loader로 확장하지 않는다.

**DESIGN DECISION:** 새 loader 개념을 둔다.

```
getAdmissionProgramDetail(...)
  → route identity (university + program)

getAdmissionProgramDetailReadModel(...)
  → university + program + children + citations + sources
```

새 loader는 Phase 1에서 기존 route lookup을 재사용할 수 있다.
책임은 분리한다.

## 3.2 Route identity (CURRENT FACT + DESIGN DECISION)

**CURRENT FACT:** `admission_programs` uniqueness는

`(university_id, academic_year, admission_slug)`

이다 (`admission_programs_routing_key`).

**CURRENT FACT:** SITE_MAP / WIREFRAME의 전형 상세 route는

`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`

이다.

**DESIGN DECISION:** detail loader는 다음 3개를 모두 요구한다.

- `universitySlug`
- `academicYear`
- `admissionSlug`

학년도 생략 금지. `admissionSlug`만으로 program lookup 금지.
다른 학년도 row를 섞지 않는다.

Validation 전용 예시 identity (KU 전용 설계가 아님):

| key | example |
| --- | --- |
| university slug | `korea-seoul` |
| academic year | `2027` |
| admission slug | `overseas-korean-2pct` |

## 3.3 Tables in the detail graph

### universities

| | |
| --- | --- |
| PK | `id` uuid |
| uniqueness | `slug` UNIQUE |
| program FK | 없음 (parent) |
| status | 없음 |
| ordering | 없음. 목록 조회는 기존 `name_ko`, `campus_name`, `slug` |

Columns: `id`, `name_ko`, `name_en`, `campus_name`, `display_name`, `slug`, `official_website_url`, `admissions_office_url`, `created_at`, `updated_at`.

### admission_programs

| | |
| --- | --- |
| PK | `id` uuid |
| parent FK | `university_id` NOT NULL → universities |
| nullable FK | `admission_category_id` → admission_categories ON DELETE SET NULL |
| uniqueness | `(university_id, academic_year, admission_slug)` |
| status | `information_type` NOT NULL, `verification_status` NOT NULL, `verified_at` nullable |
| ordering | 없음 |

**CURRENT FACT:** AdmissionProgram에 fact-level citation join table은 없다.
program provenance는 `admission_program_sources`이다.

### admission_categories

| | |
| --- | --- |
| PK | `id` |
| uniqueness | `code` UNIQUE |

전형 상세의 핵심 provenance graph는 아니다.
program의 nullable `admission_category_id`로만 연결된다.

**DESIGN DECISION:** identity enrichment로 `category | null`을 포함할 수 있다.
category가 없다고 카테고리를 추정하지 않는다.

### admission_sections

| | |
| --- | --- |
| PK | `id` |
| program FK | `admission_program_id` NOT NULL ON DELETE CASCADE |
| uniqueness | **없음** for `(program, section_type)` |
| status | `information_type`, `availability_status`, `verification_status`, `verified_at` nullable |
| ordering | `display_order` integer NOT NULL |

**CURRENT FACT:** schema comment가 명시한다. 같은 `section_type`이 한 program에 여러 번 나올 수 있다.
KU 2027도 `eligibility` 등이 반복된다.

Columns: `id`, `admission_program_id`, `section_type`, `title`, `content`, `applicability_text` nullable, `information_type`, `availability_status`, `verification_status`, `verified_at`, `display_order`, `created_at`, `updated_at`.

### admission_schedules

| | |
| --- | --- |
| PK | `id` |
| program FK | `admission_program_id` NOT NULL ON DELETE CASCADE |
| extra uniqueness | `(id, admission_program_id)` — composite child FK target |
| status | `verification_status`, `verified_at` nullable |
| ordering | `display_order` integer NOT NULL |

Temporal columns:

- `temporal_precision` `'date' | 'datetime'`
- date precision: `start_date` / `end_date`, `start_at`/`end_at` must be NULL
- datetime precision: `start_at` / `end_at`, `start_date`/`end_date` must be NULL
- `timezone` nullable text
- start-only / end-only 모두 schema가 허용

**CURRENT FACT:** NULL timezone을 KST로 강제하는 CHECK는 없다.
KU 2027 15개 schedule 중 timezone `GMT+9`는 5개, NULL은 10개이다.

### required_documents

| | |
| --- | --- |
| PK | `id` |
| program FK | `admission_program_id` NOT NULL ON DELETE CASCADE |
| extra uniqueness | `(id, admission_program_id)` |
| status | `verification_status`, `verified_at` nullable |
| ordering | `display_order` integer NOT NULL |

Columns include `name`, `description` nullable, `requirement_status` (unchecked vocabulary), `condition` nullable, `document_subject_text` nullable.

**CURRENT FACT:** 제출 phase는 document row에 없다. phase는 `document_submissions.submission_phase`에만 있다.

### document_submissions

| | |
| --- | --- |
| PK | `id` |
| parent FK | composite `(required_document_id, admission_program_id)` → required_documents |
| program FK | `admission_program_id` NOT NULL (denormalized; composite FKs keep it consistent) |
| nullable FK | `admission_schedule_id` — MATCH SIMPLE; NULL이면 schedule FK 검사 skip |
| status | `verification_status`, `verified_at` nullable |
| ordering | `display_order` integer NOT NULL |

**CURRENT FACT:** schedule이 없으면 NULL을 유지한다. 비슷한 일정을 자동 연결하는 constraint는 없다.

### required_document_choice_groups

| | |
| --- | --- |
| PK | `id` |
| program FK | `admission_program_id` NOT NULL ON DELETE CASCADE |
| extra uniqueness | `(id, admission_program_id)` |
| status | `verification_status`, `verified_at` nullable |
| ordering | `display_order` integer NOT NULL |

Columns: `title` nullable, `rule_text` NOT NULL, `condition` nullable.

### required_document_choice_group_items

| | |
| --- | --- |
| PK | `(choice_group_id, required_document_id)` — UUID PK 없음 |
| parent FKs | composite to choice group and document, both with `admission_program_id` |
| status | 없음 |
| ordering | **없음** |

**CURRENT FACT:** `choice_group_citations` 테이블은 schema에 없다.

### source_documents

| | |
| --- | --- |
| PK | `id` |
| nullable FK | `university_id` → universities; `supersedes_source_document_id` → source_documents |
| uniqueness | `source_url`은 UNIQUE가 아님 |
| status | verification_status 없음 |
| ordering | 없음 |

Columns: `academic_year` nullable, `source_type`, `title`, `issuing_organization`, `source_url`, `published_at` **date** nullable, `last_checked_at` timestamptz NOT NULL, `document_version_label` nullable, `notes` nullable.

**CURRENT FACT:** URL은 identity가 아니다. `published_at`과 `last_checked_at`은 다른 의미이다.

### source_citations

| | |
| --- | --- |
| PK | `id` |
| parent FK | `source_document_id` NOT NULL ON DELETE RESTRICT |
| locator | `file_page_number` nullable integer ≥ 1, `printed_page_label` nullable, `section` nullable, `anchor_description` nullable |
| status | `verified_at` nullable. `verification_status` 없음 |
| ordering | 없음 |

**CURRENT FACT:** `file_page_number`는 physical PDF page, 1-based이다. printed page와 같은 column이 아니다. HTML citation은 page를 가짜로 채우지 않고 NULL이다.

### admission_program_sources

| | |
| --- | --- |
| PK | `(admission_program_id, source_document_id)` |
| FKs | program ON DELETE CASCADE, source ON DELETE RESTRICT |
| extra | `source_role` nullable, `display_order` **nullable**, `notes` nullable |

이것이 현재 program의 source inventory이다.

### Citation relation tables

모두 composite PK `(entity_id, source_citation_id)`.
entity 쪽 ON DELETE CASCADE, citation 쪽 ON DELETE RESTRICT.
program FK 없음. ordering column 없음.

| relation | entity column |
| --- | --- |
| `admission_section_citations` | `admission_section_id` |
| `required_document_citations` | `required_document_id` |
| `document_submission_citations` | `document_submission_id` |
| `admission_schedule_citations` | `admission_schedule_id` |

**CURRENT FACT:** pair uniqueness는 PK로 enforce된다. 같은 `(entity, citation)` 중복 row는 불가능하다.
같은 citation을 **다른 entity**에 재사용하는 것은 허용된다 (KU SCH10/SCH11 → CIT29).

## 3.4 Cardinality (CURRENT FACT)

한 AdmissionProgram 기준:

```
University 1 ──< AdmissionProgram N
AdmissionProgram 1 ──< AdmissionSection N
AdmissionProgram 1 ──< AdmissionSchedule N
AdmissionProgram 1 ──< RequiredDocument N
AdmissionProgram 1 ──< RequiredDocumentChoiceGroup N
AdmissionProgram 1 ──< AdmissionProgramSource N
RequiredDocument 1 ──< DocumentSubmission N
RequiredDocumentChoiceGroup 1 ──< ChoiceGroupItem N
RequiredDocument 1 ──< ChoiceGroupItem N   (M:N via items)
DocumentSubmission N ──o AdmissionSchedule  (nullable)
AdmissionSection N ──< SectionCitation ──> SourceCitation
RequiredDocument N ──< DocumentCitation ──> SourceCitation
DocumentSubmission N ──< SubmissionCitation ──> SourceCitation
AdmissionSchedule N ──< ScheduleCitation ──> SourceCitation
SourceCitation N ──> SourceDocument 1
AdmissionProgram N ──< ProgramSource ──> SourceDocument
SourceDocument N ──o SourceDocument (supersedes)
```

## 3.5 Status axes location (CURRENT FACT)

| axis | 존재 위치 |
| --- | --- |
| `information_type` | `admission_programs`, `admission_sections` |
| `availability_status` | `admission_sections` only |
| `verification_status` | programs, sections, schedules, documents, submissions, choice groups |
| `verified_at` | 위 verification_status 보유 테이블 + `source_citations` |
| `requirement_status` | `required_documents` only (unchecked vocab) |
| `last_checked_at` | `source_documents` only |

축을 섞는 schema trigger는 없다.

## 3.6 Not in current schema (CURRENT FACT)

initial schema가 의도적으로 생략한 것:

- `eligibility_rules`
- `faqs`, `parent_stories`
- `source_conflicts`
- `choice_group_citations`
- evaluation children
- source URL alias table

존재하지 않는 relation을 있다고 가정하지 않는다.


# 4. Read-model Principles

1. **Identity first.** universitySlug + academicYear + admissionSlug로 한 program만 고른다.
2. **Raw facts.** DB에 저장된 값/NULL/status를 보존한다.
3. **Assemble relations, do not interpret.** citation과 source 연결만 한다.
4. **Dedicated citation paths only.** relation table이 있는 entity에만 citation을 붙인다.
5. **ProgramSource is inventory.** current source pool은 `admission_program_sources`이다. `sourcesById`도 이 inventory에 속한 SourceDocument만 담는다.
6. **Preserve evidence. Do not detect or resolve conflict.** 복수 citation을 conflict로 추론하지 않고, 충돌 값 중 하나를 고르지도 않는다.
7. **No N+1.** ID batch query.
8. **SELECT only.** service_role 없음. browser direct Supabase 없음. 기존 RLS public-read 유지.
9. **no-store 유지.** 이번 설계에서 caching 정책을 바꾸지 않는다.
10. **Fail visibly.** child query 실패를 빈 배열로 위장하지 않는다. provenance invariant 위반을 silent render하지 않는다.
11. **Plain DTO.** assembly 내부 Map/Set은 허용. 반환 contract는 JSON-serializable plain objects / arrays / `Record`만 사용한다.


# 5. Proposed Read Model

## 5.1 Raw-row expose vs UI transform

| 접근 | 장점 | 단점 |
| --- | --- | --- |
| A. DB row 필드를 거의 그대로 두고 관계만 조립 | provenance/status 손실이 적음. schema 변경 추적이 쉬움. 기존 `UniversityRow` / `AdmissionProgramRow`와 일치 | payload가 UI에 다소 거칠다. snake_case 유지 |
| B. UI용으로 과도 변환 (한글 라벨, 확정 마감일, section_type map, eligibility boolean) | 화면은 단순 | 공식 근거가 아닌 해석이 repository에 들어감. SUB82 같은 conflict를 삼킬 위험 |

**DESIGN DECISION:** A.

기존 admissions DTO는 DB column명을 snake_case로 보존한다.
read model도 row 필드는 그 규칙을 따른다.
top-level collection 이름만 읽기 쉽게 둔다.

해석적 transformation은 repository에서 하지 않는다.

금지 예:

- “지원 가능”
- “마감일 확정”
- “필수 조건 충족”
- “최종 자료”
- `section_type`을 object key로 축소
- `needs_review` → `availability_status = unknown` 자동 변경

## 5.2 Top-level DTO (DESIGN DECISION)

개념 구조. 구현 TypeScript는 후속 PR에서 schema column만 선택한다.

```
AdmissionProgramDetailReadModel
{
  university: UniversityRow
  program: AdmissionProgramRow
  category: AdmissionCategoryRow | null
  sections: SectionWithProvenance[]
  schedules: ScheduleWithProvenance[]
  requiredDocuments: RequiredDocumentWithProvenance[]
  choiceGroups: ChoiceGroupWithItems[]
  programSources: ProgramSourceLink[]
  sourcesById: Record<string, SourceDocumentSummary>
}
```

`category`는 `program.admission_category_id`가 NULL이면 NULL.

**DESIGN DECISION — canonical collections:**

- schedule 정본은 top-level `schedules[]` 한 곳이다. submission에 schedule object를 embed하지 않는다.
- current source 정본은 `programSources[]` + 그 ID로 채운 `sourcesById`이다. cited-outside-inventory를 union하지 않는다.
- choice-group M:N 정본은 `choiceGroups[].items[]`이다. document 쪽 reverse id 배열만으로 대체하지 않는다.
- 공개 DTO에 JS `Map` / `Set`을 두지 않는다. 내부 assembly에서만 사용한다.
- `schedulesById`는 공개 contract에 넣지 않는다. UI가 필요하면 `schedules[]`에서 `id`로 찾는다.

## 5.3 SectionWithProvenance

```
{
  ...AdmissionSectionRow   // applicability_text 포함, nullable 유지
  citations: CitationWithSourceReference[]
}
```

**DESIGN DECISION:** `sections`는 array로 유지한다.
`section_type`을 object key로 만들어 한 개만 남기는 방식은 금지한다.

`applicability_text`가 NULL이면 NULL 유지.
repository가 deterministic applicability로 변환하지 않는다.

## 5.4 ScheduleWithProvenance

```
{
  ...AdmissionScheduleRow
  citations: CitationWithSourceReference[]
}
```

보존해야 할 temporal 의미:

- `temporal_precision`
- date vs timestamptz 필드 분리
- nullable start/end
- nullable `timezone`

하지 말 것:

- NULL timezone을 KST/`Asia/Seoul`/`GMT+9`로 가정
- date-only를 00:00 timestamp로 변환
- end-only datetime을 “하루 종일”로 해석

UI formatter는 presentation concern이다.

schedule row + citations는 `schedules[]`에만 둔다.
여러 submission이 같은 schedule을 참조해도 schedule object를 복제하지 않는다.

## 5.5 RequiredDocumentWithProvenance

```
{
  ...RequiredDocumentRow   // document_subject_text nullable 유지
  citations: CitationWithSourceReference[]
  submissions: DocumentSubmissionWithProvenance[]
}
```

제출 phase / method / format을 document row에서 추론하지 않는다.

choice-group 소속은 이 객체의 reverse id 배열로 표현하지 않는다.
M:N은 `choiceGroups[].items[]`가 정본이다.

## 5.6 DocumentSubmissionWithProvenance

```
{
  ...DocumentSubmissionRow
  citations: CitationWithSourceReference[]
}
```

**DESIGN DECISION:** full `ScheduleWithProvenance`를 submission에 embed하지 않는다.

`DocumentSubmissionRow`가 이미 가진 DB field를 그대로 보존한다.

- `admission_schedule_id: string | null`

값이 있으면 그 UUID는 top-level `schedules[]`의 한 item `id`를 가리킨다.
NULL이면 NULL이다. 비슷한 일정을 자동 연결하지 않는다.

KU SUB82는 `admission_schedule_id = null`이다. SCH11을 embed하거나 추론하지 않는다.

하지 말 것:

- `linkedSchedule: ScheduleWithProvenance | null` 형태의 full object embed
- 공개 DTO의 `Map<scheduleId, schedule>`
- NULL FK를 “가장 가까운 마감 일정”으로 채우기

## 5.7 ChoiceGroupWithItems

**CURRENT FACT:** item table columns는 다음뿐이다.

- `choice_group_id`
- `required_document_id`
- `admission_program_id`

PK는 `(choice_group_id, required_document_id)`. UUID PK 없음.
`display_order` 없음. citation FK 없음.

```
ChoiceGroupWithItems
{
  ...RequiredDocumentChoiceGroupRow
  items: ChoiceGroupItemReference[]
}

ChoiceGroupItemReference
{
  choice_group_id
  required_document_id
  admission_program_id
}
```

존재하지 않는 item `display_order` / item citation field를 만들지 않는다.

**CURRENT FACT:** `choice_group_citations` 테이블은 없다.

**DESIGN DECISION:**

- `choiceGroups[]`는 group row와 `items[]`를 함께 보존한다.
- `requiredDocuments[].choiceGroupIds[]` 같은 reverse convenience만으로 item relation을 대체하지 않는다.
- group-level `citations[]`를 만들지 않는다.
- member document citation을 group citation으로 상속하지 않는다.

item array 순서는 11절. 순서 규칙은 item에 없는 column을 발명하는 것이 아니다.

## 5.8 CitationWithSourceReference

```
{
  id
  sourceDocumentId
  filePageNumber          // physical PDF page, 1-based, nullable
  printedPageLabel        // 문서 내부 표시, nullable
  section
  anchorDescription
  verifiedAt
}
```

citation은 독립 identity다. `file_page_number`와 `printed_page_label`을 섞지 않는다.

source 본문은 citation마다 복제하지 않는다. `sourceDocumentId`로 `sourcesById`를 본다.

## 5.9 SourceDocumentSummary

schema fields만 사용:

```
{
  id
  universityId
  academicYear
  sourceType
  title
  issuingOrganization
  sourceUrl
  publishedAt          // date | null
  lastCheckedAt        // timestamptz
  documentVersionLabel
  supersedesSourceDocumentId
  notes
}
```

URL을 identity로 쓰지 않는다.
`published_at` ≠ `last_checked_at`.
revision은 `supersedes_source_document_id`로 보존한다.

## 5.10 ProgramSourceLink

```
{
  sourceDocumentId
  sourceRole
  displayOrder          // nullable
  notes
}
```

목록의 의미는 “이 program의 current source inventory”이다.

**DESIGN DECISION:** `sourcesById`의 key 집합은 `programSources`의 `sourceDocumentId` 집합과 같다.
citation 때문에 inventory 밖 SourceDocument를 union하지 않는다.

created_at / updated_at는 row에 있으면 보존할 수 있다. UI가 보여줄지는 presentation.

## 5.11 Output serializability (DESIGN DECISION)

loader 내부 assembly는 `Map` / `Set`을 써도 된다.

최종 `AdmissionProgramDetailReadModel`은 다음만 노출한다.

- plain objects
- arrays
- `Record<string, SourceDocumentSummary>` 형태의 `sourcesById`

JS `Map` / `Set`을 public contract로 두지 않는다.
Server Component, 테스트, JSON inspection이 같은 shape를 볼 수 있어야 한다.


# 6. Provenance Model

## 6.1 Citation paths (CURRENT FACT)

```
section     → admission_section_citations      → source_citations → source_documents
document    → required_document_citations      → source_citations → source_documents
submission  → document_submission_citations    → source_citations → source_documents
schedule    → admission_schedule_citations     → source_citations → source_documents
program     → admission_program_sources        → source_documents
```

submission 줄의 중간은 `document_submission_citations` → `source_citations`이다.

program fact-level citation path는 없다.

relation이 없는 entity에 citation을 임의 연결하지 않는다.

## 6.2 ProgramSource boundary

**DESIGN DECISION:** 전형 상세의 authoritative current source pool은
해당 program의 `admission_program_sources`이다.

loader 절차:

1. ProgramSource relation에서 `source_document_id`를 현재 inventory로 수집한다.
2. entity citation → `source_citations.source_document_id`를 확인한다.
3. cited `source_document_id`가 inventory에 없으면 `INTEGRITY_VIOLATION`.
4. inventory 밖 source를 union해서 정상 payload에 포함하지 않는다.
5. `sourcesById`는 current ProgramSource inventory에 속한 SourceDocument만 구성한다.

하면 안 되는 것:

- `SELECT * FROM source_documents`
- university_id heuristic
- academic_year heuristic
- `sourcesById = program source inventory ∪ cited sources` fallback
- S06처럼 historical row를 citation 때문에 자동 union

**CURRENT FACT (KU 2027):** `source_documents`는 7개, `admission_program_sources`는 6개.
historical S06 (`KU27-SRC01`)는 SourceDocument table에 존재하지만
current ProgramSource가 아니고 current citation도 0이다.

S06는 `programSources`와 `sourcesById`와 entity citation graph에 없어야 한다.

revision 표시가 필요하면 inventory에 있는 S01의 `supersedes_source_document_id`만 보존한다.
그 UUID가 S06를 가리켜도 S06 row를 `sourcesById`에 fetch하지 않는다.
superseded row 전체를 자동 fetch하는 것은 **DEFERRED** (historical browser).

## 6.3 Provenance consistency invariant

**CURRENT FACT:** DB는 다음을 완전히 enforce하지 않는다.

```
Entity → Citation → SourceDocument
  가 반드시
Program → ProgramSource
  에도 존재해야 한다
```

VERIFIED_DATA_LOAD_SPEC §8는 이를 known limitation으로 두고
load validation에서 mandatory 검사한다. schema trigger로 메우지 않는다.

검사 대상 relation:

- admission_section_citations
- required_document_citations
- document_submission_citations
- admission_schedule_citations

historical source가 **citation되지 않고** program source에도 없으면 위반이 아니다 (S06).
citation이 S06를 가리키면 그때는 위반이다. S06를 payload에 넣어 우회하지 않는다.

선택지:

| 옵션 | 의미 |
| --- | --- |
| A. runtime assert/fail | query는 성공했으나 invariant 위반이면 throw. detail facts를 반환하지 않음 |
| B. warning/log | 페이지는 렌더, 로그만 |
| C. separate validator only | 테스트/load에서만 검사 |

**DESIGN DECISION:** A를 loader 기본으로 하고, C를 테스트에서 병행한다.

의미:

```
query succeeds
but provenance invariant is violated
→ INTEGRITY_VIOLATION
→ detail facts를 silently render하지 않음
→ log-only 기본안 아님
```

이 프로젝트는 정확성/검증 가능성을 availability보다 우선하므로 이 선택을 추천한다.

이유:

- silent mismatch는 “출처 보기”가 inventory에 없는 문서를 가리키거나, inventory와 fact가 어긋난 채 보일 수 있다.
- B만 쓰면 production이 깨진 provenance를 사용자에게 그대로 보여준다.
- C만 쓰면 load 이후 drift를 runtime이 못 본다.

권장 구현:

1. cited `source_document_id` 집합 ⊆ program source `source_document_id` 집합
2. 위반 시 정상 read model을 만들지 않고 `AdmissionsQueryError`에 `code: "INTEGRITY_VIOLATION"` (또는 subtype)
3. KU fixture 테스트는 같은 규칙을 독립 validator로 재확인
4. S06가 uncited historical이면 pass. cited이면 fail. payload union으로 pass시키지 않음
5. empty citation array는 그 자체로 integrity violation이 아니다

log는 fail과 함께 남겨 debugging에 쓴다. log-only는 충분하지 않다.

이 invariant를 schema trigger로 승격하는 것은 **DEFERRED**.

## 6.4 Choice-group provenance limitation (CURRENT FACT)

choice group / item에 대한 citation relation이 없다.

따라서:

- group `rule_text`의 페이지 위치를 read model이 직접 가리키지 못한다
- member document citation을 group이 “상속”했다고 쓰면 공식 구조가 아닌 해석이다

KU 2027 CG01은 group row의 `rule_text`에 요강 p13을 서술 텍스트로 담고,
member documents는 各自 citation을 가진다.
그것은 document provenance이지 group citation table이 아니다.

UI는 group 옆 “출처 보기”를 지금은 제공하지 않거나,
member documents의 citation을 group citation인 것처럼 합치지 말고
document 수준에서만 보여야 한다.

전용 `choice_group_citations`는 **DEFERRED**.

## 6.5 Source presentation support

향후 UI가 fact 옆 “출처 보기”를 구현하려면 citation → sourceDocumentId → sourcesById면 충분하다.

| 방식 | 장점 | 단점 |
| --- | --- | --- |
| A. citation마다 full SourceDocument embed | lookup 불필요 | CIT29처럼 재사용 시 payload 중복. JSON 커짐 |
| B. top-level `sourcesById` + citation의 sourceDocumentId | source 1회. Server Component → client serialize에 `Record`가 `Map`보다 안전 | UI가 id로 lookup |

**DESIGN DECISION:** B.

`sourcesById`는 ProgramSource-bound이므로, 정상 payload에서 citation의 `sourceDocumentId`는 항상 `sourcesById`에 있다.
invariant 위반 시 payload를 만들지 않으므로 lookup miss를 “없으면 skip”으로 처리하지 않는다.

추가:

- 하단 “공식 출처” 목록은 `programSources` 순서
- section-level “근거”는 entity `citations[]`

공개 DTO의 `sourcesById`는 `Record<string, SourceDocumentSummary>`이다. JS `Map`이 아니다.


# 7. Query / Assembly Strategy

## 7.1 Giant nested SELECT vs batched queries

평가 대상 KU 규모: sections 17, documents 42, submissions 84, citations relations 200.

| 기준 | A. one giant nested SELECT | B. several bounded SELECTs + in-memory assembly |
| --- | --- | --- |
| cardinality explosion | section × citation, document × submission × citation가 한 row set로 터질 수 있음 | 테이블별 bounded |
| duplicate rows | PostgREST embed는 parent를 복제하기 쉬움 | relation을 Map으로 1회 연결 |
| citation integrity | flatten 중 pair 손실/중복 위험이 큼 | PK pair를 Set으로 검증 가능 |
| debugging | 한 응답의 어느 가지가 비었는지 불명 | phase별 실패 지점이 분명 |
| future schema change | embed shape이 깨지기 쉬움 | 테이블 하나 추가 query |
| query readability | 한 줄이지만 실제로는 읽기 어려움 | phase 주석과 대응 |
| RLS | 둘 다 SELECT + RLS | 동일. 여러 round-trip이지만 정책은 단순 |
| performance | 현재 볼륨에선 둘 다 충분. A는 payload 팽창 | ~15 query, N+1 아님. 과도한 optimization 불필요 |
| testability | fixture assert가 어려움 | count/identity assert가 테이블 단위 |

**DESIGN DECISION:** B.

PostgREST nested resource는 편리해 보이지만, 이 graph는
document → submissions → citations와 schedule citations가 동시에 있어
duplicate/lossy flatten 위험이 크다. citation integrity가 제품 핵심이므로
조립을 애플리케이션에서 deterministic하게 하는 편이 맞다.

## 7.2 Fetch phases (DESIGN DECISION)

모두 `admission_program_id` 또는 수집한 UUID `IN (...)` batch.
entity마다 child query를 돌리지 않는다.

### Phase 1 — route identity / program

1. `universities` by slug
2. `admission_programs` by `university_id` + `academic_year` + `admission_slug`
3. optional: `admission_categories` by `admission_category_id` if not null

기존 `getAdmissionProgramDetail` 재사용 가능.
없으면 `null`.

수집 ID: `program.id`, `university.id`.

### Phase 2 — program children

4. `admission_sections` where program id
5. `admission_schedules` where program id
6. `required_documents` where program id
7. `admission_program_sources` where program id

수집 ID: sectionIds, scheduleIds, documentIds, **programSourceDocumentIds** (current inventory).

### Phase 3 — document children

8. `document_submissions` where program id (document id list로도 가능하나 program id가 더 단순)
9. `required_document_choice_groups` where program id
10. `required_document_choice_group_items` where program id

수집 ID: submissionIds. choice group/item rows는 그대로 유지해 `choiceGroups[].items[]`를 만든다.

### Phase 4 — citation relation rows

빈 ID 집합이면 해당 query skip (결과 `[]`), error로 위장하지 말 것.

11. `admission_section_citations` where `admission_section_id IN sectionIds`
12. `required_document_citations` where `required_document_id IN documentIds`
13. `document_submission_citations` where `document_submission_id IN submissionIds`
14. `admission_schedule_citations` where `admission_schedule_id IN scheduleIds`

수집 ID: sourceCitationIds (union).

### Phase 5 — source_citations + integrity

15. `source_citations` where `id IN sourceCitationIds`

수집 ID: citedSourceDocumentIds.

**Integrity validation (query success 이후, payload 조립 전):**

```
every citation.source_document_id
  ⊆ programSourceDocumentIds
```

아니면 `INTEGRITY_VIOLATION`. inventory 밖 ID를 union하지 않는다.

### Phase 6 — source_documents (ProgramSource-bound)

16. `source_documents` where `id IN programSourceDocumentIds`

cited-union이 아니다. S06는 ProgramSource가 아니므로 이 IN 목록에 없고 fetch되지 않는다.

### Phase 7 — in-memory deterministic assembly

내부 only (`Map` / `Set` 허용):

```
sectionId → citations[]
documentId → citations[]
submissionId → citations[]
scheduleId → citations[]
documentId → submissions[]
choiceGroupId → items[]
sourceCitationId → citation
sourceDocumentId → source   // ProgramSource inventory only
scheduleId → schedule       // assembly lookup; 공개 DTO에는 올리지 않음
```

알고리즘:

1. citation rows를 `CitationWithSourceReference`로 정규화. `sourceDocumentId`는 inventory lookup용 참조일 뿐 source object를 citation에 복제하지 않음
2. relation pair를 entity map에 push. PK이므로 중복 pair는 없어야 한다. 있으면 integrity error (방어)
3. children을 parent array에 연결. submission은 `admission_schedule_id`만 보존. schedule object embed 금지
4. `choiceGroups[].items[]`에 item row 필드만 넣음
5. `sourcesById`를 ProgramSource inventory SourceDocument로만 구성
6. ordering 적용 (11절)
7. plain object DTO 반환 (`Map`/`Set` 제거)

하지 말 것:

- Phase 6에서 `programSourceDocumentIds ∪ citedSourceDocumentIds`
- 공개 contract에 `schedulesById: Map` 또는 `sourcesById: Map`

## 7.3 Query budget

정상 path 약 **14–16** SELECT.
N+1 금지:

- document마다 submission query
- section마다 citation query
- citation마다 source query

현재 KU 볼륨에서 connection pooling/캐시는 넣지 않는다.
`createSupabaseReadClient`의 `cache: "no-store"`를 유지한다.

## 7.4 RLS / security (CURRENT FACT + DESIGN DECISION)

read model은 SELECT only.
anon/publishable key + existing `public_read_*` policies.
service_role 없음.
browser SDK 없음.
새 write path 없음.

대상 테이블은 RLS migration에 모두 public SELECT policy가 있다
(universities부터 citation relation까지).


# 8. Status / Null Semantics

## 8.1 Do not mix axes (DESIGN DECISION)

예: `verification_status = needs_review`를
`availability_status = unknown`으로 바꾸지 않는다.

`information_type = official_fact`이면서 `needs_review`일 수 있다.
KU SUB82가 그 패턴에 가깝다 (submission은 information_type column이 없고 verification만 있다).

Korean badge label mapping은 UI concern이다.
repository는 stored enum 값을 그대로 반환한다.

## 8.2 Null preservation

NULL은 NULL이다. repository가 추정하지 않는 것:

- `applicability_text`
- `document_subject_text`
- `admission_schedule_id`
- `timezone`
- date/datetime 한쪽만 있는 경우의 반대편
- `verified_at`
- `published_at`
- `file_page_number` / `printed_page_label`
- `admission_category_id`
- choice group `title` / `condition`

공식 자료에 없다고 해서 “없음”, “제출 불필요”, “요구하지 않음”으로 바꾸지 않는다.
그 추론은 VERIFIED_DATA_LOAD_SPEC §10과 같다.

## 8.3 verified_at semantics (CURRENT FACT)

VERIFIED_DATA_LOAD_SPEC §9 / DATA_MODEL:

- `verified_at`은 실제 공식 source 확인이 수행된 시각
- insert trigger가 채우지 않음. `set_updated_at`은 `verified_at`을 건드리지 않음
- **AdmissionProgram.verified_at**은 program 전체의 주요 항목을 검토했을 때만 변경
- child `verified_at` 변경이 program `verified_at`을 자동 갱신하지 않음
- `updated_at`은 기술 수정 시각. 오타 수정은 `updated_at`만 바뀔 수 있음
- `source_documents.last_checked_at`은 source를 마지막으로 확인한 시점. 내용 재검증 ≠ `verified_at`

**DESIGN DECISION:** read-time에 child verified_at를 보고 program verified_at를 derive하지 않는다.
NULL은 NULL.

KU 2027 program은 `verification_status = partially_verified`, `verified_at` NULL.
SUB82는 `verified_at` NULL, `needs_review`.
이 차이를 유지한다.


# 9. Conflict Handling

**CURRENT FACT:** `source_conflicts` table은 없다 (ROW_MAP GAP-08).
generic conflict entity / `hasConflict` column도 없다.

따라서 generic read model이 다음을 추론하면 안 된다.

```
복수 citations = official source conflict
needs_review = 특정 source conflict
```

**CURRENT FACT가 아닌 것:**

- multiple citations alone do NOT prove conflict
- `needs_review` alone also does NOT generically identify a specific source conflict
- complementary citations (같은 사실을 여러 공식 자료가 보완 설명)도 복수 citation이 될 수 있다. KU schedule의 S01+S03 복수 citation이 그 예다.

**DESIGN DECISION:**

- repository는 `hasConflict` boolean을 계산하지 않는다
- repository는 raw `verification_status`와 해당 entity의 모든 citation을 보존한다
- repository는 충돌하는 값 중 하나를 고르지 않는다
- UI는 현재 저장된 구조가 명시적으로 지원하지 않는 한
  “공식 자료가 충돌한다”고 자동 표시하지 않는다

repository에서 금지:

- “more recent”
- “PDF is authoritative”
- “HTML is typo”
- citation 한쪽 제거
- verified로 승격
- 임의 deadline 생성
- 복수 citation → `hasConflict: true`

S05 HTML (`KU27-SRC06`)과 S05 PDF (`KU27-SRC07`)는 별도 SourceDocument이다.
같은 게시 날짜를 공유해도 identity를 합치지 않는다.

SUB82는 canonical **acceptance case**다.
known curated conflict evidence(needs_review + schedule FK NULL + 관련 citation 4개)를
손실 없이 보존해야 한다는 테스트이지,
generic conflict-detection algorithm이 아니다.

현재 UI contract에서 안전한 표현:

- `verification_status = needs_review` → “추가 확인 필요”
- 관련 공식 출처는 citation → `sourcesById`로 표시

전용 `source_conflicts` 구조와 conflict-detection model은 **DEFERRED**.


# 10. Error Semantics

| 상황 | 결과 |
| --- | --- |
| university slug 없음, 또는 year/slug 조합의 program 없음 | `null` → page `notFound()` |
| 잘못된 argument (empty slug, non-integer year) | 기존 `AdmissionsQueryError` `INVALID_ARGUMENT` |
| 어느 phase든 database/PostgREST 실패 | `AdmissionsQueryError` `QUERY_FAILED`. 빈 배열로 위장 금지 |
| cited source ∉ program sources, 또는 relation/citation id 누락 | `INTEGRITY_VIOLATION` |

**DESIGN DECISION:** integrity는 기존 `AdmissionsQueryError`에 `code: "INTEGRITY_VIOLATION"`을 추가하는 방향을 우선한다. 별도 class도 가능하나, 호출부가 코드로 구분할 수 있으면 충분하다.

중요 구분:

```
QUERY_FAILED     = database/PostgREST 실패
INTEGRITY_VIOLATION
  = query는 성공했으나
    provenance invariant가 깨짐
  = detail facts를 silently render하지 않음
  = log-only 기본안 아님
```

이 fail-closed는 **DESIGN DECISION**이다. 정확성/검증 가능성을 availability보다 우선한다.

호출부:

- not found → `notFound()`
- QUERY_FAILED → 기존 university detail과 같이 실패 메시지. 빈 전형으로 위장하지 않음
- INTEGRITY_VIOLATION → 깨진 graph를 렌더하지 않음. 사용자에게 빈 데이터인 척하지 않음

partial child failure (예: sections 성공, submissions 실패)를
`submissions: []`로 바꾸면 “서류가 없다”는 거짓이 된다. 전체 loader fail.

Phase 2에서 children이 진짜 0개인 program은 빈 배열이 맞다.
그건 query success + empty result이다. error와 구분한다.


# 11. Ordering

## 11.1 Columns that exist (CURRENT FACT)

| entity | column |
| --- | --- |
| admission_sections | `display_order` NOT NULL |
| admission_schedules | `display_order` NOT NULL |
| required_documents | `display_order` NOT NULL |
| document_submissions | `display_order` NOT NULL |
| required_document_choice_groups | `display_order` NOT NULL |
| admission_program_sources | `display_order` **nullable** |
| choice_group_items | 없음 |
| citation relations | 없음 |
| source_citations | 없음 |
| source_documents | 없음 |

`sort_order` / `sequence` column은 이 graph에 없다.

## 11.2 Strategy (DESIGN DECISION)

있으면 `display_order` 사용. 의미적 우선순위(“중요 일정 먼저”)를 만들지 말 것.
DB insertion order에 의존하지 말 것.

tie-break / fallback:

| list | order |
| --- | --- |
| sections, schedules, documents, submissions, choice groups | `display_order` ASC, then `id` ASC |
| programSources | `display_order` ASC NULLS LAST, then `source_document_id` ASC |
| choice group items | 연결된 document의 `display_order`, then `required_document_id`. item 전용 순서가 없으므로 document 순서를 재사용할 뿐, “어느 선택지가 더 공식인지”를 정하지 않음 |
| citations on an entity | `source_citation_id` ASC |

citation UUID 정렬은 **deterministic fallback**일 뿐이다.

```
source_citation_id sort
  ≠ source authority
  ≠ official order
  ≠ conflict resolution
```

UI가 `file_page_number` 등 locator로 보여주는 것은 presentation concern이다.
repository가 page number를 우선하면 HTML(`file_page_number` NULL) citation이 밀려 해석처럼 보인다.

SQL `.order()`와 in-memory sort 중 어디서 해도 결과는 같아야 한다.
권장: query에도 order를 걸고, assembly에서 한 번 더 stable sort.


# 12. KU 2027 Acceptance Cases

이 절의 숫자는 ROW_MAP planned count와
`20260905160000_load_ku_2027_reentry.sql` 후반 DO assertion이 동일하게 강제하는 값이다.
기억된 prompt 숫자가 아니라 migration assertion을 재확인했다.

대상 program: `korea-seoul` / `2027` / `overseas-korean-2pct`
(`admission_programs.id = d35bda6d-9fed-48f1-8687-28c5d07be455`).

read model은 KU 전용이 아니나, 현재 hosted dataset이 이 한 program이므로
acceptance fixture로 쓴다.

## 12.1 Expected counts (CURRENT FACT)

| entity | count |
| --- | ---: |
| universities (this campus row) | 1 |
| admission_programs | 1 |
| admission_sections | 17 |
| admission_schedules | 15 |
| required_documents | 42 |
| document_submissions | 84 |
| required_document_choice_groups | 1 |
| required_document_choice_group_items | 2 |
| admission_program_sources | 6 |
| source_documents (including historical S06) | 7 |
| source_citations | 33 |
| admission_section_citations | 24 |
| required_document_citations | 56 |
| document_submission_citations | 90 |
| admission_schedule_citations | 30 |
| citation relation total | 200 |

read model `programSources.length` = **6**.
read model `Object.keys(sourcesById).length` = **6**.

이 6은 current ProgramSource inventory다.
global `source_documents` count **7**(S06 포함)과 구분한다.
`sourcesById`가 7이 되면 실패다.

## 12.2 Canonical tests

### 1. Route identity resolves one program

`(korea-seoul, 2027, overseas-korean-2pct)` → 한 university + 한 program.
잘못된 year 또는 slug → `null`.
`overseas-korean-2pct`만으로 lookup하지 않음.

### 2. 17 sections, no loss

`section_type` 반복을 포함한 array length 17.
object-key collapse 금지.

### 3. 42 documents, no loss

### 4. 84 submissions, no loss

parent document 아래로 모두 연결. orphan drop 금지.

### 5. SUB82 preservation (canonical integrity case)

migration:

- `document_submissions.id = 46bd94bf-42dd-4d85-85c5-ec828061f6df`
- `verification_status = needs_review`
- `admission_schedule_id` NULL
- `verified_at` NULL
- citations 4개:
  - CIT31 `b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416` (S01 p.4 원본 2027.02.10)
  - CIT07 `79281172-a2c1-4e20-919e-d31c1ef1ada2` (S01 p.6 업로드 서류 + 졸업증명서)
  - CIT27 `ebff4f8d-115a-4f44-939a-f1d3bc74315e` (S05 HTML, 2027년 3월 입학 전)
  - CIT30 `1f779f06-95f7-4520-890a-e5c30560c33e` (S05 PDF p.4)

read model 실패 조건:

- 임의 deadline 생성
- SCH11 (`8a3e7f88-b24d-4822-9737-485c2539c8cf`) 자동 연결 또는 embed
- `linkedSchedule` full object 추론
- citation 한쪽 제거
- `verified`로 승격
- conflict를 typo로 해석
- `needs_review`를 다른 status axis로 치환
- `hasConflict: true` 같은 derived boolean 생성

SUB82는 known curated conflict evidence를 보존하는 acceptance case다.
generic conflict detector의 입력이 아니다.

### 6. S05 HTML / S05 PDF remain separate SourceDocuments

- HTML `b17b767f-7eaf-4e12-a2db-6dcf4f024c25`
- PDF `31c298f9-cde7-407b-be2d-692235e1a391`

둘 다 current ProgramSource이므로 `programSources`와 `sourcesById`에 각각 존재.
repository가 하나로 merge하거나 PDF를 권위로 고르면 실패.

### 7. S06 is historical, not current ProgramSource

- S06 `91ce33c3-e327-4681-a267-04c1ba32c172`
- `programSources`에 없음
- `sourcesById`에 없음
- entity citation graph에 없음
- current citation relation 0
- S01 `supersedes_source_document_id`가 S06를 가리키는 것은 revision 힌트이며 inventory 편입/fetch가 아님
- S06를 cited-union fallback으로 `sourcesById`에 넣으면 실패

### 8. SCH10 / SCH11 citation relationships

SCH10 `6eff94e1-d237-4a8e-867d-ca0a06c81513`:

- CIT06, CIT28, CIT29 (3)

SCH11 `8a3e7f88-b24d-4822-9737-485c2539c8cf`:

- CIT31, CIT29 (2)
- CIT27 / CIT30 없음 (SUB82 row의 citation으로 남김)
- SUB82 `admission_schedule_id`가 SCH11이 아님

CIT29 재사용은 허용. 새 timezone citation을 만들어 붙이지 않음.

복수 citation이 있는 SCH10/SCH11에 `hasConflict = true`를 붙이면 실패.
그 복수 citation은 complementary / timezone provenance일 수 있으며, conflict detector가 아니다.

### 9. Provenance consistency mismatch is not silent

query success 후 cited SourceDocument가 program sources에 없으면 `INTEGRITY_VIOLATION`.
detail facts silent render 금지.
S06 예외는 uncited historical row일 때만 성립. cited이면 fail이며 S06를 payload에 넣어 통과시키지 않음.

### 10. unknown / null values are not invented

timezone NULL 10개 schedule을 GMT+9로 채우지 않음.
SUB81/SUB82 `admission_schedule_id` NULL 유지.
program `verified_at` NULL 유지.

### 11. Read-model source count vs global source_documents

- `programSources.length === 6`
- `Object.keys(sourcesById).length === 6`
- `sourcesById` keys === programSource `source_document_id` set
- global source_documents 7과 같지 않음

### 12. Choice group / items preserved

- `choiceGroups.length === 1`
- that group `items.length === 2`
- item fields는 schema 컬럼만 (`choice_group_id`, `required_document_id`, `admission_program_id`)
- item relations가 실제 document id를 가리킴
- group-level fabricated citations === 0
- member document citation을 group citation으로 상속하지 않음

## 12.3 Additional useful asserts

- `file_page_number`와 `printed_page_label`이 섞이지 않음 (CIT27/CIT28 HTML page NULL)
- submission DTO에 schedule object embed 없음
- 공개 DTO에 `Map` 없음


# 13. Future UI Contract

WIREFRAME §5는 전형 상세를 MVP 핵심 화면으로 둔다.
비교 데이터를 복제하지 않고 이 read model이 읽는 DB가 source of truth다.

## Repository / read-model responsibility

- exact fetch
- identity preservation
- relation assembly
- provenance preservation
- status / null preservation
- integrity fail-closed (query success + invariant 위반 → INTEGRITY_VIOLATION, silent render 금지)
- `hasConflict` 같은 derived conflict flag를 만들지 않음

## UI responsibility

- Korean labels (`verified` → 데이터 검토 완료 등). 기존 university detail 매핑을 재사용 가능
- date/time formatting (`temporal_precision`에 따라 date vs datetime)
- timezone 표시. NULL이면 지어내지 않고 “시간대 미기재” 등
- badge styling
- section visual layout / quick nav
- disclosure / expand
- “출처 보기” 클릭 UX
- disclaimer: 플랫폼 검증 상태 ≠ 대학의 최종 지원자격 판정

WIREFRAME이 원하는 두 수준 source 접근:

- A. section/document/schedule 옆 source reference
- B. 하단 공식 출처 전체 목록 (`programSources`)

read model은 둘 다 가능하게 데이터를 주되, copy/layout은 UI PR에서 정한다.

하지 말 것 (UI도):

- SUB82에 확정 기한을 써 넣기
- S06를 현재 요강인 것처럼 열기
- 복수 citation만 보고 “공식 자료가 충돌한다”고 자동 배지 달기
- `needs_review`를 특정 source conflict 문장으로 일반화하기
- interpretation과 official_fact를 같은 스타일로 보이게 방치 (WIREFRAME 5.10). 스타일은 UI, 값 자체는 `information_type`

`needs_review`의 현재 안전한 표시:

- “추가 확인 필요”
- 관련 공식 출처 (citation → `sourcesById`)


# 14. Compare / Eligibility Boundaries

## Compare

detail read model을 future comparison model과 동일하게 만들 필요 없다.

compare는 나중에 정규화된 field subset이 필요할 수 있다
(예: 일정 시작일만, 어학 요구 유무).

**DESIGN DECISION:** detail DTO에 comparison용 추정/normalization을 미리 넣지 않는다.

공통으로 재사용 가능한 것:

- `UniversityRow`
- `AdmissionProgramRow`
- `SourceDocumentSummary` 같은 primitive

compare loader는 별도 설계한다.

## Eligibility

**CURRENT FACT:** `EligibilityRule` table은 없고 DATA_MODEL상 deferred다.
자격진단은 별도 deterministic rule layer여야 한다.

**DESIGN DECISION:** detail read model에

- 학생 입력 기반 판정
- “지원 가능” boolean
- 체류일수 계산 결과

를 넣지 않는다.

전형 상세의 eligibility **text**는 `admission_sections` (`section_type` 포함)로 보여 준다.
그것은 공식 문장이지 rule engine 결과가 아니다.

WIREFRAME의 “이 전형 자격 확인”은 `/eligibility`로 context만 넘기는 링크다.
그 context는 identity (`university`, `academic_year`, program)이면 충분하다.


# 15. Deferred Decisions

이번 read model에 억지로 넣지 않는다.

- `source_conflicts` dedicated table
- generic conflict-detection model / `hasConflict` derivation
- EligibilityRule implementation
- FAQ integration
- ParentStory integration
- normalized evaluation children
- comparison normalization / compare DTO
- citation UI 상세 (popover vs drawer, printed vs file page 표시 copy)
- admin/edit workflow
- historical source browser (S06 전문 열람; `supersedes` UUID만으로 row fetch하지 않음)
- `choice_group_citations`
- schema trigger로 provenance invariant 승격
- 공개 DTO의 `schedulesById` convenience map
- `requirement_status` / `submission_phase` vocabulary를 CHECK로 고정
- admission_categories를 화면 identity에 어떻게 쓸지 (label vs hide)
- `AdmissionProgramDetail` 타입 이름과 새 read-model 타입의 rename
  (현재 이름이 route lookup이라 혼동 여지가 있음. rename은 별도 PR)


# 16. Recommended Implementation Plan

작은 PR로 나눈다. 한 PR에 UI와 integrity와 schema를 섞지 않는다.

## PR A — read-model types + repository only

- row DTO 확장 (`AdmissionSectionRow` 등). schema column만
- `getAdmissionProgramDetailReadModel`
- Phase 1–7 assembly (SourceDocument fetch는 ProgramSource IDs only)
- integrity fail-closed (`INTEGRITY_VIOLATION`은 payload를 반환하지 않음)
- 기존 `getAdmissionProgramDetail` 유지
- UI 없음
- SELECT only, no-store 유지
- 반환 DTO는 plain objects / arrays / `Record` (JS `Map` 없음)

## PR B — repository runtime / integrity tests

- KU 2027 count asserts (`sourcesById` 6 vs global source_documents 7)
- SUB82 (`admission_schedule_id` null, no SCH11 embed, no `hasConflict` flag)
- S05 split, S06 exclusion from programSources/sourcesById/citation graph
- choice group 1 / items 2 / group citations fabricated = 0
- unknown slug → null
- query failure vs empty children
- mismatch fixture → INTEGRITY_VIOLATION (cited-outside-inventory를 union하지 않음)
- hosted runtime smoke는 기존 admissions smoke와 분리 가능

## PR C — admission detail Server Component shell

- route `app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/page.tsx`
- identity header, disclaimer, section/document/schedule 기본 렌더
- 값 추정 없이 stored text/status 표시
- citation UI는 최소 또는 “출처 있음” 수준
- university detail에서 이 route로 링크 (C 또는 후속 초소형 PR)

## PR D — source / citation presentation

- fact 옆 “출처 보기”
- 하단 `programSources` 목록
- `file_page_number` vs `printed_page_label` 구분 표시
- `needs_review`를 숨기지 않음. 표시는 “추가 확인 필요” + 관련 출처.
  “공식 자료가 충돌한다” 자동 카피는 하지 않음

## Optional later

- PR E: university list에서 detail 링크 등 탐색 UX
- PR F: compare DTO (이 read model을 복제하지 말 것)
- PR G: eligibility rule layer (별도)

테스트는 A 직후 B를 권장한다. UI를 먼저 만들면 SUB82를 화면에서 보정하고 싶어질 수 있다.


# Appendix A. Existing vs proposed loader

| | `getAdmissionProgramDetail` | `getAdmissionProgramDetailReadModel` |
| --- | --- | --- |
| 입력 | universitySlug, academicYear, admissionSlug | 동일 |
| 로드 | universities + admission_programs | + children + citations + sources |
| 실패 | null / AdmissionsQueryError | + integrity error |
| 용도 | 향후 route lookup, 가벼운 identity | 전형 상세 페이지 source of truth |
| 이번 작업 | 변경 없음 | 설계만 |

# Appendix B. Label legend

문서에서 KU logical ID(`KU27-*`)는 설명용이다.
runtime identity는 UUID와 route slug/year이다.
UI source에 고려대학교 / `korea-seoul` / 재외국민을 hard-code하지 않는다.
acceptance test fixture만 그 identity를 사용한다.
)
