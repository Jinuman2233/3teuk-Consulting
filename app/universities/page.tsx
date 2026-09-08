import { getUniversities } from "@/lib/admissions";
import type { UniversityRow } from "@/lib/admissions";

export const dynamic = "force-dynamic";

export const metadata = {
  title: "대학전형 찾기",
  description: "대학별·학년도별 전형 정보를 공식 출처 기준으로 탐색하는 화면.",
};

export default async function UniversitiesPage() {
  let universities: UniversityRow[];

  try {
    universities = await getUniversities();
  } catch (error) {
    console.error("Failed to load universities", error);
    return (
      <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-12">
        <h1 className="text-2xl font-semibold tracking-tight">대학전형 찾기</h1>
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          대학 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
        </p>
      </main>
    );
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-8 px-6 py-12">
      <header className="flex flex-col gap-3">
        <h1 className="text-2xl font-semibold tracking-tight">대학전형 찾기</h1>
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          대학별·학년도별 전형 정보를 공식 출처 기준으로 탐색하는 화면.
        </p>
      </header>

      {universities.length === 0 ? (
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          현재 등록된 대학 정보가 없습니다.
        </p>
      ) : (
        <section aria-labelledby="university-list-heading">
          <h2 id="university-list-heading" className="sr-only">
            대학 목록
          </h2>
          <ul className="flex flex-col gap-3">
            {universities.map((university) => (
              <li
                key={university.id}
                className="rounded-lg border border-zinc-200 px-4 py-4 dark:border-zinc-800"
              >
                <p className="text-lg font-medium leading-7">
                  {university.display_name}
                </p>
              </li>
            ))}
          </ul>
        </section>
      )}

      <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
        입시 정보는 학년도별 공식 자료를 기준으로 제공합니다.
      </p>
    </main>
  );
}
