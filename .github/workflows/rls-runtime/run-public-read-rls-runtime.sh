#!/usr/bin/env bash
# Ephemeral PostgreSQL 17 runtime validation for public-read RLS.
# Test fixture only. Does not modify production migration SQL.
# Does not connect to a hosted destination.
set -euo pipefail

SCHEMA_FILE="${SCHEMA_FILE:-supabase/migrations/20260825155343_initial_schema.sql}"
KU_FILE="${KU_FILE:-supabase/migrations/20260905160000_load_ku_2027_reentry.sql}"
RLS_FILE="${RLS_FILE:-supabase/migrations/20260907081000_public_read_rls.sql}"

psql_stop() {
  local db="$1"
  shift
  psql -d "$db" -v ON_ERROR_STOP=1 "$@"
}

create_hosted_like_roles() {
  # Cluster-wide roles. Test fixture matching hosted-like attributes:
  # anon/authenticated NO BYPASSRLS; service_role BYPASSRLS.
  # Container postgres is superuser; do not claim it matches hosted postgres.
  psql_stop postgres <<'SQL'
DO $roles$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    RAISE EXCEPTION 'test fixture: role anon already exists';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    RAISE EXCEPTION 'test fixture: role authenticated already exists';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    RAISE EXCEPTION 'test fixture: role service_role already exists';
  END IF;
END
$roles$;

CREATE ROLE anon NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
CREATE ROLE authenticated NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS;
CREATE ROLE service_role NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE BYPASSRLS;

SELECT rolname, rolsuper, rolbypassrls
FROM pg_roles
WHERE rolname IN ('anon', 'authenticated', 'service_role', 'postgres')
ORDER BY rolname;
SQL
}

apply_schema() {
  local db="$1"
  psql_stop "$db" -f "$SCHEMA_FILE"
}

apply_hosted_like_grants() {
  local db="$1"
  # Test fixture only: reproduce hosted pre-RLS audit
  # (anon/authenticated effective ALL table privileges; PUBLIC table grants 0).
  psql_stop "$db" <<'SQL'
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

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
FROM PUBLIC;

GRANT ALL PRIVILEGES ON TABLE
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
TO anon, authenticated, service_role;
SQL
}

assert_pre_rls() {
  local db="$1"
  psql_stop "$db" <<'SQL'
DO $pre$
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
  rls_enabled boolean;
  policy_count integer;
  public_grant_count integer;
  role_name name;
  priv text;
  privs text[] := ARRAY[
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'
  ];
BEGIN
  FOREACH table_name IN ARRAY target_tables LOOP
    SELECT c.relrowsecurity INTO rls_enabled
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name AND c.relkind = 'r';
    IF rls_enabled IS NOT FALSE THEN
      RAISE EXCEPTION 'pre-RLS: public.% RLS is not off', table_name;
    END IF;

    SELECT count(*) INTO policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name;
    IF policy_count <> 0 THEN
      RAISE EXCEPTION 'pre-RLS: public.% already has % policies', table_name, policy_count;
    END IF;

    FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated']::name[] LOOP
      FOREACH priv IN ARRAY privs LOOP
        IF has_table_privilege(role_name, format('public.%I', table_name), priv) IS NOT TRUE THEN
          RAISE EXCEPTION 'pre-RLS fixture: role % lacks % on public.%', role_name, priv, table_name;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  SELECT count(*) INTO public_grant_count
  FROM information_schema.role_table_grants
  WHERE table_schema = 'public'
    AND grantee = 'PUBLIC'
    AND table_name = ANY (target_tables);
  IF public_grant_count <> 0 THEN
    RAISE EXCEPTION 'pre-RLS: PUBLIC has % direct table privileges', public_grant_count;
  END IF;
END
$pre$;
SQL
}

