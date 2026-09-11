# Provenance UI Contract

이 문서는 전형 상세 페이지에서 **FACT → CITATION → SOURCE DOCUMENT** 연결을
사용자에게 보여주는 presentation contract다.

문서 안의 문장은 다음 세 종류로 구분한다.

- **CURRENT FACT** — 현재 schema, read-model DTO, 기존 page/loader가 실제로 지원하는 내용
- **DESIGN DECISION** — 이번 provenance UI에서 추천하는 선택
- **DEFERRED** — 아직 구현하지 않는 내용

추측을 CURRENT FACT처럼 쓰지 않는다.
`docs/ADMISSION_DETAIL_READ_MODEL.md`의 camelCase 초안 이름
(`CitationWithSourceReference`, `sourceDocumentId` 등)이 아니라
**현재 production TypeScript 필드명**을 사용한다.


# 1. Purpose

사용자가 전형 상세의 각 사실에 대해 다음을 확인할 수 있어야 한다.

- 어떤 근거(citation)가 연결되어 있는지
- 어느 공식 문서(SourceDocument)인지
- PDF의 어느 **실제(physical)** 페이지인지
- 문서가 언제 발표되었는지 (`published_at`, 값이 있을 때만)
- 플랫폼이 해당 자료를 언제 마지막으로 확인했는지 (`last_checked_at`)

핵심은 편리한 요약이 아니라
저장된 연결을 보이게 하는 것이다.

이 UI는 **지원 자격 판정 기능이 아니다.**
근거가 있다는 이유로 지원 가능/자격 충족을 추론하지 않는다.


# 2. Scope / Non-goals

## In scope (첫 provenance UI 구현 대상)

- `AdmissionSection` (`SectionWithProvenance`)
- `AdmissionSchedule` (`ScheduleWithProvenance`)

두 entity의 `citations: SourceCitationRow[]`만 disclosure한다.

## Out of scope for the first implementation PR

- production UI 코드 (이번 문서는 design only)
- `RequiredDocument` / `DocumentSubmission` provenance
- `ChoiceGroup` (schema에 `choice_group_citations` 없음)
- program-level source browser (하단 전체 출처 목록)
- historical source browser (`supersedes_source_document_id` follow)
- conflict visualization / `hasConflict`
- citation admin UI
- Client Component accordion
- `source_type` 한국어 번역 맵
- `error.tsx` / loader-throw HTTP 5xx 인프라
- university detail page 변경
- `app/layout.tsx` 변경

WIREFRAME §5.11의 페이지 하단 “공식 출처” 전체 목록과
`docs/ADMISSION_DETAIL_READ_MODEL.md` PR D의
“하단 `programSources` 목록”은 **DEFERRED**.
기존 shell의 program-level count copy
(`연결된 출처 ${detail.programSources.length}건`)는 유지한다.


# 3. Current Data Contract

## 3.1 Loader / page (CURRENT FACT)

전형 상세 route:

`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`

page는 async Server Component이며
`getAdmissionProgramDetailReadModel(slug, academicYear, admissionSlug)`만 사용한다.
UI가 SourceDocument를 다시 query하지 않는다.
direct Supabase / `withClient` / browser Supabase는 없다.

현재 page는 section/schedule **fact fields만** 렌더한다.
`item.citations`와 `detail.sourcesById`는 아직 UI에 전달되지 않는다.

## 3.2 Wrappers (CURRENT FACT)

production types (`lib/admissions/detail-types.ts`):

```
SectionWithProvenance = {
  section: AdmissionSectionRow
  citations: SourceCitationRow[]
}

ScheduleWithProvenance = {
  schedule: AdmissionScheduleRow
  citations: SourceCitationRow[]
}

AdmissionProgramDetailReadModel.sourcesById
  = Record<string, SourceDocumentSummary>
```

`CitationWithSourceReference`라는 타입은 **코드에 없다.**
citation unit은 `SourceCitationRow`다.

## 3.3 SourceCitationRow (CURRENT FACT)

| field | type | notes |
| --- | --- | --- |
| `id` | `string` | citation identity. collapse 금지 |
| `source_document_id` | `string` | `sourcesById` lookup key |
| `file_page_number` | `number \| null` | physical PDF page, 1-based. HTML은 NULL |
| `printed_page_label` | `string \| null` | 문서 내부 표기. physical page와 다른 column |
| `section` | `string \| null` | **SourceDocument 안의** 위치 텍스트. AdmissionSection.title이 아님 |
| `anchor_description` | `string \| null` | 더 구체적인 위치/확인 메모. locator 보조 |
| `verified_at` | `string \| null` | citation location 확인 timestamptz |
| `created_at` | `string` | row 생성 시각. 사용자 provenance 1차 정보가 아님 |

