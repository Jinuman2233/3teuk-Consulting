import assert from "node:assert/strict";
import { test } from "node:test";
import { getAdmissionProgramDetailReadModel } from "@/lib/admissions";
import {
  AdmissionsIntegrityError,
  AdmissionsQueryError,
} from "@/lib/admissions/errors";
import type { AdmissionProgramDetailReadModel } from "@/lib/admissions/detail-types";
import { KU_2027 } from "./helpers/ku-2027";

function requireHostedEnv(): void {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const publishable = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();
  if (!url || !publishable) {
    throw new Error(
      "Hosted admission-detail test requires NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY. This command must not skip.",
    );
  }
}

function countCitationAttachments(model: AdmissionProgramDetailReadModel) {
  const section = model.sections.reduce(
    (sum, item) => sum + item.citations.length,
    0,
  );
  const document = model.requiredDocuments.reduce(
    (sum, item) => sum + item.citations.length,
    0,
  );
  const submission = model.requiredDocuments.reduce(
    (sum, item) =>
      sum +
      item.submissions.reduce(
        (inner, submissionItem) => inner + submissionItem.citations.length,
        0,
      ),
    0,
  );
  const schedule = model.schedules.reduce(
    (sum, item) => sum + item.citations.length,
    0,
  );
  return {
    section,
    document,
    submission,
    schedule,
    total: section + document + submission + schedule,
  };
}

function uniqueCitationIds(model: AdmissionProgramDetailReadModel): Set<string> {
  const ids = new Set<string>();
  for (const item of model.sections) {
    for (const citation of item.citations) ids.add(citation.id);
  }
  for (const document of model.requiredDocuments) {
    for (const citation of document.citations) ids.add(citation.id);
    for (const submission of document.submissions) {
      for (const citation of submission.citations) ids.add(citation.id);
    }
  }
  for (const item of model.schedules) {
    for (const citation of item.citations) ids.add(citation.id);
  }
  return ids;
}

function allCitations(model: AdmissionProgramDetailReadModel) {
  return [
    ...model.sections.flatMap((item) => item.citations),
    ...model.requiredDocuments.flatMap((item) => [
      ...item.citations,
      ...item.submissions.flatMap((submission) => submission.citations),
    ]),
    ...model.schedules.flatMap((item) => item.citations),
  ];
}

function findSubmission(
  model: AdmissionProgramDetailReadModel,
  submissionId: string,
) {
  for (const document of model.requiredDocuments) {
    const found = document.submissions.find(
      (item) => item.submission.id === submissionId,
    );
    if (found) {
      return found;
    }
  }
  return undefined;
}

requireHostedEnv();

