-- KU 2027 S05 PDF FILE_SEQ=3 SourceDocument revision + SET B user-facing text.
--
-- Data-only. Schema changes: 0.
--
-- Current official S05 PDF (rechecked 2026-09-21T17:33:12Z):
--   BBS_SEQ=1805 FILE_SEQ=3
--   7 pages
--   SHA-256 f0012033daafb8b8f4779574e0b70945d592a879d78de80083c0d2238aad55a8
--   MD5 523747d42e2a5bd3f18cd59696c9e931
--   PDF CreationDate 2026-09-18 16:46:49 +09:00
--
-- Old SRC07 (FILE_SEQ=2) is preserved historically. Do not overwrite.
-- Old CIT29 / CIT30 rows are preserved. Entity relations move to new citations.
-- SCH10 keeps new p2 (GMT+9) and adds new p3 (등록포기 date/time).
-- Current graph: unique citations 35, attachments 202.
--
-- Program: d35bda6d-9fed-48f1-8687-28c5d07be455
--   KU Seoul / 2027 / overseas-korean-2pct
--
-- published_at: NULL
--   Column is official publish date (nullable date).
--   FILE_SEQ=3 has no official attachment-revision publication date.
--   PDF CreationDate is not a publication date.
--   CMS post date 2026-09-03 is the notice date of the same post, not a
--   confirmed FILE_SEQ=3 revision publication date.
--   Same contract as historical S06: do not invent published_at.

-- =============================================================================
-- 0. Preconditions
-- =============================================================================

