# KU 2027 ROW MAP

문서 목적: 고려대학교 서울캠퍼스 2027학년도 **재외국민(정원외2%)전형**에 대해, 실제 현재 schema(`supabase/migrations/20260825155343_initial_schema.sql`)에 넣을 **planned DB row**를 row-by-row로 설계한다.

이 문서는 conceptual model이 아니다. 존재하지 않는 table/column을 있다고 가정하지 않는다. `EligibilityRule` table은 현재 initial schema에 없으므로 만들지 않는다. SQL / UUID / insert는 작성하지 않는다.

문서용 logical ID(`KU27-*`)는 DB UUID가 아니다.

`verified_at` / `source_documents.last_checked_at`의 시각은 추정하지 않는다. `last_checked_at`은 schema상 NOT NULL이므로 SQL 단계에서 실제 재확인 timestamptz를 넣는다. ROW_MAP 값: **TBD at final pre-import verification**.

**Readiness:** A. Ready for KU 2027 data migration draft (§24).

---

## Planned row count snapshot

| DB table | planned rows |
|---|---:|
| universities | 1 |
| admission_categories | 1 |
| source_documents | 7 |
| admission_programs | 1 |
| admission_program_sources | 6 |
| admission_sections | 17 |
| admission_schedules | 15 |
| required_documents | 42 |
| document_submissions | 84 |
| required_document_choice_groups | 1 |
| required_document_choice_group_items | 2 |
| source_citations | 33 |
| admission_section_citations | 24 |
| required_document_citations | 56 |
| document_submission_citations | 90 |
| admission_schedule_citations | 28 |

상세는 §22. Join 합계 24+56+90+28 = **198**.
Static audit: §25. RequiredDocument **42** / DocumentSubmission **84** 유지.

---

## 1. Scope

| 항목 | 값 | 근거 |
|---|---|---|
| University | 고려대학교 | S01 cover, S01 p21 |
| Campus | 서울캠퍼스 (`universities.campus_name`) | S01 cover. 세종캠퍼스와 혼동하지 않음. Campus 별도 table 없음 |
| Academic year | 2027 | S01 cover |
| Target AdmissionProgram | 재외국민(정원외2%)전형 | S01 cover / p3 재외국민 열 |
| 전교육과정해외이수자(전기) | target program row 없음 | 공통 규정이 재외국민에도 적용될 때만 section/document에 사용 |
| 북한이탈주민전형 | target program row 없음 | S01 p16–17 서류 열은 load하지 않음 |
| EligibilityRule | **0 rows** | table 없음 |
| Current facts | S01 only | S06에서 current fact를 가져오지 않음 |

First-load 가정: 기존 DB에 동일 university/program row가 없다. SQL 단계는 unique conflict check가 필요하다.

이번 작성에서 공식 source를 다시 열었다.

- S01 PDF `attach/202606/1781850206372_0.pdf` (21p)
- S03 HTML `BoardViewData` BBS_SEQ=1799
- S04 HTML `BoardViewData` BBS_SEQ=1803 + PDF FileDown FILE_SEQ=2 (3p)
- S05 HTML `BoardViewData` BBS_SEQ=1805 + PDF FileDown FILE_SEQ=2 (7p)
- S02·S06는 inventory URL/해시와 역할만 재확인 (S06 current fact 미사용)

S10 FAQ는 사용하지 않는다.

---

## 2. Source Baseline

Inventory `docs/data/ku/2027/SOURCE_INVENTORY.md`의 official sources만 사용한다.

| inventory source_id | role | current-fact 사용 |
|---|---|---|
| KU2027-S01 | PRIMARY current June guide PDF | yes |
| KU2027-S02 | SUPPLEMENTAL 제출서류 양식 게시 | yes (소정 양식 evidence) |
| KU2027-S03 | SUPPLEMENTAL 원서접수 안내 HTML | yes (같은 logical schedule의 추가 citation) |
| KU2027-S04 | SUPPLEMENTAL 1단계/면접 안내 | yes (면접 입실·장소 보완; 면접 schedule 복제 금지) |
| KU2027-S05 | SUPPLEMENTAL 최종합격 안내 | yes, **HTML과 PDF를 별도 SourceDocument** |
| KU2027-S06 | HISTORICAL_REVISION May PDF | historical SourceDocument only |
| KU2027-S07–S09 | REFERENCE_ONLY | DO_NOT_LOAD |
| KU2027-S10 | FAQ NEEDS_REVIEW | DO_NOT_LOAD |

S01 canonical file: `https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf`

S06 historical file: `https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf`

---

## 3. SourceDocument Load Decisions

아래 label은 문서용이다. DB enum이 아니다.

| inventory | artifact | decision | planned SourceDocument | current `admission_program_sources` |
|---|---|---|---|---|
| S01 | June PDF 21p | LOAD_CURRENT | KU27-SRC02 | yes |
| S06 | May PDF 21p | LOAD_HISTORICAL | KU27-SRC01 | **no** |
| S02 | 양식 게시 HTML (ZIP은 첨부 access) | LOAD_CURRENT | KU27-SRC03 | yes |
| S02 ZIP members / XLSX | — | DO_NOT_LOAD as SourceDocument | — | — |
| S03 | 원서접수 HTML | LOAD_CURRENT | KU27-SRC04 | yes |
| S04 | 면접 PDF 3p; HTML은 같은 notice의 access surface | LOAD_CURRENT (1 row) | KU27-SRC05 | yes |
| S05 HTML body | BoardViewData CONTENTS | LOAD_CURRENT | KU27-SRC06 | yes |
| S05 PDF 7p | FileDown FILE_SEQ=2 | LOAD_CURRENT | KU27-SRC07 | yes |
| S05 HWP | FILE_SEQ=1, PDF와 동일 안내로 inventory 확인 | DO_NOT_LOAD as third row | — | — |
| S07–S09 | — | DO_NOT_LOAD | — | — |
| S10 | FAQ | DO_NOT_LOAD | — | — |

### 3.1 S05 HTML vs PDF (필수 판단)

**결정: B. S05 HTML SourceDocument + S05 PDF SourceDocument 별도 row.**

이번 작업에서 두 artifact를 다시 확인했다. 장문 직접 인용 없이 의미만 적는다.

| artifact | 확인 방법 | 졸업예정자 졸업증명서 기한 표현 |
|---|---|---|
| S01 모집요강 | PDF p4, p6 | 최종합격자 원본서류 마감 2027.02.10. 최종 제출서류는 원서 시 업로드한 모든 서류 + 졸업증명서 |
| S05 HTML | `BoardViewData` BBS_SEQ=1805 CONTENTS | 원본서류 기한 2027.2.10 **그리고** 졸업예정자 졸업증명서 기한을 **2027년 3월 입학 전**으로 따로 적음 |
| S05 PDF | FileDown FILE_SEQ=2, physical p4 표 | 졸업증명서 원본이 원본서류 표에 있고, 표의 기한 칸은 **~ 2027.2.10**. 예정자는 졸업증명서를 추가 제출하라고 적음. HTML의 「3월 입학 전」문구는 이 PDF 본문에서 확인되지 않음 |

판단 기준:

- 각각 독립적인 fact-bearing artifact인가? **예.** HTML 본문과 PDF 표가 같은 기한을 같은 말로 말하지 않는다.
- 각각 별도 URL로 citation 가능한가? **예.** HTML = BoardView BBS_SEQ=1805. PDF = FileDown FILE_SEQ=2.
- conflict provenance를 DB에서 구분해야 하는가? **예.**
- 현재 schema에 Source URL alias table이 없다. 한 SourceDocument로 합치면 `source_url`이 하나뿐이라 **어느 artifact가 무엇을 말했는지 손실**된다.

임의 split이 아니라 확인된 substantive difference에 따른 **SPLIT_REQUIRED → 두 LOAD_CURRENT row**.

S04는 HTML과 PDF가 면접 입실·우당교양관을 **보완적으로 같은 말**을 하므로 1개 SourceDocument로 둔다. citeable artifact는 page number가 있는 PDF.

### 3.2 S01 / S06 revision mapping

- KU27-SRC01 = S06 historical
- KU27-SRC02 = S01 current
- **DB field:** `KU27-SRC02.supersedes_source_document_id` → KU27-SRC01

**확정 (static audit 유지):** 이 mapping을 DB load 대상으로 확정한다. MD5 차이만으로 확정하지 않는다.

결정적 근거 (MD5가 아님):

- 같은 2027 특별전형(전기) 모집요강 계열의 **서로 다른 official files**.
- 입학처 게시 제목 `2027학년도 특별전형(전기) 모집요강(2026.06. 수정)` 이 June 파일을 현재 요강으로 가리킨다.
- 같은 게시 HTML의 2026.06. 수정사항(학부대학 미선발, 체육교육과 전교육만 선발)이 **June PDF p3과 일치**하고 **May PDF p3과 불일치**한다.
- 현재 모집요강(전기) navigation/첨부 FILE_SEQ=4가 June bytes와 일치한다.

MD5/`CreationDate` 차이는 「다른 파일」임을 뒷받침하는 보조 근거일 뿐이다. 대체 관계는 공식 수정 게시 + 수정사항–본문 대응으로 성립한다.

S06는 current `admission_program_sources`에 연결하지 않는다. current fact citation에도 쓰지 않는다.

---

## 4. Row ID Convention

