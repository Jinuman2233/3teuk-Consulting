# DATA_MODEL_VALIDATION_2027

이 문서는 2027학년도 공식 모집요강을 사용해
현재 `docs/DATA_MODEL.md`가 실제 대학 전형 구조를
충분히 표현할 수 있는지 검증한다.

실제 production seed data가 아니다.
사용자에게 입시정보를 제공하기 위한 문서가 아니다.

모집인원, 합격선, 시험점수 등
모델 검증에 필요하지 않은 입시정보는 수집하지 않는다.

검증일: 2026-08-23

검증 범위:

- academic_year: 2027
- 연세대학교 서울캠퍼스
- 고려대학교 서울캠퍼스

연세대학교 미래캠퍼스와
고려대학교 세종캠퍼스 자료는 사용하지 않는다.

2026학년도 또는 다른 학년도 모집요강은
2027학년도 규정의 근거로 사용하지 않는다.


# 1. 문서 목적

이번 검증은 2027학년도 공식 모집요강을 사용해 다음을 확인한다.

- AdmissionProgram granularity
- AdmissionSection 구조
- RequiredDocument 구조
- AdmissionSchedule 구조
- SourceDocument / SourceCitation 구조
- verification 구조
- 향후 AdmissionTrack 필요성

이 문서는 실제 production seed data가 아니다.


# 2. 검증 Source Register

사용한 자료는 대학 입학처 공식 홈페이지와
해당 홈페이지에서 제공된 공식 모집요강/공지뿐이다.

블로그, 학원, 카페, SNS, 커뮤니티,
검색 결과 요약은 사실 근거로 사용하지 않았다.


## 2.1 연세대학교 서울캠퍼스

| 필드 | 값 |
| --- | --- |
| university | 연세대학교 |
| campus | 서울캠퍼스 |
| academic_year | 2027 |
| admission area | 재외국민전형 |
| source title | 2027학년도 3월 신입학 재외국민전형 모집요강 |
| official URL | https://admission.yonsei.ac.kr/seoul/upload/guide/20260529223906M8G4UJ.PDF |
| source type | 대학 공식 모집요강 PDF |
| official organization | 연세대학교 서울캠퍼스 입학처 |
| published/updated date | 공식 목록 페이지의 게시일은 이번 검증에서 직접 확인하지 못함. 공식 파일 경로의 날짜 문자열은 20260529. 확정 게시일은 확인 필요. |
| verified_date | 2026-08-23 |
| notes | PDF 표지에 서울캠퍼스가 명시되어 있음. 본문에서 미래캠퍼스 재외국민전형을 별도 홈페이지 참조로 구분하므로 미래캠퍼스 자료는 사용하지 않음. |

입학처 홈페이지:

https://admission.yonsei.ac.kr/seoul

대학 공식 홈페이지:

https://www.yonsei.ac.kr


## 2.2 고려대학교 서울캠퍼스

| 필드 | 값 |
| --- | --- |
| university | 고려대학교 |
| campus | 서울캠퍼스 |
| academic_year | 2027 |
| admission area | 특별전형(전기) |
| source title | 2027학년도 특별전형 모집요강 |
| official URL | https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf |
| source type | 대학 공식 모집요강 PDF |
| official organization | 고려대학교 서울캠퍼스 입학처 |
| published/updated date | 입학처 메인 공지: 2027학년도 특별전형(전기) 모집요강(2026.06. 수정), 게시일 2026.06.10 |
| verified_date | 2026-08-23 |
| notes | PDF 표지에 서울캠퍼스와 재외국민(정원외2%)전형, 전교육과정해외이수자(전기)전형, 북한이탈주민전형이 함께 표시됨. 세종캠퍼스 자료는 사용하지 않음. |

추가 공식 공지:

| 필드 | 값 |
| --- | --- |
| university | 고려대학교 |
| campus | 서울캠퍼스 |
| academic_year | 2027 |
| admission area | 특별전형(전기) 서류 제출 안내 |
| source title | 2027학년도 특별전형(전기) 파일업로드 - A4 변환 안내 |
| official URL | 입학처 메인 공지 목록에서 제목과 게시일(2026.08.19)을 확인. 개별 게시물 URL은 이번 검증에서 확정하지 못함. |
| source type | 대학 입학처 공식 공지 |
| official organization | 고려대학교 서울캠퍼스 입학처 |
| published/updated date | 2026.08.19 |
| verified_date | 2026-08-23 |
| notes | 모집요강 본문 외의 추가 공식 공지가 존재함을 확인. 공지 본문 상세는 확인 필요. |

입학처 홈페이지:

https://oku.korea.ac.kr/oku/index.do

입학처는 페이지에서 서울캠퍼스 입학처로 표시된다.


## 2.3 사용하지 않은 자료

다음 자료는 이번 2027 서울캠퍼스 검증의 규정 근거로 사용하지 않았다.