assert_ku_baseline() {
  local db="$1"
  psql_stop "$db" <<'SQL'
DO $ku$
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
  v_relations integer;
  v_n integer;
  v_status text;
  v_ts timestamptz;
  v_uuid uuid;
BEGIN
  SELECT count(*) INTO v_universities FROM public.universities;
  SELECT count(*) INTO v_categories FROM public.admission_categories;
  SELECT count(*) INTO v_sources FROM public.source_documents;
  SELECT count(*) INTO v_programs FROM public.admission_programs;
  SELECT count(*) INTO v_program_sources FROM public.admission_program_sources;
  SELECT count(*) INTO v_sections FROM public.admission_sections;
  SELECT count(*) INTO v_schedules FROM public.admission_schedules;
  SELECT count(*) INTO v_documents FROM public.required_documents;
  SELECT count(*) INTO v_submissions FROM public.document_submissions;
  SELECT count(*) INTO v_choice_groups FROM public.required_document_choice_groups;
  SELECT count(*) INTO v_choice_items FROM public.required_document_choice_group_items;
  SELECT count(*) INTO v_citations FROM public.source_citations;
  SELECT count(*) INTO v_section_cites FROM public.admission_section_citations;
  SELECT count(*) INTO v_document_cites FROM public.required_document_citations;
  SELECT count(*) INTO v_submission_cites FROM public.document_submission_citations;
  SELECT count(*) INTO v_schedule_cites FROM public.admission_schedule_citations;
  v_relations := v_section_cites + v_document_cites + v_submission_cites + v_schedule_cites;

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
     OR v_relations <> 200 THEN
    RAISE EXCEPTION
      'KU count mismatch universities=% categories=% sources=% programs=% program_sources=% sections=% schedules=% documents=% submissions=% choice_groups=% choice_items=% citations=% section_cites=% document_cites=% submission_cites=% schedule_cites=% relations=%',
      v_universities, v_categories, v_sources, v_programs, v_program_sources,
      v_sections, v_schedules, v_documents, v_submissions, v_choice_groups,
      v_choice_items, v_citations, v_section_cites, v_document_cites,
      v_submission_cites, v_schedule_cites, v_relations;
  END IF;

  SELECT verification_status, verified_at
    INTO v_status, v_ts
  FROM public.admission_programs
  WHERE id = 'd35bda6d-9fed-48f1-8687-28c5d07be455'::uuid;
  IF v_status IS DISTINCT FROM 'partially_verified' OR v_ts IS NOT NULL THEN
    RAISE EXCEPTION 'P01 preservation failed: status=% verified_at=%', v_status, v_ts;
  END IF;

  SELECT verification_status, admission_schedule_id, verified_at
    INTO v_status, v_uuid, v_ts
  FROM public.document_submissions
  WHERE id = '46bd94bf-42dd-4d85-85c5-ec828061f6df'::uuid;
  IF v_status IS DISTINCT FROM 'needs_review' OR v_uuid IS NOT NULL OR v_ts IS NOT NULL THEN
    RAISE EXCEPTION
      'SUB82 preservation failed: status=% schedule=% verified_at=%',
      v_status, v_uuid, v_ts;
  END IF;

  SELECT count(*) INTO v_n FROM public.universities
  WHERE id = '86d02517-736f-4e4b-a80f-b95e518c3433'::uuid;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'U01 missing';
  END IF;
END
$ku$;
SQL
}

snapshot_ku_counts() {
  local db="$1"
  local out="$2"
  {
    echo "universities=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.universities;')"
    echo "admission_categories=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_categories;')"
    echo "source_documents=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.source_documents;')"
    echo "admission_programs=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_programs;')"
    echo "admission_program_sources=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_program_sources;')"
    echo "admission_sections=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_sections;')"
    echo "admission_schedules=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_schedules;')"
    echo "required_documents=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.required_documents;')"
    echo "document_submissions=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.document_submissions;')"
    echo "required_document_choice_groups=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.required_document_choice_groups;')"
    echo "required_document_choice_group_items=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.required_document_choice_group_items;')"
    echo "source_citations=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.source_citations;')"
    echo "admission_section_citations=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_section_citations;')"
    echo "required_document_citations=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.required_document_citations;')"
    echo "document_submission_citations=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.document_submission_citations;')"
    echo "admission_schedule_citations=$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.admission_schedule_citations;')"
  } > "$out"
  cat "$out"
}

