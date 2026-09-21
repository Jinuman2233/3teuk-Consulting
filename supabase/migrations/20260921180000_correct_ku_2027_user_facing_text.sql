-- KU 2027 SET A user-facing text correction.
--
-- DATA ONLY. No schema / type / function / trigger / policy / index changes.
-- No citation table writes. No SourceDocument writes.
-- Requires 20260912123100_correct_ku_2027_choice_group_provenance.sql.
--
-- Purpose:
--   Replace internal loader/DB/source-locator memos in user-facing columns
--   with wording that current official sources directly support.
--   Do not add new facts. Do not expand interpretation. Do not merge sources.
--   Do not use S05 content.
--
-- Scope: 54 rows (11 required_documents + 43 document_submissions).
-- Excluded (SET B / S05 PDF revision blocked): DOC41, DOC42, SUB83.
-- Excluded source revision: SRC07 / CIT29 / CIT30.
--
-- Official source re-check (implementation, not planning):
--   S01 current June 배포용
--   https://oku.korea.ac.kr/attach/202606/1781850206372_0.pdf
--   SHA-256 eb7f5ff175dd1140e9b5e6fc64efb30d7426954db07743d05a92a1b2082389a2
--   re-checked 2026-09-21T17:17:34Z
--   S03 원서접수 안내 HTML
--   BoardView BBS_SEQ=1799
--   re-checked 2026-09-21T17:17:55Z
--
-- verified_at policy:
--   Do not use now() / CURRENT_TIMESTAMP.
--   Do not stamp one timestamp onto all 54 rows.
--   S01-only replacements (replacement wording supported by S01):
--     2026-09-21T17:17:34Z
--     DOC02, DOC04, DOC13, DOC14, DOC15, DOC20, DOC29, DOC35, DOC36, DOC37, DOC40
--     SUB41–80
--     SUB81 (new instructions are S01 1-나; CIT23 stays as existing
--     direct provenance, not as the wording source for this field)
--   S01+S03 replacement (new instructions use both S01 reporting codes
--   and S03 score-reporting mail facts; last supporting re-check is S03):
--     2026-09-21T17:17:55Z
--     SUB10
--   SUB82 remains needs_review / verified_at NULL.
--   verification_status is never changed.
--
-- Do not invent admission facts. Do not UPSERT. Do not ON CONFLICT DO NOTHING.
-- Do not DELETE. Do not edit 20260905160000_load_ku_2027_reentry.sql.
-- Logical IDs in comments (KU27-*) are documentation only, not DB fields.

-- =============================================================================
-- 0. Fail-fast guards
-- =============================================================================

DO $guard$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_university_id uuid := '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_src07_id uuid := '31c298f9-cde7-407b-be2d-692235e1a391'::uuid;
  v_cit09_id uuid := '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid;
  v_cit13_id uuid := 'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid;
  v_cit23_id uuid := '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid;
  v_cit29_id uuid := '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;
  v_cit30_id uuid := '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid;
  v_doc40_id uuid := 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid;
  v_doc41_id uuid := '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid;
  v_doc42_id uuid := 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid;
  v_sub10_id uuid := 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid;
  v_sub81_id uuid := 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid;
  v_sub82_id uuid := '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;
  v_sub83_id uuid := 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid;
  v_sub41_80 uuid[] := ARRAY[
    '40128241-eaf8-45ae-8eda-c8380851a654'::uuid,  -- SUB41
    'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid,  -- SUB42
    'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid,  -- SUB43
    '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid,  -- SUB44
    'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid,  -- SUB45
    '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid,  -- SUB46
    'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid,  -- SUB47
    '2376356e-8b23-4369-967e-96f1eeadce62'::uuid,  -- SUB48
    '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid,  -- SUB49
    'a845b3b3-857b-483a-9d94-27053887321f'::uuid,  -- SUB50
    'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid,  -- SUB51
    '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid,  -- SUB52
    'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid,  -- SUB53
    'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid,  -- SUB54
    '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid,  -- SUB55
    'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid,  -- SUB56
    '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid,  -- SUB57
    'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid,  -- SUB58
    'a9643775-179b-4d12-a570-ae0ee9792884'::uuid,  -- SUB59
    '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid,  -- SUB60
    '3702486f-32f8-4609-953c-d094f1176d18'::uuid,  -- SUB61
    '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid,  -- SUB62
    '9be7daf5-106f-43df-b942-8498d64538c4'::uuid,  -- SUB63
    'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid,  -- SUB64
    '63aa0858-3025-48e4-8d03-5edce9524585'::uuid,  -- SUB65
    '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid,  -- SUB66
    '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid,  -- SUB67
    '07e47072-a515-4fe5-8f38-0f67818df485'::uuid,  -- SUB68
    'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid,  -- SUB69
    '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid,  -- SUB70
    'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid,  -- SUB71
    'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid,  -- SUB72
    '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid,  -- SUB73
    '92c378bc-158a-4569-9753-2807aac83ed8'::uuid,  -- SUB74
    'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid,  -- SUB75
    'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid,  -- SUB76
    'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid,  -- SUB77
    '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid,  -- SUB78
    '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid,  -- SUB79
    '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid  -- SUB80
  ];
  v_university_name text;
  v_campus text;
  v_year integer;
  v_slug text;
  v_program_status text;
  v_documents integer;
  v_submissions integer;
  v_choice_groups integer;
  v_choice_items integer;
  v_doc40_cit09 integer;
  v_src07_url text;
  v_src07_checked timestamptz;
  v_src07_supersedes uuid;
  v_s06_in_program integer;
  v_sub41_80_old integer;
  v_sub82_status text;
  v_sub82_verified timestamptz;
  v_sub82_schedule uuid;
  v_sub82_cites integer;
  v_sub81_schedule uuid;
  v_sub81_status text;
  v_sub81_cites integer;
  v_cit29 integer;
  v_cit30 integer;