schema (`source_citations`): `file_page_number`는 NULL 또는 `>= 1`.
citation에 `verification_status` column은 없다.
citation 전용 display_order column은 없다.

## 3.4 SourceDocumentSummary (CURRENT FACT)

| field | type | notes |
| --- | --- | --- |
| `id` | `string` | `sourcesById` key |
| `university_id` | `string \| null` | |
| `academic_year` | `number \| null` | |
| `source_type` | `string` | unchecked text. 사용자-facing map 없음 |
| `title` | `string` | NOT NULL |
| `issuing_organization` | `string` | NOT NULL |
| `source_url` | `string` | schema `text NOT NULL`. UNIQUE 아님. identity 아님 |
| `published_at` | `string \| null` | Postgres **date**. 시각 없음 |
| `last_checked_at` | `string` | timestamptz **NOT NULL** |
| `document_version_label` | `string \| null` | |
| `supersedes_source_document_id` | `string \| null` | follow 금지 |
| `notes` | `string \| null` | load/internal commentary 가능. 사용자 UI에 그대로 노출하지 않음 |

URL은 identity가 아니다.
`published_at` ≠ `last_checked_at`.

## 3.5 Resolution (CURRENT FACT)

```
citation.source_document_id
  → detail.sourcesById[source_document_id]
```

`sourcesById` key 집합 = current `programSources`의 `source_document_id` 집합.
cited SourceDocument가 inventory 밖이면 loader가 `INTEGRITY_VIOLATION`.
missing SourceDocument도 fail-closed.

정상 UI contract에서 “Unknown source”는 발생하지 않는 것으로 취급한다.

## 3.6 Citation order (CURRENT FACT)

entity에 붙은 citations는
`source_citation.id` localeCompare ASC다
(`lib/admissions/detail-assembly.ts` `sortCitations`).

이 순서는 deterministic fallback일 뿐
source authority / 공식 순서 / conflict resolution이 아니다.

repository는 `file_page_number`로 정렬하지 않는다.
HTML(`file_page_number` NULL) citation을 뒤로 미루면 해석처럼 보인다.

## 3.7 KU 2027 counts (CURRENT FACT, hosted fixture)

대상 route: `korea-seoul` / `2027` / `overseas-korean-2pct`

| | count |
| --- | ---: |
| sections | 17 |
| schedules | 15 |
| `admission_section_citations` | 24 |
| `admission_schedule_citations` | 30 |
| current `programSources` / `sourcesById` | 6 |
| unique `source_citations` (program graph) | 33 |
| historical S06 in current inventory | 0 |

S05 HTML과 S05 PDF는 별도 SourceDocument다.
S06는 current citation/inventory에 없다.

## 3.8 Existing shell copy (CURRENT FACT)

program-level:

`연결된 출처 ${detail.programSources.length}건`

verification disclaimer는 유지한다.
provenance disclosure가 이 disclaimer를 대체하지 않는다.


# 4. User Terminology

## 4.1 Fact-level vs program-level (DESIGN DECISION)

| 층 | 데이터 | 사용자 문구 |
| --- | --- | --- |
| Program | `detail.programSources.length` (SourceDocument inventory) | `연결된 출처 N건` |
| Fact | `item.citations.length` (SourceCitation relations) | `근거 N건 보기` |

두 count는 동일 개념이 아니다.

같은 모집요강의 서로 다른 페이지는 각각 citation일 수 있다.
citation 2건 ≠ SourceDocument 2건.

따라서 fact disclosure label로
`출처 N건` / `출처 보기`는 **쓰지 않는다.**
WIREFRAME §5.4의 `[출처 보기]`와
read-model PR D의 “출처 보기”는 이 계약이 fact-level에서 수정한다.

0/1/N 모두 같은 명사(“근거”)를 쓴다.
`근거 1건 보기`를 `근거 보기`로 바꾸지 않는다.

## 4.2 Allowed vs forbidden wording (DESIGN DECISION)

허용:

- 근거 N건 보기
- 현재 연결된 근거 없음
- 원문 열기
- PDF 실제 N페이지
- 문서 표기: {stored label}
- 문서 위치: {section}
- 위치 설명: {anchor_description}
- 발표일: YYYY-MM-DD
- 자료 최종 확인(UTC): YYYY-MM-DD