DO $pre$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_src07_id uuid := '31c298f9-cde7-407b-be2d-692235e1a391'::uuid;
  v_new_src_id uuid := 'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid;
  v_cit29_id uuid := '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;
  v_cit30_id uuid := '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid;
  v_new_p2_id uuid := 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid;
  v_new_p3_id uuid := '078f4aaf-21b9-451f-abb8-67df7bab7c76'::uuid;
  v_new_p4_id uuid := 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid;
  v_src06_id uuid := 'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_doc41_id uuid := '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid;
  v_doc42_id uuid := 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid;
  v_sub82_id uuid := '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;
  v_sub83_id uuid := 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid;
  v_sub84_id uuid := '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid;
  v_sch06_id uuid := '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid;
  v_sch10_id uuid := '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid;
  v_sch11_id uuid := '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid;
  v_sch12_id uuid := '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid;
  v_sch13_id uuid := '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid;
  v_schedules uuid[] := ARRAY[
    '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
    '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
    '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
    '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
    '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid
  ];
  v_count integer;
  v_url text;
  v_checked timestamptz;
  v_notes text;
  v_supersedes uuid;
  v_cit_source uuid;
  v_cit_page integer;
  v_role text;
  v_order integer;
  v_txt text;
  v_status text;
  v_verified timestamptz;
  v_schedule uuid;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.admission_programs
  WHERE id = v_program_id
    AND academic_year = 2027
    AND admission_slug = 'overseas-korean-2pct';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: program identity count=%', v_count;
  END IF;

  SELECT source_url, last_checked_at, notes, supersedes_source_document_id
  INTO v_url, v_checked, v_notes, v_supersedes
  FROM public.source_documents
  WHERE id = v_src07_id;
  IF v_url IS DISTINCT FROM
       'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2'
     OR v_checked IS DISTINCT FROM '2026-09-05T17:02:08Z'::timestamptz
     OR v_supersedes IS NOT NULL THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: SRC07 identity mutated before apply';
  END IF;

  SELECT count(*) INTO v_count FROM public.source_documents WHERE id = v_new_src_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: new SourceDocument already exists';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.source_documents
  WHERE source_url =
    'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=3';
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: FILE_SEQ=3 SourceDocument already exists';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.source_citations
  WHERE id IN (v_new_p2_id, v_new_p3_id, v_new_p4_id);
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: new citation UUIDs already exist';
  END IF;

  SELECT source_document_id, file_page_number
  INTO v_cit_source, v_cit_page
  FROM public.source_citations
  WHERE id = v_cit29_id;
  IF v_cit_source IS DISTINCT FROM v_src07_id OR v_cit_page IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT29 source=% page=%', v_cit_source, v_cit_page;
  END IF;

  SELECT source_document_id, file_page_number
  INTO v_cit_source, v_cit_page
  FROM public.source_citations
  WHERE id = v_cit30_id;
  IF v_cit_source IS DISTINCT FROM v_src07_id OR v_cit_page IS DISTINCT FROM 4 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 source=% page=%', v_cit_source, v_cit_page;
  END IF;

  SELECT count(*), min(source_role), min(display_order)
  INTO v_count, v_role, v_order
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src07_id;
  IF v_count <> 1 OR v_role IS DISTINCT FROM 'supporting_notice' OR v_order IS DISTINCT FROM 6 THEN
    RAISE EXCEPTION
      'KU27 S05 rev preflight failed: SRC07 ProgramSource count=% role=% order=%',
      v_count, v_role, v_order;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id;
  IF v_count <> 6 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: ProgramSources=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_cit29_id
    AND admission_schedule_id = ANY (v_schedules);
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT29 expected schedule relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_cit29_id;
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT29 extra schedule relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_document_citations
  WHERE source_citation_id = v_cit29_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT29 document relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE source_citation_id = v_cit29_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT29 submission relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_document_citations
  WHERE source_citation_id = v_cit30_id
    AND required_document_id IN (v_doc41_id, v_doc42_id);
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 document relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE source_citation_id = v_cit30_id
    AND document_submission_id IN (v_sub82_id, v_sub83_id, v_sub84_id);
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 submission relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_document_citations
  WHERE source_citation_id = v_cit30_id;
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 extra document relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE source_citation_id = v_cit30_id;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 extra submission relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_cit30_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: CIT30 schedule relations=%', v_count;
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc41_id;
  IF v_txt IS DISTINCT FROM
       'S05 PDF: 재외국민 졸업예정자 중 별도 요청한 인원. 조회기간 만 12세 생일~고등학교 졸업일. 일반 DOC21–23과 발급 기준이 다름'
  THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: DOC41 old condition mismatch';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc42_id;
  IF v_txt IS DISTINCT FROM 'S05 PDF: 별도 요청 인원. DOC34와 기준일 다름' THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: DOC42 old condition mismatch';
  END IF;

  SELECT instructions, admission_schedule_id, verification_status
  INTO v_txt, v_schedule, v_status
  FROM public.document_submissions
  WHERE id = v_sub83_id;
  IF v_txt IS DISTINCT FROM
       '해당자. 기한은 원본 패키지 표와 같은 칸. 졸업증명서 HTML 3월 문구와 묶지 않음'
     OR v_schedule IS DISTINCT FROM v_sch11_id
     OR v_status IS DISTINCT FROM 'verified'
  THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: SUB83 old state mismatch';
  END IF;

  SELECT instructions, verification_status, verified_at, admission_schedule_id
  INTO v_txt, v_status, v_verified, v_schedule
  FROM public.document_submissions
  WHERE id = v_sub82_id;
  IF v_txt IS NOT NULL
     OR v_status IS DISTINCT FROM 'needs_review'
     OR v_verified IS NOT NULL
     OR v_schedule IS NOT NULL THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: SUB82 invariant broken';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub82_id;
  IF v_count <> 4 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: SUB82 citations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_s06_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: S06 is a current ProgramSource';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src06_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev preflight failed: S05 HTML ProgramSource missing';
  END IF;

  -- silence unused-variable notices for ids used only as named constants
  PERFORM v_sch06_id, v_sch10_id, v_sch12_id, v_sch13_id, v_notes;
END
$pre$;

-- =============================================================================
-- 1. New SourceDocument
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
) VALUES (
  'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid,
  '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid,
  2027,
  'official_notice',
  '2027학년도 특별전형 최종합격자 안내사항(배포용) (PDF)',
  '고려대학교 서울캠퍼스 입학처',
  'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=3',
  NULL,
  '2026-09-21T17:33:12Z'::timestamptz,
  '(배포용)',
  '31c298f9-cde7-407b-be2d-692235e1a391'::uuid,
  'FILE_SEQ=3. 7 physical pages. PDF CreationDate 2026-09-18 16:46:49 +09:00. SHA-256 f0012033daafb8b8f4779574e0b70945d592a879d78de80083c0d2238aad55a8. MD5 523747d42e2a5bd3f18cd59696c9e931. Rechecked 2026-09-21T17:33:12Z as current official attachment of BBS_SEQ=1805. supersedes SRC07 FILE_SEQ=2. FILE_SEQ=2 re-fetch was empty/unavailable. published_at NULL: official attachment-revision publication date is not stated; CreationDate is not used as publication date. HTML SRC06 remains a separate SourceDocument.'
);

