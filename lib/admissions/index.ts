import "server-only";

export {
  getAdmissionProgramDetail,
  getAdmissionProgramsByUniversity,
  getUniversities,
  getUniversityBySlug,
  AdmissionsQueryError,
} from "./repository";
export type {
  AdmissionProgramDetail,
  AdmissionProgramRow,
  InformationType,
  UniversityRow,
  VerificationStatus,
} from "./repository";
