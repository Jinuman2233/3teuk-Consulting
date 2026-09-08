import Link from "next/link";
import { notFound } from "next/navigation";
import {
  getAdmissionProgramsByUniversity,
  getUniversityBySlug,
} from "@/lib/admissions";
import type { AdmissionProgramRow } from "@/lib/admissions";

export const dynamic = "force-dynamic";

const MVP_ACADEMIC_YEAR = 2027;

function verificationStatusLabel(status: string): string {
  switch (status) {
    case "verified":
      return "데이터 검토 완료";
    case "partially_verified":
      return "일부 항목 추가 확인 필요";
    case "needs_review":
      return "검토 필요";
    case "unverified":
      return "미검증";
    default:
      return "확인 필요";
  }
}

export default async function UniversityDetailPage({
  params,
}: PageProps<"/universities/[slug]">) {
  const { slug } = await params;

  let university;
  try {
    university = await getUniversityBySlug(slug);
  } catch (error) {
    console.error("Failed to load university", error);
    return (
      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-12">
        <h1 className="text-2xl font-semibold tracking-tight">대학 상세</h1>
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          대학 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
        </p>
      </main>
    );
  }

  if (!university) {
    notFound();
  }

  let programs: AdmissionProgramRow[] | null = null;
  let programsFailed = false;
  try {
    programs = await getAdmissionProgramsByUniversity(
      university.id,
      MVP_ACADEMIC_YEAR,
    );
  } catch (error) {
    console.error("Failed to load admission programs", error);
    programsFailed = true;
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-8 px-6 py-12">
      <header className="flex flex-col gap-4">
        <Link
          href="/universities"
          className="text-sm font-medium text-zinc-700 underline-offset-4 hover:underline dark:text-zinc-300"
        >
          대학 목록으로
        </Link>
        <h1 className="text-2xl font-semibold tracking-tight">
          {university.display_name}
        </h1>
      </header>

      <section aria-labelledby="academic-year-heading" className="flex flex-col gap-4">
        <h2 id="academic-year-heading" className="text-lg font-semibold tracking-tight">
          {MVP_ACADEMIC_YEAR}학년도 전형
        </h2>

        {programsFailed ? (
          <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
            전형 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
          </p>
        ) : programs && programs.length === 0 ? (
          <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
            현재 플랫폼에 등록된 {MVP_ACADEMIC_YEAR}학년도 전형 정보가 없습니다.
          </p>
        ) : (
          <ul className="flex flex-col gap-3">
            {programs?.map((program) => (
              <li
                key={program.id}
                className="flex flex-col gap-2 rounded-lg border border-zinc-200 px-4 py-4 dark:border-zinc-800"
              >
                <p className="text-lg font-medium leading-7">
                  {program.official_program_name}
                </p>
                <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
                  검증 상태: {verificationStatusLabel(program.verification_status)}
                </p>
              </li>
            ))}
          </ul>
        )}
      </section>

      <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
        검증 상태는 이 플랫폼의 데이터 검토 상태이며, 대학의 공식 지원 자격
        판정을 의미하지 않습니다.
      </p>
      <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
        입시 정보는 학년도별 공식 자료를 기준으로 제공합니다.
      </p>
    </main>
  );
}