assert_rls_postconditions() {
  local db="$1"
  psql_stop "$db" <<'SQL'
DO $post$
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
  rls_on_count integer := 0;
  force_on_count integer := 0;
  total_policies integer := 0;
  total_write_policies integer := 0;
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
    WHERE n.nspname = 'public' AND c.relname = table_name AND c.relkind = 'r';

    IF rls_enabled IS TRUE THEN
      rls_on_count := rls_on_count + 1;
    ELSE
      RAISE EXCEPTION 'post-RLS: public.% relrowsecurity is not true', table_name;
    END IF;

    IF force_rls IS TRUE THEN
      force_on_count := force_on_count + 1;
      RAISE EXCEPTION 'post-RLS: public.% FORCE RLS is enabled', table_name;
    END IF;

    SELECT count(*) INTO total_policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name;
    total_policies := total_policies + total_policy_count;
    IF total_policy_count <> 1 THEN
      RAISE EXCEPTION 'post-RLS: public.% has % policies; expected 1', table_name, total_policy_count;
    END IF;

    SELECT count(*) INTO write_policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name AND p.polcmd <> 'r';
    total_write_policies := total_write_policies + write_policy_count;
    IF write_policy_count <> 0 THEN
      RAISE EXCEPTION 'post-RLS: public.% has % write policies', table_name, write_policy_count;
    END IF;

    SELECT p.polname, p.polcmd, p.polroles
    INTO policy_name, policy_cmd, policy_roles
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name;

    IF policy_name IS DISTINCT FROM expected_policy_name THEN
      RAISE EXCEPTION 'post-RLS: public.% policy name % expected %', table_name, policy_name, expected_policy_name;
    END IF;
    IF policy_cmd <> 'r' THEN
      RAISE EXCEPTION 'post-RLS: public.% policy is not SELECT', table_name;
    END IF;
    IF policy_roles IS NULL OR array_length(policy_roles, 1) IS DISTINCT FROM 2 THEN
      RAISE EXCEPTION 'post-RLS: public.% policy roles are not exactly 2', table_name;
    END IF;
    IF NOT (anon_oid = ANY (policy_roles)) OR NOT (authenticated_oid = ANY (policy_roles)) THEN
      RAISE EXCEPTION 'post-RLS: public.% policy roles are not exactly anon+authenticated', table_name;
    END IF;

    FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated']::name[] LOOP
      has_select := has_table_privilege(role_name, format('public.%I', table_name), 'SELECT');
      has_insert := has_table_privilege(role_name, format('public.%I', table_name), 'INSERT');
      has_update := has_table_privilege(role_name, format('public.%I', table_name), 'UPDATE');
      has_delete := has_table_privilege(role_name, format('public.%I', table_name), 'DELETE');
      has_truncate := has_table_privilege(role_name, format('public.%I', table_name), 'TRUNCATE');
      has_references := has_table_privilege(role_name, format('public.%I', table_name), 'REFERENCES');
      has_trigger := has_table_privilege(role_name, format('public.%I', table_name), 'TRIGGER');
      IF has_select IS NOT TRUE
         OR has_insert IS NOT FALSE
         OR has_update IS NOT FALSE
         OR has_delete IS NOT FALSE
         OR has_truncate IS NOT FALSE
         OR has_references IS NOT FALSE
         OR has_trigger IS NOT FALSE THEN
        RAISE EXCEPTION
          'post-RLS privilege matrix failed for % on public.% SELECT=% INSERT=% UPDATE=% DELETE=% TRUNCATE=% REFERENCES=% TRIGGER=%',
          role_name, table_name, has_select, has_insert, has_update, has_delete,
          has_truncate, has_references, has_trigger;
      END IF;
    END LOOP;
  END LOOP;

  IF rls_on_count <> 16 THEN
    RAISE EXCEPTION 'RLS enabled count=% expected 16', rls_on_count;
  END IF;
  IF force_on_count <> 0 THEN
    RAISE EXCEPTION 'FORCE RLS count=% expected 0', force_on_count;
  END IF;
  IF total_policies <> 16 THEN
    RAISE EXCEPTION 'policy count=% expected 16', total_policies;
  END IF;
  IF total_write_policies <> 0 THEN
    RAISE EXCEPTION 'write policy count=% expected 0', total_write_policies;
  END IF;

  RAISE NOTICE 'RLS 16/16 ON, FORCE 0, policies 16 SELECT, write policies 0';
END
$post$;

SELECT c.relname AS table_name,
       r.rolname AS role_name,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'SELECT') AS has_select,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'INSERT') AS has_insert,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'UPDATE') AS has_update,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'DELETE') AS has_delete,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'TRUNCATE') AS has_truncate,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'REFERENCES') AS has_references,
       has_table_privilege(r.rolname, format('public.%I', c.relname), 'TRIGGER') AS has_trigger
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN (VALUES ('anon'::name), ('authenticated'::name)) AS r(rolname)
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND c.relname IN (
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
  )