| prefix | table |
|---|---|
| KU27-U | universities |
| KU27-CAT | admission_categories |
| KU27-SRC | source_documents |
| KU27-P | admission_programs |
| KU27-PS | admission_program_sources (문서용) |
| KU27-SEC | admission_sections |
| KU27-SCH | admission_schedules |
| KU27-DOC | required_documents |
| KU27-SUB | document_submissions |
| KU27-CG | required_document_choice_groups |
| KU27-CGI | required_document_choice_group_items |
| KU27-CIT | source_citations |
| KU27-SCJ | admission_section_citations |
| KU27-DCJ | required_document_citations |
| KU27-UCJ | document_submission_citations |
| KU27-HCJ | admission_schedule_citations |

문서용 metadata (DB column 아님): `source_id / artifact`, physical page, `printed_page_label`, evidence section/anchor, conflict status, row-map decision.

`information_type` / `verification_status` / `availability_status`는 **해당 table에 column이 있을 때만** DB field로 적는다.

Timezone (`admission_schedules.timezone`): 모든 15 schedule의 DB intended value = **`GMT+9`**.

| 구분 | 값 |
|---|---|
| source literal (S05 PDF p2) | `한국 시간(GMT+9)` |
| S01 printed timezone | 없음 (IANA/`Asia/Seoul`/`GMT+9` 문자열을 인쇄하지 않음) |
| DB column intended value | `GMT+9` |
| IANA equivalent (not stored) | `Asia/Seoul` |

`Asia/Seoul`은 official source quotation이 아니다. IANA가 필요할 때를 위한 정규화 대응값일 뿐이다.

DATA_MODEL / schema: `timezone`은 nullable `text`. CHECK 없음. IANA 강제 없음. 현재 application도 IANA를 요구하지 않는다.

따라서 DB에는 source literal에 가까운 **`GMT+9`** 를 넣고, `Asia/Seoul`을 공식 기재처럼 쓰지 않는다. S01 시계 시각에 `GMT+9`를 쓰는 것은 S05가 입학처 안내 일시를 GMT+9라고 한 문맥을 같은 입학처 일정에 적용한 것이며, S01 원문 인용이 아니다. 이유: §25.2.

---

## 5. University

**row_id:** KU27-U01  
**DB table:** `universities`

| DB column | intended value | notes |
|---|---|---|
| name_ko | 고려대학교 | S01 cover / p21 |
| name_en | Korea University | S01 p4 영문 주소 |
| campus_name | 서울캠퍼스 | S01 cover. 다른 캠퍼스 아님 |
| display_name | 고려대학교 서울캠퍼스 | `campus_name`을 display에 반영. official program name 아님 |
| slug | `korea-seoul` | **proposed** route id. SITE_MAP `/universities/[slug]`. official identity 아님 |
| official_website_url | `https://www.korea.ac.kr` | S01 p21 고려대학교 홈페이지 문맥 |
| admissions_office_url | `https://oku.korea.ac.kr/oku/index.do` | S01 p21 `https://oku.korea.ac.kr`. S07을 fact source로 load하지는 않음 |

SQL 단계: `slug` UNIQUE existing-row check.

conflict: none.

---

## 6. AdmissionCategory

**row_id:** KU27-CAT01  
**DB table:** `admission_categories`

내부 taxonomy. 고려대학교 official program name이 아니다. **「3년 특례」를 `official_program_name`으로 쓰지 않는다.**

| DB column | intended value |
|---|---|
| code | `three_year_special` **proposed** |
| label | `3년 특례 관련` **proposed internal label** |
| description | 해외 재학·체류 요건을 두는 재외국민(정원외) 계열을 묶는 내부 분류. 대학 공식 전형명이 아님. |

**SQL 단계 필수:** `code` UNIQUE. 기존 category가 있으면 이 row를 insert하지 말고 existing-row에 연결한다. first-load map은 기존 row가 없다고 가정한다.

---

## 7. SourceDocuments

`source_type`은 CHECK 없음. inventory 값을 따른다. `information_type` / `verification_status` column 없음.

공통: `university_id` = KU27-U01, `academic_year` = 2027, `last_checked_at` = TBD at final pre-import verification.

### KU27-SRC01 — S06 historical

| DB column | intended value |
|---|---|
| source_type | `admissions_guide` |
| title | 2027학년도 특별전형 모집요강 (May official PDF, historical) |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf` |
| published_at | NULL |
| document_version_label | May official PDF / previous revision of S01 |
| supersedes_source_document_id | NULL |
| notes | LOAD_HISTORICAL. current program_source 금지. current citation 금지. `published_at`은 이 파일의 공식 게시일이 inventory에서 확정되지 않음. PDF `/CreationDate`를 published_at으로 쓰지 않음. |

### KU27-SRC02 — S01 current

| DB column | intended value |
|---|---|
| source_type | `admissions_guide` |
| title | 2027학년도 특별전형 모집요강 (서울캠퍼스) (2026.06.10 배포용) |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf` |
| published_at | 2026-06-10 |
| document_version_label | `(2026.06.10)_배포용` / `2026.06. 수정` |
| supersedes_source_document_id | **KU27-SRC01** |
| notes | Access surfaces (alias table 없음): BoardView BBS_SEQ=1794; FileDown FILE_SEQ=4; MENU_ID=690. supersedes → SRC01. 확정 근거는 공식 수정 게시 + 수정사항이 June p3과 일치 (MD5 단독 아님). |

### KU27-SRC03 — S02 forms posting

| DB column | intended value |
|---|---|
| source_type | `submission_forms` |
| title | [서울캠퍼스] 2027학년도 특별전형(전기) 제출서류 양식 안내 |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=124&BOARD_SEQ=3&CONTENTS_NO=&MENU_ID=730&SITE_NO=2` |
| published_at | 2026-05-26 |
| document_version_label | BBS_SEQ=124 |
| supersedes_source_document_id | NULL |
| notes | MENU_ID=1750는 같은 posting access surface. ZIP FILE_SEQ=1 / XLSX FILE_SEQ=2는 첨부. ZIP 내부를 별도 SourceDocument로 쪼개지 않음. XLSX 미개봉. 양식 필드 내용 추정 금지. |

### KU27-SRC04 — S03 HTML

| DB column | intended value |
|---|---|
| source_type | `official_notice` |
| title | 2027학년도 특별전형(전기) 원서접수 안내 |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1799&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` |
| published_at | 2026-07-02 |
| notes | HTML only. 원서/서류 일정을 S01과 같은 logical event로 인용. 경쟁률 공시 시각은 지원 필수 event가 아니므로 schedule row를 만들지 않음. |

### KU27-SRC05 — S04 interview PDF

| DB column | intended value |
|---|---|
| source_type | `official_notice` |
| title | 2027학년도 특별전형 1단계 합격자 면접고사 안내 및 수험생 유의사항(배포용) |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1803&FILE_SEQ=2` |
| published_at | 2026-07-29 |
| document_version_label | `(배포용)` |
| notes | PDF 3p를 citeable artifact로 저장 (이번 작업에서 FILE_SEQ=2 PDF download 확인). HTML BoardView BBS_SEQ=1803은 같은 notice access surface. HTML과 PDF는 면접 일시·우당교양관을 보완적으로 말하며 conflict가 아니므로 split하지 않음. |

### KU27-SRC06 — S05 HTML

| DB column | intended value |
|---|---|
| source_type | `official_notice` |
| title | 2027학년도 특별전형(전기) 최종 합격자 발표 (HTML body) |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1805&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` |
| published_at | 2026-09-03 |
| notes | BoardViewData CONTENTS가 fact-bearing body. 졸업예정자 졸업증명서 「2027년 3월 입학 전」표현의 provenance. PDF와 합치지 않음. |

### KU27-SRC07 — S05 PDF

| DB column | intended value |
|---|---|
| source_type | `official_notice` |
| title | 2027학년도 특별전형 최종합격자 안내사항(배포용) (PDF) |
| issuing_organization | 고려대학교 서울캠퍼스 입학처 |
| source_url | `https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2` |
| published_at | 2026-09-03 |
| document_version_label | `(배포용)` |
| notes | 7 physical pages. FILE_SEQ=2 확인. HWP FILE_SEQ=1은 별도 row 없음. p2에 한국 시간(GMT+9) 명시. p4 표의 졸업증명서 기한 표현은 HTML과 다름. |

---

## 8. AdmissionProgram

**1개 target program만.**

**row_id:** KU27-P01  
**DB table:** `admission_programs`

| DB column | intended value |
|---|---|
| university_id | KU27-U01 |
| admission_category_id | KU27-CAT01 |
| academic_year | 2027 |
| official_program_name | `재외국민(정원외2%)전형` |
| display_name | `재외국민(정원외2%)전형` |
| admission_slug | `overseas-korean-2pct` **proposed** route id. SITE_MAP `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`. official semantic identity 아님 |
| information_type | `official_fact` |
| verification_status | `partially_verified` |
| verified_at | TBD at final pre-import verification |
| notes | 전교육·북한은 이 row가 아님. 졸업예정자 졸업증명서 기한은 child SUB82가 `needs_review`. program 전체를 unverified로 두지 않음. |

AdmissionProgram에 fact-level citation join은 **없다**. provenance는 `admission_program_sources`.

---

## 9. AdmissionProgramSources

S06(KU27-SRC01)는 **넣지 않는다.**

