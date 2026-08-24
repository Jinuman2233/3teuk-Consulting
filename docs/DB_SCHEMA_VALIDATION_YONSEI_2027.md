# DB_SCHEMA_VALIDATION_YONSEI_2027

이 문서는 `docs/DB_SCHEMA_DRAFT.md`를
2027학년도 연세대학교 서울캠퍼스
재외국민전형[중·고교과정 해외 이수자]
공식 자료에 대입하여 반대 검증한다.

목적은 production data 입력이 아니다.
고려대학교 2027 schema validation에서 발견된 gap이
연세대에서도 반복되는지 확인하고,
두 대학 결과를 비교해 SQL 전에 확정할 수 있는 구조를 식별한다.

실제 database, SQL, migration, seed data를 만들지 않는다.
`docs/DB_SCHEMA_DRAFT.md`와 `docs/DATA_MODEL.md`는 수정하지 않는다.

검증일: 2026-08-24

이번 결과는 다음 하나의 사례에 한정된다.

- academic_year: 2027
- 연세대학교 서울캠퍼스
- 재외국민전형[중·고교과정 해외 이수자]

KU + Yonsei 두 사례만으로
모든 대한민국 대학 전형 구조를 일반화하지 않는다.


# 1. Validation Target

| 항목 | 값 |
| --- | --- |
| University | 연세대학교 |
| Campus | 서울캠퍼스 |
| academic_year | 2027 |
| Official AdmissionProgram | 재외국민전형[중·고교과정 해외 이수자] |

공식 명칭은 모집요강 표기 그대로 사용한다.
내부 사용자 분류 "3년 특례 관련"과 같은 값이 아니다.

이번 production-scope validation에서
AdmissionProgram으로 mapping하지 않는 대상:

- 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 글로벌인재대학 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 북한이탈주민전형
- 연세대학교 미래캠퍼스
- 다른 학년도

동일 모집요강 안의 다른 전형 정보는
문서 구조 이해를 위한 비교 참고로만 언급한다.


# 2. 문서 목적

핵심 질문:

"KU validation에서 발견된 schema gap들이 Yonsei에서도 반복되는가?"

모집요강 전체를 복사하지 않는다.
table별 구조적 pattern과 representative row만 기록한다.

실제 값을 적을 때는 공식 source page/section을 함께 적는다.

확인할 수 없는 사항은
"확인할 수 없음" 또는 "추가 확인 필요"로 기록한다.
추측하지 않는다.


# 3. Source Register

규정 근거는 연세대학교 서울캠퍼스 공식 입학처 자료만 사용했다.

블로그, 학원, 카페, SNS, 커뮤니티,
검색 결과 요약은 사용하지 않았다.


## S1. 2027학년도 3월 신입학 재외국민전형 모집요강 PDF

| 필드 | 값 |
| --- | --- |
| source title | 2027학년도 3월 신입학 재외국민전형 모집요강 |
| issuing organization | 연세대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| source type | 대학 공식 모집요강 PDF |
| official URL | https://admission.yonsei.ac.kr/seoul/upload/guide/20260529223906M8G4UJ.PDF |
| publication/update | 통합자료실 게시일 2026/05/29. PDF 파일 경로 날짜 문자열 20260529. PDF metadata CreationDate/ModDate 2026-05-26 13:51:21 +09:00 |
| document version | 제목/표지에 "수정" 표시는 확인되지 않음. 이전 2027 요강 파일도 확인되지 않음 |
| last checked date | 2026-08-24 |
| pages | PDF file pages 50 |
| validation 목적 | AdmissionProgram, Section, Document, Schedule, Citation, campus, source conflict 구조 검증 |

PDF 표지(file page 1)에 서울캠퍼스와
2027학년도 3월 신입학 재외국민전형 모집요강이 표시된다.

같은 요강 안에 비교 참고용으로 다음 전형이 함께 수록된다.

- 재외국민전형[중·고교과정 해외 이수자]
- 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 글로벌인재대학 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 북한이탈주민전형

같은 논리 source에 대한 official access surface는 여러 개다.

- 모집요강/서식 HTML page (S2)
- 통합자료실 posting (S3)
- 공식 PDF (S1)

S3 게시글에는 요강 PDF 첨부 링크가 있다.
그 첨부가 S1과 동일한 PDF binary인지는
이번 validation에서 확인하지 않았다.
복수 PDF URL alias가 실제로 존재한다고 단정하지 않는다.
SourceDocument alias table도 제안하지 않는다.

revision/version 관점:

- KU와 달리 공지 제목/표지에 "2026.06. 수정" 같은 수정본 표시는 없다.
- 이전 버전 PDF의 URL/파일은 확인하지 못했다.
- previous source document not confirmed.
- 수정본이 없다고 해서 revision structure가 불필요하다고 판단하지 않는다.


## S2. 공식 모집요강/서식 페이지

| 필드 | 값 |
| --- | --- |
| source title | 재외국민 > 모집요강/서식 |
| issuing organization | 연세대학교 서울캠퍼스 입학처 |
| academic_year | 페이지는 여러 학년도 배너/공지를 함께 보여 줌. 2027 규정 값으로 다른 학년도 배너 본문을 사용하지 않음 |
| source type | 대학 입학처 공식 안내 페이지 |
| official URL | https://admission.yonsei.ac.kr/seoul/admission/html/abroad/guide.asp |
| publication/update | 페이지 조회일 2026-08-24 기준. 이 페이지 자체의 게시일은 확인하지 못함 |
| last checked date | 2026-08-24 |
| validation 목적 | official application-guide page 구조, section index, campus/site 식별 |

페이지 목차(Contents Index):

- 전형 일정
- 원서접수 안내
- 모집단위 및 모집인원
- 지원자격
- 전형방법
- 제출서류
- 온라인 업로드 안내
- 면접평가 안내
- 각종 안내 사항
- 각종 서식

각 하위 절의 HTML 본문이 PDF와 동일한지,
또는 PDF만 제공하는지는 추가 확인 필요.
이번 규정의 상세 값은 S1 PDF를 사용한다.


## S3. 공식 통합자료실 게시글 — 요강 및 서식

| 필드 | 값 |
| --- | --- |
| source title | 2027학년도 3월 신입학 재외국민전형 요강 및 서식 내려받기 |
| issuing organization | 연세대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| source type | 대학 입학처 공식 통합자료실 게시글 |
| official URL | https://admission.yonsei.ac.kr/seoul/admission/html/counsel/dataView.asp?BBS_NO=3502&s_code=BBS_SUBJECT&s_data=2027&s_page=1 |
| publication/update | 작성일 2026/05/29 |
| last checked date | 2026-08-24 |
| validation 목적 | 한 게시물이 여러 AdmissionProgram과 관련 서식을 함께 제공하는 구조, official-source conflict |

게시 본문에서 확인된 대상전형 문구:

재외국민전형[중·고교과정 해외 이수자],
북한이탈주민전형,
재외국민전형[초·중·고교 전 교육과정 해외 이수자],
글로벌인재대학 재외국민전형[초·중·고교 전 교육과정 해외 이수자]

같은 게시 본문의 일정 문구:

- 원서접수: 2027. 7. 6. (월) 10:00 ~ 7. 8. (수) 17:00 (KST)
- 온라인 입력/서류 업로드: 2026. 7. 6. (월) 10:00 ~ 7. 9. (목) 17:00 (KST)
- ※ 전형 관련 세부사항은 요강을 반드시 확인하시기 바랍니다.

S1 PDF의 원서접수 연도(2026)와
이 게시글의 원서접수 연도(2027)가 다르다.
같은 게시글 안에서도 원서접수와 온라인 입력/업로드 연도가 다르다.
이 차이를 오타로 확정하지 않는다.
production interpretation은 #20 참조.

확인된 관련 공식 서식(게시글 첨부 라벨, 구조 평가용):

- 2027년도 3월 신입학 재외국민전형/북한이탈주민전형 요강
- 수학기간 기록표 [참고용]
- 비교과활동확인서
- Extracurricular Activity Confirmation Form
- 사유서
- 자기소개서(국문) [초 · 중·고교 전 교육과정 해외 이수자] [참고용]
- 자기소개서(영문) [초 · 중·고교 전 교육과정 해외 이수자 - UIC] [참고용]
- 자기소개서[북한이탈주민전형][참고용]
- 재외국민전형[중·고교과정 해외 이수자] - 개인정보수집·이용·처리위탁 동의서
- [합격자] 사실증명 발급 ·열람 신청서

모든 첨부서식을 production SourceDocument로
반드시 저장한다고 확정하지 않는다.
이번 production program에 해당하지 않는 자기소개서 서식은
mapping 대상 RequiredDocument가 아니다.


## S4. 공식 공지 — 원서접수 및 서류제출 안내

