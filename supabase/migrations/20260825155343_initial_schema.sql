-- Initial core schema for 3teuk-Consulting admissions data.
-- Validated against KU + Yonsei 2027 schema validations and
-- docs/DB_SCHEMA_DRAFT.md / docs/DATA_MODEL.md.
--
-- This migration creates structure only.
-- No seed/production admissions data.
-- No RLS / auth policies.
-- Deferred tables intentionally omitted:
--   eligibility_rules, faqs, parent_stories,
--   campuses, admission_tracks, evaluation children,
--   source_conflicts, source URL alias tables.
--
-- Cross-program integrity is enforced declaratively, without triggers:
-- document_submissions and required_document_choice_group_items carry a
-- denormalized admission_program_id and reference their parents through
-- composite FKs, so a submission cannot point at another program's schedule
-- and a choice group cannot bundle another program's documents.
-- The cost is three redundant UNIQUE (id, admission_program_id) constraints
-- on the parent tables.
--
-- Requires PostgreSQL 15+ for ON DELETE SET NULL (column_list).

-- ---------------------------------------------------------------------------
-- Updated-at helper
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
BEGIN
  NEW.updated_at = pg_catalog.now();
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Universities
-- ---------------------------------------------------------------------------

CREATE TABLE public.universities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name_ko text NOT NULL,
  name_en text,
  campus_name text,
  display_name text NOT NULL,
  slug text NOT NULL,
  official_website_url text,
  admissions_office_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT universities_slug_key UNIQUE (slug)
);

CREATE TRIGGER universities_set_updated_at
BEFORE UPDATE ON public.universities
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Admission categories
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL,
  label text NOT NULL,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admission_categories_code_key UNIQUE (code)
);

CREATE TRIGGER admission_categories_set_updated_at
BEFORE UPDATE ON public.admission_categories
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Admission programs
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_programs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid NOT NULL,
  admission_category_id uuid,
  academic_year integer NOT NULL,
  official_program_name text NOT NULL,
  display_name text NOT NULL,
  admission_slug text NOT NULL,
  information_type text NOT NULL,
  verification_status text NOT NULL,
  verified_at timestamptz,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admission_programs_university_id_fkey
    FOREIGN KEY (university_id)
    REFERENCES public.universities (id)
    ON DELETE RESTRICT,
  CONSTRAINT admission_programs_admission_category_id_fkey
    FOREIGN KEY (admission_category_id)
    REFERENCES public.admission_categories (id)
    ON DELETE SET NULL,
  CONSTRAINT admission_programs_routing_key
    UNIQUE (university_id, academic_year, admission_slug),
  CONSTRAINT admission_programs_information_type_check
    CHECK (
      information_type IN (
        'official_fact',
        'interpretation',
        'strategic_opinion',
        'parent_experience',
        'unverified'
      )
    ),
  CONSTRAINT admission_programs_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    )
);

CREATE TRIGGER admission_programs_set_updated_at
BEFORE UPDATE ON public.admission_programs
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Admission sections
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_sections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admission_program_id uuid NOT NULL,
  section_type text NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  applicability_text text,
  information_type text NOT NULL,
  availability_status text NOT NULL,
  verification_status text NOT NULL,
  verified_at timestamptz,
  display_order integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admission_sections_admission_program_id_fkey
    FOREIGN KEY (admission_program_id)
    REFERENCES public.admission_programs (id)
    ON DELETE CASCADE,
  CONSTRAINT admission_sections_information_type_check
    CHECK (
      information_type IN (
        'official_fact',
        'interpretation',
        'strategic_opinion',
        'parent_experience',
        'unverified'
      )
    ),
  CONSTRAINT admission_sections_availability_status_check
    CHECK (
      availability_status IN (
        'available',
        'not_found_in_official_source',
        'not_applicable',
        'unknown',
        'needs_confirmation'
      )
    ),
  CONSTRAINT admission_sections_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    )
  -- Intentionally no UNIQUE(admission_program_id, section_type):
  -- same section_type may appear multiple times per program.
);

