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
} from "@/lib/admissions/detail-types";
import type { AdmissionProgramRow, UniversityRow } from "@/lib/admissions/types";
import type { FakeDataset } from "./fake-supabase";

export const SYNTHETIC = {
  universityId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000001",
  categoryId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000002",
  programId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000003",
  sectionId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000004",
  scheduleId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000005",
  documentId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000006",
  submissionId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000007",
  choiceGroupId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000008",
  sourceId: "aaaaaaaa-aaaa-4aaa-8aaa-000000000009",
  citationId: "aaaaaaaa-aaaa-4aaa-8aaa-00000000000a",
  citationId2: "aaaaaaaa-aaaa-4aaa-8aaa-00000000000b",
  outsideSourceId: "aaaaaaaa-aaaa-4aaa-8aaa-00000000000c",
  outsideCitationId: "aaaaaaaa-aaaa-4aaa-8aaa-00000000000d",
  unknownId: "bbbbbbbb-bbbb-4bbb-8bbb-000000000001",
  otherProgramId: "cccccccc-cccc-4ccc-8ccc-000000000001",
  universitySlug: "synthetic-university",
  academicYear: 2026,
  admissionSlug: "synthetic-admission",
} as const;

const NOW = "2026-01-15T00:00:00.000Z";

function university(): UniversityRow {
  return {
    id: SYNTHETIC.universityId,
    name_ko: "합성대학교",
    name_en: "Synthetic University",
    campus_name: "테스트캠퍼스",
    display_name: "합성대학교 테스트캠퍼스",
    slug: SYNTHETIC.universitySlug,
    official_website_url: null,
    admissions_office_url: null,
    created_at: NOW,
    updated_at: NOW,
  };
}

function category(): AdmissionCategoryRow {
  return {
    id: SYNTHETIC.categoryId,
    code: "synthetic",
    label: "Synthetic category",
    description: null,
    created_at: NOW,
    updated_at: NOW,
  };
}

function program(
  admissionCategoryId: string | null = SYNTHETIC.categoryId,
): AdmissionProgramRow {
  return {
    id: SYNTHETIC.programId,
    university_id: SYNTHETIC.universityId,
    admission_category_id: admissionCategoryId,
    academic_year: SYNTHETIC.academicYear,
    official_program_name: "합성전형",
    display_name: "합성전형",
    admission_slug: SYNTHETIC.admissionSlug,
    information_type: "official_fact",
    verification_status: "verified",
    verified_at: NOW,
    notes: null,
    created_at: NOW,
    updated_at: NOW,
  };
}

function section(): AdmissionSectionRow {
  return {
    id: SYNTHETIC.sectionId,
    admission_program_id: SYNTHETIC.programId,
    section_type: "overview",
    title: "개요",
    content: "합성 섹션",
    applicability_text: null,
    information_type: "official_fact",
    availability_status: "available",
    verification_status: "verified",
    verified_at: NOW,
    display_order: 1,
    created_at: NOW,
    updated_at: NOW,
  };
}

function schedule(): AdmissionScheduleRow {
  return {
    id: SYNTHETIC.scheduleId,
    admission_program_id: SYNTHETIC.programId,
    event_name: "원서접수",
    temporal_precision: "date",
    start_date: "2026-07-01",
    end_date: "2026-07-10",
    start_at: null,
    end_at: null,
    timezone: null,
    location_text: null,
    description: null,
    verification_status: "verified",
    verified_at: NOW,
    display_order: 1,
    created_at: NOW,
    updated_at: NOW,
  };
}

function document(): RequiredDocumentRow {
  return {
    id: SYNTHETIC.documentId,
    admission_program_id: SYNTHETIC.programId,
    name: "성적증명서",
    description: null,
    requirement_status: "required",
    condition: null,
    document_subject_text: null,
    display_order: 1,
    verification_status: "verified",
    verified_at: NOW,
    created_at: NOW,
    updated_at: NOW,
  };
}

function submission(
  admissionScheduleId: string | null = SYNTHETIC.scheduleId,
): DocumentSubmissionRow {
  return {
    id: SYNTHETIC.submissionId,
    required_document_id: SYNTHETIC.documentId,
    admission_program_id: SYNTHETIC.programId,
    submission_phase: "원서접수",
    submission_method: "온라인",
    submission_format: "PDF",
    admission_schedule_id: admissionScheduleId,
    instructions: null,
    display_order: 1,
    verification_status: "verified",
    verified_at: NOW,
    created_at: NOW,
    updated_at: NOW,
  };
}