| row_id | admission_program_id | source_document_id | source_role | display_order | notes |
|---|---|---|---|---:|---|
| KU27-PS01 | KU27-P01 | KU27-SRC02 | `primary_guide` | 1 | S01 current |
| KU27-PS02 | KU27-P01 | KU27-SRC03 | `supporting_forms` | 2 | S02 소정 양식 |
| KU27-PS03 | KU27-P01 | KU27-SRC04 | `supporting_notice` | 3 | S03 |
| KU27-PS04 | KU27-P01 | KU27-SRC05 | `supporting_notice` | 4 | S04 |
| KU27-PS05 | KU27-P01 | KU27-SRC06 | `supporting_notice` | 5 | S05 HTML (conflict provenance) |
| KU27-PS06 | KU27-P01 | KU27-SRC07 | `supporting_notice` | 6 | S05 PDF (conflict provenance) |

`source_role`은 CHECK 없음. 위 값은 문서 제안이다.

ProgramSource audit: 6 artifact 모두 target program의 **current stored fact를 1개 이상** 뒷받침한다. LOAD만으로 넣은 것이 아님.

- SRC02: 자격·평가·일정·서류 등
- SRC03: 소정 양식 문서 (DOC01, 05, 08, 11–12, 16–19, 32–33)
- SRC04: 원서/업로드 운영, 우편 예외
- SRC05: 면접 입실·장소·편의제공
- SRC06: 합격 후 일정 + 졸업증명서 HTML 기한
- SRC07: 합격 후 일정·GMT+9 + 졸업증명서 PDF 표

S06는 historical only → program_sources 제외.

---

## 10. AdmissionSections

공통 DB: `admission_program_id` = KU27-P01, `information_type` = `official_fact`, `availability_status` = `available`, `verified_at` = TBD.  
`section_type` CHECK 없음. 같은 `section_type` 복수 허용.

`language_requirement` section을 「어학 요건 없음」으로 만들지 않는다 (`no inferred absence`). 선택 평가자료는 SEC14.

3년/학기/체류를 EligibilityRule이나 deterministic code로 변환하지 않는다.

| row_id | section_type | title | content (요지; SQL 시 공식 구조 보존) | applicability_text | verification_status | display_order | evidence |
|---|---|---|---|---|---|---:|---|
| KU27-SEC01 | eligibility | 지원자격 공통 (학력·학제·이수학기) | S01 p8–9 공통. 전교육·북한 전용 문장 제외 | 재외국민(정원외2%)에도 적용되는 공통 자격 | verified 후보 | 10 | CIT10, CIT11 |
| KU27-SEC02 | eligibility | 재외국민(정원외2%) 지원자격 개요 | p10 표: 중·고 3년, 체류 비율, 국외근무 1,095일 등 개요 | 재외국민(정원외2%)전형 | verified 후보 | 20 | CIT12 |
| KU27-SEC03 | eligibility | 국외 재학·체류·재직 기간 산정 | p10 상세 산정. rule 코딩 금지 | 재외국민(정원외2%)전형 | verified 후보 | 30 | CIT12 |
| KU27-SEC04 | other_conditions | 모집단위 및 모집인원 | 78명, 모집단위별 2명 이내, 인문 38 / 자연 38 / 의학 1 / 예능 1. 중복지원 허용. 체육교육과 재외국민 미선발. 학부대학 미선발. 단위 목록 전체를 임의 생성하지 않음 | 2027 서울캠퍼스 재외국민(정원외2%) | verified 후보 | 40 | CIT02 |
| KU27-SEC05 | evaluation | 전형요소 및 반영비율 | 1단계 서류 100% 3배수. 2단계 1단계 70% + 면접 30%. **p18 가. 만** | 재외국민(정원외2%)전형 | verified 후보 | 50 | CIT18 |
| KU27-SEC06 | evaluation | 서류평가 역량 | 학업 40 / 세계시민 30 / 계열 20 / 공동체 10. 전교육과 공유이나 재외국민에 적용 | 재외국민 서류평가 | verified 후보 | 60 | CIT19 |
| KU27-SEC07 | evaluation | 면접평가 | 인문·자연·의학 제시문 10+5분. 예능 서류기반. 장소 서울캠퍼스(요강). 건물·입실은 schedule | 재외국민 2단계 | verified 후보 | 70 | CIT33, CIT24 |
| KU27-SEC08 | caution | 원서접수 유의사항 | 접수 후 취소 불가, 6회 제한, 최종합격 시 수시·정시 지원 제한 등 p4. S03 24시간·Chrome/Edge·수험표는 같은 주제 추가 citation | 2027 특별전형 원서 (재외국민 포함) | verified 후보 | 80 | CIT04, CIT23 |
| KU27-SEC09 | caution | 등록·이중등록·최종원본 | p6. 최종 서류 = 업로드한 모든 서류 + 졸업증명서. **졸업예정자 기한 conflict를 이 row에서 단정하지 않음** | 재외국민(정원외2%)전형 | verified 후보 | 90 | CIT07, CIT31 |
| KU27-SEC10 | caution | 입학전형 공정성 및 윤리 | p7 공정성 조치 | 특별전형 (재외국민 포함) | verified 후보 | 100 | CIT08 |
| KU27-SEC11 | caution | 학교폭력 조치사항 | p7. 국내 고교 재학사실이 있는 자의 학교생활기록부 제출 | 국내 고교 재학사실이 있는 지원자 포함 | verified 후보 | 110 | CIT09 |
| KU27-SEC12 | caution | 제출서류 공통 안내 | p11: A4 PDF, 용량, 번역 공증, 미발급 고교 우편 2026.07.09 도착, 필수서류 미제출 불합격 | 재외국민 서류 제출 | verified 후보 | 120 | CIT13 |
| KU27-SEC13 | caution | 교내활동·공인성적 유의사항 | p15. predicted/best 제외. 제출 가능 ≠ 지원요건 | 해당 서류를 제출하는 경우 | verified 후보 | 130 | CIT17 |
| KU27-SEC14 | standardized_tests | 공인어학·표준화학력 (선택 평가자료) | TOEFL/HSK/JPT, AP/IB/SAT 등 요강 예시. 최대 5항목. 기관번호 ETS 8228, CB 5443, IBO 002366, ACT 2935는 리포팅 코드이지 최저점이 아님. 최소/권장/합격선 **생성 금지**. S10 사용 금지 | 해당자가 평가자료로 제출하는 경우. 미제출을 자격 미달로 해석하지 않음 | verified 후보 | 140 | CIT17 |
| KU27-SEC15 | notes | 전형료 | 예능 250,000원, 그 외 200,000원, 1단계 불합격 반환 30,000원 | 재외국민(정원외2%)전형 | verified 후보 | 150 | CIT20 |
| KU27-SEC16 | notes | 입학 관련 문의 | p21 서울캠퍼스 입학처 02-3290-5161~3, oku.korea.ac.kr | 재외국민 전형 문의 | verified 후보 | 160 | CIT21 |
| KU27-SEC17 | caution | 면접고사 수험생 유의사항 | S04 p2: 신분증, 블라인드, 휴대금지 물품, 대화 금지 등. 고사 운영 규정 | 1단계 합격 후 면접 응시자 | verified 후보 | 170 | CIT25 |

기숙사 비용·선발 안내는 AdmissionSection/Schedule first-load에 넣지 않는다 (SCHEMA_GAP-02).

---

## 11. AdmissionSchedules

원칙: 하나의 logical event = 1 row. S01과 S03이 같은 원서기간을 반복해도 schedule을 2개 만들지 않는다.

schema `admission_schedules_temporal_fields_check`:

- `date`: `start_at`/`end_at` NULL. `start_date` **또는** `end_date` NOT NULL. 마감-only는 `end_date`만 가능.
- `datetime`: `start_date`/`end_date` NULL. `start_at` **또는** `end_at` NOT NULL. 마감-only datetime은 `end_at`만 가능.

임의 midnight 금지. 날짜만 있으면 시간 추정 금지.

S04가 같은 면접에 입실 시작·건물을 추가하면 **면접 schedule을 복제하지 않고** SCH04를 보강한다. 개인 고사실 호수는 저장하지 않음 (SCHEMA_GAP-03).

공통: `admission_program_id` = KU27-P01, `timezone` = **`GMT+9`** (source literal / 입학처 시각 문맥. `Asia/Seoul`은 저장하지 않음. §4·§25.2), `verified_at` = TBD.

