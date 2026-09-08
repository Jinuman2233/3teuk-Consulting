import "server-only";

export { getAdmissionProgramDetailReadModel } from "./detail-repository";
export {
  getAdmissionProgramDetail,
  getAdmissionProgramsByUniversity,
  getUniversities,
  getUniversityBySlug,
} from "./select";
export { AdmissionsIntegrityError, AdmissionsQueryError } from "./errors";
export type {
  AdmissionProgramDetailReadModel,
  AdmissionCategoryRow,
  AdmissionProgramSourceRow,
  AdmissionScheduleRow,
  AdmissionSectionRow,
  AvailabilityStatus,
  ChoiceGroupWithItems,
  DocumentSubmissionRow,
  DocumentSubmissionWithProvenance,
  RequiredDocumentChoiceGroupItemRow,
  RequiredDocumentChoiceGroupRow,
  RequiredDocumentRow,
  RequiredDocumentWithProvenance,
  ScheduleWithProvenance,
  SectionWithProvenance,
  SourceCitationRow,
  SourceDocumentSummary,
  TemporalPrecision,
} from "./detail-types";
export type {
  AdmissionProgramDetail,
  AdmissionProgramRow,
  InformationType,
  UniversityRow,
  VerificationStatus,
} from "./types";
