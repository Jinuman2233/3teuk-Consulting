-- Public-read RLS for the 16 core admission tables.
--
-- Purpose:
--   Enable RLS on the 16 public-schema tables defined in
--   supabase/migrations/20260825155343_initial_schema.sql
--   and grant SELECT-only access to anon and authenticated.
--
-- Intended runtime:
--   PostgreSQL 17 (Supabase hosted).
--
-- Deployer:
--   This file does not specify or assume the exact session role used by
--   supabase db push. It uses table-owner-capable statements
--   (REVOKE / GRANT / CREATE POLICY / ALTER TABLE ... ENABLE ROW LEVEL SECURITY).
--   Whether the actual CLI session can execute those statements is a
--   later runtime test.
--
-- Transaction assumption:
--   This file does not assume that the Supabase CLI runner wraps the
--   entire migration in one explicit transaction. Privilege changes are
--   issued as two set-wide statements so that a later policy/RLS failure
--   cannot leave a subset of tables write-open. Policy creation is
--   completed before ENABLE RLS so that a mid-policy failure can keep
--   SELECT privilege available while writes remain denied.
--
-- Scope:
--   Core 16 tables only. FAQ, parent-experience, and eligibility tables
--   are not included.
--
-- Privilege allowlist:
--   After apply, anon and authenticated must have SELECT only.
--   INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, and TRIGGER must be
--   denied. No write policies are created.
--
-- FORCE RLS:
--   Not used. Table owners (postgres) remain able to bypass RLS.
--
-- PUBLIC / service_role:
--   This migration does not GRANT, REVOKE, or ALTER those roles.
--
-- Data:
--   No INSERT / UPDATE / DELETE of application rows.
--
-- Idempotency:
--   Not idempotent. Preflight fails if any target already has RLS enabled
--   or already has any policy. There is no silent DROP POLICY / DISABLE RLS
--   recovery. A second run on a successful apply must fail closed.

DO $$
DECLARE
  target_tables text[] := ARRAY[
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
  ];
  table_name text;
  table_exists boolean;
  rls_enabled boolean;
  existing_policy_count integer;
  anon_exists boolean;
  authenticated_exists boolean;
BEGIN
  SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon')
    INTO anon_exists;
  SELECT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated')
    INTO authenticated_exists;

  IF NOT anon_exists THEN
    RAISE EXCEPTION 'public-read RLS preflight failed: role anon does not exist';
  END IF;

  IF NOT authenticated_exists THEN
    RAISE EXCEPTION 'public-read RLS preflight failed: role authenticated does not exist';
  END IF;

  FOREACH table_name IN ARRAY target_tables LOOP
    SELECT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_class c
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = table_name
        AND c.relkind = 'r'
    )
    INTO table_exists;

    IF NOT table_exists THEN
      RAISE EXCEPTION
        'public-read RLS preflight failed: required table public.% does not exist',
        table_name;
    END IF;

    SELECT c.relrowsecurity
    INTO rls_enabled
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name
      AND c.relkind = 'r';

    IF rls_enabled THEN
      RAISE EXCEPTION
        'public-read RLS preflight failed: public.% already has RLS enabled; refusing to mutate an already-protected table',
        table_name;
    END IF;

    SELECT count(*)
    INTO existing_policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name;

    IF existing_policy_count <> 0 THEN
      RAISE EXCEPTION
        'public-read RLS preflight failed: public.% already has % policy/policies; refusing silent recovery',
        table_name,
        existing_policy_count;
    END IF;
  END LOOP;
END
$$;

REVOKE ALL PRIVILEGES ON TABLE
  public.universities,
  public.admission_categories,
  public.admission_programs,
  public.admission_sections,
  public.admission_schedules,
  public.required_documents,
  public.document_submissions,
  public.required_document_choice_groups,
  public.required_document_choice_group_items,
  public.source_documents,
  public.source_citations,
  public.admission_program_sources,
  public.admission_section_citations,
  public.required_document_citations,
  public.document_submission_citations,
  public.admission_schedule_citations
FROM anon, authenticated;

GRANT SELECT ON TABLE
  public.universities,
  public.admission_categories,
  public.admission_programs,
  public.admission_sections,
  public.admission_schedules,
  public.required_documents,
  public.document_submissions,
  public.required_document_choice_groups,
  public.required_document_choice_group_items,
  public.source_documents,
  public.source_citations,
  public.admission_program_sources,
  public.admission_section_citations,
  public.required_document_citations,
  public.document_submission_citations,
  public.admission_schedule_citations
TO anon, authenticated;

CREATE POLICY public_read_universities
  ON public.universities
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_categories
  ON public.admission_categories
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_programs
  ON public.admission_programs
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_sections
  ON public.admission_sections
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_schedules
  ON public.admission_schedules
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_required_documents
  ON public.required_documents
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_document_submissions
  ON public.document_submissions
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_required_document_choice_groups
  ON public.required_document_choice_groups
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_required_document_choice_group_items
  ON public.required_document_choice_group_items
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_source_documents
  ON public.source_documents
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_source_citations
  ON public.source_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_program_sources
  ON public.admission_program_sources
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_section_citations
  ON public.admission_section_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_required_document_citations
  ON public.required_document_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_document_submission_citations
  ON public.document_submission_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY public_read_admission_schedule_citations
  ON public.admission_schedule_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