- 연세대학교 미래캠퍼스 입학홍보처 자료
- 고려대학교 세종캠퍼스 자료
- 연세대학교 입학처의 다른 학년도 재외국민전형 모집요강 PDF
- 고려대학교 2026학년도 전교육과정해외이수자(후기) 모집요강
- 입학전형시행계획(안)
- 블로그, 학원, 카페, SNS, 커뮤니티 요약


# 3. University Mapping

현재 University entity 초안 필드:

- name_ko
- name_en
- slug
- official_website_url
- admissions_office_url


## 3.1 연세대학교 서울캠퍼스

| 검증 항목 | 관찰 |
| --- | --- |
| name_ko | 공식 자료는 연세대학교를 사용하고, 모집요강 표지에 서울캠퍼스를 명시함 |
| campus 처리 | 필요. 같은 대학명 아래 서울캠퍼스 입학처와 미래캠퍼스 입학홍보처가 분리되어 있음. 모집요강이 미래캠퍼스 전형을 별도 홈페이지로 안내함 |
| official_website_url | https://www.yonsei.ac.kr |
| admissions_office_url | https://admission.yonsei.ac.kr/seoul |


## 3.2 고려대학교 서울캠퍼스

| 검증 항목 | 관찰 |
| --- | --- |
| name_ko | 공식 자료는 고려대학교를 사용하고, 모집요강 표지에 서울캠퍼스를 명시함 |
| campus 처리 | 필요. 입학처 메인이 서울캠퍼스 입학처로 표시됨. 세종캠퍼스 입학 자료를 같은 source로 취급하면 안 됨 |
| official_website_url | https://www.korea.ac.kr |
| admissions_office_url | https://oku.korea.ac.kr |


## 3.3 Model Gap

현재 University model에는 campus 전용 field가 없다.

서울캠퍼스와 다른 캠퍼스를
같은 admissions source처럼 취급하면 안 된다.

이 문제는 단순 UI 표시 문제가 아니다.

동일 대학명의 서로 다른 캠퍼스가
별도 입학처/입학팀과 별도의 모집요강을 운영할 수 있다.

campus 식별 실패는
다른 모집요강, 지원자격, 일정, source를 연결하는
데이터 정확성 문제로 이어질 수 있다.

이번 검증 단계에서는 Campus entity 도입을 확정하지 않는다.

schema 단계에서 다음 두 방향을 비교한다.
어느 하나를 이번 validation에서 최종 확정하지 않는다.

A. University에 campus discriminator를 포함
B. University 1 → N Campus entity로 정규화

이번 단계에서는 DATA_MODEL.md를 수정하지 않는다.
Gap ID: G-01
Severity: high


# 4. SourceDocument 검증


## 4.1 연세대학교

하나의 공식 모집요강 문서 안에
독립적으로 판단해야 하는 전형이 여러 개 포함된다.

공식 명칭으로 확인된 단위:

- 재외국민전형[중·고교과정 해외 이수자]
- 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 글로벌인재대학 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- 북한이탈주민전형

즉 SourceDocument 1개에
AdmissionProgram 후보가 4개 있다.

한 AdmissionProgram이 모집요강 외 추가 공식 자료를
필요로 하는가:

- 입학처 홈페이지를 일정 발표 장소로 지정함
- 합격자 발표 후 추가 안내를 전제함
- 이번 검증에서 모집요강 외 2027 재외국민전형 정정 공지의 존재 여부는 확인 필요

SourceDocument 현재 field로 식별 가능한가:

- title, source_url, university_id, academic_year, source_type, issuing_organization으로 이 PDF를 식별할 수 있음
- 공식 목록 페이지의 게시일은 이번 검증에서 직접 확인하지 못했으므로 published_at은 확인 필요

revision/update 개념:

- 파일명 날짜 문자열만으로 revision을 확정할 수는 없음
- document_version_label과 last_checked_at은 유용함
- snapshot 저장은 이번 검증에서 필수로 확정하지 않음
- 연세대 2027 재외국민전형 정정/수정본의 존재 여부는 이번 검증에서 확인하지 못함


## 4.2 고려대학교

하나의 공식 특별전형(전기) 모집요강 문서 안에
다음 전형이 함께 수록된다.

- 재외국민(정원외2%)전형
- 전교육과정해외이수자(전기)전형
- 북한이탈주민전형

즉 SourceDocument 1개에
AdmissionProgram 후보가 3개 있다.

한 AdmissionProgram이 모집요강 외 추가 공식 자료를
필요로 하는가:

- 예. 입학처 메인이 2027학년도 특별전형(전기) 파일업로드 - A4 변환 안내를 별도 공지로 게시함
- 제출서류 양식은 입학처 홈페이지의 특별전형 제출서류 메뉴를 참조하라고 안내함
- 전교육과정해외이수자 후기는 이 전기 모집요강의 대상이 아님. 2027 후기 모집요강 존재 여부는 확인 필요

revision/update 개념:

- 공식 입학처 공지 제목에
  2027학년도 특별전형(전기) 모집요강(2026.06. 수정)이 명시되어 있음
- 이는 미래 가능성이 아니라
  이번 검증에서 확인된 SourceDocument revision 요구사항이다
- 이후 2026.08.19 파일업로드 안내 공지가 추가됨
- document_version_label 유지와 함께
  수정본/revision lineage를 추적할 구조가 필요함
- 현재 schema는 확정하지 않음
- Gap ID: G-05


## 4.3 결론

SourceDocument와 AdmissionProgram은 1:1이 아니다.

이 관계는 현재 DATA_MODEL의
SourceDocument N ↔ N AdmissionProgram 설계와 맞다.


# 5. AdmissionProgram Granularity 검증

비교와 자격진단을 독립적으로 수행할 수 있는
가장 작은 공식 전형 단위를 식별한다.

모집요강 문서 자체를 그 단위로 보지 않는다.


## 5.1 연세대학교 서울캠퍼스

### 후보 A

- university: 연세대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 재외국민전형[중·고교과정 해외 이수자]
- proposed display_name: 재외국민전형 (중·고교과정 해외 이수)
- 하나의 AdmissionProgram으로 보는 이유: 지원자격, 평가방법, 제출서류, 면접 일정이 다른 전형과 독립적으로 정의됨
- 독립 eligibility: 있음. 부모 국외근무와 중·고교 해외 이수 요건을 사용
- 독립 evaluation: 있음. 단계별 서류+면접
- 독립 required documents: 있음. 부모 재직 증빙이 필수
- 독립 schedule: 일부 공유, 면접 관련 일정은 이 전형과 북한이탈주민전형에 한정
- source: 2027학년도 3월 신입학 재외국민전형 모집요강

### 후보 B

- university: 연세대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- proposed display_name: 재외국민전형 (전교육과정 해외 이수)
- 하나의 AdmissionProgram으로 보는 이유: 지원자격이 전 교육과정 이수로 정의되고, 평가가 일괄합산 서류 100%이며, 부모 재직서류가 중·고교과정 전형과 다름
- 독립 eligibility: 있음
- 독립 evaluation: 있음
- 독립 required documents: 있음
- 독립 schedule: 원서접수 등 일부 공유, 면접 일정 없음
- source: 동일 모집요강

### 후보 C

- university: 연세대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 글로벌인재대학 재외국민전형[초·중·고교 전 교육과정 해외 이수자]
- proposed display_name: 글로벌인재대학 재외국민전형 (전교육과정)
- 하나의 AdmissionProgram으로 보는 이유: 공식 명칭이 별도 전형으로 구분되고, 전교육과정 전형과 중복지원이 허용되며, 모집단위가 글로벌인재대학으로 제한됨
- 독립 eligibility: 전교육과정 이수 요건을 사용. 일반 전교육과정 전형과의 세부 차이 전부는 이 검증에서 세항까지 재서술하지 않음
- 독립 evaluation: 일괄합산 서류 100%로 표시됨
- 독립 required documents: 전교육과정 전형과 같은 장에서 함께 안내됨. 완전 독립인지 공유인지는 항목 단위로 더 확인 필요
- 독립 schedule: 전교육과정 전형과 유사하게 면접 일정이 없음
- source: 동일 모집요강

### 후보 D

- university: 연세대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 북한이탈주민전형
- proposed display_name: 북한이탈주민전형
- 하나의 AdmissionProgram으로 보는 이유: 지원자격, 평가, 서류, 면접 일정이 별도로 안내됨
- 독립 eligibility: 있음
- 독립 evaluation: 있음
- 독립 required documents: 있음
- 독립 schedule: 면접 일정을 중·고교과정 전형과 공유
- source: 동일 모집요강

display_name은 공식 괄호/수식어를 UI에서 읽기 쉽게 나눈 것이며
새로운 전형을 만들지 않는다.


## 5.2 고려대학교 서울캠퍼스

### 후보 A

- university: 고려대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 재외국민(정원외2%)전형
- proposed display_name: 재외국민전형 (정원외 2%)
- 하나의 AdmissionProgram으로 보는 이유: 지원자격, 단계별 평가, 재직 증빙서류, 면접 일정이 독립됨
- 독립 eligibility: 있음. 공통 학제 인정기준 + 재외국민 고유 요건
- 독립 evaluation: 있음. 서류 후 면접
- 독립 required documents: 있음. 재직 증빙 포함
- 독립 schedule: 면접 일정이 북한이탈주민전형과 함께 안내됨
- source: 2027학년도 특별전형 모집요강

### 후보 B

- university: 고려대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 전교육과정해외이수자(전기)전형
- proposed display_name: 전교육과정해외이수자전형 (전기)
- 하나의 AdmissionProgram으로 보는 이유: 지원자격이 전 교육과정 이수로 정의되고, 평가에 면접이 없으며, 일정표에서 면접 칸이 비어 있음
- 독립 eligibility: 있음
- 독립 evaluation: 있음
- 독립 required documents: 재외국민전형과 학력서류는 공유 안내, 재직서류는 없음
- 독립 schedule: 원서접수 공유, 면접 없음
- source: 동일 모집요강