금지 (stored data가 명시적으로 지원하지 않음):

- 공식적으로 검증됨
- 이 자료로 지원 가능 / 자격 충족 / 지원 불가능
- 정답 / 확정
- 자료 충돌 / 상충 / 불일치 (자동)
- 모든 공식 출처 / 완전 검증
- 공식 출처 없음 / 근거 자료가 존재하지 않음 / 근거가 없음 / 자료 없음
- 대학 최종 수정일 / 대학 공식 확인일 / 전형 검증 완료일
  (`last_checked_at` 또는 citation `verified_at`을 그렇게 부르는 것)
- 공식 자료 열기 (generic UI. `source_type`이 official을 보장하는 enum이 아님)


# 5. Fact-to-Citation Interaction

## 5.1 Native disclosure (DESIGN DECISION)

`citations.length >= 1`이면 native HTML:

```
<details>
  <summary>근거 N건 보기</summary>
  … citation items …
</details>
```

이유:

- Server Component 유지
- `"use client"` / `useState` / `useEffect` 불필요
- JS disclosure library 없음
- keyboard / browser semantics 기본 지원

기본 상태는 **닫힘** (`open` 속성 넣지 않음).
17+15개 disclosure를 모두 열어 두면 본문이 묻힌다.

새 UI library 금지.
custom accordion은 **DEFERRED**.

## 5.2 No Client Component (DESIGN DECISION)

첫 구현: Client Component = 0.

## 5.3 Multiple citations are not conflict (DESIGN DECISION)

`citations.length > 1`이어도
요약 문구는 `근거 N건 보기`만 쓴다.

`needs_review`여도 disclosure가 충돌 경고로 바뀌지 않는다.
verification status UI와 provenance UI는 별도 축이다.
generic conflict detector 없음. `hasConflict` 없음.


# 6. Citation Presentation

## 6.1 Unit = one SourceCitation (DESIGN DECISION)

한 disclosure item의 기본 단위는 **하나의 `SourceCitationRow`**다.

- `citation.id`를 list key로 쓴다
- 같은 `source_document_id`를 가진 citation 여러 개를 merge하지 않는다
- 같은 `title`이 반복되어도 physical page / printed label / locator를 보존한다

사용자 스케치(같은 모집요강 제목 + 서로 다른 PDF 페이지)가 이 모델이다.

## 6.2 Flat list, not SourceDocument groups (DESIGN DECISION)

비교:

| | A. citation별 flat list | B. SourceDocument별 group |
| --- | --- | --- |
| citation identity | 항목 = citation | group 안에 유지해야 함 |
| 같은 PDF 제목 반복 | 반복됨 (허용) | 제목은 한 번 |
| physical page | item마다 자연스럽게 | group 하위에 필요 |
| conflict 시각화 여지 | 이후 추가 가능 | group이 권위처럼 읽힐 수 있음 |
| 구현 | 단순 | group 순서 결정 필요 |

**첫 구현은 A.**

grouping은 제목 반복을 줄이지만
group 순서가 “공식 우선순위”로 오해되기 쉽다.
첫 PR에서는 citation identity와 단순성을 우선한다.

나중에 grouping하더라도 개별 citation collapse는 금지.
group order도 권위/최신성을 의미하지 않아야 한다.
`published_at` 최신 우선으로 source를 고르는 방식은 금지.

## 6.3 Resolve, do not hide (DESIGN DECISION)

각 citation:

```
const source = sourcesById[citation.source_document_id]
```

UI는 추가 fetch를 하지 않는다.

lookup 실패는 정상 경로가 아니다.
`"Unknown source"` fallback으로 숨기지 않는다.
구현은 해당 렌더를 실패시켜 loader 에러 경로로 보낸다
(현재 page catch의 generic 메시지는 **KNOWN FOLLOW-UP**.
이번 provenance PR에서 `error.tsx`를 추가하지 않는다).

## 6.4 Order in the disclosure (DESIGN DECISION)

read-model 배열 순서를 그대로 사용한다
(`citation.id` ASC).

presentation용 page/title sort는 하지 않는다.
순서를 바꿔도 그것은 display convenience일 뿐
semantic authority가 아님을 명시한다. 첫 PR에서는 바꾸지 않는다.

## 6.5 S05 / S06 (DESIGN DECISION + CURRENT FACT)