ORDER BY c.relname, r.rolname;
SQL
}

assert_actual_select() {
  local db="$1"
  local role="$2"
  psql_stop "$db" <<SQL
SET ROLE ${role};
DO \$sel\$
DECLARE
  expected jsonb := jsonb_build_object(
    'universities', 1,
    'admission_categories', 1,
    'admission_programs', 1,
    'admission_sections', 17,
    'admission_schedules', 15,
    'required_documents', 42,
    'document_submissions', 84,
    'required_document_choice_groups', 1,
    'required_document_choice_group_items', 2,
    'source_documents', 7,
    'source_citations', 33,
    'admission_program_sources', 6,
    'admission_section_citations', 24,
    'required_document_citations', 56,
    'document_submission_citations', 90,
    'admission_schedule_citations', 30
  );
  table_name text;
  actual integer;
  wanted integer;
BEGIN
  IF current_user IS DISTINCT FROM '${role}' THEN
    RAISE EXCEPTION 'expected current_user %, got %', '${role}', current_user;
  END IF;
  FOR table_name IN SELECT jsonb_object_keys(expected) LOOP
    EXECUTE format('SELECT count(*) FROM public.%I', table_name) INTO actual;
    wanted := (expected ->> table_name)::integer;
    IF actual IS DISTINCT FROM wanted THEN
      RAISE EXCEPTION
        '% SELECT count on public.% = % expected %',
        current_user, table_name, actual, wanted;
    END IF;
  END LOOP;
END
\$sel\$;
RESET ROLE;
SELECT current_user;
SQL
}

assert_write_denied() {
  local db="$1"
  local role="$2"
  psql_stop "$db" <<SQL
SET ROLE ${role};
DO \$deny\$
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
  col name;
  stmt text;
  op text;
  ops text[] := ARRAY['INSERT', 'UPDATE', 'DELETE'];
  denied_count integer := 0;
BEGIN
  IF current_user IS DISTINCT FROM '${role}' THEN
    RAISE EXCEPTION 'expected current_user %, got %', '${role}', current_user;
  END IF;

  FOREACH table_name IN ARRAY target_tables LOOP
    SELECT a.attname INTO col
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = table_name
      AND a.attnum > 0
      AND NOT a.attisdropped
    ORDER BY a.attnum
    LIMIT 1;

    FOREACH op IN ARRAY ops LOOP
      IF op = 'INSERT' THEN
        stmt := format(
          'INSERT INTO public.%I SELECT * FROM public.%I WHERE false',
          table_name, table_name
        );
      ELSIF op = 'UPDATE' THEN
        stmt := format(
          'UPDATE public.%I SET %I = %I WHERE false',
          table_name, col, col
        );
      ELSE
        stmt := format('DELETE FROM public.%I WHERE false', table_name);
      END IF;

      BEGIN
        EXECUTE stmt;
        RAISE EXCEPTION
          '% % on public.% unexpectedly succeeded',
          current_user, op, table_name;
      EXCEPTION
        WHEN insufficient_privilege THEN
          denied_count := denied_count + 1;
          RAISE NOTICE
            '% % on public.% denied SQLSTATE=% (%)',
            current_user, op, table_name, SQLSTATE, SQLERRM;
          IF SQLSTATE IS DISTINCT FROM '42501' THEN
            RAISE EXCEPTION
              '% % on public.% denied but SQLSTATE=% expected 42501',
              current_user, op, table_name, SQLSTATE;
          END IF;
        WHEN OTHERS THEN
          RAISE EXCEPTION
            '% % on public.% failed with unexpected SQLSTATE=% MSG=%',
            current_user, op, table_name, SQLSTATE, SQLERRM;
      END;
    END LOOP;
  END LOOP;

  IF denied_count <> 48 THEN
    RAISE EXCEPTION '% write denials=% expected 48 (16 tables x INSERT/UPDATE/DELETE)', current_user, denied_count;
  END IF;
END
\$deny\$;
RESET ROLE;
SQL
}