| 필드 | 값 |
| --- | --- |
| source title | 2027학년도 3월 신입학 재외국민전형 원서접수 및 서류제출 안내 |
| issuing organization | 연세대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| source type | 대학 입학처 공식 공지 |
| official URL | https://admission.yonsei.ac.kr/seoul/admission/html/counsel/noticeView.asp?BBS_NO=3501 |
| publication/update | 작성일 2026/05/29 |
| last checked date | 2026-08-24 |
| validation 목적 | S1/S3 일정 표기 비교, 한 공지가 여러 program에 적용되는 구조 |

본문 일정 원문:

- 온라인 원서접수: 2026.7.6.(월) 10:00 ~ 7.8.(수) 17:00 (KST)
- 수학기간기록표 및 자기소개서 입력: 2026.7.6.(월) 10:00 ~ 7.9.(목) 17:00 (KST)
- 제출서류 업로드: 2026.7.6.(월) 10:00 ~ 7.9.(목) 17:00 (KST)

이 공지의 원서접수 연도는 S1 PDF와 같다.
S3 통합자료실 요약의 2027 원서접수 표기와는 다르다.

대상 전형 4개를 한 공지에 함께 안내한다.
본문은 요강을 참고하라고 명시한다.

이 공지를 S1의 상세 규정을 대체하는 production rule로 사용하지 않는다.


## S5. 비교 참고 — 후속 공식 공지 존재

입학처 재외국민 공지 목록에서 다음이 확인된다.
본문 상세를 production rule로 사용하지 않는다.

- 2027학년도 3월 재외국민(중ㆍ고교과정 해외이수자, 북한이탈주민) 면접대상자 발표, 작성일 2026/08/24
  홈페이지 배너 링크: https://www2.yonsei.ac.kr/entrance/2027/jfore/jfore_2027_1/pass.asp
  개별 공지사항 noticeView BBS_NO는 이번 검증에서 확정하지 못함
- 2027학년도 3월 신입학 재외국민전형 비교과활동 확인서, 작성일 2026/05/13,
  https://admission.yonsei.ac.kr/seoul/admission/html/counsel/noticeView.asp?BBS_NO=3497
  본문은 열지 않음

이는 모집요강 외에 program 관련 후속/부가 official source가
존재할 수 있음을 보여주는 비교 참고다.


## S6. 캠퍼스 식별 비교 참고 — 미래캠퍼스 입학처 사이트

| 필드 | 값 |
| --- | --- |
| source title | 연세대학교 미래캠퍼스 입학 사이트 메인 |
| official URL | https://admission.yonsei.ac.kr/mirae/admission/html/main/main.asp |
| last checked date | 2026-08-24 |
| validation 목적 | 서울캠퍼스와 미래캠퍼스의 입학처 사이트 분리 확인 |

S1 PDF file page 6 / printed 3:

연세대학교 미래캠퍼스 재외국민전형에 중복지원할 수 있으며,
미래캠퍼스 모집일정 및 모집단위에 대한 사항은
미래캠퍼스 입학홍보처 홈페이지를 참조하기 바랍니다.

미래캠퍼스 사이트 footer는 Mirae Office of Admissions로 표시된다.
서울캠퍼스 사이트는 `/seoul` 경로를 사용한다.

미래캠퍼스 요강/일정 값은 이번 production mapping에 사용하지 않는다.


## 사용하지 않은 자료

- 연세대학교 미래캠퍼스 모집요강 및 입학홍보처 규정 본문
- 2026학년도 및 그 이전 재외국민전형 모집요강 PDF
- 입학전형시행계획
- 면접대상자 발표 페이지 본문/합격 여부
- 블로그, 학원, 카페, SNS, 커뮤니티 요약


# 4. University / Campus Mapping

table: universities

representative row 개념:

| field | mapping |
| --- | --- |
| id | `<generated UUID>` 개념만. 실제 UUID를 생성하지 않음 |
| name_ko | 연세대학교 |
| name_en | PDF 우편 영문 표기에 Yonsei University가 있음. 이번 row의 확정 name_en으로 단정하지 않음 |
| campus_name | 서울캠퍼스 |
| display_name | 이번 validation에서 별도 값을 만들지 않음 |
| slug | PK가 아님. 실제 slug 값을 확정하지 않음 |
| official_website_url | 이번 검증의 규정 근거로 사용하지 않음. 추가 확인 필요 |
| admissions_office_url | https://admission.yonsei.ac.kr/seoul |
| created_at / updated_at | 운영 필드. 입시 규정이 아님 |

근거:

- PDF 표지 file page 1: 서울캠퍼스
- PDF file page 50: 서울캠퍼스 주소, 입학처 전화, http://admission.yonsei.ac.kr
- 서울캠퍼스 입학처 사이트 경로 `/seoul`
- 미래캠퍼스 입학 사이트 `/mirae` 및 Mirae Office of Admissions footer
- PDF file page 6 / printed 3: 미래캠퍼스를 별도 입학홍보처 홈페이지로 안내

질문:
University + campus_name으로
서울캠퍼스와 미래캠퍼스를 안전하게 구분할 수 있는가?

평가: 조건부 가능

이유:

- 공식 입학처가 서울(`/seoul`)과 미래(`/mirae`)를 별도 사이트로 운영한다.
- 서울캠퍼스 요강이 미래캠퍼스 전형을 같은 요강 본문으로 규정하지 않고
  별도 홈페이지 참조로 돌린다.
- campus_name으로 구분하는 방향은 이 사례와 맞다.

University.campus_name
= 입학전형 운영 단위인 서울캠퍼스

면접 장소의 신촌캠퍼스
= AdmissionSchedule event venue/location
  (file page 4 / printed 1, file page 26 / printed 23)

신촌캠퍼스는 University identity gap이 아니다.
University row를 추가하거나 campus model을 변경할 근거가 아니다.
표지와 합격/원본서류 안내는 서울캠퍼스를 사용한다
(file page 1, file page 22 / printed 19, file page 29 / printed 26).

일정 장소 표기는 G-Y-03 AdmissionSchedule location representation으로 다룬다.

University uniqueness는 KU + Yonsei를 함께 보면
campus discriminator가 필요하다는 점은 반복된다.
실제 UNIQUE(name_ko, campus_name)는
nullable campus_name 때문에 아직 확정하지 않는다.
이 composite uniqueness는 추가 대학 검증까지 open이다.


# 5. AdmissionCategory Mapping

내부 사용자 분류:

3년 특례 관련

공식 명칭:

재외국민전형[중·고교과정 해외 이수자]

둘은 같은 값이 아니다.

AdmissionCategory.code 실제 값은 생성하지 않는다.

평가:

AdmissionCategory 1 → N AdmissionProgram
관계는 KU와 Yonsei 모두에서 자연스럽다.

같은 내부 분류 아래
고려대의 재외국민(정원외2%)전형과
연세대의 재외국민전형[중·고교과정 해외 이수자]가 올 수 있다.
공식 명칭을 category code로 대체하면 안 된다.


# 6. AdmissionProgram Mapping

table: admission_programs

representative row 개념:

| field | mapping |
| --- | --- |
| id | `<generated UUID>` 개념만 |
| university_id | 연세대학교 서울캠퍼스 University row |
| admission_category_id | "3년 특례 관련" 내부 분류. 실제 code 미생성 |
| academic_year | 2027 |
| official_program_name | 재외국민전형[중·고교과정 해외 이수자] |
| display_name | 이번 validation에서 별도 값을 만들지 않음 |
| admission_slug | routing key 후보. 실제 값을 확정하지 않음 |
| information_type | official_fact |
| verification_status | 이 문서는 schema 검증이지 production 검증 완료가 아님. 상태 값을 확정하지 않음 |
| verified_at | 이 mapping의 자료 확인일 개념은 2026-08-24. production verified_at으로 확정하지 않음 |
| notes | 동일 요강에 다른 전형이 함께 수록됨. 이번 row 범위는 재외국민전형[중·고교과정 해외 이수자]만 |

근거:

- PDF 표지 및 본문 여러 절의 동일 명칭
- Ⅲ. 모집단위 file page 7 / printed 4
- Ⅳ. 지원자격 file page 12 / printed 9
- Ⅴ. 전형방법 file page 14 / printed 11
- Ⅵ. 제출서류 file page 16 / printed 13

현재 하나의 AdmissionProgram으로
전형 전체를 자연스럽게 표현할 수 있는가?

평가: 가능

이유:

- 지원자격, 단계별 평가, 부모 재직 증빙, 면접 일정이
  이 전형 단위로 독립되어 있다.
- 비교 참고: 전교육과정/글로벌인재대학 전형은 일괄합산 서류 100%이며 면접이 없다.
  같은 요강에 있어도 다른 AdmissionProgram 후보다.
  이번 production mapping에는 넣지 않는다.

특정 모집단위 예외 때문에
AdmissionProgram 자체를 분리해야 하는가?

