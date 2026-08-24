# DB_SCHEMA_VALIDATION_KU_2027

이 문서는 `docs/DB_SCHEMA_DRAFT.md`가
실제 2027학년도 고려대학교 서울캠퍼스
재외국민(정원외2%)전형 구조를
정보 손실 없이 표현할 수 있는지 검증한다.

이 문서는 production dataset이 아니다.
실제 database, SQL, migration, seed data를 만들지 않는다.

검증일: 2026-08-23

이번 결과는 다음 하나의 사례에 한정된다.

- academic_year: 2027
- 고려대학교 서울캠퍼스
- 재외국민(정원외2%)전형

이 결과를 전체 고려대 전형,
다른 학년도, 다른 대학으로 일반화하지 않는다.


# 1. Validation Target

| 항목 | 값 |
| --- | --- |
| University | 고려대학교 |
| Campus | 서울캠퍼스 |
| academic_year | 2027 |
| Official AdmissionProgram | 재외국민(정원외2%)전형 |

이번 validation에서 production scope로 mapping하지 않는 대상:

- 전교육과정해외이수자전형
- 북한이탈주민전형
- 고려대학교 세종캠퍼스
- 다른 학년도

동일 모집요강 안의 다른 전형 정보는
문서 구조를 이해하는 비교 참고로만 언급한다.


# 2. 문서 목적

질문:

현재 DB_SCHEMA_DRAFT가
실제 2027 고려대 재외국민(정원외2%)전형의
구조를 정보 손실 없이 표현할 수 있는가?

모집요강 전체를 복사하지 않는다.
table별 구조적 pattern과 representative row만 기록한다.

실제 값을 적을 때는
공식 source page/section을 함께 적는다.

확인할 수 없는 사항은
"확인할 수 없음" 또는 "추가 확인 필요"로 기록한다.
추측하지 않는다.


# 3. Source Register

규정 근거는 고려대학교 서울캠퍼스
공식 입학처 자료만 사용했다.

블로그, 학원, 카페, SNS, 커뮤니티,
검색 결과 요약은 사용하지 않았다.


## S1. 2027학년도 특별전형 모집요강

| 필드 | 값 |
| --- | --- |
| source title | 2027학년도 특별전형 모집요강 |
| issuing organization | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| source type | 대학 공식 모집요강 PDF |
| official URL | https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf |
| publication/update | 입학처 메인 특별전형 공지 제목: 2027학년도 특별전형(전기) 모집요강(2026.06. 수정), 게시일 2026.06.10 |
| document version | 공지 제목에 2026.06. 수정이 명시됨. PDF 파일 경로에 202605 문자열이 있음. 입학처 메인 Quick Link는 2027학년도 특별전형 전기 모집요강 2026.05.29 update로 표시됨 |
| last checked date | 2026-08-23 |
| pages | PDF file pages 21 |
| validation 목적 | AdmissionProgram, Section, Document, Schedule, Citation, revision 구조 검증 |

PDF 표지(file page 1)에
서울캠퍼스와
재외국민(정원외2%)전형,
전교육과정해외이수자(전기)전형,
북한이탈주민전형이 함께 표시된다.

revision/version 관점:

- "2026.06. 수정"은 실제 공식 입학처에서 확인된 수정본 표시다.
- 이전 버전 PDF의 URL/파일은 이번 검증에서 확인하지 못했다.
- previous source document not confirmed.
- document_version_label과 supersedes 개념은 적합해 보이나
  실제 lineage row를 완전히 구성할 수는 없다.


## S2. 입학처 메인 페이지

| 필드 | 값 |
| --- | --- |
| source title | 고려대학교 서울캠퍼스 입학처 메인 |
| issuing organization | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 해당 페이지는 여러 학년도 공지를 함께 보여 줌. 2027 규정 근거로 다른 학년도 공지 본문을 사용하지 않음 |
| source type | 대학 입학처 공식 홈페이지 |
| official URL | https://oku.korea.ac.kr/oku/index.do |
| publication/update | 페이지 조회일 2026-08-23 기준 공지 목록 |
| last checked date | 2026-08-23 |
| validation 목적 | campus 식별, 모집요강 수정 표시, 후속 공지 존재 확인 |

페이지 상단에 "서울캠퍼스 입학처"가 표시된다.


## S3. 후속 공식 공지 — 파일업로드 안내

| 필드 | 값 |
| --- | --- |
| source title | 2027학년도 특별전형(전기) 파일업로드 - A4 변환 안내 |
| issuing organization | 고려대학교 서울캠퍼스 입학처 |
| academic_year | 2027 |
| source type | 대학 입학처 공식 공지 |
| official URL | https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?MENU_ID=750&CONTENTS_NO=&SITE_NO=2&BOARD_SEQ=5&BBS_SEQ=1801 |
| publication/update | 게시일 2026.08.19 |
| last checked date | 2026-08-23 |
| validation 목적 | 모집요강과 별도 official supplemental SourceDocument 사례 확인 |

입학처 메인 공지 목록뿐 아니라
개별 공식 게시 페이지가 존재한다.