assert_owner_harmless_write() {
  local db="$1"
  psql_stop "$db" <<'SQL'
SELECT current_user;
BEGIN;
UPDATE public.universities
SET name_ko = name_ko
WHERE false;
ROLLBACK;
SELECT count(*) AS universities_after_owner_probe FROM public.universities;
SQL
  local n
  n="$(psql_stop "$db" -Atc 'SELECT count(*) FROM public.universities;')"
  if [ "$n" != "1" ]; then
    echo "owner write probe changed universities count to ${n}"
    exit 1
  fi
}

assert_rollback_restored() {
  local db="$1"
  psql_stop "$db" <<'SQL'
DO $rb$
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
  rls_enabled boolean;
  rls_on integer := 0;
  policy_count integer;
  policies integer := 0;
  role_name name;
  priv text;
  privs text[] := ARRAY[
    'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER'
  ];
BEGIN
  FOREACH table_name IN ARRAY target_tables LOOP
    SELECT c.relrowsecurity
    INTO rls_enabled
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name AND c.relkind = 'r';
    IF rls_enabled THEN
      rls_on := rls_on + 1;
    END IF;

    SELECT count(*)
    INTO policy_count
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = table_name;
    policies := policies + policy_count;

    FOREACH role_name IN ARRAY ARRAY['anon', 'authenticated']::name[] LOOP
      FOREACH priv IN ARRAY privs LOOP
        IF has_table_privilege(role_name, format('public.%I', table_name), priv) IS NOT TRUE THEN
          RAISE EXCEPTION
            'rollback probe: role % lost % on public.%', role_name, priv, table_name;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  IF rls_on <> 0 THEN
    RAISE EXCEPTION 'rollback probe: RLS enabled count=% expected 0', rls_on;
  END IF;
  IF policies <> 0 THEN
    RAISE EXCEPTION 'rollback probe: policy count=% expected 0', policies;
  END IF;
END
$rb$;
SQL
}

echo "=== create hosted-like roles (cluster) ==="
create_hosted_like_roles
echo "hosted-like roles fixture PASS"

echo "=== create disposable databases A/B/C ==="
psql_stop postgres -c "CREATE DATABASE rls_scenario_a;"
psql_stop postgres -c "CREATE DATABASE rls_rollback_b;"
psql_stop postgres -c "CREATE DATABASE rls_scenario_c;"

echo "========== Scenario A: initial schema → KU data → RLS =========="
apply_schema rls_scenario_a
echo "A: initial schema apply PASS"
apply_hosted_like_grants rls_scenario_a
echo "A: hosted-like privilege fixture PASS"
assert_pre_rls rls_scenario_a
echo "A: pre-RLS assertions PASS"
psql_stop rls_scenario_a -f "$KU_FILE"
echo "A: KU migration apply PASS"
assert_ku_baseline rls_scenario_a
echo "A: KU baseline counts PASS"
snapshot_ku_counts rls_scenario_a /tmp/rls_a_counts_before_rls.txt
echo "A: KU snapshot before RLS written"

psql_stop rls_scenario_a -f "$RLS_FILE"
echo "A: public-read RLS clean apply PASS"

