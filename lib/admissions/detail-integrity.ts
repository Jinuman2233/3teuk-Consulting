import { AdmissionsIntegrityError } from "./errors";
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

export function assertCategoryRowPresent(
  categoryId: string | null,
  category: AdmissionCategoryRow | null,
): void {
  if (categoryId && !category) {
    throw new AdmissionsIntegrityError(
      `admission_category ${categoryId} referenced by program was not found`,
    );
  }
}

export function assertCitationRowsPresent(
  referencedCitationIds: readonly string[],
  citations: readonly SourceCitationRow[],
): void {
  const found = new Set(citations.map((citation) => citation.id));
  const missing = referencedCitationIds.filter((id) => !found.has(id));
  if (missing.length > 0) {
    throw new AdmissionsIntegrityError(
      `source_citation rows missing for referenced ids: ${missing.join(", ")}`,
    );
  }
}

export function collectProgramSourceDocumentIds(
  programSources: readonly AdmissionProgramSourceRow[],
): Set<string> {
  return new Set(programSources.map((row) => row.source_document_id));
}

export function assertCitedSourcesInInventory(
  citations: readonly SourceCitationRow[],
  programSourceDocumentIds: ReadonlySet<string>,
): void {
  const outside = citations.filter(
    (citation) => !programSourceDocumentIds.has(citation.source_document_id),
  );
  if (outside.length > 0) {
    const sourceIds = [...new Set(outside.map((row) => row.source_document_id))];
    throw new AdmissionsIntegrityError(
      `cited source_document ids are outside admission_program_sources: ${sourceIds.join(", ")}`,
    );
  }
}

export function assertSourceDocumentsPresent(
  programSourceDocumentIds: ReadonlySet<string>,
  sourceDocuments: readonly SourceDocumentSummary[],
): void {
  const found = new Set(sourceDocuments.map((document) => document.id));
  const missing = [...programSourceDocumentIds].filter((id) => !found.has(id));
  if (missing.length > 0) {
    throw new AdmissionsIntegrityError(
      `source_document rows missing for program sources: ${missing.join(", ")}`,
    );
  }
}

function assertRowsBelongToProgram(
  rows: readonly { admission_program_id: string }[],
  programId: string,
  table: string,
): void {
  for (const row of rows) {
    if (row.admission_program_id !== programId) {
      throw new AdmissionsIntegrityError(
        `${table} row is not scoped to the current admission program`,
      );
    }
  }
}

function assertParentPresent(
  parentId: string,
  loadedIds: ReadonlySet<string>,
  message: string,
): void {
  if (!loadedIds.has(parentId)) {
    throw new AdmissionsIntegrityError(message);
  }
}

/**
 * Fail-closed graph checks after queries succeed.
 * Missing required parents / dangling non-null FKs are INTEGRITY_VIOLATION.
 * Nullable FKs (category, admission_schedule_id) stay null with no inference.
 */
export function assertAdmissionDetailGraph(input: {
  programId: string;
  sections: readonly AdmissionSectionRow[];
  schedules: readonly AdmissionScheduleRow[];
  documents: readonly RequiredDocumentRow[];
  submissions: readonly DocumentSubmissionRow[];
  choiceGroups: readonly RequiredDocumentChoiceGroupRow[];
  choiceGroupItems: readonly RequiredDocumentChoiceGroupItemRow[];
  programSources: readonly AdmissionProgramSourceRow[];
  sectionCitations: readonly AdmissionSectionCitationRow[];
  documentCitations: readonly RequiredDocumentCitationRow[];
  submissionCitations: readonly DocumentSubmissionCitationRow[];
  scheduleCitations: readonly AdmissionScheduleCitationRow[];
}): void {
  const { programId } = input;

  assertRowsBelongToProgram(input.sections, programId, "admission_sections");
  assertRowsBelongToProgram(input.schedules, programId, "admission_schedules");
  assertRowsBelongToProgram(input.documents, programId, "required_documents");
  assertRowsBelongToProgram(
    input.choiceGroups,
    programId,
    "required_document_choice_groups",
  );
  assertRowsBelongToProgram(
    input.choiceGroupItems,
    programId,
    "required_document_choice_group_items",
  );
  assertRowsBelongToProgram(
    input.submissions,
    programId,
    "document_submissions",
  );
  assertRowsBelongToProgram(
    input.programSources,
    programId,
    "admission_program_sources",
  );

  const sectionIds = new Set(input.sections.map((row) => row.id));
  const scheduleIds = new Set(input.schedules.map((row) => row.id));
  const documentIds = new Set(input.documents.map((row) => row.id));
  const choiceGroupIds = new Set(input.choiceGroups.map((row) => row.id));
  const submissionIds = new Set(input.submissions.map((row) => row.id));

  for (const submission of input.submissions) {
    assertParentPresent(
      submission.required_document_id,
      documentIds,
      `document_submission ${submission.id} references required_document ${submission.required_document_id} that was not loaded`,
    );
    if (
      submission.admission_schedule_id !== null &&
      !scheduleIds.has(submission.admission_schedule_id)
    ) {
      throw new AdmissionsIntegrityError(
        `document_submission ${submission.id} references admission_schedule ${submission.admission_schedule_id} that was not loaded`,
      );
    }
  }

  for (const item of input.choiceGroupItems) {
    assertParentPresent(
      item.choice_group_id,
      choiceGroupIds,
      `choice_group_item (${item.choice_group_id}, ${item.required_document_id}) references a choice group that was not loaded`,
    );
    assertParentPresent(
      item.required_document_id,
      documentIds,
      `choice_group_item (${item.choice_group_id}, ${item.required_document_id}) references a required document that was not loaded`,
    );
  }

  for (const row of input.sectionCitations) {
    assertParentPresent(
      row.admission_section_id,
      sectionIds,
      `admission_section_citation references admission_section ${row.admission_section_id} that was not loaded`,
    );
  }
  for (const row of input.documentCitations) {
    assertParentPresent(
      row.required_document_id,
      documentIds,
      `required_document_citation references required_document ${row.required_document_id} that was not loaded`,
    );
  }
  for (const row of input.submissionCitations) {
    assertParentPresent(
      row.document_submission_id,
      submissionIds,
      `document_submission_citation references document_submission ${row.document_submission_id} that was not loaded`,
    );
  }
  for (const row of input.scheduleCitations) {
    assertParentPresent(
      row.admission_schedule_id,
      scheduleIds,
      `admission_schedule_citation references admission_schedule ${row.admission_schedule_id} that was not loaded`,
    );
  }
}
