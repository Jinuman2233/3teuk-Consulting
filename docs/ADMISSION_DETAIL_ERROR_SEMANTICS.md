# Admission Detail Error Semantics

이 문서는 전형 상세 route의 **404 vs runtime/application failure** 경계를 정의한다.

문서 안의 문장은 다음 세 종류로 구분한다.

- **CURRENT FACT** — 현재 schema, loader, page, installed Next API가 실제로 지원하는 내용
- **DESIGN DECISION** — 이번 error-semantics에서 추천하는 선택
- **TO PROVE** — 구현 PR의 production HTTP/HTML로만 확정할 내용

추측을 CURRENT FACT처럼 쓰지 않는다.
웹 예시나 다른 Next 버전의 API 이름을 installed truth로 쓰지 않는다.

이번 작업은 **설계만**이다. production code / UI / repository / migration을 구현하지 않는다.


# 1. Purpose

전형 상세 route

`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`

에서 다음을 분리한다.

| 사용자에게 의미하는 것 | HTTP 목표 |
| --- | --- |
| 그런 전형/대학/학년도 identity가 없음 | **404** |
| 서버가 데이터를 불러오거나 조립하지 못함 | **5xx, 우선 500** |

목표는 편리한 fallback이 아니라 **상태 코드가 사실을 거짓말하지 않는 것**이다.

현재 page-level broad catch는 loader throw를 generic JSX로 바꾸므로
application failure가 HTTP 200처럼 보일 수 있다. 그 경로를 제거한다.

이 UI는 지원 자격 판정이 아니다.
오류 화면이 “지원 불가”를 의미하지 않는다.


# 2. Current Problem

## 2.1 Current page catch (CURRENT FACT)

`app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/page.tsx`:

1. malformed `academicYear` → `notFound()`
2. `getAdmissionProgramDetailReadModel(...)` 를 `try/catch`
3. catch → `console.error("Failed to load admission program detail", error)`
4. catch → `<LoadError />` JSX return
5. loader `null` → `notFound()`

`LoadError` copy:

```
전형 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
```

## 2.2 Why this is wrong (CURRENT FACT + DESIGN)

`AdmissionsQueryError` (`QUERY_FAILED`)와
`AdmissionsIntegrityError` (`INTEGRITY_VIOLATION`)는
loader가 **throw**한다. route miss는 **`null`**이다.

broad catch는 throw를 successful Server Component render로 바꾼다.
Next error boundary로 bubble하지 않는다.

결과적으로:

- application/server failure가 HTTP **200**일 수 있다
- 사용자에게는 정상 페이지 골격 + generic 문장만 보인다
- 404와 서버 실패가 같은 “안 됨”으로 섞일 수 있다
  (현재는 404가 `notFound()`라서 분리는 되어 있으나,
   failure 쪽이 200으로 내려앉는다)

`CitationDisclosure` missing-source throw는 loader `try/catch` **밖** render에서 난다.
그 경로는 이미 boundary로 bubble한다.
문제는 **loader throw가 catch로 삼켜지는 것**이다.


# 3. Current Framework Facts

## 3.1 Installed Next (CURRENT FACT)

| | |
| --- | --- |
| `package.json` / lock / `node_modules/next/package.json` | **16.3.2** |
| `export const dynamic` | page에 `"force-dynamic"` |
| `loading.tsx` | **없음** (app 전체) |
| `error.tsx` | **없음** (app 전체) |
| `not-found.tsx` | **없음** (app 전체) |
| `global-error.tsx` | **없음** |
| `Suspense` in admission detail page | **없음** |

Route tree (layouts는 root만 있음):

```
app/layout.tsx
app/page.tsx
app/universities/page.tsx
app/universities/[slug]/page.tsx
app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/page.tsx
```

leaf admission-detail 위에 universities layout은 없다.
`error.tsx`를 leaf에 두면 `/universities` list/detail을 같은 fallback으로 묶지 않는다.

## 3.2 Installed error boundary API (CURRENT FACT)

`next/error` re-export:

```
ErrorInfo = {
  error: unknown
  reset: () => void
  retry: () => void
}
```

출처: `node_modules/next/dist/client/components/error-boundary.d.ts`

bundled docs (`node_modules/next/dist/docs/.../error.md`):

