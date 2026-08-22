# Project Purpose

이 프로젝트는 해외 거주 한국 학생과 학부모를 위한
대한민국 대학 입시 정보 플랫폼이다.

MVP 우선순위는 다음과 같다.

1. 대학전형 DB
2. 대학비교
3. 자격진단
4. 질문 FAQ
5. 학부모 경험 콘텐츠

가장 중요한 제품 원칙은
정보량보다 정확성, 검증 가능성, 중립성, 최신성이다.


# Admission Information Safety

대학 입시 정보를 절대 임의로 생성하지 않는다.

특히 다음 정보를 공식 근거 없이 만들거나 추측하지 않는다.

- 지원 자격
- 모집 인원
- 경쟁률
- 합격선
- SAT / IB / AP 기준
- TOEFL / IELTS 기준
- 학기 인정 규칙
- 부모 체류 요건
- 학생 해외 재학 요건
- 제출 서류
- 전형 방법
- 원서 접수 일정
- 등록금
- 합격자 통계

정보가 확인되지 않으면
unknown, null, 자료 없음, 확인 필요 등의 상태로 처리한다.

실제 대학명을 사용한 가짜 입시정보나
그럴듯한 placeholder 입시정보를 생성하지 않는다.

UI 개발을 위해 샘플 데이터가 필요한 경우에는
반드시 명백한 가상 대학명을 사용하고
fixture 또는 demo data임을 표시한다.


# Source Policy

입시정보의 출처 우선순위는 다음과 같다.

1. 대학 입학처 공식 홈페이지
2. 대학 공식 모집요강
3. 대학 공식 FAQ / 공지사항
4. 교육부 및 정부기관
5. 한국대학교육협의회 등 공신력 있는 기관
6. 기타 신뢰할 수 있는 2차 자료

블로그, 카페, 학원, 커뮤니티, SNS는
공식 입시규정의 1차 근거로 취급하지 않는다.

공식 자료와 2차 자료가 충돌하면 공식 자료를 우선한다.


# Academic Year Rules

서로 다른 학년도의 모집요강을 섞지 않는다.

예를 들어 2027학년도 규정을
2028학년도에도 동일하다고 가정하지 않는다.

가능하면 입시 데이터에는 다음 필드를 유지할 수 있도록 설계한다.

- academic_year
- university
- admission_type
- eligibility
- required_documents
- evaluation_method
- language_requirement
- standardized_tests
- application_period
- source_url
- source_document
- source_page
- verified_date
- notes

학년도와 출처가 없는 데이터를
확정된 공식정보처럼 사용자에게 보여주지 않는다.


# Fact vs Interpretation

가능하면 정보를 다음 성격으로 구분할 수 있도록 설계한다.

- official_fact
- interpretation
- strategic_opinion
- unverified

해석이나 전략적 의견을
대학의 공식 규정처럼 표시하지 않는다.


# Eligibility Diagnosis

자격진단은 단순한 AI 추측 기능으로 만들지 않는다.

가능하면 검증 가능한 규칙 기반 구조를 사용한다.

특정 학생의 지원 가능 여부를 판단하려면
다음과 같은 정보를 고려할 수 있어야 한다.

- 학생 국적
- 부모 국적
- 학생 해외 재학 기간
- 부모 해외 체류/근무 기간
- 학교 학제
- 이수 학기 수
- 입학 및 졸업 시점
- 중간 전학
- 월반
- 유급
- 해당 대학
- 해당 학년도
- 해당 전형

필수 입력정보가 부족하면
단순히 가능/불가능으로 판정하지 않는다.

결과에는 가능하면
판정 근거와 확인이 필요한 조건을 함께 제공할 수 있도록 설계한다.

각 eligibility rule은
향후 공식 source와 연결 가능하도록 설계한다.


# Product Architecture

대학전형 DB가 입시 데이터의 source of truth가 되어야 한다.

대학비교 기능은 별도의 입시 데이터를 복제하지 않고
대학전형 DB의 동일한 데이터를 읽어 비교해야 한다.

자격진단 역시 가능하면
동일한 전형 데이터 및 eligibility rules를 사용해야 한다.

FAQ의 공식 규정 설명과
학부모 경험 콘텐츠를 데이터 구조와 UI에서 명확히 구분한다.

개인 경험을 공식 입시규정처럼 표시하지 않는다.


# Current Technology

현재 프로젝트의 기본 기술은 다음과 같다.

- Next.js App Router
- TypeScript
- React
- Tailwind CSS
- ESLint
- npm

현재 database, authentication, CMS는 아직 구현되지 않았다.

별도 요청 없이
Supabase, Prisma, Firebase, Clerk, NextAuth/Auth.js,
CMS 또는 기타 인프라를 임의로 추가하지 않는다.


# Development Rules

새로운 코드는 TypeScript를 기본으로 한다.

기존 App Router 구조를 유지한다.

불필요한 dependency를 추가하지 않는다.

새 dependency가 필요하면
왜 필요한지 먼저 설명한다.

관련 없는 파일을 임의로 수정하지 않는다.

요청받지 않은 대규모 refactoring을 하지 않는다.

큰 기능을 구현하기 전에는
먼저 구현 계획과 영향을 받는 파일을 설명한다.

한 번의 작업에서는 가능한 한
하나의 명확한 기능 또는 목적만 처리한다.

기존에 정상 작동하는 기능을 보존한다.

구현되지 않은 기능을
구현되었다고 보고하지 않는다.

실제 존재하지 않는 API나 library 기능을
있다고 가정하지 않는다.


# Security and Privacy

.env 파일, API key, database credential,
secret token 등을 repository에 commit하지 않는다.

민감정보를 source code에 hard-code하지 않는다.

학생 및 학부모 개인정보는 최소한으로 수집하도록 설계한다.

학생 개인정보를 저장하는 기능을 추가할 때는
구현 전에 개인정보 및 보안 위험을 검토한다.


# Validation

의미 있는 코드 변경 후에는 가능한 경우

- lint
- TypeScript check
- production build

를 확인한다.

실패가 발생하면 성공했다고 보고하지 않는다.


# Git Workflow

main branch는 안정 버전으로 취급한다.

기능 개발은 별도 branch에서 수행한다.

별도 요청 없이 force push 하지 않는다.

별도 요청 없이 기존 commit history를 rewrite하지 않는다.

사용자가 명시적으로 요청하지 않은 경우
작업 완료 후 자동으로 main에 merge하지 않는다.


# Agent Working Style

추측보다 확인을 우선한다.

불확실한 내용은 불확실하다고 명시한다.

기능을 먼저 만들고 데이터 구조를 나중에 맞추지 않는다.

다음 순서로 사고한다.

사용자 문제
→ 필요한 정보
→ 데이터 구조
→ 정보 검증 방법
→ UX
→ 기능
→ 기술 구현

사용자의 아이디어에 무조건 동의하지 않는다.

기술적 또는 제품적 문제가 발견되면
근거와 함께 문제를 알려준다.

작업 완료 후에는 항상 다음을 보고한다.

- 변경한 파일
- 무엇을 변경했는지
- 실행한 검증
- 검증 결과
- 해결되지 않은 문제
- 다음 단계에서 고려할 사항
