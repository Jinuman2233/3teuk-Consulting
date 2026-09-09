import assert from "node:assert/strict";
import { test } from "node:test";
import { getAdmissionProgramDetailReadModelWithClient } from "@/lib/admissions/detail-repository";
import {
  AdmissionsIntegrityError,
  AdmissionsQueryError,
} from "@/lib/admissions/errors";
import {
  cloneDataset,
  createStrictFakeClient,
  queryTables,
  type FakeDataset,
} from "./helpers/fake-supabase";
import {
  SYNTHETIC,
  createValidDataset,
  outsideInventoryCitation,
} from "./helpers/synthetic-graph";

async function loadReadModel(
  dataset: FakeDataset,
  options?: {
    queryErrors?: Parameters<typeof createStrictFakeClient>[0]["queryErrors"];
    injectAfterFilter?: Parameters<
      typeof createStrictFakeClient
    >[0]["injectAfterFilter"];
  },
) {
  const { client, calls } = createStrictFakeClient({
    dataset,
    queryErrors: options?.queryErrors,
    injectAfterFilter: options?.injectAfterFilter,
  });
  const result = await getAdmissionProgramDetailReadModelWithClient(
    SYNTHETIC.universitySlug,
    SYNTHETIC.academicYear,
    SYNTHETIC.admissionSlug,
    client,
  );
  return { result, calls };
}

async function expectIntegrityViolation(run: () => Promise<unknown>) {
  await assert.rejects(run, (error: unknown) => {
    assert.ok(error instanceof AdmissionsIntegrityError);
    assert.equal(error.code, "INTEGRITY_VIOLATION");
    assert.notEqual(error.code, "QUERY_FAILED");
    return true;
  });
}

test("valid synthetic baseline returns a serializable read model", async () => {
  const { result, calls } = await loadReadModel(createValidDataset());
  assert.ok(result);
  assert.equal(result.university.slug, SYNTHETIC.universitySlug);
  assert.equal(result.program.admission_slug, SYNTHETIC.admissionSlug);
  assert.equal(result.category?.id, SYNTHETIC.categoryId);
  assert.equal(result.sections.length, 1);
  assert.equal(result.schedules.length, 1);
  assert.equal(result.requiredDocuments.length, 1);
  assert.equal(result.requiredDocuments[0]?.submissions.length, 1);
  assert.equal(result.choiceGroups.length, 1);
  assert.equal(result.choiceGroups[0]?.items.length, 1);
  assert.equal(result.programSources.length, 1);
  assert.deepEqual(Object.keys(result.sourcesById), [SYNTHETIC.sourceId]);
  assert.equal("hasConflict" in result, false);
  assert.equal("conflictDetected" in result, false);
  assert.equal(
    "linkedSchedule" in (result.requiredDocuments[0]?.submissions[0] ?? {}),
    false,
  );
  const json = JSON.stringify(result);
  assert.ok(json.includes(SYNTHETIC.programId));
  assert.equal(json.includes("[object Map]"), false);

  const tables = queryTables(calls);
  assert.ok(tables.length <= 16);
  assert.equal(tables.length, 16);
  for (const table of tables) {
    assert.equal(
      tables.filter((name) => name === table).length,
      1,
      `${table} was queried more than once`,
    );
  }
});

test("null admission_schedule_id is valid and stays null", async () => {
  const { result } = await loadReadModel(
    createValidDataset({ admissionScheduleId: null }),
  );
  assert.ok(result);
  assert.equal(
    result.requiredDocuments[0]?.submissions[0]?.submission
      .admission_schedule_id,
    null,
  );
});

test("multiple citations on one parent succeed without conflict inference", async () => {
  const { result } = await loadReadModel(
    createValidDataset({ extraSectionCitation: true }),
  );
  assert.ok(result);
  assert.equal(result.sections[0]?.citations.length, 2);
  assert.equal("hasConflict" in result, false);
  assert.equal("conflictDetected" in (result.sections[0] ?? {}), false);
});

test("nullable category FK returns category null", async () => {
  const { result, calls } = await loadReadModel(
    createValidDataset({ admissionCategoryId: null }),
  );
  assert.ok(result);
  assert.equal(result.category, null);
  assert.equal(
    queryTables(calls).includes("admission_categories"),
    false,
  );
});