같은 게시 페이지에 첨부 PDF가 존재한다.
첨부 파일명:
2027학년도 특별전형(전기) 파일업로드 - A4 변환 안내(참조 사진 포함).pdf

이 source는 production admission rule로 해석하지 않는다.
본문/첨부 세부 내용을 추가 schema 결론으로 확대하지 않는다.

모집요강 S1과 별도 SourceDocument 후보다.


## S4. 비교 참고로만 확인한 공지

입학처 메인에 다음 공지가 보인다.
이번 production mapping의 규정 값으로 사용하지 않는다.

- 2027학년도 특별전형(재외국민(정원외2%), 북한이탈주민) 1단계 합격자 발표, 게시일 2026.07.29
- 2027학년도 특별전형(전기) 원서접수 안내, 게시일 2026.07.02

개별 게시물 URL과 본문은 확인할 수 없음.
program 전체에 관련된 후속 공지가
모집요강 외에도 존재할 수 있음을 보여주는 비교 참고다.


## 사용하지 않은 자료

- 고려대학교 세종캠퍼스 자료
- 2026학년도 전교육과정해외이수자(후기) 모집요강 및 관련 공지
- 입학전형시행계획
- 블로그, 학원, 카페, SNS, 커뮤니티 요약


# 4. University Mapping

table: universities

representative row 개념:

| field | mapping |
| --- | --- |
| id | `<generated UUID>` 개념만. 실제 UUID를 생성하지 않음 |
| name_ko | 고려대학교 |
| name_en | 공식 영문 표기는 PDF 우편 주소에 Korea University가 있음. 이번 row의 확정 name_en으로 단정하지 않음 |
| campus_name | 서울캠퍼스 |
| display_name | 이번 validation에서 별도 값을 만들지 않음. UI 표시명은 이후 결정 |
| slug | PK가 아님. 실제 slug 값을 확정하지 않음 |
| official_website_url | 이번 검증의 규정 근거로 사용하지 않음. 추가 확인 필요 |
| admissions_office_url | https://oku.korea.ac.kr |
| created_at / updated_at | 운영 필드. 입시 규정이 아님 |

근거:

- PDF 표지 file page 1: 서울캠퍼스
- 입학처 메인: 서울캠퍼스 입학처
- PDF file page 21: 서울캠퍼스 입학처, https://oku.korea.ac.kr

질문:
현재 University + campus_name 구조로
서울캠퍼스를 세종캠퍼스와 명확하게 분리할 수 있는가?

평가: 조건부 가능

이유:

- 서울캠퍼스 입학처와 모집요강이 캠퍼스를 명시하므로
  campus_name으로 구분하는 방향은 이 사례와 맞다.
- 세종캠퍼스 공식 자료를 이번 검증에서 사용하지 않았으므로
  세종 row의 실제 필드 값을 만들지 않는다.
- University uniqueness constraint는
  이번 사례 하나만으로 최종 확정하지 않는다.


# 5. AdmissionCategory Mapping

MVP 내부 분류:

"3년 특례 관련"

공식 AdmissionProgram 명칭:

재외국민(정원외2%)전형

둘은 같은 값이 아니다.

AdmissionCategory.code 실제 값은 생성하지 않는다.

평가:

AdmissionCategory 1 → N AdmissionProgram
관계는 이 사례에서 자연스럽다.

같은 내부 분류 아래
다른 대학의 공식 전형명이 올 수 있다.
공식 명칭을 category code로 대체하면 안 된다.


# 6. AdmissionProgram Mapping

table: admission_programs

representative row 개념:

| field | mapping |
| --- | --- |
| id | `<generated UUID>` 개념만 |
| university_id | 고려대학교 서울캠퍼스 University row |
| admission_category_id | "3년 특례 관련" 내부 분류. 실제 code 미생성 |
| academic_year | 2027 |
| official_program_name | 재외국민(정원외2%)전형 |
| display_name | 이번 validation에서 별도 값을 만들지 않음 |
| admission_slug | routing key 후보. 실제 값을 확정하지 않음 |
| information_type | official_fact |
| verification_status | 이 문서는 schema 검증이지 production 검증 완료가 아님. 상태 값을 확정하지 않음 |
| verified_at | 이 mapping의 자료 확인일 개념은 2026-08-23. production verified_at으로 확정하지 않음 |
| notes | 동일 요강에 다른 전형이 함께 수록됨. 이번 row 범위는 재외국민(정원외2%)전형만 |

근거:

- PDF 표지 file page 1
- PDF 본문 여러 절에서 동일 명칭 사용
- 본문 일부는 "재외국민(정원외 2%)"처럼 공백이 있는 표기도 있음.
  official_program_name의 정규화 규칙은 추가 확인 필요.
  이번 mapping은 표지 표기 재외국민(정원외2%)전형을 사용한다.

현재 하나의 AdmissionProgram으로
전형 전체를 자연스럽게 표현할 수 있는가?

평가: 가능

이유:

- 지원자격, 단계별 평가, 재직 증빙, 면접 일정이
  이 전형 단위로 독립되어 있다.
