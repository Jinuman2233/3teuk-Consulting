import type {
  AdmissionProgramRow,
  InformationType,
  UniversityRow,
  VerificationStatus,
} from "./types";

export type AvailabilityStatus =
  | "available"
  | "not_found_in_official_source"
  | "not_applicable"
  | "unknown"
  | "needs_confirmation";

export type TemporalPrecision = "date" | "datetime";

export type AdmissionCategoryRow = {
  id: string;
  code: string;
  label: string;
  description: string | null;
  created_at: string;
  updated_at: string;
};

export type AdmissionSectionRow = {
  id: string;
  admission_program_id: string;
  section_type: string;
  title: string;
  content: string;
  applicability_text: string | null;
  information_type: InformationType;
  availability_status: AvailabilityStatus;
  verification_status: VerificationStatus;
  verified_at: string | null;
  display_order: number;
  created_at: string;
  updated_at: string;
};

export type AdmissionScheduleRow = {
  id: string;
  admission_program_id: string;
  event_name: string;
  temporal_precision: TemporalPrecision;
  start_date: string | null;
  end_date: string | null;
  start_at: string | null;
  end_at: string | null;
  timezone: string | null;
  location_text: string | null;
  description: string | null;
  verification_status: VerificationStatus;
  verified_at: string | null;
  display_order: number;
  created_at: string;
  updated_at: string;
};

export type RequiredDocumentRow = {
  id: string;
  admission_program_id: string;
  name: string;
  description: string | null;
  requirement_status: string;
  condition: string | null;
  document_subject_text: string | null;
  display_order: number;
  verification_status: VerificationStatus;
  verified_at: string | null;
  created_at: string;
  updated_at: string;
};

export type DocumentSubmissionRow = {
  id: string;
  required_document_id: string;
  admission_program_id: string;
  submission_phase: string;
  submission_method: string | null;
  submission_format: string | null;
  admission_schedule_id: string | null;
  instructions: string | null;
  display_order: number;
  verification_status: VerificationStatus;
  verified_at: string | null;
  created_at: string;
  updated_at: string;
};

export type RequiredDocumentChoiceGroupRow = {
  id: string;
  admission_program_id: string;
  title: string | null;
  rule_text: string;
  condition: string | null;
  display_order: number;
  verification_status: VerificationStatus;
  verified_at: string | null;
  created_at: string;
  updated_at: string;
};

export type RequiredDocumentChoiceGroupItemRow = {
  choice_group_id: string;
  required_document_id: string;
  admission_program_id: string;
};

export type AdmissionProgramSourceRow = {
  admission_program_id: string;
  source_document_id: string;
  source_role: string | null;
  display_order: number | null;
  notes: string | null;
  created_at: string;
};

/**
 * file_page_number is the physical PDF page, 1-based, when present.
 * printed_page_label is a separate in-document label. Do not mix them.
 */
export type SourceCitationRow = {
  id: string;
  source_document_id: string;
  file_page_number: number | null;
  printed_page_label: string | null;
  section: string | null;
  anchor_description: string | null;
  verified_at: string | null;
  created_at: string;
};

export type SourceDocumentSummary = {
  id: string;
  university_id: string | null;
  academic_year: number | null;
  source_type: string;
  title: string;
  issuing_organization: string;
  source_url: string;
  published_at: string | null;
  last_checked_at: string;
  document_version_label: string | null;
  supersedes_source_document_id: string | null;
  notes: string | null;
};

export type AdmissionSectionCitationRow = {
  admission_section_id: string;
  source_citation_id: string;
};

export type RequiredDocumentCitationRow = {
  required_document_id: string;
  source_citation_id: string;
};

export type DocumentSubmissionCitationRow = {
  document_submission_id: string;
  source_citation_id: string;
};

export type AdmissionScheduleCitationRow = {
  admission_schedule_id: string;
  source_citation_id: string;
};

export type SectionWithProvenance = {
  section: AdmissionSectionRow;
  citations: SourceCitationRow[];
};

export type ScheduleWithProvenance = {
  schedule: AdmissionScheduleRow;
  citations: SourceCitationRow[];
};

export type DocumentSubmissionWithProvenance = {
  submission: DocumentSubmissionRow;
  citations: SourceCitationRow[];
};

export type RequiredDocumentWithProvenance = {
  document: RequiredDocumentRow;
  citations: SourceCitationRow[];
  submissions: DocumentSubmissionWithProvenance[];
  /** Convenience reverse index. Canonical M:N is choiceGroups[].items. */
  choiceGroupIds: string[];
};

export type ChoiceGroupWithItems = {
  choiceGroup: RequiredDocumentChoiceGroupRow;
  items: RequiredDocumentChoiceGroupItemRow[];
};

export type AdmissionProgramDetailReadModel = {
  university: UniversityRow;
  program: AdmissionProgramRow;
  category: AdmissionCategoryRow | null;
  sections: SectionWithProvenance[];
  schedules: ScheduleWithProvenance[];
  requiredDocuments: RequiredDocumentWithProvenance[];
  choiceGroups: ChoiceGroupWithItems[];
  programSources: AdmissionProgramSourceRow[];
  sourcesById: Record<string, SourceDocumentSummary>;
};

export type AdmissionDetailAssemblyInput = {
  university: UniversityRow;
  program: AdmissionProgramRow;
  category: AdmissionCategoryRow | null;
  sections: AdmissionSectionRow[];
  schedules: AdmissionScheduleRow[];
  documents: RequiredDocumentRow[];
  submissions: DocumentSubmissionRow[];
  choiceGroups: RequiredDocumentChoiceGroupRow[];
  choiceGroupItems: RequiredDocumentChoiceGroupItemRow[];
  programSources: AdmissionProgramSourceRow[];
  sectionCitations: AdmissionSectionCitationRow[];
  documentCitations: RequiredDocumentCitationRow[];
  submissionCitations: DocumentSubmissionCitationRow[];
  scheduleCitations: AdmissionScheduleCitationRow[];
  citations: SourceCitationRow[];
  sourceDocuments: SourceDocumentSummary[];
};
