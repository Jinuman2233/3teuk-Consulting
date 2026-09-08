import "server-only";

function assertServerRuntime(): void {
  if (typeof document !== "undefined") {
    throw new Error("Supabase env must be read on the server");
  }
}

export class SupabaseConfigError extends Error {
  readonly code = "MISSING_CONFIG";

  constructor(message: string) {
    super(message);
    this.name = "SupabaseConfigError";
  }
}

export const SUPABASE_URL_ENV = "NEXT_PUBLIC_SUPABASE_URL";
export const SUPABASE_PUBLISHABLE_KEY_ENV = "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY";
export const SUPABASE_ANON_KEY_ENV = "NEXT_PUBLIC_SUPABASE_ANON_KEY";

export type SupabasePublicEnv = {
  url: string;
  publicKey: string;
  publicKeySource:
    | typeof SUPABASE_PUBLISHABLE_KEY_ENV
    | typeof SUPABASE_ANON_KEY_ENV;
};

function decodeJwtPayload(token: string): { role?: unknown } | null {
  const parts = token.split(".");
  if (parts.length !== 3 || !parts[1]) {
    return null;
  }

  try {
    const json = Buffer.from(parts[1], "base64url").toString("utf8");
    const payload: unknown = JSON.parse(json);
    if (payload !== null && typeof payload === "object") {
      return payload as { role?: unknown };
    }
    return null;
  } catch {
    return null;
  }
}

function assertPublicReadKey(key: string): void {
  if (key.startsWith("sb_secret_")) {
    throw new SupabaseConfigError(
      "Refusing a secret key. Application reads must use the publishable or anon key.",
    );
  }

  const payload = decodeJwtPayload(key);
  if (payload?.role === "service_role") {
    throw new SupabaseConfigError(
      "Refusing a service_role key. Application reads must use the publishable or anon key.",
    );
  }
}

export function getSupabasePublicEnv(): SupabasePublicEnv {
  assertServerRuntime();

  const url = process.env[SUPABASE_URL_ENV]?.trim();
  const publishable = process.env[SUPABASE_PUBLISHABLE_KEY_ENV]?.trim();
  const anon = process.env[SUPABASE_ANON_KEY_ENV]?.trim();

  if (!url) {
    throw new SupabaseConfigError(`${SUPABASE_URL_ENV} is not set`);
  }

  if (publishable) {
    assertPublicReadKey(publishable);
    return {
      url,
      publicKey: publishable,
      publicKeySource: SUPABASE_PUBLISHABLE_KEY_ENV,
    };
  }

  if (anon) {
    assertPublicReadKey(anon);
    return {
      url,
      publicKey: anon,
      publicKeySource: SUPABASE_ANON_KEY_ENV,
    };
  }

  throw new SupabaseConfigError(
    `${SUPABASE_PUBLISHABLE_KEY_ENV} or ${SUPABASE_ANON_KEY_ENV} is not set`,
  );
}