- 비교 참고: 전교육과정해외이수자전형은 면접이 없고 일괄 서류 100%다.
  같은 요강에 있어도 다른 AdmissionProgram 후보다.
  이번 production mapping에는 넣지 않는다.

계열/모집단위별 차이가 있어
Program보다 작은 구조가 필요한가?

평가: 지금은 AdmissionTrack을 추가하지 않는다.

확인된 계열/모집단위 차이:

- 면접 유형이 인문/자연/의학과 예능에서 다름
  (PDF file page 19 / printed 19)
- 포트폴리오는 디자인조형학부 필수
  (PDF file page 13 / printed 13)
- 전형료가 예능과 그 외로 다름
  (PDF file page 20 / printed 20)

이 차이는 같은 AdmissionProgram 안의
조건/내용 차이로 먼저 평가한다.
AdmissionTrack 자동 해결로 가정하지 않는다.


# 7. AdmissionProgram UNIQUE Test

후보:

(university_id, academic_year, admission_slug)

이 사례에서 routing constraint로 문제가 있는지:

평가: 이 한 program만 보면 routing uniqueness는 가능해 보인다.

구분:

routing uniqueness
= 같은 대학/학년도에서 admission_slug가 하나이면
  URL 충돌 없이 조회할 수 있음

semantic identity
= 공식 전형 자체의 의미 단위.
  official_program_name 표기 차이(공백 유무)가
  다른 program을 만들지 않는지가 핵심.
  이번 한 사례만으로 확정하지 않음

historical identity
= slug가 바뀌어도 id는 유지되어야 함.
  slug는 PK가 아님

한 사례만으로 판단 불가능한 부분:

연세대 반대 검증 필요.


# 8. AdmissionSection Mapping

table: admission_sections

같은 section_type을 여러 row로 나눌 필요가 있다.

representative row 개념:

| section_type | title 개념 | source |
| --- | --- | --- |
| eligibility | 지원자격 공통 | PDF file page 8-9 / printed 8-9, Ⅳ. 지원자격 1. 공통 |
| eligibility | 재외국민(정원외2%) 고유 요건 | PDF file page 10 / printed 10, Ⅳ. 지원자격 2. 재외국민(정원외 2%) |
| evaluation | 전형요소 및 반영비율 | PDF file page 18 / printed 18 |
| evaluation | 서류평가 안내 | PDF file page 19 / printed 19 |
| evaluation | 면접평가 안내 | PDF file page 19 / printed 19 |
| caution | 원서접수 유의사항 | PDF file page 4 / printed 4 |
| caution | 지원자 유의사항 / 학교폭력 조치사항 | PDF file page 6-7 / printed 6-7 |
| other_conditions | 최종합격자 제출 서류 | PDF file page 6 / printed 6 |

공통 자격 텍스트는
비교 참고로 전교육과정해외이수자와 같은 절에 있다.
이번 production row는
재외국민(정원외2%)전형이 사용하는 공통 절만 연결한다.
전교육과정 고유 요건(file page 11)은 mapping하지 않는다.

평가:

현재 AdmissionSection 구조는
이 전형의 주요 정보 구조를 표현할 수 있다.

UNIQUE(admission_program_id, section_type)는
이 사례와 맞지 않는다.


# 9. Conditional AdmissionSection Test

확인된 적용 범위 차이:

면접평가 표는 계열별로 다르다.

- 인문 / 자연 / 의학: 제시문 기반 면접, 준비시간 10분, 면접시간 5분, 대면, 서울캠퍼스
- 예능: 제출서류 기반 면접, 준비시간 없음, 면접시간 5분, 대면, 서울캠퍼스

근거: PDF file page 19 / printed 19, Ⅴ. 면접평가 안내

포트폴리오/전형료도 모집단위 또는 계열 조건이 있다.
서류는 RequiredDocument.condition으로 볼 수 있다.
면접 차이는 현재 AdmissionSection에
별도 applicability field가 없다.

평가: B

현재 title/content만으로 표 전체를 저장할 수는 있다.
그러나 계열/모집단위 적용 범위가
first-class 조건이 아니면
조회·비교 시 본문 해석에 의존하게 된다.

AdmissionSection에
condition / applicability_scope와 같은
nullable 적용범위 개념이 필요할 가능성이 있다.

별도 child structure(C)나 AdmissionTrack을
이번 사례의 자동 해결책으로 보지 않는다.

새 field는 지금 DATA_MODEL/schema에 추가하지 않는다.
validation gap으로만 기록한다.

연세대 counter-validation 후 최종 결정한다.


# 10. RequiredDocument Structural Inventory

table: required_documents

실제 문서 목록 전체를 전사하지 않는다.
재외국민(정원외2%)전형에서 확인된
서로 다른 구조적 pattern만 적는다.

