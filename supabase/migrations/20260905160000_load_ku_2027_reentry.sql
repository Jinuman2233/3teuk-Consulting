-- KU 2027 재외국민(정원외2%)전형 verified admissions data load (draft)
--
-- DATA ONLY. No schema / type / function / trigger / policy / index changes.
-- Source of truth: docs/data/ku/2027/ROW_MAP.md
-- Supporting: docs/data/ku/2027/SOURCE_INVENTORY.md
--             docs/VERIFIED_DATA_LOAD_SPEC.md
--
-- Do not invent admission facts. Do not UPSERT. Do not ON CONFLICT DO NOTHING.
-- Do not overwrite existing rows. Do not DELETE. Do not use seed.sql.
--
-- UUID strategy: one fixed UUIDv4 per UUID PK, written literally.
-- UUIDs are technical identity only. Not derived from slug / URL / year.
-- No UUIDv5. No gen_random_uuid() at insert time.
--
-- Transaction: no explicit BEGIN/COMMIT.
-- supabase/migrations/20260825155343_initial_schema.sql also has none.
-- Current migration convention is preserved.
-- Transaction behavior = TO BE PROVEN IN RUNTIME VALIDATION.
-- Do not treat a runner wrapping this file as an established fact.
--
-- Verification timestamps:
-- source_documents.last_checked_at and child verified_at values are
-- literal timestamptz captured during final pre-import official-source
-- verification (UTC). Not a SQL clock function and not apply time.
-- AdmissionProgram P01 remains partially_verified with verified_at NULL.
-- DocumentSubmission SUB82 remains needs_review with verified_at NULL and schedule FK NULL.
--
-- Logical IDs in comments (KU27-*) are documentation only, not DB fields.

-- =============================================================================
-- 0. Preflight duplicate / conflict guards
-- =============================================================================

DO $$
DECLARE
  v_count integer;
BEGIN
  -- University: intended slug / name / campus identity
  SELECT count(*) INTO v_count
  FROM public.universities
  WHERE slug = 'korea-seoul'
     OR display_name = '고려대학교 서울캠퍼스'
     OR (name_ko = '고려대학교' AND campus_name = '서울캠퍼스');

  IF v_count > 0 THEN
    RAISE EXCEPTION
      'KU27 preflight: existing university row conflicts with KU27-U01 (slug korea-seoul / 고려대학교 서울캠퍼스). Manual review required. No silent reuse or UPSERT.';
  END IF;

  -- AdmissionCategory: identity fields on current schema
  SELECT count(*) INTO v_count
  FROM public.admission_categories
  WHERE code = 'three_year_special'
     OR label = '3년 특례 관련';

  IF v_count > 0 THEN
    RAISE EXCEPTION
      'KU27 preflight: existing admission_categories row conflicts with KU27-CAT01 (code three_year_special / label 3년 특례 관련). Manual review required. No silent reuse or UPSERT.';
  END IF;

  -- Program routing identity (university + academic_year + admission_slug)
  SELECT count(*) INTO v_count
  FROM public.admission_programs p
  JOIN public.universities u ON u.id = p.university_id
  WHERE p.academic_year = 2027
    AND p.admission_slug = 'overseas-korean-2pct'
    AND (
      u.slug = 'korea-seoul'
      OR u.display_name = '고려대학교 서울캠퍼스'
      OR (u.name_ko = '고려대학교' AND u.campus_name = '서울캠퍼스')
    );

  IF v_count > 0 THEN
    RAISE EXCEPTION
      'KU27 preflight: existing admission_programs routing key conflicts with KU27-P01 (2027 / overseas-korean-2pct). Manual review required.';
  END IF;

  -- SourceDocument equivalent / conflict (not URL-only identity)
  SELECT count(*) INTO v_count
  FROM public.source_documents
  WHERE academic_year = 2027
    AND (
      (
        title = '2027학년도 특별전형 모집요강 (May official PDF, historical)'
        AND source_url = 'https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf'
        AND document_version_label = 'May official PDF / previous revision of S01'
      )
      OR (
        title = '2027학년도 특별전형 모집요강 (서울캠퍼스) (2026.06.10 배포용)'
        AND source_url = 'https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf'
        AND document_version_label = '(2026.06.10)_배포용 / 2026.06. 수정'
      )
      OR (
        title = '[서울캠퍼스] 2027학년도 특별전형(전기) 제출서류 양식 안내'
        AND source_url = 'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=124&BOARD_SEQ=3&CONTENTS_NO=&MENU_ID=730&SITE_NO=2'
        AND document_version_label = 'BBS_SEQ=124'
      )
      OR (
        title = '2027학년도 특별전형(전기) 원서접수 안내'
        AND source_url = 'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1799&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2'
      )
      OR (
        title = '2027학년도 특별전형 1단계 합격자 면접고사 안내 및 수험생 유의사항(배포용)'
        AND source_url = 'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1803&FILE_SEQ=2'
        AND document_version_label = '(배포용)'
      )
      OR (
        title = '2027학년도 특별전형(전기) 최종 합격자 발표 (HTML body)'
        AND source_url = 'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1805&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2'
      )
      OR (
        title = '2027학년도 특별전형 최종합격자 안내사항(배포용) (PDF)'
        AND source_url = 'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2'
        AND document_version_label = '(배포용)'
      )
    );

  IF v_count > 0 THEN
    RAISE EXCEPTION
      'KU27 preflight: existing source_documents row is equivalent or conflicting with a planned KU27 SourceDocument (title + URL + academic/version context). Manual review required. URL alone is not identity.';
  END IF;
END
$$;

-- =============================================================================
-- 1. universities (1)
-- =============================================================================

-- KU27-U01
INSERT INTO public.universities (
  id,
  name_ko,
  name_en,
  campus_name,
  display_name,
  slug,
  official_website_url,
  admissions_office_url
) VALUES (
  '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
  '고려대학교',
  'Korea University',
  '서울캠퍼스',
  '고려대학교 서울캠퍼스',
  'korea-seoul',
  'https://www.korea.ac.kr',
  'https://oku.korea.ac.kr/oku/index.do'
);

-- =============================================================================
-- 2. admission_categories (1)
-- =============================================================================

-- KU27-CAT01
INSERT INTO public.admission_categories (
  id,
  code,
  label,
  description
) VALUES (
  '8dcdeb53-4d2c-4840-94cf-3d05948e411a'::uuid,
  'three_year_special',
  '3년 특례 관련',
  '해외 재학·체류 요건을 두는 재외국민(정원외) 계열을 묶는 내부 분류. 대학 공식 전형명이 아님.'
);

-- =============================================================================
-- 3. source_documents (7) — historical S06 first, then current S01
-- last_checked_at: literal UTC from final pre-import verification of each artifact.
-- =============================================================================

INSERT INTO public.source_documents (
  id,
  university_id,
  academic_year,
  source_type,
  title,
  issuing_organization,
  source_url,
  published_at,
  last_checked_at,
  document_version_label,
  supersedes_source_document_id,
  notes
) VALUES
  -- KU27-SRC01
  (
    '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'admissions_guide',
    '2027학년도 특별전형 모집요강 (May official PDF, historical)',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/attach/202605/1780023938272_0.pdf',
    NULL,
    '2026-09-05T17:01:54Z'::timestamptz,
    'May official PDF / previous revision of S01',
    NULL,
    'LOAD_HISTORICAL. current program_source 금지. current citation 금지. published_at은 이 파일의 공식 게시일이 inventory에서 확정되지 않음. PDF /CreationDate를 published_at으로 쓰지 않음.'
  ),
  -- KU27-SRC02
  (
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'admissions_guide',
    '2027학년도 특별전형 모집요강 (서울캠퍼스) (2026.06.10 배포용)',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf',
    '2026-06-10'::date,
    '2026-09-05T17:02:00Z'::timestamptz,
    '(2026.06.10)_배포용 / 2026.06. 수정',
    '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid,
    'Access surfaces (alias table 없음): BoardView BBS_SEQ=1794; FileDown FILE_SEQ=4; MENU_ID=690. supersedes → SRC01. 확정 근거는 공식 수정 게시 + 수정사항이 June p3과 일치 (MD5 단독 아님).'
  ),
  -- KU27-SRC03
  (
    '5e5f6845-dca3-4d4a-8616-7c65bec86c7d'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'submission_forms',
    '[서울캠퍼스] 2027학년도 특별전형(전기) 제출서류 양식 안내',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=124&BOARD_SEQ=3&CONTENTS_NO=&MENU_ID=730&SITE_NO=2',
    '2026-05-26'::date,
    '2026-09-05T17:02:01Z'::timestamptz,
    'BBS_SEQ=124',
    NULL,
    'MENU_ID=1750는 같은 posting access surface. ZIP FILE_SEQ=1 / XLSX FILE_SEQ=2는 첨부. ZIP 내부를 별도 SourceDocument로 쪼개지 않음. XLSX 미개봉. 양식 필드 내용 추정 금지.'
  ),
  -- KU27-SRC04
  (
    '37f271ad-c13d-4650-bb5b-6a54e3777d69'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'official_notice',
    '2027학년도 특별전형(전기) 원서접수 안내',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1799&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2',
    '2026-07-02'::date,
    '2026-09-05T17:02:03Z'::timestamptz,
    NULL,
    NULL,
    'HTML only. 원서/서류 일정을 S01과 같은 logical event로 인용. 경쟁률 공시 시각은 지원 필수 event가 아니므로 schedule row를 만들지 않음.'
  ),
  -- KU27-SRC05
  (
    '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'official_notice',
    '2027학년도 특별전형 1단계 합격자 면접고사 안내 및 수험생 유의사항(배포용)',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1803&FILE_SEQ=2',
    '2026-07-29'::date,
    '2026-09-05T17:02:05Z'::timestamptz,
    '(배포용)',
    NULL,
    'PDF 3p를 citeable artifact로 저장 (이번 작업에서 FILE_SEQ=2 PDF download 확인). HTML BoardView BBS_SEQ=1803은 같은 notice access surface. HTML과 PDF는 면접 일시·우당교양관을 보완적으로 말하며 conflict가 아니므로 split하지 않음.'
  ),
  -- KU27-SRC06
  (
    'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'official_notice',
    '2027학년도 특별전형(전기) 최종 합격자 발표 (HTML body)',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/oku/cms/FR_BBS_CON/BoardView.do?BBS_SEQ=1805&BOARD_SEQ=5&CONTENTS_NO=5&MENU_ID=750&SEARCH_SEQ=4&SITE_NO=2',
    '2026-09-03'::date,
    '2026-09-05T17:02:06Z'::timestamptz,
    NULL,
    NULL,
    'BoardViewData CONTENTS가 fact-bearing body. 졸업예정자 졸업증명서 「2027년 3월 입학 전」표현의 provenance. PDF와 합치지 않음.'
  ),
  -- KU27-SRC07
  (
    '31c298f9-cde7-407b-be2d-692235e1a391'::uuid,
    '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
    2027,
    'official_notice',
    '2027학년도 특별전형 최종합격자 안내사항(배포용) (PDF)',
    '고려대학교 서울캠퍼스 입학처',
    'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2',
    '2026-09-03'::date,
    '2026-09-05T17:02:08Z'::timestamptz,
    '(배포용)',
    NULL,
    '7 physical pages. FILE_SEQ=2 확인. HWP FILE_SEQ=1은 별도 row 없음. p2에 한국 시간(GMT+9) 명시. p4 표의 졸업증명서 기한 표현은 HTML과 다름.'
  );

-- =============================================================================
-- 4. admission_programs (1)
-- verification_status = partially_verified (ROW_MAP). verified_at NULL (program not fully verified).
-- =============================================================================

-- KU27-P01
INSERT INTO public.admission_programs (
  id,
  university_id,
  admission_category_id,
  academic_year,
  official_program_name,
  display_name,
  admission_slug,
  information_type,
  verification_status,
  verified_at,
  notes
) VALUES (
  'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
  '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
  '8dcdeb53-4d2c-4840-94cf-3d05948e411a'::uuid,
  2027,
  '재외국민(정원외2%)전형',
  '재외국민(정원외2%)전형',
  'overseas-korean-2pct',
  'official_fact',
  'partially_verified',
  NULL,
  '전교육·북한은 이 row가 아님. 졸업예정자 졸업증명서 기한은 child SUB82가 needs_review. program 전체를 unverified로 두지 않음.'
);