test("missing category row is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  dataset.admission_categories = [];
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("category query error is QUERY_FAILED, not INTEGRITY_VIOLATION", async () => {
  await assert.rejects(
    () =>
      loadReadModel(createValidDataset(), {
        queryErrors: {
          admission_categories: { message: "category lookup failed" },
        },
      }),
    (error: unknown) => {
      assert.ok(error instanceof AdmissionsQueryError);
      assert.equal(error instanceof AdmissionsIntegrityError, false);
      assert.equal(error.code, "QUERY_FAILED");
      return true;
    },
  );
});

test("child query error is QUERY_FAILED", async () => {
  await assert.rejects(
    () =>
      loadReadModel(createValidDataset(), {
        queryErrors: {
          admission_sections: { message: "sections select failed" },
        },
      }),
    (error: unknown) => {
      assert.ok(error instanceof AdmissionsQueryError);
      assert.equal(error instanceof AdmissionsIntegrityError, false);
      assert.equal(error.code, "QUERY_FAILED");
      return true;
    },
  );
});

test("route miss returns null, not an integrity error", async () => {
  const missingUniversity = createValidDataset();
  missingUniversity.universities = [];
  const { result: noUniversity } = await loadReadModel(missingUniversity);
  assert.equal(noUniversity, null);

  const missingProgram = createValidDataset();
  missingProgram.admission_programs = [];
  const { result: noProgram } = await loadReadModel(missingProgram);
  assert.equal(noProgram, null);
});

test("dangling schedule FK is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const submission = dataset.document_submissions[0];
  assert.ok(submission);
  submission.admission_schedule_id = SYNTHETIC.unknownId;
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("orphan submission missing parent document is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const orphan = cloneDataset(dataset).document_submissions[0];
  assert.ok(orphan);
  orphan.required_document_id = SYNTHETIC.unknownId;
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: { document_submissions: [orphan] },
    }),
  );
});

test("submission with another program id is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const submission = dataset.document_submissions[0];
  assert.ok(submission);
  submission.admission_program_id = SYNTHETIC.otherProgramId;
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("choice item missing group is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const orphan = {
    choice_group_id: SYNTHETIC.unknownId,
    required_document_id: SYNTHETIC.documentId,
    admission_program_id: SYNTHETIC.programId,
  };
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: {
        required_document_choice_group_items: [orphan],
      },
    }),
  );
});

test("choice item missing document is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const item = dataset.required_document_choice_group_items[0];
  assert.ok(item);
  item.required_document_id = SYNTHETIC.unknownId;
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("choice item with another program id is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const item = dataset.required_document_choice_group_items[0];
  assert.ok(item);
  item.admission_program_id = SYNTHETIC.otherProgramId;
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("section citation missing parent is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: {
        admission_section_citations: [
          {
            admission_section_id: SYNTHETIC.unknownId,
            source_citation_id: SYNTHETIC.citationId,
          },
        ],
      },
    }),
  );
});

test("document citation missing parent is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: {
        required_document_citations: [
          {
            required_document_id: SYNTHETIC.unknownId,
            source_citation_id: SYNTHETIC.citationId,
          },
        ],
      },
    }),
  );
});

test("submission citation missing parent is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: {
        document_submission_citations: [
          {
            document_submission_id: SYNTHETIC.unknownId,
            source_citation_id: SYNTHETIC.citationId,
          },
        ],
      },
    }),
  );
});

test("schedule citation missing parent is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: {
        admission_schedule_citations: [
          {
            admission_schedule_id: SYNTHETIC.unknownId,
            source_citation_id: SYNTHETIC.citationId,
          },
        ],
      },
    }),
  );
});

test("missing source_citation identity is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const relation = dataset.admission_section_citations[0];
  assert.ok(relation);
  relation.source_citation_id = SYNTHETIC.unknownId;
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("citation outside ProgramSource inventory is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  dataset.source_citations.push(outsideInventoryCitation());
  dataset.admission_section_citations.push({
    admission_section_id: SYNTHETIC.sectionId,
    source_citation_id: SYNTHETIC.outsideCitationId,
  });
  await expectIntegrityViolation(() => loadReadModel(dataset));
});

test("ProgramSource scoped to another program is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  const leaked = { ...dataset.admission_program_sources[0]! };
  leaked.admission_program_id = SYNTHETIC.otherProgramId;
  await expectIntegrityViolation(() =>
    loadReadModel(dataset, {
      injectAfterFilter: { admission_program_sources: [leaked] },
    }),
  );
});

test("missing SourceDocument for ProgramSource is INTEGRITY_VIOLATION", async () => {
  const dataset = createValidDataset();
  dataset.source_documents = [];
  await expectIntegrityViolation(() => loadReadModel(dataset));
});