| row_id | event_name | temporal_precision | start / end | location_text | description | verification_status | display_order | citations |
|---|---|---|---|---|---|---|---:|---|
| KU27-SCH01 | 원서접수 | datetime | start_at 2026-07-06 10:00, end_at 2026-07-08 17:00 | 온라인 | S03: 기간 중 24시간, Chrome/Edge, 전형료 결제 포함 마감. 개인정보 수정신청은 같은 기간(S03)이며 별도 event로 복제하지 않고 여기에 적음 | verified 후보 | 10 | CIT03, CIT23 |
| KU27-SCH02 | 온라인 서식 입력 및 온라인 서류제출 | datetime | start_at 2026-07-06 10:00, end_at 2026-07-09 17:00 | 온라인 / 입학처 홈페이지 | S03는 서식 입력과 서류 업로드를 항으로 나누지만 요강은 한 기간. **한 logical window → 1 row**. S03 세부(교내활동확인서 등 서식 대상)는 description | verified 후보 | 20 | CIT03, CIT23 |
| KU27-SCH03 | 1단계 합격자 발표 및 고사장 발표 | datetime | start_at = end_at 2026-07-31 17:00 | 입학처 홈페이지 | 순간 발표. 시간을 추정한 것이 아니라 공식 17:00 | verified 후보 | 30 | CIT05, CIT24 |
| KU27-SCH04 | 면접고사 | datetime | start_at 2026-08-14 12:10, **end_at NULL** | 고려대학교 서울캠퍼스 우당교양관 | 요강: 12:30까지 입실 / 서울캠퍼스. S04: 12:10 시작 ~ 12:30 입실완료, 우당교양관. complementary. 면접 종료 시각은 공식 source에 없음 → 추정 금지 | verified 후보 | 40 | CIT05, CIT24 |
| KU27-SCH05 | 최초합격자 발표 | datetime | start_at = end_at 2026-09-04 17:00 | 입학처 홈페이지 | | verified 후보 | 50 | CIT05, CIT06 |
| KU27-SCH06 | 문서등록 | datetime | start_at 2026-12-21 10:00, end_at 2026-12-23 14:00 | 온라인 | S05도 동일 기간 재진술. 복제 row 없음 | verified 후보 | 60 | CIT06, CIT28, CIT29 |
| KU27-SCH07 | 1차 충원합격 발표 및 등록 | datetime | start_at 2026-12-23 21:00, end_at 2026-12-24 14:00 | 입학처 홈페이지 | S01 p5 1차 행. 발표와 등록마감을 한 충원 round로 봄 | verified 후보 | 70 | CIT06 |
| KU27-SCH08 | 2차 충원합격 발표 및 등록 | datetime | start_at 2026-12-24 21:00, end_at 2026-12-27 10:00 | 입학처 홈페이지 | S01 p5 2차 행 | verified 후보 | 80 | CIT06 |
| KU27-SCH09 | 3차 충원합격 발표 및 등록 | datetime | start_at 2026-12-27 13:00, end_at 2026-12-28 10:00 | 입학처 홈페이지 | S01 p5 3차 행 | verified 후보 | 90 | CIT06 |
| KU27-SCH10 | 등록포기 (문서등록 취소) | datetime | start_at NULL, end_at 2026-12-29 10:00 | 입학처 홈페이지 | 마감-only datetime. schema 허용. S05 p3도 `~ 2026.12.29 10:00` | verified 후보 | 100 | CIT06, CIT28 |
| KU27-SCH11 | 최종합격자 원본 서류 제출 | date | start_date NULL, end_date 2027-02-10 | 우편 | 요강 p4 「까지」. 도착/등기 조건은 description. **이 end_date를 졸업예정자 졸업증명서의 유일한 기한으로 단정하지 않음**. SUB82를 이 schedule에 연결하지 않음 (§25.1) | verified 후보 | 110 | CIT31 |
| KU27-SCH12 | 등록금 납부 | date | start_date 2027-02-15, end_date 2027-02-16 | NULL | S01 p5와 S05가 날짜를 말함. S05 HTML은 상세 일시 추후 공지 → **시간 추정 금지**. date precision | verified 후보 | 120 | CIT06, CIT28, CIT29 |
| KU27-SCH13 | 입학허가통지서 출력 | datetime | start_at 2026-09-04 17:00, end_at 2026-09-30 17:00 | 입학처 홈페이지 | S05: 합격자 발표 시 ~ 09.30 17:00. 시작은 최초합격 발표(SCH05)와 같은 공식 시점. 시작 시각을 임의 midnight으로 두지 않음 | verified 후보 | 130 | CIT28, CIT29 |
| KU27-SCH14 | 면접 편의제공 신청 | date | start_date NULL, end_date 2026-08-11 | 이메일 (S04) | S04: 2026.08.11까지. 요강 p6는 「면접 2일 전」generic. complementary cycle deadline. 요강을 버려 S04만 쓴 것이 아니라 description에 둘 다 보존 | verified 후보 | 140 | CIT25, CIT32, CIT26 |
| KU27-SCH15 | 신분증 미소지자 본인확인 | datetime | start_at 2026-08-18 14:00, end_at 2026-08-18 17:00 | 입학처 방문 | S04 p2. **해당자** 조건부 event. 전원 면접이 아니므로 SCH04와 합치지 않음 | verified 후보 | 150 | CIT25 |

연도: 요강 표의 07–12월은 문맥상 2026년, 02월 원본/등록금은 2027년 (p4가 원본을 2027.02.10으로 명시).

저장하지 않음: 기숙사 선발 2027.01.08 14:00(예정), 오리엔테이션, 학번, 수강신청, 입학식, 학생증, 경쟁률 공시. 입학 전형 핵심 event가 아니거나 지원 필수 행위가 아님 (SCHEMA_GAP-02, SCHEMA_GAP-12).

---

## 12. RequiredDocuments

「무엇을 제출하는가」. phase를 이 table에 넣지 않는다.  
`information_type` column **없음**.  
`requirement_status` CHECK 없음. 요강 표기: `필수` / `선택` / `해당자 필수`.

공통: `admission_program_id` = KU27-P01, `verified_at` = TBD, `verification_status` = `verified` 후보.  
**졸업증명서 conflict 때문에 문서 전체를 unverified로 만들지 않음.** DOC04 identity는 충돌하지 않음. conflict 최소 단위는 SUB82.

재외국민 열만. 북한 p16–17 / 전교육-only 열 제외.

`document_subject_text`는 공식 대상만. 지원자·부·모가 요강에 명시된 경우만 분리.

| row_id | name | requirement_status | condition | document_subject_text | display_order | evidence |
|---|---|---|---|---|---:|---|
| KU27-DOC01 | 학력조회 동의서 | 필수 | | 지원자 | 10 | CIT14, CIT22 |
| KU27-DOC02 | 초등학교 성적‧재학증명서 | 필수 | 국외 초등은 성적·재학 중 하나만 제출해도 되나 이수학년·학기·재학기간 명시. **한 표 행 → ChoiceGroup 아님** | 지원자 | 20 | CIT14 |
| KU27-DOC03 | 중학교 성적‧재학증명서 | 필수 | | 지원자 | 30 | CIT14 |
| KU27-DOC04 | 고등학교 성적‧재학‧졸업(예정)증명서 | 필수 | 최종 원본에 졸업증명서 포함(p6). 예정자 추가 졸업증명서 기한은 SUB82 | 지원자 | 40 | CIT14 |
| KU27-DOC05 | 학교과정 특이사항 증빙서류 | 해당자 필수 | 성적·재학기록 폐기, 학기 조정, 월반, 조기졸업, 국가재난 결손 등 요강 열거 | 지원자 | 50 | CIT14, CIT22 |
| KU27-DOC06 | 국외학교 학사일정표 (School Calendar) | 필수 | | 재학한 국외학교 | 60 | CIT14 |
| KU27-DOC07 | 국외고교 School Profile | 선택 | | 고등학교 | 70 | CIT14 |
| KU27-DOC08 | 교내활동확인서 | 선택 | | 지원자 | 80 | CIT14, CIT17, CIT22 |
| KU27-DOC09 | 교내활동증빙서류 | 해당자 필수 | 교내활동확인서 제출자 | 지원자 | 90 | CIT14, CIT17 |
| KU27-DOC10 | 공인성적표 | 해당자 필수 | 원서에 공인성적을 입력한 경우. 미입력을 자격 미달로 해석하지 않음 | 지원자 | 100 | CIT14, CIT17 |
| KU27-DOC11 | 포트폴리오 서약서 | 해당자 필수 | 디자인조형학부 | 지원자 | 110 | CIT15, CIT22 |
| KU27-DOC12 | 포트폴리오 | 해당자 필수 | 디자인조형학부. 요강: 서약서와 일괄 스캔 업로드 | 지원자 | 120 | CIT15, CIT22 |
| KU27-DOC13 | 여권 사본 | 필수 | 분실 시 여권 발급기록증명서 (대체 조건을 description에 보존. 열린 「등」이 아니나 조건부여체이므로 별도 자유 ChoiceGroup은 만들지 않음) | 지원자 | 130 | CIT15 |
| KU27-DOC14 | 여권 사본 | 필수 | 위와 동일 | 부 | 140 | CIT15 |
| KU27-DOC15 | 여권 사본 | 필수 | 위와 동일 | 모 | 150 | CIT15 |
| KU27-DOC16 | 사실증명발급·열람 신청서 및 위임장 | 필수 | 서명은 여권과 동일 | 지원자 | 160 | CIT15, CIT22 |
| KU27-DOC17 | 사실증명발급·열람 신청서 및 위임장 | 필수 | | 부 | 170 | CIT15, CIT22 |
| KU27-DOC18 | 사실증명발급·열람 신청서 및 위임장 | 필수 | | 모 | 180 | CIT15, CIT22 |
| KU27-DOC19 | 개인정보 변경확인요청서 | 해당자 필수 | 성명·생년월일 등이 서류와 다른 경우 | 지원자 | 190 | CIT15, CIT22 |
| KU27-DOC20 | 주민등록표초본 | 해당자 필수 | p11: 주민등록번호 또는 성명이 다른 지원자. DOC19와 함께 | 지원자 | 200 | CIT13 |
| KU27-DOC21 | 출입국사실증명서 | 필수 | 2026.07.01 이후 발급. 조회기간은 요강 표 | 지원자 | 210 | CIT15 |
| KU27-DOC22 | 출입국사실증명서 | 필수 | | 부 | 220 | CIT15 |
| KU27-DOC23 | 출입국사실증명서 | 필수 | | 모 | 230 | CIT15 |
| KU27-DOC24 | 가족관계증명서 | 필수 | 2026.07.01 이후 발급, 지원자 본인 기준 | 지원자 | 240 | CIT15 |
| KU27-DOC25 | 기본증명서(상세) | 해당자 필수 | 부모 사망 | 사망한 부 또는 모 | 250 | CIT15 |
| KU27-DOC26 | 제적등본 | 해당자 필수 | 부모 사망 | 사망한 부 또는 모 | 260 | CIT15 |
| KU27-DOC27 | 기본증명서(상세) | 해당자 필수 | 부모 이혼/재혼 | 지원자 | 270 | CIT15 |
| KU27-DOC28 | 혼인관계증명서(상세) | 해당자 필수 | 부모 이혼/재혼 | 함께 체류 중인 부 또는 모 | 280 | CIT15 |
| KU27-DOC29 | 재외국민등록부 등본 | 필수 | 2026.07.01 이후. 불가·특이 시 비자 사본 등 대체는 description. 「등」열린 대체 → ChoiceGroup 아님 | 지원자 | 290 | CIT15 |
| KU27-DOC30 | 재외국민등록부 등본 | 필수 | | 부 | 300 | CIT15 |
| KU27-DOC31 | 재외국민등록부 등본 | 필수 | | 모 | 310 | CIT15 |
| KU27-DOC32 | 개인정보 수집 및 이용 동의서 | 필수 | 학부모 작성용 소정 양식 | 부 | 320 | CIT15, CIT22 |
| KU27-DOC33 | 개인정보 수집 및 이용 동의서 | 필수 | | 모 | 330 | CIT15, CIT22 |
| KU27-DOC34 | 경력증명서 또는 재직증명서 | 필수 | 국외파견 재직자 및 현지법인 취업자 표 행. 근무기간·국가명 | 해외근무 부모 (요강 재직 구분) | 340 | CIT16 |
| KU27-DOC35 | 해외직접투자신고서(허가서) 또는 해외지사설치인증서 | 해당자 필수 | 국외파견 중 상사 주재원. 한 표 셀의 또는 → 공식명을 그대로 한 document | 해당 재직 구분 | 350 | CIT16 |
| KU27-DOC36 | 법인 사업자등록증 또는 법인 등기부 등본 | 필수 | 현지법인 취업자. 표 셀 또는를 공식명으로 보존 | 해당 재직 구분 | 360 | CIT16 |
| KU27-DOC37 | 법인세 납부이력 | 필수 | 현지법인. 미발급 시 개인 소득세 납부 증명 대체는 description (조건부여체) | 해당 재직 구분 | 370 | CIT16 |
| KU27-DOC38 | 사업자등록증 또는 법인 등기부 등본 | 필수 | 현지 자영업자 | 해당 재직 구분 | 380 | CIT16 |
| KU27-DOC39 | 국외 세금납부 증명서 | 필수 | 현지 자영업자 | 해당 재직 구분 | 390 | CIT16 |
| KU27-DOC40 | 학교생활기록부 | 해당자 필수 | p7: 국내 고교 재학사실이 있는 자. 학력서류로 이미 제출한 경우와 중복될 수 있으나 요강이 학교폭력 확인용으로 별도 요구 | 지원자 | 400 | CIT09 |
| KU27-DOC41 | 출입국사실증명서 (졸업일 기준, 별도 요청) | 해당자 필수 | S05 PDF: 재외국민 졸업예정자 중 **별도 요청한 인원**. 조회기간 만 12세 생일~고등학교 졸업일. 일반 DOC21–23과 발급 기준이 다름 | 지원자·부·모 | 410 | CIT30 |
| KU27-DOC42 | 재직증명서 (고등학교 졸업일 기준, 별도 요청) | 해당자 필수 | S05 PDF: 별도 요청 인원. DOC34와 기준일 다름 | 재직자 | 420 | CIT30 |