BEGIN
  SELECT u.name_ko, u.campus_name, p.academic_year, p.admission_slug, p.verification_status
  INTO v_university_name, v_campus, v_year, v_slug, v_program_status
  FROM public.admission_programs p
  JOIN public.universities u ON u.id = p.university_id
  WHERE p.id = v_program_id;

  IF v_university_name IS DISTINCT FROM '고려대학교'
     OR v_campus IS DISTINCT FROM '서울캠퍼스'
     OR v_year IS DISTINCT FROM 2027
     OR v_slug IS DISTINCT FROM 'overseas-korean-2pct'
     OR v_program_status IS DISTINCT FROM 'partially_verified' THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: unexpected program identity name=% campus=% year=% slug=% status=%',
      v_university_name, v_campus, v_year, v_slug, v_program_status;
  END IF;

  SELECT count(*) INTO v_documents
  FROM public.required_documents
  WHERE admission_program_id = v_program_id;

  SELECT count(*) INTO v_submissions
  FROM public.document_submissions
  WHERE admission_program_id = v_program_id;

  SELECT count(*) INTO v_choice_groups
  FROM public.required_document_choice_groups
  WHERE admission_program_id = v_program_id;

  SELECT count(*) INTO v_choice_items
  FROM public.required_document_choice_group_items
  WHERE admission_program_id = v_program_id;

  IF v_documents <> 42
     OR v_submissions <> 84
     OR v_choice_groups <> 1
     OR v_choice_items <> 2 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: unexpected dataset counts documents=% submissions=% choiceGroups=% items=%',
      v_documents, v_submissions, v_choice_groups, v_choice_items;
  END IF;

  -- DOC40 must cite CIT09. Citation rewrite is out of scope; STOP rather than guess.
  SELECT count(*) INTO v_doc40_cit09
  FROM public.required_document_citations
  WHERE required_document_id = v_doc40_id
    AND source_citation_id = v_cit09_id;

  IF v_doc40_cit09 <> 1 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight STOP: DOC40 existing citation is not CIT09 (count=%)',
      v_doc40_cit09;
  END IF;

  SELECT source_url, last_checked_at, supersedes_source_document_id
  INTO v_src07_url, v_src07_checked, v_src07_supersedes
  FROM public.source_documents
  WHERE id = v_src07_id;

  IF v_src07_url IS DISTINCT FROM
       'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2'
     OR v_src07_checked IS DISTINCT FROM '2026-09-05T17:02:08Z'::timestamptz
     OR v_src07_supersedes IS NOT NULL THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: SRC07 was already mutated url=% checked=% supersedes=%',
      v_src07_url, v_src07_checked, v_src07_supersedes;
  END IF;

  SELECT count(*) INTO v_s06_in_program
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_s06_id;

  IF v_s06_in_program <> 0 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: S06 is in admission_program_sources';
  END IF;

  SELECT count(*) INTO v_cit29 FROM public.source_citations WHERE id = v_cit29_id;
  SELECT count(*) INTO v_cit30 FROM public.source_citations WHERE id = v_cit30_id;
  IF v_cit29 <> 1 OR v_cit30 <> 1 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: CIT29/CIT30 missing cit29=% cit30=%',
      v_cit29, v_cit30;
  END IF;

  SELECT count(*) INTO v_sub41_80_old
  FROM public.document_submissions
  WHERE admission_program_id = v_program_id
    AND id = ANY (v_sub41_80)
    AND instructions IS NOT DISTINCT FROM
      '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4';

  IF v_sub41_80_old <> 40 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: SUB41-80 old instructions match count=% (expected 40)',
      v_sub41_80_old;
  END IF;

  SELECT verification_status, verified_at, admission_schedule_id
  INTO v_sub82_status, v_sub82_verified, v_sub82_schedule
  FROM public.document_submissions
  WHERE id = v_sub82_id;

  SELECT count(*) INTO v_sub82_cites
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub82_id;

  IF v_sub82_status IS DISTINCT FROM 'needs_review'
     OR v_sub82_verified IS NOT NULL
     OR v_sub82_schedule IS NOT NULL
     OR v_sub82_cites <> 4 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: SUB82 invariant status=% verified_at=% schedule=% cites=%',
      v_sub82_status, v_sub82_verified, v_sub82_schedule, v_sub82_cites;
  END IF;

  SELECT admission_schedule_id, verification_status
  INTO v_sub81_schedule, v_sub81_status
  FROM public.document_submissions
  WHERE id = v_sub81_id;

  SELECT count(*) INTO v_sub81_cites
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub81_id
    AND source_citation_id IN (v_cit13_id, v_cit23_id);

  IF v_sub81_schedule IS NOT NULL
     OR v_sub81_status IS DISTINCT FROM 'verified'
     OR v_sub81_cites <> 2 THEN
    RAISE EXCEPTION
      'KU27 SET A preflight failed: SUB81 invariant schedule=% status=% cit13+cit23=%',
      v_sub81_schedule, v_sub81_status, v_sub81_cites;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.document_submission_citations
    WHERE document_submission_id = v_sub10_id
      AND source_citation_id = v_cit23_id
  ) THEN
    RAISE EXCEPTION 'KU27 SET A preflight failed: SUB10 missing CIT23';
  END IF;
END
$guard$;

-- =============================================================================
-- 1. RequiredDocument SET A (11 rows)
-- Direct citations are S01 only. verified_at = S01 re-check.
-- =============================================================================

DO $docs$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_s01 timestamptz := '2026-09-21T17:17:34Z'::timestamptz;
  v_count integer;
