import "server-only";

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { getSupabasePublicEnv } from "./env";

function assertServerRuntime(): void {
  if (typeof document !== "undefined") {
    throw new Error("Supabase read client must be created on the server");
  }
}

/**
 * Public-key, SELECT-oriented Supabase client for server runtimes.
 * App code should import from `./server`.
 *
 * fetch uses cache: "no-store" so Next.js Data Cache does not serve
 * stale admissions rows. Accuracy/freshness over ISR in this layer.
 */
export function createSupabaseReadClient(): SupabaseClient {
  assertServerRuntime();

  const { url, publicKey } = getSupabasePublicEnv();

  return createClient(url, publicKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: {
      fetch: (input, init) => fetch(input, { ...init, cache: "no-store" }),
    },
  });
}