DOC41/42의 지원자·부·모를 세 row로 더 쪼개지 않은 이유: S05 표가 「본인,부,모 출입국 1부」를 한 묶음 해당자 세트로 제시. 일반 원서 단계 DOC21–23은 요강이 대상자를 행 단위로 나눔.

재직 DOC34–39는 재직구분에 따른 **조건별 세트**이지 전체 택1이 아님. ChoiceGroup 없음.

---

## 13. DocumentSubmissions

「언제 / 어떤 방식 / 어떤 형태」. document를 복제하지 않는다.

복합 FK: `admission_program_id` = KU27-P01. `admission_schedule_id`가 있으면 같은 program의 schedule.

p11: 모든 제출서류는 A4 PDF로 스캔하여 **원서접수 시 업로드**.  
p6: 최종합격자 제출서류 = 원서 시 업로드한 **모든 서류** + 졸업증명서.

이 두 공통 규정이 **원서 단계 문서(DOC01–DOC40)** 에 적용된다. 해당자/선택 문서의 submission row는 「조건이 성립해 그 문서를 제출할 때의 방법」이지, 전원 제출을 뜻하지 않는다. 「선택 = 원본 불필요」로 바꾸지 않음.

DOC41–DOC42는 원서 업로드 대상이 아니다 (S05 별도 요청). Pattern A/B에 넣지 않음.

교내활동확인서(DOC08)는 원서 입력 후 출력·직인·PDF 업로드이므로 물리적 날인 서류다. 「온라인만 생성되어 원본이 없다」로 해석하지 않음. p15 미날인 시 최종 원본 날인본은 p6 패키지와 같은 Pattern B로 충분하다.

학사일정표 홈페이지 출력물도 업로드되면 p6 패키지에 들어간다. 「출력물이라 원본 불필요」로 추정하지 않음.

아포스티유/영사확인은 original `instructions` (방법/형태), 별도 document 아님.

공통: `verified_at` = TBD.

### 13.1 Pattern A — 원서 온라인 (40 rows)

KU27-SUB01 … KU27-SUB40  
각 `required_document_id` = DOC01 … DOC40  
`submission_phase` = `원서접수`  
`submission_method` = `온라인 업로드`  
`submission_format` = `PDF` (요강 A4 PDF)  
`admission_schedule_id` = SCH02  
`verification_status` = verified 후보  
`display_order` = 10, 20, … 400  
DOC10 `instructions`: 진위확인 수단 또는 2026.07.09까지 스코어리포팅 도착. 기관번호 ETS 8228 등. 별도 document 아님.  
DOC11+DOC12 `instructions`: 두 파일을 일괄 스캔 업로드.  
DOC13–15, 16–18, 21–23, 29–31 `instructions`: 지원자·부·모 순서 병합 PDF (요강).

### 13.2 Pattern B — 최종 원본 (40 rows)

KU27-SUB41 … KU27-SUB80  
각 `required_document_id` = DOC01 … DOC40  
`submission_phase` = `최종합격 후`  
`submission_method` = `우편`  
`submission_format` = `원본 또는 원본대조 사본`  
`admission_schedule_id` = SCH11  
`instructions` = 등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4  
`verification_status` = verified 후보  
`display_order` = 1010 … 1400  

이 40개는 **패키지 마감 2027.02.10 (S01)** 을 따른다. 졸업예정자 졸업증명서만의 다른 기한 표현은 SUB82.

### 13.3 Exceptions (4 rows)

| row_id | required_document_id | submission_phase | submission_method | submission_format | admission_schedule_id | verification_status | notes |
|---|---|---|---|---|---|---|---|
| KU27-SUB81 | DOC04 | 원서접수 (학력 미발급 고교) | 우편 | 고교 직접 송부 | SCH02와 같은 마감일 2026-07-09 도착. **schedule은 SCH02를 쓰지 않고** 우편 마감만 같음. datetime 17:00가 우편 도착에 적용된다고 단정하지 않음 → `admission_schedule_id` NULL, instructions에 2026.07.09 도착 | verified 후보 | CIT13, CIT23 |
| KU27-SUB82 | DOC04 | 최종합격 후 (졸업예정자 졸업증명서 추가) | 우편 | 원본 | **NULL** | **needs_review** | CIT31, CIT07, CIT27, CIT30. SCH11에 연결하면 2027.02.10을 조용히 채택하게 되므로 FK를 두지 않음. §18·§25.1 |
| KU27-SUB83 | DOC41 | 최종합격 후 (별도 요청) | 우편 | 원본 | SCH11 | verified 후보 | 해당자. 기한은 원본 패키지 표와 같은 칸. 졸업증명서 HTML 3월 문구와 묶지 않음 |
| KU27-SUB84 | DOC42 | 최종합격 후 (별도 요청) | 우편 | 원본 | SCH11 | verified 후보 | 해당자 |

SUB81을 SCH02에 묶지 않는 이유: SCH02는 온라인 17:00 datetime. 우편은 「도착분까지」 date. 같은 달력이라도 precision이 다름. 전용 date schedule을 새로 만들지 않고 (`instructions`에 2026.07.09 도착 보존) FK NULL. 억지 schedule FK 금지.

SUB82를 SCH11에 묶지 않는 이유: SCH11은 원본 패키지 마감 2027.02.10. 졸업예정자 졸업증명서 기한은 unresolved conflict. FK를 두면 S01 쪽을 채택한 것이 됨.

SUB83–84는 S05 표의 원본 기한 칸(~2027.2.10)과 같은 패키지 event이므로 SCH11 연결. HTML 3월 문구는 졸업증명서 항에만 있으므로 이 두 row에 확장하지 않음.

Total submissions = 40+40+4 = **84** (audit 후 유지).

소유권: 모든 SUB → DOC → KU27-P01. schedule FK가 있는 row는 같은 program의 SCH만. SUB81·SUB82는 schedule NULL (MATCH SIMPLE).

---

## 14. RequiredDocumentChoiceGroups

공식 「또는」이 **서로 다른 서류명으로 나열**된 경우만.

