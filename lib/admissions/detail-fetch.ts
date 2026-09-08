import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import {
  ADMISSION_CATEGORIES_TABLE,
  ADMISSION_CATEGORY_COLUMNS,
  ADMISSION_PROGRAM_SOURCE_COLUMNS,
  ADMISSION_PROGRAM_SOURCES_TABLE,
  ADMISSION_SCHEDULE_CITATION_COLUMNS,
  ADMISSION_SCHEDULE_CITATIONS_TABLE,
  ADMISSION_SCHEDULE_COLUMNS,
  ADMISSION_SCHEDULES_TABLE,
  ADMISSION_SECTION_CITATION_COLUMNS,
  ADMISSION_SECTION_CITATIONS_TABLE,
  ADMISSION_SECTION_COLUMNS,
  ADMISSION_SECTIONS_TABLE,
  DOCUMENT_SUBMISSION_CITATION_COLUMNS,
  DOCUMENT_SUBMISSION_CITATIONS_TABLE,
  DOCUMENT_SUBMISSION_COLUMNS,
  DOCUMENT_SUBMISSIONS_TABLE,
  REQUIRED_DOCUMENT_CHOICE_GROUP_COLUMNS,
  REQUIRED_DOCUMENT_CHOICE_GROUP_ITEM_COLUMNS,
  REQUIRED_DOCUMENT_CHOICE_GROUP_ITEMS_TABLE,
  REQUIRED_DOCUMENT_CHOICE_GROUPS_TABLE,
  REQUIRED_DOCUMENT_CITATION_COLUMNS,
  REQUIRED_DOCUMENT_CITATIONS_TABLE,
  REQUIRED_DOCUMENT_COLUMNS,
  REQUIRED_DOCUMENTS_TABLE,
  SOURCE_CITATION_COLUMNS,
  SOURCE_CITATIONS_TABLE,
  SOURCE_DOCUMENT_SUMMARY_COLUMNS,
  SOURCE_DOCUMENTS_TABLE,
} from "./detail-columns";
import type {
  AdmissionCategoryRow,
  AdmissionProgramSourceRow,
  AdmissionScheduleCitationRow,
  AdmissionScheduleRow,
  AdmissionSectionCitationRow,
  AdmissionSectionRow,
  DocumentSubmissionCitationRow,
  DocumentSubmissionRow,
  RequiredDocumentChoiceGroupItemRow,
  RequiredDocumentChoiceGroupRow,
  RequiredDocumentCitationRow,
  RequiredDocumentRow,
  SourceCitationRow,
  SourceDocumentSummary,
} from "./detail-types";
import { throwIfQueryError, uniqueIds } from "./query";

async function selectByIds<T>(
  client: SupabaseClient,
  table: string,
  columns: string,
  column: string,
  ids: readonly string[],
  context: string,
): Promise<T[]> {
  const unique = uniqueIds(ids);
  if (unique.length === 0) {
    return [];
  }

  const { data, error } = await client
    .from(table)
    .select(columns)
    .in(column, unique);

  throwIfQueryError(error, context);
  return (data ?? []) as T[];
}

export async function fetchAdmissionCategory(
  client: SupabaseClient,
  categoryId: string,
): Promise<AdmissionCategoryRow | null> {
  const { data, error } = await client
    .from(ADMISSION_CATEGORIES_TABLE)
    .select(ADMISSION_CATEGORY_COLUMNS)
    .eq("id", categoryId)
    .maybeSingle();

  throwIfQueryError(error, `select ${ADMISSION_CATEGORIES_TABLE} by id`);
  return (data as AdmissionCategoryRow | null) ?? null;
}

export async function fetchProgramChildren(
  client: SupabaseClient,
  programId: string,
): Promise<{
  sections: AdmissionSectionRow[];
  schedules: AdmissionScheduleRow[];
  documents: RequiredDocumentRow[];
  choiceGroups: RequiredDocumentChoiceGroupRow[];
  programSources: AdmissionProgramSourceRow[];
}> {
  const [
    sectionsResult,
    schedulesResult,
    documentsResult,
    choiceGroupsResult,
    programSourcesResult,
  ] = await Promise.all([
    client
      .from(ADMISSION_SECTIONS_TABLE)
      .select(ADMISSION_SECTION_COLUMNS)
      .eq("admission_program_id", programId)
      .order("display_order", { ascending: true })
      .order("id", { ascending: true }),
    client
      .from(ADMISSION_SCHEDULES_TABLE)
      .select(ADMISSION_SCHEDULE_COLUMNS)
      .eq("admission_program_id", programId)
      .order("display_order", { ascending: true })
      .order("id", { ascending: true }),
    client
      .from(REQUIRED_DOCUMENTS_TABLE)
      .select(REQUIRED_DOCUMENT_COLUMNS)
      .eq("admission_program_id", programId)
      .order("display_order", { ascending: true })
      .order("id", { ascending: true }),
    client
      .from(REQUIRED_DOCUMENT_CHOICE_GROUPS_TABLE)
      .select(REQUIRED_DOCUMENT_CHOICE_GROUP_COLUMNS)
      .eq("admission_program_id", programId)
      .order("display_order", { ascending: true })
      .order("id", { ascending: true }),
    client
      .from(ADMISSION_PROGRAM_SOURCES_TABLE)
      .select(ADMISSION_PROGRAM_SOURCE_COLUMNS)
      .eq("admission_program_id", programId)
      .order("display_order", { ascending: true, nullsFirst: false })
      .order("source_document_id", { ascending: true }),
  ]);

  throwIfQueryError(
    sectionsResult.error,
    `select ${ADMISSION_SECTIONS_TABLE}`,
  );
  throwIfQueryError(
    schedulesResult.error,
    `select ${ADMISSION_SCHEDULES_TABLE}`,
  );
  throwIfQueryError(
    documentsResult.error,
    `select ${REQUIRED_DOCUMENTS_TABLE}`,
  );
  throwIfQueryError(
    choiceGroupsResult.error,
    `select ${REQUIRED_DOCUMENT_CHOICE_GROUPS_TABLE}`,
  );
  throwIfQueryError(
    programSourcesResult.error,
    `select ${ADMISSION_PROGRAM_SOURCES_TABLE}`,
  );

  return {
    sections: (sectionsResult.data ?? []) as AdmissionSectionRow[],
    schedules: (schedulesResult.data ?? []) as AdmissionScheduleRow[],
    documents: (documentsResult.data ?? []) as RequiredDocumentRow[],
    choiceGroups: (choiceGroupsResult.data ??
      []) as RequiredDocumentChoiceGroupRow[],
    programSources: (programSourcesResult.data ??
      []) as AdmissionProgramSourceRow[],
  };
}