BEGIN
  -- KU27-DOC02 condition. Direct: CIT14 (S01 p12).
  UPDATE public.required_documents
  SET
    condition = '국외 초등학교 성적·재학증명서는 둘 중 하나만 제출해도 되나, 증명서상에 이수학년, 학기 및 재학기간이 명시되어 있어야 함',
    verified_at = v_s01
  WHERE id = 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      '국외 초등은 성적·재학 중 하나만 제출해도 되나 이수학년·학기·재학기간 명시. 한 표 행 → ChoiceGroup 아님'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC02 condition update count=%', v_count;
  END IF;

  -- KU27-DOC04 condition -> NULL. name unchanged. Direct: CIT14 (S01 p12).
  UPDATE public.required_documents
  SET
    condition = NULL,
    verified_at = v_s01
  WHERE id = 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid
    AND admission_program_id = v_program_id
    AND name = '고등학교 성적‧재학‧졸업(예정)증명서'
    AND condition IS NOT DISTINCT FROM
      '최종 원본에 졸업증명서 포함(p6). 예정자 추가 졸업증명서 기한은 SUB82'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC04 condition update count=%', v_count;
  END IF;

  -- KU27-DOC13 description. Direct: CIT15 (S01 p13).
  UPDATE public.required_documents
  SET
    description = '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출',
    verified_at = v_s01
  WHERE id = 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid
    AND admission_program_id = v_program_id
    AND description IS NOT DISTINCT FROM
      '분실 시 여권 발급기록증명서 (대체 조건. 열린 「등」이 아니나 조건부여체이므로 별도 자유 ChoiceGroup은 만들지 않음)'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC13 description update count=%', v_count;
  END IF;

  -- KU27-DOC14 description. Same official 여권 분실 대체 sentence as DOC13; subject is 부.
  UPDATE public.required_documents
  SET
    description = '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출',
    verified_at = v_s01
  WHERE id = '5e960174-2563-4216-9c82-c159c909e63f'::uuid
    AND admission_program_id = v_program_id
    AND description IS NOT DISTINCT FROM
      '분실 시 여권 발급기록증명서 (대체 조건. DOC13과 동일)'
    AND document_subject_text = '부'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC14 description update count=%', v_count;
  END IF;

  -- KU27-DOC15 description. Same official 여권 분실 대체 sentence as DOC13; subject is 모.
  UPDATE public.required_documents
  SET
    description = '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출',
    verified_at = v_s01
  WHERE id = 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid
    AND admission_program_id = v_program_id
    AND description IS NOT DISTINCT FROM
      '분실 시 여권 발급기록증명서 (대체 조건. DOC13과 동일)'
    AND document_subject_text = '모'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC15 description update count=%', v_count;
  END IF;

  -- KU27-DOC20 condition. Direct: CIT13 (S01 p11).
  UPDATE public.required_documents
  SET
    condition = '주민등록번호 또는 성명이 다른 지원자',
    verified_at = v_s01
  WHERE id = '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      'p11: 주민등록번호 또는 성명이 다른 지원자. DOC19와 함께'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC20 condition update count=%', v_count;
  END IF;

  -- KU27-DOC29 description. Direct: CIT15 (S01 p13). condition unchanged.
  UPDATE public.required_documents
  SET
    description = '제출이 불가하거나, 입국일 정보에 특이사항이 있는 경우, 특이사항 증빙서류 제출 필수 (해당국 체류 기간을 확인할 수 있는 비자 사본 등의 대체 문서)',
    verified_at = v_s01
  WHERE id = 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid
    AND admission_program_id = v_program_id
    AND description IS NOT DISTINCT FROM
      '불가·특이 시 비자 사본 등 대체. 「등」열린 대체 → ChoiceGroup 아님'
    AND condition IS NOT DISTINCT FROM '2026.07.01 이후'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC29 description update count=%', v_count;
  END IF;

  -- KU27-DOC35 condition. Direct: CIT16 (S01 p14).
  UPDATE public.required_documents
  SET
    condition = '국외파견 재직자 중 상사 주재원에 한함',
    verified_at = v_s01
  WHERE id = 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      '국외파견 중 상사 주재원. 한 표 셀의 또는 → 공식명을 그대로 한 document'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC35 condition update count=%', v_count;
  END IF;

  -- KU27-DOC36 condition. Direct: CIT16 (S01 p14).
  UPDATE public.required_documents
  SET
    condition = '현지법인 취업자',
    verified_at = v_s01
  WHERE id = '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      '현지법인 취업자. 표 셀 또는를 공식명으로 보존'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC36 condition update count=%', v_count;
  END IF;

  -- KU27-DOC37 description. Direct: CIT16 (S01 p14). condition unchanged.
  UPDATE public.required_documents
  SET
    description = '법인세 납부 이력이 국가 정책상 또는 영업 기밀상의 이유로 발급되지 않은 경우 개인 소득세 납부 증명으로 대체하여 제출할 수 있음',
    verified_at = v_s01
  WHERE id = 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid
    AND admission_program_id = v_program_id
    AND description IS NOT DISTINCT FROM
      '미발급 시 개인 소득세 납부 증명 대체 (조건부여체)'
    AND condition IS NOT DISTINCT FROM '현지법인'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC37 description update count=%', v_count;
  END IF;

  -- KU27-DOC40 condition. Direct: CIT09 (S01 p7). Preflight confirmed CIT09.
  UPDATE public.required_documents
  SET
    condition = '국내 고교 재학사실이 있는 자',
    verified_at = v_s01
  WHERE id = 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      'p7: 국내 고교 재학사실이 있는 자. 학력서류로 이미 제출한 경우와 중복될 수 있으나 요강이 학교폭력 확인용으로 별도 요구'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: DOC40 condition update count=%', v_count;
  END IF;
END
$docs$;

-- =============================================================================
-- 2. DocumentSubmission SET A (43 rows)
-- =============================================================================

-- KU27-SUB10 instructions.
-- Direct citations: CIT14 (S01 p12), CIT17 (S01 p15), CIT23 (S03).
-- New instructions combine S01 reporting codes and S03 score-reporting mail.
-- verified_at is the S03 re-check of that complete dual-source row.
DO $sub10$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.document_submissions
  SET
    instructions = '원서접수 시 진위여부 수단을 제공하거나 2026.07.09까지 본교로 스코어리포팅이 도착해야 함. 기관 번호: ETS (8228), College Board (5443), IBO (002366), ACT(2935)',
    verified_at = '2026-09-21T17:17:55Z'::timestamptz
  WHERE id = 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
    AND instructions IS NOT DISTINCT FROM
      '진위확인 수단 또는 2026.07.09까지 스코어리포팅 도착. 기관번호 ETS 8228 등. 별도 document 아님.'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: SUB10 instructions update count=%', v_count;
  END IF;