### 후보 C

- university: 고려대학교 서울캠퍼스
- academic_year: 2027
- official_program_name: 북한이탈주민전형
- proposed display_name: 북한이탈주민전형
- 하나의 AdmissionProgram으로 보는 이유: 지원자격과 제출서류 상세가 별도 절이며, 평가에 면접이 있음
- 독립 eligibility: 있음
- 독립 evaluation: 있음
- 독립 required documents: 있음
- 독립 schedule: 재외국민전형과 면접 일정을 함께 안내
- source: 동일 모집요강


## 5.3 Granularity 결론

두 대학 모두
하나의 모집요강 문서 ≠ 하나의 AdmissionProgram
이다.

최소 비교/자격진단 단위는
문서가 아니라 위 공식 전형명 단위다.

이는 현재 DATA_MODEL의 AdmissionProgram 정의와 맞다.


# 6. AdmissionTrack 필요성 검증


## 6.1 연세대학교 서울캠퍼스

A. AdmissionProgram 하나로 eligibility를 표현할 수 있는가

중·고교과정 / 전교육과정 / 글로벌인재대학 / 북한이탈주민을
하나의 AdmissionProgram에 넣으면
비교와 자격진단을 독립적으로 할 수 없다.
따라서 위 후보는 각각 별도 AdmissionProgram이 맞다.

B. 일정·평가·서류를 공유하고 eligibility만 다른 반복 sub-track이 있는가

중·고교과정 전형 안에서
해외파견근무자 / 현지취업자 / 자영업자 구분은
지원자격의 큰 틀을 공유하고
제출서류 조합이 달라진다.

이것은 AdmissionTrack보다
RequiredDocument.condition으로 표현하는 편이 맞다.
평가방법과 전형 일정은 재직형태별로 갈라지지 않는다.

전교육과정 전형의 일부 모집단위 한국어 증빙은
별도 전형이 아니라 조건부 서류/조건이다.

C. 각각 AdmissionProgram으로 나누면 중복이 과도한가

원서접수 일정과 일부 유의사항은 반복된다.
그러나 지원자격, 평가, 핵심 서류가 다르므로
program 분리가 과도하다고 보기 어렵다.

이번 2027학년도 연세대학교 서울캠퍼스 자료에서는
AdmissionTrack 도입 필요성이 확인되지 않았다.
이 판단을 다른 대학 또는 다른 학년도로 일반화하지 않는다.


## 6.2 고려대학교 서울캠퍼스

A. AdmissionProgram 하나로 eligibility를 표현할 수 있는가

재외국민 / 전교육과정(전기) / 북한이탈주민을
한 program으로 합치면 안 된다.

B. eligibility만 다른 반복 sub-track이 있는가

재외국민과 전교육과정은
공통 학제·이수학기 인정기준을 공유한다.
그러나 고유 자격, 평가, 면접 여부, 재직서류가 다르다.

공유되는 것은 공통 인정기준 텍스트이지
평가/일정/서류 전체가 아니다.

재직 구분(국외파견 / 현지법인 취업 / 현지 자영업)도
현재 검증 자료에서는 별도 AdmissionProgram/AdmissionTrack보다
RequiredDocument의 condition 차이로 표현 가능한 사례로 평가한다.

C. program 분리 시 중복

공통 학제 인정기준과 원서접수 일정은 반복된다.
중복 수준은 moderate이나,
자격진단 단위를 유지하려면 분리하는 편이 맞다.

이번 2027학년도 고려대학교 서울캠퍼스 자료에서는
AdmissionTrack 도입 필요성이 확인되지 않았다.
이 판단을 다른 대학 또는 다른 학년도로 일반화하지 않는다.

공통 학제 기준의 중복을 줄이려면
같은 SourceCitation을 여러 program의 eligibility section에
연결하는 방식으로 충분하다.


## 6.3 종합

이번에 검토한 2027학년도
연세대학교 서울캠퍼스와 고려대학교 서울캠퍼스 자료에서는
AdmissionTrack 도입 필요성이 확인되지 않았다.

이 결론을 다른 대학 또는 다른 학년도로 일반화하지 않는다.

현재 DATA_MODEL이 Track을 현재 entity로 두지 않고
향후 확장으로만 열어 둔 판단은
이번 두 사례와는 맞다.

단, 다른 대학에서 공통 일정/평가를 공유하면서
eligibility만 독립적으로 반복되는 구조가 발견되면
다시 AdmissionTrack을 검토한다.


# 7. AdmissionSection 검증

현재 후보 section_type:

- eligibility
- evaluation
- language_requirement
- standardized_tests
- other_conditions
- caution
- notes


## 7.1 연세대학교 대응

