/**
 * Hand-written row DTOs matching columns in
 * supabase/migrations/20260825155343_initial_schema.sql.
 *
 * This repo does not yet have generated Supabase Database types.
 * When codegen is added (`supabase gen types typescript`), replace these
 * with the generated Row types instead of maintaining a parallel model.
 *
 * Values are returned as stored. Do not treat display helpers as official facts.
 */

export type InformationType =
  | "official_fact"
  | "interpretation"
  | "strategic_opinion"
  | "parent_experience"
  | "unverified";

export type VerificationStatus =
  | "verified"
  | "partially_verified"
  | "needs_review"
  | "unverified";

export type UniversityRow = {
  id: string;
  name_ko: string;
  name_en: string | null;
  campus_name: string | null;
  display_name: string;
  slug: string;
  official_website_url: string | null;
  admissions_office_url: string | null;
  created_at: string;
  updated_at: string;
};

export type AdmissionProgramRow = {
  id: string;
  university_id: string;
  admission_category_id: string | null;
  academic_year: number;
  official_program_name: string;
  display_name: string;
  admission_slug: string;
  information_type: InformationType;
  verification_status: VerificationStatus;
  verified_at: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
};

/**
 * Route lookup result for SITE_MAP
 * `/universities/[slug]/admissions/[academicYear]/[admissionSlug]`.
 *
 * This is two table rows composed for routing, not a nested program graph.
 * Child tables (sections, documents, schedules, sources) are not loaded here.
 */
export type AdmissionProgramDetail = {
  university: UniversityRow;
  program: AdmissionProgramRow;
};
