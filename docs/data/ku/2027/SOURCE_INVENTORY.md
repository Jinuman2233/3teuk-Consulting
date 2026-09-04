# KU 2027 Source Inventory

Inventory-only document for official-source ingestion of
고려대학교 서울캠퍼스 2027학년도 재외국민(정원외2%)전형.

This file is **not** a ROW_MAP, Citation Map, SQL migration, or data load.
No admission facts are structured into DB rows here.
`source_id` values (`KU2027-S01` …) are temporary inventory identifiers, not DB UUIDs.
Inventory `status` labels are human-readable document labels, not DB `verification_status`.
Document-only status values used here include PRIMARY, SUPPLEMENTAL, REFERENCE_ONLY, EXCLUDED, NEEDS_REVIEW, and HISTORICAL_REVISION.


## 1. Scope

| Field | Value |
| --- | --- |
| University | 고려대학교 |
| Campus | 서울캠퍼스 (`campus_name`; no separate Campus entity) |
| Academic year | 2027 |
| Target official admission program | 재외국민(정원외2%)전형 |
| Issuing office in scope | 고려대학교 서울캠퍼스 입학처 (`https://oku.korea.ac.kr`) |
| Verified date (inventory) | 2026-09-04 |

### In this inventory

- 전교육과정해외이수자(전기)전형
- 북한이탈주민전형

appear in the same 특별전형(전기) 모집요강 PDF. They are **not** target programs.
Their pages are recorded only when the same passage is a **common rule that actually applies** to 재외국민(정원외2%)전형.

### Out of this inventory as target sources

- 고려대학교 세종캠퍼스 (`/sejong/` URLs)
- 2026학년도 전교육과정해외이수자(후기) and other prior-year notices
- 수시 / 정시 모집요강 (except where a 특별전형 제출서류 board is reached through a shared CMS menu)

No admission data was inserted into any database as part of this inventory.


## 2. Verification Standard

Followed `docs/VERIFIED_DATA_LOAD_SPEC.md` source-first rules for this step only:

- Official 입학처 sources only.
- Do not invent eligibility, quotas, scores, dates, or document lists.
- Do not mix academic years.
- Do not treat 세종캠퍼스 materials as 서울캠퍼스 sources.
- `published_at` is recorded only when the official posting date is visible. File-path timestamps and PDF `/CreationDate` are not used as `published_at`.
- `verified_date` in this inventory is 2026-09-04. It is not a source publication date.
- Logical source document vs access surface are separated. Different URLs are not automatically different SourceDocuments.
- ZIP/XLSX inner field contents are not guessed. ZIP member **filenames** were listed after download. XLSX sheet contents were not inspected.
- Complete fact extraction, RequiredDocument rows, AdmissionSchedule rows, and ROW_MAP structure are deferred.

### Homepage check (not a primary citation)

`https://oku.korea.ac.kr/oku/index.do` (verified 2026-09-04):

- Identifies itself as **서울캠퍼스 입학처**. Footer address: 서울시 성북구 안암로 145.
- Navigation includes 특별전형 → 모집요강(전기) (`MENU_ID=690`).
- Current official navigation PDF viewer for that menu loads the June 배포용 file (see KU2027-S01 access surfaces).
- Homepage banners/notices current at verification included 2027학년도 특별전형(전기) 최종합격자 발표 and 2027학년도 특별전형(재외국민(정원외2%), 북한이탈주민) 1단계 합격자 발표.
- Separate footer link to 세종캠퍼스 입학팀 (`/sejong/index.do`) is **excluded**.

The homepage is not used as primary evidence for eligibility, evaluation, quotas, or dates.


## 3. Included Official Sources

Sources that can supply MVP eligibility / evaluation / schedule / documents / submission / caution evidence for the **target program**.

S01–S05 below are **current-fact** sources. KU2027-S06 is a HISTORICAL_REVISION of the same 요강 family: it is documented after S05 for source history, not as a current-fact included source.

### 3.1 Summary table