S05 HTML과 S05 PDF citation이 같은 fact에 붙어 있으면 **둘 다** 보여준다.
UI가 “더 공식적인 것”을 고르거나 한쪽을 숨기지 않는다.
KU/S05 identity를 production UI에 hard-code하지 않는다.

S06는 current `sourcesById`와 current citation graph에 없다.
`supersedes_source_document_id`를 따라 넣지 않는다.
렌더 0.


# 7. SourceDocument Presentation

각 citation item의 정보 순서 (DESIGN DECISION):

1. `title` (primary identity)
2. `issuing_organization` (secondary. schema NOT NULL이므로 값이 있으면 표시)
3. locators — §8
4. `발표일: {published_at}` — 값이 있을 때만. calendar date fact. UTC 접미사 없음
5. `자료 최종 확인(UTC): {last_checked_at의 UTC calendar date}`
6. `원문 열기` — §7.2 URL safety를 통과한 경우만

표시하지 않음 (첫 PR):

- `source_type` (영문 enum 노출 금지. 임의 한국어 번역 금지. mapping은 DEFERRED)
- `document_version_label` (KU title에 버전 문구가 이미 있는 경우가 많음. 중복 표시 DEFERRED)
- `notes` (internal load commentary)
- `supersedes_source_document_id` 및 가리키는 historical document
- `id` / `university_id` / `academic_year`를 사용자 identity로 사용
- URL 문자열 자체 (identity가 아님. 링크 href로만 사용)

## 7.1 Title length (DESIGN DECISION)

첫 구현은 **full title을 접지 않고 줄바꿈으로 보여 준다.**
CSS visual truncation을 쓰더라도 accessible full title이 남아 있어야 한다.
과도한 design은 DEFERRED.

## 7.2 source_url (CURRENT FACT + DESIGN DECISION)

schema/DTO 모두 `source_url` **NOT NULL**.
nullable missing-URL 상태는 현재 contract에 없다.

NOT NULL과 non-empty string만으로 모든 값을 `href`에 넣는 계약은 두지 않는다.

**DESIGN DECISION — 원문 링크 렌더 조건 (모두 충족):**

1. URL parse가 성공한다
2. `protocol === "https:"` 또는 `protocol === "http:"`

그 경우에만:

```
<a href={parsedHref} target="_blank" rel="noopener noreferrer">원문 열기</a>
```

`target="_blank"`를 쓰면 `rel="noopener noreferrer"`를 유지한다.

링크를 **생략**하는 경우:

- 빈 문자열 / whitespace-only
- malformed URL (parse 실패)
- unsupported scheme: `javascript:`, `data:`, `file:`, `vbscript:` 등
  `http:` / `https:`가 아닌 모든 protocol

금지:

- 가짜 URL 생성
- allowed protocol 외 값을 외부 navigation에 사용
- 링크가 없다고 공식 자료가 없다고 해석
- 빈 문자열을 “공식 자료 없음”으로 해석

Next `Link`를 외부 원문의 기본 선택으로 강제하지 않는다.

label은 **원문 열기**.
`공식 자료 열기`는 `source_type`/official classification이
이를 보장하지 않으므로 쓰지 않는다.


# 8. Page / Locator Semantics

## 8.1 Physical PDF page (CURRENT FACT + DESIGN DECISION)

`file_page_number` = physical PDF page, 1-based.

값이 있으면:

`PDF 실제 {N}페이지`

이 숫자를 인쇄면(printed page)과 같다고 쓰지 않는다.
`p.{N}` / `쪽`만으로 physical page를 대체하지 않는다.

## 8.2 Printed page label (CURRENT FACT + DESIGN DECISION)

`printed_page_label`은 별도 column이다.
KU 값은 `"4"`일 수도 있고 `"- 2 -"`일 수도 있다.

값이 있으면 stored string 그대로:

`문서 표기: {printed_page_label}`

`쪽`을 구현이 붙이지 않는다. 저장된 label이 이미 표기를 포함한다.

physical과 printed를 한 값으로 합치지 않는다.
둘 다 있으면 **두 줄**:

```
PDF 실제 4페이지
문서 표기: 4
```

한 줄 시각 축약은 가능하나 레이블은 분리된 채로 남아야 한다.

## 8.3 HTML / no page (CURRENT FACT + DESIGN DECISION)

`file_page_number === null`이면 페이지 줄을 **생략**한다.