평가: 지금은 분리하지 않는다. AdmissionTrack도 자동 추가하지 않는다.

확인된 모집단위/대학 차이:

- 언더우드국제대학 소속 모집단위는 영어면접을 실시하지 않음
  (file page 14 / printed 11, file page 26 / printed 23)
- 언더우드국제대학 학부는 이 전형의 모집단위에 포함됨
  (file page 7-8 / printed 4-5)
- 추가합격자 발표는 이 전형에 한함
  (file page 4 / printed 1, file page 29 / printed 26)

이 차이는 같은 AdmissionProgram 안의
조건/내용 차이로 먼저 평가한다.
모집단위 예외만으로 program을 쪼개지 않는다.


# 7. AdmissionProgram UNIQUE Counter-test

후보:

(university_id, academic_year, admission_slug)

routing uniqueness:

이 한 program만 보면 가능해 보인다.
같은 대학/학년도에서 이 전형용 admission_slug가 하나이면
SITE_MAP의
`/universities/[slug]/admissions/[academicYear]/[admissionSlug]`
조회와 충돌하지 않는다.

semantic / historical identity:

slug로 정의하지 않는다.
slug는 historical identity가 아니다.
semantic/historical identity는 UUID PK다.

공식 전형명 표기 차이(공백, 괄호)의 정규화 규칙은
추가 대학 검증까지 open이다.

KU와 Yonsei 비교:

- 두 대학 모두 같은 학년도에
  재외국민 관련 공식 전형이 여러 개 있다.
- 따라서 university_id + academic_year + official_program_name만으로
  unique를 걸면 표기 정규화 위험이 있다.
- (university_id, academic_year, admission_slug)는
  두 사례 모두 routing uniqueness로 자연스럽다.

판단:

- routing UNIQUE 후보로 strong recommendation
- semantic/historical identity는 UUID PK
- semantic naming normalization은 추가 대학까지 open


# 8. AdmissionSection Mapping

table: admission_sections

같은 section_type을 여러 row로 나눌 필요가 있다.

representative row 개념:

| section_type | title 개념 | source |
| --- | --- | --- |
| eligibility | 재외국민전형[중·고교과정 해외 이수자] 고유 지원자격 | file page 12 / printed 9, Ⅳ.1 |
| eligibility | 지원자격 관련 유의사항 중 이 전형에 적용되는 공통 주의 | file page 13 / printed 10, 지원자격 관련 유의사항 |
| evaluation | 단계별 전형방법 | file page 14 / printed 11, Ⅴ.1 |
| evaluation | 동점자 처리 기준 | file page 15 / printed 12 |
| evaluation | 면접평가 유형 및 방법 | file page 26 / printed 23, Ⅷ |
| other_conditions | 복수 지원 가능 범위 / 수시 6회 제한 | file page 5-6 / printed 2-3 |
| other_conditions | 아포스티유 및 영사확인 | file page 27 / printed 24, Ⅸ |
| caution | 원서접수 유의사항 | file page 5 / printed 2 |
| caution | 전형 관련 유의사항 | file page 15 / printed 12 |
| caution | 면접 유의사항 | file page 26 / printed 23 |
| caution | 합격 및 등록 유의사항 | file page 29-30 / printed 26-27 |

실제 규정 전체를 복사하지 않는다.
eligibility가 여러 논리적 subsection으로 나뉜다.

- 학생/부모 국외근무·재학·체류 요건 (Ⅳ.1)
- 학제/기간 인정 원칙과 예외 (지원자격 관련 유의사항)
- 코로나19 소명 가능 안내

UNIQUE(admission_program_id, section_type)는
이 사례에서도 금지하는 편이 맞다.

language_requirement / standardized_tests:

이 전형에서 공식 최저 어학기준 절은 확인하지 못했다.
표준화학력평가자료 및 어학능력 증빙서류는
해당자/선택 제출 서류로 안내된다
(file page 17 / printed 14).
별도 필수 language_requirement section으로 만들지 않는다.
"어학을 요구하지 않음"으로 바꾸지 않는다.


# 9. Section Applicability Counter-test

KU 결과: 계열/모집단위에 따라 면접 방식이 달라
AdmissionSection applicability gap (G-KU-01).

Yonsei 관찰:

동일 AdmissionProgram 내부에서
특정 대학/모집단위에만 적용되는 평가 조건이 있다.

대표 사실:

- 전형방법 2단계 비고: 언더우드국제대학 소속 모집단위 영어면접 미실시
  (file page 14 / printed 11)
- 면접평가 안내 표: 재외국민전형[중·고교과정 해외 이수자]에
  ※ 언더우드국제대학 소속 모집단위 영어면접 미실시
  (file page 26 / printed 23)
- 언더우드학부(인문·사회), 융합인문사회과학부, 융합과학공학부가
  이 전형 모집단위에 포함됨
  (file page 7-8 / printed 4-5)

제출서류/자격 쪽:

- 개인정보수집·이용·처리위탁 동의서는 이 전형의 공통 서류이며
  제출 주체가 부·모다. 특정 모집단위 예외로 보지 않는다.
- 전교육과정 전형의 UIC 영어 자기소개서는
  이번 production program의 서류가 아니다. 비교 참고만.

평가: B. nullable applicability/condition 필요

A(불필요)는 이 사례와 맞지 않는다.
영어면접 미실시는 전형 전체가 아니라
언더우드국제대학 소속 모집단위에만 적용된다.
content 본문에만 두면
비교/필터에서 모집단위 조건을 구조적으로 구분하기 어렵다.

C(별도 structure)는 아직 과하다.
AdmissionTrack이나 모집단위 child table을
이 한 문장 예외만으로 만들지 않는다.

D(판단 불가)가 아니다.
KU와 같은 종류의 모집단위/계열 조건이 반복된다.

KU와 Yonsei 결과가 같으므로
core schema candidate로 승격한다.

SQL 전 결정:

문제를 표현할 구조가 필요함.

DB_SCHEMA refinement에서 결정:

별도 table인지 nullable field인지,
실제 field 이름.

아직 schema를 수정하지 않는다.

G-KU-01 분류: repeated at Yonsei. resolve before SQL.


# 10. Evaluation Structure Counter-test

이 전형은 단계별 평가 구조를 가진다.

대표 구조 (file page 14 / printed 11, file page 6 / printed 3):

- 1단계: 서류 100%, 모집인원 3배수 면접 대상 선발
- 2단계: 서류 70% + 면접 30%
- 대면 인성 면접
- 언더우드국제대학 소속 모집단위 영어면접 미실시
- 전형료 안내도 단계별로 표시되고, 1단계 불합격 시 2단계 전형료 반환

PDF 텍스트 추출에서 Ⅴ.1 표와 다른 전형 표가
페이지 레이아웃상 섞여 보일 수 있다.
단계별 구조의 근거는
전형료의 "단계별" 표시, 면접평가 장의 이 전형 전용 행,
1단계 불합격자 반환 안내를 함께 사용한다.

현재 AdmissionSection.content만으로
MVP 안내용으로 표현 가능한가?

평가: 초기 MVP 표시에는 content로 충분할 수 있다.

그러나:

- 1단계 / 2단계
- 서류 / 면접
- 특정 모집단위 예외

가 한 표에 같이 있다.
evaluation child table이 있으면 단계·반영비율·예외를
더 정확히 나눌 수 있다.

KU와 비교:

두 대학 모두 단계별 서류+면접이다.
초기 migration에서 evaluation child table을 만들 필요성은
높아졌지만, 아직 필수로 확정할 정도는 아니다.
applicability/condition을 section에 두는 편이
지금 더 직접적인 gap이다.

새 table은 만들지 않는다.
over-modeling 후보는 유지한다.


# 11. RequiredDocument Pattern Inventory

출처: Ⅵ·Ⅶ (file page 16-24 / printed 13-21),
최종합격자 원본 안내 (file page 22 / printed 19),
재직형태별 표 (file page 18 / printed 15)

확인된 structural pattern:

| pattern | 실제 존재 | 대표 예 | 현재 schema로 자연스러운가 |
| --- | --- | --- | --- |
| 필수 | 예 | 입학원서, 수학기간 기록표, 학력서류, 가족관계증명서 | requirement_status로 가능 |
| 선택 | 예 | 비교과활동 확인서, 출신 고등학교 프로파일 | requirement_status로 가능 |
| 해당자 | 예 | 사유서/증빙, 표준화학력·어학 자료, 이혼 시 추가 서류 | condition으로 부분 가능 |
| 대체 가능 | 예 | 재외한국학교 생활기록부로 재학/성적/졸업 대체, 졸업일을 성적증명으로 대체 | condition/description으로 느슨하게 가능. choice 구조는 없음 |
| A 또는 B | 예 | 해외직접투자신고서(허가서) 또는 해외지사설치인증서; 사업자등록증 또는 법인등기부등본; Official Transcript 권장, 불가 시 School Report | 현재 schema는 한 name 문자열에 넣거나 두 row를  Conditionally 두는 수준. choice_group 없음 |
| 재직 형태별 | 예 | 해외파견 / 현지취업 / 자영업 표, ○ / △ | condition으로 표현 가능. AdmissionTrack 불필요 |
| 지원자 / 부 / 모 | 예 | 재외국민등록부등본, 출입국 사실증명, 여권 발급기록 (지원자, 부, 모); 가족관계증명서(지원자); 개인정보 동의서(부, 모) | name 문자열에만 남음. submitter field 없음 |
| 특정 국적 조건 | 예 | 여권 발급기록: 대한민국 단일 / 복수 / 외국 단일 국적자 세트가 다름 | condition으로 가능 |
| 온라인 제출 | 예 | 원서접수 사이트 입력 또는 PDF 업로드 | submission_phase 하나로 두 단계와 방법을 동시에 담기 어려움 |
| 최종합격 후 원본 | 예 | 업로드한 서류의 원본을 2027.2.12.까지 서울캠퍼스 입학처 제출 | 같은 논리 서류의 두 번째 event |
| 추가 소명/증빙 | 예 | 사유서, 대학이 추가 증빙 요청 가능 | condition/notes로 가능 |
| 인증 방법 선택 | 예 | 아포스티유 / 영사확인 / 중국 학력인증 중 가능한 방법 (가~다) | choice 개념에 가깝다. 현재는 description |
| 제출 방법 분기 | 예 | IB·AP·ACT·IELTS·TOEFL·SAT는 스코어리포팅, 그 외는 스캔/캡처 | 같은 논리 서류의 다른 제출 방법·마감 |

현재 RequiredDocument 필드
name, description, requirement_status, condition, submission_phase
만으로는
필수/선택/해당자/재직조건은 비교적 자연스럽다.
choice, submitter, multi-phase, method별 마감은 부족하다.


# 12. Submitter / Subject Counter-test

KU G-KU-03 반복 여부: repeated at Yonsei

대표 사실:

- 가족관계증명서(지원자)
- 재외국민등록부등본 (지원자, 부, 모)
- 출입국에 관한 사실증명 (지원자, 부, 모)
- 여권 발급기록 증명서 (지원자, 부, 모)
- 개인정보수집·이용·처리위탁 동의서 (부, 모)
- 최종합격 후 출입국 사실증명 원본:
  중·고교과정 해외 이수자: 지원자, 부, 모
  (전교육과정은 지원자만 — 비교 참고, 이번 row 범위 아님)

  (file page 16-17 / printed 13-14, file page 22 / printed 19, file page 24 / printed 21)

document name 문자열 일부로만 남는 것이 충분한가?

평가: 충분하지 않다.
두 대학에서
지원자 / 부 / 모 / 지원자·부·모
패턴이 반복되므로
submitter/subject를 표현할 구조가 필요하다.
core schema candidate이며 SQL 전에 방향을 결정한다.

구분:

- SQL 전: 문제를 표현할 구조가 필요함
- DB_SCHEMA refinement: 별도 table인지 nullable field인지,
  최종 enum/lookup 여부. 실제 field 이름은 미확정

필드/entity는 아직 만들지 않는다.


# 13. Choice / Alternative Document Counter-test

KU G-KU-02 반복 여부: repeated at Yonsei

확인된 대체/선택 패턴:

- 해외직접투자신고서(허가서) 또는 해외지사설치인증서
- 사업자등록증 또는 법인등기부등본
- 현지취업자: 법인세 납부 이력이 어려우면 개인 세금 납부 이력 (△)
- 재외국민등록부 제출 불가 시 체류 대체서류
- 재외한국학교 생활기록부 대체
- 졸업(예정)증명을 졸업일이 적힌 성적증명으로 대체
- Official Transcript 권장, 불가 시 School Report
- 학력 확인: 아포스티유 또는 영사확인 또는 중국 학력인증 (가~다)

requirement_status + condition + description만으로 충분한가?

평가: 느슨하게는 가능하나
"한 요건을 여러 서류 중 하나로 충족"을
query/검증하기는 어렵다.

choice/alternative group을 표현할 구조가 필요한지:

두 대학에서 반복되므로 core schema candidate다.
SQL 전에 "문제를 표현할 구조가 필요함"을 결정한다.

구분:

- SQL 전: choice/alternative group 표현이 필요함
- DB_SCHEMA refinement: 별도 table인지 nullable field/condition인지.
  최종 구현과 실제 이름은 미확정

별도 table/field는 아직 만들지 않는다.


# 14. Document Multi-phase Counter-test

매우 중요.

지원 시:

- 입학원서·수학기간 기록표 등 온라인 입력
- 학력/체류/재직 서류 PDF 업로드
- 기간: 2026.7.6.(월) 10:00 ~ 7.9.(목) 17:00
  (file page 4 / printed 1, file page 16 / printed 13)

이후:

- 최종합격자는 업로드한 서류의 원본 및 추가 원본을
  2027.2.12.(금)까지 서울캠퍼스 입학처로 제출
  (file page 4 / printed 1, file page 22 / printed 19)
- 고교 서류는 원서 단계 스캔 업로드 후
  최종합격 시 아포스티유/영사확인 원본
  (file page 21 / printed 18)

같은 논리적 document가
여러 submission event를 가진다.

추가 event:

- 스코어리포팅 대상 시험은
  2026.7.9.(목) 17:00(KST)까지 연세대학교 도착
  (file page 17 / printed 14)
  업로드가 아니라 기관 발송이다.

KU + Yonsei에서 같은 논리 document가
여러 submission phase를 갖는 pattern이 반복되었다.

strong recommendation:

RequiredDocument
= logical document requirement

Submission structure
= phase / method / original requirement / schedule

평가: B. Yonsei에서도 반복.
core schema candidate. SQL 전 resolve.

아직 DB_SCHEMA_DRAFT를 수정하지 않는다.
실제 table 이름과 field는
DB_SCHEMA_DRAFT refinement에서 결정한다.

G-KU-04 분류: repeated at Yonsei


# 15. Submission Model Comparison

후보:

A. RequiredDocument.submission_phase 하나
→ insufficient

B. phase별 RequiredDocument 복제
→ fallback, duplication risk

C. document와 submission 분리
→ recommended core schema direction

KU + Yonsei 비교:

| 기준 | A | B | C |
| --- | --- | --- | --- |
| duplicate | 한 필드에 두 phase를 못 담음 | 서류 identity가 단계마다 복제됨 | 논리 서류 1개 유지 |
| document identity | 단계가 필드 값이 되어 identity가 흔들림 | 같은 성적증명이 두 row | 유지에 가장 유리 |
| citation | 같은 쪽을 두 번 인용하기 애매 | row마다 citation 반복 | 논리 서류와 submission에 나눠 인용 가능 |
| verification | 원본 제출만 재확인해도 서류 전체가 갱신된 것처럼 보임 | 한쪽만 재검증하기는 쉬우나 복제 비용 | child verified_at에 맞음 |
| UI query | "필수 서류 목록"과 "지금 낼 것"이 섞임 | 단계 필터는 쉬우나 목록이 두 배 | 목록/단계 분리 query에 유리 |
| schedule 연결 | 한 schedule FK로는 부족 | 단계 row마다 FK | submission이 schedule과 연결되는 편이 자연스러움 |
| maintenance | 초안과 가장 가깝지만 두 사례 모두에서 부족 | fallback | 운영 테이블은 늘지만 중복이 줄어듦 |

strong recommendation: C

A는 KU와 Yonsei 모두에서 insufficient하다.
B는 fallback only이며 duplication risk가 있다.

SQL 전에 resolve해야 하는가?

예.
현재 draft의 submission_phase 단일 필드로는
두 대학의 온라인 업로드 + 최종합격 원본 구조를
정보 손실 없이 만들기 어렵다.

실제 table 이름과 field는
DB_SCHEMA_DRAFT refinement에서 결정한다.


# 16. AdmissionSchedule Counter-validation

확인된 temporal pattern만 기록한다.
출처: file page 4 / printed 1, file page 17 / printed 14,
file page 26 / printed 23, file page 29 / printed 26,
S3/S4 게시 문구.

