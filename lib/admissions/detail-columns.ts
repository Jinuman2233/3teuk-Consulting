/** Exact table/column lists from 20260825155343_initial_schema.sql */

export const ADMISSION_CATEGORIES_TABLE = "admission_categories";
export const ADMISSION_SECTIONS_TABLE = "admission_sections";
export const ADMISSION_SCHEDULES_TABLE = "admission_schedules";
export const REQUIRED_DOCUMENTS_TABLE = "required_documents";
export const DOCUMENT_SUBMISSIONS_TABLE = "document_submissions";
export const REQUIRED_DOCUMENT_CHOICE_GROUPS_TABLE =
  "required_document_choice_groups";
export const REQUIRED_DOCUMENT_CHOICE_GROUP_ITEMS_TABLE =
  "required_document_choice_group_items";
export const SOURCE_DOCUMENTS_TABLE = "source_documents";
export const SOURCE_CITATIONS_TABLE = "source_citations";
export const ADMISSION_PROGRAM_SOURCES_TABLE = "admission_program_sources";
export const ADMISSION_SECTION_CITATIONS_TABLE = "admission_section_citations";
export const REQUIRED_DOCUMENT_CITATIONS_TABLE = "required_document_citations";
export const DOCUMENT_SUBMISSION_CITATIONS_TABLE =
  "document_submission_citations";
export const ADMISSION_SCHEDULE_CITATIONS_TABLE = "admission_schedule_citations";

export const ADMISSION_CATEGORY_COLUMNS =
  "id, code, label, description, created_at, updated_at";

export const ADMISSION_SECTION_COLUMNS =
  "id, admission_program_id, section_type, title, content, applicability_text, information_type, availability_status, verification_status, verified_at, display_order, created_at, updated_at";

export const ADMISSION_SCHEDULE_COLUMNS =
  "id, admission_program_id, event_name, temporal_precision, start_date, end_date, start_at, end_at, timezone, location_text, description, verification_status, verified_at, display_order, created_at, updated_at";

export const REQUIRED_DOCUMENT_COLUMNS =
  "id, admission_program_id, name, description, requirement_status, condition, document_subject_text, display_order, verification_status, verified_at, created_at, updated_at";

export const DOCUMENT_SUBMISSION_COLUMNS =
  "id, required_document_id, admission_program_id, submission_phase, submission_method, submission_format, admission_schedule_id, instructions, display_order, verification_status, verified_at, created_at, updated_at";

export const REQUIRED_DOCUMENT_CHOICE_GROUP_COLUMNS =
  "id, admission_program_id, title, rule_text, condition, display_order, verification_status, verified_at, created_at, updated_at";

export const REQUIRED_DOCUMENT_CHOICE_GROUP_ITEM_COLUMNS =
  "choice_group_id, required_document_id, admission_program_id";

export const ADMISSION_PROGRAM_SOURCE_COLUMNS =
  "admission_program_id, source_document_id, source_role, display_order, notes, created_at";

export const SOURCE_CITATION_COLUMNS =
  "id, source_document_id, file_page_number, printed_page_label, section, anchor_description, verified_at, created_at";

/** Provenance fields needed for citation → source lookup. Does not follow supersedes. */
export const SOURCE_DOCUMENT_SUMMARY_COLUMNS =
  "id, university_id, academic_year, source_type, title, issuing_organization, source_url, published_at, last_checked_at, document_version_label, supersedes_source_document_id, notes";

export const ADMISSION_SECTION_CITATION_COLUMNS =
  "admission_section_id, source_citation_id";

export const REQUIRED_DOCUMENT_CITATION_COLUMNS =
  "required_document_id, source_citation_id";

export const DOCUMENT_SUBMISSION_CITATION_COLUMNS =
  "document_submission_id, source_citation_id";

export const ADMISSION_SCHEDULE_CITATION_COLUMNS =
  "admission_schedule_id, source_citation_id";