-- =============================================================================
-- 2. New p2 / p3 / p4 SourceCitations
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
  (
    'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid,
    'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid,
    2,
    '- 2 -',
    '신입생 관련 주요 학사 일정',
    '표: 입학허가통지서 출력 합격자발표일~2026.09.30 17:00, 문서등록 2026.12.21 10:00~12.23 14:00, 원본서류 2027.02.10까지, 등록금 2027.02.15~02.16 예정. 각주: 본 안내사항에 기재된 일자와 일시는 한국 시간(GMT+9)',
    '2026-09-21T17:33:12Z'::timestamptz
  ),
  (
    '078f4aaf-21b9-451f-abb8-67df7bab7c76'::uuid,
    'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid,
    3,
    '- 3 -',
    '입학허가통지서 출력 및 합격자 문서등록(온라인 문서등록) 안내',
    '3. 합격자 문서등록 취소. 문서등록 취소 기간 ~ 2026.12.29.(화) 10:00. 등록을 포기하려는 경우 문서등록 취소 절차',
    '2026-09-21T17:33:12Z'::timestamptz
  ),
  (
    'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid,
    'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid,
    4,
    '- 4 -',
    '최종합격자 원본서류 제출 안내',
    '원본 표 ~2027.2.10, 졸업예정자 졸업증명서 추가 제출, 재외국민(정원외2%)전형 졸업예정자 중 별도 요청 출입국사실증명서(지원자 만 12세 생일~고등학교 졸업일)·재직증명서(고등학교 졸업일 기준), 아포스티유/영사확인',
    '2026-09-21T17:33:12Z'::timestamptz
  );

-- =============================================================================
-- 3. New ProgramSource (current S05 PDF)
-- =============================================================================

INSERT INTO public.admission_program_sources (
  admission_program_id,
  source_document_id,
  source_role,
  display_order,
  notes
) VALUES (
  'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid,
  'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid,
  'supporting_notice',
  6,
  'S05 PDF FILE_SEQ=3 current (conflict provenance)'
);

-- =============================================================================
-- 4. New entity citation relations
-- =============================================================================

