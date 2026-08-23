# MVP_DATA_SCOPE

이 문서는 3teuk-Consulting MVP에서
최초로 구축할 실제 대학 입시 데이터 범위를 정의한다.

`docs/DATA_MODEL.md`가
"데이터를 어떻게 저장할 것인가"를 정의한다면,

`docs/MVP_DATA_SCOPE.md`는
"어떤 데이터를 먼저 구축할 것인가"를 정의한다.

이 문서는 실제 입시 규정을 작성하는 문서가 아니다.

지원자격, 모집인원, 제출서류, 일정 등의 실제 값은
각 대학 공식 2027학년도 모집요강을 검증한 뒤
별도의 데이터 구축 단계에서 입력한다.

실제 official_program_name, source URL,
eligibility rule 값, 일정, 서류명은
이번 문서에 작성하지 않는다.


# 1. 문서 목적

MVP 최초 출시에서 실제로 구축할
입시 데이터의 경계를 확정한다.

이 문서는 다음을 정의한다.

- 최초 academic_year
- 최초 admission scope
- 최초 대상 대학과 구축 순서
- campus 구분 원칙
- source / verification 원칙
- 과거 학년도 정책
- 최초 출시에서 제외하는 범위
- 한 대학 데이터의 구축 완료 기준

이 문서는 다음을 하지 않는다.

- 실제 입시 규정 작성
- 실제 모집요강 값 입력
- schema / SQL / migration 정의
- 대학 우열 또는 추천 순위 부여


# 2. 최초 Academic Year

MVP 최초 구축 학년도:

2027학년도

2027학년도를 MVP의 기본 제공 학년도로 사용한다.

중요:

- 2026 또는 2025 자료를 2027 자료에 섞지 않는다.
- 이전 학년도 규정을 2027에도 동일하다고 가정하지 않는다.
- 2027학년도 공식 모집요강에서 확인한 정보만
  2027 AdmissionProgram에 사용한다.


# 3. 최초 Admission Scope

MVP 최초 데이터 구축 범위는

"3년 특례 관련 전형"

으로 한정한다.

중요:

"3년 특례"는 사용자 이해와 내부 분류를 위한 표현이다.

모든 대학에서 공식 전형명이
"3년 특례"라고 가정하지 않는다.

데이터 구조에서는 다음을 구분한다.

AdmissionCategory
= 사이트 내부 분류 / 사용자 탐색용
  예: 3년 특례 관련

official_program_name
= 각 대학의 2027학년도 공식 모집요강에 기재된
  실제 공식 전형명

display_name
= 공식 의미를 변경하지 않는 범위에서
  사용자에게 이해하기 쉽게 보여주는 표시명

실제 official_program_name은
공식 자료 검증 전에는 작성하지 않는다.

실제 AdmissionCategory code 값도
이번 문서에서 확정하지 않는다.


# 4. 최초 대상 대학

MVP 첫 출시 대상 대학은 5개다.

1. 고려대학교
2. 연세대학교
3. 서강대학교
4. 한양대학교
5. 성균관대학교

이 대학 목록은
대학의 우열 또는 추천 순위를 의미하지 않는다.

초기 데이터 구축 범위를 제한하기 위한
운영상의 우선순위다.


# 5. 데이터 구축 순서

실제 데이터 구축 순서는 다음과 같다.

1. 고려대학교
2. 연세대학교
3. 서강대학교
4. 한양대학교
5. 성균관대학교

이 순서는
대학 평가 또는 선호도 순위가 아니다.

database/schema 검증과
데이터 구축 작업을 단계적으로 수행하기 위한 순서다.


# 6. Campus 원칙

각 대학의 실제 자료를 수집할 때
캠퍼스를 명확하게 구분한다.

서로 다른 입학처 또는 모집요강을 운영하는 캠퍼스의 자료를
같은 University/AdmissionProgram 데이터에 섞지 않는다.

현재 MVP DATA_MODEL은
University에 campus discriminator를 두는 초기 전략을 사용한다.

실제 구축 대상 campus는
각 대학의 공식 입학처 및 2027학년도 모집요강을
검증한 후 명시한다.

확인되지 않은 campus 정보는 추측하지 않는다.


# 7. 최초 구축 대상 데이터

각 대상 대학의 2027학년도
3년 특례 관련 AdmissionProgram에 대해
가능한 범위에서 다음 데이터를 구축한다.

- University
- AdmissionProgram
- AdmissionSection
  - eligibility
  - evaluation
  - language_requirement
  - standardized_tests
  - other_conditions
  - caution
  - 기타 실제 자료에서 필요한 section