assert_rls_postconditions rls_scenario_a
echo "A: RLS catalog + privilege matrix PASS"
assert_actual_select rls_scenario_a anon
echo "A: anon actual SELECT PASS"
assert_actual_select rls_scenario_a authenticated
echo "A: authenticated actual SELECT PASS"
assert_write_denied rls_scenario_a anon
echo "A: anon INSERT/UPDATE/DELETE denial PASS (SQLSTATE 42501)"
assert_write_denied rls_scenario_a authenticated
echo "A: authenticated INSERT/UPDATE/DELETE denial PASS (SQLSTATE 42501)"
echo "A: write denial is from the final DB access-control configuration (privilege deny + no write RLS policy). Do not attribute the INSERT error solely to RLS."
assert_owner_harmless_write rls_scenario_a
echo "A: postgres/owner harmless write PASS"
assert_ku_baseline rls_scenario_a
snapshot_ku_counts rls_scenario_a /tmp/rls_a_counts_after_rls.txt
if ! cmp -s /tmp/rls_a_counts_before_rls.txt /tmp/rls_a_counts_after_rls.txt; then
  echo "KU counts changed after RLS apply"
  echo "BEFORE:"; cat /tmp/rls_a_counts_before_rls.txt
  echo "AFTER:"; cat /tmp/rls_a_counts_after_rls.txt
  exit 1
fi
echo "A: KU data preservation PASS"

echo "=== Scenario A second-run fail-fast ==="
set +e
second_out="$(psql -d rls_scenario_a -v ON_ERROR_STOP=1 -f "$RLS_FILE" 2>&1)"
second_rc=$?
set -e
echo "$second_out"
if [ "$second_rc" -eq 0 ]; then
  echo "Second-run unexpectedly succeeded"
  exit 1
fi
if ! grep -Eq "already has RLS enabled|already has .+ policy" <<<"$second_out"; then
  echo "Second-run failed, but not with preflight RLS/policy message"
  exit 1
fi
echo "A: second-run fail-fast PASS (exit ${second_rc})"

assert_rls_postconditions rls_scenario_a
assert_actual_select rls_scenario_a anon
assert_write_denied rls_scenario_a anon
assert_ku_baseline rls_scenario_a
snapshot_ku_counts rls_scenario_a /tmp/rls_a_counts_after_second.txt
if ! cmp -s /tmp/rls_a_counts_after_rls.txt /tmp/rls_a_counts_after_second.txt; then
  echo "KU counts changed after expected-failure second-run"
  exit 1
fi
echo "A: second-run no state change PASS"

echo "========== Scenario B/DB B: explicit transaction rollback probe =========="
apply_schema rls_rollback_b
apply_hosted_like_grants rls_rollback_b
assert_pre_rls rls_rollback_b
echo "B: pre-RLS fixture PASS"
psql_stop rls_rollback_b <<SQL
BEGIN;
\i ${RLS_FILE}
ROLLBACK;
SQL
assert_rollback_restored rls_rollback_b
echo "B: PostgreSQL explicit-transaction rollback probe PASS"
echo "B: This proves PostgreSQL explicit transaction behavior only. It does not prove Supabase CLI migration transaction semantics."

echo "========== Scenario C: initial schema → RLS → KU data =========="
apply_schema rls_scenario_c
apply_hosted_like_grants rls_scenario_c
assert_pre_rls rls_scenario_c
psql_stop rls_scenario_c -f "$RLS_FILE"
echo "C: RLS-first apply PASS"
assert_rls_postconditions rls_scenario_c
psql_stop rls_scenario_c <<'SQL'
SET ROLE anon;
SELECT count(*) AS universities_before_data FROM public.universities;
RESET ROLE;
SET ROLE authenticated;
SELECT count(*) AS universities_before_data FROM public.universities;
RESET ROLE;
SQL
echo "C: RLS/read-only state before data PASS (anon/authenticated SELECT allowed on empty tables)"
psql_stop rls_scenario_c -f "$KU_FILE"
echo "C: KU data migration after RLS PASS"
assert_ku_baseline rls_scenario_c
echo "C: KU-after-RLS counts PASS"
assert_rls_postconditions rls_scenario_c
assert_actual_select rls_scenario_c anon
assert_actual_select rls_scenario_c authenticated
assert_write_denied rls_scenario_c anon
assert_write_denied rls_scenario_c authenticated
echo "C: anon/authenticated SELECT succeeds and write denied PASS"
echo "C: PostgreSQL owner/BYPASSRLS-capable path can load verified data after RLS."
echo "C: actual hosted CLI deploy compatibility is NOT PROVEN."

echo "========== ALL RUNTIME SCENARIOS PASS =========="
