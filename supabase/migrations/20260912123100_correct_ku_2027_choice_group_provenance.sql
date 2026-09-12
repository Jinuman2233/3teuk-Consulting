-- KU 2027 CG01 user-safe text + direct ChoiceGroup provenance.
--
-- DATA ONLY. No schema / type / function / trigger / policy / index changes.
-- Requires 20260912123000_add_choice_group_citations.sql.
--
-- Official source re-check (implementation, not planning):
--   S01 current June 배포용
--   https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf
--   physical page 13 / printed page 13
--   SHA-256 eb7f5ff175dd1140e9b5e6fc64efb30d7426954db07743d05a92a1b2082389a2
--   confirmed 2026-09-12T08:11:54Z
--   Official cell:
--     부모가 사망한 경우
--     기본증명서(상세) 또는 제적등본 1부
--     (사망한 부 또는 모 기준)
--   Not in source: 택1 / exactly_one / 대체.
--
-- Removed from stored rule_text (internal load notes, not official wording):
--   "요강 p13 표."
--   "any_of / exactly_one enum 만들지 않음."
--
-- Do not invent admission facts. Do not UPSERT. Do not ON CONFLICT DO NOTHING.
-- Do not DELETE. Do not use now() / CURRENT_TIMESTAMP for verified_at.
-- Do not edit 20260905160000_load_ku_2027_reentry.sql.
--
-- UUID strategy: one fixed UUIDv4 per new UUID PK, written literally.
-- KU27-CIT34 = 6cc44f83-0936-4f73-9e97-a5ff99ce87fd
--
-- Logical IDs in comments (KU27-*) are documentation only, not DB fields.

-- =============================================================================
-- 0. Fail-fast guards
-- =============================================================================