| pattern | 대표 event | 값의 형태 |
| --- | --- | --- |
| 시작/종료 시각이 있는 기간 | 입학원서 접수 | 2026.7.6.(월) 10:00 ~ 7.8.(수) 17:00 |
| 시작/종료 시각이 있는 기간 | 온라인 입력/업로드 | 2026.7.6.(월) 10:00 ~ 7.9.(목) 17:00 |
| 시작/종료 시각이 있는 기간 | 최초합격자 문서등록 | 2026.12.21.(월) 10:00 ~ 12.23.(수) 14:00 |
| 특정 시각 발표 | 면접대상자 발표 | 2026.8.24.(월) 17:00 |
| 특정 시각 발표 | 합격자 발표 | 2026.9.7.(월) 17:00 |
| 날짜만 있는 행사 | 면접구술시험 | 2026.8.29.(토). 시각 없음. 장소는 신촌캠퍼스 지정장소 |
| 날짜까지만 명시된 deadline | 합격자 원본 서류 제출 | 2027.2.12.(금)까지 |
| 여러 날에 걸친 기간, 종료 시각만 있는 경우 | 본등록 | 2027.2.10.(수) ~ 2.12.(금) 16:00 |
| 여러 날에 걸친 기간, 일자만 있는 요약 | 추가합격자 발표 요약 | 2026.12.23.(수) ~ 12.29.(화) |
| 회차별 시각이 다른 기간 | 1~4차 추가합격 | 예: 1차 발표 12.23.(수) 20:00, 4차 12.29.(화) 10:00 ~ 16:00 개별통지 |
| 도착 시각이 있는 제출 deadline | 스코어리포팅 | 2026.7.9.(목) 17:00(KST)까지 도착 |

timezone:

S3/S4와 스코어리포팅은 KST를 명시한다.
전형일정 표의 모든 칸이 KST를 인쇄하지는 않는다.
timezone 필드는 nullable로 두는 현재 draft와 맞다.
없는 칸의 timezone을 추측해 채우지 않는다.

연도가 생략된 종료일
(예: 7.8.(수) 17:00)은
같은 행의 시작 연도를 따라가는 표 관례로 보인다.
이 문서에서 빈 연도를 채워 새 사실로 만들지 않는다.

장소/location:

면접구술시험 장소는 "연세대학교 신촌캠퍼스 지정장소"다
(file page 4 / printed 1, file page 26 / printed 23).
원본 서류 제출 장소는 서울캠퍼스 입학처 주소다
(file page 4 / printed 1, file page 22 / printed 19).

이것은 University.campus_name이 아니라
AdmissionSchedule event venue/location이다.

현재 schedule의 description만으로 저장할지,
nullable location_text 같은 개념이 필요한지는
DB_SCHEMA refinement에서 결정한다.
실제 field 이름은 아직 확정하지 않는다.
SQL 전에는 location 표현 필요성만 결정한다.
Gap ID: G-Y-03


# 17. Date-only vs Time-specific Counter-test

KU G-KU-05 반복 여부: repeated at Yonsei

비교:

- 원서접수/온라인 업로드: 날짜 + 시각
- 면접: 날짜만
- 합격자 원본서류 제출: 날짜만의 deadline
- 발표류: 날짜 + 17:00 또는 20:00

모든 값을 timestamptz만으로 저장하면
면접일 2026-08-29 00:00 같은 가짜 시각이 생긴다.
원본서류 마감 2027-02-12 00:00도
"그날 0시 마감"으로 오해될 수 있다.

구현 개념 비교:

A. timestamptz only
가짜 시각 위험이 두 대학에서 확인됨. 추천하지 않음.

B. date + timestamptz separate fields
date-only와 time-specific을 나눌 수 있다.
time-specific 기간은 start/end timestamp,
date-only는 start/end date가 필요하다.
precision을 필드 존재만으로 추론하면
null 의미(미정 vs 날짜만)가 겹칠 수 있다.

C. temporal_type/precision discriminator
+ 적절한 date/timestamp storage
두 대학의 혼재 패턴과 가장 잘 맞는다.
discriminator만으로 모든 값을 timestamptz에 넣는 것은
A와 같은 가짜 시각 문제가 남는다.
storage도 precision에 맞게 나눠야 한다.

D. 다른 구조
이번 두 사례만으로 새 모델을 만들지 않음.

KU + Yonsei 근거 strong recommendation: C

가짜 00:00 시간을 생성하는 방식은 추천하지 않는다.
SQL type은 아직 락하지 않는다.
이 결정은 SQL 전에 resolve해야 한다.


# 18. Document ↔ Schedule Relation

document submission 구조와 분리해 결정하지 않는다.

관찰:

- 논리 서류 하나(예: 고교 성적증명)가
  업로드 마감(2026.7.9. 17:00)과
  원본 마감(2027.2.12.)에 모두 연결됨
- 스코어리포팅은 같은 어학/표준화 자료 요건의
  다른 방법·다른 도착 일정
- 한 일정(온라인 업로드 기간)에 여러 서류가 묶임

RequiredDocument가 AdmissionSchedule과
직접 1:1 FK로 연결되어야 하는가?

평가: 직접 참조는 부족하다.

KU와 Yonsei 모두에서 더 자연스러운 구조:

RequiredDocument
→ submission
→ schedule

한 논리 서류가 여러 submission phase/일정을 갖고,
한 일정이 여러 서류에 적용되기 때문이다.

이를 SQL 전 resolve 항목으로 둔다.
RequiredDocument → AdmissionSchedule 직접 FK는 넣지 않는다.

G-KU Document↔Schedule: repeated at Yonsei


# 19. SourceDocument Mapping

최소 세 층위:

1. 공식 모집요강 PDF (S1)
   상세 규정의 primary rule source 후보.

2. 공식 모집요강 게시/안내 페이지
   - S2 guide.asp: section index
   - S3 통합자료실 게시글: 요강+서식 배포 단위
   - S4 원서접수 안내 공지: 요약 일정

3. 게시 페이지에서 제공되는 관련 공식 서식
   비교과활동확인서, 사유서, 개인정보 동의서 등.

질문: 각각을 SourceDocument로 어떻게 취급할 것인가?

평가:

- S1 PDF는 독립 SourceDocument가 맞다.
- S3 게시글은 PDF와 다른 HTML source다.
  요약 일정 conflict가 있으므로
  PDF와 같은 row로 합치면 안 된다.
- S2는 안내 허브 페이지다. 별도 SourceDocument로 둘 수 있으나
  규정 상세 citation의 기본 대상은 S1이다.
- 서식 파일은
  게시글의 첨부 또는 별도 SourceDocument 후보다.
  모든 첨부서식을 production에 저장한다고 확정하지 않는다.
  이번 program에 실제로 인용되는 서식만
  필요 시 SourceDocument로 둔다.

확인된 것은 같은 논리 source에 대한
multiple official access surfaces다.

- 모집요강/서식 HTML page
- 통합자료실 posting
- 공식 PDF

동일 PDF binary가 서로 다른 복수 URL로
실제로 제공되는지는 확인되지 않았다.
PDF URL alias 문제 또는 alias table을
확정된 schema gap으로 쓰지 않는다.


# 20. Official Source Conflict Test

직접 재확인한 결과, official-source inconsistency는 실제로 존재한다.

세 official source를 구분한다.

A. 공식 모집요강 PDF (S1)
원서접수: 2026.7.6 ~ 7.8
(file page 4 / printed 1)

B. 공식 원서접수 및 서류제출 안내 공지 (S4)
원서접수: 2026.7.6 ~ 7.8

C. 공식 통합자료실 모집요강 게시글 summary (S3)
원서접수: 2027.7.6 ~ 7.8
같은 게시글의 온라인 입력/업로드는 2026.7.6 ~ 7.9

임의로 하나로 정규화하지 않는다.
2027 표기를 오타라고 단정하지 않는다.
별도 정정 공지는 이번 검증에서 확인하지 못했다.

| source | field/fact | value shown | source priority 평가 | production interpretation | needs follow-up? |
| --- | --- | --- | --- | --- | --- |
| A. S1 모집요강 PDF file page 4 / printed 1 | 입학원서 접수 | 2026.7.6.(월) 10:00 ~ 7.8.(수) 17:00 | 상세 공식 모집요강 | production fact 2026의 근거 | C의 불일치 기록 유지 |
| A. S1 같은 표 | 온라인 입력/업로드 | 2026.7.6.(월) 10:00 ~ 7.9.(목) 17:00 | 동일 | production fact 후보 | C 온라인 항목과 연도는 같음 |
| C. S3 통합자료실 게시글 summary | 원서접수 | 2027. 7. 6. (월) 10:00 ~ 7. 8. (수) 17:00 (KST) | 공식 게시이나 요약. 같은 글의 다른 행과 연도가 다름 | production fact로 채택하지 않음. inconsistency로 보존 | 예. 정정 공지 여부 추가 확인 |
| C. S3 같은 게시글 | 온라인 입력/서류 업로드 | 2026. 7. 6. (월) 10:00 ~ 7. 9. (목) 17:00 (KST) | 같은 요약 글 | A와 연도는 일치. 글 내부 일관성은 없음 | 예. 내부 inconsistency 기록 |
| B. S4 원서접수 안내 공지 | 온라인 원서접수 | 2026.7.6.(월) 10:00 ~ 7.8.(수) 17:00 (KST) | 원서접수 전용 공식 공지. 요강 참고를 명시 | A와 일치. production fact 2026의 근거 | C 정정 여부 확인 |

