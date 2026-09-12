-- Add required_document_choice_group_citations.
--
-- Structure only for the new citation-join table, plus the same
-- public-read SELECT posture used by the other citation joins.
-- Does not rewrite 20260907081000_public_read_rls.sql.
-- No admissions data.

-- ---------------------------------------------------------------------------
-- Preflight: roles exist; table is absent; no silent recovery
-- ---------------------------------------------------------------------------

DO $$
DECLARE
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
    RAISE EXCEPTION
      'choice-group citations preflight failed: role anon does not exist';
  END IF;

  IF NOT authenticated_exists THEN
    RAISE EXCEPTION
      'choice-group citations preflight failed: role authenticated does not exist';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'required_document_choice_group_citations'
      AND c.relkind = 'r'
  )
  INTO table_exists;

  IF table_exists THEN
    RAISE EXCEPTION
      'choice-group citations preflight failed: public.required_document_choice_group_citations already exists; refusing silent recovery';
  END IF;

  SELECT c.relrowsecurity
  INTO rls_enabled
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'required_document_choice_group_citations'
    AND c.relkind = 'r';

  IF rls_enabled IS TRUE THEN
    RAISE EXCEPTION
      'choice-group citations preflight failed: public.required_document_choice_group_citations already has RLS enabled';
  END IF;

  SELECT count(*)
  INTO existing_policy_count
  FROM pg_catalog.pg_policy p
  JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'required_document_choice_group_citations';

  IF existing_policy_count <> 0 THEN
    RAISE EXCEPTION
      'choice-group citations preflight failed: public.required_document_choice_group_citations already has % policy/policies; refusing silent recovery',
      existing_policy_count;
  END IF;
END
$$;

-- ---------------------------------------------------------------------------
-- Table: same shape as the other citation joins
-- ---------------------------------------------------------------------------

CREATE TABLE public.required_document_choice_group_citations (
  choice_group_id uuid NOT NULL,
  source_citation_id uuid NOT NULL,
  PRIMARY KEY (choice_group_id, source_citation_id),
  CONSTRAINT required_document_choice_group_citations_choice_group_id_fkey
    FOREIGN KEY (choice_group_id)
    REFERENCES public.required_document_choice_groups (id)
    ON DELETE CASCADE,
  CONSTRAINT required_document_choice_group_citations_source_citation_fkey
    FOREIGN KEY (source_citation_id)
    REFERENCES public.source_citations (id)
    ON DELETE RESTRICT
);

CREATE INDEX required_document_choice_group_citations_source_citation_id_idx
  ON public.required_document_choice_group_citations (source_citation_id);

-- ---------------------------------------------------------------------------
-- Public-read SELECT for this table only
-- ---------------------------------------------------------------------------

REVOKE ALL PRIVILEGES ON TABLE
  public.required_document_choice_group_citations
FROM anon, authenticated;

GRANT SELECT ON TABLE
  public.required_document_choice_group_citations
TO anon, authenticated;

CREATE POLICY public_read_required_document_choice_group_citations
  ON public.required_document_choice_group_citations
  FOR SELECT
  TO anon, authenticated
  USING (true);

ALTER TABLE public.required_document_choice_group_citations
  ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Postconditions: same checks as the 16-table public-read bootstrap
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  table_name text := 'required_document_choice_group_citations';
  expected_policy_name text := 'public_read_required_document_choice_group_citations';
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

  SELECT c.relrowsecurity, c.relforcerowsecurity
  INTO rls_enabled, force_rls
  FROM pg_catalog.pg_class c
  JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = table_name
    AND c.relkind = 'r';

  IF rls_enabled IS NOT TRUE THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% does not have RLS enabled',
      table_name;
  END IF;

  IF force_rls IS NOT FALSE THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% has FORCE ROW LEVEL SECURITY enabled',
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
      'choice-group citations postcondition failed: public.% has % policies; expected exactly 1 SELECT policy',
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
      'choice-group citations postcondition failed: public.% has % non-SELECT policy/policies',
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
      'choice-group citations postcondition failed: public.% policy name is %; expected %',
      table_name,
      policy_name,
      expected_policy_name;
  END IF;

  IF policy_cmd <> 'r' THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% policy % is not FOR SELECT',
      table_name,
      policy_name;
  END IF;

  IF policy_roles IS NULL OR array_length(policy_roles, 1) IS DISTINCT FROM 2 THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% policy % does not target exactly anon and authenticated',
      table_name,
      policy_name;
  END IF;

  IF NOT (anon_oid = ANY (policy_roles)) THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% policy % does not include role anon',
      table_name,
      policy_name;
  END IF;

  IF NOT (authenticated_oid = ANY (policy_roles)) THEN
    RAISE EXCEPTION
      'choice-group citations postcondition failed: public.% policy % does not include role authenticated',
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
        'choice-group citations postcondition failed: role % lacks SELECT on public.%',
        role_name,
        table_name;
    END IF;

    IF has_insert IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has INSERT on public.%',
        role_name,
        table_name;
    END IF;

    IF has_update IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has UPDATE on public.%',
        role_name,
        table_name;
    END IF;

    IF has_delete IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has DELETE on public.%',
        role_name,
        table_name;
    END IF;

    IF has_truncate IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has TRUNCATE on public.%',
        role_name,
        table_name;
    END IF;

    IF has_references IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has REFERENCES on public.%',
        role_name,
        table_name;
    END IF;

    IF has_trigger IS NOT FALSE THEN
      RAISE EXCEPTION
        'choice-group citations postcondition failed: role % still has TRIGGER on public.%',
        role_name,
        table_name;
    END IF;
  END LOOP;
END
$$;