- RequiredDocument
- AdmissionSchedule
- SourceDocument
- SourceCitation
- verification metadata

중요:

모든 항목을 억지로 채우지 않는다.

공식 모집요강에서 확인되지 않는 경우

- 자료 없음
- 공식자료 미확인
- 확인 필요

등의 상태를 사용한다.

"공식자료에서 찾지 못함"을
"요구하지 않음"으로 해석하지 않는다.

같은 AdmissionProgram 안에
동일한 section_type의 AdmissionSection이
여러 개 있을 수 있다.


# 8. EligibilityRule 범위

2027학년도 3년 특례 관련 공식 입시정보 DB 구축과
EligibilityRule 자동 판정 구조 구축은 분리한다.

먼저 사람에게 보여줄 공식 지원자격 정보를
정확하게 구조화한다.

그 후 공식 규정 중
결정론적으로 안전하게 표현 가능한 조건만
EligibilityRule로 변환한다.

모호한 규정이나 예외 조건을
억지로 자동 Rule로 만들지 않는다.

따라서 초기 데이터 구축 단계에서
EligibilityRule 완성률을 목표로 하지 않는다.


# 9. Source 원칙

모든 핵심 입시정보는 가능한 경우
공식 대학 입학처 자료를 근거로 한다.

우선순위:

1. 해당 대학 입학처 공식 모집요강
2. 해당 대학 공식 입학처 페이지
3. 해당 대학 공식 FAQ / 공지사항
4. 필요한 경우 정부 또는 공신력 기관 자료

블로그, 학원, 카페, SNS, 커뮤니티는
공식 전형 데이터의 1차 source로 사용하지 않는다.

각 데이터에는 가능한 경우 다음을 연결한다.

- SourceDocument
- SourceCitation
- academic_year
- verified_at

실제 source URL은
데이터 구축 단계에서 공식 자료를 직접 확인한 뒤 입력한다.


# 10. Verified Date 원칙

2027학년도 데이터가 등록되어 있다는 이유만으로
모든 정보를 verified 상태로 표시하지 않는다.

AdmissionProgram 전체 검토가 완료된 경우에만
program-level verified_at을 사용한다.

개별 section, document, schedule은
필요한 경우 별도의 verified_at을 유지한다.

updated_at과 verified_at은 같은 개념이 아니다.

SourceDocument 수정본이 발견되면
기존 데이터가 자동으로 재검증된 것으로 처리하지 않는다.


# 11. 과거 학년도 정책

MVP 최초 출시는 2027학년도에 집중한다.

2026학년도는
2027학년도 DB 구조와 데이터 운영이 안정된 뒤
과거 학년도 데이터로 추가하는 것을 목표로 한다.

2025학년도는
사용자 가치와 데이터 구축/검증 비용을 확인한 뒤
추가 여부를 결정한다.

우선순위:

Phase 1
2027학년도

Phase 2
2026학년도

Phase 3
2025학년도 추가 여부 평가


# 12. 과거 학년도 UI 원칙

과거 학년도 데이터가 추가될 경우
최신 학년도와 명확하게 구분한다.

기본 표시 학년도는
현재 서비스가 기준으로 삼는 학년도다.

초기 MVP에서는:

2027학년도
= 기본 제공 학년도

향후 2026 데이터가 추가되면
"과거 학년도"로 접근하도록 한다.

과거 학년도 페이지에서는 사용자가
현재 규정으로 오해하지 않도록 다음 의미의 안내를 제공한다.

예:

"이 페이지는 2026학년도 공식 자료를 기준으로 합니다.
현재 2027학년도 전형과 내용이 다를 수 있습니다."

정확한 UI copy는 디자인 단계에서 결정한다.

과거 학년도 화면에서는
최신 학년도 정보로 이동할 수 있는 CTA를 제공하는 방향을 사용한다.


# 13. 과거 데이터 보존 원칙

새 학년도가 발표되어도
이전 학년도 AdmissionProgram을 삭제하지 않는다.

예:

AdmissionProgram 2026
≠
AdmissionProgram 2027

서로 독립적인 데이터다.

2027 자료를 근거로
2026 AdmissionProgram을 수정하지 않는다.

2026 자료를 근거로
2027 AdmissionProgram을 채우지 않는다.


# 14. 대학비교 학년도 정책

기존 MVP 원칙을 유지한다.

대학비교에서는 동일 academic_year의
AdmissionProgram끼리만 비교한다.

예:

2027 고려대
vs
2027 연세대

