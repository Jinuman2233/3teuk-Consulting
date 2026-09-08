import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import {
  ADMISSION_PROGRAM_COLUMNS,
  ADMISSION_PROGRAMS_TABLE,
  UNIVERSITIES_TABLE,
  UNIVERSITY_COLUMNS,
} from "./columns";
import {
  getClient,
  requireAcademicYear,
  requireNonEmptyString,
  requireUniversityId,
  throwIfQueryError,
} from "./query";
import type {
  AdmissionProgramDetail,
  AdmissionProgramRow,
  UniversityRow,
} from "./types";

export async function getUniversities(
  client?: SupabaseClient,
): Promise<UniversityRow[]> {
  const supabase = getClient(client);
  const { data, error } = await supabase
    .from(UNIVERSITIES_TABLE)
    .select(UNIVERSITY_COLUMNS)
    .order("name_ko", { ascending: true })
    .order("campus_name", { ascending: true })
    .order("slug", { ascending: true });

  throwIfQueryError(error, `select ${UNIVERSITIES_TABLE}`);
  return (data ?? []) as UniversityRow[];
}

export async function getUniversityBySlug(
  slug: string,
  client?: SupabaseClient,
): Promise<UniversityRow | null> {
  const supabase = getClient(client);
  const lookup = requireNonEmptyString(slug, "slug");
  const { data, error } = await supabase
    .from(UNIVERSITIES_TABLE)
    .select(UNIVERSITY_COLUMNS)
    .eq("slug", lookup)
    .maybeSingle();

  throwIfQueryError(error, `select ${UNIVERSITIES_TABLE} by slug`);
  return (data as UniversityRow | null) ?? null;
}

export async function getAdmissionProgramsByUniversity(
  universityId: string,
  academicYear?: number,
  client?: SupabaseClient,
): Promise<AdmissionProgramRow[]> {
  const supabase = getClient(client);
  const id = requireUniversityId(universityId);

  let query = supabase
    .from(ADMISSION_PROGRAMS_TABLE)
    .select(ADMISSION_PROGRAM_COLUMNS)
    .eq("university_id", id);

  if (academicYear !== undefined) {
    query = query.eq("academic_year", requireAcademicYear(academicYear));
  }

  const { data, error } = await query
    .order("academic_year", { ascending: false })
    .order("admission_slug", { ascending: true });

  throwIfQueryError(error, `select ${ADMISSION_PROGRAMS_TABLE}`);
  return (data ?? []) as AdmissionProgramRow[];
}

/**
 * Route lookup for university slug + academic year + admission slug.
 *
 * Loads `universities` and `admission_programs` only.
 * Does not load sections, documents, schedules, citations, or sources.
 * Does not mix academic years: year is an exact filter, never a default.
 */
export async function getAdmissionProgramDetail(
  universitySlug: string,
  academicYear: number,
  admissionSlug: string,
  client?: SupabaseClient,
): Promise<AdmissionProgramDetail | null> {
  const supabase = getClient(client);
  const year = requireAcademicYear(academicYear);
  const programSlug = requireNonEmptyString(admissionSlug, "admissionSlug");

  const university = await getUniversityBySlug(universitySlug, supabase);
  if (!university) {
    return null;
  }

  const { data, error } = await supabase
    .from(ADMISSION_PROGRAMS_TABLE)
    .select(ADMISSION_PROGRAM_COLUMNS)
    .eq("university_id", university.id)
    .eq("academic_year", year)
    .eq("admission_slug", programSlug)
    .maybeSingle();

  throwIfQueryError(error, `select ${ADMISSION_PROGRAMS_TABLE} detail`);
  if (!data) {
    return null;
  }

  return {
    university,
    program: data as AdmissionProgramRow,
  };
}