-- =============================================================================
-- 5. admission_program_sources (6) — S06 / KU27-SRC01 is not linked
-- =============================================================================

INSERT INTO public.admission_program_sources (
  admission_program_id,
  source_document_id,
  source_role,
  display_order,
  notes
) VALUES
  -- KU27-PS01
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    'primary_guide',
    1,
    'S01 current'
  ),
  -- KU27-PS02
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '5e5f6845-dca3-4d4a-8616-7c65bec86c7d'::uuid,
    'supporting_forms',
    2,
    'S02 소정 양식'
  ),
  -- KU27-PS03
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '37f271ad-c13d-4650-bb5b-6a54e3777d69'::uuid,
    'supporting_notice',
    3,
    'S03'
  ),
  -- KU27-PS04
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid,
    'supporting_notice',
    4,
    'S04'
  ),
  -- KU27-PS05
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid,
    'supporting_notice',
    5,
    'S05 HTML (conflict provenance)'
  ),
  -- KU27-PS06
  (
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '31c298f9-cde7-407b-be2d-692235e1a391'::uuid,
    'supporting_notice',
    6,
    'S05 PDF (conflict provenance)'
  );

-- =============================================================================
-- 6. admission_sections (17)
-- information_type = official_fact, availability_status = available
-- verification_status = verified (ROW_MAP verified 후보)
-- verified_at = latest citation-location confirmation time for that section
-- No language_requirement absence section.
-- =============================================================================

INSERT INTO public.admission_sections (
  id,
  admission_program_id,
  section_type,
  title,
  content,
  applicability_text,
  information_type,
  availability_status,
  verification_status,
  verified_at,
  display_order
) VALUES
  -- KU27-SEC01
  (
    'a48538c9-e84f-491d-a246-836ed8c0457d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'eligibility',
    '지원자격 공통 (학력·학제·이수학기)',
    'S01 p8–9 공통. 전교육·북한 전용 문장 제외',
    '재외국민(정원외2%)에도 적용되는 공통 자격',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    10
  ),
  -- KU27-SEC02
  (
    '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'eligibility',
    '재외국민(정원외2%) 지원자격 개요',
    'p10 표: 중·고 3년, 체류 비율, 국외근무 1,095일 등 개요',
    '재외국민(정원외2%)전형',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    20
  ),
  -- KU27-SEC03
  (
    'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'eligibility',
    '국외 재학·체류·재직 기간 산정',
    'p10 상세 산정. rule 코딩 금지',
    '재외국민(정원외2%)전형',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    30
  ),
  -- KU27-SEC04
  (
    '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'other_conditions',
    '모집단위 및 모집인원',
    '78명, 모집단위별 2명 이내, 인문 38 / 자연 38 / 의학 1 / 예능 1. 중복지원 허용. 체육교육과 재외국민 미선발. 학부대학 미선발. 단위 목록 전체를 임의 생성하지 않음',
    '2027 서울캠퍼스 재외국민(정원외2%)',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    40
  ),
  -- KU27-SEC05
  (
    'cedac3d2-df94-4561-adf7-3f6505475981'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'evaluation',
    '전형요소 및 반영비율',
    '1단계 서류 100% 3배수. 2단계 1단계 70% + 면접 30%. p18 가. 만',
    '재외국민(정원외2%)전형',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    50
  ),
  -- KU27-SEC06
  (
    '22f25f30-a90a-47bb-9006-844894416915'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'evaluation',
    '서류평가 역량',
    '학업 40 / 세계시민 30 / 계열 20 / 공동체 10. 전교육과 공유이나 재외국민에 적용',
    '재외국민 서류평가',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    60
  ),
  -- KU27-SEC07
  (
    '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'evaluation',
    '면접평가',
    '인문·자연·의학 제시문 10+5분. 예능 서류기반. 장소 서울캠퍼스(요강). 건물·입실은 schedule',
    '재외국민 2단계',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    70
  ),
  -- KU27-SEC08
  (
    '5155c173-53aa-431f-b359-b109de23d067'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '원서접수 유의사항',
    '접수 후 취소 불가, 6회 제한, 최종합격 시 수시·정시 지원 제한 등 p4. S03 24시간·Chrome/Edge·수험표는 같은 주제 추가 citation',
    '2027 특별전형 원서 (재외국민 포함)',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    80
  ),
  -- KU27-SEC09
  (
    'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '등록·이중등록·최종원본',
    'p6. 최종 서류 = 업로드한 모든 서류 + 졸업증명서. 졸업예정자 기한 conflict를 이 row에서 단정하지 않음',
    '재외국민(정원외2%)전형',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    90
  ),
  -- KU27-SEC10
  (
    'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '입학전형 공정성 및 윤리',
    'p7 공정성 조치',
    '특별전형 (재외국민 포함)',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    100
  ),
  -- KU27-SEC11
  (
    '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '학교폭력 조치사항',
    'p7. 국내 고교 재학사실이 있는 자의 학교생활기록부 제출',
    '국내 고교 재학사실이 있는 지원자 포함',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    110
  ),
  -- KU27-SEC12
  (
    '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '제출서류 공통 안내',
    'p11: A4 PDF, 용량, 번역 공증, 미발급 고교 우편 2026.07.09 도착, 필수서류 미제출 불합격',
    '재외국민 서류 제출',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    120
  ),
  -- KU27-SEC13
  (
    'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '교내활동·공인성적 유의사항',
    'p15. predicted/best 제외. 제출 가능 ≠ 지원요건',
    '해당 서류를 제출하는 경우',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    130
  ),
  -- KU27-SEC14
  (
    'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'standardized_tests',
    '공인어학·표준화학력 (선택 평가자료)',
    'TOEFL/HSK/JPT, AP/IB/SAT 등 요강 예시. 최대 5항목. 기관번호 ETS 8228, CB 5443, IBO 002366, ACT 2935는 리포팅 코드이지 최저점이 아님. 최소/권장/합격선 생성 금지. S10 사용 금지',
    '해당자가 평가자료로 제출하는 경우. 미제출을 자격 미달로 해석하지 않음',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    140
  ),
  -- KU27-SEC15
  (
    '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'notes',
    '전형료',
    '예능 250,000원, 그 외 200,000원, 1단계 불합격 반환 30,000원',
    '재외국민(정원외2%)전형',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    150
  ),
  -- KU27-SEC16
  (
    '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'notes',
    '입학 관련 문의',
    'p21 서울캠퍼스 입학처 02-3290-5161~3, oku.korea.ac.kr',
    '재외국민 전형 문의',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    160
  ),
  -- KU27-SEC17
  (
    '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    'caution',
    '면접고사 수험생 유의사항',
    'S04 p2: 신분증, 블라인드, 휴대금지 물품, 대화 금지 등. 고사 운영 규정',
    '1단계 합격 후 면접 응시자',
    'official_fact',
    'available',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    170
  );

-- =============================================================================
-- 7. admission_schedules (15)
-- Migration review metadata (not a DB fact):
--   GMT+9 is stored only for schedules that S05 PDF directly supports.
--   NULL does not mean an official source declared that no timezone exists.
--   It means the approved source did not confirm a timezone value, so this
--   load does not store an inferred timezone.
-- Asia/Seoul is not stored. Date/datetime values are unchanged by this
-- timezone correction. datetime literals may still use +09 offset; that
-- storage offset is not the timezone column.
-- verified_at = latest citation-location confirmation time for that schedule
-- =============================================================================

INSERT INTO public.admission_schedules (
  id,
  admission_program_id,
  event_name,
  temporal_precision,
  start_date,
  end_date,
  start_at,
  end_at,
  timezone,
  location_text,
  description,
  verification_status,
  verified_at,
  display_order
) VALUES
  -- KU27-SCH01
  (
    '0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    'datetime',
    NULL,
    NULL,
    '2026-07-06 10:00:00+09'::timestamptz,
    '2026-07-08 17:00:00+09'::timestamptz,
    NULL,
    '온라인',
    'S03: 기간 중 24시간, Chrome/Edge, 전형료 결제 포함 마감. 개인정보 수정신청은 같은 기간(S03)이며 별도 event로 복제하지 않고 여기에 적음',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    10
  ),
  -- KU27-SCH02
  (
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '온라인 서식 입력 및 온라인 서류제출',
    'datetime',
    NULL,
    NULL,
    '2026-07-06 10:00:00+09'::timestamptz,
    '2026-07-09 17:00:00+09'::timestamptz,
    NULL,
    '온라인 / 입학처 홈페이지',
    'S03는 서식 입력과 서류 업로드를 항으로 나누지만 요강은 한 기간. 한 logical window → 1 row. S03 세부(교내활동확인서 등 서식 대상)는 description',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    20
  ),
  -- KU27-SCH03
  (
    '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '1단계 합격자 발표 및 고사장 발표',
    'datetime',
    NULL,
    NULL,
    '2026-07-31 17:00:00+09'::timestamptz,
    '2026-07-31 17:00:00+09'::timestamptz,
    NULL,
    '입학처 홈페이지',
    '순간 발표. 시간을 추정한 것이 아니라 공식 17:00',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    30
  ),
  -- KU27-SCH04
  (
    'c5492304-0687-4414-acbc-62361928c9f2'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '면접고사',
    'datetime',
    NULL,
    NULL,
    '2026-08-14 12:10:00+09'::timestamptz,
    NULL,
    NULL,
    '고려대학교 서울캠퍼스 우당교양관',
    '요강: 12:30까지 입실 / 서울캠퍼스. S04: 12:10 시작 ~ 12:30 입실완료, 우당교양관. complementary. 면접 종료 시각은 공식 source에 없음 → 추정 금지',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    40
  ),
  -- KU27-SCH05
  (
    '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최초합격자 발표',
    'datetime',
    NULL,
    NULL,
    '2026-09-04 17:00:00+09'::timestamptz,
    '2026-09-04 17:00:00+09'::timestamptz,
    NULL,
    '입학처 홈페이지',
    NULL,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    50
  ),
  -- KU27-SCH06
  (
    '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '문서등록',
    'datetime',
    NULL,
    NULL,
    '2026-12-21 10:00:00+09'::timestamptz,
    '2026-12-23 14:00:00+09'::timestamptz,
    'GMT+9',
    '온라인',
    'S05도 동일 기간 재진술. 복제 row 없음',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    60
  ),
  -- KU27-SCH07
  (
    '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '1차 충원합격 발표 및 등록',
    'datetime',
    NULL,
    NULL,
    '2026-12-23 21:00:00+09'::timestamptz,
    '2026-12-24 14:00:00+09'::timestamptz,
    NULL,
    '입학처 홈페이지',
    'S01 p5 1차 행. 발표와 등록마감을 한 충원 round로 봄',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    70
  ),
  -- KU27-SCH08
  (
    '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '2차 충원합격 발표 및 등록',
    'datetime',
    NULL,
    NULL,
    '2026-12-24 21:00:00+09'::timestamptz,
    '2026-12-27 10:00:00+09'::timestamptz,
    NULL,
    '입학처 홈페이지',
    'S01 p5 2차 행',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    80
  ),
  -- KU27-SCH09
  (
    '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '3차 충원합격 발표 및 등록',
    'datetime',
    NULL,
    NULL,
    '2026-12-27 13:00:00+09'::timestamptz,
    '2026-12-28 10:00:00+09'::timestamptz,
    NULL,
    '입학처 홈페이지',
    'S01 p5 3차 행',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    90
  ),
  -- KU27-SCH10
  (
    '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '등록포기 (문서등록 취소)',
    'datetime',
    NULL,
    NULL,
    NULL,
    '2026-12-29 10:00:00+09'::timestamptz,
    'GMT+9',
    '입학처 홈페이지',
    '마감-only datetime. schema 허용. S05 p3도 ~ 2026.12.29 10:00',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    100
  ),
  -- KU27-SCH11
  (
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격자 원본 서류 제출',
    'date',
    NULL,
    '2027-02-10'::date,
    NULL,
    NULL,
    'GMT+9',
    '우편',
    '요강 p4 「까지」. 도착/등기 조건은 description. 이 end_date를 졸업예정자 졸업증명서의 유일한 기한으로 단정하지 않음. SUB82를 이 schedule에 연결하지 않음',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    110
  ),
  -- KU27-SCH12
  (
    '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '등록금 납부',
    'date',
    '2027-02-15'::date,
    '2027-02-16'::date,
    NULL,
    NULL,
    'GMT+9',
    NULL,
    'S01 p5와 S05가 날짜를 말함. S05 HTML은 상세 일시 추후 공지 → 시간 추정 금지. date precision',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    120
  ),
  -- KU27-SCH13
  (
    '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '입학허가통지서 출력',
    'datetime',
    NULL,
    NULL,
    '2026-09-04 17:00:00+09'::timestamptz,
    '2026-09-30 17:00:00+09'::timestamptz,
    'GMT+9',
    '입학처 홈페이지',
    'S05: 합격자 발표 시 ~ 09.30 17:00. 시작은 최초합격 발표(SCH05)와 같은 공식 시점. 시작 시각을 임의 midnight으로 두지 않음',
    'verified',
    '2026-09-05T17:02:08Z'::timestamptz,
    130
  ),
  -- KU27-SCH14
  (
    'c114aa23-e4e7-4643-a928-b710050cf576'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '면접 편의제공 신청',
    'date',
    NULL,
    '2026-08-11'::date,
    NULL,
    NULL,
    NULL,
    '이메일 (S04)',
    'S04: 2026.08.11까지. 요강 p6는 「면접 2일 전」generic. complementary cycle deadline. 요강을 버려 S04만 쓴 것이 아니라 description에 둘 다 보존',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    140
  ),
  -- KU27-SCH15
  (
    'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '신분증 미소지자 본인확인',
    'datetime',
    NULL,
    NULL,
    '2026-08-18 14:00:00+09'::timestamptz,
    '2026-08-18 17:00:00+09'::timestamptz,
    NULL,
    '입학처 방문',
    'S04 p2. 해당자 조건부 event. 전원 면접이 아니므로 SCH04와 합치지 않음',
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz,
    150
  );