END
$sub10$;

-- KU27-SUB41–80 instructions. Exactly 40 rows. Common old value.
-- Direct citation: CIT07 (S01 p6). Replacement supported by S01 p4/p6 only.
-- Do not use S05. Do not add CIT30.
DO $sub4180$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_count integer;
  v_sub41_80 uuid[] := ARRAY[
    '40128241-eaf8-45ae-8eda-c8380851a654'::uuid,  -- SUB41
    'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid,  -- SUB42
    'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid,  -- SUB43
    '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid,  -- SUB44
    'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid,  -- SUB45
    '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid,  -- SUB46
    'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid,  -- SUB47
    '2376356e-8b23-4369-967e-96f1eeadce62'::uuid,  -- SUB48
    '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid,  -- SUB49
    'a845b3b3-857b-483a-9d94-27053887321f'::uuid,  -- SUB50
    'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid,  -- SUB51
    '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid,  -- SUB52
    'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid,  -- SUB53
    'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid,  -- SUB54
    '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid,  -- SUB55
    'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid,  -- SUB56
    '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid,  -- SUB57
    'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid,  -- SUB58
    'a9643775-179b-4d12-a570-ae0ee9792884'::uuid,  -- SUB59
    '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid,  -- SUB60
    '3702486f-32f8-4609-953c-d094f1176d18'::uuid,  -- SUB61
    '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid,  -- SUB62
    '9be7daf5-106f-43df-b942-8498d64538c4'::uuid,  -- SUB63
    'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid,  -- SUB64
    '63aa0858-3025-48e4-8d03-5edce9524585'::uuid,  -- SUB65
    '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid,  -- SUB66
    '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid,  -- SUB67
    '07e47072-a515-4fe5-8f38-0f67818df485'::uuid,  -- SUB68
    'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid,  -- SUB69
    '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid,  -- SUB70
    'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid,  -- SUB71
    'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid,  -- SUB72
    '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid,  -- SUB73
    '92c378bc-158a-4569-9753-2807aac83ed8'::uuid,  -- SUB74
    'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid,  -- SUB75
    'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid,  -- SUB76
    'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid,  -- SUB77
    '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid,  -- SUB78
    '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid,  -- SUB79
    '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid  -- SUB80
  ];
BEGIN
  UPDATE public.document_submissions
  SET
    instructions = '배송 현황을 확인할 수 있는 (등기우편, DHL 등) 우편 제출만 가능. 국외고 서류 및 재직 관련 증빙서류는 아포스티유 또는 영사확인 필수(대한민국 교육부 인가 재외 한국학교는 학교(장) 직인 인정)',
    verified_at = '2026-09-21T17:17:34Z'::timestamptz
  WHERE admission_program_id = v_program_id
    AND id = ANY (v_sub41_80)
    AND instructions IS NOT DISTINCT FROM
      '등기/DHL 등 배송확인, 아포스티유 대상은 p6/S05 p4'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 40 THEN
    RAISE EXCEPTION
      'KU27 SET A failed: SUB41-80 instructions update count=% (expected 40)',
      v_count;
  END IF;
END
$sub4180$;

-- KU27-SUB81 instructions. New wording is S01 1-나 (CIT13).
-- CIT23 remains as existing direct provenance and is not rewritten.
-- verified_at uses the S01 wording-source re-check, not the later S03 time.
-- admission_schedule_id remains NULL. verification_status remains verified.
DO $sub81$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.document_submissions
  SET
    instructions = '학생에게 성적·재학증명서를 제공하지 않는 고교의 경우, 해당 고교에서 본교로 우편 송부(2026.07.09. 까지 도착 서류만 인정)',
    verified_at = '2026-09-21T17:17:34Z'::timestamptz
  WHERE id = 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
    AND instructions IS NOT DISTINCT FROM
      '2026.07.09 도착. SCH02 datetime 17:00가 우편 도착에 적용된다고 단정하지 않음. admission_schedule_id NULL.'
    AND admission_schedule_id IS NULL
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: SUB81 instructions update count=%', v_count;
  END IF;
END
$sub81$;

-- KU27-SUB82 instructions -> NULL.
-- This does not resolve the source conflict.
-- needs_review / verified_at NULL / admission_schedule_id NULL / 4 citations remain.
DO $sub82$
DECLARE
  v_count integer;
BEGIN
  UPDATE public.document_submissions
  SET
    instructions = NULL
  WHERE id = '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid
    AND admission_program_id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid
    AND instructions IS NOT DISTINCT FROM
      '졸업예정자 졸업증명서 기한 official-source conflict. S01: 최종 원본 마감 2027.02.10 및 최종 서류 = 업로드한 모든 서류 + 졸업증명서. S05 HTML: 원본 2027.2.10 그리고 졸업예정자 졸업증명서 2027년 3월 입학 전. S05 PDF p4: 표 기한 ~2027.2.10, 예정자는 졸업증명서 추가 제출. 오타 단정 금지. 단일 확정 기한 없음. SCH11 UUID를 연결하지 않음. admission_schedule_id NULL.'
    AND verification_status = 'needs_review'
    AND verified_at IS NULL
    AND admission_schedule_id IS NULL;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A failed: SUB82 instructions update count=%', v_count;
  END IF;
END
$sub82$;

-- =============================================================================
-- 3. Post-apply assertions
-- =============================================================================