| pattern | 공식 자료에서 확인된 예 | source |
| --- | --- | --- |
| 항상 필수 | 학력조회 동의서, 중·고 학력서류, 가족관계증명서 | file page 12-13 / printed 12-13 |
| 해당자 필수 | 학교과정 특이사항 증빙서류, 개인정보 변경확인요청서, 교내활동증빙서류 | file page 12-13 / printed 12-13 |
| 선택 | 국외고교 School Profile, 교내활동확인서 | file page 12 / printed 12 |
| 특정 재직 유형에만 필수 | 국외파견 / 현지법인 취업 / 현지 자영업별 재직 증빙 조합 | file page 14 / printed 14 |
| 여러 문서 중 하나 | 국외 초등학교 성적·재학증명서는 둘 중 하나만 제출 가능 | file page 12 / printed 12 |
| 제출 주체가 다름 | 출입국사실증명서, 여권 사본, 재외국민등록부 등본을 지원자·부·모 기준으로 제출 | file page 13 / printed 13 |
| 온라인 제출 후 합격 시 원본 | 원서 시 업로드, 최종합격자 원본 우편 제출 | file page 4, 6, 12 / printed 4, 6, 12 |
| 추가 보완서류 | 지원자격 확인 목적 또는 기타 필요 시 추가 요구 가능 | file page 6 / printed 6 |
| 모집단위 한정 필수 | 디자인조형학부 포트폴리오 및 서약서 | file page 13 / printed 13 |
| 병합 제출 | 일부 서류를 지원자·부·모 순서로 하나의 PDF로 병합 | file page 13 / printed 13 |

북한이탈주민 서류의 "택1" 학력 구조는
비교 참고로만 보았고 production mapping하지 않는다.


# 11. RequiredDocument Field Pressure Test

현재 필드:
name, description, requirement_status, condition,
submission_phase, display_order,
verification_status, verified_at

| 질문 | 평가 |
| --- | --- |
| 1. "A 또는 B" 선택 구조를 표현 가능한가? | condition 텍스트로는 가능. 선택 그룹을 구조적으로 묶는 field는 없다. |
| 2. 지원자/부/모 제출 주체를 구조적으로 표현할 필요가 있는가? | 이 전형에서는 반복된다. condition 텍스트로 표현은 가능하나 first-class field는 없다. |
| 3. 재직 유형별 조건은 condition으로 충분한가? | 현재 자료에서는 condition으로 표현 가능해 보인다. |
| 4. 같은 논리적 문서의 온라인/원본 재제출을 한 row로 둘 것인가? | 논리적 document는 하나다. 제출 단계가 다르므로 한 row의 단일 submission_phase로는 부족하다. phase마다 document row를 복제하는 것은 추천하지 않는다. |
| 5. submission_phase 단일 값으로 충분한가? | 이 사례만 보면 충분하지 않다. phase/method는 document와 분리하는 편이 맞다. |

해결책을 확정하지 않는다.
Schema Gap으로 기록한다.


# 12. Document Submission Model Test

공식 자료의 제출 단계:

- 원서접수 시 온라인 업로드
  (file page 4 / printed 4, 2026.07.06 10:00 ~ 07.09 17:00)
- 입력/업로드 기간 이후 수정 불가
- 최종합격자 원본 우편 제출
  (file page 4 / printed 4, 2027.02.10까지)
- 원서 업로드 파일과 원본이 다르면 합격/입학 취소
  (file page 6 / printed 6)

후보 비교:

| 기준 | A. submission_phase 하나만 | B. phase마다 RequiredDocument row 복제 | C. 별도 submission child/relation |
| --- | --- | --- | --- |
| 중복 | 낮음. 한 단계가 유실됨 | document identity/condition/citation/verification 반복 | 낮음 |
| 의미 명확성 | 두 단계를 한 값에 넣으면 모호 | 단계는 나뉘나 같은 서류가 여러 identity를 가짐 | 논리적 서류와 제출 단계가 분리되어 명확 |
| source citation | 한 citation에 여러 쪽을 넣기 어려움 | page 4와 page 6을 row별로 연결 가능하나 문서 근거가 복제됨 | 서류 자체와 제출 event를 나눠 연결 가능 |
| verification | 한 verified_at으로 두 안내를 섞을 위험 | 단계별 재확인은 가능하나 같은 서류 검증이 갈라짐 | 서류 요건과 제출 안내를 분리 확인 가능 |
| UI query | 단순하나 단계 필터가 부정확 | 단순 | join 필요 |
| 유지보수 | 단순하나 정보 손실 | row 수 증가, 수정 시 불일치 위험 | table/relation 증가 |

provisional recommendation: C

RequiredDocument는
논리적 document requirement 자체를 표현한다.

submission phase / method / original requirement / schedule 등은
별도 submission child 또는 relation structure로 분리한다.

아직 새 table을 DB_SCHEMA_DRAFT에 추가하지 않는다.
실제 entity/table 이름은 확정하지 않는다.

B(phase마다 RequiredDocument row 복제)는
fallback 후보로만 남긴다. 추천안이 아니다.

이유:

같은 논리적 서류가

- 지원 단계에서 온라인 제출되고
- 최종합격 후 원본/확인된 원본 형태로 다시 제출되는