두 질문을 분리한다.

1. official sources are inconsistent
   예. C의 원서접수 연도는 A/B와 다르고, C 내부에서도 2027/2026이 혼재한다.
   이 inconsistency 자체는 유지한다.

2. 어느 source를 production fact의 기준으로 사용할 것인가
   상세 모집요강 PDF(A)와
   원서접수 전용 공식 공지(B)가 모두 2026으로 일치한다.
   따라서 원서접수 일정의 production fact로 2026을 사용하는 것이
   source hierarchy 및 specificity 관점에서 타당하다.

   이유:
   - A는 상세 규칙 문서다.
   - B는 원서접수/서류제출 전용 공식 공지이며 A와 같다.
   - C 본문이 "전형 관련 세부사항은 요강을 반드시 확인"이라고 한다.
   - C 요약은 같은 글 안에서 이미 일관되지 않다.

AGENTS.md source priority는

1. 대학 입학처 공식 홈페이지
2. 대학 공식 모집요강

이다.
홈페이지와 요강이 충돌하면 단순 번호만으로 홈페이지 요약을 이기게 하면 안 된다.
이 사례에서 홈페이지는 단일 값이 아니라
S2/S3/S4가 함께 있다.
C 요약과 B 공지가 서로 다르므로
"홈페이지 값" 하나로 정규화할 수 없다.

A+B를 production fact로 쓰는 평가는
source policy 및 specificity와 모순되지 않는다.
C의 2027 표기를 삭제하거나 오타로 바꾸지 않는다.

schema 차원의 source_conflict entity가 필요한가?

평가: 현재 필요하지 않다.
기존 verification_status = needs_review와
notes/provenance로 충돌을 보존한다.
불필요한 normalization은 피한다.

기존 status로 표현:

- 해당 AdmissionSchedule의 production 값은 A+B 기준 2026
- C와의 차이는 needs_review + notes/provenance로 남김
- program 전체를 unverified로 내릴 필요는 없을 수 있음
- 새 status 값 "conflicted"를 지금 추가하지 않음

이건 KU에는 없었던 Yonsei 신규 gap이다.
Gap ID: G-Y-01


# 21. SourceCitation Page Test

KU 결정: file_page_number = 1-based physical PDF page.
Yonsei PDF에도 적용한다.

이 PDF는 표지/목차/변경사항 뒤에 본문 인쇄 쪽수가 시작한다.

| 내용 | file_page_number | printed_page_label | section |
| --- | --- | --- | --- |
| 전형일정 | 4 | 1 | Ⅰ. 전형 일정 |
| 지원자격 | 12 | 9 | Ⅳ. 지원자격 |
| 전형방법 | 14 | 11 | Ⅴ. 전형방법 |
| 제출서류 | 16 | 13 | Ⅵ. 제출서류 |

추가 확인:

- file page 1 표지: printed label 없음
- file page 2 목차: printed label 없음. 목차는 인쇄 쪽수로 장을 가리킴
- file page 3 주요 변경사항: printed label 없음
- file page 26 면접평가: printed 23, Ⅷ
- 본문 페이지는 대체로 file_page = printed_page_label + 3

KU에서 정한 1-based 규칙은 Yonsei에서도 자연스럽다.
physical page와 printed label이 다르므로
두 필드를 유지해야 한다.

library 0-based index는 implementation concern이다.


# 22. Citation Relation Counter-test

AdmissionSection, RequiredDocument, AdmissionSchedule에
SourceCitation conceptual mapping은 Yonsei에서도 자연스럽다.

explicit join table도 자연스럽다.
polymorphic entity_type+entity_id를 이 사례가 요구하지는 않는다.

같은 citation을 여러 entity에서 재사용할 수 있는가?

예.
전형일정 표(file page 4 / printed 1)는
원서접수, 온라인 업로드, 면접, 원본 제출 등
여러 AdmissionSchedule이 공유한다.

제출서류 장(file page 16 / printed 13)은
여러 RequiredDocument가 공유한다.

항목마다 citation row를 새로 만들면
과도한 duplication이 발생한다.
citation 재사용 + join table이 맞다.

모든 RequiredDocument 항목에
개별 citation을 강제하면 운영 부담이 커진다.
같은 절을 묶어서 인용하는 편이 현실적이다.

초기 migration 범위:
section / document / schedule join이면 이 사례에 충분하다.
EligibilityRule/FAQ citation은 아직 불필요하다.


# 23. Program ↔ Source Direct Relation Counter-test

KU: open. supplemental notice로 필요성 강화.

Yonsei 관찰:

S3 한 게시물이 네 AdmissionProgram과
program별로 다른 서식을 함께 제공한다.

- 요강 PDF: 4개 전형 공통
- 개인정보 동의서: 재외국민전형[중·고교과정 해외 이수자] 전용
- 자기소개서(국문/영문): 전교육과정/UIC용. 이번 production program 아님
- 북한이탈 자기소개서: 이번 production program 아님

의미 구분:

Program ↔ SourceDocument
= 어떤 official source가 해당 program에 적용되는지

Entity ↔ SourceCitation
= 특정 fact의 정확한 근거 위치

두 관계는 동일 source of truth가 아니다.
요강 PDF가 이 program에 적용된다는 것과
지원자격 9쪽을 citation하는 것은 다른 말이다.

S3에 첨부된 UIC 자기소개서를
citation이 없다고 해서 이 program source 목록에 올리면 안 된다.
direct relation이 있으면
"이 서식은 다른 program용"을 표현할 수 있다.

KU와 Yonsei 모두에서
모집요강, 별도 공지, 관련 공식 안내/서식이
한 AdmissionProgram에 적용될 수 있다.

결론: initial schema에
AdmissionProgram ↔ SourceDocument
direct N:N relation을 포함하는 방향을 권장한다.

"유용할 가능성"보다 강한 권장이다.
citation과 목적이 다르므로 자동 two sources of truth로 보지 않는다.

A(불필요)는 한 게시물-여러 전형-부분 서식 구조와 맞지 않는다.


# 24. Source Revision / Version Test

연세대 2027 재외국민 모집요강의 수정본/revision:

이번 검증에서 확인되지 않았다.

- S1 제목/표지에 수정 표시 없음
- 통합자료실/공지 목록에서 2027 요강 수정본 게시 미확인
- PDF metadata 작성일은 2026-05-26, 게시는 2026-05-29
  이 차이만으로 revision lineage를 만들지 않음
- 이전 2027 요강 파일 not confirmed

revision을 임의 생성하지 않는다.

KU 비교:

KU는 실제 "2026.06. 수정" 사례가 있었다.
Yonsei에 같은 패턴이 없다고 해서
revision structure가 불필요하지 않다.
두 대학을 합치면
document_version_label + supersedes 후보는 유지하고,
is_current boolean은 아직 두지 않는 편이 맞다.


# 25. Verification Workflow Counter-test

| 상황 | 현재 구조로 표현 | 주의 |
| --- | --- | --- |
| 모집요강 전체 확인 | AdmissionProgram.verified_at | 전체 검토가 끝났을 때만 갱신 |
| 별도 공식 게시물 확인 (S3/S4) | SourceDocument.last_checked_at | program verified_at 자동 갱신 금지 |
| 공식 서식 추가/변경 | 해당 서식 SourceDocument.last_checked_at | 요강 재검증으로 취급 금지 |
| source conflict 발견 (S3 vs S1) | 해당 schedule/citation needs_review + notes | program 전체를 verified로 올리지 않음. conflicted status는 추가하지 않음 |
| 특정 제출서류만 재확인 | RequiredDocument.verified_at 또는 SourceCitation.verified_at | 서류 일부 확인을 전형 전체 검증으로 보지 않음 |
| 면접대상자 발표 등 후속 공지 | 새 SourceDocument.last_checked_at | 요강 일정이 자동으로 최신이 되지 않음 |

평가: 계층 구조는 거짓 최신화를 피하는 데 적합하다.
필드만으로는 자동 갱신을 막지 못한다.
구현/운영 규칙이 필요하다.

S3 last_checked_at을 갱신했다고
S1 일정 fact가 재검증된 것은 아니다.


# 26. Status / Availability Counter-test

verification_status:

verified
partially_verified
needs_review
unverified

availability_status:

available
not_found_in_official_source
not_applicable
unknown
needs_confirmation

공식 source 간 conflict:

needs_review + notes로 표현 가능해 보인다.
S3 원서접수 2027 표기를
not_found_in_official_source로 두면 안 된다.
공식 source에 있는 값이다.
available도 단독으로는 충돌을 나타내지 못한다.

새 status를 지금 추가하지 않는다.
필요하면 gap으로만 기록한다.
G-Y-01의 표현 수단은 기존 needs_review가 우선이다.


# 27. KU Gap 재분류