| version | API |
| --- | --- |
| 16.2.0 | `unstable_retry` added |
| **16.3.0** | **`retry` became stable** |
| 16.3.2 (installed) | `ErrorInfo.retry` 존재. **`unstable_retry`는 ErrorInfo type에 없음** |

`retry()`: error boundary children을 **re-fetch + re-render**.
`reset()`: error state를 지우고 children을 **re-fetch 없이** 다시 그린다.

docs: loader/RSC 재요청이 필요하면 **대부분의 경우 `retry()`를 쓰고 `reset()`은 쓰지 않는다.**

`error.tsx`는 Client Component여야 한다 (`'use client'`).

`catchError` (`next/error`)는 component-level client API다.
이번 leaf `error.tsx`의 대체재가 아니다. **첫 PR에서 사용하지 않는다.**

## 3.3 Production error privacy (CURRENT FACT — installed docs)

bundled `error.md`:

- development: original `Error.message`가 client로 serialize될 수 있다
- **production: Server Component error는 generic message + identifier**
  (민감 정보 유출 방지)
- `error.digest`: 자동 생성된 hash. server-side log와 대조하는 용도

따라서 production `error.tsx`가
`instanceof AdmissionsIntegrityError` 또는 `error.code`
로 QUERY_FAILED vs INTEGRITY_VIOLATION을
**신뢰성 있게 구분한다고 가정하지 않는다.**

## 3.4 Loader outcomes (CURRENT FACT)

`getAdmissionProgramDetailReadModel(slug, year, admissionSlug)`:

| outcome | meaning |
| --- | --- |
| `null` | route identity miss (`getAdmissionProgramDetail` miss) |
| throw `AdmissionsQueryError` `QUERY_FAILED` | PostgREST/network/query 실패 (`throwIfQueryError`) |
| throw `AdmissionsQueryError` `INVALID_ARGUMENT` | loader 입력 검증 실패 (empty slug, non-integer year 등). page는 year를 먼저 parse하므로 정상 page path에서는 드묾 |
| throw `AdmissionsIntegrityError` `INTEGRITY_VIOLATION` | query는 성공했으나 graph invariant 위반 |
| return DTO | 렌더 가능. empty arrays는 정상 |

## 3.5 CitationDisclosure (CURRENT FACT)

missing `sourcesById[citation.source_document_id]` → `throw new Error(...)`.
silent fallback 없음.

unsafe URL → 링크 생략 (route fatal 아님).
invalid `last_checked_at` → metadata 생략 (route fatal 아님).
`citations.length === 0` → `현재 연결된 근거 없음` (error 아님).


# 4. Error Taxonomy

| | Case | CURRENT FACT trigger | DESIGN HTTP |
| --- | --- | --- | --- |
| **A** | malformed `academicYear` (`not-a-year`, `2027abc`, `0`, negative) | page `parseAcademicYearParam` → `notFound()` | **404** |
| **B** | 구문상 유효한 identity이나 loader `null` | unknown university / year / admission slug | **404** |
| **C** | `AdmissionsQueryError` `QUERY_FAILED` | loader throw | **runtime failure, 404 아님**, target **500** |
| **D** | `AdmissionsIntegrityError` `INTEGRITY_VIOLATION` | loader throw, fail closed | **runtime failure, 404 아님**, target **500** |
| **E** | unexpected Server Component / presentation throw | 예: CitationDisclosure missing source | **runtime failure**, target **500** |
| **F** | valid empty data | `sections=[]` / `schedules=[]` / `citations=[]` | **200**, error 아님 |

`INVALID_ARGUMENT`가 page path에서 throw되면 **C와 같이 runtime failure**로 취급한다.
malformed year를 loader에 넘기지 않고 `notFound()` 하는 현재 page 규칙은 유지한다.


# 5. 404 Semantics

**DESIGN DECISION:** `notFound()`는 오직:

1. invalid route parameter (현재: academicYear parse 실패)
2. loader result `=== null`

에만 사용한다.

사용 금지:

- `QUERY_FAILED`
- `INTEGRITY_VIOLATION`
- unexpected render throw
- empty sections/schedules/citations

server failure를 404로 숨기지 않는다.