| 모집요강 구조 | 가능한 section_type |
| --- | --- |
| Ⅳ. 지원자격 | eligibility |
| Ⅴ. 전형방법 | evaluation |
| Ⅵ·Ⅶ. 제출서류 및 업로드 안내 | RequiredDocument + notes/caution |
| Ⅷ. 면접평가 안내 | evaluation 또는 other_conditions |
| Ⅸ. 아포스티유 및 영사확인 | other_conditions 또는 RequiredDocument 조건 |
| Ⅹ. 합격 및 등록 안내 | AdmissionSchedule + caution |
| 표준화학력평가자료 및 어학능력 증빙 | standardized_tests / language_requirement 또는 RequiredDocument |
| 일부 모집단위 한국어 능력 증빙 | language_requirement 또는 조건부 RequiredDocument |

eligibility 내부는
학생 요건, 부모 요건, 학교/학제 요건, 기간 요건, 예외사항이
한 장 안에서 중첩된다.

하나의 AdmissionSection.content로
저장은 가능하지만,
자격진단 rule 설계와 section-level citation을 세분하려면
내용이 너무 길다.

새 entity를 바로 추가하는 결론은 내리지 않는다.

먼저 AdmissionProgram 하나에
같은 section_type = eligibility를 가진
AdmissionSection이 여러 개 존재할 수 있도록 허용하는 방식을 검토한다.

개념 예:

- eligibility / 공통 조건
- eligibility / 학생 관련 조건
- eligibility / 부모 관련 조건
- eligibility / 재학·체류 조건

위 예는 구분 방식의 개념이며
실제 대학 규정을 새로 만든 것이 아니다.

따라서 schema 단계에서
AdmissionProgram + section_type 조합을
무조건 unique하게 만들면 안 된다.

Model Gap: G-02


## 7.2 고려대학교 대응

| 모집요강 구조 | 가능한 section_type |
| --- | --- |
| Ⅳ. 지원자격 공통 | eligibility (여러 program이 같은 citation을 공유 가능) |
| Ⅳ. 전형별 지원자격 | eligibility |
| Ⅴ. 전형요소 및 반영비율 | evaluation |
| 서류평가 / 면접평가 안내 | evaluation |
| 제출서류 상세 | RequiredDocument |
| 지원자 유의사항, 학교폭력 조치 | caution / other_conditions |
| 공인성적 안내 | standardized_tests 또는 RequiredDocument |

고려대도 eligibility가
공통 기준 + 전형별 고유 요건으로 나뉜다.

하나의 긴 content보다
같은 program 아래 eligibility section을 여러 개 두거나
display_order로 나누는 편이 맞다.

현재 모델은 AdmissionProgram 1 → N AdmissionSection이므로
새 entity 없이 이 방식을 먼저 검토할 수 있다.

schema 단계에서
AdmissionProgram + section_type을 unique로 고정하면
이 분할이 막힌다.


## 7.3 결론

현재 section_type 후보는 대체로 충분하다.

부족한 것은 새로운 상위 entity가 아니라
eligibility 내부 세부 구분 규칙이다.

새 entity를 바로 추가하지 말고,
같은 section_type = eligibility를 가진
AdmissionSection을 한 program에 여러 개 둘 수 있는지부터 검토한다.

standardized_tests와 language_requirement는
공식 최저기준 섹션이라기보다
제출/인정 방식 안내인 경우가 많다.
availability_status를
not_found_in_official_source / not_applicable과 혼동하면 안 된다.


# 8. RequiredDocument 검증

실제 서류 전체 목록은 복사하지 않는다.
구조만 기록한다.


## 8.1 관찰된 구조

두 대학 모두 서류가 여러 개다.

필수 / 선택 / 해당자 필수 구분이 있다.
현재 requirement_status 개념과 맞다.

지원자 유형에 따라 달라진다.

- 전형별 차이
- 재직형태별 차이
- 국적/복수국적 차이
- 특정 모집단위 조건부 서류
- 합격 후 원본 제출

한 서류에 여러 조건이 붙는 경우가 있다.
RequiredDocument.condition으로 표현 가능하다.

별도의 제출 시점이 있다.

- 원서접수 시 온라인 업로드
- 특정 시각 이후 수정 불가
- 최종합격 후 원본 우편 제출

실제 공식 모집요강에서
지원 단계 온라인 서류 제출,
이후 원본 제출,
최종합격자 제출처럼
서로 다른 submission phase가 존재할 수 있다.

현재 RequiredDocument 모델만으로는
제출 시점을 충분히 구조화하기 어려울 수 있다.

SourceCitation을 item 단위로 연결할 필요는 있다.
재직서류와 학력서류의 근거 위치가 다르다.


## 8.2 Model Gap

G-03: RequiredDocument에 제출 단계 개념이 없다.

현재 RequiredDocument만으로는
지원 단계 온라인 서류 제출,
이후 원본 제출,
최종합격자 제출처럼
서로 다른 submission phase를 충분히 구조화하기 어려울 수 있다.