| KU gap | Yonsei 분류 | 메모 |
| --- | --- | --- |
| G-KU-01 AdmissionSection applicability | repeated at Yonsei | UIC 영어면접 미실시 |
| G-KU-02 RequiredDocument choice group | repeated at Yonsei | A 또는 B, 대체, 가~다 인증 |
| G-KU-03 submitter/subject | repeated at Yonsei | 지원자 / 부 / 모 |
| G-KU-04 document multi-phase | repeated at Yonsei | 업로드 후 원본 |
| G-KU-05 date-only vs time-specific | repeated at Yonsei | 면접 날짜만, 접수/발표는 시각 |
| Program ↔ SourceDocument direct relation | repeated at Yonsei | 한 게시물-여러 전형-부분 서식 |
| University uniqueness | repeated at Yonsei | 서울/미래 분리. composite UNIQUE는 추가 대학까지 open |
| AdmissionProgram UNIQUE | repeated at Yonsei | routing UNIQUE는 strong recommendation. semantic/historical identity는 UUID PK |
| Document ↔ Schedule | repeated at Yonsei | RequiredDocument → submission → schedule |

insufficient evidence로 분류한 KU 주요 gap은 없다.
G-KU-06 file_page 1-based는 Yonsei에서도 자연스럽다.
G-KU-07 이전 요강 파일 미확인은 Yonsei에서도 이전 파일이 없다.
revision 사례 자체는 Yonsei에서 not observed이다.
structure 필요성까지 not observed로 내리지는 않는다.


# 28. KU vs Yonsei Gap Matrix

| Schema issue | KU result | Yonsei result | Repeated across both? | Core schema candidate? | Resolve before SQL? | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| 1. University campus identification | campus_name 조건부 가능. UNIQUE 미확정 | 서울/미래 사이트 분리. 신촌은 schedule location. UNIQUE 미확정 | campus 분리는 yes. 신촌 identity는 no | campus discriminator는 이미 draft에 있음. Campus table은 아님 | no | campus_name=서울캠퍼스 유지. name/campus composite UNIQUE는 추가 대학까지 open |
| 2. AdmissionProgram granularity | 한 program으로 충분. Track 불필요 | 한 program으로 충분. UIC 예외로 program 분리 불필요 | yes | 현재 AdmissionProgram 정의 유지 | no | Track 추가하지 않음 |
| 3. AdmissionProgram UNIQUE | routing 후보 OK | routing UNIQUE 자연스러움 | yes | routing UNIQUE | routing UNIQUE는 yes. naming normalization은 no | routing UNIQUE strong recommendation. semantic/historical identity는 UUID PK |
| 4. same-type AdmissionSection | 복수 eligibility 필요 | 복수 eligibility/evaluation/caution 필요 | yes | UNIQUE(program, section_type) 금지 | yes | 금지 유지 |
| 5. section applicability | 계열별 면접 차이 | UIC 영어면접 미실시 | yes | yes | yes | 표현 구조 필요. 최종 field 구조는 refinement |
| 6. RequiredDocument choice group | A 또는 B | A 또는 B, 대체, 가~다 | yes | yes | yes | 표현 구조 필요. 최종 table/field는 refinement |
| 7. submitter/subject | 지원자/부/모 | 지원자/부/모 반복 | yes | yes | yes | 표현 구조 필요. 최종 enum/lookup은 refinement |
| 8. document multi-phase | 온라인 후 원본 | 온라인 후 원본 + 스코어리포팅 | yes | yes | yes | RequiredDocument와 submission 분리 |
| 9. document submission model | provisional C | C 확인, strong recommendation | yes | yes | yes | C. A insufficient. B fallback |
| 10. date-only/time-specific schedule | 혼재, 가짜 시각 위험 | 혼재 반복 | yes | yes | yes | discriminator + date/timestamp 분리. timestamptz-only 금지 |
| 11. Document↔Schedule | submission과 함께 검토 | RequiredDocument → submission → schedule | yes | yes | yes | 직접 FK 금지. submission 경유 |
| 12. PDF file_page convention | 1-based physical page | 동일. file=printed+3 | yes (resolved) | 현재 citation 필드 유지 | no | 1-based 유지. resolved |
| 13. explicit citation join | section/document/schedule | 재사용 필요, 과잉 개별 citation 위험 | yes | 초기 3개 join | no | explicit join 유지. 전부 upfront 생성하지 않음 |
| 14. Program↔Source direct relation | 필요성 강화, open | 모집요강+공지+서식이 한 program에 적용 | yes | yes | yes | initial schema에 N:N 포함 권장. citation과 역할 분리 |
| 15. source revision lineage | 수정본 표시 있음, 이전 파일 없음 | 수정본 미확인 | 사례는 no, structure 필요는 유지 | version_label/supersedes 유지 | no | 임의 revision row 금지. self-FK 세부는 추가 대학까지 open |
| 16. verification hierarchy | 적합 | conflict 포함해도 적합 | yes | 현재 필드 유지 | no | 자동 갱신 금지. needs_review + notes |
| 17. official-source conflict handling | 해당 사례 없음 | A/B=2026, C=2027. inconsistency 유지 | no (Yonsei 신규) | 새 entity는 아님 | yes (정책) | production fact=2026 (PDF+전용 공지). C는 notes/needs_review. source_conflict table 없음 |
| 18. AdmissionSchedule location | 해당 사례를 campus identity로 보지 않음 | 면접 장소 신촌캠퍼스 vs 운영 단위 서울캠퍼스 | Yonsei에서 장소 표기 확인 | schedule location 표현 | yes (필요성) | University identity 아님. description vs location 개념은 refinement |


# 29. Schema Gap Register

실제 공식 자료에서 확인된 gap만 기록한다.
KU와 같은 문제는 새로운 문제처럼 과장하지 않고 confirmed/repeated로 표시한다.

| ID | Entity | official-source pattern | current limitation | Severity | repeated from KU? | possible direction | SQL 전 해결? | evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| G-KU-01 | admission_sections | UIC 소속 모집단위 영어면접 미실시 | applicability 표현 구조 없음 | medium | confirmed/repeated | SQL 전: 표현 구조 필요. refinement: nullable field vs 별도 structure. Track 아님 | yes | file page 14, 26 / printed 11, 23 |
| G-KU-02 | required_documents | A 또는 B, 대체 제출, 가~다 인증 | choice/alternative 표현 구조 없음 | medium | confirmed/repeated | SQL 전: 표현 구조 필요. refinement: table vs field. 최종 구현 미확정 | yes | file page 18, 16, 27 / printed 15, 13, 24 |
| G-KU-03 | required_documents | 지원자 / 부 / 모 | submitter/subject 표현 구조 없음 | medium | confirmed/repeated | SQL 전: 표현 구조 필요. refinement: field vs table, enum/lookup 여부 미확정 | yes | file page 16-17, 22, 24 / printed 13-14, 19, 21 |
| G-KU-04 | required_documents | 온라인 업로드 후 최종합격 원본. 스코어리포팅은 별도 도착 시각 | 단일 submission_phase 부족 | medium | confirmed/repeated | strong recommendation C: RequiredDocument와 submission 분리. table/field 이름은 refinement | yes | file page 4, 16, 17, 22 / printed 1, 13, 14, 19 |
| G-KU-05 | admission_schedules | 시각 있는 기간/발표와 날짜만 있는 면접·원본마감 혼재 | start_at/end_at timestamptz만이면 가짜 시각 | high | confirmed/repeated | precision discriminator + date/timestamp 분리 | yes | file page 4, 26, 22 / printed 1, 23, 19 |
| G-Y-01 | source_documents / admission_schedules / verification | A/B 원서접수 2026, C summary 2027. C 내부도 2027/2026 혼재 | 충돌을 지우면 공식 표기가 사라짐 | medium | no (Yonsei 신규) | production fact=2026 (PDF+전용 공지). inconsistency는 needs_review + notes/provenance. source_conflict entity 없음 | yes (정책) | S1 file page 4; S3 게시 본문; S4 공지 본문 |
| G-Y-02 | source_documents | 모집요강/서식 HTML, 통합자료실 posting, 공식 PDF 등 여러 official access surface | 같은 논리 source의 접근 면이 여러 개임. 동일 PDF binary의 복수 URL은 미확인 | low | no. 확인된 것은 access surface 다양성 | alias table 제안하지 않음. URL alias 필요 여부는 추가 대학까지 open | no | S1, S2, S3 |
| G-Y-03 | admission_schedules | 면접 장소 신촌캠퍼스. 원본 제출 장소 서울캠퍼스 입학처 | 현재 description만으로 장소를 둘지 미정 | low | no (Yonsei 신규). University identity gap이 아님 | SQL 전: location 표현 필요성 결정. refinement: description vs nullable location 개념. field 이름 미확정. campus model 변경 아님 | yes (필요성) | file page 4, 22, 26 / printed 1, 19, 23 |