multi-phase pattern이 공식 자료에서 확인된다.

같은 document를 여러 row로 복제하면
document identity, source citation, condition,
verification, maintenance 중복 위험이 생길 수 있다.

연세대 counter-validation 후 최종 결정한다.


# 13. AdmissionSchedule Mapping

table: admission_schedules

모든 일정을 전사하지 않는다.
재외국민(정원외2%)전형과 관련된
distinct time pattern만 적는다.

| pattern | 공식 자료 예 | source |
| --- | --- | --- |
| 시작/종료 시각이 있는 기간 | 원서접수 2026.07.06.(월) 10:00 ~ 07.08.(수) 17:00 | file page 4 / printed 4 |
| 시작/종료 시각이 있는 기간 | 온라인 서식 입력 및 서류제출 07.06 10:00 ~ 07.09 17:00 | file page 4 / printed 4 |
| 특정 날짜까지 deadline | 최종합격자 원본서류 제출 2027.02.10.(수) 까지 | file page 4 / printed 4 |
| 특정 시각의 발표 | 1단계 합격자/고사장발표 07.31.(금) 17:00 | file page 5 / printed 5 |
| 특정 시각까지 입실 | 면접 08.14.(금) 12:30까지 입실 | file page 5 / printed 5 |
| 특정 시각의 발표 | 최초합격자발표 09.04.(금) 17:00 | file page 5 / printed 5 |
| 시작/종료 시각이 있는 기간 | 문서등록 12.21.(월) 10:00 ~ 12.23.(수) 14:00 | file page 5 / printed 5 |
| 특정 시각까지 deadline | 1차 충원 문서등록 12.24.(목) 14:00까지 | file page 5 / printed 5 |
| 변경 가능성이 명시된 일정 | 지원 인원에 따라 일정이 연장 혹은 변경될 수 있음 | file page 4-5 / printed 4-5 |
| 날짜 구간, 시각 미기재 | 신입생 등록금 납부기간 2027.02.15.(월)~02.16.(화) | file page 5 / printed 5 |

연도는 표에 생략된 칸이 있다.
원서/면접/최초합격은 문맥상 2026년으로 읽히고
원본제출·등록금은 2027년으로 명시되어 있다.
생략된 연도를 추측해 채우지 않고,
표에 연도가 없는 칸은 추가 확인이 필요하다고 본다.

비교 참고:
전교육과정해외이수자 면접 칸은 비어 있다.
이번 program row에는 면접 일정을 넣는다.


# 14. Date-only vs Time-specific Test

고려대 공식 자료에는
time-specific 일정과
date/deadline 형태가 함께 있다.

위험:

- 자정으로 임의 변환하면 사용자가 잘못 이해할 수 있다.
  예: 2027.02.10까지를 02.10 00:00으로 바꾸면
  그날 하루가 제외된 것처럼 보일 수 있다.
- end_at NULL이
  단일 발표인지, 종료 미정인지 구분되지 않는다.
- 시각이 있는 항목은 한국시간으로 읽는 것이 자연스럽다.
  timezone 미지정 시 해석이 달라질 수 있다.

후보 비교:

A. 모든 schedule을 timestamptz로 표현
= 날짜만 있는 deadline을 임의 시각으로 채워야 함. 위험.

B. date-only와 timestamp를 별도 field로 표현
= 명확하나 column이 늘어남.

C. schedule precision/type discriminator를 둠
= date / datetime / deadline 등을 구분해
  해당 필드만 채울 수 있음.

D. 다른 구조
= 이번 한 사례만으로 새 구조를 확정하지 않음.

provisional recommendation:

- date-only와 time-specific schedule을 의미적으로 구분해야 한다.
- precision/type discriminator가 필요할 가능성이 높다.
- 그러나 discriminator만 추가한 채
  모든 값을 timestamptz로 저장하는 구조는
  date-only 일정에 임의의 시각을 생성할 위험이 있다.
- discriminator만으로 충분한지는 미확정이다.
- date field와 timestamptz field를 분리하는 방식 등을
  연세대 counter-validation에서 비교한다.

SQL type이나 최종 column 구조는 아직 확정하지 않는다.


# 15. Evaluation Structure Test

재외국민(정원외2%)전형 평가 구조:

- 1단계 서류 100%, 모집단위별 모집인원의 3배수 선발
- 2단계 1단계 성적 70% + 면접 30%
- 서류평가는 역량별 비율이 표로 제시됨
- 면접은 계열에 따라 방식이 다름

근거: PDF file page 18-19 / printed 18-19

현재 schema에는
evaluation_stage / evaluation_component table이 없다.

평가: C

MVP에서는 AdmissionSection.content로
단계와 비율 표를 저장할 수 있다.

비교 기능을 위해 지금 structured evaluation child가
필수라고 단정하지 않는다.

향후 필요하지만
초기 migration에서는 불필요하다.

새 table은 만들지 않는다.


# 16. SourceDocument Revision Test

현재 official admissions site에서
2027학년도 특별전형(전기) 모집요강이
"2026.06. 수정"으로 표시된다.