export async function fetchDocumentChildren(
  client: SupabaseClient,
  documentIds: readonly string[],
  choiceGroupIds: readonly string[],
): Promise<{
  submissions: DocumentSubmissionRow[];
  choiceGroupItems: RequiredDocumentChoiceGroupItemRow[];
}> {
  const [submissions, choiceGroupItems] = await Promise.all([
    selectByIds<DocumentSubmissionRow>(
      client,
      DOCUMENT_SUBMISSIONS_TABLE,
      DOCUMENT_SUBMISSION_COLUMNS,
      "required_document_id",
      documentIds,
      `select ${DOCUMENT_SUBMISSIONS_TABLE}`,
    ),
    selectByIds<RequiredDocumentChoiceGroupItemRow>(
      client,
      REQUIRED_DOCUMENT_CHOICE_GROUP_ITEMS_TABLE,
      REQUIRED_DOCUMENT_CHOICE_GROUP_ITEM_COLUMNS,
      "choice_group_id",
      choiceGroupIds,
      `select ${REQUIRED_DOCUMENT_CHOICE_GROUP_ITEMS_TABLE}`,
    ),
  ]);

  return { submissions, choiceGroupItems };
}

export async function fetchCitationRelations(
  client: SupabaseClient,
  sectionIds: readonly string[],
  documentIds: readonly string[],
  submissionIds: readonly string[],
  scheduleIds: readonly string[],
): Promise<{
  sectionCitations: AdmissionSectionCitationRow[];
  documentCitations: RequiredDocumentCitationRow[];
  submissionCitations: DocumentSubmissionCitationRow[];
  scheduleCitations: AdmissionScheduleCitationRow[];
}> {
  const [
    sectionCitations,
    documentCitations,
    submissionCitations,
    scheduleCitations,
  ] = await Promise.all([
    selectByIds<AdmissionSectionCitationRow>(
      client,
      ADMISSION_SECTION_CITATIONS_TABLE,
      ADMISSION_SECTION_CITATION_COLUMNS,
      "admission_section_id",
      sectionIds,
      `select ${ADMISSION_SECTION_CITATIONS_TABLE}`,
    ),
    selectByIds<RequiredDocumentCitationRow>(
      client,
      REQUIRED_DOCUMENT_CITATIONS_TABLE,
      REQUIRED_DOCUMENT_CITATION_COLUMNS,
      "required_document_id",
      documentIds,
      `select ${REQUIRED_DOCUMENT_CITATIONS_TABLE}`,
    ),
    selectByIds<DocumentSubmissionCitationRow>(
      client,
      DOCUMENT_SUBMISSION_CITATIONS_TABLE,
      DOCUMENT_SUBMISSION_CITATION_COLUMNS,
      "document_submission_id",
      submissionIds,
      `select ${DOCUMENT_SUBMISSION_CITATIONS_TABLE}`,
    ),
    selectByIds<AdmissionScheduleCitationRow>(
      client,
      ADMISSION_SCHEDULE_CITATIONS_TABLE,
      ADMISSION_SCHEDULE_CITATION_COLUMNS,
      "admission_schedule_id",
      scheduleIds,
      `select ${ADMISSION_SCHEDULE_CITATIONS_TABLE}`,
    ),
  ]);

  return {
    sectionCitations,
    documentCitations,
    submissionCitations,
    scheduleCitations,
  };
}

export async function fetchSourceCitations(
  client: SupabaseClient,
  citationIds: readonly string[],
): Promise<SourceCitationRow[]> {
  return selectByIds<SourceCitationRow>(
    client,
    SOURCE_CITATIONS_TABLE,
    SOURCE_CITATION_COLUMNS,
    "id",
    citationIds,
    `select ${SOURCE_CITATIONS_TABLE}`,
  );
}

export async function fetchSourceDocumentSummaries(
  client: SupabaseClient,
  sourceDocumentIds: readonly string[],
): Promise<SourceDocumentSummary[]> {
  return selectByIds<SourceDocumentSummary>(
    client,
    SOURCE_DOCUMENTS_TABLE,
    SOURCE_DOCUMENT_SUMMARY_COLUMNS,
    "id",
    sourceDocumentIds,
    `select ${SOURCE_DOCUMENTS_TABLE}`,
  );
}