**KU27-CG01**

| DB column | intended value |
|---|---|
| admission_program_id | KU27-P01 |
| title | 부모 사망 시 가족관계 대체 서류 |
| rule_text | 부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준). 요강 p13 표. **any_of / exactly_one enum 만들지 않음.** |
| condition | 부모 사망 해당자 |
| display_order | 10 |
| verification_status | verified 후보 |
| verified_at | TBD |

만들지 않음:

- 국외 초등 성적/재학 (한 서류명, 표 안 설명)
- 재직 표 셀의 「또는」 (공식명을 한 RequiredDocument에 보존)
- 여권 분실 시 발급기록증명서 (조건부여체, description)
- 재외국민등록부 비자 등 대체 (「등」 열린 집합)
- 법인세 → 개인소득세 (조건부여체, DOC37 description)

---

## 15. ChoiceGroupItems

같은 AdmissionProgram의 RequiredDocument만. schema: `(choice_group_id, required_document_id, admission_program_id)`.

| row_id | choice_group_id | required_document_id | admission_program_id |
|---|---|---|---|
| KU27-CGI01 | KU27-CG01 | KU27-DOC25 | KU27-P01 |
| KU27-CGI02 | KU27-CG01 | KU27-DOC26 | KU27-P01 |

---

## 16. SourceCitations

한 citation = 한 evidence location. HTML은 `file_page_number` NULL.  
PDF `file_page_number` = physical 1-based. S01 printed label 3–21 = physical 3–21.  
`verified_at` = TBD.

S06 citation **0**.

| row_id | source_document_id | file_page_number | printed_page_label | section | anchor_description |
|---|---|---|---|---|---|
| KU27-CIT01 | SRC02 | 1 | NULL (표지 숫자 없음) | 표지 | 2027학년도 특별전형 모집요강 / 서울캠퍼스 / 재외국민(정원외2%)전형 |
| KU27-CIT02 | SRC02 | 3 | 3 | Ⅰ. 모집단위 및 모집인원 | 재외국민 78명, 계열 배분, 체육교육과 미선발, 학부대학 없음 |
| KU27-CIT03 | SRC02 | 4 | 4 | Ⅱ. 원서 접수 및 서류 제출 일정 (원서·온라인 행) | 원서 07.06 10:00–07.08 17:00, 온라인 서식/서류 07.09 17:00 |
| KU27-CIT04 | SRC02 | 4 | 4 | Ⅱ. 원서접수 유의사항 | 6회 제한, 최종합격 시 수시·정시 지원 제한 |
| KU27-CIT05 | SRC02 | 5 | 5 | Ⅱ. 전형별 일정 | 1단계 07.31 17:00, 면접 08.14 12:30 입실, 최초합격 09.04 17:00 |
| KU27-CIT06 | SRC02 | 5 | 5 | Ⅱ. 합격자 발표 및 등록, 충원 / 등록 포기 | 문서등록·충원·포기·등록금 날짜 |
| KU27-CIT07 | SRC02 | 6 | 6 | Ⅲ. 최종합격자 제출 서류 | 업로드한 모든 서류 + 졸업증명서 |
| KU27-CIT08 | SRC02 | 7 | 7 | Ⅲ. 공정성 및 윤리 | 블라인드·부정행위 등 |
| KU27-CIT09 | SRC02 | 7 | 7 | Ⅲ. 학교폭력 조치사항 | 국내 고교 재학자 학교생활기록부 |
| KU27-CIT10 | SRC02 | 8 | 8 | Ⅳ. 지원자격 공통 | 학력·학제·이수학기 |
| KU27-CIT11 | SRC02 | 9 | 9 | Ⅳ. 지원자격 공통 (계속) | 사례 및 입학 전 졸업 등 |
| KU27-CIT12 | SRC02 | 10 | 10 | Ⅳ. 재외국민(정원외 2%) | 자격 표 및 산정 |
| KU27-CIT13 | SRC02 | 11 | 11 | Ⅳ. 제출서류 안내사항 | A4 PDF, 미발급 고교 우편 07.09, 번역 |
| KU27-CIT14 | SRC02 | 12 | 12 | Ⅳ. 제출서류 상세 (학력·활동·공인) | 재외국민 열 |
| KU27-CIT15 | SRC02 | 13 | 13 | Ⅳ. 제출서류 상세 (여권·출입국·가족) | 재외국민 열, 사망/이혼 주석 |
| KU27-CIT16 | SRC02 | 14 | 14 | Ⅳ. 재직 증빙서류 | 재외국민 재직 구분 |
| KU27-CIT17 | SRC02 | 15 | 15 | Ⅳ. 교내활동, 공인성적 | 선택 평가자료, 리포팅 코드, predicted 제외 |
| KU27-CIT18 | SRC02 | 18 | 18 | Ⅴ. 전형요소 가. 재외국민 | 1단계 100% 3배수, 2단계 70+30 |
| KU27-CIT19 | SRC02 | 19 | 19 | Ⅴ. 서류평가 가 | 학업 40 / 세계시민 30 / 계열 20 / 공동체 10 |
| KU27-CIT20 | SRC02 | 20 | 20 | Ⅵ. 전형료 | 재외국민 금액·반환 |
| KU27-CIT21 | SRC02 | 21 | 21 | Ⅵ. 연락처 | 서울캠퍼스 입학처 |
| KU27-CIT22 | SRC03 | NULL | NULL | 게시 본문 | 2027학년도 특별전형(전기) 제출서류 양식 안내 |
| KU27-CIT23 | SRC04 | NULL | NULL | 게시 본문 | 원서/서식/업로드 기간, 24시간, 브라우저, 우편 예외, 스코어리포팅 우편 |
| KU27-CIT24 | SRC05 | 1 | NULL (표지형) | 면접고사 일시 및 정보 | 2026-08-14, 12:10–12:30 입실, 우당교양관 |
| KU27-CIT25 | SRC05 | 2 | 수험생 유의사항 | 수험생 유의사항 | 신분증, 휴대금지, 편의제공 2026.08.11, 미소지 08.18 방문 |
| KU27-CIT26 | SRC05 | 3 | [별첨1] | 편의제공 요청서 | 양식. 별도 RequiredDocument로 일반화하지 않음 (해당자 신청서) |
| KU27-CIT27 | SRC06 | NULL | NULL | HTML 본문 항 3 | 원본 2027.2.10 및 졸업예정자 졸업증명서 2027년 3월 입학 전 |
| KU27-CIT28 | SRC06 | NULL | NULL | HTML 본문 항 1–2 | 입학허가통지서 출력, 문서등록, 등록금 날짜·상세 추후 |
| KU27-CIT29 | SRC07 | 2 | - 2 - | 신입생 관련 주요 학사 일정 | 입학허가통지서·문서등록·원본·등록금, GMT+9 |
| KU27-CIT30 | SRC07 | 4 | - 4 - | 최종합격자 원본서류 제출 안내 | 원본 표 ~2027.2.10, 예정자 졸업증명서 추가, 별도 요청 출입국/재직 |
| KU27-CIT31 | SRC02 | 4 | 4 | Ⅱ. 원서 접수 및 서류 제출 일정 (최종원본 행) | 최종합격자 원본서류 제출 2027.02.10까지, 우편 |
| KU27-CIT32 | SRC02 | 6 | 6 | Ⅲ. 기본사항 편의제공 | 면접 2일 전까지 편의제공 요청서 |
| KU27-CIT33 | SRC02 | 19 | 19 | Ⅴ. 면접평가 안내 | 제시문 10+5분 / 예능 서류기반, 서울캠퍼스 |

CIT03과 CIT31은 같은 쪽·같은 표이지만 **다른 행·다른 의미**라 분리.  
CIT07과 CIT32는 같은 p6이지만 **최종 서류 항 vs 편의제공 항**이라 분리.  
CIT19와 CIT33은 같은 p19이지만 **서류평가 표 vs 면접평가 표**라 분리.

CIT26은 편의제공 요청서 양식. SCH14에만 연결.

---

## 17. Citation Relations

AdmissionProgram fact-level citation join **없음**.

### 17.1 admission_section_citations (24)

| join | section | citation |
|---|---|---|
| SCJ01 | SEC01 | CIT10 |
| SCJ02 | SEC01 | CIT11 |
| SCJ03 | SEC02 | CIT12 |
| SCJ04 | SEC03 | CIT12 |
| SCJ05 | SEC04 | CIT02 |
| SCJ06 | SEC04 | CIT01 |
| SCJ07 | SEC05 | CIT18 |
| SCJ08 | SEC06 | CIT19 |
| SCJ09 | SEC07 | CIT33 |
| SCJ10 | SEC07 | CIT24 |
| SCJ11 | SEC08 | CIT04 |
| SCJ12 | SEC08 | CIT23 |
| SCJ13 | SEC09 | CIT07 |
| SCJ14 | SEC10 | CIT08 |
| SCJ15 | SEC11 | CIT09 |
| SCJ16 | SEC12 | CIT13 |
| SCJ17 | SEC13 | CIT17 |
| SCJ18 | SEC14 | CIT17 |
| SCJ19 | SEC15 | CIT20 |
| SCJ20 | SEC16 | CIT21 |
| SCJ21 | SEC17 | CIT25 |
| SCJ22 | SEC09 | CIT31 |
| SCJ23 | SEC12 | CIT23 |
| SCJ24 | SEC07 | CIT05 |

= 24.

### 17.2 required_document_citations (56)

기본 1 citation + 양식/유의사항 추가.