CREATE TRIGGER admission_sections_set_updated_at
BEFORE UPDATE ON public.admission_sections
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Admission schedules
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_schedules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admission_program_id uuid NOT NULL,
  event_name text NOT NULL,
  temporal_precision text NOT NULL,
  start_date date,
  end_date date,
  start_at timestamptz,
  end_at timestamptz,
  timezone text,
  location_text text,
  description text,
  verification_status text NOT NULL,
  verified_at timestamptz,
  display_order integer NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admission_schedules_admission_program_id_fkey
    FOREIGN KEY (admission_program_id)
    REFERENCES public.admission_programs (id)
    ON DELETE CASCADE,
  CONSTRAINT admission_schedules_temporal_precision_check
    CHECK (temporal_precision IN ('date', 'datetime')),
  CONSTRAINT admission_schedules_temporal_fields_check
    CHECK (
      (
        temporal_precision = 'date'
        AND start_at IS NULL
        AND end_at IS NULL
        AND (start_date IS NOT NULL OR end_date IS NOT NULL)
        AND (
          start_date IS NULL
          OR end_date IS NULL
          OR start_date <= end_date
        )
      )
      OR
      (
        temporal_precision = 'datetime'
        AND start_date IS NULL
        AND end_date IS NULL
        AND (start_at IS NOT NULL OR end_at IS NOT NULL)
        AND (
          start_at IS NULL
          OR end_at IS NULL
          OR start_at <= end_at
        )
      )
    ),
  CONSTRAINT admission_schedules_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    ),
  -- Redundant on its own (id is already unique), but required as the
  -- target of composite FKs that keep child rows inside one program.
  CONSTRAINT admission_schedules_id_program_key
    UNIQUE (id, admission_program_id)
);

CREATE TRIGGER admission_schedules_set_updated_at
BEFORE UPDATE ON public.admission_schedules
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Documents
-- ---------------------------------------------------------------------------

CREATE TABLE public.required_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admission_program_id uuid NOT NULL,
  name text NOT NULL,
  description text,
  requirement_status text NOT NULL,
  condition text,
  document_subject_text text,
  display_order integer NOT NULL,
  verification_status text NOT NULL,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT required_documents_admission_program_id_fkey
    FOREIGN KEY (admission_program_id)
    REFERENCES public.admission_programs (id)
    ON DELETE CASCADE,
  CONSTRAINT required_documents_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    ),
  -- Redundant on its own (id is already unique), but required as the
  -- target of composite FKs that keep child rows inside one program.
  CONSTRAINT required_documents_id_program_key
    UNIQUE (id, admission_program_id)
  -- requirement_status vocabulary intentionally unchecked until
  -- additional university data patterns are confirmed.
);

CREATE TRIGGER required_documents_set_updated_at
BEFORE UPDATE ON public.required_documents
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

CREATE TABLE public.document_submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  required_document_id uuid NOT NULL,
  -- Denormalized program scope. Not a second source of truth: composite FKs
  -- below force it to match both the parent document and the linked schedule.
  admission_program_id uuid NOT NULL,
  submission_phase text NOT NULL,
  submission_method text,
  submission_format text,
  admission_schedule_id uuid,
  instructions text,
  display_order integer NOT NULL,
  verification_status text NOT NULL,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT document_submissions_required_document_id_fkey
    FOREIGN KEY (required_document_id, admission_program_id)
    REFERENCES public.required_documents (id, admission_program_id)
    ON DELETE CASCADE,
  -- MATCH SIMPLE: skipped entirely while admission_schedule_id IS NULL,
  -- so an unscheduled submission stays valid.
  CONSTRAINT document_submissions_admission_schedule_id_fkey
    FOREIGN KEY (admission_schedule_id, admission_program_id)
    REFERENCES public.admission_schedules (id, admission_program_id)
    ON DELETE SET NULL (admission_schedule_id),
  CONSTRAINT document_submissions_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    )
  -- submission_phase / submission_method / submission_format
  -- vocabulary intentionally unchecked until more universities are mapped.
);

CREATE TRIGGER document_submissions_set_updated_at
BEFORE UPDATE ON public.document_submissions
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

CREATE TABLE public.required_document_choice_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admission_program_id uuid NOT NULL,
  title text,
  rule_text text NOT NULL,
  condition text,
  display_order integer NOT NULL,
  verification_status text NOT NULL,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT required_document_choice_groups_admission_program_id_fkey
    FOREIGN KEY (admission_program_id)
    REFERENCES public.admission_programs (id)
    ON DELETE CASCADE,
  CONSTRAINT required_document_choice_groups_verification_status_check
    CHECK (
      verification_status IN (
        'verified',
        'partially_verified',
        'needs_review',
        'unverified'
      )
    ),
  -- Redundant on its own (id is already unique), but required as the
  -- target of composite FKs that keep child rows inside one program.
  CONSTRAINT required_document_choice_groups_id_program_key
    UNIQUE (id, admission_program_id)
);