| source_id | status | source_type | title | issuing_org | academic_year | campus | target_program_relevance | source_url | published_at | document_version_label | physical_page_count | coverage | source_role | verified_date |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| KU2027-S01 | PRIMARY | admissions_guide | 2027학년도 특별전형 모집요강 (서울캠퍼스); 게시 제목 2027학년도 특별전형(전기) 모집요강(2026.06. 수정); 첨부 파일명 2027학년도 고려대학교 서울캠퍼스 특별전형모집 요강 (2026.06.10)_배포용.pdf | 고려대학교 서울캠퍼스 입학처 | 2027 | 서울캠퍼스 | target program included (with two non-target programs in the same PDF) | canonical file: `https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf` | 2026-06-10 | (2026.06.10)_배포용 / 2026.06. 수정 | 21 | eligibility, evaluation, schedules, documents, submission, cautions, program identity, quotas | primary official guide | 2026-09-04 |
| KU2027-S02 | SUPPLEMENTAL | submission_forms | [서울캠퍼스] 2027학년도 특별전형(전기) 제출서류 양식 안내 | 고려대학교 서울캠퍼스 입학처 | 2027 | 서울캠퍼스 | target program named in ZIP title and form filenames | posting: `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=124&BOARD_SEQ=3&CONTENTS_NO=&MENU_ID=730&SITE_NO=2` | 2026-05-26 | none confirmed inside files | ZIP archive (member PDFs/DOC/HWP not counted as one guide); XLSX separate attachment | official form templates + 교내활동 글자수 sample | supplemental document-template source | 2026-09-04 |
| KU2027-S03 | SUPPLEMENTAL | official_notice | 2027학년도 특별전형(전기) 원서접수 안내 | 고려대학교 서울캠퍼스 입학처 | 2027 | 서울캠퍼스 | target program included in 특별전형(전기) | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1799&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` | 2026-07-02 | none confirmed | HTML notice (no PDF attachment found) | application window, online form/upload, mail exceptions, 6-회 제한 reminder | supplemental schedule/submission operations | 2026-09-04 |
| KU2027-S04 | SUPPLEMENTAL | official_notice | 2027학년도 특별전형(재외국민(정원외2%), 북한이탈주민) 1단계 합격자 발표 + 첨부 2027학년도 특별전형 1단계 합격자 면접고사 안내 및 수험생 유의사항(배포용).pdf | 고려대학교 서울캠퍼스 입학처 | 2027 | 서울캠퍼스 | target program named | posting: `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1803&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` | 2026-07-29 | (배포용) on interview PDF filename | interview PDF: 3 physical pages | interview logistics, cautions, 편의제공 | supplemental interview operations (조회 화면 자체는 informational-only) | 2026-09-04 |
| KU2027-S05 | SUPPLEMENTAL | official_notice | 2027학년도 특별전형(전기) 최종 합격자 발표 + 첨부 2027학년도 특별전형 최종합격자 안내사항(배포용).pdf | 고려대학교 서울캠퍼스 입학처 | 2027 | 서울캠퍼스 | target program named | posting: `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1805&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` | 2026-09-03 | (배포용) on attachment filenames | final guide PDF: 7 physical pages | post-admit documents/registration; some schedule restatement | supplemental post-admit documents/schedule | 2026-09-04 |

### KU2027-S01 — Primary 특별전형(전기) 모집요강 PDF

| Field | Value |
| --- | --- |
| source_id | KU2027-S01 |
| status | PRIMARY |
| source_type | admissions_guide |
| Cover title (PDF physical page 1) | 2027학년도 특별전형 모집요강 / 서울캠퍼스 / 재외국민(정원외2%)전형, 전교육과정해외이수자(전기)전형, 북한이탈주민전형 |
| Official posting subject | 2027학년도 특별전형(전기) 모집요강(2026.06. 수정) |
| Official attachment filename | 2027학년도 고려대학교 서울캠퍼스 특별전형모집 요강 (2026.06.10)_배포용.pdf |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | Target program is in scope. The other two programs in the PDF are not target programs. |
| published_at | 2026-06-10 (`WRITE_DATE` / 작성일 on BBS_SEQ=1794). Original CMS `REG_DT` of the same post: 2026-05-21. `UPT_DT` 2026-08-31 is a later CMS update timestamp, not treated as a new document version. |
| document_version_label | `(2026.06.10)_배포용` (filename); `2026.06. 수정` (posting subject). PDF body text does not itself print a “수정/개정/version” label. |
| physical_page_count | 21 |
| coverage | program identity; 모집단위/인원; 원서·서류 일정; 전형별 일정; 유의사항; 지원자격 공통; 재외국민 지원자격; 제출서류 안내/상세/재직증빙/교내활동·공인성적; 전형요소; 서류평가; 면접평가; 전형료 |
| source_role | Current primary official guide for ROW_MAP of core DB facts. Supersedes KU2027-S06 at inventory level; see §6. |
| verified_date | 2026-09-04 |
| notes | Current facts are taken from this June revision only. See §5 page map, §6 revision (S01 supersedes S06), and access surfaces below. PDF metadata `/CreationDate` = 2026-06-10 16:17:25 +09:00 is recorded only as file metadata, not as `published_at`. |

**Logical document vs access surfaces (same SourceDocument):**

| Access surface | URL / locator | Role |
| --- | --- | --- |
| Canonical current PDF file | `https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf` | Direct file used by 모집요강(전기) navigation viewer |
| Official posting page | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1794&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2&pageNo=1&pagePerCnt=10` | Official access surface, attachment metadata, revision notes in HTML body |
| Board file download | `/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1794&FILE_SEQ=4` | Same bytes as the June attach URL (MD5 match confirmed 2026-09-04) |
| Navigation page 특별전형 > 모집요강(전기) | `https://oku.korea.ac.kr/oku/cms/FR_CON/index.do?MENU_ID=690` | Official navigation; iframe viewer of the June PDF; download JS uses filename `(2026.06.10)_배포용.pdf` |