DO $$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_cg01_id uuid := 'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid;
  v_doc25_id uuid := '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid;
  v_doc26_id uuid := 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid;
  v_doc27_id uuid := 'b67c787f-9501-47f3-ab55-7541d757739e'::uuid;
  v_src02_id uuid := '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_cit15_id uuid := 'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid;
  v_cit34_id uuid := '6cc44f83-0936-4f73-9e97-a5ff99ce87fd'::uuid;
  v_cg_count integer;
  v_title text;
  v_rule_text text;
  v_condition text;
  v_program_fk uuid;
  v_member_count integer;
  v_doc25_member integer;
  v_doc26_member integer;
  v_doc27_member integer;
  v_src02_title text;
  v_src02_url text;
  v_src02_in_program integer;
  v_s06_in_program integer;
  v_cit34_exists integer;
  v_cg_rel_exists integer;
  v_doc25_cit15 integer;
  v_doc26_cit15 integer;
  v_program_status text;
  v_program_verified_at timestamptz;
  v_join_exists boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'required_document_choice_group_citations'
      AND c.relkind = 'r'
  )
  INTO v_join_exists;

  IF v_join_exists IS NOT TRUE THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: required_document_choice_group_citations does not exist';
  END IF;

  SELECT count(*)
  INTO v_cg_count
  FROM public.required_document_choice_groups
  WHERE id = v_cg01_id;

  IF v_cg_count <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: CG01 row count=%', v_cg_count;
  END IF;

  SELECT admission_program_id, title, rule_text, condition
  INTO v_program_fk, v_title, v_rule_text, v_condition
  FROM public.required_document_choice_groups
  WHERE id = v_cg01_id;

  IF v_program_fk IS DISTINCT FROM v_program_id THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected admission_program_id=%',
      v_program_fk;
  END IF;

  IF v_title IS DISTINCT FROM '부모 사망 시 가족관계 대체 서류' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected title=%', v_title;
  END IF;

  IF v_rule_text IS DISTINCT FROM
    '부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준). 요강 p13 표. any_of / exactly_one enum 만들지 않음.'
  THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected rule_text=%', v_rule_text;
  END IF;

  IF v_condition IS DISTINCT FROM '부모 사망 해당자' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected condition=%', v_condition;
  END IF;

  SELECT count(*)
  INTO v_member_count
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = v_cg01_id
    AND admission_program_id = v_program_id;

  IF v_member_count <> 2 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: member count=%', v_member_count;
  END IF;

  SELECT count(*)
  INTO v_doc25_member
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = v_cg01_id
    AND required_document_id = v_doc25_id
    AND admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_doc26_member
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = v_cg01_id
    AND required_document_id = v_doc26_id
    AND admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_doc27_member
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = v_cg01_id
    AND required_document_id = v_doc27_id;

  IF v_doc25_member <> 1 OR v_doc26_member <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: DOC25/DOC26 membership doc25=% doc26=%',
      v_doc25_member, v_doc26_member;
  END IF;

  IF v_doc27_member <> 0 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: DOC27 must not be a CG01 member';
  END IF;

  SELECT title, source_url
  INTO v_src02_title, v_src02_url
  FROM public.source_documents
  WHERE id = v_src02_id;

  IF v_src02_title IS DISTINCT FROM
    '2027학년도 특별전형 모집요강 (서울캠퍼스) (2026.06.10 배포용)'
  THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected SRC02 title=%',
      v_src02_title;
  END IF;

  IF v_src02_url IS DISTINCT FROM
    'https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf'
  THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected SRC02 url=%',
      v_src02_url;
  END IF;

  SELECT count(*)
  INTO v_src02_in_program
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src02_id;

  IF v_src02_in_program <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: SRC02 is not in admission_program_sources';
  END IF;

  SELECT count(*)
  INTO v_s06_in_program
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_s06_id;

  IF v_s06_in_program <> 0 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: S06 is in admission_program_sources';
  END IF;

  SELECT count(*)
  INTO v_cit34_exists
  FROM public.source_citations
  WHERE id = v_cit34_id;

  IF v_cit34_exists <> 0 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: new citation UUID already exists';
  END IF;

  SELECT count(*)
  INTO v_cg_rel_exists
  FROM public.required_document_choice_group_citations
  WHERE choice_group_id = v_cg01_id;

  IF v_cg_rel_exists <> 0 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: CG01 already has % group citation relation(s)',
      v_cg_rel_exists;
  END IF;

  SELECT count(*)
  INTO v_doc25_cit15
  FROM public.required_document_citations
  WHERE required_document_id = v_doc25_id
    AND source_citation_id = v_cit15_id;

  SELECT count(*)
  INTO v_doc26_cit15
  FROM public.required_document_citations
  WHERE required_document_id = v_doc26_id
    AND source_citation_id = v_cit15_id;

  IF v_doc25_cit15 <> 1 OR v_doc26_cit15 <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: DOC25/DOC26 CIT15 relations missing doc25=% doc26=%',
      v_doc25_cit15, v_doc26_cit15;
  END IF;

  SELECT verification_status, verified_at
  INTO v_program_status, v_program_verified_at
  FROM public.admission_programs
  WHERE id = v_program_id;

  IF v_program_status IS DISTINCT FROM 'partially_verified'
     OR v_program_verified_at IS NOT NULL THEN
    RAISE EXCEPTION
      'KU27 CG01 correction preflight failed: unexpected program verification_status=% verified_at=%',
      v_program_status, v_program_verified_at;
  END IF;
END
$$;

-- =============================================================================
-- 1. CG01 user-safe text
-- =============================================================================

DO $$
BEGIN
  UPDATE public.required_document_choice_groups
  SET
    title = '부모 사망 시 제출 서류',
    rule_text = '부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준)',
    condition = '부모가 사망한 경우',
    verification_status = 'verified',
    verified_at = '2026-09-12T08:11:54Z'::timestamptz
  WHERE id = 'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
    AND title = '부모 사망 시 가족관계 대체 서류'
    AND rule_text = '부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준). 요강 p13 표. any_of / exactly_one enum 만들지 않음.'
    AND condition = '부모 사망 해당자';

  IF NOT FOUND THEN
    RAISE EXCEPTION
      'KU27 CG01 correction failed: UPDATE matched 0 rows after precondition guards';
  END IF;