DO $post$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_s01 timestamptz := '2026-09-21T17:17:34Z'::timestamptz;
  v_s03 timestamptz := '2026-09-21T17:17:55Z'::timestamptz;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_src07_id uuid := '31c298f9-cde7-407b-be2d-692235e1a391'::uuid;
  v_cit09_id uuid := '5c07dafe-c069-4b9b-bfc7-a832a2b1d151'::uuid;
  v_cit13_id uuid := 'c01db4a8-f8c2-4561-a778-eee04bd35490'::uuid;
  v_cit23_id uuid := '556d605e-b68e-4eba-9ef7-8a34ecab2e0a'::uuid;
  v_cit29_id uuid := '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;
  v_cit30_id uuid := '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid;
  v_doc02_id uuid := 'd7e200d7-e478-4e87-96c4-713a2df35712'::uuid;
  v_doc04_id uuid := 'd1acd111-a3ba-4c11-ad62-7fb380b5551a'::uuid;
  v_doc13_id uuid := 'ee113820-bdd8-43d6-b15b-2b0a913a97a7'::uuid;
  v_doc14_id uuid := '5e960174-2563-4216-9c82-c159c909e63f'::uuid;
  v_doc15_id uuid := 'af6e4bb3-ff57-454a-9af0-12d85de3ba34'::uuid;
  v_doc20_id uuid := '81c177e8-6fd8-4630-aead-6e239bd2aced'::uuid;
  v_doc29_id uuid := 'a54f7a3b-618d-47eb-87e0-a8d8f098925e'::uuid;
  v_doc35_id uuid := 'a1a42d72-4d42-4dee-9601-d3aba2014f23'::uuid;
  v_doc36_id uuid := '93433c33-5ade-4f70-aace-d433fb418d2a'::uuid;
  v_doc37_id uuid := 'b5d34146-93ef-42a8-8038-bbe4968ede0c'::uuid;
  v_doc40_id uuid := 'eb04a17d-2422-4a9f-8dc9-bf94ca7ee4db'::uuid;
  v_doc41_id uuid := '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid;
  v_doc42_id uuid := 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid;
  v_sub10_id uuid := 'dd2ad32c-c42b-4b75-973d-8c9d70f42cc4'::uuid;
  v_sub81_id uuid := 'bbfadff6-d352-4a2d-8d23-86feadd1248f'::uuid;
  v_sub82_id uuid := '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;
  v_sub83_id uuid := 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid;
  v_sub41_80 uuid[] := ARRAY[
    '40128241-eaf8-45ae-8eda-c8380851a654'::uuid,  -- SUB41
    'ce748bb2-6d5a-4d27-984a-95dab19c855a'::uuid,  -- SUB42
    'e27c475e-4bbc-4105-992e-41d2ab92fb0a'::uuid,  -- SUB43
    '651f7934-a3ed-43ee-b900-a125caf7e009'::uuid,  -- SUB44
    'd3049434-0607-4a04-8e74-eb4afa534a5c'::uuid,  -- SUB45
    '6f13b5c9-6f90-4c36-b4c9-870ed12e6c52'::uuid,  -- SUB46
    'd3b9c691-fdac-4a1d-a558-f923c2f1cf65'::uuid,  -- SUB47
    '2376356e-8b23-4369-967e-96f1eeadce62'::uuid,  -- SUB48
    '78d6c667-baf4-4ae3-bb8a-2ad07340fe0c'::uuid,  -- SUB49
    'a845b3b3-857b-483a-9d94-27053887321f'::uuid,  -- SUB50
    'a2e4f2a1-cc6f-40eb-944a-8a3a2ca1e11b'::uuid,  -- SUB51
    '4080a7c5-91ad-4bae-a094-e46828d4713d'::uuid,  -- SUB52
    'a35909cc-16a9-484e-b4e2-10faa9b68852'::uuid,  -- SUB53
    'f5725759-f6f0-4dc2-a713-6d7268052fd8'::uuid,  -- SUB54
    '2e2531c9-dab9-4dda-9571-8d6933a36497'::uuid,  -- SUB55
    'e48ea0f9-64f9-43d1-8310-f971c4e4bbca'::uuid,  -- SUB56
    '3b01c0ca-8e6e-405f-a60b-9465be18f61f'::uuid,  -- SUB57
    'fcc974f3-c1b0-4ec4-a572-471910925d46'::uuid,  -- SUB58
    'a9643775-179b-4d12-a570-ae0ee9792884'::uuid,  -- SUB59
    '3630b972-542f-4190-afd7-c25ef3dbc273'::uuid,  -- SUB60
    '3702486f-32f8-4609-953c-d094f1176d18'::uuid,  -- SUB61
    '7b96b037-28b3-4132-9f63-3a5ffca9a3ab'::uuid,  -- SUB62
    '9be7daf5-106f-43df-b942-8498d64538c4'::uuid,  -- SUB63
    'e4b6d81f-6321-4e36-aae5-4759d9a62346'::uuid,  -- SUB64
    '63aa0858-3025-48e4-8d03-5edce9524585'::uuid,  -- SUB65
    '1a2f5b56-aa77-43eb-b208-996df273d458'::uuid,  -- SUB66
    '477c237c-c91c-4e2d-8767-edd4a024a28e'::uuid,  -- SUB67
    '07e47072-a515-4fe5-8f38-0f67818df485'::uuid,  -- SUB68
    'b94501c1-c7a9-4b5f-9ee5-cb0fec210daf'::uuid,  -- SUB69
    '2ca94e2c-7c6a-4c54-adcc-f030aab25d02'::uuid,  -- SUB70
    'd3f87429-515f-4dc8-bce4-ec61b578bf9a'::uuid,  -- SUB71
    'e60a7144-cb97-40af-8d3e-0c9222cd2cca'::uuid,  -- SUB72
    '2c697c73-236d-4cae-830a-c8b914a62b63'::uuid,  -- SUB73
    '92c378bc-158a-4569-9753-2807aac83ed8'::uuid,  -- SUB74
    'f75aad3c-bf5f-4e0d-b7ac-880f444baf7b'::uuid,  -- SUB75
    'b80329f7-c914-48f6-94dd-8f5f8f269269'::uuid,  -- SUB76
    'd786d73d-cdc4-43ce-8eeb-8b9b7b34692f'::uuid,  -- SUB77
    '5c46fa0c-c459-4586-b496-bab6cf2184fa'::uuid,  -- SUB78
    '10b3c093-75e6-4717-a140-648ddf75d8e8'::uuid,  -- SUB79
    '1ef63e0c-1cec-436a-90d0-62dc98c81344'::uuid  -- SUB80
  ];
  v_set_a_docs uuid[] := ARRAY[
    v_doc02_id, v_doc04_id, v_doc13_id, v_doc14_id, v_doc15_id,
    v_doc20_id, v_doc29_id, v_doc35_id, v_doc36_id, v_doc37_id, v_doc40_id
  ];
  v_set_a_subs uuid[] := ARRAY[v_sub10_id] || v_sub41_80 || ARRAY[v_sub81_id, v_sub82_id];
  v_marker text :=
    'ChoiceGroup 아님|DOC13과 동일|DOC19와 함께|S05 p4|별도 document 아님|SCH02 datetime|admission_schedule_id|조건부여체|한 표 셀|공식명을 그대로|공식명으로 보존|열린 「등」|학교폭력 확인용|official-source conflict';
  v_blocker_marker text :=
    'ChoiceGroup|조건부여체|DOC13과 동일|DOC19와 함께|S05 p4|S05 PDF|별도 document 아님|admission_schedule_id|SCH02 datetime|한 표 셀|공식명을 그대로|공식명으로 보존|열린 「등」|학교폭력 확인용|묶지 않음|official-source conflict';
  v_txt text;
  v_status text;
  v_verified timestamptz;
  v_schedule uuid;
  v_method text;
  v_format text;
  v_name text;
  v_count integer;
  v_universities integer;
  v_programs integer;
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
  v_group_cites integer;
  v_citation_relations integer;
  v_program_sources integer;
  v_s06_in_program integer;
  v_s06_relations integer;
  v_src07_url text;
  v_src07_checked timestamptz;
  v_src07_supersedes uuid;
  v_cit29_page integer;
  v_cit30_page integer;
  v_doc40_cit09 integer;
  v_sub10_cites integer;
  v_sub81_cites integer;
  v_sub82_cites integer;
  v_sub82_cit30 integer;
  v_set_b_touch integer;