The HTML posting body is **not** treated as a second SourceDocument. It is metadata / revision context for KU2027-S01. Confirmed HTML revision bullets (2026.06. 수정사항):

- 체육교육과 전교육과정해외이수자전형만 선발
- 학부대학 미선발

Those bullets match the current June PDF physical page 3 table, compared with the confirmed previous official file KU2027-S06.

**Current-fact source vs historical provenance:** `https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf` is a different 21-page PDF (different MD5). It is KU2027-S06, a confirmed previous official revision. It is **not** the current primary fact source. See the S06 card and §6.

### KU2027-S02 — 제출서류 양식 posting + attachments

| Field | Value |
| --- | --- |
| source_id | KU2027-S02 |
| status | SUPPLEMENTAL |
| source_type | submission_forms |
| title | [서울캠퍼스] 2027학년도 특별전형(전기) 제출서류 양식 안내 |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | ZIP title and several form filenames include 재외국민(정원외2%) / `[2%]`. 북한이탈주민-only forms are in the same ZIP and are not target-program forms. |
| source_url | User-specified posting: `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=124&BOARD_SEQ=3&CONTENTS_NO=&MENU_ID=730&SITE_NO=2` |
| published_at | 2026-05-26 (`WRITE_DATE`). `REG_DT` 2026-05-26; `UPT_DT` 2026-05-29. |
| document_version_label | none confirmed |
| physical_page_count | not a single PDF; ZIP of 견본/서식 files |
| coverage | official prescribed-form inventory that backs RequiredDocument / submission template facts already named in KU2027-S01. Does not replace the 요강 document list. |
| source_role | Supplemental templates. Guide remains primary for which documents are required. |
| verified_date | 2026-09-04 |

**Access surfaces (same posting):**

- User URL uses `MENU_ID=730` (CMS breadcrumb on that URL: 정시 > 제출서류). The PDF itself points applicants to 입학처 홈페이지 – [특별전형] – [제출서류], which is `MENU_ID=1750`. Board identity is `BOARD_SEQ=3`, `BBS_SEQ=124` in both cases. Same logical posting; different menu wrappers.
- 모집요강(전기) viewer (`MENU_ID=690`) has a “제출서류 양식” button that opens BBS_SEQ=124.

**Attachments confirmed on the posting:**

1. `2027학년도 전기 특별전형(재외국민(정원외2%),전교육과정해외이수자(전기),북한이탈주민)제출서류 양식.zip` (`FILE_SEQ=1`)
2. `2027학년도 특별전형(전기) 교내활동확인서 글자수(byte) test.xlsx` (`FILE_SEQ=2`)

**ZIP member filenames (listed after download; form field contents not extracted):**

- 견본: `[2%,전과정] 교내활동확인서(국문).pdf`, `[2%,전과정] 교내활동확인서(영문).pdf`, `[북한이탈주민] 활동증빙서류 목록표.pdf`
- 서식 (each as `.doc` and `.hwp`): `[2%, 전과정] 사실증명 발급열람신청서 및 위임장`, `[2%, 전과정] 학력조회 동의서`, `[2%] 개인정보 수집 및 이용 동의서(학부모용)`, `[북한이탈주민] 특이사항(사유서)`, `[공통] 개인정보 변경확인요청서`, `디자인조형학부 포트폴리오 서약서`, `디자인조형학부 포트폴리오 제출 양식`

The posting HTML itself classifies 견본 vs 서식 and states that 견본 files are 참고용 / not for printing, and that the XLSX is a byte-count **sample** that “원서접수 시 byte수와는 상이할 수 있으니, 원서접수 시 직접 입력하여 확인”. XLSX internal sheets/cells were **not** inspected.

Does this source add MVP document facts? **Yes, as templates and form inventory**, not as a second quota/eligibility guide.

### KU2027-S03 — 원서접수 안내

| Field | Value |
| --- | --- |
| source_id | KU2027-S03 |
| status | SUPPLEMENTAL |
| source_type | official_notice |
| title | 2027학년도 특별전형(전기) 원서접수 안내 |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | 특별전형(전기) includes the target program |
| source_url | `https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1799&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2` |
| published_at | 2026-07-02 (`WRITE_DATE`). `REG_DT` 2026-06-26; `UPT_DT` 2026-07-14. |
| document_version_label | none confirmed |
| physical_page_count | HTML only (no attachment found on the posting) |
| coverage | restates 원서/온라인서식/업로드 일정 from the guide; adds operational submission facts (24-hour receipt during window, Chrome/Edge only, 수험표 check, mail-in exceptions, score-reporting mail) |
| source_role | Supplemental schedule/submission operations. Not a replacement guide. |
| verified_date | 2026-09-04 |
| notes | New-evidence test: **yes** for submission operations / cautions. Core dates already exist in KU2027-S01 physical pages 4–5. |