ALTER TABLE public.universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.required_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.required_document_choice_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.required_document_choice_group_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.source_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.source_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_program_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_section_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.required_document_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_submission_citations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admission_schedule_citations ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  target_tables text[] := ARRAY[
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
  ];
  expected_policy_names text[] := ARRAY[
    'public_read_universities',
    'public_read_admission_categories',
    'public_read_admission_programs',
    'public_read_admission_sections',
    'public_read_admission_schedules',
    'public_read_required_documents',
    'public_read_document_submissions',
    'public_read_required_document_choice_groups',
    'public_read_required_document_choice_group_items',
    'public_read_source_documents',
    'public_read_source_citations',
    'public_read_admission_program_sources',
    'public_read_admission_section_citations',
    'public_read_required_document_citations',
    'public_read_document_submission_citations',
    'public_read_admission_schedule_citations'
  ];
  i integer;
  table_name text;
  expected_policy_name text;
  rls_enabled boolean;
  force_rls boolean;
  total_policy_count integer;
  write_policy_count integer;
  policy_name name;
  policy_cmd char(1);
  policy_roles oid[];
  anon_oid oid;
  authenticated_oid oid;
  role_name name;
  has_select boolean;
  has_insert boolean;
  has_update boolean;
  has_delete boolean;
  has_truncate boolean;
  has_references boolean;
  has_trigger boolean;
BEGIN
  SELECT oid INTO anon_oid FROM pg_roles WHERE rolname = 'anon';
  SELECT oid INTO authenticated_oid FROM pg_roles WHERE rolname = 'authenticated';

  FOR i IN 1 .. array_length(target_tables, 1) LOOP
    table_name := target_tables[i];
    expected_policy_name := expected_policy_names[i];

    SELECT c.relrowsecurity, c.relforcerowsecurity
    INTO rls_enabled, force_rls
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name
      AND c.relkind = 'r';

    IF rls_enabled IS NOT TRUE THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% does not have RLS enabled',
        table_name;
    END IF;

    IF force_rls IS NOT FALSE THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% has FORCE ROW LEVEL SECURITY enabled',
        table_name;
    END IF;

    SELECT count(*)
    INTO total_policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name;

    IF total_policy_count <> 1 THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% has % policies; expected exactly 1 SELECT policy',
        table_name,
        total_policy_count;
    END IF;

    SELECT count(*)
    INTO write_policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name
      AND p.polcmd <> 'r';

    IF write_policy_count <> 0 THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% has % non-SELECT policy/policies',
        table_name,
        write_policy_count;
    END IF;

    SELECT p.polname, p.polcmd, p.polroles
    INTO policy_name, policy_cmd, policy_roles
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name;

    IF policy_name IS DISTINCT FROM expected_policy_name THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% policy name is %; expected %',
        table_name,
        policy_name,
        expected_policy_name;
    END IF;

    IF policy_cmd <> 'r' THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% policy % is not FOR SELECT',
        table_name,
        policy_name;
    END IF;

    IF policy_roles IS NULL OR array_length(policy_roles, 1) IS DISTINCT FROM 2 THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% policy % does not target exactly anon and authenticated',
        table_name,
        policy_name;
    END IF;

    IF NOT (anon_oid = ANY (policy_roles)) THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% policy % does not include role anon',
        table_name,
        policy_name;
    END IF;

    IF NOT (authenticated_oid = ANY (policy_roles)) THEN
      RAISE EXCEPTION
        'public-read RLS postcondition failed: public.% policy % does not include role authenticated',
        table_name,
        policy_name;
    END IF;

    FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated']::name[] LOOP
      has_select := has_table_privilege(role_name, format('public.%I', table_name), 'SELECT');
      has_insert := has_table_privilege(role_name, format('public.%I', table_name), 'INSERT');
      has_update := has_table_privilege(role_name, format('public.%I', table_name), 'UPDATE');
      has_delete := has_table_privilege(role_name, format('public.%I', table_name), 'DELETE');
      has_truncate := has_table_privilege(role_name, format('public.%I', table_name), 'TRUNCATE');
      has_references := has_table_privilege(role_name, format('public.%I', table_name), 'REFERENCES');
      has_trigger := has_table_privilege(role_name, format('public.%I', table_name), 'TRIGGER');

      IF has_select IS NOT TRUE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % lacks SELECT on public.%',
          role_name,
          table_name;
      END IF;

      IF has_insert IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has INSERT on public.%',
          role_name,
          table_name;
      END IF;

      IF has_update IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has UPDATE on public.%',
          role_name,
          table_name;
      END IF;

      IF has_delete IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has DELETE on public.%',
          role_name,
          table_name;
      END IF;

      IF has_truncate IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has TRUNCATE on public.%',
          role_name,
          table_name;
      END IF;

      IF has_references IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has REFERENCES on public.%',
          role_name,
          table_name;
      END IF;

      IF has_trigger IS NOT FALSE THEN
        RAISE EXCEPTION
          'public-read RLS postcondition failed: role % still has TRIGGER on public.%',
          role_name,
          table_name;
      END IF;
    END LOOP;
  END LOOP;
END
$$;