CREATE TRIGGER required_document_choice_groups_set_updated_at
BEFORE UPDATE ON public.required_document_choice_groups
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

CREATE TABLE public.required_document_choice_group_items (
  choice_group_id uuid NOT NULL,
  required_document_id uuid NOT NULL,
  -- Denormalized program scope. Not a second source of truth: composite FKs
  -- below force group and document to sit in the same admission_program.
  admission_program_id uuid NOT NULL,
  PRIMARY KEY (choice_group_id, required_document_id),
  CONSTRAINT required_document_choice_group_items_choice_group_id_fkey
    FOREIGN KEY (choice_group_id, admission_program_id)
    REFERENCES public.required_document_choice_groups (id, admission_program_id)
    ON DELETE CASCADE,
  CONSTRAINT required_document_choice_group_items_required_document_id_fkey
    FOREIGN KEY (required_document_id, admission_program_id)
    REFERENCES public.required_documents (id, admission_program_id)
    ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- Sources
-- ---------------------------------------------------------------------------

CREATE TABLE public.source_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  university_id uuid,
  academic_year integer,
  source_type text NOT NULL,
  title text NOT NULL,
  issuing_organization text NOT NULL,
  source_url text NOT NULL,
  -- published_at is date (not timestamptz) to avoid inventing 00:00 when
  -- official publish timing is date-only. Trade-off: exact publish times,
  -- if ever needed, are not stored in this column.
  published_at date,
  last_checked_at timestamptz NOT NULL,
  document_version_label text,
  supersedes_source_document_id uuid,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT source_documents_university_id_fkey
    FOREIGN KEY (university_id)
    REFERENCES public.universities (id)
    ON DELETE RESTRICT,
  CONSTRAINT source_documents_supersedes_source_document_id_fkey
    FOREIGN KEY (supersedes_source_document_id)
    REFERENCES public.source_documents (id)
    ON DELETE RESTRICT,
  CONSTRAINT source_documents_no_self_supersede_check
    CHECK (
      supersedes_source_document_id IS NULL
      OR supersedes_source_document_id <> id
    )
  -- source_url intentionally not UNIQUE (revision / access-surface cases).
  -- Long cycle prevention for revision lineage is deferred to
  -- data validation / application logic, not this migration.
);

CREATE TRIGGER source_documents_set_updated_at
BEFORE UPDATE ON public.source_documents
FOR EACH ROW
EXECUTE PROCEDURE public.set_updated_at();

CREATE TABLE public.source_citations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_document_id uuid NOT NULL,
  file_page_number integer,
  printed_page_label text,
  section text,
  anchor_description text,
  verified_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT source_citations_source_document_id_fkey
    FOREIGN KEY (source_document_id)
    REFERENCES public.source_documents (id)
    ON DELETE RESTRICT,
  CONSTRAINT source_citations_file_page_number_check
    CHECK (
      file_page_number IS NULL
      OR file_page_number >= 1
    )
);

