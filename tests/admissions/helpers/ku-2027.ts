/**
 * Hosted acceptance constants from
 * supabase/migrations/20260905160000_load_ku_2027_reentry.sql
 * These belong in tests only, not production lib/.
 */

export const KU_2027 = {
  universitySlug: "korea-seoul",
  academicYear: 2027,
  admissionSlug: "overseas-korean-2pct",
  officialProgramName: "재외국민(정원외2%)전형",
  sub82Id: "46bd94bf-42dd-4d85-85c5-ec828061f6df",
  cit31Id: "b03a90b5-c3d5-42ea-b6ff-1ff61ebb4416",
  cit07Id: "79281172-a2c1-4e20-919e-d31c1ef1ada2",
  cit27Id: "ebff4f8d-115a-4f44-939a-f1d3bc74315e",
  cit30Id: "1f779f06-95f7-4520-890a-e5c30560c33e",
  sch11Id: "8a3e7f88-b24d-4822-9737-485c2539c8cf",
  s01Id: "316d1a61-6119-4d15-ac69-5395279ff99a",
  s05HtmlId: "b17b767f-7eaf-4e12-a2db-6dcf4f024c25",
  s05PdfId: "31c298f9-cde7-407b-be2d-692235e1a391",
  s06Id: "91ce33c3-e327-4681-a267-04c1ba32c172",
  expected: {
    sections: 17,
    schedules: 15,
    documents: 42,
    submissions: 84,
    choiceGroups: 1,
    choiceItems: 2,
    programSources: 6,
    sourcesById: 6,
    sectionCitations: 24,
    documentCitations: 56,
    submissionCitations: 90,
    scheduleCitations: 30,
    citationRelations: 200,
    uniqueCitations: 33,
  },
} as const;