비교 가능.

2027 고려대
vs
2026 연세대

를 동일 조건 비교표에 섞지 않는다.

연도별 규정 변화 비교 기능은
MVP 이후 별도 기능으로 검토한다.


# 15. 최초 출시에서 제외하는 데이터 범위

이번 최초 데이터 구축에는 원칙적으로 다음을 포함하지 않는다.

전교육과정 해외이수자는
제품 전체 범위에서는 고려할 수 있다.
그러나 최초 production data 범위에서는 제외한다.

장기 제품 범위와
최초 production data 범위를 같은 것으로 취급하지 않는다.

- 전교육과정 해외이수자 전형 데이터
- 북한이탈주민 관련 전형
- 일반 수시 전체 전형
- 정시
- 외국인전형 전체
- 2026학년도 데이터
- 2025학년도 데이터
- 대학 전체 모집단위 데이터
- 합격선
- 합격 가능성
- 경쟁률 예측
- 대학 추천 점수
- SAT/IB/AP 권장 점수 추정
- 학원/커뮤니티 기반 입시 규정

단,
3년 특례 관련 공식 전형을 이해하기 위해
공식 모집요강에서 연결 관계를 확인할 필요가 있는 경우에는
source 분석에는 참고할 수 있으나
MVP production data 범위를 자동 확장하지 않는다.


# 16. 5개 대학 이후 확장 원칙

초기 5개 대학 구축이 완료된 후
대학 수를 자동으로 늘리지 않는다.

다음 요소를 확인한 뒤 확장한다.

- 사용자 요청
- 데이터 구축 시간
- 검증 난이도
- 업데이트 비용
- 실제 사용량
- 대학별 공식 자료 접근성
- 기존 DB 구조의 안정성

"대학 수" 자체를 제품 성공의 핵심 KPI로 사용하지 않는다.


# 17. 구축 완료 기준

한 대학의 2027학년도 3년 특례 관련 데이터가
"구축 완료"라고 간주되기 위해서는
최소한 다음을 확인한다.

1. 정확한 University/campus 확인
2. 해당 AdmissionProgram 식별
3. official_program_name 확인
4. 주요 AdmissionSection 확인
5. 주요 RequiredDocument 구조 확인
6. AdmissionSchedule 구조 확인
7. 공식 SourceDocument 등록
8. 핵심 SourceCitation 연결
9. 학년도 확인
10. verification 상태 확인

자료에서 확인되지 않는 항목이 있다고 해서
완료할 수 없는 것은 아니다.

대신 해당 항목의 availability/verification 상태를
정확하게 기록해야 한다.


# 18. 실제 구축 시작 순서

실제 데이터 구축은 다음 순서를 사용한다.

Step 1
고려대학교 2027학년도 3년 특례 관련
공식 자료 확인

Step 2
현재 schema 설계에 실제 데이터 구조 매핑

Step 3
연세대학교 2027학년도 동일 범위로
schema 반대 검증

Step 4
필요한 schema 수정

Step 5
PostgreSQL/Supabase schema 확정

Step 6
고려대/연세대 실제 검증 데이터 입력

Step 7
서강대학교 추가

Step 8
한양대학교 추가

Step 9
성균관대학교 추가

중요:

실제 schema를 확정하기 전에
고려대와 연세대 공식 자료를 이용해
최소 한 번 더 검증한다.

이 재검증은 3년 특례 관련 범위에 한정한다.
DATA_MODEL 구조 검증에서 확인한 다른 전형 단위를
이번 production data 범위로 자동 확장하지 않는다.


# 19. 이번 단계에서 결정하지 않을 사항

다음은 아직 결정하지 않는다.

- 실제 PostgreSQL DDL
- Supabase project 설정
- PK type
- index
- RLS
- enum 구현 방식
- ORM
- 관리자 UI
- 데이터 입력 UI
- 실제 AdmissionCategory code
- 실제 official_program_name
- 실제 source URL
- 실제 2027 입시 규정 데이터
- 2026/2025 데이터 상세 구축 일정
- 대학 5개 이후 추가 대학


# 20. 다음 단계

MVP_DATA_SCOPE 확정 후 다음 작업 순서는:

1. PostgreSQL/Supabase schema 설계
2. 고려대학교 2027 공식 자료로 schema 검증
3. 연세대학교 2027 공식 자료로 반대 검증
4. 필요한 schema 수정
5. migration 작성
6. Supabase database 구축
7. 검증된 데이터 입력
8. application read layer 연결
9. 대학전형 UI 구현