-- ---------------------------------------------------------------------------
-- Program ↔ source relation
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_program_sources (
  admission_program_id uuid NOT NULL,
  source_document_id uuid NOT NULL,
  source_role text,
  display_order integer,
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (admission_program_id, source_document_id),
  CONSTRAINT admission_program_sources_admission_program_id_fkey
    FOREIGN KEY (admission_program_id)
    REFERENCES public.admission_programs (id)
    ON DELETE CASCADE,
  CONSTRAINT admission_program_sources_source_document_id_fkey
    FOREIGN KEY (source_document_id)
    REFERENCES public.source_documents (id)
    ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------------
-- Citation relations
-- ---------------------------------------------------------------------------

CREATE TABLE public.admission_section_citations (
  admission_section_id uuid NOT NULL,
  source_citation_id uuid NOT NULL,
  PRIMARY KEY (admission_section_id, source_citation_id),
  CONSTRAINT admission_section_citations_admission_section_id_fkey
    FOREIGN KEY (admission_section_id)
    REFERENCES public.admission_sections (id)
    ON DELETE CASCADE,
  CONSTRAINT admission_section_citations_source_citation_id_fkey
    FOREIGN KEY (source_citation_id)
    REFERENCES public.source_citations (id)
    ON DELETE RESTRICT
);

CREATE TABLE public.required_document_citations (
  required_document_id uuid NOT NULL,
  source_citation_id uuid NOT NULL,
  PRIMARY KEY (required_document_id, source_citation_id),
  CONSTRAINT required_document_citations_required_document_id_fkey
    FOREIGN KEY (required_document_id)
    REFERENCES public.required_documents (id)
    ON DELETE CASCADE,
  CONSTRAINT required_document_citations_source_citation_id_fkey
    FOREIGN KEY (source_citation_id)
    REFERENCES public.source_citations (id)
    ON DELETE RESTRICT
);

CREATE TABLE public.document_submission_citations (
  document_submission_id uuid NOT NULL,
  source_citation_id uuid NOT NULL,
  PRIMARY KEY (document_submission_id, source_citation_id),
  CONSTRAINT document_submission_citations_document_submission_id_fkey
    FOREIGN KEY (document_submission_id)
    REFERENCES public.document_submissions (id)
    ON DELETE CASCADE,
  CONSTRAINT document_submission_citations_source_citation_id_fkey
    FOREIGN KEY (source_citation_id)
    REFERENCES public.source_citations (id)
    ON DELETE RESTRICT
);

CREATE TABLE public.admission_schedule_citations (
  admission_schedule_id uuid NOT NULL,
  source_citation_id uuid NOT NULL,
  PRIMARY KEY (admission_schedule_id, source_citation_id),
  CONSTRAINT admission_schedule_citations_admission_schedule_id_fkey
    FOREIGN KEY (admission_schedule_id)
    REFERENCES public.admission_schedules (id)
    ON DELETE CASCADE,
  CONSTRAINT admission_schedule_citations_source_citation_id_fkey
    FOREIGN KEY (source_citation_id)
    REFERENCES public.source_citations (id)
    ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

-- admission_programs.routing UNIQUE already prefixes university_id.
CREATE INDEX admission_programs_academic_year_idx
  ON public.admission_programs (academic_year);

CREATE INDEX admission_programs_admission_category_id_idx
  ON public.admission_programs (admission_category_id);

CREATE INDEX admission_sections_program_section_type_idx
  ON public.admission_sections (admission_program_id, section_type);

CREATE INDEX required_documents_admission_program_id_idx
  ON public.required_documents (admission_program_id);

CREATE INDEX document_submissions_required_document_program_idx
  ON public.document_submissions (required_document_id, admission_program_id);

CREATE INDEX document_submissions_admission_schedule_program_idx
  ON public.document_submissions (admission_schedule_id, admission_program_id);

CREATE INDEX required_document_choice_groups_admission_program_id_idx
  ON public.required_document_choice_groups (admission_program_id);

CREATE INDEX required_document_choice_group_items_required_document_program_idx
  ON public.required_document_choice_group_items (required_document_id, admission_program_id);

CREATE INDEX required_document_choice_group_items_choice_group_program_idx
  ON public.required_document_choice_group_items (choice_group_id, admission_program_id);

CREATE INDEX admission_schedules_admission_program_id_idx
  ON public.admission_schedules (admission_program_id);

CREATE INDEX source_documents_university_id_idx
  ON public.source_documents (university_id);

CREATE INDEX source_documents_academic_year_idx
  ON public.source_documents (academic_year);

CREATE INDEX source_documents_supersedes_source_document_id_idx
  ON public.source_documents (supersedes_source_document_id);

CREATE INDEX source_citations_source_document_id_idx
  ON public.source_citations (source_document_id);

CREATE INDEX admission_program_sources_source_document_id_idx
  ON public.admission_program_sources (source_document_id);

CREATE INDEX admission_section_citations_source_citation_id_idx
  ON public.admission_section_citations (source_citation_id);

CREATE INDEX required_document_citations_source_citation_id_idx
  ON public.required_document_citations (source_citation_id);

CREATE INDEX document_submission_citations_source_citation_id_idx
  ON public.document_submission_citations (source_citation_id);

CREATE INDEX admission_schedule_citations_source_citation_id_idx
  ON public.admission_schedule_citations (source_citation_id);