BEGIN
  IF array_length(v_set_a_docs, 1) <> 11
     OR array_length(v_set_a_subs, 1) <> 43 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: target array sizes docs=% subs=%',
      array_length(v_set_a_docs, 1), array_length(v_set_a_subs, 1);
  END IF;

  -- Document new values
  SELECT condition, verification_status, verified_at INTO v_txt, v_status, v_verified
  FROM public.required_documents WHERE id = v_doc02_id;
  IF v_txt IS DISTINCT FROM '국외 초등학교 성적·재학증명서는 둘 중 하나만 제출해도 되나, 증명서상에 이수학년, 학기 및 재학기간이 명시되어 있어야 함'
     OR v_status IS DISTINCT FROM 'verified'
     OR v_verified IS DISTINCT FROM v_s01 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC02 after value';
  END IF;

  SELECT name, condition, verification_status, verified_at
  INTO v_name, v_txt, v_status, v_verified
  FROM public.required_documents WHERE id = v_doc04_id;
  IF v_name IS DISTINCT FROM '고등학교 성적‧재학‧졸업(예정)증명서'
     OR v_txt IS NOT NULL
     OR v_status IS DISTINCT FROM 'verified'
     OR v_verified IS DISTINCT FROM v_s01 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC04 after value name=% condition=%', v_name, v_txt;
  END IF;

  SELECT description, verification_status, verified_at INTO v_txt, v_status, v_verified
  FROM public.required_documents WHERE id = v_doc13_id;
  IF v_txt IS DISTINCT FROM '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출'
     OR v_verified IS DISTINCT FROM v_s01 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC13 after value';
  END IF;

  SELECT description INTO v_txt FROM public.required_documents WHERE id = v_doc14_id;
  IF v_txt IS DISTINCT FROM '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC14 after value';
  END IF;

  SELECT description INTO v_txt FROM public.required_documents WHERE id = v_doc15_id;
  IF v_txt IS DISTINCT FROM '여권 분실 등의 이유로 여권사본 제출이 불가능한 경우, 여권 발급기록증명서를 제출' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC15 after value';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc20_id;
  IF v_txt IS DISTINCT FROM '주민등록번호 또는 성명이 다른 지원자' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC20 after value';
  END IF;

  SELECT description, condition INTO v_txt, v_name
  FROM public.required_documents WHERE id = v_doc29_id;
  IF v_txt IS DISTINCT FROM '제출이 불가하거나, 입국일 정보에 특이사항이 있는 경우, 특이사항 증빙서류 제출 필수 (해당국 체류 기간을 확인할 수 있는 비자 사본 등의 대체 문서)'
     OR v_name IS DISTINCT FROM '2026.07.01 이후' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC29 after value';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc35_id;
  IF v_txt IS DISTINCT FROM '국외파견 재직자 중 상사 주재원에 한함' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC35 after value';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc36_id;
  IF v_txt IS DISTINCT FROM '현지법인 취업자' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC36 after value';
  END IF;

  SELECT description, condition INTO v_txt, v_name
  FROM public.required_documents WHERE id = v_doc37_id;
  IF v_txt IS DISTINCT FROM '법인세 납부 이력이 국가 정책상 또는 영업 기밀상의 이유로 발급되지 않은 경우 개인 소득세 납부 증명으로 대체하여 제출할 수 있음'
     OR v_name IS DISTINCT FROM '현지법인' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC37 after value';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc40_id;
  IF v_txt IS DISTINCT FROM '국내 고교 재학사실이 있는 자' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC40 after value';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_documents
  WHERE id = ANY (v_set_a_docs)
    AND verified_at IS DISTINCT FROM v_s01;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SET A documents with unexpected verified_at=%', v_count;
  END IF;

  -- Submission new values
  SELECT instructions, verification_status, verified_at
  INTO v_txt, v_status, v_verified
  FROM public.document_submissions WHERE id = v_sub10_id;
  IF v_txt IS DISTINCT FROM '원서접수 시 진위여부 수단을 제공하거나 2026.07.09까지 본교로 스코어리포팅이 도착해야 함. 기관 번호: ETS (8228), College Board (5443), IBO (002366), ACT(2935)'
     OR v_status IS DISTINCT FROM 'verified'
     OR v_verified IS DISTINCT FROM v_s03 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB10 after value';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submissions
  WHERE id = ANY (v_sub41_80)
    AND instructions IS NOT DISTINCT FROM
      '배송 현황을 확인할 수 있는 (등기우편, DHL 등) 우편 제출만 가능. 국외고 서류 및 재직 관련 증빙서류는 아포스티유 또는 영사확인 필수(대한민국 교육부 인가 재외 한국학교는 학교(장) 직인 인정)'
    AND verified_at IS NOT DISTINCT FROM v_s01
    AND verification_status = 'verified';
  IF v_count <> 40 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB41-80 after count=%', v_count;
  END IF;

  SELECT submission_method, submission_format, admission_schedule_id,
         verification_status, instructions, verified_at
  INTO v_method, v_format, v_schedule, v_status, v_txt, v_verified
  FROM public.document_submissions WHERE id = v_sub81_id;
  IF v_method IS DISTINCT FROM '우편'
     OR v_format IS DISTINCT FROM '고교 직접 송부'
     OR v_schedule IS NOT NULL
     OR v_status IS DISTINCT FROM 'verified'
     OR v_txt IS DISTINCT FROM '학생에게 성적·재학증명서를 제공하지 않는 고교의 경우, 해당 고교에서 본교로 우편 송부(2026.07.09. 까지 도착 서류만 인정)'
     OR v_verified IS DISTINCT FROM v_s01 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: SUB81 after method=% format=% schedule=% status=%',
      v_method, v_format, v_schedule, v_status;
  END IF;

  SELECT count(*) INTO v_sub81_cites
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub81_id;
  IF v_sub81_cites <> 2 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB81 citations=%', v_sub81_cites;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.document_submission_citations
    WHERE document_submission_id = v_sub81_id AND source_citation_id = v_cit13_id
  ) OR NOT EXISTS (
    SELECT 1 FROM public.document_submission_citations
    WHERE document_submission_id = v_sub81_id AND source_citation_id = v_cit23_id
  ) THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB81 CIT13+CIT23 missing';
  END IF;

  SELECT verification_status, verified_at, admission_schedule_id, instructions
  INTO v_status, v_verified, v_schedule, v_txt
  FROM public.document_submissions WHERE id = v_sub82_id;
  SELECT count(*) INTO v_sub82_cites
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub82_id;
  SELECT count(*) INTO v_sub82_cit30
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub82_id
    AND source_citation_id = v_cit30_id;
  IF v_status IS DISTINCT FROM 'needs_review'
     OR v_verified IS NOT NULL
     OR v_schedule IS NOT NULL
     OR v_txt IS NOT NULL
     OR v_sub82_cites <> 4
     OR v_sub82_cit30 <> 1 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: SUB82 invariant status=% verified_at=% schedule=% instructions=% cites=% cit30=%',
      v_status, v_verified, v_schedule, v_txt, v_sub82_cites, v_sub82_cit30;
  END IF;

  -- SET B untouched
  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc41_id;
  IF v_txt IS DISTINCT FROM 'S05 PDF: 재외국민 졸업예정자 중 별도 요청한 인원. 조회기간 만 12세 생일~고등학교 졸업일. 일반 DOC21–23과 발급 기준이 다름' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC41 was mutated';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc42_id;
  IF v_txt IS DISTINCT FROM 'S05 PDF: 별도 요청 인원. DOC34와 기준일 다름' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC42 was mutated';
  END IF;

  SELECT instructions INTO v_txt FROM public.document_submissions WHERE id = v_sub83_id;
  IF v_txt IS DISTINCT FROM '해당자. 기한은 원본 패키지 표와 같은 칸. 졸업증명서 HTML 3월 문구와 묶지 않음' THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB83 was mutated';
  END IF;

  SELECT count(*) INTO v_set_b_touch
  FROM public.required_documents
  WHERE id IN (v_doc41_id, v_doc42_id)
    AND updated_at IS DISTINCT FROM created_at;
  -- SET B documents must not have been updated by this migration.
  -- created_at = updated_at from insert (trigger only fires on UPDATE).
  IF v_set_b_touch <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC41/DOC42 updated_at changed count=%', v_set_b_touch;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submissions
  WHERE id = v_sub83_id
    AND updated_at IS DISTINCT FROM created_at;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB83 updated_at changed';
  END IF;

  -- SET A corrected fields must not contain contamination markers.
  -- Literal DB NULL is allowed; the check is stored text.
  SELECT count(*) INTO v_count
  FROM public.required_documents
  WHERE id = ANY (v_set_a_docs)
    AND (
      coalesce(condition, '') ~ v_marker
      OR coalesce(description, '') ~ v_marker
      OR coalesce(condition, '') LIKE '%NULL%'
      OR coalesce(description, '') LIKE '%NULL%'
      OR coalesce(condition, '') LIKE '%datetime%'
      OR coalesce(description, '') LIKE '%datetime%'
      OR coalesce(condition, '') LIKE '%SUB82%'
      OR coalesce(description, '') LIKE '%SUB82%'
    );
  IF v_count <> 0 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: SET A document fields still contain contamination markers count=%',
      v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submissions
  WHERE id = ANY (v_set_a_subs)
    AND (
      coalesce(instructions, '') ~ v_marker
      OR coalesce(instructions, '') LIKE '%NULL%'
      OR coalesce(instructions, '') LIKE '%datetime%'
      OR coalesce(instructions, '') LIKE '%SUB82%'
    );
  IF v_count <> 0 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: SET A submission fields still contain contamination markers count=%',
      v_count;
  END IF;

  -- Remaining known BLOCKER contamination: exactly SET B 3 rows.
  SELECT count(*) INTO v_count
  FROM (
    SELECT id
    FROM public.required_documents
    WHERE admission_program_id = v_program_id
      AND (
        coalesce(condition, '') ~ v_blocker_marker
        OR coalesce(description, '') ~ v_blocker_marker
      )
    UNION ALL
    SELECT id
    FROM public.document_submissions
    WHERE admission_program_id = v_program_id
      AND coalesce(instructions, '') ~ v_blocker_marker
  ) remaining;
  IF v_count <> 3 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: remaining blocker-pattern rows=% (expected 3 SET B)',
      v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM (
    SELECT id FROM public.required_documents
    WHERE id IN (v_doc41_id, v_doc42_id)
      AND coalesce(condition, '') ~ v_blocker_marker
    UNION ALL
    SELECT id FROM public.document_submissions
    WHERE id = v_sub83_id
      AND coalesce(instructions, '') ~ v_blocker_marker
  ) set_b;
  IF v_count <> 3 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: SET B blocker-pattern identity count=%',
      v_count;
  END IF;

  -- Entity counts
  SELECT count(*) INTO v_universities FROM public.universities
  WHERE id = '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid;
  SELECT count(*) INTO v_programs FROM public.admission_programs
  WHERE id = v_program_id;
  SELECT count(*) INTO v_sections FROM public.admission_sections
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_schedules FROM public.admission_schedules
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_documents FROM public.required_documents
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_submissions FROM public.document_submissions
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_choice_groups FROM public.required_document_choice_groups
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_choice_items FROM public.required_document_choice_group_items
  WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_citations FROM public.source_citations;
  SELECT count(*) INTO v_program_sources FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id;

  SELECT count(*) INTO v_section_cites
  FROM public.admission_section_citations r
  JOIN public.admission_sections s ON s.id = r.admission_section_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*) INTO v_document_cites
  FROM public.required_document_citations r
  JOIN public.required_documents d ON d.id = r.required_document_id
  WHERE d.admission_program_id = v_program_id;

  SELECT count(*) INTO v_submission_cites
  FROM public.document_submission_citations r
  JOIN public.document_submissions s ON s.id = r.document_submission_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*) INTO v_schedule_cites
  FROM public.admission_schedule_citations r
  JOIN public.admission_schedules s ON s.id = r.admission_schedule_id
  WHERE s.admission_program_id = v_program_id;

  SELECT count(*) INTO v_group_cites
  FROM public.required_document_choice_group_citations r
  JOIN public.required_document_choice_groups g ON g.id = r.choice_group_id
  WHERE g.admission_program_id = v_program_id;

  v_citation_relations :=
    v_section_cites + v_document_cites + v_submission_cites
    + v_schedule_cites + v_group_cites;

  IF v_universities <> 1
     OR v_programs <> 1
     OR v_sections <> 17
     OR v_schedules <> 15
     OR v_documents <> 42
     OR v_submissions <> 84
     OR v_choice_groups <> 1
     OR v_choice_items <> 2
     OR v_citations <> 34
     OR v_section_cites <> 24
     OR v_document_cites <> 56
     OR v_submission_cites <> 90
     OR v_schedule_cites <> 30
     OR v_group_cites <> 1
     OR v_citation_relations <> 201
     OR v_program_sources <> 6 THEN
    RAISE EXCEPTION
      'KU27 SET A assertion failed: counts universities=% programs=% sections=% schedules=% documents=% submissions=% choiceGroups=% items=% citations=% section=% document=% submission=% schedule=% group=% relations=% programSources=%',
      v_universities, v_programs, v_sections, v_schedules, v_documents,
      v_submissions, v_choice_groups, v_choice_items, v_citations,
      v_section_cites, v_document_cites, v_submission_cites, v_schedule_cites,
      v_group_cites, v_citation_relations, v_program_sources;
  END IF;

  SELECT count(*) INTO v_s06_in_program
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_s06_id;
  IF v_s06_in_program <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: S06 entered program_sources';
  END IF;

  SELECT
    (
      SELECT count(*) FROM public.admission_section_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    ) + (
      SELECT count(*) FROM public.required_document_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    ) + (
      SELECT count(*) FROM public.document_submission_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    ) + (
      SELECT count(*) FROM public.admission_schedule_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    ) + (
      SELECT count(*) FROM public.required_document_choice_group_citations r
      JOIN public.source_citations c ON c.id = r.source_citation_id
      WHERE c.source_document_id = v_s06_id
    )
  INTO v_s06_relations;
  IF v_s06_relations <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: S06 current citation relations=%', v_s06_relations;
  END IF;

  SELECT source_url, last_checked_at, supersedes_source_document_id
  INTO v_src07_url, v_src07_checked, v_src07_supersedes
  FROM public.source_documents WHERE id = v_src07_id;
  IF v_src07_url IS DISTINCT FROM
       'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2'
     OR v_src07_checked IS DISTINCT FROM '2026-09-05T17:02:08Z'::timestamptz
     OR v_src07_supersedes IS NOT NULL THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SRC07 mutated';
  END IF;

  SELECT file_page_number INTO v_cit29_page FROM public.source_citations WHERE id = v_cit29_id;
  SELECT file_page_number INTO v_cit30_page FROM public.source_citations WHERE id = v_cit30_id;
  IF v_cit29_page IS DISTINCT FROM 2 OR v_cit30_page IS DISTINCT FROM 4 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: CIT29/CIT30 mutated';
  END IF;

  SELECT count(*) INTO v_doc40_cit09
  FROM public.required_document_citations
  WHERE required_document_id = v_doc40_id AND source_citation_id = v_cit09_id;
  IF v_doc40_cit09 <> 1 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: DOC40 CIT09 relation lost';
  END IF;

  SELECT count(*) INTO v_sub10_cites
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub10_id;
  IF v_sub10_cites <> 3 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: SUB10 citations=%', v_sub10_cites;
  END IF;

  -- no now() leaked into SET A verified_at besides the two literals
  SELECT count(*) INTO v_count
  FROM public.required_documents
  WHERE id = ANY (v_set_a_docs)
    AND verified_at IS DISTINCT FROM v_s01;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: unexpected document verified_at';
  END IF;

  SELECT verification_status, verified_at INTO v_status, v_verified
  FROM public.admission_programs WHERE id = v_program_id;
  IF v_status IS DISTINCT FROM 'partially_verified' OR v_verified IS NOT NULL THEN
    RAISE EXCEPTION 'KU27 SET A assertion failed: AdmissionProgram verification mutated';
  END IF;
END
$post$;