| 관찰 | 값 |
| --- | --- |
| 공지 제목 | 2027학년도 특별전형(전기) 모집요강(2026.06. 수정) |
| 게시일 | 2026.06.10 |
| Quick Link | 2027학년도 특별전형 전기 모집요강 2026.05.29 update |
| PDF 경로 | /attach/202605/... |

document_version_label은 이 표시를 담을 수 있다.

supersedes_source_document_id 개념은 적합하다.

그러나 이전 version의 실제 URL/파일은
확인할 수 없으므로 만들어내지 않는다.

previous source document not confirmed

평가 구분:

- revision lineage concept: 적합
- 실제 lineage를 완전히 구성: 불가능 (이전 source 미확인)

latest published_at = current source라고
단정하지 않는다.
Quick Link의 2026.05.29와 공지의 2026.06. 수정이
같은 파일을 가리키는지 추가 확인 필요.


# 17. SourceCitation Page Test

PDF file page와
문서 내부 printed page label을
서로 다른 3개 이상 section에서 비교했다.

이번 validation에서 file_page_number 기준을 결정한다.

정의:

file_page_number
= PDF 파일의 physical page 순번, 1부터 시작
  (1-based physical PDF page number)

printed_page_label
= 문서 안에 실제 인쇄된 page number 또는 label

두 값은 독립적이다.

표지/목차처럼 printed_page_label이 없더라도
file_page_number는 존재할 수 있다.

PDF parsing library나 screenshot API에서
0-based index를 사용하는 것은 implementation concern이다.
database source citation 값과 혼동하지 않는다.

확인한 대응:

| 내용 | file_page_number | printed_page_label | header |
| --- | --- | --- | --- |
| 원서접수 및 전형 일정 | 4 | 4 | Ⅱ. 원서접수 및 전형 일정 \| 4 |
| 재외국민 지원자격 | 10 | 10 | Ⅳ. 전형 세부안내 \| 10 |
| 제출서류 상세 | 12 | 12 | Ⅳ. 전형 세부안내 \| 12 |
| 전형요소 및 반영비율 | 18 | 18 | Ⅴ. 평가관련 안내사항 \| 18 |

추가 관찰:

- file page 1 표지: printed_page_label을 확인할 수 없음. file_page_number는 1이다.
- file page 2 목차: printed page로 3부터 본문을 안내함
- file page 3부터는 이번 PDF에서
  1-based file page와 printed label 숫자가 같다

따라서 두 개념을 항상 같다고 가정하면 안 된다.

평가:

SourceCitation의
file_page_number / printed_page_label / section / anchor_description
분리는 이 PDF citation에 적합하다.

기존 단일 page 필드는 충분하지 않다.

G-KU-06은 이 결정으로 해결된 것으로 본다.


# 18. Citation Relation Test

conceptual mapping:

| target | citation 개념 | source |
| --- | --- | --- |
| AdmissionSection eligibility 고유 요건 | SourceDocument S1 + file page 10 / printed 10 / section Ⅳ.2 | S1 |
| RequiredDocument 재직 증빙 | S1 + file page 14 / printed 14 / section 재직 증빙서류 | S1 |
| AdmissionSchedule 원서접수 | S1 + file page 4 / printed 4 / section 원서 접수 및 서류 제출 일정 | S1 |

EligibilityRule 실제 logic은 만들지 않는다.

평가:

explicit join table은
이 mapping에서 과도한 중복을 강제하지 않는다.

같은 SourceCitation을
여러 schedule row가 재사용할 수 있다.
예: file page 5의 전형별 일정 표를
면접/합격발표 schedule이 공유.

모든 RequiredDocument 항목에
개별 citation을 강제하면 운영 부담이 커진다.
같은 절을 묶어서 인용하는 편이 현실적이다.


# 19. Program ↔ Source Direct Relation Test

A.
Program → child → SourceCitation → SourceDocument

B.
A + AdmissionProgram ↔ SourceDocument 직접 join

질문과 이 사례의 관찰:

전형 상세의 공식 출처 전체 목록은
citation에서 derive할 수 있다.
단, 모든 사용 source가 child citation으로 연결되어야 한다.

S3 A4 변환 안내는
모집요강과 다른 별도 official supplemental notice다.
개별 공식 게시 페이지와 첨부 PDF가 실제로 존재한다.

이 사례는
AdmissionProgram ↔ SourceDocument 직접 relation의 필요성을
고려대 validation에서 다소 강화한다.

의미를 구분한다.

Program ↔ SourceDocument direct relation
= 이 official source가 어떤 AdmissionProgram에 적용되는지 표현

SourceCitation relation
= 특정 fact/section/document/schedule의 근거 위치 표현

두 semantic purpose가 다르면
반드시 two sources of truth라고 볼 필요는 없다.

S3 본문/첨부 세부 내용은
추가 schema 결론이나 production rule로 확대하지 않는다.

실제 direct join 포함 여부는
연세대 counter-validation까지 open으로 유지한다.


# 20. Verification Test