test(
  "public loader returns the KU 2027 overseas-korean-2pct graph",
  { timeout: 60_000 },
  async () => {
    const model = await getAdmissionProgramDetailReadModel(
      KU_2027.universitySlug,
      KU_2027.academicYear,
      KU_2027.admissionSlug,
    );

    assert.ok(model, "expected a read model, not null");
    assert.equal(model.university.slug, KU_2027.universitySlug);
    assert.equal(model.program.academic_year, KU_2027.academicYear);
    assert.equal(model.program.admission_slug, KU_2027.admissionSlug);
    assert.equal(
      model.program.official_program_name,
      KU_2027.officialProgramName,
    );

    assert.equal(model.sections.length, KU_2027.expected.sections);
    assert.equal(model.schedules.length, KU_2027.expected.schedules);
    assert.equal(model.requiredDocuments.length, KU_2027.expected.documents);
    const submissionCount = model.requiredDocuments.reduce(
      (sum, document) => sum + document.submissions.length,
      0,
    );
    assert.equal(submissionCount, KU_2027.expected.submissions);
    assert.equal(model.choiceGroups.length, KU_2027.expected.choiceGroups);
    const choiceItemCount = model.choiceGroups.reduce(
      (sum, group) => sum + group.items.length,
      0,
    );
    assert.equal(choiceItemCount, KU_2027.expected.choiceItems);
    assert.equal(model.programSources.length, KU_2027.expected.programSources);
    assert.equal(
      Object.keys(model.sourcesById).length,
      KU_2027.expected.sourcesById,
    );

    const attachments = countCitationAttachments(model);
    assert.equal(attachments.section, KU_2027.expected.sectionCitations);
    assert.equal(attachments.document, KU_2027.expected.documentCitations);
    assert.equal(attachments.submission, KU_2027.expected.submissionCitations);
    assert.equal(attachments.schedule, KU_2027.expected.scheduleCitations);
    assert.equal(attachments.total, KU_2027.expected.citationRelations);
    assert.equal(
      uniqueCitationIds(model).size,
      KU_2027.expected.uniqueCitations,
    );

    const programSourceIds = new Set(
      model.programSources.map((row) => row.source_document_id),
    );
    const sourcesByIdKeys = new Set(Object.keys(model.sourcesById));
    assert.deepEqual(
      [...programSourceIds].sort(),
      [...sourcesByIdKeys].sort(),
    );

    for (const citation of allCitations(model)) {
      assert.ok(
        sourcesByIdKeys.has(citation.source_document_id),
        `citation ${citation.id} source is outside inventory`,
      );
      assert.notEqual(citation.source_document_id, KU_2027.s06Id);
    }

    const scheduleIds = new Set(
      model.schedules.map((item) => item.schedule.id),
    );
    for (const document of model.requiredDocuments) {
      for (const item of document.submissions) {
        const scheduleId = item.submission.admission_schedule_id;
        if (scheduleId !== null) {
          assert.ok(
            scheduleIds.has(scheduleId),
            `submission ${item.submission.id} has dangling schedule ${scheduleId}`,
          );
        }
      }
    }

    const documentIds = new Set(
      model.requiredDocuments.map((item) => item.document.id),
    );
    assert.equal(model.choiceGroups.length, 1);
    for (const group of model.choiceGroups) {
      for (const item of group.items) {
        assert.equal(item.choice_group_id, group.choiceGroup.id);
        assert.ok(documentIds.has(item.required_document_id));
        assert.equal(item.admission_program_id, model.program.id);
      }
    }

    const sub82 = findSubmission(model, KU_2027.sub82Id);
    assert.ok(sub82, "SUB82 missing from hosted graph");
    assert.equal(sub82.submission.verification_status, "needs_review");
    assert.equal(sub82.submission.admission_schedule_id, null);
    assert.equal(sub82.submission.verified_at, null);
    assert.deepEqual(
      [...sub82.citations.map((citation) => citation.id)].sort(),
      [KU_2027.cit07Id, KU_2027.cit27Id, KU_2027.cit30Id, KU_2027.cit31Id].sort(),
    );
    assert.equal("linkedSchedule" in sub82, false);
    assert.equal("deadline" in sub82.submission, false);
    assert.equal("hasConflict" in sub82, false);
    assert.notEqual(sub82.submission.verification_status, "verified");
    assert.notEqual(sub82.submission.admission_schedule_id, KU_2027.sch11Id);

    const programSourceIdList = model.programSources.map(
      (row) => row.source_document_id,
    );
    assert.ok(programSourceIdList.includes(KU_2027.s05HtmlId));
    assert.ok(programSourceIdList.includes(KU_2027.s05PdfId));
    assert.notEqual(KU_2027.s05HtmlId, KU_2027.s05PdfId);
    assert.ok(model.sourcesById[KU_2027.s05HtmlId]);
    assert.ok(model.sourcesById[KU_2027.s05PdfId]);

    assert.equal(programSourceIdList.includes(KU_2027.s06Id), false);
    assert.equal(KU_2027.s06Id in model.sourcesById, false);
    const s01 = model.sourcesById[KU_2027.s01Id];
    assert.ok(s01);
    assert.equal(s01.supersedes_source_document_id, KU_2027.s06Id);

    assert.equal("hasConflict" in model, false);
    assert.equal("conflictDetected" in model, false);
    JSON.stringify(model);
  },
);

test(
  "public loader returns null for unknown university or admission slug",
  { timeout: 30_000 },
  async () => {
    const missingUniversity = await getAdmissionProgramDetailReadModel(
      "no-such-university",
      KU_2027.academicYear,
      KU_2027.admissionSlug,
    );
    assert.equal(missingUniversity, null);

    const missingAdmission = await getAdmissionProgramDetailReadModel(
      KU_2027.universitySlug,
      KU_2027.academicYear,
      "no-such-admission",
    );
    assert.equal(missingAdmission, null);
  },
);

test("hosted route miss is not an integrity or query error", async () => {
  try {
    const result = await getAdmissionProgramDetailReadModel(
      "no-such-university",
      KU_2027.academicYear,
      KU_2027.admissionSlug,
    );
    assert.equal(result, null);
  } catch (error) {
    assert.equal(error instanceof AdmissionsIntegrityError, false);
    assert.equal(
      error instanceof AdmissionsQueryError && error.code === "QUERY_FAILED",
      false,
    );
    throw error;
  }
});