| documents | citations |
|---|---|
| DOC01 | CIT14, CIT22 |
| DOC02–DOC04, DOC06–DOC07 | CIT14 |
| DOC05 | CIT14, CIT22 |
| DOC08 | CIT14, CIT17, CIT22 |
| DOC09 | CIT14, CIT17 |
| DOC10 | CIT14, CIT17 |
| DOC11–DOC12 | CIT15, CIT22 |
| DOC13–DOC18 | CIT15; DOC16–18 +CIT22 |
| DOC19 | CIT15, CIT22 |
| DOC20 | CIT13 |
| DOC21–DOC31 | CIT15 |
| DOC32–DOC33 | CIT15, CIT22 |
| DOC34–DOC39 | CIT16 |
| DOC40 | CIT09 |
| DOC41–DOC42 | CIT30 |

Count (문서 내부와 summary 일치):

DOC01=2; DOC02–04=3; DOC05=2; DOC06–07=2; DOC08=3; DOC09=2; DOC10=2; DOC11–12=4; DOC13–15=3; DOC16–18=6; DOC19=2; DOC20=1; DOC21–31=11; DOC32–33=4; DOC34–39=6; DOC40=1; DOC41–42=2.

2+3+2+2+3+2+2+4+3+6+2+1+11+4+6+1+2 = **56**.

### 17.3 document_submission_citations (90 planned, exact below)

- SUB01–SUB40: 각 문서의 기본 원서 citation 1개 (해당 DOC의 첫 citation) = 40
- SUB41–SUB80: CIT07 (최종 모든 서류 원본) = 40
- SUB10 추가 CIT17, CIT23 (스코어리포팅) = +2 on top of SUB10's 1 → SUB10 total 3, extra +2
- SUB81: CIT13, CIT23 = 2
- SUB82: CIT31, CIT07, CIT27, CIT30 = 4
- SUB83–84: CIT30 each = 2

If SUB01–40 already include 1 each (40), SUB10 extras +2, SUB41–80 = 40, SUB81=2, SUB82=4, SUB83–84=2  
= 40+2+40+2+4+2 = **90**.

SUB11/12 양식은 document citation에 있고 submission은 CIT15면 충분.

### 17.4 admission_schedule_citations (28)

| schedule | citations | n |
|---|---|---:|
| SCH01 | CIT03, CIT23 | 2 |
| SCH02 | CIT03, CIT23 | 2 |
| SCH03 | CIT05, CIT24 | 2 |
| SCH04 | CIT05, CIT24 | 2 |
| SCH05 | CIT05, CIT06 | 2 |
| SCH06 | CIT06, CIT28, CIT29 | 3 |
| SCH07 | CIT06 | 1 |
| SCH08 | CIT06 | 1 |
| SCH09 | CIT06 | 1 |
| SCH10 | CIT06, CIT28 | 2 |
| SCH11 | CIT31 | 1 |
| SCH12 | CIT06, CIT28, CIT29 | 3 |
| SCH13 | CIT28, CIT29 | 2 |
| SCH14 | CIT25, CIT32, CIT26 | 3 |
| SCH15 | CIT25 | 1 |

2+2+2+2+2+3+1+1+1+2+1+3+2+3+1 = **28**.

SCH11에 S05 citations를 넣지 않는다. 졸업증명서 conflict는 SUB82만. SUB82는 SCH11 FK 없음.

---

## 18. Official-source Conflict Mapping

### 18.1 졸업예정자 졸업증명서 제출 기한

**Definitive single deadline 금지. `needs_review`. 추가 공식 clarification 전까지 data migration에서도 unresolved 유지 가능.**

장문 직접 인용 없이 source-derived paraphrase:

| artifact | SourceDocument | citation | 의미 요약 |
|---|---|---|---|
| S01 모집요강 | KU27-SRC02 | CIT31, CIT07 | 최종 원본 마감 2027.02.10. 최종 서류는 원서 시 업로드한 모든 서류 + 졸업증명서. 기한 내 원본 미제출 또는 파일과 상이 시 합격·입학 취소 |
| S05 HTML | KU27-SRC06 | CIT27 | 원본서류 기한 2027.2.10 **그리고** 졸업예정자의 졸업증명서 기한을 **2027년 3월 입학 전**으로 별도 항 |
| S05 PDF p4 | KU27-SRC07 | CIT30 | 졸업증명서 원본이 원본서류 표에 있고 기한 칸은 ~2027.2.10. 예정자는 졸업예정증명서를 냈으면 졸업증명서를 추가 제출 |

오타 단정 금지. 어느 쪽이 맞다고 정규화하지 않음.

### 18.2 row-level 범위

| row | verification_status | 이유 |
|---|---|---|
| KU27-DOC04 | verified 후보 | 고교 학력서류를 제출한다는 점은 충돌하지 않음 |
| KU27-SUB04 | verified 후보 | 원서 시 졸업예정증명 온라인 |
| KU27-SUB44 | verified 후보 | 업로드한 고교 학력서류(예정증명 포함)의 원본 패키지. 추가 졸업증명서 기한과 별개 |
| KU27-SCH11 | verified 후보 | 원본 패키지 마감의 S01 표현. 졸업증명서 단독 기한으로 단정하지 않음 |
| **KU27-SUB82** | **needs_review** | 기한 표현 conflict의 정확한 단위. `admission_schedule_id` NULL |
| KU27-P01 | `partially_verified` | child 1건. program 전체를 `needs_review`로 올리지 않음 |
| KU27-SUB83–84 | verified 후보 | S05 별도 요청. HTML 3월 항은 졸업증명서에만 해당 |
| 기타 documents / SCH01–15 | 이 conflict로 needs_review 만들지 않음 | |

### 18.3 provenance

Citation A → S01 (SRC02)  
Citation B → S05 HTML (SRC06)  
Citation C → S05 PDF (SRC07)

한 SourceDocument로 합쳤다면 B/C 구분 불가. 그래서 split.  
`source_conflicts` table 없음 → needs_review + 복수 citation (SCHEMA_GAP-08, blocking 아님).

---

## 19. Schema Gaps

이번 작업에서 schema를 변경하지 않는다. 분류: **NON_BLOCKING** / **DEFERRED** / **POTENTIAL_FUTURE_SCHEMA_CHANGE**. Blocking 없음.

| id | topic | classification | 왜 현 schema로 손실 없이 못 넣는가 | MVP 저장 |
|---|---|---|---|---|
| GAP-01 | 모집단위별 정원 표 | POTENTIAL_FUTURE_SCHEMA_CHANGE | unit table 없음. SEC04 요약은 가능 | 요약 저장 |
| GAP-02 | 기숙사 선발 | DEFERRED | 입학 전형 핵심 event가 아님 | first-load 제외. 「없음」 금지 |
| GAP-03 | 개인 면접 고사실 | NON_BLOCKING | `location_text`는 건물만 | 우당교양관만 |
| GAP-04 | 면접 종료 시각 | NON_BLOCKING | source에 없음. `end_at` NULL 허용 | NULL |
| GAP-05 | (철회) date start NOT NULL | — | schema는 end_date only 허용 | SCH11 |
| GAP-06 | (철회) datetime start NOT NULL | — | schema는 end_at only 허용 | SCH10 |
| GAP-07 | 스코어리포팅 채널 | NON_BLOCKING | method enum 없음 | SUB10 instructions |
| GAP-08 | source_conflicts table | POTENTIAL_FUTURE_SCHEMA_CHANGE | conflict entity 없음 | needs_review + 복수 citation |
| GAP-09 | Source URL alias | POTENTIAL_FUTURE_SCHEMA_CHANGE | `source_url` 1개 | notes / S05 split |
| GAP-10 | EligibilityRule | DEFERRED | table 없음. 이번 범위 밖 | AdmissionSection만 |
| GAP-11 | last_checked_at NOT NULL | NON_BLOCKING | 시각 미확보 | TBD at SQL 재확인 |
| GAP-12 | 합격 후 학사·비자 | DEFERRED | 지원 핵심 아님 | first-load 제외 |
| GAP-13 | 경쟁률 공시 | DEFERRED | 지원 필수 event 아님 | 제외 |

**Blocking schema gap: 없음.**

---

## 20. Provenance Consistency Check

규칙: current fact Entity → SourceCitation → SourceDocument 는 해당 program의 `admission_program_sources`에 있어야 한다.

예외: KU27-SRC01 (S06) — current citation 없음, program_sources 없음.

| SourceDocument | program_sources | current citations | result |
|---|---|---|---|
| SRC01 S06 | no | no | OK (historical exception) |
| SRC02 S01 | PS01 | CIT01–21, CIT31–33 | OK |
| SRC03 S02 | PS02 | CIT22 | OK (양식 DOC에 연결) |
| SRC04 S03 | PS03 | CIT23 | OK |
| SRC05 S04 | PS04 | CIT24–26 | OK |
| SRC06 S05 HTML | PS05 | CIT27–28 | OK |
| SRC07 S05 PDF | PS06 | CIT29–30 | OK |

**결과: PASS.**

---

## 21. Duplicate / Normalization Review