| 상황 | 현재 구조로 표현 | 주의 |
| --- | --- | --- |
| 1. 모집요강 전체를 검토한 날 | AdmissionProgram.verified_at | 전체 검토가 끝났을 때만 갱신 |
| 2. 이후 별도 공식 공지가 추가된 경우 | 새 SourceDocument.last_checked_at | program verified_at 자동 갱신 금지 |
| 3. 특정 제출서류 안내만 다시 확인 | RequiredDocument.verified_at 또는 해당 SourceCitation.verified_at | 서류 일부 확인을 전형 전체 검증으로 보지 않음 |
| 4. 수정 모집요강이 발견된 경우 | 새 SourceDocument row + version/supersedes 개념 | 이전 source 삭제/덮어쓰기 금지. program 자동 재검증 금지 |

평가: 적합

program-level verified_at이
거짓으로 최신화되지 않으려면
운영 규칙이 schema와 같아야 한다.
필드만으로는 자동 갱신을 막지 못한다.
이는 구현/운영 규칙이지
이번 한 사례로 새 field를 만들 이유는 아니다.


# 21. Availability / Status Test

이번 mapping에서
재외국민(정원외2%)전형의 공식 최저 어학기준을
별도 필수 요건 절로 확인하지 못했다.

공인성적표는
원서에 입력한 경우 해당자 필수로 제출하는 서류다.
(file page 12, 15 / printed 12, 15)

이를 "어학 점수를 요구하지 않음"으로 바꾸지 않는다.

평가:

not_found_in_official_source
not_applicable
unknown
needs_confirmation

개념은 이 구분에 충분해 보인다.

실제 status value를 새로 추가하지 않는다.


# 22. Duplicate Analysis

| 데이터 | 반복 양상 | 구분 |
| --- | --- | --- |
| 공통 eligibility | 요강에서 전교육과정과 같은 절을 공유 | 정상. 이번 production은 한 program만 저장 |
| RequiredDocument 제출 단계 | 같은 논리적 서류가 온라인/원본 단계로 반복 | 정상 pattern. document row 복제가 아니라 submission 분리로 다루는 편이 맞음 |
| source citation | 같은 쪽을 여러 schedule/document가 참조 | 정상. citation 재사용 |
| 동일 일정 | 북한이탈주민과 면접/발표를 같은 표에 둠 | 비교 참고. 이번 program만 저장하면 중복 아님 |
| 계열별 evaluation | 한 표 안의 조건 차이 | 정상. program을 쪼갤 중복이 아님 |

불필요한 schema duplication으로 보지 않는다.


# 23. Schema Gap Register

실제 공식 자료에서 확인된 gap만 기록한다.

| ID | Entity | official-source pattern | current limitation | Severity | Possible Direction | SQL 전 해결? | 연세대 검증? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G-KU-01 | admission_sections | 면접 방식이 계열에 따라 다름 (file/printed 19) | applicability/condition field 없음 | medium | title/content에 표를 두거나 condition/applicability_scope 검토. AdmissionTrack으로 가정하지 않음 | no | yes |
| G-KU-02 | required_documents | 국외 초등 성적·재학 중 하나만 제출 (file/printed 12) | A 또는 B 그룹을 묶는 구조 없음 | medium | condition 텍스트 또는 이후 alternative group 검토 | no | yes |
| G-KU-03 | required_documents | 지원자/부/모가 각각 제출 (file/printed 13) | submitter first-class field 없음 | medium | condition 텍스트로 우선 표현 | no | yes |
| G-KU-04 | required_documents | 같은 논리적 서류가 지원 단계 온라인 제출 후 최종합격 원본 재제출 (file/printed 4, 6, 12) | 단일 submission_phase로 두 단계 표현이 어려움. phase별 document 복제는 identity 중복 위험 | medium | provisional C: RequiredDocument는 논리 요건, submission phase/method/original/schedule은 별도 child 또는 relation. 새 table 이름 미확정. B는 fallback | yes | yes |
| G-KU-05 | admission_schedules | time-specific 기간과 date-only deadline이 혼재 (file/printed 4-5) | start_at/end_at만으로는 precision이 모호. discriminator만으로 모든 값을 timestamptz에 넣으면 임의 시각 생성 위험 | high | date-only와 time-specific을 의미적으로 구분. discriminator 필요 가능성 높음. date field와 timestamptz 분리 등은 연세대에서 비교. SQL type 미확정 | yes | yes |
| G-KU-06 | source_citations | 표지/목차는 printed label이 없고 본문은 file=printed 숫자 | 이전에는 0-based/1-based가 미정의였음 | resolved | file_page_number = 1-based physical PDF page. printed_page_label은 독립. library 0-based index는 implementation concern | no | no |
| G-KU-07 | source_documents | 2026.06. 수정 표시는 있으나 이전 파일 미확인 | supersedes 대상 row를 구성할 수 없음 | low | version_label 유지. 이전 source를 만들지 않음 | no | no |

억지로 추가한 gap은 없다.
G-KU-06은 해결된 것으로 표시한다.
남은 주요 gap은 G-KU-01 ~ G-KU-05, G-KU-07이다.


