import "server-only";

export {
  getAdmissionProgramDetail,
  getAdmissionProgramsByUniversity,
  getUniversities,
  getUniversityBySlug,
} from "./select";
export { AdmissionsQueryError } from "./errors";
export type {
  AdmissionProgramDetail,
  AdmissionProgramRow,
  InformationType,
  UniversityRow,
  VerificationStatus,
} from "./types";