### KU2027-S04 — 1단계 합격자 발표 + 면접 안내 PDF

| Field | Value |
| --- | --- |
| source_id | KU2027-S04 |
| status | SUPPLEMENTAL |
| source_type | official_notice |
| title | 2027학년도 특별전형(재외국민(정원외2%), 북한이탈주민) 1단계 합격자 발표 |
| Attachment | 2027학년도 특별전형 1단계 합격자 면접고사 안내 및 수험생 유의사항(배포용).pdf |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | Target program is named. 북한이탈주민 is also named; not a target program. |
| source_url | posting `BBS_SEQ=1803` (URL in summary table) |
| published_at | 2026-07-29 (`WRITE_DATE`). `REG_DT` 2026-07-24; `UPT_DT` 2026-08-31. |
| document_version_label | `(배포용)` on attachment filename |
| physical_page_count | 3 (interview PDF). Printed labels: page 1 untitled cover-style; page 2 수험생 유의사항; page 3 `[별첨1] 편의제공 요청서`. |
| coverage | interview date/building/entry window, prohibited items, 편의제공 request (email + deadline), identity-document rules |
| source_role | Supplemental interview logistics. 1단계 합격자 조회 UI itself is informational-only and is not an MVP eligibility/evaluation fact source. |
| verified_date | 2026-09-04 |
| notes | Guide physical page 5 already has interview date and “12:30까지 입실” / “서울캠퍼스”. This notice adds 12:10 입실 시작, 우당교양관, and 편의제공 절차. Treated as complementary detail, not as a second primary evaluation scheme. |

### KU2027-S05 — 최종합격자 발표 + 합격자 안내 PDF

| Field | Value |
| --- | --- |
| source_id | KU2027-S05 |
| status | SUPPLEMENTAL |
| source_type | official_notice |
| title | 2027학년도 특별전형(전기) 최종 합격자 발표 |
| Attachments | `2027학년도 특별전형 최종합격자 안내사항(배포용).hwp` and `.pdf` (same posting; PDF used for page inventory; HWP not treated as a separate SourceDocument) |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | Target program named among 특별전형(전기) |
| source_url | posting `BBS_SEQ=1805` (URL in summary table) |
| published_at | 2026-09-03 (`WRITE_DATE`; `START_DT` 2026-09-03 17:03). `REG_DT` 2026-08-28; `UPT_DT` 2026-09-03. |
| document_version_label | `(배포용)` on attachment filenames |
| physical_page_count | 7 (PDF). Printed labels `- 2 -` … `- 7 -` on pages 2–7; page 1 is cover. |
| coverage | 입학허가통지서 출력, 문서등록, 원본서류 제출, 등록금, 비자/표준입학허가서 (foreign students), 기숙사 restatement |
| source_role | Supplemental post-admit document/registration source. Core application-time facts remain in KU2027-S01. |
| verified_date | 2026-09-04 |
| notes | Adds post-admit operational facts (envelope 수험번호, 중국 CHSI report for 중국 현지 고교 졸업생, 졸업예정자 중 별도 요청 인원 추가 출입국/재직서류). HTML posting also states 졸업예정자 졸업증명서 기한 as 2027년 3월 입학 전까지. That wording is part of the **unresolved official-source conflict** in §7; do not treat it as identical to the 요강 2027.02.10 원본서류 deadline. |

### 3.2 Historical revision (not current-fact source)

### KU2027-S06 — Historical previous 요강 PDF (not current fact source)

This is a confirmed previous official revision of the same 2027 특별전형(전기) 모집요강, not an unrelated or erroneous file.

**Current applicability and historical provenance are separate:**

- S06 is **not** the current-regulation primary source.
- Current facts are taken from **S01 (June revision)** only.
- Do **not** extract current eligibility, 모집단위, or other facts from S06.
- S06 **is** a confirmed previous official revision and a SourceDocument **history-preservation candidate**.
- Future DB load should **keep an S06 SourceDocument row**.
- Inventory-level recommended mapping for ROW_MAP review: `S01.supersedes_source_document_id` → S06.
- That FK is **not** confirmed in this inventory. Actual DB FK is decided after ROW_MAP review.
- Do **not** assume S06 is automatically linked as a current `AdmissionProgramSource`.