schema 단계 Possible Direction:

- submission_phase 개념 추가
- 필요 시 AdmissionSchedule event와의 optional relation 검토

실제 enum 값이나 FK는 아직 확정하지 않는다.
이번 단계에서는 필드 추가를 proposal로만 남긴다.


# 9. AdmissionSchedule 검증

실제 날짜는 필요 이상으로 복사하지 않는다.


## 9.1 관찰된 구조

두 대학 모두 일정이 여러 event다.

관찰된 event 유형:

- 원서접수 기간
- 온라인 서식/서류 제출 기간
- 1단계 발표
- 면접
- 최초합격 발표
- 문서등록 기간
- 충원 발표
- 최종 원본서류 제출
- 등록금 납부

단일 날짜와 기간이 모두 있다.
현재 start_at / end_at 구조로 표현 가능하다.

일부 event는 특정 AdmissionProgram에만 적용된다.
program별로 schedule row를 두면 된다.

같은 날짜를 여러 program이 공유하면
row가 반복된다. 중복은 moderate다.


## 9.2 결론

AdmissionSchedule을 단일 text로 두지 않은 현재 설계는 적절하다.

program 간 공유 일정을 위한 별도 entity는
이번 두 대학만으로는 필수가 아니다.


# 10. SourceCitation 검증


## 10.1 연결 가능성

연세대 모집요강 목차는 인쇄 쪽수를 제공한다.

예: 전형 일정, 지원자격, 전형방법, 제출서류가
서로 다른 장/쪽에 있다.

고려대 모집요강도 절 단위로
지원자격, 제출서류, 평가, 일정이 분리된다.

따라서

SourceDocument
→ SourceCitation(page 또는 section)
→ AdmissionProgram / AdmissionSection / RequiredDocument / AdmissionSchedule

흐름은 가능하다.


## 10.2 페이지 번호 주의

PDF에서는 다음이 다를 수 있다.

- 실제 PDF 파일 페이지 순번
- 문서 내부에 인쇄된 페이지 번호/라벨

표지, 목차, 공백 쪽 때문에
PDF 뷰어 페이지와 모집요강에 인쇄된 쪽수가 달라질 수 있다.

따라서 SourceCitation.page 하나만으로 충분한지
schema 단계에서 검토해야 한다.

Possible Direction:

- file_page_number
- printed_page_label
- section
- anchor_description

등을 분리하는 방법을 검토한다.

실제 field 이름은 아직 확정하지 않는다.

Model Gap: G-04


# 11. Verification 구조 검증

실제 운영 예:

- 모집요강 전체를 2026-08-23에 검토
- 이후 서류 업로드 방식만 다룬 공식 공지를 별도 확인

현재 구조로 표현 가능한가:

- AdmissionProgram.verified_at: 전형 전체 재검토가 끝났을 때만 갱신
- RequiredDocument.verified_at 또는 관련 SourceDocument.last_checked_at:
  서류 제출 방식 공지만 확인한 시점
- updated_at: 내부 레코드 수정 시점

이 차이는 현재 이중 verified_at 설계로 표현 가능하다.

고려대처럼 모집요강 수정본과
이후 추가 공지가 있으면
SourceDocument를 분리하는 편이 더 안전하다.

한 section만 고쳤다고
AdmissionProgram.verified_at을 자동 갱신하면 안 된다는
기존 원칙이 이 사례와 맞다.


# 12. 중복 분석

AdmissionProgram을 공식 전형 단위로 분리했을 때


## 연세대학교

| 데이터 | 중복 수준 | 근거 |
| --- | --- | --- |
| AdmissionSection | moderate | 원서접수 유의사항, 일부 지원자격 주의사항이 반복됨. 핵심 eligibility/evaluation은 다름 |
| RequiredDocument | moderate | 학력서류 안내가 일부 유사. 재직서류와 자기소개서 여부는 다름 |
| AdmissionSchedule | moderate | 원서접수 기간 공유. 면접 일정은 일부 전형만 |


## 고려대학교

| 데이터 | 중복 수준 | 근거 |
| --- | --- | --- |
| AdmissionSection | moderate | 공통 학제 인정기준이 재외국민/전교육과정에 공유됨 |
| RequiredDocument | moderate | 학력서류 표가 두 전형에 함께 안내됨. 재직서류와 북한이탈 서류는 다름 |
| AdmissionSchedule | moderate | 원서접수 공유. 면접은 재외국민/북한이탈만 |

정량 수치는 만들지 않았다.

중복이 high라고 보기 어렵고,
program을 합치면 자격진단 단위가 무너진다.


# 13. Model Gap Register

실제 공식 자료에서 확인된 gap만 기록한다.

