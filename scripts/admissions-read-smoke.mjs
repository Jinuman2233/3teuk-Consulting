/**
 * SELECT-only hosted smoke for the admissions read layer.
 *
 * This script talks to Supabase with the public (publishable/anon) key only.
 * It does not import Next.js `server-only` modules (those cannot run in Node).
 * Column lists must stay aligned with lib/admissions/columns.ts.
 *
 * Usage:
 *   cp .env.example .env.local   # fill URL + public key
 *   npm run admissions:smoke
 *
 * Never pass service_role. This script never calls insert/update/delete/upsert.
 */

import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { createClient } from "@supabase/supabase-js";

const UNIVERSITIES_TABLE = "universities";
const ADMISSION_PROGRAMS_TABLE = "admission_programs";
const UNIVERSITY_COLUMNS =
  "id, name_ko, name_en, campus_name, display_name, slug, official_website_url, admissions_office_url, created_at, updated_at";
const ADMISSION_PROGRAM_COLUMNS =
  "id, university_id, admission_category_id, academic_year, official_program_name, display_name, admission_slug, information_type, verification_status, verified_at, notes, created_at, updated_at";

function loadEnvLocal() {
  const path = resolve(process.cwd(), ".env.local");
  if (!existsSync(path)) {
    return;
  }
  const text = readFileSync(path, "utf8");
  for (const rawLine of text.split("\n")) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }
    const eq = line.indexOf("=");
    if (eq === -1) {
      continue;
    }
    const key = line.slice(0, eq).trim();
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}

function requirePublicEnv() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL?.trim();
  const publishable = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY?.trim();
  const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY?.trim();
  const publicKey = publishable || anon;

  if (!url || !publicKey) {
    throw new Error(
      "Missing NEXT_PUBLIC_SUPABASE_URL and NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY (or NEXT_PUBLIC_SUPABASE_ANON_KEY). Hosted smoke not run.",
    );
  }

  if (publicKey.startsWith("sb_secret_")) {
    throw new Error("Refusing secret key for smoke test");
  }

  const parts = publicKey.split(".");
  if (parts.length === 3 && parts[1]) {
    try {
      const json = Buffer.from(parts[1], "base64url").toString("utf8");
      const payload = JSON.parse(json);
      if (payload?.role === "service_role") {
        throw new Error("Refusing service_role key for smoke test");
      }
    } catch (error) {
      if (error instanceof Error && error.message.startsWith("Refusing")) {
        throw error;
      }
    }
  }

  return { url, publicKey };
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function main() {
  loadEnvLocal();
  const { url, publicKey } = requirePublicEnv();

  const supabase = createClient(url, publicKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: {
      fetch: (input, init) => fetch(input, { ...init, cache: "no-store" }),
    },
  });

  const universitiesResult = await supabase
    .from(UNIVERSITIES_TABLE)
    .select(UNIVERSITY_COLUMNS)
    .order("name_ko", { ascending: true })
    .order("campus_name", { ascending: true })
    .order("slug", { ascending: true });

  if (universitiesResult.error) {
    throw new Error(`getUniversities failed: ${universitiesResult.error.message}`);
  }

  const universities = universitiesResult.data ?? [];
  const koreaSeoul = universities.find((row) => row.slug === "korea-seoul");
  assert(koreaSeoul, "getUniversities did not return slug korea-seoul");
  assert(
    koreaSeoul.name_ko === "고려대학교",
    `unexpected name_ko: ${koreaSeoul.name_ko}`,
  );
  assert(
    koreaSeoul.campus_name === "서울캠퍼스",
    `unexpected campus_name: ${koreaSeoul.campus_name}`,
  );
  assert(
    koreaSeoul.display_name === "고려대학교 서울캠퍼스",
    `unexpected display_name: ${koreaSeoul.display_name}`,
  );
  console.log("PASS getUniversities → 고려대학교 서울캠퍼스");

  const programsResult = await supabase
    .from(ADMISSION_PROGRAMS_TABLE)
    .select(ADMISSION_PROGRAM_COLUMNS)
    .eq("university_id", koreaSeoul.id)
    .eq("academic_year", 2027)
    .order("academic_year", { ascending: false })
    .order("admission_slug", { ascending: true });

  if (programsResult.error) {
    throw new Error(
      `getAdmissionProgramsByUniversity failed: ${programsResult.error.message}`,
    );
  }

  const programs = programsResult.data ?? [];
  const overseas = programs.find(
    (row) => row.admission_slug === "overseas-korean-2pct",
  );
  assert(overseas, "2027 programs did not include overseas-korean-2pct");
  assert(overseas.academic_year === 2027, "academic_year was mixed or missing");
  assert(
    overseas.official_program_name === "재외국민(정원외2%)전형",
    `unexpected official_program_name: ${overseas.official_program_name}`,
  );
  assert(
    overseas.verification_status === "partially_verified",
    `unexpected verification_status: ${overseas.verification_status}`,
  );
  console.log(
    "PASS getAdmissionProgramsByUniversity(korea-seoul, 2027) → overseas-korean-2pct",
  );

  const detailUniversity = await supabase
    .from(UNIVERSITIES_TABLE)
    .select(UNIVERSITY_COLUMNS)
    .eq("slug", "korea-seoul")
    .maybeSingle();
  if (detailUniversity.error) {
    throw new Error(`detail university lookup failed: ${detailUniversity.error.message}`);
  }
  assert(detailUniversity.data, "getUniversityBySlug(korea-seoul) returned empty");

  const detailProgram = await supabase
    .from(ADMISSION_PROGRAMS_TABLE)
    .select(ADMISSION_PROGRAM_COLUMNS)
    .eq("university_id", detailUniversity.data.id)
    .eq("academic_year", 2027)
    .eq("admission_slug", "overseas-korean-2pct")
    .maybeSingle();
  if (detailProgram.error) {
    throw new Error(`detail program lookup failed: ${detailProgram.error.message}`);
  }
  assert(detailProgram.data, "getAdmissionProgramDetail returned empty");
  assert(detailProgram.data.academic_year === 2027, "detail mixed academic_year");
  console.log(
    "PASS getAdmissionProgramDetail(korea-seoul, 2027, overseas-korean-2pct)",
  );

  console.log("SELECT-only hosted smoke PASS");
}

main().catch((error) => {
  console.error("SELECT-only hosted smoke FAIL");
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
