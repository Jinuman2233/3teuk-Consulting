export type AdmissionsQueryErrorCode =
  | "QUERY_FAILED"
  | "INVALID_ARGUMENT"
  | "INTEGRITY_VIOLATION";

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

/**
 * Query succeeded, but the assembled graph is internally inconsistent.
 * Distinct from QUERY_FAILED (PostgREST / network / RLS query errors).
 */
export class AdmissionsIntegrityError extends AdmissionsQueryError {
  constructor(message: string, options?: { cause?: unknown }) {
    super("INTEGRITY_VIOLATION", message, options);
    this.name = "AdmissionsIntegrityError";
  }
}