function choiceGroup(): RequiredDocumentChoiceGroupRow {
  return {
    id: SYNTHETIC.choiceGroupId,
    admission_program_id: SYNTHETIC.programId,
    title: "선택 제출",
    rule_text: "다음 중 하나",
    condition: null,
    display_order: 1,
    verification_status: "verified",
    verified_at: NOW,
    created_at: NOW,
    updated_at: NOW,
  };
}

function choiceItem(): RequiredDocumentChoiceGroupItemRow {
  return {
    choice_group_id: SYNTHETIC.choiceGroupId,
    required_document_id: SYNTHETIC.documentId,
    admission_program_id: SYNTHETIC.programId,
  };
}

function programSource(): AdmissionProgramSourceRow {
  return {
    admission_program_id: SYNTHETIC.programId,
    source_document_id: SYNTHETIC.sourceId,
    source_role: "primary_guide",
    display_order: 1,
    notes: null,
    created_at: NOW,
  };
}

function sourceDocument(): SourceDocumentSummary {
  return {
    id: SYNTHETIC.sourceId,
    university_id: SYNTHETIC.universityId,
    academic_year: SYNTHETIC.academicYear,
    source_type: "admissions_guide",
    title: "합성 요강",
    issuing_organization: "합성대학교",
    source_url: "https://example.test/guide.pdf",
    published_at: "2026-01-01",
    last_checked_at: NOW,
    document_version_label: null,
    supersedes_source_document_id: null,
    notes: null,
  };
}

function citation(id: string = SYNTHETIC.citationId): SourceCitationRow {
  return {
    id,
    source_document_id: SYNTHETIC.sourceId,
    file_page_number: 1,
    printed_page_label: "1",
    section: "I",
    anchor_description: "합성 인용",
    verified_at: NOW,
    created_at: NOW,
  };
}

function sectionCitation(
  citationId: string = SYNTHETIC.citationId,
): AdmissionSectionCitationRow {
  return {
    admission_section_id: SYNTHETIC.sectionId,
    source_citation_id: citationId,
  };
}

function documentCitation(): RequiredDocumentCitationRow {
  return {
    required_document_id: SYNTHETIC.documentId,
    source_citation_id: SYNTHETIC.citationId,
  };
}

function submissionCitation(): DocumentSubmissionCitationRow {
  return {
    document_submission_id: SYNTHETIC.submissionId,
    source_citation_id: SYNTHETIC.citationId,
  };
}

function scheduleCitation(): AdmissionScheduleCitationRow {
  return {
    admission_schedule_id: SYNTHETIC.scheduleId,
    source_citation_id: SYNTHETIC.citationId,
  };
}

export function createValidDataset(options?: {
  admissionCategoryId?: string | null;
  admissionScheduleId?: string | null;
  extraSectionCitation?: boolean;
}): FakeDataset {
  const citations = [citation()];
  const sectionCitations = [sectionCitation()];
  if (options?.extraSectionCitation) {
    citations.push(citation(SYNTHETIC.citationId2));
    sectionCitations.push(sectionCitation(SYNTHETIC.citationId2));
  }

  return {
    universities: [university()],
    admission_programs: [program(options?.admissionCategoryId)],
    admission_categories: [category()],
    admission_sections: [section()],
    admission_schedules: [schedule()],
    required_documents: [document()],
    document_submissions: [submission(options?.admissionScheduleId)],
    required_document_choice_groups: [choiceGroup()],
    required_document_choice_group_items: [choiceItem()],
    admission_program_sources: [programSource()],
    source_documents: [sourceDocument()],
    source_citations: citations,
    admission_section_citations: sectionCitations,
    required_document_citations: [documentCitation()],
    document_submission_citations: [submissionCitation()],
    admission_schedule_citations: [scheduleCitation()],
  };
}

export function outsideInventoryCitation(): SourceCitationRow {
  return {
    id: SYNTHETIC.outsideCitationId,
    source_document_id: SYNTHETIC.outsideSourceId,
    file_page_number: 2,
    printed_page_label: "2",
    section: null,
    anchor_description: null,
    verified_at: null,
    created_at: NOW,
  };
}