| Field | Value |
| --- | --- |
| source_id | KU2027-S06 |
| status | HISTORICAL_REVISION |
| source_type | admissions_guide |
| title | 2027학년도 특별전형 모집요강 (May official PDF; still reachable) |
| issuing_org | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| campus | 서울캠퍼스 |
| target_program_relevance | Same guide family as S01; superseded for current facts |
| source_url | `https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf` |
| published_at | official posting date for this *file* not separately labeled; PDF `/CreationDate` 2026-05-29 is metadata only — not used as `published_at` |
| document_version_label | none printed inside the PDF; inventory label = May official PDF / previous revision of S01 |
| physical_page_count | 21 |
| coverage | historical provenance only; not current-fact coverage |
| source_role | Historical SourceDocument. Not current AdmissionProgramSource. |
| verified_date | 2026-09-04 |
| notes | Same 21 physical pages as S01. Confirmed content differences on physical page 3 (학부대학 row present; 체육교육과 marked 미선발 without “전교육만 선발”). HISTORICAL_REVISION is an inventory document label, not a DB enum. |


## 4. Excluded / Reference-only Sources

These were checked because they appear on the official site. They are **not** initial DB sources for extracting the target program’s core application-time facts, unless a later ROW_MAP step explicitly cites a complementary detail.

KU2027-S06 is **not** in this EXCLUDED list. It is a HISTORICAL_REVISION (see the S06 card above): excluded from **current-fact** extraction, preserved for **source history**.

| source_id | status | source_type | title | campus | published_at | source_url | notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| KU2027-S07 | REFERENCE_ONLY | official_notice | 서울캠퍼스 입학처 홈페이지 | 서울캠퍼스 | n/a (living page) | `https://oku.korea.ac.kr/oku/index.do` | Navigation / latest-notice check only. Not a primary citation for detailed facts. |
| KU2027-S08 | REFERENCE_ONLY | official_notice | 2027학년도 고려대학교 입학전형시행계획(2026.07. 수정) | 서울캠퍼스 (university-level plan) | WRITE_DATE displayed 2025-04-30; subject includes 2026.07. 수정; `UPT_DT` 2026-08-31 | `BBS_SEQ=1712` | Body says some contents may change and **모집요강을 반드시 확인**. Not used over KU2027-S01. |
| KU2027-S09 | REFERENCE_ONLY | official_notice | 원서접수 파일업로드 A4 변환 안내 | not campus-specific in title (일반사항) | 2026-09-02 (`WRITE_DATE`; `REG_DT` 2026-07-08) | `BBS_SEQ=1801` | How-to for A4 PDF conversion. Guide already requires A4 PDF upload. Informational-only for MVP fact categories. |
| KU2027-S10 | NEEDS_REVIEW | official_faq | 입학처 FAQ category 특별전형 (BOARD_SEQ=8, CATE_SEQ=9) | 서울캠퍼스 | FAQ `WRITE_DATE` values display as `0025.04.25` (likely 2025-04-25; not labeled 2027학년도) | `https://oku.korea.ac.kr/oku/cms/FR_CON/index.do?MENU_ID=790` | Standing FAQ includes 재외국민(정원외2%) items (재직서류 대체, 재외국민등록부 대체, 국내체류 14일 등). Year-binding to 2027 is **not confirmed**. Do **not** use S10 as an automatic initial ROW_MAP fact source unless 2027 applicability is confirmed. Do not let FAQ override 2027 요강. |
| — | EXCLUDED | official_notice | 2026학년도 전교육과정해외이수자(후기) notices (BBS_SEQ 1804, 1797, 1796, 1783, 1779, etc.) | 서울캠퍼스 | 2026 dates | 특별전형 공지 목록 | Wrong academic year and/or non-target program. |
| — | EXCLUDED | admissions_guide | 세종캠퍼스 any `/sejong/` material | 세종캠퍼스 | — | URLs containing `/sejong/` | Strict campus split. Homepage links 세종캠퍼스 입학팀; those URLs are out of scope. |
| — | EXCLUDED | submission_forms | 정시/수시 제출서류 양식 안내 (adjacent posts to BBS_SEQ=124) | 서울캠퍼스 | 2027 | previous/next on forms board | Wrong admission type. |
| — | EXCLUDED | — | 전교육과정해외이수자(전기)전형 / 북한이탈주민전형 as programs | 서울캠퍼스 | 2027 | same KU2027-S01 PDF | Same PDF, not target programs. Common-rule pages may still be cited for the target program. |

### 특별전형 공지 board snapshot (verified 2026-09-04)

Official 특별전형 공지 list (`MENU_ID=1740`, `SEARCH_SEQ=4`) contained 13 posts. 2027 전기 / target-program-related posts on that list:

- 1805 최종 합격자 발표 → KU2027-S05
- 1803 1단계 합격자 발표 → KU2027-S04
- 1794 모집요강(2026.06. 수정) → KU2027-S01 access surface
- 1799 원서접수 안내 → KU2027-S03

No separate 2027 정정 공지 beyond the 2026.06. 수정 요강 posting was found on this board.


## 5. Primary Guide Physical Page Map

Source: **KU2027-S01** current June 배포용 PDF (`attach/202606/1781850206372_0.pdf`).