END
$$;

-- =============================================================================
-- 2. KU27-CIT34 tighter locator (S01 p.13 death-case cell)
-- =============================================================================

INSERT INTO public.source_citations (
  id,
  source_document_id,
  file_page_number,
  printed_page_label,
  section,
  anchor_description,
  verified_at
) VALUES (
  '6cc44f83-0936-4f73-9e97-a5ff99ce87fd'::uuid,
  '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid,
  13,
  '13',
  '가족관계증명서 유의사항',
  '부모가 사망한 경우 · 기본증명서(상세) 또는 제적등본 1부',
  '2026-09-12T08:11:54Z'::timestamptz
);

-- =============================================================================
-- 3. CG01 → CIT34 direct relation (exactly one)
-- =============================================================================

INSERT INTO public.required_document_choice_group_citations (
  choice_group_id,
  source_citation_id
) VALUES (
  'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid,
  '6cc44f83-0936-4f73-9e97-a5ff99ce87fd'::uuid
);

-- =============================================================================
-- 4. Post-apply assertions
-- =============================================================================

DO $$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_cg01_id uuid := 'ae4b32a8-8ef9-409d-848d-e8f9ff84956f'::uuid;
  v_doc25_id uuid := '0be8eaa1-edc0-48e3-8723-eea8073fafe3'::uuid;
  v_doc26_id uuid := 'f6806da9-2911-4b3d-ad0d-d6b97dbe708c'::uuid;
  v_src02_id uuid := '316d1a61-6119-4d15-ac69-5395279ff99a'::uuid;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_cit15_id uuid := 'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid;
  v_cit34_id uuid := '6cc44f83-0936-4f73-9e97-a5ff99ce87fd'::uuid;
  v_historical_citation_ids uuid[] := ARRAY[
    'c3565efc-a24e-4fbc-857a-769228aebe9b'::uuid,
    'afd292cf-fa31-476c-8807-c95a75b73528'::uuid,
    'f11bf897-c662-4b96-b53a-b3fc2847e78f'::uuid,
    '41ea7aa5-847f-4243-97d7-99f2a2226c54'::uuid,
    '5080a730-4dc2-4af2-ae5a-e9a87ae89d2a'::uuid,
    '2cae549f-57ff-4e35-8ec8-a5a07628a3b7'::uuid,
    '79281172-a2c1-4e20-919e-d31c1ef1ada2'::uuid,
    '95381979-c07c-48ad-8f72-e3ec59ba7158'::uuid,
    '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid,
    '3c56af53-f964-44dd-80bf-cd1971520990'::uuid,
    '62c2e2d1-136b-44df-87d7-07b38d06df20'::uuid,
    '6e4d1560-617f-4af2-b0cc-b62fafceca06'::uuid,
    'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid,
    'dcd83bed-74ff-4d0e-a0fd-e0f8ddfb82f8'::uuid,
    'a841f22c-5e46-4933-b21a-44b9305a21f9'::uuid,
    'ff96d9da-2b22-4c32-b37e-888dd6057de0'::uuid,
    '3fba734e-2a25-4e3a-a419-fb81fa9eb297'::uuid,
    '176db75a-941c-4980-a004-3644ff564d8b'::uuid,
    'e9a4c088-5f9b-4fda-9efd-5bb3a48542f4'::uuid,
    'bb8b177f-e6b0-45c9-a9f8-6555e5687a09'::uuid,
    '2c1b7752-9057-4f0e-8268-2dca8060ce30'::uuid,
    'c48e2898-0398-424c-a259-471be9623e33'::uuid,
    '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid,
    '996f1ff0-bc7e-4418-b855-660fa65384bc'::uuid,
    '36544164-460a-4cb8-8a65-eb1c67f47ee2'::uuid,
    '6291c0e7-05b1-417d-b5ec-e0de8c7dd4d1'::uuid,
    'ebff4f8d-115a-4f44-939a-f1d3bc74315e'::uuid,
    'b2300055-7f04-4805-8938-00d2fb292df4'::uuid,
    '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid,
    '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid,
    'b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416'::uuid,
    '0a90841a-83a4-436d-a957-59373077a497'::uuid,
    '9716a890-15a4-46be-98c0-09842d4671f9'::uuid
  ];
  v_title text;
  v_rule_text text;
  v_condition text;
  v_status text;
  v_verified_at timestamptz;
  v_member_count integer;
  v_group_cites integer;
  v_cit34_source uuid;
  v_cit34_page integer;
  v_cit34_label text;
  v_cit34_section text;
  v_cit34_anchor text;
  v_cit34_verified timestamptz;
  v_historical_citations integer;
  v_citations integer;
  v_section_cites integer;
  v_document_cites integer;
  v_submission_cites integer;
  v_schedule_cites integer;
  v_citation_relations integer;
  v_s06_relations integer;
  v_doc25_cit15 integer;
  v_doc26_cit15 integer;
  v_doc25_condition text;
  v_doc26_condition text;
  v_program_status text;
  v_program_verified_at timestamptz;
  v_cit15_page integer;
  v_cit15_anchor text;
