import { AdmissionsIntegrityError } from "./errors";
import type {
  AdmissionDetailAssemblyInput,
  AdmissionProgramDetailReadModel,
  AdmissionProgramSourceRow,
  AdmissionScheduleCitationRow,
  AdmissionSectionCitationRow,
  DocumentSubmissionCitationRow,
  DocumentSubmissionRow,
  RequiredDocumentChoiceGroupItemRow,
  RequiredDocumentCitationRow,
  RequiredDocumentRow,
  SourceCitationRow,
  SourceDocumentSummary,
} from "./detail-types";

function compareDisplayOrderThenId(
  a: { display_order: number; id: string },
  b: { display_order: number; id: string },
): number {
  if (a.display_order !== b.display_order) {
    return a.display_order - b.display_order;
  }
  return a.id.localeCompare(b.id);
}

function compareProgramSources(
  a: AdmissionProgramSourceRow,
  b: AdmissionProgramSourceRow,
): number {
  if (a.display_order == null && b.display_order == null) {
    return a.source_document_id.localeCompare(b.source_document_id);
  }
  if (a.display_order == null) {
    return 1;
  }
  if (b.display_order == null) {
    return -1;
  }
  if (a.display_order !== b.display_order) {
    return a.display_order - b.display_order;
  }
  return a.source_document_id.localeCompare(b.source_document_id);
}

function sortCitations(citations: SourceCitationRow[]): SourceCitationRow[] {
  return [...citations].sort((a, b) => a.id.localeCompare(b.id));
}

function citationsFor<T extends { source_citation_id: string }>(
  relations: readonly T[],
  citationsById: ReadonlyMap<string, SourceCitationRow>,
): SourceCitationRow[] {
  const attached: SourceCitationRow[] = [];
  const seen = new Set<string>();
  for (const relation of relations) {
    if (seen.has(relation.source_citation_id)) {
      continue;
    }
    const citation = citationsById.get(relation.source_citation_id);
    if (!citation) {
      throw new AdmissionsIntegrityError(
        `source_citation ${relation.source_citation_id} referenced by a citation relation was not loaded`,
      );
    }
    seen.add(relation.source_citation_id);
    attached.push(citation);
  }
  return sortCitations(attached);
}

function groupBy<T, K extends string>(
  rows: readonly T[],
  key: (row: T) => K,
): Map<K, T[]> {
  const groups = new Map<K, T[]>();
  for (const row of rows) {
    const id = key(row);
    const list = groups.get(id);
    if (list) {
      list.push(row);
    } else {
      groups.set(id, [row]);
    }
  }
  return groups;
}

function requireLoadedDocument(
  documentsById: ReadonlyMap<string, RequiredDocumentRow>,
  documentId: string,
): RequiredDocumentRow {
  const document = documentsById.get(documentId);
  if (!document) {
    throw new AdmissionsIntegrityError(
      `required_document ${documentId} referenced by a choice-group item was not loaded`,
    );
  }
  return document;
}

function sortChoiceGroupItems(
  items: RequiredDocumentChoiceGroupItemRow[],
  documentsById: ReadonlyMap<string, RequiredDocumentRow>,
): RequiredDocumentChoiceGroupItemRow[] {
  return [...items].sort((a, b) => {
    const orderA = requireLoadedDocument(
      documentsById,
      a.required_document_id,
    ).display_order;
    const orderB = requireLoadedDocument(
      documentsById,
      b.required_document_id,
    ).display_order;
    if (orderA !== orderB) {
      return orderA - orderB;
    }
    return a.required_document_id.localeCompare(b.required_document_id);
  });
}

function sourcesByIdRecord(
  sourceDocuments: readonly SourceDocumentSummary[],
): Record<string, SourceDocumentSummary> {
  const record: Record<string, SourceDocumentSummary> = {};
  for (const document of sourceDocuments) {
    record[document.id] = document;
  }
  return record;
}

/**
 * Deterministic in-memory assembly. Does not fetch, interpret statuses,
 * infer conflicts, or follow supersedes_source_document_id.
 */
export function assembleAdmissionDetailReadModel(
  input: AdmissionDetailAssemblyInput,
): AdmissionProgramDetailReadModel {
  const citationsById = new Map(
    input.citations.map((citation) => [citation.id, citation]),
  );
  const documentsById = new Map(
    input.documents.map((document) => [document.id, document]),
  );

  const sectionRelations = groupBy(
    input.sectionCitations,
    (row: AdmissionSectionCitationRow) => row.admission_section_id,
  );
  const documentRelations = groupBy(
    input.documentCitations,
    (row: RequiredDocumentCitationRow) => row.required_document_id,
  );
  const submissionRelations = groupBy(
    input.submissionCitations,
    (row: DocumentSubmissionCitationRow) => row.document_submission_id,
  );
  const scheduleRelations = groupBy(
    input.scheduleCitations,
    (row: AdmissionScheduleCitationRow) => row.admission_schedule_id,
  );

  const submissionsByDocumentId = groupBy(
    input.submissions,
    (row: DocumentSubmissionRow) => row.required_document_id,
  );
  const itemsByGroupId = groupBy(
    input.choiceGroupItems,
    (row: RequiredDocumentChoiceGroupItemRow) => row.choice_group_id,
  );
  const groupIdsByDocumentId = groupBy(
    input.choiceGroupItems,
    (row: RequiredDocumentChoiceGroupItemRow) => row.required_document_id,
  );

  const sections = [...input.sections]
    .sort(compareDisplayOrderThenId)
    .map((section) => ({
      section,
      citations: citationsFor(
        sectionRelations.get(section.id) ?? [],
        citationsById,
      ),
    }));

  const schedules = [...input.schedules]
    .sort(compareDisplayOrderThenId)
    .map((schedule) => ({
      schedule,
      citations: citationsFor(
        scheduleRelations.get(schedule.id) ?? [],
        citationsById,
      ),
    }));

  const requiredDocuments = [...input.documents]
    .sort(compareDisplayOrderThenId)
    .map((document) => {
      const submissions = [...(submissionsByDocumentId.get(document.id) ?? [])]
        .sort(compareDisplayOrderThenId)
        .map((submission) => ({
          submission,
          citations: citationsFor(
            submissionRelations.get(submission.id) ?? [],
            citationsById,
          ),
        }));
      const choiceGroupIds = [
        ...new Set(
          (groupIdsByDocumentId.get(document.id) ?? []).map(
            (item) => item.choice_group_id,
          ),
        ),
      ].sort((a, b) => a.localeCompare(b));

      return {
        document,
        citations: citationsFor(
          documentRelations.get(document.id) ?? [],
          citationsById,
        ),
        submissions,
        choiceGroupIds,
      };
    });

  const choiceGroups = [...input.choiceGroups]
    .sort(compareDisplayOrderThenId)
    .map((choiceGroup) => ({
      choiceGroup,
      items: sortChoiceGroupItems(
        itemsByGroupId.get(choiceGroup.id) ?? [],
        documentsById,
      ),
    }));

  return {
    university: input.university,
    program: input.program,
    category: input.category,
    sections,
    schedules,
    requiredDocuments,
    choiceGroups,
    programSources: [...input.programSources].sort(compareProgramSources),
    sourcesById: sourcesByIdRecord(input.sourceDocuments),
  };
}