`file_page_number` = physical PDF page, **1-based**.
`printed_page_label` = footer label printed on the page.
Do not use 0-based viewer indexes.

Physical pages 3–21 print a footer of the form `섹션명 | N` where N equals the physical page number. Physical pages 1–2 have no such numeric footer.

| Topic | file_page_number (start) | printed_page_label | Section in PDF | Applies to target program? |
| --- | --- | --- | --- | --- |
| Cover / program list | 1 | none | cover | yes (identity) |
| Table of contents | 2 | none (TOC points to printed 3–21) | CONTENTS | navigation only |
| 모집단위 / 모집인원 | 3 | 3 | Ⅰ. 전형 주요 사항 | yes for 재외국민 column / 78명 총괄. 전교육·북한이탈 인원제한없음 is not a target-program quota fact. 체육교육과 “미선발 전교육만 선발” and 학부대학 미선발 are current-table facts; 재외국민 체육교육과 is 미선발. |
| 원서접수 및 서류 제출 일정 | 4 | 4 | Ⅱ. 원서접수 및 전형 일정 | yes (common 전기 schedule) |
| 원서접수 유의사항 | 4 | 4 | Ⅱ | yes (includes 재외국민-specific 수시·정시 지원 제한 and 6회 제한) |
| 전형별 일정 | 5 | 5 | Ⅱ | yes for 재외국민/북한이탈 면접 일정 row. 전교육과정 “- -” is not target. |
| 합격자 발표·등록·충원 / 등록 포기 | 5 | 5 | Ⅱ | yes |
| 지원자 유의사항 (기본 / 등록 / 최종합격자 제출서류) | 6 | 6 | Ⅲ. 지원자 유의사항 | yes; 면접 자격검토 문장은 재외국민·북한이탈 공통 |
| 공정성·윤리 / 학교폭력 | 7 | 7 | Ⅲ | yes (common) |
| 지원자격 공통 (재외국민 + 전교육과정) | 8–9 | 8–9 | Ⅳ. 전형 세부안내 u 지원자격 1. 공통 | yes — common rule that the PDF applies to 재외국민(정원외2%) |
| 재외국민(정원외2%) 지원자격 | 10 | 10 | Ⅳ. 2. 재외국민(정원외 2%) | yes — target-specific |
| 전교육과정해외이수자 지원자격 | 11 | 11 | Ⅳ. 3. | **no** as target eligibility. Do not load as target-program eligibility. |
| 북한이탈주민 지원자격 | 11 | 11 | Ⅳ. 4. | **no** as target eligibility |
| 제출서류 안내사항 | 11 | 11 | Ⅳ. u 제출서류 안내사항 | yes — common submission rules |
| 재외국민 제출서류 상세 (shared table with 전과정 columns) | 12–13 | 12–13 | Ⅳ. 제출서류 상세 안내 - 재외국민(정원외2%), 전교육과정해외이수자 | yes — use 정원외2% column only |
| 재외국민 재직 증빙서류 | 14 | 14 | Ⅳ. 제출서류 상세 안내 – 재외국민(정원외2%) 재직 증빙서류 | yes — target-specific |
| 교내활동 / 공인성적 유의사항 | 15 | 15 | Ⅳ. 제출서류 유의 사항 – 교내활동, 공인성적 | yes — common to 재외국민/전과정 document practice |
| 북한이탈주민 제출서류 / 활동증빙 | 16–17 | 16–17 | Ⅳ | **no** as target RequiredDocument list |
| 전형요소 및 반영비율 | 18 | 18 | Ⅴ. 평가 관련 안내사항 | yes — 가. 재외국민(정원외2%)전형 only. 나/다 are other programs. |
| 서류평가 | 19 | 19 | Ⅴ. 서류평가 안내 가. 재외국민, 전교육과정 | yes — 가. scheme applies to target (shared with 전과정). 나. 북한이탈 is not target. |
| 면접평가 | 19 | 19 | Ⅴ. 면접평가 안내 - 재외국민(정원외2%), 북한이탈주민 | yes — shared interview format with 북한이탈; still applies to target |
| 전형료 / 기숙사 | 20 | 20 | Ⅵ. 참고 사항 | yes for 재외국민 전형료 row; 기숙사 is reference |
| 연락처 | 21 | 21 | Ⅵ | university/campus contact confirmation |

This map only says **which physical page owns which fact category**. It does not extract the sentences.


## 6. Source Revision / Version Notes

Current applicability and historical provenance are separate.

### Current

