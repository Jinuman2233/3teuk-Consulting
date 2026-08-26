-- Runtime validation for supabase/migrations/20260825155343_initial_schema.sql
-- Synthetic fixtures only. No production university/admissions values.
-- Fixture data is rolled back at the end.

BEGIN;

-- ---------------------------------------------------------------------------
-- Schema existence
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  missing text;
  unexpected text;
BEGIN
  SELECT string_agg(t, ', ' ORDER BY t)
  INTO missing
  FROM unnest(ARRAY[
    'universities',
    'admission_categories',
    'admission_programs',
    'admission_sections',
    'admission_schedules',
    'required_documents',
    'document_submissions',
    'required_document_choice_groups',
    'required_document_choice_group_items',
    'source_documents',
    'source_citations',
    'admission_program_sources',
    'admission_section_citations',
    'required_document_citations',
    'document_submission_citations',
    'admission_schedule_citations'
  ]) AS t
  WHERE to_regclass('public.' || t) IS NULL;

  IF missing IS NOT NULL THEN
    RAISE EXCEPTION 'missing core tables: %', missing;
  END IF;

  SELECT string_agg(t, ', ' ORDER BY t)
  INTO unexpected
  FROM unnest(ARRAY[
    'eligibility_rules',
    'faqs',
    'parent_stories',
    'campuses',
    'admission_tracks',
    'source_conflicts'
  ]) AS t
  WHERE to_regclass('public.' || t) IS NOT NULL;

  IF unexpected IS NOT NULL THEN
    RAISE EXCEPTION 'deferred tables unexpectedly exist: %', unexpected;
  END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- Synthetic fixtures
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  uni_a uuid;
  uni_b uuid;
  cat_id uuid;
  prog_a uuid;
  prog_b uuid;
  doc_a uuid;
  doc_b uuid;
  sched_a uuid;
  sched_b uuid;
  sub_linked uuid;
  sub_optional uuid;
  group_a uuid;
  src_x uuid;
  src_y uuid;
  cite_x uuid;
  cite_y uuid;
  section_a uuid;
  src_checked_at timestamptz := TIMESTAMPTZ '2099-01-01 12:00:00+00';
  uni_updated_before timestamptz;
  uni_updated_after timestamptz;
  src_updated_before timestamptz;
  src_updated_after timestamptz;
  src_checked_after timestamptz;
  remaining_join integer;
  remaining_cite integer;
  remaining_src integer;
  remaining_sub integer;
  sub_sched uuid;
  sub_prog uuid;
  fn_exists boolean;
  fn_definer boolean;
  fn_config text[];
