export const UNIVERSITIES_TABLE = "universities";
export const ADMISSION_PROGRAMS_TABLE = "admission_programs";

/** Exact universities columns from 20260825155343_initial_schema.sql */
export const UNIVERSITY_COLUMNS =
  "id, name_ko, name_en, campus_name, display_name, slug, official_website_url, admissions_office_url, created_at, updated_at";

/** Exact admission_programs columns from 20260825155343_initial_schema.sql */
export const ADMISSION_PROGRAM_COLUMNS =
  "id, university_id, admission_category_id, academic_year, official_program_name, display_name, admission_slug, information_type, verification_status, verified_at, notes, created_at, updated_at";