- **KU2027-S01**
- `2026.06.10` 배포용 / `2026.06` 수정
- Official posting subject: `2027학년도 특별전형(전기) 모집요강(2026.06. 수정)`
- Attachment filename: `2027학년도 고려대학교 서울캠퍼스 특별전형모집 요강 (2026.06.10)_배포용.pdf`
- Official 작성일 / `WRITE_DATE`: **2026-06-10**
- Same CMS post was first registered `REG_DT` **2026-05-21**
- FILE_SEQ on the current attachment is **4**, which indicates the post has had multiple files; earlier FILE_SEQ objects were not separately retrieved.
- PDF body: no printed “수정/개정/version N” string confirmed inside the 21 pages.
- PDF `/CreationDate` / `/ModDate`: 2026-06-10 16:17:25 +09:00 (metadata only).
- **Current facts are taken from S01 only.**

### Previous confirmed revision

- **KU2027-S06**
- May official PDF
- `https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf`
- Still publicly fetchable. Not byte-identical to the current official attachment.
- Inventory status: **HISTORICAL_REVISION** (document label, not a DB enum).

| | May official PDF (KU2027-S06) | June 배포용 (KU2027-S01) |
| --- | --- | --- |
| Physical pages | 21 | 21 |
| MD5 (2026-09-04) | `0101ca32cd58aa6e0bae18da477a4540` | `5125201fbde632473c1b9e57839227b9` |
| PDF `/CreationDate` | 2026-05-29 10:19:05 +09:00 | 2026-06-10 16:17:25 +09:00 |
| Board FILE_SEQ=4 | no match | exact byte match |

Extracted-text / rendered-page differences confirmed on **physical page 3**:

- 학부대학 모집단위 row: present in May file; **absent** in June file (matches HTML 수정사항 “학부대학 미선발”).
- 체육교육과: May “미선발”; June “미선발 전교육만 선발” (matches HTML 수정사항 “체육교육과 전교육과정해외이수자전형만 선발”).
- Other extracted pages 1–2 and 4–21: identical extracted text between the two files.

No additional named previous revision (e.g. a dated “1차 배포” PDF) was confirmed beyond this May file and the June 배포용. Do not invent further versions.

The previous revision was **not guessed**. It is an actual official-file difference (different MD5, different `/CreationDate`, confirmed page-3 content change matching the posting’s 2026.06. 수정사항).

### Relationship (inventory-level recommended mapping)

**S01 supersedes S06**

This is the current inventory-level recommended mapping only.

- Future DB load should preserve an S06 SourceDocument row.
- ROW_MAP should review `S01.supersedes_source_document_id` → S06.
- The actual DB FK is **not** set in this inventory. It is confirmed after ROW_MAP review.
- S06 is not assumed to be a current `AdmissionProgramSource`.
- Current extraction uses S01 only.


## 7. Official-source Conflict Check

Between **current** official sources for the 2027 target program:

**No confirmed official-source conflict found** on eligibility criteria, evaluation ratios, or the main application/interview/announcement dates in KU2027-S01 vs KU2027-S03/S04.

Complementary (not treated as conflict):

- KU2027-S01 p.5: 면접 “08.14.(금) 12:30까지 입실”, 장소 “서울캠퍼스”.
- KU2027-S04: 입실 12:10 시작 ~ 12:30 완료, 장소 우당교양관.

May vs June 요강 differences are a **revision** (S01 supersedes S06), not a same-generation conflict. Current official text is June (KU2027-S01).

### Unresolved official-source conflict: 졸업예정자 졸업증명서 제출 기한

This is an **explicit unresolved conflict** among current official sources. All related sources are kept. None is discarded. None is called a typo. No single deadline is normalized here. No DB row is created in this inventory.

| Source | Location | Official wording (as read; not normalized) |
| --- | --- | --- |
| KU2027-S01 모집요강 | physical p.4 / p.6 | 최종합격자 원본서류 제출 기한 2027.02.10.(수). 최종합격자 제출서류 includes 졸업증명서. |
| KU2027-S05 최종합격자 안내 HTML | posting body | 원본서류 2027.02.10.(수)까지 **and** “졸업예정자의 졸업증명서 제출 기한: 2027년 3월 입학 전까지”. |
| KU2027-S05 최종합격자 안내 PDF | physical page 4 table | 졸업증명서 원본 is listed in the 원본서류 table whose visible deadline column includes `~ 2027.2.10.(수)`; the table also says 졸업예정자는 졸업증명서를 추가 제출. |

**ROW_MAP handling (required):**

Treat this fact as **needs_review**.

Possible ROW_MAP direction (not executed here):

- Connect **all** conflicting citations.
- Record each source’s wording in notes.
- Do **not** confirm a definitive normalized deadline before additional review.

`needs_review` here is a ROW_MAP fact-handling instruction, not a new DB status enum.


## 8. Coverage Assessment

Labels below are inventory judgments, not DB enums.

**COVERED** means official sources exist and are sufficient to map the domain in ROW_MAP. It does **not** mean every fact is conflict-free.