INSERT INTO public.admission_schedule_citations (
  admission_schedule_id,
  source_citation_id
) VALUES
  ('3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid, 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid),
  ('6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid),
  ('6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid, '078f4aaf-21b9-451f-abb8-67df7bab7c76'::uuid),
  ('8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid, 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid),
  ('84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid, 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid),
  ('41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid, 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid);

INSERT INTO public.required_document_citations (
  required_document_id,
  source_citation_id
) VALUES
  ('47110092-f5be-419c-baa5-39e6154b1ba8'::uuid, 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid),
  ('cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid, 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid);

INSERT INTO public.document_submission_citations (
  document_submission_id,
  source_citation_id
) VALUES
  ('46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid, 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid),
  ('fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid, 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid),
  ('815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid, 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid);

-- =============================================================================
-- 5. Remove old current relations (keep historical citation rows)
-- =============================================================================

DO $move$
DECLARE
  v_cit29_id uuid := '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;
  v_cit30_id uuid := '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid;
  v_src07_id uuid := '31c298f9-cde7-407b-be2d-692235e1a391'::uuid;
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_count integer;
BEGIN
  DELETE FROM public.admission_schedule_citations
  WHERE source_citation_id = v_cit29_id
    AND admission_schedule_id IN (
      '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid,
      '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid,
      '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid,
      '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid,
      '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid
    );
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: CIT29 schedule detach count=%', v_count;
  END IF;

  DELETE FROM public.required_document_citations
  WHERE source_citation_id = v_cit30_id
    AND required_document_id IN (
      '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid,
      'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid
    );
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: CIT30 document detach count=%', v_count;
  END IF;

  DELETE FROM public.document_submission_citations
  WHERE source_citation_id = v_cit30_id
    AND document_submission_id IN (
      '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid,
      'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid,
      '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid
    );
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: CIT30 submission detach count=%', v_count;
  END IF;

  DELETE FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src07_id
    AND source_role = 'supporting_notice'
    AND display_order = 6;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SRC07 ProgramSource detach count=%', v_count;
  END IF;
END
$move$;

-- =============================================================================
-- 6. SET B text + reverified timestamps
-- =============================================================================

DO $setb$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_recheck timestamptz := '2026-09-21T17:33:12Z'::timestamptz;
  v_count integer;
BEGIN
  UPDATE public.required_documents
  SET
    condition = '재외국민(정원외2%)전형 졸업예정자 중 별도 요청한 인원. 조회기간: 지원자 만 12세 생일 ~ 고등학교 졸업일',
    verified_at = v_recheck
  WHERE id = '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      'S05 PDF: 재외국민 졸업예정자 중 별도 요청한 인원. 조회기간 만 12세 생일~고등학교 졸업일. 일반 DOC21–23과 발급 기준이 다름'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: DOC41 update count=%', v_count;
  END IF;

  UPDATE public.required_documents
  SET
    condition = '재외국민(정원외2%)전형 졸업예정자 중 별도 요청한 인원. 고등학교 졸업일 기준',
    verified_at = v_recheck
  WHERE id = 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid
    AND admission_program_id = v_program_id
    AND condition IS NOT DISTINCT FROM
      'S05 PDF: 별도 요청 인원. DOC34와 기준일 다름'
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: DOC42 update count=%', v_count;
  END IF;

  UPDATE public.document_submissions
  SET
    instructions = '해당자',
    verified_at = v_recheck
  WHERE id = 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid
    AND admission_program_id = v_program_id
    AND instructions IS NOT DISTINCT FROM
      '해당자. 기한은 원본 패키지 표와 같은 칸. 졸업증명서 HTML 3월 문구와 묶지 않음'
    AND admission_schedule_id IS NOT DISTINCT FROM '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid
    AND verification_status = 'verified';
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SUB83 update count=%', v_count;
  END IF;

  -- SUB84 stored user-facing text is already 「해당자」. Current p4 still
  -- supports 해당자 / 우편 / 원본 / SCH11(~2027.2.10). verified_at updates
  -- because that stored fact was reverified against current p4, not merely
  -- because the citation UUID changed.
  UPDATE public.document_submissions
  SET verified_at = v_recheck
  WHERE id = '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid
    AND admission_program_id = v_program_id
    AND instructions IS NOT DISTINCT FROM '해당자'
    AND admission_schedule_id IS NOT DISTINCT FROM '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:49Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SUB84 verified_at update count=%', v_count;
  END IF;

  -- Schedules: each stored fact was reread against current FILE_SEQ=3.
  UPDATE public.admission_schedules
  SET verified_at = v_recheck
  WHERE id = '3e137100-0a35-48bb-bf52-4f2b5d88782e'::uuid
    AND admission_program_id = v_program_id
    AND event_name = '문서등록'
    AND start_at IS NOT DISTINCT FROM '2026-12-21 10:00:00+09'::timestamptz
    AND end_at IS NOT DISTINCT FROM '2026-12-23 14:00:00+09'::timestamptz
    AND timezone IS NOT DISTINCT FROM 'GMT+9'
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:49Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SCH06 verified_at update count=%', v_count;
  END IF;

  -- SCH10 date/time is on current p3; p2 supplies GMT+9.
  -- Both citations stay attached. Stored end_at matches current p3.
  UPDATE public.admission_schedules
  SET verified_at = v_recheck
  WHERE id = '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid
    AND admission_program_id = v_program_id
    AND event_name = '등록포기 (문서등록 취소)'
    AND end_at IS NOT DISTINCT FROM '2026-12-29 10:00:00+09'::timestamptz
    AND timezone IS NOT DISTINCT FROM 'GMT+9'
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:49Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SCH10 verified_at update count=%', v_count;
  END IF;

  UPDATE public.admission_schedules
  SET verified_at = v_recheck
  WHERE id = '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid
    AND admission_program_id = v_program_id
    AND event_name = '최종합격자 원본 서류 제출'
    AND end_date IS NOT DISTINCT FROM '2027-02-10'::date
    AND timezone IS NOT DISTINCT FROM 'GMT+9'
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:49Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SCH11 verified_at update count=%', v_count;
  END IF;

  UPDATE public.admission_schedules
  SET verified_at = v_recheck
  WHERE id = '84f7daa1-bbe0-4711-b919-926b29092bb8'::uuid
    AND admission_program_id = v_program_id
    AND event_name = '등록금 납부'
    AND start_date IS NOT DISTINCT FROM '2027-02-15'::date
    AND end_date IS NOT DISTINCT FROM '2027-02-16'::date
    AND timezone IS NOT DISTINCT FROM 'GMT+9'
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:49Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SCH12 verified_at update count=%', v_count;
  END IF;

  UPDATE public.admission_schedules
  SET verified_at = v_recheck
  WHERE id = '41b6dc2a-888c-49ba-9414-fc5357c4934f'::uuid
    AND admission_program_id = v_program_id
    AND event_name = '입학허가통지서 출력'
    AND end_at IS NOT DISTINCT FROM '2026-09-30 17:00:00+09'::timestamptz
    AND timezone IS NOT DISTINCT FROM 'GMT+9'
    AND verification_status = 'verified'
    AND verified_at IS NOT DISTINCT FROM '2026-09-05T17:02:08Z'::timestamptz;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev failed: SCH13 verified_at update count=%', v_count;
  END IF;
END
$setb$;

-- =============================================================================
-- 7. Postconditions
-- =============================================================================

DO $post$
DECLARE
  v_program_id uuid := 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  v_src07_id uuid := '31c298f9-cde7-407b-be2d-692235e1a391'::uuid;
  v_new_src_id uuid := 'e2c8f9d5-1a51-44ba-8cd0-725bddd90dfd'::uuid;
  v_cit29_id uuid := '74c5f6e7-a8fe-4c4c-9bcc-598f063b3608'::uuid;
  v_cit30_id uuid := '1f779f06-95f7-4520-890a-e5c30560c33e'::uuid;
  v_new_p2_id uuid := 'a272a151-8fa6-4d46-8373-f68b0c221fcd'::uuid;
  v_new_p3_id uuid := '078f4aaf-21b9-451f-abb8-67df7bab7c76'::uuid;
  v_new_p4_id uuid := 'eb6af150-393f-45ec-ae98-c7ac04e01083'::uuid;
  v_src06_id uuid := 'b17b767f-7eaf-4e12-a2db-6dcf4f024c25'::uuid;
  v_s06_id uuid := '91ce33c3-e327-4681-a267-04c1ba32c172'::uuid;
  v_doc41_id uuid := '47110092-f5be-419c-baa5-39e6154b1ba8'::uuid;
  v_doc42_id uuid := 'cf5b159c-6931-4adf-bfd6-a4614f3d7c62'::uuid;
  v_sub82_id uuid := '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;
  v_sub83_id uuid := 'fe764fa1-fb88-4a63-9395-5988fa0b30fe'::uuid;
  v_sub84_id uuid := '815a43a3-8fb7-4ddc-a2f7-2e13a4ef68f7'::uuid;
  v_recheck timestamptz := '2026-09-21T17:33:12Z'::timestamptz;
  v_marker text :=
    'ChoiceGroup 아님|DOC13과 동일|DOC19와 함께|S05 p4|S05 PDF:|별도 document 아님|SCH02 datetime|admission_schedule_id|조건부여체|한 표 셀|공식명을 그대로|공식명으로 보존|열린 「등」|학교폭력 확인용|official-source conflict|원본 패키지 표와 같은 칸|HTML 3월 문구와 묶지 않음|DOC21–23|DOC34와 기준일';
  v_count integer;
  v_url text;
  v_checked timestamptz;
  v_notes text;
  v_supersedes uuid;
  v_published date;
  v_txt text;
  v_status text;
  v_verified timestamptz;
  v_schedule uuid;
  v_universities integer;
  v_programs integer;
  v_sections integer;
  v_schedules integer;
  v_documents integer;
  v_submissions integer;
  v_choice_groups integer;
  v_choice_items integer;
  v_sources integer;
  v_citations integer;
  v_program_sources integer;
  v_section_cites integer;
  v_document_cites integer;
  v_submission_cites integer;
  v_schedule_cites integer;
  v_choice_cites integer;
  v_current_unique integer;
  v_current_orphan integer;
  v_old_rel integer;
  v_s06_rel integer;
BEGIN
  SELECT source_url, last_checked_at, notes, supersedes_source_document_id
  INTO v_url, v_checked, v_notes, v_supersedes
  FROM public.source_documents
  WHERE id = v_src07_id;
  IF v_url IS DISTINCT FROM
       'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=2'
     OR v_checked IS DISTINCT FROM '2026-09-05T17:02:08Z'::timestamptz
     OR v_supersedes IS NOT NULL
     OR v_notes IS DISTINCT FROM
       '7 physical pages. FILE_SEQ=2 확인. HWP FILE_SEQ=1은 별도 row 없음. p2에 한국 시간(GMT+9) 명시. p4 표의 졸업증명서 기한 표현은 HTML과 다름.'
  THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SRC07 was mutated';
  END IF;

  SELECT source_url, published_at, last_checked_at, supersedes_source_document_id
  INTO v_url, v_published, v_checked, v_supersedes
  FROM public.source_documents
  WHERE id = v_new_src_id;
  IF v_url IS DISTINCT FROM
       'https://oku.korea.ac.kr/ajaxfile/FR_SVC/FileDown.do?GBN=X01&BOARD_SEQ=5&SITE_NO=2&BBS_SEQ=1805&FILE_SEQ=3'
     OR v_published IS NOT NULL
     OR v_checked IS DISTINCT FROM v_recheck
     OR v_supersedes IS DISTINCT FROM v_src07_id THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new SourceDocument metadata';
  END IF;

  SELECT count(*) INTO v_count FROM public.source_citations WHERE id = v_cit29_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: CIT29 row missing';
  END IF;
  SELECT count(*) INTO v_count FROM public.source_citations WHERE id = v_cit30_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: CIT30 row missing';
  END IF;

  SELECT count(*) INTO v_old_rel
  FROM (
    SELECT 1 FROM public.admission_schedule_citations WHERE source_citation_id IN (v_cit29_id, v_cit30_id)
    UNION ALL
    SELECT 1 FROM public.required_document_citations WHERE source_citation_id IN (v_cit29_id, v_cit30_id)
    UNION ALL
    SELECT 1 FROM public.document_submission_citations WHERE source_citation_id IN (v_cit29_id, v_cit30_id)
    UNION ALL
    SELECT 1 FROM public.admission_section_citations WHERE source_citation_id IN (v_cit29_id, v_cit30_id)
    UNION ALL
    SELECT 1 FROM public.required_document_choice_group_citations WHERE source_citation_id IN (v_cit29_id, v_cit30_id)
  ) x;
  IF v_old_rel <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: old CIT29/CIT30 still attached count=%', v_old_rel;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_new_p2_id;
  IF v_count <> 5 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new p2 schedule relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_new_p3_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new p3 schedule relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE admission_schedule_id = '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid
    AND source_citation_id IN (v_new_p2_id, v_new_p3_id);
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SCH10 new p2+p3 relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_schedule_citations
  WHERE source_citation_id = v_new_p3_id
    AND admission_schedule_id <> '6eff94e1-d237-4a8e-867d-ca0a06c81513'::uuid;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new p3 attached outside SCH10 count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_document_citations
  WHERE source_citation_id = v_new_p4_id;
  IF v_count <> 2 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new p4 document relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE source_citation_id = v_new_p4_id;
  IF v_count <> 3 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new p4 submission relations=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src07_id;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SRC07 still current ProgramSource';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_new_src_id
    AND source_role = 'supporting_notice';
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: new S05 ProgramSource count=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.admission_program_sources
  WHERE admission_program_id = v_program_id
    AND source_document_id = v_src06_id;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: S05 HTML ProgramSource changed';
  END IF;

  SELECT condition, verification_status, verified_at
  INTO v_txt, v_status, v_verified
  FROM public.required_documents WHERE id = v_doc41_id;
  IF v_txt IS DISTINCT FROM
       '재외국민(정원외2%)전형 졸업예정자 중 별도 요청한 인원. 조회기간: 지원자 만 12세 생일 ~ 고등학교 졸업일'
     OR v_status IS DISTINCT FROM 'verified'
     OR v_verified IS DISTINCT FROM v_recheck THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: DOC41 after value';
  END IF;

  SELECT condition INTO v_txt FROM public.required_documents WHERE id = v_doc42_id;
  IF v_txt IS DISTINCT FROM
       '재외국민(정원외2%)전형 졸업예정자 중 별도 요청한 인원. 고등학교 졸업일 기준'
  THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: DOC42 after value';
  END IF;

  SELECT instructions, admission_schedule_id, verification_status, verified_at
  INTO v_txt, v_schedule, v_status, v_verified
  FROM public.document_submissions WHERE id = v_sub83_id;
  IF v_txt IS DISTINCT FROM '해당자'
     OR v_schedule IS DISTINCT FROM '8a3e7f88-b24d-4822-9737-485c2539c8cf'::uuid
     OR v_status IS DISTINCT FROM 'verified'
     OR v_verified IS DISTINCT FROM v_recheck THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SUB83 after value';
  END IF;

  SELECT instructions, verification_status, verified_at, admission_schedule_id
  INTO v_txt, v_status, v_verified, v_schedule
  FROM public.document_submissions WHERE id = v_sub82_id;
  SELECT count(*) INTO v_count
  FROM public.document_submission_citations
  WHERE document_submission_id = v_sub82_id;
  IF v_txt IS NOT NULL
     OR v_status IS DISTINCT FROM 'needs_review'
     OR v_verified IS NOT NULL
     OR v_schedule IS NOT NULL
     OR v_count <> 4 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SUB82 invariant after';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.document_submission_citations
    WHERE document_submission_id = v_sub82_id AND source_citation_id = v_new_p4_id
  ) THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SUB82 missing new p4 citation';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.document_submission_citations
    WHERE document_submission_id = v_sub82_id AND source_citation_id = v_cit30_id
  ) THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SUB82 still cites CIT30';
  END IF;

  SELECT instructions, verified_at INTO v_txt, v_verified
  FROM public.document_submissions WHERE id = v_sub84_id;
  IF v_txt IS DISTINCT FROM '해당자' OR v_verified IS DISTINCT FROM v_recheck THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: SUB84 after value';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.required_documents
  WHERE admission_program_id = v_program_id
    AND (
      coalesce(condition, '') ~ v_marker
      OR coalesce(description, '') ~ v_marker
    );
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: remaining document blockers=%', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM public.document_submissions
  WHERE admission_program_id = v_program_id
    AND coalesce(instructions, '') ~ v_marker;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: remaining submission blockers=%', v_count;
  END IF;

  SELECT count(*) INTO v_universities FROM public.universities;
  SELECT count(*) INTO v_programs FROM public.admission_programs WHERE id = v_program_id;
  SELECT count(*) INTO v_sections FROM public.admission_sections WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_schedules FROM public.admission_schedules WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_documents FROM public.required_documents WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_submissions FROM public.document_submissions WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_choice_groups FROM public.required_document_choice_groups WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_choice_items FROM public.required_document_choice_group_items WHERE admission_program_id = v_program_id;
  SELECT count(*) INTO v_sources FROM public.source_documents;
  SELECT count(*) INTO v_citations FROM public.source_citations;
  SELECT count(*) INTO v_program_sources
  FROM public.admission_program_sources WHERE admission_program_id = v_program_id;

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
  SELECT count(*) INTO v_choice_cites
  FROM public.required_document_choice_group_citations r
  JOIN public.required_document_choice_groups g ON g.id = r.choice_group_id
  WHERE g.admission_program_id = v_program_id;

  IF v_universities <> 1
     OR v_programs <> 1
     OR v_sections <> 17
     OR v_schedules <> 15
     OR v_documents <> 42
     OR v_submissions <> 84
     OR v_choice_groups <> 1
     OR v_choice_items <> 2
     OR v_sources <> 8
     OR v_citations <> 37
     OR v_program_sources <> 6
     OR v_section_cites <> 24
     OR v_document_cites <> 56
     OR v_submission_cites <> 90
     OR v_schedule_cites <> 31
     OR v_choice_cites <> 1
     OR (v_section_cites + v_document_cites + v_submission_cites + v_schedule_cites + v_choice_cites) <> 202
  THEN
    RAISE EXCEPTION
      'KU27 S05 rev assertion failed: counts uni=% prog=% sec=% sch=% doc=% sub=% cg=% cgi=% src=% cit=% ps=% sc=% dc=% uc=% hc=% cc=%',
      v_universities, v_programs, v_sections, v_schedules, v_documents,
      v_submissions, v_choice_groups, v_choice_items, v_sources, v_citations,
      v_program_sources, v_section_cites, v_document_cites, v_submission_cites,
      v_schedule_cites, v_choice_cites;
  END IF;

  WITH current_cites AS (
    SELECT r.source_citation_id
    FROM public.admission_section_citations r
    JOIN public.admission_sections s ON s.id = r.admission_section_id
    WHERE s.admission_program_id = v_program_id
    UNION
    SELECT r.source_citation_id
    FROM public.required_document_citations r
    JOIN public.required_documents d ON d.id = r.required_document_id
    WHERE d.admission_program_id = v_program_id
    UNION
    SELECT r.source_citation_id
    FROM public.document_submission_citations r
    JOIN public.document_submissions s ON s.id = r.document_submission_id
    WHERE s.admission_program_id = v_program_id
    UNION
    SELECT r.source_citation_id
    FROM public.admission_schedule_citations r
    JOIN public.admission_schedules s ON s.id = r.admission_schedule_id
    WHERE s.admission_program_id = v_program_id
    UNION
    SELECT r.source_citation_id
    FROM public.required_document_choice_group_citations r
    JOIN public.required_document_choice_groups g ON g.id = r.choice_group_id
    WHERE g.admission_program_id = v_program_id
  )
  SELECT count(*) INTO v_current_unique FROM current_cites;
  IF v_current_unique <> 35 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: current unique citations=%', v_current_unique;
  END IF;

  SELECT count(*) INTO v_current_orphan
  FROM (
    SELECT r.source_citation_id
    FROM public.admission_section_citations r
    JOIN public.admission_sections s ON s.id = r.admission_section_id
    JOIN public.source_citations c ON c.id = r.source_citation_id
    WHERE s.admission_program_id = v_program_id
      AND NOT EXISTS (
        SELECT 1 FROM public.admission_program_sources p
        WHERE p.admission_program_id = v_program_id
          AND p.source_document_id = c.source_document_id
      )
    UNION ALL
    SELECT r.source_citation_id
    FROM public.required_document_citations r
    JOIN public.required_documents d ON d.id = r.required_document_id
    JOIN public.source_citations c ON c.id = r.source_citation_id
    WHERE d.admission_program_id = v_program_id
      AND NOT EXISTS (
        SELECT 1 FROM public.admission_program_sources p
        WHERE p.admission_program_id = v_program_id
          AND p.source_document_id = c.source_document_id
      )
    UNION ALL
    SELECT r.source_citation_id
    FROM public.document_submission_citations r
    JOIN public.document_submissions s ON s.id = r.document_submission_id
    JOIN public.source_citations c ON c.id = r.source_citation_id
    WHERE s.admission_program_id = v_program_id
      AND NOT EXISTS (
        SELECT 1 FROM public.admission_program_sources p
        WHERE p.admission_program_id = v_program_id
          AND p.source_document_id = c.source_document_id
      )
    UNION ALL
    SELECT r.source_citation_id
    FROM public.admission_schedule_citations r
    JOIN public.admission_schedules s ON s.id = r.admission_schedule_id
    JOIN public.source_citations c ON c.id = r.source_citation_id
    WHERE s.admission_program_id = v_program_id
      AND NOT EXISTS (
        SELECT 1 FROM public.admission_program_sources p
        WHERE p.admission_program_id = v_program_id
          AND p.source_document_id = c.source_document_id
      )
    UNION ALL
    SELECT r.source_citation_id
    FROM public.required_document_choice_group_citations r
    JOIN public.required_document_choice_groups g ON g.id = r.choice_group_id
    JOIN public.source_citations c ON c.id = r.source_citation_id
    WHERE g.admission_program_id = v_program_id
      AND NOT EXISTS (
        SELECT 1 FROM public.admission_program_sources p
        WHERE p.admission_program_id = v_program_id
          AND p.source_document_id = c.source_document_id
      )
  ) orphans;
  IF v_current_orphan <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: current citations outside ProgramSources=%', v_current_orphan;
  END IF;

  SELECT (
    SELECT count(*) FROM public.admission_program_sources
    WHERE admission_program_id = v_program_id AND source_document_id = v_s06_id
  ) + (
    SELECT count(*) FROM public.source_citations c
    JOIN (
      SELECT source_citation_id FROM public.admission_section_citations
      UNION ALL
      SELECT source_citation_id FROM public.required_document_citations
      UNION ALL
      SELECT source_citation_id FROM public.document_submission_citations
      UNION ALL
      SELECT source_citation_id FROM public.admission_schedule_citations
      UNION ALL
      SELECT source_citation_id FROM public.required_document_choice_group_citations
    ) r ON r.source_citation_id = c.id
    WHERE c.source_document_id = v_s06_id
  ) INTO v_s06_rel;
  IF v_s06_rel <> 0 THEN
    RAISE EXCEPTION 'KU27 S05 rev assertion failed: S06 current involvement=%', v_s06_rel;
  END IF;
END
$post$;