BEGIN
  INSERT INTO public.universities (name_ko, display_name, slug)
  VALUES ('Test University A', 'Test University A', 'test-university-a')
  RETURNING id INTO uni_a;

  INSERT INTO public.universities (name_ko, display_name, slug)
  VALUES ('Test University B', 'Test University B', 'test-university-b')
  RETURNING id INTO uni_b;

  INSERT INTO public.admission_categories (code, label)
  VALUES ('synthetic_test', 'Synthetic Test Category')
  RETURNING id INTO cat_id;

  INSERT INTO public.admission_programs (
    university_id,
    admission_category_id,
    academic_year,
    official_program_name,
    display_name,
    admission_slug,
    information_type,
    verification_status
  ) VALUES (
    uni_a,
    cat_id,
    2099,
    'Synthetic Program A',
    'Synthetic Program A',
    'program-a',
    'official_fact',
    'unverified'
  )
  RETURNING id INTO prog_a;

  INSERT INTO public.admission_programs (
    university_id,
    admission_category_id,
    academic_year,
    official_program_name,
    display_name,
    admission_slug,
    information_type,
    verification_status
  ) VALUES (
    uni_b,
    cat_id,
    2099,
    'Synthetic Program B',
    'Synthetic Program B',
    'program-b',
    'official_fact',
    'unverified'
  )
  RETURNING id INTO prog_b;

  INSERT INTO public.required_documents (
    admission_program_id,
    name,
    requirement_status,
    display_order,
    verification_status
  ) VALUES (
    prog_a,
    'Document A',
    'required',
    1,
    'unverified'
  )
  RETURNING id INTO doc_a;

  INSERT INTO public.required_documents (
    admission_program_id,
    name,
    requirement_status,
    display_order,
    verification_status
  ) VALUES (
    prog_b,
    'Document B',
    'required',
    1,
    'unverified'
  )
  RETURNING id INTO doc_b;

  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    start_date,
    end_date,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'Schedule A',
    'date',
    DATE '2099-03-01',
    DATE '2099-03-02',
    'unverified',
    1
  )
  RETURNING id INTO sched_a;

  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    start_at,
    end_at,
    timezone,
    verification_status,
    display_order
  ) VALUES (
    prog_b,
    'Schedule B',
    'datetime',
    TIMESTAMPTZ '2099-04-01 09:00:00+00',
    TIMESTAMPTZ '2099-04-01 18:00:00+00',
    'UTC',
    'unverified',
    1
  )
  RETURNING id INTO sched_b;

  -- 7. same-program submission
  INSERT INTO public.document_submissions (
    required_document_id,
    admission_program_id,
    submission_phase,
    admission_schedule_id,
    display_order,
    verification_status
  ) VALUES (
    doc_a,
    prog_a,
    'application',
    sched_a,
    1,
    'unverified'
  )
  RETURNING id INTO sub_linked;

  -- 8. cross-program submission must fail
  BEGIN
    INSERT INTO public.document_submissions (
      required_document_id,
      admission_program_id,
      submission_phase,
      admission_schedule_id,
      display_order,
      verification_status
    ) VALUES (
      doc_a,
      prog_a,
      'application',
      sched_b,
      2,
      'unverified'
    );
    RAISE EXCEPTION 'expected foreign_key_violation for cross-program submission did not occur';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'PASS: cross-program submission rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'cross-program submission expected foreign_key_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 9. optional schedule (MATCH SIMPLE)
  INSERT INTO public.document_submissions (
    required_document_id,
    admission_program_id,
    submission_phase,
    admission_schedule_id,
    display_order,
    verification_status
  ) VALUES (
    doc_a,
    prog_a,
    'application',
    NULL,
    3,
    'unverified'
  )
  RETURNING id INTO sub_optional;

  IF sub_optional IS NULL THEN
    RAISE EXCEPTION 'optional-schedule submission was not created';
  END IF;

  -- 10. schedule delete SET NULL
  DELETE FROM public.admission_schedules WHERE id = sched_a;

  SELECT COUNT(*) INTO remaining_sub
  FROM public.document_submissions
  WHERE id = sub_linked;

  IF remaining_sub <> 1 THEN
    RAISE EXCEPTION 'linked submission was deleted when schedule was deleted';
  END IF;

  SELECT admission_schedule_id, admission_program_id
  INTO sub_sched, sub_prog
  FROM public.document_submissions
  WHERE id = sub_linked;

  IF sub_sched IS NOT NULL THEN
    RAISE EXCEPTION 'admission_schedule_id was not SET NULL after schedule delete';
  END IF;

  IF sub_prog IS DISTINCT FROM prog_a THEN
    RAISE EXCEPTION 'admission_program_id changed after schedule delete';
  END IF;

  -- 11. choice-group positive
  INSERT INTO public.required_document_choice_groups (
    admission_program_id,
    title,
    rule_text,
    display_order,
    verification_status
  ) VALUES (
    prog_a,
    'Choice Group A',
    'Submit Document A or an allowed synthetic alternative.',
    1,
    'unverified'
  )
  RETURNING id INTO group_a;

  INSERT INTO public.required_document_choice_group_items (
    choice_group_id,
    required_document_id,
    admission_program_id
  ) VALUES (
    group_a,
    doc_a,
    prog_a
  );

  -- 12. cross-program choice must fail
  BEGIN
    INSERT INTO public.required_document_choice_group_items (
      choice_group_id,
      required_document_id,
      admission_program_id
    ) VALUES (
      group_a,
      doc_b,
      prog_a
    );
    RAISE EXCEPTION 'expected foreign_key_violation for cross-program choice item did not occur';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'PASS: cross-program choice item rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'cross-program choice expected foreign_key_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 13. temporal positive: one-sided boundaries
  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    start_date,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'Date only start boundary',
    'date',
    DATE '2099-05-01',
    'unverified',
    2
  );

  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    end_date,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'Date only end boundary',
    'date',
    DATE '2099-05-31',
    'unverified',
    3
  );

  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    start_at,
    timezone,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'Datetime only start boundary',
    'datetime',
    TIMESTAMPTZ '2099-05-01 09:00:00+00',
    'UTC',
    'unverified',
    4
  );

  INSERT INTO public.admission_schedules (
    admission_program_id,
    event_name,
    temporal_precision,
    end_at,
    timezone,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'Datetime only end boundary',
    'datetime',
    TIMESTAMPTZ '2099-05-02 12:00:00+00',
    'UTC',
    'unverified',
    5
  );

  -- 16A. date + timestamp
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      start_date,
      start_at,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid date with timestamp',
      'date',
      DATE '2099-06-01',
      TIMESTAMPTZ '2099-06-01 00:00:00+00',
      'unverified',
      10
    );
    RAISE EXCEPTION 'expected check_violation for date+timestamp did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: date+timestamp rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'date+timestamp expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16B. datetime + date
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      start_at,
      start_date,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid datetime with date',
      'datetime',
      TIMESTAMPTZ '2099-06-01 09:00:00+00',
      DATE '2099-06-01',
      'unverified',
      11
    );
    RAISE EXCEPTION 'expected check_violation for datetime+date did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: datetime+date rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'datetime+date expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16C. date with all temporal fields NULL
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid date empty',
      'date',
      'unverified',
      12
    );
    RAISE EXCEPTION 'expected check_violation for empty date schedule did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: empty date schedule rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'empty date schedule expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16D. datetime with all temporal fields NULL
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid datetime empty',
      'datetime',
      'unverified',
      13
    );
    RAISE EXCEPTION 'expected check_violation for empty datetime schedule did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: empty datetime schedule rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'empty datetime schedule expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16E. start_date > end_date
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      start_date,
      end_date,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid date order',
      'date',
      DATE '2099-07-02',
      DATE '2099-07-01',
      'unverified',
      14
    );
    RAISE EXCEPTION 'expected check_violation for start_date > end_date did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: start_date > end_date rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'start_date > end_date expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16F. start_at > end_at
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      start_at,
      end_at,
      timezone,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid datetime order',
      'datetime',
      TIMESTAMPTZ '2099-07-02 18:00:00+00',
      TIMESTAMPTZ '2099-07-02 09:00:00+00',
      'UTC',
      'unverified',
      15
    );
    RAISE EXCEPTION 'expected check_violation for start_at > end_at did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: start_at > end_at rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'start_at > end_at expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16G. invalid temporal_precision
  BEGIN
    INSERT INTO public.admission_schedules (
      admission_program_id,
      event_name,
      temporal_precision,
      start_date,
      verification_status,
      display_order
    ) VALUES (
      prog_a,
      'Invalid precision',
      'sometime',
      DATE '2099-08-01',
      'unverified',
      16
    );
    RAISE EXCEPTION 'expected check_violation for invalid temporal_precision did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: invalid temporal_precision rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'invalid temporal_precision expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- sources / citations
  INSERT INTO public.source_documents (
    source_type,
    title,
    issuing_organization,
    source_url,
    last_checked_at
  ) VALUES (
    'synthetic',
    'Synthetic Source X',
    'Synthetic Org',
    'https://example.test/source-x',
    src_checked_at
  )
  RETURNING id INTO src_x;

  INSERT INTO public.source_documents (
    source_type,
    title,
    issuing_organization,
    source_url,
    last_checked_at
  ) VALUES (
    'synthetic',
    'Synthetic Source Y',
    'Synthetic Org',
    'https://example.test/source-y',
    src_checked_at
  )
  RETURNING id INTO src_y;

  -- 17. citation page CHECK
  INSERT INTO public.source_citations (source_document_id, file_page_number)
  VALUES (src_x, 1)
  RETURNING id INTO cite_x;

  INSERT INTO public.source_citations (source_document_id, file_page_number)
  VALUES (src_x, NULL)
  RETURNING id INTO cite_y;

  BEGIN
    INSERT INTO public.source_citations (source_document_id, file_page_number)
    VALUES (src_x, 0);
    RAISE EXCEPTION 'expected check_violation for file_page_number = 0 did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: file_page_number = 0 rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'file_page_number = 0 expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  BEGIN
    INSERT INTO public.source_citations (source_document_id, file_page_number)
    VALUES (src_x, -1);
    RAISE EXCEPTION 'expected check_violation for file_page_number = -1 did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: file_page_number = -1 rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'file_page_number = -1 expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 16. self-supersede CHECK (insert and update)
  BEGIN
    INSERT INTO public.source_documents (
      id,
      source_type,
      title,
      issuing_organization,
      source_url,
      last_checked_at,
      supersedes_source_document_id
    ) VALUES (
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'synthetic',
      'Synthetic Self Super Insert',
      'Synthetic Org',
      'https://example.test/self-super-insert',
      src_checked_at,
      'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'
    );
    RAISE EXCEPTION 'expected check_violation for self-supersede insert did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: self-supersede insert rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'self-supersede insert expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  INSERT INTO public.source_documents (
    id,
    source_type,
    title,
    issuing_organization,
    source_url,
    last_checked_at
  ) VALUES (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    'synthetic',
    'Synthetic Self Super Update',
    'Synthetic Org',
    'https://example.test/self-super-update',
    src_checked_at
  );

  BEGIN
    UPDATE public.source_documents
    SET supersedes_source_document_id = id
    WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    RAISE EXCEPTION 'expected check_violation for self-supersede update did not occur';
  EXCEPTION
    WHEN check_violation THEN
      RAISE NOTICE 'PASS: self-supersede update rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'self-supersede update expected check_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 17. source delete RESTRICT via citation
  BEGIN
    DELETE FROM public.source_documents WHERE id = src_x;
    RAISE EXCEPTION 'expected foreign_key_violation deleting cited source did not occur';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'PASS: cited source delete RESTRICT (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'cited source delete expected foreign_key_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  SELECT COUNT(*) INTO remaining_cite
  FROM public.source_citations
  WHERE id = cite_x;

  IF remaining_cite <> 1 THEN
    RAISE EXCEPTION 'source citation was deleted when source delete was restricted';
  END IF;

  INSERT INTO public.admission_program_sources (
    admission_program_id,
    source_document_id
  ) VALUES (
    prog_a,
    src_y
  );

  BEGIN
    DELETE FROM public.source_documents WHERE id = src_y;
    RAISE EXCEPTION 'expected foreign_key_violation deleting program-linked source did not occur';
  EXCEPTION
    WHEN foreign_key_violation THEN
      RAISE NOTICE 'PASS: program-linked source delete RESTRICT (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'program-linked source delete expected foreign_key_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  -- 20. entity-side citation CASCADE, source/citation retained
  INSERT INTO public.admission_sections (
    admission_program_id,
    section_type,
    title,
    content,
    information_type,
    availability_status,
    verification_status,
    display_order
  ) VALUES (
    prog_a,
    'notes',
    'Synthetic Section A',
    'Synthetic section content.',
    'official_fact',
    'available',
    'unverified',
    1
  )
  RETURNING id INTO section_a;

  INSERT INTO public.admission_section_citations (
    admission_section_id,
    source_citation_id
  ) VALUES (
    section_a,
    cite_x
  );

  DELETE FROM public.admission_sections WHERE id = section_a;

  SELECT COUNT(*) INTO remaining_join
  FROM public.admission_section_citations
  WHERE admission_section_id = section_a;

  IF remaining_join <> 0 THEN
    RAISE EXCEPTION 'section citation join row was not cascaded';
  END IF;

  SELECT COUNT(*) INTO remaining_cite
  FROM public.source_citations
  WHERE id = cite_x;

  SELECT COUNT(*) INTO remaining_src
  FROM public.source_documents
  WHERE id = src_x;

  IF remaining_cite <> 1 OR remaining_src <> 1 THEN
    RAISE EXCEPTION 'source citation or source document was deleted with section';
  END IF;

  -- 23. provenance consistency is not DB-enforced:
  -- Entity -> Citation -> SourceDocument can exist without
  -- AdmissionProgram <-> SourceDocument. cite_x / src_x have no
  -- admission_program_sources row for src_x; that insert is allowed.

  -- 19 continued: routing UNIQUE
  BEGIN
    INSERT INTO public.admission_programs (
      university_id,
      academic_year,
      official_program_name,
      display_name,
      admission_slug,
      information_type,
      verification_status
    ) VALUES (
      uni_a,
      2099,
      'Synthetic Program A Duplicate',
      'Synthetic Program A Duplicate',
      'program-a',
      'official_fact',
      'unverified'
    );
    RAISE EXCEPTION 'expected unique_violation for routing key did not occur';
  EXCEPTION
    WHEN unique_violation THEN
      RAISE NOTICE 'PASS: routing UNIQUE rejected (SQLSTATE %)', SQLSTATE;
    WHEN OTHERS THEN
      RAISE EXCEPTION 'routing UNIQUE expected unique_violation, got SQLSTATE %: %', SQLSTATE, SQLERRM;
  END;

  INSERT INTO public.admission_programs (
    university_id,
    academic_year,
    official_program_name,
    display_name,
    admission_slug,
    information_type,
    verification_status
  ) VALUES (
    uni_a,
    2100,
    'Synthetic Program A Next Year',
    'Synthetic Program A Next Year',
    'program-a',
    'official_fact',
    'unverified'
  );

  -- 20. updated_at trigger
  SELECT updated_at INTO uni_updated_before
  FROM public.universities
  WHERE id = uni_a;

  PERFORM pg_sleep(1);

  UPDATE public.universities
  SET display_name = 'Test University A Updated'
  WHERE id = uni_a;

  SELECT updated_at INTO uni_updated_after
  FROM public.universities
  WHERE id = uni_a;

  IF uni_updated_after <= uni_updated_before THEN
    RAISE EXCEPTION 'universities.updated_at did not increase after update';
  END IF;

  -- universities have no verified_at; programs must stay null unless set
  IF EXISTS (
    SELECT 1
    FROM public.admission_programs
    WHERE id = prog_a
      AND verified_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'admission_programs.verified_at was populated automatically';
  END IF;

  UPDATE public.admission_programs
  SET display_name = 'Synthetic Program A Updated'
  WHERE id = prog_a;

  IF EXISTS (
    SELECT 1
    FROM public.admission_programs
    WHERE id = prog_a
      AND verified_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'admission_programs.verified_at changed on ordinary update';
  END IF;

  -- 21. last_checked_at preservation
  SELECT updated_at INTO src_updated_before
  FROM public.source_documents
  WHERE id = src_x;

  PERFORM pg_sleep(1);

  UPDATE public.source_documents
  SET notes = 'synthetic note'
  WHERE id = src_x;

  SELECT updated_at, last_checked_at
  INTO src_updated_after, src_checked_after
  FROM public.source_documents
  WHERE id = src_x;

  IF src_updated_after <= src_updated_before THEN
    RAISE EXCEPTION 'source_documents.updated_at did not increase after update';
  END IF;

  IF src_checked_after IS DISTINCT FROM src_checked_at THEN
    RAISE EXCEPTION 'source_documents.last_checked_at changed on ordinary update';
  END IF;

  -- 22. function hardening catalog (non-fragile subset)
  SELECT
    TRUE,
    p.prosecdef,
    p.proconfig
  INTO fn_exists, fn_definer, fn_config
  FROM pg_proc p
  JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname = 'public'
    AND p.proname = 'set_updated_at';

  IF NOT COALESCE(fn_exists, FALSE) THEN
    RAISE EXCEPTION 'public.set_updated_at() does not exist';
  END IF;

  IF fn_definer THEN
    RAISE EXCEPTION 'public.set_updated_at() is SECURITY DEFINER';
  END IF;

  RAISE NOTICE 'set_updated_at exists, SECURITY DEFINER=%, proconfig=%', fn_definer, fn_config;
  RAISE NOTICE 'runtime constraint tests passed';
END;
$$;

ROLLBACK;
