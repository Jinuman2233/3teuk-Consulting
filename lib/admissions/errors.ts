export type AdmissionsQueryErrorCode = "QUERY_FAILED" | "INVALID_ARGUMENT";

export class AdmissionsQueryError extends Error {
  readonly code: AdmissionsQueryErrorCode;
  readonly cause?: unknown;

  constructor(
    code: AdmissionsQueryErrorCode,
    message: string,
    options?: { cause?: unknown },
  ) {
    super(message);
    this.name = "AdmissionsQueryError";
    this.code = code;
    this.cause = options?.cause;
  }
}