`PDF 페이지 없음` / `페이지 정보 없음` placeholder를 넣지 않는다.
HTML이라는 이유로 `page=1`을 생성하지 않는다.

`printed_page_label`이 함께 null이면 그것도 생략한다.
(KU CIT27/CIT28: HTML, page null, printed null, `section`/`anchor_description` 사용.)

## 8.4 section / anchor_description (DESIGN DECISION)

둘 다 SourceCitation locator 보조 필드다.
AdmissionSection의 `title` / `section_type`이 아니다.

| field | 값이 있을 때 |
| --- | --- |
| `section` | `문서 위치: {section}` |
| `anchor_description` | `위치 설명: {anchor_description}` |

schema semantics를 “지원 자격 항목명” 등으로 확대하지 않는다.
둘 다 null이면 생략한다.


# 9. Date / Verification Semantics

세 시각은 서로 다른 의미다. **하나를 다른 하나의 fallback으로 쓰지 않는다.**

| field | 의미 | 첫 provenance UI |
| --- | --- | --- |
| `AdmissionProgram.verified_at` | program 전체 주요 항목 검토 시각. nullable | 기존과 같이 상단 확정값으로 보여 주지 않음. disclosure에 사용 금지 |
| `AdmissionSection.verified_at` / `AdmissionSchedule.verified_at` | 해당 fact row 검토 시각 | 첫 disclosure에 표시하지 않음 |
| `SourceCitation.verified_at` | 그 citation location을 확인한 시각 | 첫 PR에서 **생략** |
| `SourceDocument.published_at` | 자료 **발표일**. Postgres **date**. calendar date fact. timezone 없음 | `발표일: YYYY-MM-DD` (값 있을 때만). UTC 접미사 없음 |
| `SourceDocument.last_checked_at` | 플랫폼이 이 SourceDocument를 마지막으로 확인한 **timestamptz** | `자료 최종 확인(UTC): YYYY-MM-DD` |

## 9.1 왜 citation `verified_at`을 첫 PR에서 빼는가 (DESIGN DECISION)

같은 item에 `last_checked_at`과 citation `verified_at`을 같이 두면
사용자가 둘을 전형 검증 완료일로 섞기 쉽다.
첫 구현은 문서 단위 `자료 최종 확인(UTC)` 하나만 보여 정보 과부하를 줄인다.

생략하는 것: `SourceCitation.verified_at`.
이유: 사용자에게 더 직접적인 질문은 “이 문서를 플랫폼이 언제 확인했는가”이고
그 답은 `last_checked_at`이다.
citation location 재확인 시각은 내부 provenance 정밀도에 가깝다.

`last_checked_at`의 UTC 표시를 citation `verified_at`의
대체값이나 fallback으로 쓰지 않는다.
세 시각은 서로 다른 필드다.

citation `verified_at`을 program/section 검토일처럼 쓰지 않는다.
나중에 표시할 때도 `위치 확인:` 같은 별도 라벨이 필요하다. **DEFERRED**.

## 9.2 published_at (CURRENT FACT + DESIGN DECISION)

`published_at`은 **calendar date fact**다.
Postgres `date` column. timezone / time-of-day가 없다.

값이 있으면 stored `YYYY-MM-DD`를 그대로 보여 준다.

```
발표일: YYYY-MM-DD
```

null이면 생략. `00:00`을 만들지 않는다.
UTC 접미사를 붙이지 않는다. date에는 UTC 기준이 없다.

`last_checked_at`과 formatter semantics가 다르다.
`발표일`을 `자료 최종 확인(UTC)`의 fallback으로 쓰지 않는다.
대학이 그 날짜에 “최종 확정했다”는 뜻이 아니다.

## 9.3 last_checked_at timezone (CURRENT FACT + DESIGN DECISION)

`last_checked_at`은 **timestamp fact**다.
timestamptz NOT NULL.
KU load 값은 UTC literal이다. 예: `2026-09-05T17:02:00Z`.

이 instant를 런타임 locale/KST/Istanbul 등 사용자 timezone으로
calendar date를 만들면 날짜가 바뀐다.

```
2026-09-05T17:02:00Z  →  UTC date 2026-09-05
                      →  KST 2026-09-06 02:02
```

금지:

- `toLocaleDateString`
- runtime / user timezone에 따라 날짜가 이동하는 formatter
- KST 추정
- Istanbul 또는 기타 로컬 timezone 추정
- `last_checked_at`을 대학 발표일 / 대학 확인일 / 전형 검증 완료일로 표현
- citation `verified_at`를 이 표시의 대체·fallback으로 사용