억지로 추가한 gap은 없다.


# 30. Over-modeling Register

KU + Yonsei 두 사례 기준,
지금 과하거나 초기 migration에서 미룰 수 있는 것:

- Campus table
  두 대학 모두 campus discriminator로 충분해 보인다.
- AdmissionTrack
  UIC 예외, 재직형태, 전교육과정 비교 참고 모두 Track이 아니다.
- evaluation child tables
  단계별 평가는 있지만 section content + applicability로 우선.
- 모든 citation relation upfront 생성
  초기에는 section/document/schedule.
- EligibilityRule initial migration
  실제 deterministic rule을 만들지 않음.
- 과도한 status taxonomy
  conflicted 등 새 값을 지금 추가하지 않음.
- source_conflict entity
  한 건의 공식 충돌만으로 정규화하지 않음.
- 모든 첨부서식을 SourceDocument로 저장
  UIC/북한이탈 전용 서식까지 이 program에 넣지 않음.
- is_current boolean
- 면접 장소 신촌을 별도 University/Campus row로 만드는 것
- SourceDocument alias table
  복수 PDF URL binary가 확인되지 않았음

program-source 직접 N:N은
과한 정규화가 아니라
initial schema에 포함하는 방향을 권장하는 항목이다.


# 31. Open Decision Resolution

KU validation 후 open이었던 항목을
두 대학 결과로 재분류한다.

| 항목 | 분류 | 메모 |
| --- | --- | --- |
| UUID | D. defer after initial migration | recommended default 유지. semantic/historical identity |
| University uniqueness | C. keep open for Sogang/Hanyang/SKKU | campus_name 분리는 두 대학에서 필요. name/campus composite UNIQUE 미확정 |
| AdmissionProgram UNIQUE | B. routing UNIQUE strong recommendation. naming은 C | (university_id, academic_year, admission_slug) routing UNIQUE. semantic/historical identity는 UUID PK. naming normalization은 추가 대학 |
| AdmissionSection applicability | A. resolve before SQL | 두 대학 반복. 표현 구조 필요. 최종 field 구조는 refinement |
| RequiredDocument choice group | A. resolve before SQL (표현 방향) | 두 대학 반복. 구조 필요. 최종 table/field는 refinement |
| submitter/subject | A. resolve before SQL (표현 방향) | 두 대학 반복. 구조 필요. 최종 enum/lookup은 refinement |
| document submission structure | A. resolve before SQL | strong recommendation C. table/field 이름은 refinement |
| schedule temporal structure | A. resolve before SQL | timestamptz-only 폐기. discriminator + date/timestamp |
| Document↔Schedule | A. resolve before SQL | RequiredDocument → submission → schedule |
| Program↔Source direct join | A. resolve before SQL | initial schema에 N:N 포함 권장. citation과 역할 분리 |
| AdmissionSchedule location | A. resolve before SQL (필요성) | University identity 아님. description vs location 개념은 refinement |
| status implementation | D. defer after initial migration | TEXT + CHECK 유지. conflicted 추가하지 않음 |
| academic_year type | B. provisional decision strong enough | integer 2027이 두 사례와 맞음 |
| ON DELETE | D. defer after initial migration | 이 mapping이 삭제 정책을 검증하지 않음 |
| citation join scope | B. provisional decision strong enough | 초기 section/document/schedule |
| EligibilityRule initial migration | D. defer after initial migration | 실제 rule 없음 |
| official-source conflict policy | A. resolve before SQL | 새 table 없음. production fact=2026. needs_review + notes |
| SourceDocument URL alias | C. keep open | 동일 PDF binary 복수 URL은 미확인. alias table 없음 |


# 32. Final Counter-validation Evaluation

선택: C. structural changes needed before SQL

이유:

핵심 table 분할(University, Program, Section, Document, Schedule, Source, Citation)은
두 대학을 표현할 수 있다.
모델 전체를 폐기하는 수준은 아니다.

그러나 KU와 Yonsei에서 반복된 실제 pattern 때문에
현재 DB_SCHEMA_DRAFT에 최소한 다음 구조 변경이 필요하다.

- document submission abstraction
- schedule temporal redesign
- section applicability
- program-source applicability relation

추가로 SQL 전에 표현 방향을 정해야 하는 반복 gap:

- RequiredDocument submitter/subject
- RequiredDocument choice/alternative group
- DocumentSubmission ↔ Schedule
- AdmissionSchedule location 표현 필요성

이는 minor column 추가만으로 보기 어렵다.
SQL 전에 draft를 고쳐야 한다.

A(그대로 사용)는 두 사례와 맞지 않는다.
B(minor)는 KU 단독 평가에는 가능했으나,
반복 gap이 core change candidate가 되었으므로
이번 counter-validation의 종합은 C다.
D(추가 대학 없이는 판단 불가)는
SQL 전 항목 전체에 해당하지 않는다.
composite uniqueness, naming normalization,
submitter/choice/applicability의 최종 구현 형태만
추가 대학에 열어 둔다.


## SQL 전에 반드시 해결

1. DocumentSubmission 구조
   (C: RequiredDocument = logical requirement,
   submission = phase / method / original / schedule)
2. date-only/time-specific schedule 구조
3. AdmissionSection applicability 표현
4. RequiredDocument submitter 표현 방향
   (구조 필요. 최종 enum/lookup은 refinement)
5. RequiredDocument choice group 표현 방향
   (구조 필요. 최종 table/field는 refinement)
6. DocumentSubmission ↔ Schedule 관계
   (RequiredDocument → submission → schedule)
7. Program ↔ SourceDocument direct N:N
8. AdmissionSchedule location 표현 필요성
   (University identity 아님. field는 refinement)
9. same-type AdmissionSection unique 금지 유지

file_page_number 1-based 규칙은 이미 resolved다.

official-source conflict 정책도 SQL 전에 둔다.
새 entity 없이 production fact=2026,
C 표기는 needs_review + notes/provenance.


## 연세대 검증으로 충분히 결론 가능

- 한 AdmissionProgram 단위 유지, AdmissionTrack 없음
- routing UNIQUE 후보 (university_id, academic_year, admission_slug)
- semantic/historical identity는 UUID PK
- file_page_number 1-based physical page
- explicit citation join, citation 재사용
- verification_at 계층과 자동 갱신 금지
- academic_year integer
- Campus table / evaluation child table 초기 불필요
- 모든 서식을 SourceDocument로 저장하지 않음
- source_conflict entity 불필요
- DocumentSubmission C 방향
- Program↔Source N:N 포함 권장


## 추가 대학까지 열어둘 수 있음

- University name/campus composite uniqueness
- AdmissionProgram semantic naming normalization
- submitter의 최종 enum/lookup 여부
- choice group의 최종 table/field 구현
- applicability의 최종 field 구조
- SourceDocument revision self-FK 세부 구현
- SourceDocument URL alias가 실제 필요한지 여부

위 항목의 core capability 자체는
KU + Yonsei 반복 결과를 반영한다.
열어 두는 것은 최종 normalization/구현 형태다.


# 33. Important Limitation

이번 validation은

- 2027학년도
- 연세대학교 서울캠퍼스
- 재외국민전형[중·고교과정 해외 이수자]

한 사례에 대한 counter-validation이다.

KU + Yonsei 두 사례만으로
모든 대한민국 대학 전형 구조를 일반화하지 않는다.

전교육과정, 글로벌인재대학 재외국민, 북한이탈주민,
미래캠퍼스, 다른 학년도 값은 production mapping하지 않았다.


# 34. 다음 단계

1. 결과를 여기에서 review
2. KU vs Yonsei 반복 gap 확인
3. SQL 전 필요한 schema decision 확정
4. docs/DB_SCHEMA_DRAFT.md refinement
5. 필요 시 최소 추가 validation
6. SQL DDL / migration 설계
7. Supabase 구축

이번 작업에서는 위 4~7을 수행하지 않는다.
DB_SCHEMA_DRAFT는 수정하지 않는다.


# 35. 확인하지 못한 사항

- S3 첨부 요강 링크와 S1 PDF가 동일 binary인지
  (확인되지 않았으므로 복수 PDF URL alias로 단정하지 않음)
- S2 guide.asp 하위 절 HTML 본문이 PDF와 동일한지
- 2027 요강 수정본/정정 공지 존재 여부
- 면접대상자 발표 개별 noticeView BBS_NO
- 비교과활동 확인서 공지(BBS_NO=3497) 본문
- 미래캠퍼스 공식 campus_name의 확정 표기 값
- official_website_url 확정 값
- name_en 확정 값
- 일정표에서 연도가 생략된 칸을 채운 값
- 이 전형의 공식 최저 어학기준 별도 절 존재 여부
  (해당자 서류만 확인됨)
- S3 원서접수 2027 표기에 대한 별도 정정 공지
