import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import { assembleAdmissionDetailReadModel } from "./detail-assembly";
import {
  fetchAdmissionCategory,
  fetchCitationRelations,
  fetchDocumentChildren,
  fetchProgramChildren,
  fetchSourceCitations,
  fetchSourceDocumentSummaries,
} from "./detail-fetch";
import {
  assertAdmissionDetailGraph,
  assertCategoryRowPresent,
  assertCitationRowsPresent,
  assertCitedSourcesInInventory,
  assertSourceDocumentsPresent,
  collectProgramSourceDocumentIds,
} from "./detail-integrity";
import type { AdmissionProgramDetailReadModel } from "./detail-types";
import { getClient, uniqueIds } from "./query";
import { getAdmissionProgramDetail } from "./select";

function collectRelationCitationIds(
  relations: readonly { source_citation_id: string }[],
): string[] {
  return uniqueIds(relations.map((row) => row.source_citation_id));
}

/**
 * Production admission-detail loader.
 * Always uses the approved server public/publishable read client.
 * Does not accept an injected Supabase client.
 */
export async function getAdmissionProgramDetailReadModel(
  universitySlug: string,
  academicYear: number,
  admissionSlug: string,
): Promise<AdmissionProgramDetailReadModel | null> {
  return getAdmissionProgramDetailReadModelWithClient(
    universitySlug,
    academicYear,
    admissionSlug,
    getClient(),
  );
}

/**
 * Internal/test seam. Not exported from `@/lib/admissions`.
 * Route lookup and all child queries use the same injected client.
 */
export async function getAdmissionProgramDetailReadModelWithClient(
  universitySlug: string,
  academicYear: number,
  admissionSlug: string,
  client: SupabaseClient,
): Promise<AdmissionProgramDetailReadModel | null> {
  const supabase = getClient(client);
  const identity = await getAdmissionProgramDetail(
    universitySlug,
    academicYear,
    admissionSlug,
    supabase,
  );
  if (!identity) {
    return null;
  }

  const { university, program } = identity;
  const categoryId = program.admission_category_id;

  const [category, children] = await Promise.all([
    categoryId ? fetchAdmissionCategory(supabase, categoryId) : null,
    fetchProgramChildren(supabase, program.id),
  ]);

  assertCategoryRowPresent(categoryId, category);

  const { submissions, choiceGroupItems } = await fetchDocumentChildren(
    supabase,
    children.documents.map((document) => document.id),
    children.choiceGroups.map((group) => group.id),
  );

  const citationRelations = await fetchCitationRelations(
    supabase,
    children.sections.map((section) => section.id),
    children.documents.map((document) => document.id),
    submissions.map((submission) => submission.id),
    children.schedules.map((schedule) => schedule.id),
  );

  const referencedCitationIds = collectRelationCitationIds([
    ...citationRelations.sectionCitations,
    ...citationRelations.documentCitations,
    ...citationRelations.submissionCitations,
    ...citationRelations.scheduleCitations,
  ]);

  const citations = await fetchSourceCitations(supabase, referencedCitationIds);
  assertCitationRowsPresent(referencedCitationIds, citations);

  const programSourceDocumentIds = collectProgramSourceDocumentIds(
    children.programSources,
  );
  assertCitedSourcesInInventory(citations, programSourceDocumentIds);

  const sourceDocuments = await fetchSourceDocumentSummaries(
    supabase,
    [...programSourceDocumentIds],
  );
  assertSourceDocumentsPresent(programSourceDocumentIds, sourceDocuments);
  assertAdmissionDetailGraph({
    programId: program.id,
    sections: children.sections,
    schedules: children.schedules,
    documents: children.documents,
    submissions,
    choiceGroups: children.choiceGroups,
    choiceGroupItems,
    programSources: children.programSources,
    sectionCitations: citationRelations.sectionCitations,
    documentCitations: citationRelations.documentCitations,
    submissionCitations: citationRelations.submissionCitations,
    scheduleCitations: citationRelations.scheduleCitations,
  });

  return assembleAdmissionDetailReadModel({
    university,
    program,
    category,
    sections: children.sections,
    schedules: children.schedules,
    documents: children.documents,
    submissions,
    choiceGroups: children.choiceGroups,
    choiceGroupItems,
    programSources: children.programSources,
    sectionCitations: citationRelations.sectionCitations,
    documentCitations: citationRelations.documentCitations,
    submissionCitations: citationRelations.submissionCitations,
    scheduleCitations: citationRelations.scheduleCitations,
    citations,
    sourceDocuments,
  });
}