비교:

| | A | B |
| --- | --- | --- |
| 표시 | `자료 최종 확인(UTC): YYYY-MM-DD` | `자료 최종 확인:` + `YYYY-MM-DD HH:mm UTC` |
| timezone 노출 | 라벨에 UTC | 시각+UTC |
| 첫 구현 단순성 | 높음 | 시각 포맷 필요 |

**선택: A.** 첫 구현 단순성을 위해 UTC calendar date만 쓰고,
timezone 기준이 숨겨지지 않도록 라벨에 `(UTC)`를 넣는다.

```
자료 최종 확인(UTC): YYYY-MM-DD
```

formatting 규칙:

- 저장된 ISO가 `Z` 또는 `+00:00`이면 그 UTC 날짜 prefix를 쓴다
- 다른 offset이면 UTC로 환산한 **날짜만** 쓴다. 로컬 날짜를 쓰지 않는다
- Korean `2026. 6. 10.` 로케일 포맷은 쓰지 않는다
- 시각(`HH:mm`)은 첫 PR에서 넣지 않는다 (옵션 B는 DEFERRED)

`자료 확인일`만 쓰지 않는다. “확인일”은 대학 확인일로 읽히기 쉽다.
“최종”은 플랫폼이 그 SourceDocument를 마지막으로 본 시점이지
전형 검증 완료가 아니다.
`(UTC)`는 그 calendar date의 기준이 UTC임을 사용자에게 알린다.

## 9.4 Program verification stays on the existing axis (DESIGN DECISION)

상단 `검증 상태: …`와 disclaimer는 그대로 둔다.
provenance item이 `partially_verified` / `needs_review`를 다시 해석하지 않는다.


# 10. Multiple Citations / Conflict Safety

CURRENT FACT: `source_conflicts` table 없음. `hasConflict` 없음.
복수 citation은 complementary evidence일 수 있다.

DESIGN DECISION:

- N>1 → `근거 N건 보기`
- parent `needs_review` → disclosure copy 변경 없음
- S05 HTML/PDF 동시 표시 가능
- “더 최근 자료”, “PDF가 정본” 같은 resolution 금지


# 11. Zero-Citation State

`citations.length === 0`은 정상이다.
loader integrity 실패가 아니다.

```
0 citation
  ≠ no official evidence exists
  ≠ 공식 근거 자체가 존재하지 않음
```

뜻은: **현재 플랫폼 read model에 이 fact row의 citation relation이 연결되어 있지 않다.**
대학 공식 자료가 존재하지 않는다는 뜻이 아니다.

비교:

| | A. disclosure 숨김 | B. neutral metadata |
| --- | --- | --- |
| 조용함 | 높음 | 낮음 |
| “출처 UI를 빠뜨린 것”과 구분 | 어려움 | 가능 |
| 공식 부재 단정 위험 | 낮음 | copy만 잘못 쓰면 높음 |

**추천: B.** 사용자 문구도 플랫폼 **현재** 상태임을 유지한다.

표시:

`현재 연결된 근거 없음`

`<details>` / `근거 0건 보기`는 쓰지 않는다.

금지:

- 공식 출처 없음
- 근거 자료가 존재하지 않음
- 근거가 없음
- 출처 없음
- 자료 없음

## 11.1 Three states (DESIGN DECISION)

| `citations.length` | UI |
| ---: | --- |
| 0 | static `현재 연결된 근거 없음` |
| 1 | `<details><summary>근거 1건 보기</summary>` + item 1 |
| >1 | `<details><summary>근거 N건 보기</summary>` + item N, 충돌 문구 없음 |


# 12. Section Placement

기존 `SectionArticle` 순서에 provenance를 붙인다.

1. `title`
2. `content`
3. `applicability_text` (있을 때만. 없으면 생략. “공통 적용” 추론 없음)
4. provenance (disclosure 또는 `현재 연결된 근거 없음`)

fact 바로 아래다.
페이지 하단 inventory만으로 fact-to-source를 대체하지 않는다.

`section_type`을 공식 label로 번역하지 않는 기존 shell 규칙을 유지한다.
section identity collapse 없음. runtime 17 유지.


# 13. Schedule Placement

기존 `ScheduleArticle` 순서:

1. `event_name`
2. date/datetime window (기존 date-only / raw timestamptz 규칙)
3. `timezone` (non-null만)
4. `location_text` (있을 때만)
5. `description` (있을 때만)
6. provenance (disclosure 또는 `현재 연결된 근거 없음`)

전형 전체 `연결된 출처 N건`과
개별 schedule citation disclosure를 구분한다.

schedule identity collapse 없음. runtime 15 유지.


# 14. Component Contract

## 14.1 Conceptual component (DESIGN DECISION, 코드 없음)

```
CitationDisclosure({
  citations: SourceCitationRow[]
  sourcesById: Record<string, SourceDocumentSummary>
})
```

실제 type names는 `lib/admissions` export와 같다.
`CitationWithSourceReference`를 새로 만들지 않는다.

책임:

- fetch하지 않음
- Supabase를 모름
- eligibility / conflict / verification 해석 없음
- `citations` + `sourcesById` presentation only
- 0/1/N 상태 처리

page는 이미 받은 `detail`에서
`item.citations`와 `detail.sourcesById`만 넘긴다.

## 14.2 Location (DESIGN DECISION)

비교:

| | A. route-local `_components/` | B. `components/admissions/` |
| --- | --- | --- |
| 첫 PR 범위 | page 옆에 가깝다 | 공유 폴더 신설 |
| document/submission 재사용 | 이후 이동 필요 | 그대로 재사용 |
| data layer와 분리 | 가능 | `lib/admissions`와 명확히 분리 |

**추천: B.** `components/admissions/`의 presentational Server Component.

현재 repo에 `components/`가 없다. 첫 구현 PR에서 이 폴더를 만든다.
`lib/admissions`에 UI를 넣지 않는다 (loader/DTO 경계 유지).

첫 PR이 한 파일에 인라인해도 동작은 같지만
Section/Schedule에 동일 JSX를 복제하지 말라는 요구와 맞지 않으므로
처음부터 작은 공유 컴포넌트를 둔다.

## 14.3 No re-query (DESIGN DECISION)

CitationDisclosure가 repository/API를 다시 호출하는 설계 금지.


# 15. Accessibility / Server Rendering / Responsive

## 15.1 Semantics (DESIGN DECISION)

- 기존 `main` / `header` / `h1` / `section` / `h2` / `article` 유지
- summary 텍스트 자체에 `근거 N건 보기` (아이콘/색만으로 의미 전달 금지)
- citation list는 `<ul><li>` (한 `li` = 한 citation)
- 링크 텍스트는 `원문 열기` (`여기` / `클릭` 금지)
- 비interactive status를 button처럼 보이지 않게 (기존 검증 상태 규칙 유지)
- `details`/`summary`는 native keyboard 동작에 맡김

debug-only hidden markup (`data-citation-count` 등 테스트 전용 숨김 노드) 금지.
acceptance count는 실제 `li`로 센다.

## 15.2 Layout (DESIGN DECISION)

표(table)보다 **stacked metadata**.

모바일에서 한 줄로 title+page+dates+link를 잇지 않는다.

```
{title}
{issuing_organization}
PDF 실제 N페이지
문서 표기: …
문서 위치: …
위치 설명: …
발표일: YYYY-MM-DD
자료 최종 확인(UTC): YYYY-MM-DD
원문 열기
```

없는 필드는 줄을 만들지 않는다.

## 15.3 Rendering constraints (CURRENT FACT + DESIGN DECISION)

- `export const dynamic = "force-dynamic"` 유지
- ISR / `revalidate` / `"use cache"` / `force-static` 추가 금지
- 기존 read client `cache: "no-store"` 유지
- write / service_role / browser Supabase = 0


# 16. Runtime Acceptance Criteria

첫 provenance UI PR에서 검증할 것.
DB write 금지. 기존 hosted read + production HTML.

## 16.1 Route

`GET /universities/korea-seoul/admissions/2027/overseas-korean-2pct`
→ HTTP 200 유지.

잘못된 identity → HTTP 404 유지.

## 16.2 Fact counts

- section `<article>` 17
- schedule `<article>` 15

## 16.3 Citation item counts

semantic `<li>` (hidden debug node 아님):

- section articles 안의 citation items = **24**
- schedule articles 안의 citation items = **30**

각 item은 `sourcesById` resolve에 성공한 title을 가진다.

## 16.4 Copy / locators