BEGIN
  SELECT title, rule_text, condition, verification_status, verified_at
  INTO v_title, v_rule_text, v_condition, v_status, v_verified_at
  FROM public.required_document_choice_groups
  WHERE id = v_cg01_id
    AND admission_program_id = v_program_id;

  IF v_title IS DISTINCT FROM '부모 사망 시 제출 서류' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: title=%', v_title;
  END IF;

  IF v_rule_text IS DISTINCT FROM
    '부모가 사망한 경우 기본증명서(상세) 또는 제적등본 1부 (사망한 부 또는 모 기준)'
  THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: rule_text=%', v_rule_text;
  END IF;

  IF v_condition IS DISTINCT FROM '부모가 사망한 경우' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: condition=%', v_condition;
  END IF;

  IF v_status IS DISTINCT FROM 'verified' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: verification_status=%', v_status;
  END IF;

  IF v_verified_at IS DISTINCT FROM '2026-09-12T08:11:54Z'::timestamptz THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: verified_at=%', v_verified_at;
  END IF;

  SELECT count(*)
  INTO v_member_count
  FROM public.required_document_choice_group_items
  WHERE choice_group_id = v_cg01_id
    AND admission_program_id = v_program_id;

  IF v_member_count <> 2 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: member count=%', v_member_count;
  END IF;

  SELECT count(*)
  INTO v_group_cites
  FROM public.required_document_choice_group_citations
  WHERE choice_group_id = v_cg01_id;

  IF v_group_cites <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: CG01 group citation relations=%',
      v_group_cites;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.required_document_choice_group_citations
    WHERE choice_group_id = v_cg01_id
      AND source_citation_id = v_cit34_id
  ) THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: CG01 is not linked to CIT34';
  END IF;

  SELECT source_document_id, file_page_number, printed_page_label,
         section, anchor_description, verified_at
  INTO v_cit34_source, v_cit34_page, v_cit34_label,
       v_cit34_section, v_cit34_anchor, v_cit34_verified
  FROM public.source_citations
  WHERE id = v_cit34_id;

  IF v_cit34_source IS DISTINCT FROM v_src02_id
     OR v_cit34_page IS DISTINCT FROM 13
     OR v_cit34_label IS DISTINCT FROM '13'
     OR v_cit34_section IS DISTINCT FROM '가족관계증명서 유의사항'
     OR v_cit34_anchor IS DISTINCT FROM
       '부모가 사망한 경우 · 기본증명서(상세) 또는 제적등본 1부'
     OR v_cit34_verified IS DISTINCT FROM '2026-09-12T08:11:54Z'::timestamptz
  THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: CIT34 locator mismatch';
  END IF;

  SELECT count(*)
  INTO v_historical_citations
  FROM public.source_citations
  WHERE id = ANY (v_historical_citation_ids);

  IF v_historical_citations <> 33 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: historical source_citations=%',
      v_historical_citations;
  END IF;

  SELECT count(*)
  INTO v_citations
  FROM public.source_citations
  WHERE id = ANY (v_historical_citation_ids || v_cit34_id);

  IF v_citations <> 34 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: planned source_citations=%',
      v_citations;
  END IF;

  SELECT count(*)
  INTO v_section_cites
  FROM public.admission_section_citations r
  JOIN public.admission_sections s ON s.id = r.admission_section_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_document_cites
  FROM public.required_document_citations r
  JOIN public.required_documents d ON d.id = r.required_document_id
  WHERE d.admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_submission_cites
  FROM public.document_submission_citations r
  JOIN public.document_submissions s ON s.id = r.document_submission_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_schedule_cites
  FROM public.admission_schedule_citations r
  JOIN public.admission_schedules s ON s.id = r.admission_schedule_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*)
  INTO v_group_cites
  FROM public.required_document_choice_group_citations r
  JOIN public.required_document_choice_groups g ON g.id = r.choice_group_id
  WHERE g.admission_program_id = v_program_id;

  v_citation_relations :=
    v_section_cites + v_document_cites + v_submission_cites
    + v_schedule_cites + v_group_cites;

  IF v_section_cites <> 24
     OR v_document_cites <> 56
     OR v_submission_cites <> 90
     OR v_schedule_cites <> 30
     OR v_group_cites <> 1
     OR v_citation_relations <> 201 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: section=% document=% submission=% schedule=% group=% total=%',
      v_section_cites, v_document_cites, v_submission_cites,
      v_schedule_cites, v_group_cites, v_citation_relations;
  END IF;

  SELECT
    (
      SELECT count(*)
      FROM public.admission_section_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
    + (
      SELECT count(*)
      FROM public.required_document_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
    + (
      SELECT count(*)
      FROM public.document_submission_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
    + (
      SELECT count(*)
      FROM public.admission_schedule_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
    + (
      SELECT count(*)
      FROM public.required_document_choice_group_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
  INTO v_s06_relations;

  IF v_s06_relations <> 0 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: S06 current citation relations=%',
      v_s06_relations;
  END IF;

  SELECT count(*)
  INTO v_doc25_cit15
  FROM public.required_document_citations
  WHERE required_document_id = v_doc25_id
    AND source_citation_id = v_cit15_id;

  SELECT count(*)
  INTO v_doc26_cit15
  FROM public.required_document_citations
  WHERE required_document_id = v_doc26_id
    AND source_citation_id = v_cit15_id;

  IF v_doc25_cit15 <> 1 OR v_doc26_cit15 <> 1 THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: CIT15 member relations lost';
  END IF;

  SELECT file_page_number, anchor_description
  INTO v_cit15_page, v_cit15_anchor
  FROM public.source_citations
  WHERE id = v_cit15_id;

  IF v_cit15_page IS DISTINCT FROM 13
     OR v_cit15_anchor IS DISTINCT FROM '재외국민 열, 사망/이혼 주석' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: CIT15 was mutated';
  END IF;

  SELECT condition
  INTO v_doc25_condition
  FROM public.required_documents
  WHERE id = v_doc25_id;

  SELECT condition
  INTO v_doc26_condition
  FROM public.required_documents
  WHERE id = v_doc26_id;

  IF v_doc25_condition IS DISTINCT FROM '부모 사망'
     OR v_doc26_condition IS DISTINCT FROM '부모 사망' THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: DOC25/DOC26 condition was mutated';
  END IF;

  SELECT verification_status, verified_at
  INTO v_program_status, v_program_verified_at
  FROM public.admission_programs
  WHERE id = v_program_id;

  IF v_program_status IS DISTINCT FROM 'partially_verified'
     OR v_program_verified_at IS NOT NULL THEN
    RAISE EXCEPTION
      'KU27 CG01 correction assertion failed: AdmissionProgram verification was mutated';
  END IF;
END
$$;