| DB domain | coverage | evidence |
| --- | --- | --- |
| university/campus | COVERED | KU2027-S01 cover + p.21; homepage confirms 서울캠퍼스 입학처 |
| admission program identity | COVERED | KU2027-S01 cover and posting subject/filename |
| eligibility | COVERED | KU2027-S01 p.8–10 (common + 재외국민). FAQ extras year-unbound → not counted as covered |
| evaluation | COVERED | KU2027-S01 p.18–19. Interview building/entry window supplemented by KU2027-S04 |
| schedules | COVERED | KU2027-S01 p.4–5. Operational restatement/additions in S03–S05 |
| required documents | COVERED (with one official-source deadline conflict requiring ROW_MAP needs_review) | KU2027-S01 p.11–15. Templates in S02. 북한-only lists excluded. 졸업예정자 졸업증명서 기한: unresolved conflict among S01 / S05 HTML / S05 PDF (§7). Sources are sufficient; the deadline fact is not conflict-free. |
| document submissions | COVERED (with one official-source deadline conflict requiring ROW_MAP needs_review) | KU2027-S01 p.4, 6, 11–15. S03 adds mail-exception / browser / 24h operations. S05 adds post-admit original-copy process. Same 졸업증명서 deadline conflict as above. |
| document choices | COVERED | KU2027-S01 필수 / 선택 / 해당자 필수 columns on p.12–14 |
| standardized tests / language | COVERED | KU2027-S01 p.15 (공인어학성적·표준화학력자료, 5-item cap, score reporting, predicted/best-score exclusion). No minimum score in the guide. FAQ Home Edition / ID·PW items are year-unbound NEEDS_REVIEW |
| cautions | COVERED | KU2027-S01 p.4, 6–7, 15; S04 interview cautions |
| citations | COVERED | Physical page map in §5 is sufficient to plan `file_page_number` / `printed_page_label` for the primary guide |

PARTIALLY_COVERED would be used if a domain existed only in FAQ or post-admit notices. Core application-time domains are in the primary guide. The 졸업증명서 deadline conflict does not reduce overall source coverage below COVERED; it remains an unresolved fact for ROW_MAP.


## 9. Gaps / Needs Review

1. **KU2027-S10 FAQ year-binding** — 특별전형 FAQ exists and includes 재외국민(정원외2%) answers, but items are not labeled 2027학년도 (`WRITE_DATE` displays `0025.04.25`). Status remains **NEEDS_REVIEW**. Do not use S10 as an automatic initial ROW_MAP fact source unless 2027 applicability is confirmed against the 2027 요강.
2. **졸업예정자 졸업증명서 제출 기한** — explicit unresolved official-source conflict among KU2027-S01, KU2027-S05 HTML, and KU2027-S05 PDF (§7). ROW_MAP must treat this fact as **needs_review**. Keep all citations. Do not normalize a single deadline in this inventory.
3. **XLSX sample** — `교내활동확인서 글자수(byte) test.xlsx` is officially described as a sample that may differ from the live application form. Sheets/cells were not inspected. Do not derive the 100-byte rule from the XLSX; that rule is already on KU2027-S01 p.12 / p.15.
4. **Form file internals** — ZIP member names are inventoried; field-level contents of DOC/HWP/PDF forms were not extracted.
5. **Post-admit follow-on notices** — KU2027-S05 points to later 문서등록 / 등록금 안내 posts that were “추후 공지”. Those future notices are not in this inventory.
6. **Interview building** — not in the primary guide; only in KU2027-S04. Decide at ROW_MAP whether 우당교양관 is stored as a 2027 cycle schedule fact or omitted as one-cycle logistics.
7. **Non-target programs in the same PDF** — keep 전교육/북한이탈 pages out of target ROW_MAP except common-rule citations listed in §5.
8. **세종** — no 서울 source may be taken from `/sejong/` even if search results mix campuses.


## 10. Readiness for ROW_MAP

**A. Ready for KU 2027 ROW_MAP**

The current official 21-page 특별전형(전기) 모집요강 (KU2027-S01, 2026.06.10 배포용 / 2026.06. 수정) covers the target program’s core identity, eligibility, evaluation, schedules, required documents, submission rules, standardized-test handling, and cautions with physical page locations.

Supplemental notices (S02–S05) exist for templates and cycle operations. They do not block mapping of core facts from the primary guide.

Ready for ROW_MAP does **not** mean every fact is fully resolved.

**Safeguards:**

1. S06 is a historical revision, not a current fact source.
2. Graduation-certificate deadline conflict must remain needs_review.
3. S10 FAQ is not used unless 2027 applicability is confirmed.

ROW_MAP must also:

- cite KU2027-S01 for current 요강 facts, not KU2027-S06
- review inventory-level mapping `S01.supersedes_source_document_id` → S06 before setting any DB FK
- use 1-based physical pages from §5
- keep 전교육과정해외이수자(전기) and 북한이탈주민 out of the target program
- connect all 졸업증명서-deadline citations; do not resolve the conflict in SQL

This inventory does not authorize DB inserts.