- `근거 N건 보기` summary 존재 (N은 해당 entity의 `citations.length`)
- SourceDocument `title` 존재
- PDF citation: `PDF 실제 {N}페이지` 존재 (stored `file_page_number`)
- HTML citation (page null): fake `PDF 실제 1페이지` 없음
- `연결된 출처 6건` 유지 (ProgramSource count)
- fact-level에 `출처 N건` / `출처 N건 보기` 미사용
- 0-citation copy가 있으면 `현재 연결된 근거 없음` ( `공식 출처 없음` 아님 )
- PDF item: `자료 최종 확인(UTC):` 존재. timezone-less `자료 최종 확인:` only는 사용하지 않음
- `원문 열기` href는 `http:` / `https:`만
- S06 title/historical follow 렌더 0
- `공식 자료 충돌` / 지원 가능·불가능 문구 0

## 16.5 Test approach (DESIGN DECISION)

병행:

1. 기존 `npm run test:admission-detail:integrity` / `hosted` (loader 회귀)
2. production `GET` HTML 검사 (disclosure/summary/title/page/item count)
3. `npm run lint` / `npm run build`

UI 전용 node:test를 추가한다면 **read-only HTML/loader assert**만.
hosted test가 loader graph를 이미 증명하므로
UI 테스트가 DB를 다시 조립하지 않아도 된다.

## 16.6 KU-specific hard-code

production component/page에
고려대학교 / `korea-seoul` / 재외국민 / S05 / S06 / SUB82 UUID를 넣지 않는다.
acceptance fixture만 그 identity를 안다.


# 17. Deferred Decisions

- RequiredDocument / DocumentSubmission provenance UI
- ChoiceGroup provenance (relation table 없음)
- program-level source browser (WIREFRAME §5.11)
- historical / superseded source browser
- SourceDocument group-by-document disclosure
- `source_type` 사용자-facing mapping
- `document_version_label` 별도 표시
- `SourceCitation.verified_at` 사용자 표시
- child entity `verified_at` 표시
- JS accordion / Client Component
- conflict visualization / `source_conflicts`
- citation admin UI
- polished locale date (`2026. 6. 10.`) after a timezone-safe formatter exists
- CSS title truncation design
- university-detail → admission-detail 카드 링크
- loader throw → HTTP 5xx (`error.tsx`)


# 18. Recommended Implementation PR

**Provenance UI PR 1** (이 문서 다음의 code PR):

포함:

- `components/admissions/` presentational `CitationDisclosure`
- AdmissionSection citations
- AdmissionSchedule citations
- SourceDocument `title` (+ `issuing_organization`)
- physical PDF page when present
- printed page label when present
- section / anchor locator when present
- `발표일` when `published_at` present (date, no UTC suffix)
- `자료 최종 확인(UTC): YYYY-MM-DD` from `last_checked_at`
- `원문 열기` only when URL parse succeeds and protocol is `http:` or `https:`
- native `details`/`summary`
- 0-citation `현재 연결된 근거 없음`
- no Client Component
- 기존 program-level `연결된 출처 N건` 유지

제외:

- documents / submissions
- historical browser
- conflict detector
- source-management UI
- `source_type` labels
- layout / university detail 변경
- loader/repository 변경 (필요 없음. 데이터가 이미 있음)

예상 변경 파일 (구현 시, 이번 docs PR 아님):

- `app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/page.tsx`
- `components/admissions/CitationDisclosure.tsx` (신설)

`lib/*`, `supabase/*`, package files, tests의 production loader는
회귀 방지 외에 바꾸지 않는 것을 기본으로 한다.


# Appendix. Field checklist for implementers

citation item에 쓰는 것:

`SourceCitationRow.id`
`SourceCitationRow.source_document_id`
`SourceCitationRow.file_page_number`
`SourceCitationRow.printed_page_label`
`SourceCitationRow.section`
`SourceCitationRow.anchor_description`

resolve 후 쓰는 것:

`SourceDocumentSummary.title`
`SourceDocumentSummary.issuing_organization`
`SourceDocumentSummary.source_url` (href only after http/https parse)
`SourceDocumentSummary.published_at`
`SourceDocumentSummary.last_checked_at` (UTC calendar date, label includes `(UTC)`)

첫 PR에서 쓰지 않는 것:

`SourceCitationRow.verified_at`
`SourceCitationRow.created_at`
`SourceDocumentSummary.source_type`
`SourceDocumentSummary.notes`
`SourceDocumentSummary.document_version_label`
`SourceDocumentSummary.supersedes_source_document_id`
`program.verified_at` as fallback
)