-- =============================================================================
-- 8. required_documents (42)
-- what to submit only. No submission timing/method in this table.
-- verification_status = verified. verified_at = latest supporting citation check time.
-- =============================================================================

INSERT INTO public.required_documents (
  id,
  admission_program_id,
  name,
  description,
  requirement_status,
  condition,
  document_subject_text,
  display_order,
  verification_status,
  verified_at
) VALUES
  -- KU27-DOC01
  (
    '00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '학력조회 동의서',
    NULL,
    '필수',
    NULL,
    '지원자',
    10,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC02
  (
    'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '초등학교 성적‧재학증명서',
    NULL,
    '필수',
    '국외 초등은 성적·재학 중 하나만 제출해도 되나 이수학년·학기·재학기간 명시. 한 표 행 → ChoiceGroup 아님',
    '지원자',
    20,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC03
  (
    'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '중학교 성적‧재학증명서',
    NULL,
    '필수',
    NULL,
    '지원자',
    30,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC04
  (
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '고등학교 성적‧재학‧졸업(예정)증명서',
    NULL,
    '필수',
    '최종 원본에 졸업증명서 포함(p6). 예정자 추가 졸업증명서 기한은 SUB82',
    '지원자',
    40,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC05
  (
    'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '학교과정 특이사항 증빙서류',
    NULL,
    '해당자 필수',
    '성적·재학기록 폐기, 학기 조정, 월반, 조기졸업, 국가재난 결손 등 요강 열거',
    '지원자',
    50,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC06
  (
    '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '국외학교 학사일정표 (School Calendar)',
    NULL,
    '필수',
    NULL,
    '재학한 국외학교',
    60,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC07
  (
    'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '국외고교 School Profile',
    NULL,
    '선택',
    NULL,
    '고등학교',
    70,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC08
  (
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '교내활동확인서',
    NULL,
    '선택',
    NULL,
    '지원자',
    80,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC09
  (
    'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '교내활동증빙서류',
    NULL,
    '해당자 필수',
    '교내활동확인서 제출자',
    '지원자',
    90,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC10
  (
    '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '공인성적표',
    NULL,
    '해당자 필수',
    '원서에 공인성적을 입력한 경우. 미입력을 자격 미달로 해석하지 않음',
    '지원자',
    100,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC11
  (
    '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '포트폴리오 서약서',
    NULL,
    '해당자 필수',
    '디자인조형학부',
    '지원자',
    110,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC12
  (
    '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '포트폴리오',
    NULL,
    '해당자 필수',
    '디자인조형학부. 요강: 서약서와 일괄 스캔 업로드',
    '지원자',
    120,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC13
  (
    'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '여권 사본',
    '분실 시 여권 발급기록증명서 (대체 조건. 열린 「등」이 아니나 조건부여체이므로 별도 자유 ChoiceGroup은 만들지 않음)',
    '필수',
    NULL,
    '지원자',
    130,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC14
  (
    '5e960174-2563-4216-9c82-c159c909e63f'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '여권 사본',
    '분실 시 여권 발급기록증명서 (대체 조건. DOC13과 동일)',
    '필수',
    NULL,
    '부',
    140,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC15
  (
    'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '여권 사본',
    '분실 시 여권 발급기록증명서 (대체 조건. DOC13과 동일)',
    '필수',
    NULL,
    '모',
    150,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC16
  (
    '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '사실증명발급·열람 신청서 및 위임장',
    NULL,
    '필수',
    '서명은 여권과 동일',
    '지원자',
    160,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC17
  (
    '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '사실증명발급·열람 신청서 및 위임장',
    NULL,
    '필수',
    NULL,
    '부',
    170,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC18
  (
    'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '사실증명발급·열람 신청서 및 위임장',
    NULL,
    '필수',
    NULL,
    '모',
    180,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC19
  (
    '91195347-4269-4241-8ab3-202c07785a72'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '개인정보 변경확인요청서',
    NULL,
    '해당자 필수',
    '성명·생년월일 등이 서류와 다른 경우',
    '지원자',
    190,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC20
  (
    '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '주민등록표초본',
    NULL,
    '해당자 필수',
    'p11: 주민등록번호 또는 성명이 다른 지원자. DOC19와 함께',
    '지원자',
    200,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC21
  (
    '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '출입국사실증명서',
    NULL,
    '필수',
    '2026.07.01 이후 발급. 조회기간은 요강 표',
    '지원자',
    210,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC22
  (
    '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '출입국사실증명서',
    NULL,
    '필수',
    NULL,
    '부',
    220,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC23
  (
    '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '출입국사실증명서',
    NULL,
    '필수',
    NULL,
    '모',
    230,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC24
  (
    '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '가족관계증명서',
    NULL,
    '필수',
    '2026.07.01 이후 발급, 지원자 본인 기준',
    '지원자',
    240,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC25
  (
    '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '기본증명서(상세)',
    NULL,
    '해당자 필수',
    '부모 사망',
    '사망한 부 또는 모',
    250,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC26
  (
    'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '제적등본',
    NULL,
    '해당자 필수',
    '부모 사망',
    '사망한 부 또는 모',
    260,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC27
  (
    'b67c787f-9501-47f3-ab55-7541d757739e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '기본증명서(상세)',
    NULL,
    '해당자 필수',
    '부모 이혼/재혼',
    '지원자',
    270,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC28
  (
    'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '혼인관계증명서(상세)',
    NULL,
    '해당자 필수',
    '부모 이혼/재혼',
    '함께 체류 중인 부 또는 모',
    280,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC29
  (
    'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '재외국민등록부 등본',
    '불가·특이 시 비자 사본 등 대체. 「등」열린 대체 → ChoiceGroup 아님',
    '필수',
    '2026.07.01 이후',
    '지원자',
    290,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC30
  (
    '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '재외국민등록부 등본',
    NULL,
    '필수',
    NULL,
    '부',
    300,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC31
  (
    '9f1da499-2035-4924-901f-896bf6519202'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '재외국민등록부 등본',
    NULL,
    '필수',
    NULL,
    '모',
    310,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC32
  (
    '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '개인정보 수집 및 이용 동의서',
    NULL,
    '필수',
    '학부모 작성용 소정 양식',
    '부',
    320,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC33
  (
    'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '개인정보 수집 및 이용 동의서',
    NULL,
    '필수',
    NULL,
    '모',
    330,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC34
  (
    '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '경력증명서 또는 재직증명서',
    NULL,
    '필수',
    '국외파견 재직자 및 현지법인 취업자 표 행. 근무기간·국가명',
    '해외근무 부모 (요강 재직 구분)',
    340,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC35
  (
    'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '해외직접투자신고서(허가서) 또는 해외지사설치인증서',
    NULL,
    '해당자 필수',
    '국외파견 중 상사 주재원. 한 표 셀의 또는 → 공식명을 그대로 한 document',
    '해당 재직 구분',
    350,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC36
  (
    '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '법인 사업자등록증 또는 법인 등기부 등본',
    NULL,
    '필수',
    '현지법인 취업자. 표 셀 또는를 공식명으로 보존',
    '해당 재직 구분',
    360,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC37
  (
    'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '법인세 납부이력',
    '미발급 시 개인 소득세 납부 증명 대체 (조건부여체)',
    '필수',
    '현지법인',
    '해당 재직 구분',
    370,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC38
  (
    'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '사업자등록증 또는 법인 등기부 등본',
    NULL,
    '필수',
    '현지 자영업자',
    '해당 재직 구분',
    380,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC39
  (
    '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '국외 세금납부 증명서',
    NULL,
    '필수',
    '현지 자영업자',
    '해당 재직 구분',
    390,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC40
  (
    'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '학교생활기록부',
    NULL,
    '해당자 필수',
    'p7: 국내 고교 재학사실이 있는 자. 학력서류로 이미 제출한 경우와 중복될 수 있으나 요강이 학교폭력 확인용으로 별도 요구',
    '지원자',
    400,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC41
  (
    '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '출입국사실증명서 (졸업일 기준, 별도 요청)',
    NULL,
    '해당자 필수',
    'S05 PDF: 재외국민 졸업예정자 중 별도 요청한 인원. 조회기간 만 12세 생일~고등학교 졸업일. 일반 DOC21–23과 발급 기준이 다름',
    '지원자·부·모',
    410,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-DOC42
  (
    'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '재직증명서 (고등학교 졸업일 기준, 별도 요청)',
    NULL,
    '해당자 필수',
    'S05 PDF: 별도 요청 인원. DOC34와 기준일 다름',
    '재직자',
    420,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  );

-- =============================================================================
-- 9. document_submissions (84)
-- SUB01-40: online PDF upload against SCH02
-- SUB41-80: original follow-up against SCH11
-- SUB81: unissued-high-school mail, schedule FK NULL
-- SUB82: graduation-certificate deadline conflict, schedule FK NULL, needs_review
-- SUB83-84: S05 extra-request originals against SCH11
-- =============================================================================

INSERT INTO public.document_submissions (
  id,
  required_document_id,
  admission_program_id,
  submission_phase,
  submission_method,
  submission_format,
  admission_schedule_id,
  instructions,
  display_order,
  verification_status,
  verified_at
) VALUES
  -- KU27-SUB01 / KU27-DOC01 online
  (
    '151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid,
    '00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    10,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB02 / KU27-DOC02 online
  (
    '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid,
    'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    20,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB03 / KU27-DOC03 online
  (
    '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid,
    'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    30,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB04 / KU27-DOC04 online
  (
    '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid,
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    40,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB05 / KU27-DOC05 online
  (
    '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid,
    'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    50,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB06 / KU27-DOC06 online
  (
    '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid,
    '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    60,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB07 / KU27-DOC07 online
  (
    'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid,
    'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    70,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB08 / KU27-DOC08 online
  (
    '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid,
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    80,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB09 / KU27-DOC09 online
  (
    '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid,
    'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    90,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB10 / KU27-DOC10 online
  (
    'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid,
    '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '진위확인 수단 또는 2026.07.09까지 스코어리포팅 도착. 기관번호 ETS 8228 등. 별도 document 아님.',
    100,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB11 / KU27-DOC11 online
  (
    '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid,
    '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '두 파일을 일괄 스캔 업로드.',
    110,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB12 / KU27-DOC12 online
  (
    'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid,
    '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '두 파일을 일괄 스캔 업로드.',
    120,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB13 / KU27-DOC13 online
  (
    '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid,
    'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    130,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB14 / KU27-DOC14 online
  (
    '29a72835-9e26-48af-8179-000fe39c52d9'::uuid,
    '5e960174-2563-4216-9c82-c159c909e63f'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    140,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB15 / KU27-DOC15 online
  (
    'f907b240-4650-4e93-af06-efa188ea954d'::uuid,
    'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    150,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB16 / KU27-DOC16 online
  (
    '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid,
    '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    160,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB17 / KU27-DOC17 online
  (
    '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid,
    '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    170,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB18 / KU27-DOC18 online
  (
    '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid,
    'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    180,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB19 / KU27-DOC19 online
  (
    'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid,
    '91195347-4269-4241-8ab3-202c07785a72'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    190,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB20 / KU27-DOC20 online
  (
    'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid,
    '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    200,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB21 / KU27-DOC21 online
  (
    '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid,
    '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    210,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB22 / KU27-DOC22 online
  (
    '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid,
    '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    220,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB23 / KU27-DOC23 online
  (
    'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid,
    '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    230,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB24 / KU27-DOC24 online
  (
    'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid,
    '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    240,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB25 / KU27-DOC25 online
  (
    'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid,
    '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    250,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB26 / KU27-DOC26 online
  (
    '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid,
    'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    260,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB27 / KU27-DOC27 online
  (
    '4b683d44-08da-477e-858e-0bc3df08a654'::uuid,
    'b67c787f-9501-47f3-ab55-7541d757739e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    270,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB28 / KU27-DOC28 online
  (
    '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid,
    'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    280,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB29 / KU27-DOC29 online
  (
    '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid,
    'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    290,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB30 / KU27-DOC30 online
  (
    '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid,
    '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    300,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB31 / KU27-DOC31 online
  (
    'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid,
    '9f1da499-2035-4924-901f-896bf6519202'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '지원자·부·모 순서 병합 PDF (요강).',
    310,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB32 / KU27-DOC32 online
  (
    'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid,
    '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    320,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB33 / KU27-DOC33 online
  (
    'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid,
    'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    330,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB34 / KU27-DOC34 online
  (
    'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid,
    '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    340,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB35 / KU27-DOC35 online
  (
    'de7016e4-9683-4d79-ba96-166171275dfe'::uuid,
    'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    350,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB36 / KU27-DOC36 online
  (
    'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid,
    '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    360,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB37 / KU27-DOC37 online
  (
    '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid,
    'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    370,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB38 / KU27-DOC38 online
  (
    'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid,
    'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    380,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB39 / KU27-DOC39 online
  (
    '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid,
    '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    390,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB40 / KU27-DOC40 online
  (
    '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid,
    'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수',
    '온라인 업로드',
    'PDF',
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    NULL,
    400,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB41 / KU27-DOC01 original follow-up
  (
    '40128241-eaf8-45ae-8eda-c8380851a654'::uuid,
    '00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1010,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB42 / KU27-DOC02 original follow-up
  (
    'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid,
    'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1020,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB43 / KU27-DOC03 original follow-up
  (
    'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid,
    'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1030,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB44 / KU27-DOC04 original follow-up
  (
    '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid,
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1040,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB45 / KU27-DOC05 original follow-up
  (
    'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid,
    'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1050,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB46 / KU27-DOC06 original follow-up
  (
    '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid,
    '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1060,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB47 / KU27-DOC07 original follow-up
  (
    'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid,
    'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1070,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB48 / KU27-DOC08 original follow-up
  (
    '2376356e-8b23-4369-967e-96f1eeadce62'::uuid,
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1080,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB49 / KU27-DOC09 original follow-up
  (
    '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid,
    'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1090,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB50 / KU27-DOC10 original follow-up
  (
    'a845b3b3-857b-483a-9d94-27053887321f'::uuid,
    '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1100,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB51 / KU27-DOC11 original follow-up
  (
    'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid,
    '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1110,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB52 / KU27-DOC12 original follow-up
  (
    '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid,
    '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1120,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB53 / KU27-DOC13 original follow-up
  (
    'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid,
    'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1130,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB54 / KU27-DOC14 original follow-up
  (
    'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid,
    '5e960174-2563-4216-9c82-c159c909e63f'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1140,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB55 / KU27-DOC15 original follow-up
  (
    '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid,
    'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1150,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB56 / KU27-DOC16 original follow-up
  (
    'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid,
    '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1160,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB57 / KU27-DOC17 original follow-up
  (
    '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid,
    '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1170,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB58 / KU27-DOC18 original follow-up
  (
    'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid,
    'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1180,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB59 / KU27-DOC19 original follow-up
  (
    'a9643775-179b-4d12-a570-ae0ee9792884'::uuid,
    '91195347-4269-4241-8ab3-202c07785a72'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1190,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB60 / KU27-DOC20 original follow-up
  (
    '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid,
    '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1200,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB61 / KU27-DOC21 original follow-up
  (
    '3702486f-32f8-4609-953c-d094f1176d18'::uuid,
    '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1210,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB62 / KU27-DOC22 original follow-up
  (
    '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid,
    '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1220,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB63 / KU27-DOC23 original follow-up
  (
    '9be7daf5-106f-43df-b942-8498d64538c4'::uuid,
    '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1230,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB64 / KU27-DOC24 original follow-up
  (
    'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid,
    '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1240,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB65 / KU27-DOC25 original follow-up
  (
    '63aa0858-3025-48e4-8d03-5edce9524585'::uuid,
    '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1250,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB66 / KU27-DOC26 original follow-up
  (
    '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid,
    'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1260,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB67 / KU27-DOC27 original follow-up
  (
    '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid,
    'b67c787f-9501-47f3-ab55-7541d757739e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1270,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB68 / KU27-DOC28 original follow-up
  (
    '07e47072-a515-4fe5-8f38-0f67818df485'::uuid,
    'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1280,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB69 / KU27-DOC29 original follow-up
  (
    'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid,
    'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1290,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB70 / KU27-DOC30 original follow-up
  (
    '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid,
    '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1300,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB71 / KU27-DOC31 original follow-up
  (
    'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid,
    '9f1da499-2035-4924-901f-896bf6519202'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1310,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB72 / KU27-DOC32 original follow-up
  (
    'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid,
    '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1320,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB73 / KU27-DOC33 original follow-up
  (
    '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid,
    'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1330,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB74 / KU27-DOC34 original follow-up
  (
    '92c378bc-158a-4569-9753-2807aac83ed8'::uuid,
    '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1340,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB75 / KU27-DOC35 original follow-up
  (
    'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid,
    'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1350,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB76 / KU27-DOC36 original follow-up
  (
    'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid,
    '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1360,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB77 / KU27-DOC37 original follow-up
  (
    'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid,
    'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1370,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB78 / KU27-DOC38 original follow-up
  (
    '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid,
    'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1380,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB79 / KU27-DOC39 original follow-up
  (
    '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid,
    '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1390,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB80 / KU27-DOC40 original follow-up
  (
    '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid,
    'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후',
    '우편',
    '원본 또는 원본대조 사본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4',
    1400,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB81
  -- display_order 2010 is implementation-only display ordering; not an official admission fact.
  (
    'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid,
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '원서접수 (학력 미발급 고교)',
    '우편',
    '고교 직접 송부',
    NULL,
    '2026.07.09 도착. SCH02 datetime 17:00가 우편 도착에 적용된다고 단정하지 않음. admission_schedule_id NULL.',
    2010,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB82  SAFEGUARD: admission_schedule_id IS NULL; verification_status = needs_review; do not attach SCH11
  -- display_order 2020 is implementation-only display ordering; not an official admission fact.
  (
    '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후 (졸업예정자 졸업증명서 추가)',
    '우편',
    '원본',
    NULL,
    '졸업예정자 졸업증명서 기한 official-source conflict. S01: 최종 원본 마감 2027.02.10 및 최종 서류 = 업로드한 모든 서류 + 졸업증명서. S05 HTML: 원본 2027.2.10 그리고 졸업예정자 졸업증명서 2027년 3월 입학 전. S05 PDF p4: 표 기한 ~2027.2.10, 예정자는 졸업증명서 추가 제출. 오타 단정 금지. 단일 확정 기한 없음. SCH11 UUID를 연결하지 않음. admission_schedule_id NULL.',
    2020,
    'needs_review',
    NULL
  ),
  -- KU27-SUB83
  -- display_order 2030 is implementation-only display ordering; not an official admission fact.
  (
    'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid,
    '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후 (별도 요청)',
    '우편',
    '원본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '해당자. 기한은 원본 패키지 표와 같은 칸. 졸업증명서 HTML 3월 문구와 묶지 않음',
    2030,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-SUB84
  -- display_order 2040 is implementation-only display ordering; not an official admission fact.
  (
    '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid,
    'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
    '최종합격 후 (별도 요청)',
    '우편',
    '원본',
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '해당자',
    2040,
    'verified',
    '2026-09-05T17:02:49Z'::timestamptz
  );

-- =============================================================================
-- 10. required_document_choice_groups (1)
-- Death-substitute documents only. Do not expand other 「또는」 phrases.
-- =============================================================================

-- KU27-CG01
INSERT INTO public.required_document_choice_groups (
  id,
  admission_program_id,
  title,
  rule_text,
  condition,
  display_order,
  verification_status,
  verified_at
) VALUES (
  'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid,
  'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
  '부모 사망 시 가족관계 대체 서류',
  '부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준). 요강 p13 표. any_of / exactly_one enum 만들지 않음.',
  '부모 사망 해당자',
  10,
  'verified',
  '2026-09-05T17:02:49Z'::timestamptz
);

-- =============================================================================
-- 11. required_document_choice_group_items (2)
-- Composite PK; no UUID column.
-- =============================================================================

INSERT INTO public.required_document_choice_group_items (
  choice_group_id,
  required_document_id,
  admission_program_id
) VALUES
  -- KU27-CGI01
  (
    'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid,
    '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
  ),
  -- KU27-CGI02
  (
    'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid,
    'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid,
    'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
  );

-- =============================================================================
-- 12. source_citations (33)
-- PDF: file_page_number = physical 1-based; printed_page_label = ROW_MAP value.
-- HTML: no fake page numbers.
-- verified_at = location re-check time for that citation.
-- No S06 citations.
-- =============================================================================

INSERT INTO public.source_citations (
  id,
  source_document_id,
  file_page_number,
  printed_page_label,
  section,
  anchor_description,
  verified_at
) VALUES
  -- KU27-CIT01
  (
    'c3565efc-a24e-4fbc-857a-769228aebe9b'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    1,
    NULL,
    '표지',
    '2027학년도 특별전형 모집요강 / 서울캠퍼스 / 재외국민(정원외2%)전형',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT02
  (
    'afd292cf-fa31-476c-8807-c95a75b73528'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    3,
    '3',
    'Ⅰ. 모집단위 및 모집인원',
    '재외국민 78명, 계열 배분, 체육교육과 미선발, 학부대학 없음',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT03
  (
    'f11bf897-c662-4b96-b53a-b3fc2847e78f'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    4,
    '4',
    'Ⅱ. 원서 접수 및 서류 제출 일정 (원서·온라인 행)',
    '원서 07.06 10:00–07.08 17:00, 온라인 서식/서류 07.09 17:00',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT04
  (
    '41ea7aa5-847f-4243-97d7-99f2a2226c54'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    4,
    '4',
    'Ⅱ. 원서접수 유의사항',
    '6회 제한, 최종합격 시 수시·정시 지원 제한',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT05
  (
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    5,
    '5',
    'Ⅱ. 전형별 일정',
    '1단계 07.31 17:00, 면접 08.14 12:30 입실, 최초합격 09.04 17:00',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT06
  (
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    5,
    '5',
    'Ⅱ. 합격자 발표 및 등록, 충원 / 등록 포기',
    '문서등록·충원·포기·등록금 날짜',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT07
  (
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    6,
    '6',
    'Ⅲ. 최종합격자 제출 서류',
    '업로드한 모든 서류 + 졸업증명서',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT08
  (
    '95381979-c07c-48ad-8f72-e3ec59ba7158'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    7,
    '7',
    'Ⅲ. 공정성 및 윤리',
    '블라인드·부정행위 등',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT09
  (
    '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    7,
    '7',
    'Ⅲ. 학교폭력 조치사항',
    '국내 고교 재학자 학교생활기록부',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT10
  (
    '3c56af53-f964-44dd-80bf-cd1971520990'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    8,
    '8',
    'Ⅳ. 지원자격 공통',
    '학력·학제·이수학기',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT11
  (
    '62c2e2d1-136b-44df-87d7-07b38d06df20'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    9,
    '9',
    'Ⅳ. 지원자격 공통 (계속)',
    '사례 및 입학 전 졸업 등',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT12
  (
    '6e4d1560-617f-4af2-b0cc-b62fafceca06'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    10,
    '10',
    'Ⅳ. 재외국민(정원외 2%)',
    '자격 표 및 산정',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT13
  (
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    11,
    '11',
    'Ⅳ. 제출서류 안내사항',
    'A4 PDF, 미발급 고교 우편 07.09, 번역',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT14
  (
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    12,
    '12',
    'Ⅳ. 제출서류 상세 (학력·활동·공인)',
    '재외국민 열',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT15
  (
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    13,
    '13',
    'Ⅳ. 제출서류 상세 (여권·출입국·가족)',
    '재외국민 열, 사망/이혼 주석',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT16
  (
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    14,
    '14',
    'Ⅳ. 재직 증빙서류',
    '재외국민 재직 구분',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT17
  (
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    15,
    '15',
    'Ⅳ. 교내활동, 공인성적',
    '선택 평가자료, 리포팅 코드, predicted 제외',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT18
  (
    '176db75a-941c-4980-a004-3644ff564d8b'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    18,
    '18',
    'Ⅴ. 전형요소 가. 재외국민',
    '1단계 100% 3배수, 2단계 70+30',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT19
  (
    'e9a4c088-5f9b-4fda-9efd-5bb3a48542f4'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    19,
    '19',
    'Ⅴ. 서류평가 가',
    '학업 40 / 세계시민 30 / 계열 20 / 공동체 10',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT20
  (
    'bb8b177f-e6b0-45c9-a9f8-6555e5687a09'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    20,
    '20',
    'Ⅵ. 전형료',
    '재외국민 금액·반환',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT21
  (
    '2c1b7752-9057-4f0e-8268-2dca8060ce30'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    21,
    '21',
    'Ⅵ. 연락처',
    '서울캠퍼스 입학처',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT22
  (
    'c48e2898-0398-424c-a259-471be9623e33'::uuid,
    '5e5f6845-dca3-4d4a-8616-7c65bec86c7d'::uuid,
    NULL,
    NULL,
    '게시 본문',
    '2027학년도 특별전형(전기) 제출서류 양식 안내',
    '2026-09-05T17:02:01Z'::timestamptz
  ),
  -- KU27-CIT23
  (
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid,
    '37f271ad-c13d-4650-bb5b-6a54e3777d69'::uuid,
    NULL,
    NULL,
    '게시 본문',
    '원서/서식/업로드 기간, 24시간, 브라우저, 우편 예외, 스코어리포팅 우편',
    '2026-09-05T17:02:03Z'::timestamptz
  ),
  -- KU27-CIT24
  (
    '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid,
    '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid,
    1,
    NULL,
    '면접고사 일시 및 정보',
    '2026-08-14, 12:10–12:30 입실, 우당교양관',
    '2026-09-05T17:02:05Z'::timestamptz
  ),
  -- KU27-CIT25
  (
    '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid,
    '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid,
    2,
    '수험생 유의사항',
    '수험생 유의사항',
    '신분증, 휴대금지, 편의제공 2026.08.11, 미소지 08.18 방문',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT26
  (
    '6291c0e7-05b1-417d-b5ec-e0de8c7dd4d1'::uuid,
    '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid,
    3,
    '[별첨1]',
    '편의제공 요청서',
    '양식. 별도 RequiredDocument로 일반화하지 않음 (해당자 신청서)',
    '2026-09-05T17:02:05Z'::timestamptz
  ),
  -- KU27-CIT27
  (
    'ebff4f8d-115a-4f44-939a-f1d3bc74315e'::uuid,
    'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid,
    NULL,
    NULL,
    'HTML 본문 항 3',
    '원본 2027.2.10 및 졸업예정자 졸업증명서 2027년 3월 입학 전',
    '2026-09-05T17:02:06Z'::timestamptz
  ),
  -- KU27-CIT28
  (
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid,
    'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid,
    NULL,
    NULL,
    'HTML 본문 항 1–2',
    '입학허가통지서 출력, 문서등록, 등록금 날짜·상세 추후',
    '2026-09-05T17:02:06Z'::timestamptz
  ),
  -- KU27-CIT29
  (
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid,
    '31c298f9-cde7-407b-be2d-692235e1a391'::uuid,
    2,
    '- 2 -',
    '신입생 관련 주요 학사 일정',
    '입학허가통지서·문서등록·원본·등록금, GMT+9',
    '2026-09-05T17:02:08Z'::timestamptz
  ),
  -- KU27-CIT30
  (
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid,
    '31c298f9-cde7-407b-be2d-692235e1a391'::uuid,
    4,
    '- 4 -',
    '최종합격자 원본서류 제출 안내',
    '원본 표 ~2027.2.10, 예정자 졸업증명서 추가, 별도 요청 출입국/재직',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT31
  (
    'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    4,
    '4',
    'Ⅱ. 원서 접수 및 서류 제출 일정 (최종원본 행)',
    '최종합격자 원본서류 제출 2027.02.10까지, 우편',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT32
  (
    '0a90841a-83a4-436d-a957-59373077a497'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    6,
    '6',
    'Ⅲ. 기본사항 편의제공',
    '면접 2일 전까지 편의제공 요청서',
    '2026-09-05T17:02:49Z'::timestamptz
  ),
  -- KU27-CIT33
  (
    '9716a890-15a4-46be-98c0-09842d4671f9'::uuid,
    '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
    19,
    '19',
    'Ⅴ. 면접평가 안내',
    '제시문 10+5분 / 예능 서류기반, 서울캠퍼스',
    '2026-09-05T17:02:49Z'::timestamptz
  );

-- =============================================================================
-- 13. admission_section_citations (24)
-- =============================================================================

INSERT INTO public.admission_section_citations (
  admission_section_id,
  source_citation_id
) VALUES
  -- KU27-SCJ01
  (
    'a48538c9-e84f-491d-a246-836ed8c0457d'::uuid,
    '3c56af53-f964-44dd-80bf-cd1971520990'::uuid
  ),
  -- KU27-SCJ02
  (
    'a48538c9-e84f-491d-a246-836ed8c0457d'::uuid,
    '62c2e2d1-136b-44df-87d7-07b38d06df20'::uuid
  ),
  -- KU27-SCJ03
  (
    '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid,
    '6e4d1560-617f-4af2-b0cc-b62fafceca06'::uuid
  ),
  -- KU27-SCJ04
  (
    'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid,
    '6e4d1560-617f-4af2-b0cc-b62fafceca06'::uuid
  ),
  -- KU27-SCJ05
  (
    '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid,
    'afd292cf-fa31-476c-8807-c95a75b73528'::uuid
  ),
  -- KU27-SCJ06
  (
    '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid,
    'c3565efc-a24e-4fbc-857a-769228aebe9b'::uuid
  ),
  -- KU27-SCJ07
  (
    'cedac3d2-df94-4561-adf7-3f6505475981'::uuid,
    '176db75a-941c-4980-a004-3644ff564d8b'::uuid
  ),
  -- KU27-SCJ08
  (
    '22f25f30-a90a-47bb-9006-844894416915'::uuid,
    'e9a4c088-5f9b-4fda-9efd-5bb3a48542f4'::uuid
  ),
  -- KU27-SCJ09
  (
    '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid,
    '9716a890-15a4-46be-98c0-09842d4671f9'::uuid
  ),
  -- KU27-SCJ10
  (
    '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid,
    '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid
  ),
  -- KU27-SCJ11
  (
    '5155c173-53aa-431f-b359-b109de23d067'::uuid,
    '41ea7aa5-847f-4243-97d7-99f2a2226c54'::uuid
  ),
  -- KU27-SCJ12
  (
    '5155c173-53aa-431f-b359-b109de23d067'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-SCJ13
  (
    'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-SCJ14
  (
    'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid,
    '95381979-c07c-48ad-8f72-e3ec59ba7158'::uuid
  ),
  -- KU27-SCJ15
  (
    '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid,
    '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid
  ),
  -- KU27-SCJ16
  (
    '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid,
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid
  ),
  -- KU27-SCJ17
  (
    'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-SCJ18
  (
    'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-SCJ19
  (
    '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid,
    'bb8b177f-e6b0-45c9-a9f8-6555e5687a09'::uuid
  ),
  -- KU27-SCJ20
  (
    '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid,
    '2c1b7752-9057-4f0e-8268-2dca8060ce30'::uuid
  ),
  -- KU27-SCJ21
  (
    '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid,
    '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid
  ),
  -- KU27-SCJ22
  (
    'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid,
    'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid
  ),
  -- KU27-SCJ23
  (
    '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-SCJ24
  (
    '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid,
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid
  );

-- =============================================================================
-- 14. required_document_citations (56)
-- =============================================================================

INSERT INTO public.required_document_citations (
  required_document_id,
  source_citation_id
) VALUES
  -- KU27-DCJ01
  (
    '00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ02
  (
    '00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ03
  (
    'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ04
  (
    'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ05
  (
    'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ06
  (
    'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ07
  (
    'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ08
  (
    '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ09
  (
    'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ10
  (
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ11
  (
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-DCJ12
  (
    'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ13
  (
    'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ14
  (
    'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-DCJ15
  (
    '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-DCJ16
  (
    '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-DCJ17
  (
    '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ18
  (
    '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ19
  (
    '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ20
  (
    '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ21
  (
    'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ22
  (
    '5e960174-2563-4216-9c82-c159c909e63f'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ23
  (
    'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ24
  (
    '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ25
  (
    '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ26
  (
    '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ27
  (
    '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ28
  (
    'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ29
  (
    'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ30
  (
    '91195347-4269-4241-8ab3-202c07785a72'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ31
  (
    '91195347-4269-4241-8ab3-202c07785a72'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ32
  (
    '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid,
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid
  ),
  -- KU27-DCJ33
  (
    '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ34
  (
    '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ35
  (
    '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ36
  (
    '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ37
  (
    '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ38
  (
    'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ39
  (
    'b67c787f-9501-47f3-ab55-7541d757739e'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ40
  (
    'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ41
  (
    'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ42
  (
    '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ43
  (
    '9f1da499-2035-4924-901f-896bf6519202'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ44
  (
    '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ45
  (
    '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ46
  (
    'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-DCJ47
  (
    'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid
  ),
  -- KU27-DCJ48
  (
    '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ49
  (
    'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ50
  (
    '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ51
  (
    'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ52
  (
    'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ53
  (
    '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-DCJ54
  (
    'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid,
    '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid
  ),
  -- KU27-DCJ55
  (
    '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid
  ),
  -- KU27-DCJ56
  (
    'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid
  );

-- =============================================================================
-- 15. document_submission_citations (90)
-- =============================================================================

INSERT INTO public.document_submission_citations (
  document_submission_id,
  source_citation_id
) VALUES
  -- KU27-UCJ001
  (
    '151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ002
  (
    '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ003
  (
    '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ004
  (
    '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ005
  (
    '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ006
  (
    '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ007
  (
    'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ008
  (
    '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ009
  (
    '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ010
  (
    'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid
  ),
  -- KU27-UCJ011
  (
    '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ012
  (
    'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ013
  (
    '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ014
  (
    '29a72835-9e26-48af-8179-000fe39c52d9'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ015
  (
    'f907b240-4650-4e93-af06-efa188ea954d'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ016
  (
    '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ017
  (
    '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ018
  (
    '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ019
  (
    'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ020
  (
    'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid,
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid
  ),
  -- KU27-UCJ021
  (
    '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ022
  (
    '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ023
  (
    'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ024
  (
    'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ025
  (
    'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ026
  (
    '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ027
  (
    '4b683d44-08da-477e-858e-0bc3df08a654'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ028
  (
    '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ029
  (
    '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ030
  (
    '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ031
  (
    'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ032
  (
    'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ033
  (
    'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid
  ),
  -- KU27-UCJ034
  (
    'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ035
  (
    'de7016e4-9683-4d79-ba96-166171275dfe'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ036
  (
    'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ037
  (
    '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ038
  (
    'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ039
  (
    '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid
  ),
  -- KU27-UCJ040
  (
    '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid,
    '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid
  ),
  -- KU27-UCJ041
  (
    'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid
  ),
  -- KU27-UCJ042
  (
    'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-UCJ043
  (
    '40128241-eaf8-45ae-8eda-c8380851a654'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ044
  (
    'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ045
  (
    'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ046
  (
    '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ047
  (
    'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ048
  (
    '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ049
  (
    'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ050
  (
    '2376356e-8b23-4369-967e-96f1eeadce62'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ051
  (
    '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ052
  (
    'a845b3b3-857b-483a-9d94-27053887321f'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ053
  (
    'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ054
  (
    '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ055
  (
    'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ056
  (
    'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ057
  (
    '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ058
  (
    'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ059
  (
    '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ060
  (
    'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ061
  (
    'a9643775-179b-4d12-a570-ae0ee9792884'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ062
  (
    '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ063
  (
    '3702486f-32f8-4609-953c-d094f1176d18'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ064
  (
    '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ065
  (
    '9be7daf5-106f-43df-b942-8498d64538c4'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ066
  (
    'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ067
  (
    '63aa0858-3025-48e4-8d03-5edce9524585'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ068
  (
    '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ069
  (
    '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ070
  (
    '07e47072-a515-4fe5-8f38-0f67818df485'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ071
  (
    'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ072
  (
    '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ073
  (
    'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ074
  (
    'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ075
  (
    '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ076
  (
    '92c378bc-158a-4569-9753-2807aac83ed8'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ077
  (
    'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ078
  (
    'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ079
  (
    'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ080
  (
    '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ081
  (
    '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ082
  (
    '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ083
  (
    'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid,
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid
  ),
  -- KU27-UCJ084
  (
    'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-UCJ085
  (
    '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
    'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid
  ),
  -- KU27-UCJ086
  (
    '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid
  ),
  -- KU27-UCJ087
  (
    '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
    'ebff4f8d-115a-4f44-939a-f1d3bc74315e'::uuid
  ),
  -- KU27-UCJ088
  (
    '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid
  ),
  -- KU27-UCJ089
  (
    'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid
  ),
  -- KU27-UCJ090
  (
    '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid
  );

-- =============================================================================
-- 16. admission_schedule_citations (30)
-- SCH10 cites CIT06, CIT28, CIT29. SCH11 cites CIT31, CIT29.
-- SCH10/SCH11 → CIT29 is timezone provenance only.
-- That is not SUB82 → SCH11. Graduation-certificate conflict stays on SUB82.
-- =============================================================================

INSERT INTO public.admission_schedule_citations (
  admission_schedule_id,
  source_citation_id
) VALUES
  -- KU27-HCJ01
  (
    '0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid,
    'f11bf897-c662-4b96-b53a-b3fc2847e78f'::uuid
  ),
  -- KU27-HCJ02
  (
    '0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-HCJ03
  (
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    'f11bf897-c662-4b96-b53a-b3fc2847e78f'::uuid
  ),
  -- KU27-HCJ04
  (
    '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid
  ),
  -- KU27-HCJ05
  (
    '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid,
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid
  ),
  -- KU27-HCJ06
  (
    '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid,
    '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid
  ),
  -- KU27-HCJ07
  (
    'c5492304-0687-4414-acbc-62361928c9f2'::uuid,
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid
  ),
  -- KU27-HCJ08
  (
    'c5492304-0687-4414-acbc-62361928c9f2'::uuid,
    '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid
  ),
  -- KU27-HCJ09
  (
    '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid,
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid
  ),
  -- KU27-HCJ10
  (
    '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ11
  (
    '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ12
  (
    '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid
  ),
  -- KU27-HCJ13
  (
    '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid
  ),
  -- KU27-HCJ14
  (
    '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ15
  (
    '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ16
  (
    '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ17
  (
    '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ18
  (
    '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid
  ),
  -- KU27-HCJ29  SCH10 → CIT29 timezone provenance; existing CIT29 UUID
  (
    '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid
  ),
  -- KU27-HCJ19
  (
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid
  ),
  -- KU27-HCJ30  SCH11 → CIT29 timezone provenance only; not SUB82 → SCH11
  (
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid
  ),
  -- KU27-HCJ20
  (
    '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid
  ),
  -- KU27-HCJ21
  (
    '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid
  ),
  -- KU27-HCJ22
  (
    '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid
  ),
  -- KU27-HCJ23
  (
    '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid,
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid
  ),
  -- KU27-HCJ24
  (
    '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid
  ),
  -- KU27-HCJ25
  (
    'c114aa23-e4e7-4643-a928-b710050cf576'::uuid,
    '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid
  ),
  -- KU27-HCJ26
  (
    'c114aa23-e4e7-4643-a928-b710050cf576'::uuid,
    '0a90841a-83a4-436d-a957-59373077a497'::uuid
  ),
  -- KU27-HCJ27
  (
    'c114aa23-e4e7-4643-a928-b710050cf576'::uuid,
    '6291c0e7-05b1-417d-b5ec-e0de8c7dd4d1'::uuid
  ),
  -- KU27-HCJ28
  (
    'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid,
    '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid
  );

-- =============================================================================
-- 17. Post-insert dataset-scoped count + critical assertions
-- Counts are scoped to KU27 planned UUIDs / KU27-P01, not whole-table totals.
-- =============================================================================

DO $$
DECLARE
  v_universities integer;
  v_categories integer;
  v_sources integer;
  v_programs integer;
  v_program_sources integer;
  v_sections integer;
  v_schedules integer;
  v_documents integer;
  v_submissions integer;
  v_choice_groups integer;
  v_choice_items integer;
  v_citations integer;
  v_section_cites integer;
  v_document_cites integer;
  v_submission_cites integer;
  v_schedule_cites integer;
  v_citation_relations integer;
  v_tz_gmt9 integer;
  v_tz_null integer;
  v_tz_gmt9_set integer;
  v_tz_null_set integer;
  v_sch10_cit29 integer;
  v_sch11_cit29 integer;
  v_program_status text;
  v_sub82_status text;
  v_sub82_schedule uuid;
  v_s01_supersedes uuid;
  v_s06_in_program_sources integer;
  v_s06_current_relations integer;
  v_provenance_violations integer;
BEGIN
  SELECT count(*) INTO v_universities
  FROM public.universities
  WHERE id = '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid;

  SELECT count(*) INTO v_categories
  FROM public.admission_categories
  WHERE id = '8dcdeb53-4d2c-4840-94cf-3d05948e411a'::uuid;

  SELECT count(*) INTO v_sources
  FROM public.source_documents
  WHERE id IN ('91ce33c3-e327-4681-a267-04c1ba32c172'::uuid, '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid, '5e5f6845-dca3-4d4a-8616-7c65bec86c7d'::uuid, '37f271ad-c13d-4650-bb5b-6a54e3777d69'::uuid, '74ba3585-8912-4bd1-904d-8f942f420e8c'::uuid, 'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid, '31c298f9-cde7-407b-be2d-692235e1a391'::uuid);

  SELECT count(*) INTO v_programs
  FROM public.admission_programs
  WHERE id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_program_sources
  FROM public.admission_program_sources
  WHERE admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_sections
  FROM public.admission_sections
  WHERE id IN ('a48538c9-e84f-491d-a246-836ed8c0457d'::uuid, '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid, 'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid, '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid, 'cedac3d2-df94-4561-adf7-3f6505475981'::uuid, '22f25f30-a90a-47bb-9006-844894416915'::uuid, '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid, '5155c173-53aa-431f-b359-b109de23d067'::uuid, 'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid, 'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid, '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid, '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid, 'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid, 'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid, '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid, '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid, '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid)
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_schedules
  FROM public.admission_schedules
  WHERE id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid)
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_documents
  FROM public.required_documents
  WHERE id IN ('00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid, 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid, 'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid, 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid, 'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid, '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid, 'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid, 'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid, 'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid, '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid, '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid, '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid, 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid, '5e960174-2563-4216-9c82-c159c909e63f'::uuid, 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid, '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid, '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid, 'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid, '91195347-4269-4241-8ab3-202c07785a72'::uuid, '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid, '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid, '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid, '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid, '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid, '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid, 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid, 'b67c787f-9501-47f3-ab55-7541d757739e'::uuid, 'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid, 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid, '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid, '9f1da499-2035-4924-901f-896bf6519202'::uuid, '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid, 'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid, '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid, 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid, '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid, 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid, 'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid, '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid, 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid, '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid, 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid)
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_submissions
  FROM public.document_submissions
  WHERE id IN ('151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid, '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid, '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid, '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid, '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid, '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid, 'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid, '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid, '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid, 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid, '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid, 'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid, '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid, '29a72835-9e26-48af-8179-000fe39c52d9'::uuid, 'f907b240-4650-4e93-af06-efa188ea954d'::uuid, '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid, '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid, '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid, 'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid, 'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid, '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid, '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid, 'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid, 'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid, 'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid, '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid, '4b683d44-08da-477e-858e-0bc3df08a654'::uuid, '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid, '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid, '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid, 'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid, 'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid, 'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid, 'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid, 'de7016e4-9683-4d79-ba96-166171275dfe'::uuid, 'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid, '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid, 'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid, '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid, '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid, '40128241-eaf8-45ae-8eda-c8380851a654'::uuid, 'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid, 'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid, '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid, 'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid, '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid, 'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid, '2376356e-8b23-4369-967e-96f1eeadce62'::uuid, '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid, 'a845b3b3-857b-483a-9d94-27053887321f'::uuid, 'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid, '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid, 'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid, 'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid, '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid, 'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid, '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid, 'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid, 'a9643775-179b-4d12-a570-ae0ee9792884'::uuid, '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid, '3702486f-32f8-4609-953c-d094f1176d18'::uuid, '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid, '9be7daf5-106f-43df-b942-8498d64538c4'::uuid, 'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid, '63aa0858-3025-48e4-8d03-5edce9524585'::uuid, '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid, '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid, '07e47072-a515-4fe5-8f38-0f67818df485'::uuid, 'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid, '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid, 'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid, 'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid, '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid, '92c378bc-158a-4569-9753-2807aac83ed8'::uuid, 'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid, 'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid, 'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid, '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid, '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid, '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid, 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid, '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid, 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid, '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid)
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_choice_groups
  FROM public.required_document_choice_groups
  WHERE id = 'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_choice_items
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = 'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  SELECT count(*) INTO v_citations
  FROM public.source_citations
  WHERE id IN ('c3565efc-a24e-4fbc-857a-769228aebe9b'::uuid, 'afd292cf-fa31-476c-8807-c95a75b73528'::uuid, 'f11bf897-c662-4b96-b53a-b3fc2847e78f'::uuid, '41ea7aa5-847f-4243-97d7-99f2a2226c54'::uuid, '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid, '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid, '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid, '95381979-c07c-48ad-8f72-e3ec59ba7158'::uuid, '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid, '3c56af53-f964-44dd-80bf-cd1971520990'::uuid, '62c2e2d1-136b-44df-87d7-07b38d06df20'::uuid, '6e4d1560-617f-4af2-b0cc-b62fafceca06'::uuid, 'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid, 'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid, 'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid, 'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid, '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid, '176db75a-941c-4980-a004-3644ff564d8b'::uuid, 'e9a4c088-5f9b-4fda-9efd-5bb3a48542f4'::uuid, 'bb8b177f-e6b0-45c9-a9f8-6555e5687a09'::uuid, '2c1b7752-9057-4f0e-8268-2dca8060ce30'::uuid, 'c48e2898-0398-424c-a259-471be9623e33'::uuid, '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid, '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid, '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid, '6291c0e7-05b1-417d-b5ec-e0de8c7dd4d1'::uuid, 'ebff4f8d-115a-4f44-939a-f1d3bc74315e'::uuid, 'b2300055-7f04-4805-8938-00d2fb292df4'::uuid, '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid, '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid, 'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid, '0a90841a-83a4-436d-a957-59373077a497'::uuid, '9716a890-15a4-46be-98c0-09842d4671f9'::uuid);

  SELECT count(*) INTO v_section_cites
  FROM public.admission_section_citations
  WHERE admission_section_id IN ('a48538c9-e84f-491d-a246-836ed8c0457d'::uuid, '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid, 'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid, '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid, 'cedac3d2-df94-4561-adf7-3f6505475981'::uuid, '22f25f30-a90a-47bb-9006-844894416915'::uuid, '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid, '5155c173-53aa-431f-b359-b109de23d067'::uuid, 'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid, 'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid, '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid, '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid, 'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid, 'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid, '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid, '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid, '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid);

  SELECT count(*) INTO v_document_cites
  FROM public.required_document_citations
  WHERE required_document_id IN ('00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid, 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid, 'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid, 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid, 'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid, '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid, 'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid, 'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid, 'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid, '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid, '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid, '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid, 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid, '5e960174-2563-4216-9c82-c159c909e63f'::uuid, 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid, '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid, '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid, 'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid, '91195347-4269-4241-8ab3-202c07785a72'::uuid, '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid, '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid, '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid, '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid, '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid, '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid, 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid, 'b67c787f-9501-47f3-ab55-7541d757739e'::uuid, 'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid, 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid, '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid, '9f1da499-2035-4924-901f-896bf6519202'::uuid, '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid, 'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid, '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid, 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid, '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid, 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid, 'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid, '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid, 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid, '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid, 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid);

  SELECT count(*) INTO v_submission_cites
  FROM public.document_submission_citations
  WHERE document_submission_id IN ('151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid, '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid, '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid, '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid, '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid, '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid, 'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid, '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid, '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid, 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid, '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid, 'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid, '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid, '29a72835-9e26-48af-8179-000fe39c52d9'::uuid, 'f907b240-4650-4e93-af06-efa188ea954d'::uuid, '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid, '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid, '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid, 'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid, 'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid, '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid, '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid, 'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid, 'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid, 'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid, '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid, '4b683d44-08da-477e-858e-0bc3df08a654'::uuid, '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid, '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid, '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid, 'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid, 'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid, 'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid, 'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid, 'de7016e4-9683-4d79-ba96-166171275dfe'::uuid, 'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid, '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid, 'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid, '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid, '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid, '40128241-eaf8-45ae-8eda-c8380851a654'::uuid, 'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid, 'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid, '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid, 'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid, '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid, 'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid, '2376356e-8b23-4369-967e-96f1eeadce62'::uuid, '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid, 'a845b3b3-857b-483a-9d94-27053887321f'::uuid, 'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid, '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid, 'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid, 'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid, '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid, 'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid, '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid, 'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid, 'a9643775-179b-4d12-a570-ae0ee9792884'::uuid, '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid, '3702486f-32f8-4609-953c-d094f1176d18'::uuid, '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid, '9be7daf5-106f-43df-b942-8498d64538c4'::uuid, 'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid, '63aa0858-3025-48e4-8d03-5edce9524585'::uuid, '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid, '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid, '07e47072-a515-4fe5-8f38-0f67818df485'::uuid, 'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid, '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid, 'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid, 'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid, '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid, '92c378bc-158a-4569-9753-2807aac83ed8'::uuid, 'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid, 'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid, 'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid, '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid, '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid, '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid, 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid, '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid, 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid, '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid);

  SELECT count(*) INTO v_schedule_cites
  FROM public.admission_schedule_citations
  WHERE admission_schedule_id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid);

  v_citation_relations :=
    v_section_cites + v_document_cites + v_submission_cites + v_schedule_cites;

  IF v_universities <> 1
     OR v_categories <> 1
     OR v_sources <> 7
     OR v_programs <> 1
     OR v_program_sources <> 6
     OR v_sections <> 17
     OR v_schedules <> 15
     OR v_documents <> 42
     OR v_submissions <> 84
     OR v_choice_groups <> 1
     OR v_choice_items <> 2
     OR v_citations <> 33
     OR v_section_cites <> 24
     OR v_document_cites <> 56
     OR v_submission_cites <> 90
     OR v_schedule_cites <> 30
     OR v_citation_relations <> 200 THEN
    RAISE EXCEPTION
      'KU27 count assertion failed: universities=%, categories=%, sources=%, programs=%, program_sources=%, sections=%, schedules=%, documents=%, submissions=%, choice_groups=%, choice_items=%, citations=%, section_cites=%, document_cites=%, submission_cites=%, schedule_cites=%, citation_relations=%',
      v_universities, v_categories, v_sources, v_programs, v_program_sources,
      v_sections, v_schedules, v_documents, v_submissions, v_choice_groups,
      v_choice_items, v_citations, v_section_cites, v_document_cites,
      v_submission_cites, v_schedule_cites, v_citation_relations;
  END IF;

  -- A. AdmissionProgram verification_status
  SELECT verification_status INTO v_program_status
  FROM public.admission_programs
  WHERE id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;

  IF v_program_status IS DISTINCT FROM 'partially_verified' THEN
    RAISE EXCEPTION
      'KU27 critical A failed: KU27-P01 verification_status=%', v_program_status;
  END IF;

  -- B/C. SUB82 needs_review and schedule FK NULL
  SELECT verification_status, admission_schedule_id
    INTO v_sub82_status, v_sub82_schedule
  FROM public.document_submissions
  WHERE id = '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;

  IF v_sub82_status IS DISTINCT FROM 'needs_review' THEN
    RAISE EXCEPTION
      'KU27 critical B failed: KU27-SUB82 verification_status=%', v_sub82_status;
  END IF;

  IF v_sub82_schedule IS NOT NULL THEN
    RAISE EXCEPTION
      'KU27 critical C failed: KU27-SUB82 admission_schedule_id must stay NULL; found %',
      v_sub82_schedule;
  END IF;

  -- D. S01 supersedes S06
  SELECT supersedes_source_document_id INTO v_s01_supersedes
  FROM public.source_documents
  WHERE id = '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid;

  IF v_s01_supersedes IS DISTINCT FROM '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid THEN
    RAISE EXCEPTION
      'KU27 critical D failed: KU27-SRC02.supersedes_source_document_id=%',
      v_s01_supersedes;
  END IF;

  -- E. S06 not in current program sources
  SELECT count(*) INTO v_s06_in_program_sources
  FROM public.admission_program_sources
  WHERE admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
    AND source_document_id = '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;

  IF v_s06_in_program_sources <> 0 THEN
    RAISE EXCEPTION
      'KU27 critical E failed: historical KU27-SRC01 is in admission_program_sources';
  END IF;

  -- F. S06 must not back any current entity citation relation
  SELECT
    (
      SELECT count(*)
      FROM public.admission_section_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid
        AND r.admission_section_id IN ('a48538c9-e84f-491d-a246-836ed8c0457d'::uuid, '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid, 'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid, '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid, 'cedac3d2-df94-4561-adf7-3f6505475981'::uuid, '22f25f30-a90a-47bb-9006-844894416915'::uuid, '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid, '5155c173-53aa-431f-b359-b109de23d067'::uuid, 'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid, 'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid, '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid, '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid, 'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid, 'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid, '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid, '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid, '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid)
    )
    + (
      SELECT count(*)
      FROM public.required_document_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid
        AND r.required_document_id IN ('00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid, 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid, 'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid, 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid, 'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid, '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid, 'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid, 'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid, 'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid, '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid, '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid, '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid, 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid, '5e960174-2563-4216-9c82-c159c909e63f'::uuid, 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid, '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid, '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid, 'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid, '91195347-4269-4241-8ab3-202c07785a72'::uuid, '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid, '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid, '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid, '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid, '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid, '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid, 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid, 'b67c787f-9501-47f3-ab55-7541d757739e'::uuid, 'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid, 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid, '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid, '9f1da499-2035-4924-901f-896bf6519202'::uuid, '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid, 'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid, '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid, 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid, '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid, 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid, 'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid, '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid, 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid, '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid, 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid)
    )
    + (
      SELECT count(*)
      FROM public.document_submission_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid
        AND r.document_submission_id IN ('151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid, '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid, '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid, '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid, '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid, '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid, 'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid, '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid, '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid, 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid, '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid, 'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid, '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid, '29a72835-9e26-48af-8179-000fe39c52d9'::uuid, 'f907b240-4650-4e93-af06-efa188ea954d'::uuid, '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid, '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid, '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid, 'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid, 'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid, '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid, '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid, 'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid, 'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid, 'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid, '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid, '4b683d44-08da-477e-858e-0bc3df08a654'::uuid, '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid, '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid, '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid, 'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid, 'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid, 'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid, 'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid, 'de7016e4-9683-4d79-ba96-166171275dfe'::uuid, 'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid, '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid, 'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid, '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid, '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid, '40128241-eaf8-45ae-8eda-c8380851a654'::uuid, 'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid, 'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid, '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid, 'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid, '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid, 'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid, '2376356e-8b23-4369-967e-96f1eeadce62'::uuid, '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid, 'a845b3b3-857b-483a-9d94-27053887321f'::uuid, 'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid, '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid, 'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid, 'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid, '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid, 'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid, '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid, 'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid, 'a9643775-179b-4d12-a570-ae0ee9792884'::uuid, '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid, '3702486f-32f8-4609-953c-d094f1176d18'::uuid, '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid, '9be7daf5-106f-43df-b942-8498d64538c4'::uuid, 'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid, '63aa0858-3025-48e4-8d03-5edce9524585'::uuid, '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid, '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid, '07e47072-a515-4fe5-8f38-0f67818df485'::uuid, 'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid, '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid, 'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid, 'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid, '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid, '92c378bc-158a-4569-9753-2807aac83ed8'::uuid, 'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid, 'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid, 'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid, '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid, '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid, '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid, 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid, '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid, 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid, '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid)
    )
    + (
      SELECT count(*)
      FROM public.admission_schedule_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid
        AND r.admission_schedule_id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid)
    )
  INTO v_s06_current_relations;

  IF v_s06_current_relations <> 0 THEN
    RAISE EXCEPTION
      'KU27 critical F failed: historical KU27-SRC01 appears in % current citation relations',
      v_s06_current_relations;
  END IF;

  -- G. S05 HTML and S05 PDF are distinct SourceDocument UUIDs
  IF 'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid = '31c298f9-cde7-407b-be2d-692235e1a391'::uuid THEN
    RAISE EXCEPTION
      'KU27 critical G failed: S05 HTML and S05 PDF share the same UUID';
  END IF;

  IF (
    SELECT count(DISTINCT id)
    FROM public.source_documents
    WHERE id IN ('b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid, '31c298f9-cde7-407b-be2d-692235e1a391'::uuid)
  ) <> 2 THEN
    RAISE EXCEPTION
      'KU27 critical G failed: S05 HTML/PDF SourceDocument rows are not two distinct rows';
  END IF;

  -- H. planned citation relation total
  IF v_citation_relations <> 200 THEN
    RAISE EXCEPTION
      'KU27 critical H failed: citation relation total=%', v_citation_relations;
  END IF;

  -- I. timezone dataset validation (approved ROW_MAP; not new admission facts)
  -- GMT+9 = 5, NULL = 10 among the 15 planned KU27 schedule UUIDs.
  SELECT count(*) INTO v_tz_gmt9
  FROM public.admission_schedules
  WHERE id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid)
    AND timezone = 'GMT+9';

  SELECT count(*) INTO v_tz_null
  FROM public.admission_schedules
  WHERE id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid)
    AND timezone IS NULL;

  IF v_tz_gmt9 <> 5 OR v_tz_null <> 10 THEN
    RAISE EXCEPTION
      'KU27 critical I failed: KU27 schedule timezone counts gmt9=% null=%',
      v_tz_gmt9, v_tz_null;
  END IF;

  -- J. GMT+9 logical set is exactly SCH06, SCH10, SCH11, SCH12, SCH13
  SELECT count(*) INTO v_tz_gmt9_set
  FROM public.admission_schedules
  WHERE id IN (
      '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
      '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
      '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
      '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
      '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid
    )
    AND timezone = 'GMT+9';

  IF v_tz_gmt9_set <> 5 THEN
    RAISE EXCEPTION
      'KU27 critical J failed: GMT+9 set is not exactly SCH06/SCH10/SCH11/SCH12/SCH13';
  END IF;

  -- K. NULL logical set is exactly SCH01–SCH05, SCH07–SCH09, SCH14, SCH15
  SELECT count(*) INTO v_tz_null_set
  FROM public.admission_schedules
  WHERE id IN (
      '0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid,
      '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid,
      '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid,
      'c5492304-0687-4414-acbc-62361928c9f2'::uuid,
      '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid,
      '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid,
      '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid,
      '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid,
      'c114aa23-e4e7-4643-a928-b710050cf576'::uuid,
      'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid
    )
    AND timezone IS NULL;

  IF v_tz_null_set <> 10 THEN
    RAISE EXCEPTION
      'KU27 critical K failed: NULL timezone set is not exactly SCH01–05/07–09/14–15';
  END IF;

  -- L. SCH10 → CIT29 and SCH11 → CIT29 exist exactly once each
  SELECT count(*) INTO v_sch10_cit29
  FROM public.admission_schedule_citations
  WHERE admission_schedule_id = '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid
    AND source_citation_id = '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;

  SELECT count(*) INTO v_sch11_cit29
  FROM public.admission_schedule_citations
  WHERE admission_schedule_id = '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid
    AND source_citation_id = '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;

  IF v_sch10_cit29 <> 1 THEN
    RAISE EXCEPTION
      'KU27 critical L failed: SCH10→CIT29 relation count=%', v_sch10_cit29;
  END IF;

  IF v_sch11_cit29 <> 1 THEN
    RAISE EXCEPTION
      'KU27 critical L failed: SCH11→CIT29 relation count=%', v_sch11_cit29;
  END IF;

  -- Provenance: current fact Entity → SourceCitation → SourceDocument
  -- must be in this program's admission_program_sources.
  -- Historical S06 is excluded from program sources and must not appear.
  SELECT
    (
      SELECT count(*)
      FROM public.admission_section_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE r.admission_section_id IN ('a48538c9-e84f-491d-a246-836ed8c0457d'::uuid, '70bd3f0b-1bdb-4d41-b9a6-e212dc357384'::uuid, 'da1f69d4-6d39-40ac-ac27-7c30ec25cc4d'::uuid, '4a2ac737-495b-47d9-aa2c-bfef80b28c06'::uuid, 'cedac3d2-df94-4561-adf7-3f6505475981'::uuid, '22f25f30-a90a-47bb-9006-844894416915'::uuid, '1e51791e-1185-412f-875e-c0a319c8ff74'::uuid, '5155c173-53aa-431f-b359-b109de23d067'::uuid, 'dde58a87-0bda-4719-9eb6-53422d6171e8'::uuid, 'abcc8c9e-6d1f-4f5c-a853-0ce1a0e9f07c'::uuid, '6d4366c9-db5e-479d-a2b3-0181e2d9ad70'::uuid, '809f5867-c5b0-4303-92ac-2638e639a3d7'::uuid, 'f63a6508-fb67-41c9-a45d-006e7a185708'::uuid, 'f99d7eb4-e22a-4403-92c7-62c22d982599'::uuid, '179b4b81-02ae-449d-871d-8d476d7531e1'::uuid, '041e8c6c-1af9-4923-be3b-3986042c85fb'::uuid, '8f982f86-a754-4b54-852e-8e437686fb4d'::uuid)
        AND NOT EXISTS (
          SELECT 1
          FROM public.admission_program_sources ps
          WHERE ps.admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
            AND ps.source_document_id = c.source_document_id
        )
    )
    + (
      SELECT count(*)
      FROM public.required_document_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE r.required_document_id IN ('00374bb7-1b3a-4512-8e9d-79411ec501b4'::uuid, 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid, 'af30dffe-79dd-4d18-8cc9-6f4cc68415f2'::uuid, 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid, 'e87baf54-e349-4538-a9d6-9fb57165b46d'::uuid, '89d4569b-5755-4ed1-8764-05bca50f8156'::uuid, 'cbc89162-2907-407e-9ab2-5ab015de1861'::uuid, 'ecbe5437-3dec-4ca1-bad7-eded630355db'::uuid, 'b74d1a53-4fa0-4764-96a7-c405cb6adbbd'::uuid, '1220efd4-c1f5-454c-acd7-ce2f04c87b79'::uuid, '178c5669-c08c-46d4-aedd-440408ec4a48'::uuid, '009c40a0-8842-4fa0-8cd0-9af60ebccc0b'::uuid, 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid, '5e960174-2563-4216-9c82-c159c909e63f'::uuid, 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid, '4d71e45c-67a6-4897-b65f-d8ee4ffd7a46'::uuid, '3ab05019-48fa-4f8f-b04b-66030cc9e300'::uuid, 'd5b485a4-c479-4071-98fa-2c4a091aa77b'::uuid, '91195347-4269-4241-8ab3-202c07785a72'::uuid, '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid, '06ed2880-4299-4e42-aae9-e07e7f3046f7'::uuid, '03df8c9d-4e11-43a7-9f4c-c67377c543d7'::uuid, '5c75ecb5-fdcd-4a08-bd1a-90d77a90e6a7'::uuid, '4e7b0130-7912-4b68-90c4-16d0cd7d3bd9'::uuid, '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid, 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid, 'b67c787f-9501-47f3-ab55-7541d757739e'::uuid, 'dc71327c-5824-43f9-87c8-e9d6e1136c9a'::uuid, 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid, '4175ba83-10e7-4115-a5ab-81446d047e07'::uuid, '9f1da499-2035-4924-901f-896bf6519202'::uuid, '1a0fb498-2364-4308-a599-f8d539a1584b'::uuid, 'ceb8319a-5af9-4f35-8f68-f62da2d74e7e'::uuid, '3a3122b0-d28f-4b6f-bb07-5a5407424856'::uuid, 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid, '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid, 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid, 'c714d0d8-4753-4bcc-b8d7-96a0541f7f4e'::uuid, '495f097c-bd19-4266-88a8-97ad06bf9450'::uuid, 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid, '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid, 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid)
        AND NOT EXISTS (
          SELECT 1
          FROM public.admission_program_sources ps
          WHERE ps.admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
            AND ps.source_document_id = c.source_document_id
        )
    )
    + (
      SELECT count(*)
      FROM public.document_submission_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE r.document_submission_id IN ('151debf4-c6a6-48d7-973d-d57a2d462c2d'::uuid, '63228f0e-997b-40b6-8e14-78b5066aa50a'::uuid, '615201e6-7c1e-4f9c-a691-bc5ad6e9a0e6'::uuid, '4628c624-5610-4408-a79b-89fbb5d38b4c'::uuid, '3b8767d4-9109-4a8e-a4d0-d146ad04bd2e'::uuid, '4ae9568b-b5a8-4ded-92ff-47150459dd02'::uuid, 'd65c0105-cf16-47c4-82e2-435e039e1269'::uuid, '79ec6857-fa8a-4a7e-9177-287cda5917b9'::uuid, '13af8262-d6bc-45d8-94c3-4d8c81acf0fc'::uuid, 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid, '3cb31bd6-fd60-4ec6-833c-9fe926829d19'::uuid, 'f029b865-f1cd-45d5-9a1a-e1b774150a23'::uuid, '0f050d6e-759d-4eb1-8bf6-d81e0ffe8c32'::uuid, '29a72835-9e26-48af-8179-000fe39c52d9'::uuid, 'f907b240-4650-4e93-af06-efa188ea954d'::uuid, '4ccbc9d4-9832-4bbb-ad3d-ede6ecfb39c5'::uuid, '6d80fe21-462d-4d7e-987a-7f8c8c358c63'::uuid, '0b8dfab1-1f7f-405e-80cc-534bc716eaac'::uuid, 'fbd925f2-35dd-4c9e-a5c5-05e4cde45951'::uuid, 'e3d86357-4984-48ef-ad3c-d6dfed4ad372'::uuid, '1aac891f-476f-47dc-8cc4-d87e637d0017'::uuid, '64ba165f-ddfa-4eb6-99c4-fac6d3b1482c'::uuid, 'b8de7ab7-daf2-47fb-b0a8-c55c28b1041d'::uuid, 'aebfe7a1-84d8-4d90-af5f-20c2ef7c4eb2'::uuid, 'a40e547d-5ec1-41f6-a519-2b69b590ac85'::uuid, '29e8bca6-fe79-44b8-8d4b-f564e45d706e'::uuid, '4b683d44-08da-477e-858e-0bc3df08a654'::uuid, '5dc0a855-71ec-4e88-b8be-4be35c50e795'::uuid, '52d74e90-7f36-406d-9226-e99a6744d7b9'::uuid, '10176c74-d1b0-4ad1-8b82-92d65b750318'::uuid, 'd2ff3a1e-27f4-41b6-9acd-795916a400d5'::uuid, 'd5e392de-759a-49d8-bb2e-9518706f6768'::uuid, 'f5f650d1-4225-4cae-839e-1aa7cbd1dd19'::uuid, 'faba863d-9b55-4d6e-9ca2-59f8ba0b9923'::uuid, 'de7016e4-9683-4d79-ba96-166171275dfe'::uuid, 'c98cd215-38e1-4df1-8ccd-6273543febcb'::uuid, '2eb6b088-6b76-4c40-ba03-32e2e5e80013'::uuid, 'c7801354-c971-4af6-8f30-72592f63e0ad'::uuid, '3a6e9430-cf5d-467d-9d2d-33c864fa4bab'::uuid, '4b3e7a80-c040-4452-8d6e-8a31e7d54aa3'::uuid, '40128241-eaf8-45ae-8eda-c8380851a654'::uuid, 'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid, 'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid, '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid, 'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid, '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid, 'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid, '2376356e-8b23-4369-967e-96f1eeadce62'::uuid, '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid, 'a845b3b3-857b-483a-9d94-27053887321f'::uuid, 'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid, '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid, 'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid, 'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid, '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid, 'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid, '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid, 'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid, 'a9643775-179b-4d12-a570-ae0ee9792884'::uuid, '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid, '3702486f-32f8-4609-953c-d094f1176d18'::uuid, '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid, '9be7daf5-106f-43df-b942-8498d64538c4'::uuid, 'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid, '63aa0858-3025-48e4-8d03-5edce9524585'::uuid, '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid, '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid, '07e47072-a515-4fe5-8f38-0f67818df485'::uuid, 'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid, '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid, 'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid, 'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid, '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid, '92c378bc-158a-4569-9753-2807aac83ed8'::uuid, 'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid, 'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid, 'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid, '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid, '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid, '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid, 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid, '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid, 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid, '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid)
        AND NOT EXISTS (
          SELECT 1
          FROM public.admission_program_sources ps
          WHERE ps.admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
            AND ps.source_document_id = c.source_document_id
        )
    )
    + (
      SELECT count(*)
      FROM public.admission_schedule_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE r.admission_schedule_id IN ('0c7fbc83-e4c3-427c-8f3c-e502c2b5fae7'::uuid, '5fd7701e-196e-48ea-80e6-b2e5ed20b8e7'::uuid, '3bdaa20a-78aa-4dd2-abd7-602226dc5781'::uuid, 'c5492304-0687-4414-acbc-62361928c9f2'::uuid, '255ad4c7-5dad-4d01-8652-70a6e6f60586'::uuid, '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, '4972bc72-1628-4275-b419-1d7ff0adf70d'::uuid, '4b21a66c-c029-4443-8016-1023cd85a4cb'::uuid, '9badf2f4-abf6-485f-bd13-3997cff34f9d'::uuid, '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'c114aa23-e4e7-4643-a928-b710050cf576'::uuid, 'b3976703-2d4f-43a6-aaa5-7ad57698783f'::uuid)
        AND NOT EXISTS (
          SELECT 1
          FROM public.admission_program_sources ps
          WHERE ps.admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
            AND ps.source_document_id = c.source_document_id
        )
    )
  INTO v_provenance_violations;

  IF v_provenance_violations > 0 THEN
    RAISE EXCEPTION
      'KU27 provenance assertion failed: % current citation relations point at a SourceDocument that is not in admission_program_sources for KU27-P01',
      v_provenance_violations;
  END IF;
END
$$;
