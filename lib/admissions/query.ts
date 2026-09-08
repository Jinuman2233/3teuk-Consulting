import "server-only";

import type { SupabaseClient } from "@supabase/supabase-js";
import { createSupabaseReadClient } from "../supabase/read-client";
import { AdmissionsQueryError } from "./errors";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function assertServerRuntime(): void {
  if (typeof document !== "undefined") {
    throw new Error("Admissions read queries must run on the server");
  }
}

export function requireNonEmptyString(value: string, name: string): string {
  const trimmed = value.trim();
  if (!trimmed) {
    throw new AdmissionsQueryError(
      "INVALID_ARGUMENT",
      `${name} must be a non-empty string`,
    );
  }
  return trimmed;
}

export function requireUniversityId(universityId: string): string {
  const id = requireNonEmptyString(universityId, "universityId");
  if (!UUID_RE.test(id)) {
    throw new AdmissionsQueryError(
      "INVALID_ARGUMENT",
      "universityId must be a UUID",
    );
  }
  return id;
}

export function requireAcademicYear(academicYear: number): number {
  if (!Number.isInteger(academicYear)) {
    throw new AdmissionsQueryError(
      "INVALID_ARGUMENT",
      "academicYear must be an integer",
    );
  }
  return academicYear;
}

export function throwIfQueryError(
  error: { message: string } | null,
  context: string,
): void {
  if (error) {
    throw new AdmissionsQueryError(
      "QUERY_FAILED",
      `${context}: ${error.message}`,
      { cause: error },
    );
  }
}

export function getClient(client?: SupabaseClient): SupabaseClient {
  assertServerRuntime();
  return client ?? createSupabaseReadClient();
}

export function uniqueIds(ids: readonly string[]): string[] {
  return [...new Set(ids)];
}