| ID | Entity | Problem | University | Severity | Possible Direction |
| --- | --- | --- | --- | --- | --- |
| G-01 | University | campus 식별 실패 시 다른 모집요강/지원자격/일정/source를 연결할 수 있음. 동일 대학명의 캠퍼스가 별도 입학처와 별도 모집요강을 운영할 수 있음 | 연세대, 고려대 | high | schema에서 A. University에 campus discriminator 포함 vs B. University 1 → N Campus 정규화를 비교. 이번 검증에서 Campus entity를 확정하지 않음 |
| G-02 | AdmissionSection | 재외국민 eligibility가 학생/부모/학제/기간/예외로 중첩되어 단일 content 관리가 어려움 | 연세대, 고려대 | medium | 새 entity를 바로 추가하지 않음. 한 AdmissionProgram에 section_type = eligibility인 AdmissionSection을 여러 개 허용하는 방식을 먼저 검토. AdmissionProgram + section_type을 unique로 고정하면 안 됨 |
| G-03 | RequiredDocument | 지원 단계 온라인 제출, 이후 원본 제출, 최종합격자 제출 등 submission phase가 달라 현재 모델만으로는 제출 시점을 충분히 구조화하기 어려울 수 있음 | 연세대, 고려대 | medium | submission_phase 개념 추가, 필요 시 AdmissionSchedule event와의 optional relation 검토. 실제 enum/FK는 미확정 |
| G-04 | SourceCitation | PDF 파일 페이지 순번과 문서 내부 인쇄 페이지 번호/라벨이 다를 수 있어 page 하나만으로 충분한지 검토 필요 | 연세대, 고려대 | low | file_page_number, printed_page_label, section, anchor_description 분리 검토. 실제 field 이름은 미확정 |
| G-05 | SourceDocument | 공식 모집요강 수정본/revision lineage를 명확하게 추적할 구조 필요. 고려대 2027 특별전형 모집요강이 공식 입학처에서 2026.06. 수정으로 표시된 실제 사례가 있음 | 고려대 | medium | document_version_label 유지, revision 식별, 향후 supersedes_source_document_id 또는 이에 준하는 version relationship 검토. 현재 schema는 미확정 |

억지로 추가한 gap은 없다.
G-05는 미래 가정이 아니라
이번 검증에서 확인된 요구사항이다.


# 14. Over-modeling Register

확인된 과도함:

- 모든 RequiredDocument 항목에 개별 SourceCitation을 강제하면
  운영 부담이 클 수 있음. 같은 절을 묶어서 인용하는 편이 현실적이다.
- child entity마다 verification_status를 매번 다르게 관리하면
  전체 요강을 한 번에 검토하는 초기 운영과 맞지 않을 수 있음.
  필드는 유지하되, 초기에는 program 단위 검증을 기본으로 해도 된다.
- 이번에 검토한 2027학년도
  연세대학교 서울캠퍼스와 고려대학교 서울캠퍼스 자료에서는
  AdmissionTrack 도입 필요성이 확인되지 않았다.
  이 판단을 다른 대학 또는 다른 학년도로 일반화하지 않는다.
  지금 도입하면 과도하다.

필수 entity를 줄여야 할 정도는 아니다.
RequiredDocument와 AdmissionSchedule을
다시 긴 text로 합치는 것은 이 자료와 맞지 않다.


# 15. 대학별 결론


## 연세대학교 서울캠퍼스

- 현재 모델로 표현 가능 여부: 소폭 보완하면 가능
- 가장 큰 model gap: campus 구분과 eligibility 내부 복잡도
- AdmissionTrack 필요성: 이번에 검토한 2027학년도 연세대학교 서울캠퍼스 자료에서는 도입 필요성이 확인되지 않음. 다른 대학/학년도로 일반화하지 않음
- source/citation 적합성: 적합. 한 모집요강이 여러 program의 근거가 됨
- 운영 난이도: 중. 전형별 서류/면접 차이가 커서 program 분리가 필요함


## 고려대학교 서울캠퍼스

- 현재 모델로 표현 가능 여부: 소폭 보완하면 가능
- 가장 큰 model gap: campus 구분, 공통 학제 기준의 공유, 모집요강 수정본 revision, 모집요강 이후 추가 공지
- AdmissionTrack 필요성: 이번에 검토한 2027학년도 고려대학교 서울캠퍼스 자료에서는 도입 필요성이 확인되지 않음. 재직형태 차이는 RequiredDocument.condition으로 표현 가능한 사례로 평가. 다른 대학/학년도로 일반화하지 않음
- source/citation 적합성: 적합. 2026.06. 수정 모집요강과 이후 공지를 별도 SourceDocument 또는 revision lineage로 둘 수 있음
- 운영 난이도: 중. 전기 모집요강과 후기 자료, 추가 공지를 학년도/전형 단위로 섞지 않아야 함


# 16. Cross-University Conclusion

판단: B. 소폭 수정 후 사용 가능

근거:

핵심 구조인 다음 항목은
실제 두 대학 자료에서 유효하다.

- AdmissionProgram granularity
- SourceDocument / SourceCitation 분리
- Program과 Source의 N:N 관계
- program/child verification 분리
- EligibilityRule 분리