# 24. Over-modeling Register

이 한 전형을 표현하는 데 지금 불필요할 수 있는 것:

- eligibility_rules table을 초기 migration에 넣는 것
- evaluation_stage / evaluation_component 정규화
- campuses table
- AdmissionTrack
- 모든 citation join table을 한 번에 만드는 것.
  이번 mapping에 필요한 것은
  section / document / schedule 수준이다.
- 모든 RequiredDocument 항목에 개별 citation 강제
- is_current boolean을 지금 확정하는 것
- status 값을 더 세분하는 것

program-source 직접 join은
S3 같은 official supplemental notice 때문에
필요성이 다소 강화되었다.

다만
Program↔Source는 적용 문서 목록,
SourceCitation은 사실 단위 근거로
목적이 다를 수 있다.
반드시 two sources of truth라고 보지 않는다.
포함 여부는 연세대 검증까지 open이다.


# 25. Open Decision Results

DB_SCHEMA_DRAFT open decisions를
이번 고려대 검증 후 분류한다.

| 항목 | 분류 | 메모 |
| --- | --- | --- |
| UUID | D. defer beyond initial migration | 이 사례가 PK 전략을 바꾸지 않음. recommended default 유지 |
| University uniqueness | C. keep open until Yonsei validation | campus_name 분리는 조건부 가능. unique는 미확정 |
| AdmissionProgram UNIQUE | C. keep open until Yonsei validation | routing 후보는 문제 없어 보임. semantic UNIQUE 미확정 |
| RequiredDocument ↔ Schedule | C. keep open until Yonsei validation | submission child/relation과 함께 검토. 지금 FK 미확정 |
| document submission structure | B. provisional recommendation | C: 논리 서류와 submission 분리. B 복제는 fallback. 연세대 후 최종 |
| Program ↔ Source direct join | C. keep open until Yonsei validation | A4 변환 안내 같은 supplemental notice로 필요성 강화. 미확정 |
| status implementation | D. defer beyond initial migration | TEXT + CHECK 추천 유지. 새 값 없음 |
| academic_year type | B. provisional recommendation | integer 2027이 이 사례와 맞음 |
| date-only vs timestamptz schedule | B. provisional recommendation | 의미적 구분 필요. discriminator만으로 충분여부는 미확정. SQL type 미확정 |
| ON DELETE | D. defer beyond initial migration | 이 mapping이 삭제 정책을 검증하지 않음 |
| citation join scope | B. provisional recommendation | 초기에는 section/document/schedule join이면 충분 |
| EligibilityRule initial migration | D. defer beyond initial migration | 실제 rule을 만들지 않음 |


# 26. Final Evaluation

평가: B. minor changes needed

DB_SCHEMA_DRAFT의 핵심 table 분할은
이 전형을 표현할 수 있다.

구조 전체를 바꾸는 C가 아니다.
한 사례만으로 A(그대로 사용)라고 단정하지 않는다.


## SQL 작성 전에 반드시 해결해야 하는 것

1. document multi-phase 구조
2. date-only vs time-specific schedule 구조
3. file_page_number 1-based 규칙은 해결 완료
4. AdmissionProgram + section_type unique 금지 유지


## 연세대 반대 검증 후 결정할 것

- University uniqueness
- AdmissionProgram semantic/routing UNIQUE
- AdmissionSection applicability
- RequiredDocument choice group
- RequiredDocument submitter/subject
- final document submission structure
- final schedule temporal structure
- Program ↔ Source direct join
- Document ↔ Schedule relation


## 초기 migration 이후로 미뤄도 되는 것

- EligibilityRule
- faqs / parent_stories
- evaluation child table
- Campus entity
- AdmissionTrack
- ON DELETE 상세
- index 최종 구성
- UUID 최종 확정
- 이전 모집요강 파일 lineage 완전 구성


# 27. 검증 한계

- 대학 1곳, 전형 1개, 학년도 1개만 분석함
- 전교육과정/북한이탈/세종/다른 학년도는 production mapping하지 않음
- A4 변환 안내의 개별 공식 게시 페이지와 첨부 PDF 존재는 확인함.
  본문/첨부 세부 내용은 production rule로 사용하지 않음
- 1단계 합격자 발표, 원서접수 안내 등 일부 후속 공지는
  제목/날짜만 확인함
- 이전 수정 전 모집요강 원본/URL은 확인하지 못함
- 일정표에서 연도가 생략된 칸의 연도를 채우지 않음
- official_program_name 공백 표기 차이의 정규화 규칙은 추가 확인 필요
- 세종캠퍼스 production row 값은 만들지 않음
- 따라서 이번 결과만으로 schema를 최종 확정하지 않음


# 28. 다음 단계

1. 결과 review
2. 필요한 경우 DB_SCHEMA_DRAFT 수정 제안
3. 2027 연세대학교 서울캠퍼스
   3년 특례 관련 전형으로 counter-validation
4. 두 validation 결과 비교
5. schema final decision
6. 그 후에만 SQL/migration 설계