| 위험 | 조치 |
|---|---|
| 원서기간 S01+S03 이중 schedule | SCH01/SCH02 각 1, 복수 citation |
| S03 서식 입력 vs 서류 업로드 | 요강이 한 window → SCH02 1개 |
| 면접 S01+S04+S04 HTML 삼중 | SCH04 1개 |
| 문서등록 S01+S05 | SCH06 1개 |
| 등록금 S01+S05 | SCH12 1개, date only |
| S05 HTML+PDF를 한 source로 합침 | **합치지 않음** (conflict) |
| S05 HWP 세 번째 source | 만들지 않음 |
| S01 BoardView/FileDown 다중 SourceDocument | 1 PDF + notes |
| 졸업증명서 RequiredDocument 복제 | DOC04 유지, SUB82만 추가 |
| 초등 성적/재학 두 document | DOC02 1개 |
| 재직 조건을 택1 group | group 없음 |
| 전교육/북한 서류 | 제외 |
| CIT03에 원서일정+최종원본 뭉침 | CIT03 원서·온라인 행, CIT31 최종원본 행 |
| 편의제공 요강 generic vs S04 날짜 | SCH14 1개, 두 citation |
| ChoiceGroup 중복 | 1 group |

의미가 다른 fact를 중복 제거로 합치지 않음.

---

## 22. Planned Row Count Summary

| DB table | count |
|---|---:|
| universities | 1 |
| admission_categories | 1 |
| source_documents | 7 |
| admission_programs | 1 |
| admission_program_sources | 6 |
| admission_sections | 17 |
| admission_schedules | 15 |
| required_documents | 42 |
| document_submissions | 84 |
| required_document_choice_groups | 1 |
| required_document_choice_group_items | 2 |
| source_citations | 33 |
| admission_section_citations | 24 |
| required_document_citations | 56 |
| document_submission_citations | 90 |
| admission_schedule_citations | 28 |

Citation relation 합계: 24+56+90+28 = **198**.

---

## 23. Open Questions / Needs Review

1. **KU27-SUB82** 졸업예정자 졸업증명서 기한 — unresolved official conflict. clarification 전까지 needs_review.
2. `last_checked_at` / `verified_at` — TBD at final pre-import verification.
3. `slug` / category `code` / `admission_slug` — proposed. SQL 전 unique check.
4. S06 `published_at` NULL — 파일 공식 게시일 미확정.
5. DOC41/42 별도 요청 서류 — 해당자만. 일반 지원 필수로 확대하지 않음.
6. SUB81 `admission_schedule_id` NULL — 우편 도착일과 SCH02 datetime precision 불일치. 전용 schedule을 새로 만들지 않음.
6b. SUB82 `admission_schedule_id` NULL — 기한 conflict를 SCH11(02.10)에 묶지 않음.
7. S10 FAQ — 미사용.
8. 기숙사·비자·학사일정 — this load scope 밖. not_found로 쓰지 않음.
9. language_requirement 최저 section — 만들지 않음 (no inferred absence).
10. 기존 universities/categories — SQL conflict check.

Non-blocking for readiness A.

---

## 24. Readiness for Data Migration

판정: **A. Ready for KU 2027 data migration draft**

| 조건 | 상태 |
|---|---|
| 모든 planned current fact에 source 존재 | yes |
| citation location 존재 | yes |
| row ownership 명확 | KU27-P01 / KU27-U01 |
| duplicate review | §21 |
| provenance consistency | PASS, S06 예외 |
| unresolved conflict를 needs_review로 표현 | SUB82 + CIT A/B/C |
| blocking schema gap | 없음 |

unresolved fact가 있어도 정확한 단위로 needs_review 보존이 가능하면 A.

Static audit(§25) 후 재판정: **A 유지.**

다음 단계(별도 작업): SQL draft. 이 문서는 SQL을 포함하지 않는다.

---

## 25. Static audit (final)

새 source/데이터 추가가 아니라 planned row의 고위험 가정만 재검토했다.

### 25.1 RequiredDocument ↔ DocumentSubmission

**최종 수: RequiredDocument 42 / DocumentSubmission 84. 패턴 유지.**

근거: row가 많아서가 아니라, p11(원서 업로드) + p6(업로드한 모든 서류 원본)이 DOC01–40에 적용되고, 예외 4건만 패턴 밖이다.

| DOC | 온라인? | 최종 원본? | 조건부인가 | 별도 방식 | 온라인-only 오해? | p6 적용? |
|---|---|---|---|---|---|---|
| 01–07, 09–40 | 예 (조건 성립 시) | 예 (업로드한 경우) | 해당자/선택은 condition으로 표시. row 자체는 제출 방법을 말함 | 아니오 (기본 PDF 업로드) | 아니오 | 예 |
| 08 교내활동확인서 | 예 (입력→출력→직인→PDF) | 예 (p6 + p15 미날인 시 최종 날인본) | 선택 | 아니오 | **아니오** — 날인 서류 | 예 |
| 06 학사일정표 | 예 | 예 (업로드 시 p6) | 필수 | 출력물 가능은 format이지 원본 면제가 아님 | 원본 불필요로 추정 금지 | 예 |
| 10 공인성적 | 예 | 예 (업로드 시) | 해당자 | 스코어리포팅은 instructions. 별도 document 아님 | 아니오 | 예 |
| 41–42 | **아니오** | 예 (S05 우편만) | 별도 요청 해당자 | 원서 Pattern A 없음 | 해당 없음 | p6 「원서 업로드분」이 아님 |

예외 submission:

| SUB | ownership | schedule FK | 재검토 |
|---|---|---|---|
| SUB01–40 | DOC01–40 → P01 | SCH02 (같은 program) | 원서 온라인 |
| SUB41–80 | DOC01–40 → P01 | SCH11 (같은 program) | p6 패키지 02.10. conflict 아님 |
| SUB81 | DOC04 → P01 | **NULL** | 미발급 고교 우편. SCH02 17:00과 precision 불일치. 전용 date schedule 미생성 |
| SUB82 | DOC04 → P01 | **NULL** | 졸업예정자 **추가** 졸업증명서. SCH11 연결 시 02.10 채택이 됨 |
| SUB83–84 | DOC41–42 → P01 | SCH11 | S05 별도 요청. 3월 항과 묶지 않음 |

**SUB82 conflict scope:** `needs_review`는 SUB82만. DOC04, SUB04, SUB44, SCH11, 다른 서류, AdmissionProgram 전체(`needs_review`)로 확대하지 않음. Program은 `partially_verified`. 다른 submission이 같은 deadline conflict를 숨기고 있지 않음.

### 25.2 Timezone

| | |
|---|---|
| source literal | S05 PDF p2 `한국 시간(GMT+9)` |
| S01 | timezone 문자열 없음 |
| **DB `timezone`** | **`GMT+9`** |
| not stored | `Asia/Seoul` |

`Asia/Seoul` is a normalized IANA timezone value for the official GMT+9 schedule context; it is not a literal source quotation.

schema/`DATA_MODEL`: timezone은 nullable text. IANA 요구 없음. 따라서 source literal에 가까운 `GMT+9`를 저장하고 IANA를 공식값처럼 쓰지 않는 편이 더 정확하다.

timestamptz 구성 시 SQL 단계에서 같은 GMT+9 오프셋을 쓰되, `timezone` column에 `Asia/Seoul`을 넣지 않는다.

### 25.3 date / datetime (15 schedules)

| SCH | precision | 이유 | fake 00:00 |
|---|---|---|---|
| 01–02 | datetime | 10:00 / 17:00 공식 | 없음 |
| 03, 05 | datetime | 발표 17:00 | 없음 |
| 04 | datetime | 입실 시작 12:10. end_at NULL | 없음 |
| 06–09 | datetime | 충원·문서등록 시각 공식 | 없음 |
| 10 | datetime end_at only | 12.29 10:00까지 | 없음 |
| 11 | date end_date only | 2027.02.10까지. 시간 없음 | 없음 |
| 12 | date | 02.15–02.16. S05 상세 일시 추후 | 시간 추정 없음 |
| 13 | datetime | 합격자 발표 시 17:00 ~ 09.30 17:00 | 없음 |
| 14 | date end_date only | S04 08.11까지. 시간 없음 | 없음 |
| 15 | datetime | 08.18 14:00–17:00 | 없음 |

SUB81: SCH02 FK 없음 유지. 도착일 date vs 온라인 datetime.

### 25.4 S01 / S06

**DB load 확정 유지.** 결정적 근거는 공식 `2026.06. 수정` 게시 + 수정사항↔June p3 일치. MD5는 보조.

### 25.5 S05 split

**B 유지.** HTML/PDF 각각 fact-bearing, 독립 citation, deadline provenance 구분 필요. HWP row 추가 없음.

### 25.6 Citations

30→**33**. 같은 쪽의 **다른 의미**를 분리: CIT03/CIT31, CIT07/CIT32, CIT19/CIT33. 의미 없는 위치 중복 생성 없음. reuse는 같은 location이 여러 entity를 실제로 뒷받침할 때만 (예: CIT06 → SCH05–10, SCH12).

### 25.7 Citation relations / ProgramSource / provenance

section 24, document 56, submission 90, schedule 28 = **198**.  
경로: entity → citation → SRC02–07 → PS01–06. S06 current relation **0**. **PASS.**

### 25.8 slug / timestamps

`admission_slug` = `overseas-korean-2pct` **proposed** route id. official name = `재외국민(정원외2%)전형`. SQL 전 uniqueness check.  
`verified_at` / `last_checked_at` = TBD. S06 `published_at` NULL.

### 25.9 Readiness

**A. Ready for KU 2027 data migration draft**

- 84 submissions가 row-level evidence와 일치
- timezone mapping 명확 (literal vs IANA)
- S01/S06 근거 충분
- S05 split 적절
- conflict 국소화 (SUB82, FK NULL)
- provenance PASS
- blocking gap 없음
- row count 내부 일치 (42/84/33/198)