비교/자격진단 단위를 모집요강 문서로 두면 안 된다.

이번에 검토한 2027학년도
연세대학교 서울캠퍼스와 고려대학교 서울캠퍼스 자료에서는
AdmissionTrack 도입 필요성이 확인되지 않았다.
이 결론을 다른 대학 또는 다른 학년도로 일반화하지 않는다.

schema 전에 수정 또는 결정이 필요한 핵심 사항은 다음이다.

- campus 식별
- RequiredDocument submission phase
- SourceDocument revision lineage
- SourceCitation page representation
- AdmissionSection granularity

C. 구조적 수정 필요로 보지 않는 이유:

- source of truth, 학년도 독립, citation 분리,
  비교 데이터 비복제 원칙을 바꿀 필요는 없다.


# 17. Schema 단계 전에 결정할 사항

실제 검증에서 나온 항목만 적는다.

1. campus 식별:
   A. University에 campus discriminator를 포함할지,
   B. University 1 → N Campus로 정규화할지.
   이번 validation에서는 확정하지 않음
2. AdmissionSection granularity:
   한 AdmissionProgram에 section_type = eligibility인
   AdmissionSection을 여러 개 허용할지.
   AdmissionProgram + section_type을 unique로 고정하면 안 됨.
   새 entity를 바로 추가하지 않음
3. RequiredDocument submission phase:
   submission_phase 개념과
   AdmissionSchedule event와의 optional relation을 검토.
   실제 enum/FK는 미확정
4. SourceCitation page representation:
   파일 페이지 순번과 인쇄 페이지 번호/라벨 분리 여부.
   실제 field 이름은 미확정
5. SourceDocument revision lineage:
   document_version_label 유지,
   revision 식별,
   향후 supersedes_source_document_id 또는 이에 준하는
   version relationship 검토.
   현재 schema는 미확정
6. 모집요강 수정본과 이후 운영 공지를
   같은 SourceDocument의 version으로 볼지,
   별도 SourceDocument로 볼지
7. MVP 초기 AdmissionProgram 범위에
   북한이탈주민전형과 글로벌인재대학 전형을 포함할지
   (모델 표현은 가능하나 제품 범위 결정이 필요)
8. 고려대 전교육과정 후기를 별도 academic cycle/program으로 둘지.
   이번 전기 모집요강만으로는 2027 후기 구조를 확정하지 않음


# 18. DATA_MODEL 수정 제안

이번 branch에서는 DATA_MODEL.md를 수정하지 않는다.

제안만 기록한다.

1. University / campus 식별
   - A. University에 campus discriminator 포함
   - B. University 1 → N Campus entity로 정규화
   - 이번 validation에서 어느 하나도 확정하지 않음

2. RequiredDocument
   - submission_phase 개념 추가 검토
   - 필요 시 AdmissionSchedule event와의 optional relation 검토
   - 실제 enum 값이나 FK는 확정하지 않음

3. AdmissionSection
   - 새 entity를 바로 추가하지 않음
   - 한 AdmissionProgram에 section_type = eligibility인
     AdmissionSection을 여러 개 둘 수 있는지 먼저 검토
   - AdmissionProgram + section_type을 unique로 고정하면 안 됨

4. SourceCitation
   - file_page_number, printed_page_label, section,
     anchor_description 분리 검토
   - 실제 field 이름은 확정하지 않음

5. SourceDocument
   - document_version_label 유지
   - revision 식별
   - 향후 supersedes_source_document_id 또는 이에 준하는
     version relationship 검토
   - 현재 schema는 확정하지 않음

6. AdmissionTrack
   - 현재 보류 유지
   - 이번에 검토한 2027학년도
     연세대학교 서울캠퍼스와 고려대학교 서울캠퍼스 자료에서는
     도입 필요성이 확인되지 않음
   - 다른 대학 또는 다른 학년도로 일반화하지 않음
   - 다른 대학에서 공통 일정/평가를 공유하고
     eligibility만 독립 반복되면 다시 검토


# 19. 검증 한계

이번 문서의 모든 결론은 다음 범위에 한정된다.

- 2027학년도
- 연세대학교 서울캠퍼스
- 고려대학교 서울캠퍼스

AdmissionTrack Not needed를 포함한 모든 평가는
위 두 사례에 한정된 결과이다.
다른 대학 또는 다른 학년도로 일반화하지 않는다.

- 연세대는 재외국민전형 모집요강, 고려대는 특별전형(전기) 모집요강만 분석함
- 다른 대학 구조는 다를 수 있음
- 공식 자료 해석이 필요한 예외는 추가 검증 필요
- 연세대 입학처 목록 페이지의 정확한 게시일은 확인하지 못함
- 고려대 파일업로드 안내 공지의 본문은 제목/날짜만 확인함
- 2027학년도 고려대 전교육과정 후기 모집요강은 이번 검증에 포함하지 않음
- 따라서 이번 결과만으로 모든 대학 구조를 일반화하지 않음