error boundary 추가 후에도 기존 negative routes는 404여야 한다:

- wrong university
- `2028` (없는 학년도)
- `not-a-year`
- `2027abc`
- wrong admission slug

`notFound()`가 generic `error.tsx` fallback으로 바뀌면 **실패**다.


# 6. Runtime Failure Semantics

**DESIGN DECISION:** C/D/E는 동일 user-facing fallback.

구분하지 않는 이유:

- production Server → Client error는 sanitize된다
- Client boundary에서 internal `code`를 신뢰하지 않는다
- 사용자에게 taxonomy를 보여줄 이유가 없다

INTEGRITY_VIOLATION은 retry해도 반복될 수 있다.
그래도 Client가 종류를 모르면 **generic retry 하나**를 둔다.

부분 graph 렌더 금지. fail closed.


# 7. Error Boundary Placement

**DESIGN DECISION:**

```
app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/error.tsx
```

leaf segment.

이유:

- admission detail failure만 격리
- `/universities` list, university detail을 같은 fallback으로 묶지 않음
- 이 leaf에는 nested child route가 없음. boundary는 이 `page.tsx` render를 감싼다
- 같은 segment의 layout은 없음. root `app/layout.tsx`는 유지된다

`app/error.tsx` / `app/universities/error.tsx` / `app/global-error.tsx`는
**이번 범위 밖 (DEFERRED).**

Next nearest-boundary: throw한 Server Component의 가장 가까운 `error.tsx`.
leaf에 두면 그 page의 loader/render throw가 이 파일로 온다.


# 8. Production Error Privacy

**DESIGN DECISION:** production error UI에 다음을 출력하지 않는다.

- Supabase / PostgREST message
- SQL / table names
- UUID
- stack
- `QUERY_FAILED` / `INTEGRITY_VIOLATION` / `INVALID_ARGUMENT` 문자열
- injected test marker (forced-failure proof 포함)
- `error.message` 그대로 (Server Component production message도
  support UI가 아니면 보여 주지 않는다)

`error.digest`도 첫 UI에서 사용자에게 표시하지 않는다.


# 9. Retry / Recovery

## 9.1 API (DESIGN DECISION, based on CURRENT FACT)

loader/RSC 재요청이 필요하므로 **`retry()`** 를 쓴다.
`reset()`은 쓰지 않는다.
`unstable_retry`는 16.3.2 ErrorInfo에 없으므로 쓰지 않는다.

conceptual `error.tsx`:

```
"use client"

export default function AdmissionDetailError({
  error,
  retry,
}: {
  error: Error & { digest?: string }
  retry: () => void
}) {
  // do not render error.message / digest
  // do not instanceof Admissions*Error
  return ...
}
```

`retry` wiring은 **compile/build로 확인**한다. 실제 클릭 복구는
forced failure가 일시적일 때만 의미 있다. INTEGRITY_VIOLATION은
retry가 같은 실패를 반복할 수 있다. 그래도 버튼은 제공한다.
성공 보장을 문구에 쓰지 않는다.

## 9.2 UX copy (DESIGN DECISION)

heading:

`전형 정보를 불러오지 못했습니다.`

description:

`일시적인 문제일 수 있습니다. 잠시 후 다시 시도해 주세요.`

button:

`다시 시도` → `retry()`

금지:

- 데이터베이스 오류
- Supabase 오류
- 무결성 오류
- QUERY_FAILED / INTEGRITY_VIOLATION
- 지원 자격 데이터 오류
- 다시 시도하면 반드시 성공합니다

## 9.3 Navigation (DESIGN DECISION)

`대학 목록으로` → `<Link href="/universities">`

첫 PR에서 `useParams()`로 부모 `/universities/${slug}` 를 조립하지 않는다.
Client routing 복잡도를 늘리지 않는다.


# 10. Logging / Digest

**CURRENT FACT:** uncaught Server Component error는 Next server runtime이
서버 로그에 남긴다. 이 전제를 구현 PR에서 관찰한다 (**TO PROVE**가 아니라
framework 문서/관행. 로그 포맷은 측정 시 기록).

**DESIGN DECISION:** `error.tsx`에 `useEffect(() => console.error(error))`를
**필수로 두지 않는다.**

이유:

- production client `error`는 sanitize될 수 있다
- server log와 browser console이 중복될 수 있다
- 민감 메시지가 development에서 client로 새는 경로를 늘린다

external monitoring (Sentry 등): **DEFERRED**.

`digest` 사용자 표시: **DEFERRED**. 첫 PR에서 렌더하지 않는다.


# 11. Partial-Data Safety

**DESIGN DECISION:** runtime failure 시 다음을 남기지 않는다.

- university display name
- program name / year
- sections / schedules
- citations / provenance disclosure
- `연결된 출처 N건`

integrity violation에서 부분 facts를 보여주는 것은
깨진 graph를 정상인 척하는 것이다.

empty arrays (taxonomy F)는 부분 실패가 아니다. 정상 200.


# 12. HTTP Status Contract

| | target | proof status |
| --- | --- | --- |
| valid KU identity + loader success | **200** | already PROVEN on main; regression **TO PROVE** after change |
| taxonomy A/B | **404** | already PROVEN; regression **TO PROVE** |
| taxonomy C/D/E | **500** 우선 | **TO PROVE**. `error.tsx` 추가 = 자동 500이 아님 |

**DESIGN DECISION:** 구현 PR은 production `next start`에서
forced failure의 **실제 HTTP status를 측정**한다.

측정 결과가 200이면 성공으로 합리화하지 않는다.
그때는 **B. status semantics requires redesign**.

streaming caveat (**CURRENT FACT + TO PROVE**):

- 현재 leaf에 `loading.tsx` / `Suspense`가 없다
- headers가 이미 commit된 뒤 throw하면 status가 200으로 남을 수 있다
- 그래서 문서만으로 500을 PROVEN 처리하지 않는다


# 13. Runtime Proof Strategy

## 13.1 Forbidden (DESIGN DECISION)

- hosted DB mutation
- RLS mutation
- `service_role`
- committed test backdoor
- query-param forced-error hook
- permanent env forced-error hook

## 13.2 Required: uncommitted deterministic throw (DESIGN DECISION)

구현 PR에서:

1. page broad catch **제거** + leaf `error.tsx` 추가
2. **uncommitted** temporary throw를 loader 전 또는 loader 직후 render path에 삽입
   (deterministic, 특정 요청에만 한정 가능하면 그 편이 낫다.
    최소: KU detail GET이 항상 throw하도록 잠시 패치)
3. `npm run build` && `next start`
4. `GET` KU detail
   - **실제 status code 기록**
   - fallback HTML: generic copy 존재
   - university/program/sections/schedules/citations **없음**
   - raw throw marker / stack / table names **없음**
5. patch **완전 revert**
6. final lint / integrity / hosted / build / 정상 200 / 404 regression 재실행

final committed diff에 test injection **0**.

target status: **500**.
다른 5xx가 나오면 기록하고, 200이면 redesign.

## 13.3 CitationDisclosure throw (DESIGN DECISION)

missing-source throw는 같은 leaf `error.tsx`로 bubble해야 한다.

첫 implementation PR에서 **loader-path forced failure는 필수**.
별도 child-only forced-error runtime은 비용 대비 **optional**.
코드 리뷰로 “catch가 없으므로 throw가 boundary로 간다”를 확인하고,
child 전용 HTTP 측정은 필수가 아니다.


# 14. Accessibility / UX

**DESIGN DECISION:** fallback 최소 구조:

```
<main>
  <h1>전형 정보를 불러오지 못했습니다.</h1>
  <p>일시적인 문제일 수 있습니다. 잠시 후 다시 시도해 주세요.</p>
  <button type="button" onClick={() => retry()}>다시 시도</button>
  <Link href="/universities">대학 목록으로</Link>
</main>
```

- semantic heading
- 색만으로 error 전달 금지
- retry는 실제 `<button>` (비interactive status처럼 보이지 않음)
- 링크 텍스트는 `대학 목록으로` (`여기` / `클릭` 금지)

기존 page의 `LoadError`는 catch 제거와 함께 **삭제**한다.
duplicate generic JSX를 page에 남기지 않는다.


# 15. Implementation Scope

## 15.1 Broad catch (DESIGN DECISION)

**REMOVE** page-level `try/catch` around the loader.

이유:

- repository/integrity exception을 정상 JSX로 바꾸지 않음
- nearest Next error boundary로 bubble
- partial facts 렌더 방지
- framework-native semantics 유지

`console.error` in page catch도 함께 제거한다.
server logging은 uncaught path에 맡긴다.

## 15.2 Proposed files (DESIGN DECISION)

향후 code PR:

1. `app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/page.tsx`
   — catch/`LoadError` 제거. `notFound()` 유지. provenance UI 변경 없음.
2. `app/universities/[slug]/admissions/[academicYear]/[admissionSlug]/error.tsx`
   — Client Component. generic copy + `retry` + `/universities` link.

원칙:

- `lib/*` 0
- repository 0
- DB 0
- package 0
- `CitationDisclosure.tsx` 0
- `app/global-error.tsx` 0
- university detail의 기존 catch는 **이번 PR에서 건드리지 않음** (별도 route)

## 15.3 Client Component scope (DESIGN DECISION)

| file | |
| --- | --- |
| `error.tsx` | Client (`'use client'`). framework requirement |
| `page.tsx` | Server 유지 |
| `CitationDisclosure.tsx` | Server 유지 |

Client JS 확대는 error fallback **하나**로 제한.

## 15.4 Provenance contract unchanged (DESIGN DECISION)

error-semantics PR은 provenance UI를 재설계하지 않는다.

- missing source → throw (fail closed)
- unsafe URL → link omit, not fatal
- invalid `last_checked_at` → omit metadata, not fatal
- zero citations → `현재 연결된 근거 없음`


# 16. Acceptance Criteria

구현 PR:

**NORMAL**

- valid KU route → **200**
- sections 17 / schedules 15
- section citations 24 / schedule citations 30 / total 54
- linked ProgramSources 6
- provenance wording 유지 (`근거 N건 보기`, `연결된 출처 6건`)

**NOT FOUND**

- malformed year → **404**
- missing university → **404**
- missing program/slug → **404**

**FORCED FAILURE** (uncommitted throw, then revert)

- generic error fallback rendered
- partial facts absent
- raw injected marker absent from user UI
- **actual HTTP status measured**
- target **500**
- if 200: do not merge as success

**RECOVERY**

- `retry` prop compiles under Next 16.3.2
- button calls `retry`, not `reset` / `unstable_retry`

**SECURITY**

- raw internal error absent from production UI
- credentials 0
- write 0
- service_role 0
- new dependencies 0
- committed test hook 0

## Proof wording (after implementation measurement)

구현 전 (지금):

```
Admission-detail error HTTP semantics:
DESIGNED, NOT YET PROVEN
```

구현 후 forced failure가 **500**이면:

```
Admission-detail runtime failure HTTP semantics:
PROVEN (500)

404 regression:
PROVEN

normal route:
PROVEN (200)
```

실제 500 측정 전에는 failure HTTP를 PROVEN이라고 쓰지 않는다.

Zero-citation empty state는 이번 계약의 대상이 아니다.
기존: IMPLEMENTED, NOT EXERCISED BY CURRENT KU HOSTED DATA.


# 17. Deferred Decisions

- `app/global-error.tsx` / site-wide error policy
- university list/detail broad catch 정리
- Sentry / external monitoring
- support reference (`digest`) UI
- 503 vs 500 distinction
- automatic retry / backoff
- custom branded outage page
- `catchError()` component-level boundaries
- other routes
- RequiredDocument UI
- CitationDisclosure helper unit tests
- zero-citation hosted fixture


# Appendix. Mapping to existing docs

`docs/ADMISSION_DETAIL_READ_MODEL.md` §10:

- miss → `null` → `notFound()` 유지
- `QUERY_FAILED` / `INTEGRITY_VIOLATION` → 빈 데이터 위장 금지 유지
- 호출부 “실패 메시지”는 이번 계약에서 **error.tsx generic fallback + 5xx target**으로 구체화한다
  (page catch + HTTP 200 가능 경로는 폐기)

`docs/PROVENANCE_UI_CONTRACT.md`:

- `error.tsx` / loader-throw 5xx는 그 문서에서 DEFERRED였다
- 이 문서가 그 follow-up의 **계약**이다. 구현은 후속 code PR.
)
