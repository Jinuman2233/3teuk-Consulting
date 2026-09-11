import Link from "next/link";
import { notFound } from "next/navigation";
import { CitationDisclosure } from "@/components/admissions/CitationDisclosure";
import { getAdmissionProgramDetailReadModel } from "@/lib/admissions";
import type {
  ScheduleWithProvenance,
  SectionWithProvenance,
  SourceDocumentSummary,
} from "@/lib/admissions";

export const dynamic = "force-dynamic";

function parseAcademicYearParam(raw: string): number | null {
  if (!/^[0-9]+$/.test(raw)) {
    return null;
  }
  const academicYear = Number(raw);
  if (!Number.isInteger(academicYear) || academicYear <= 0) {
    return null;
  }
  return academicYear;
}

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

function scheduleWindowLabel(
  schedule: ScheduleWithProvenance["schedule"],
): string | null {
  if (schedule.temporal_precision === "date") {
    const start = schedule.start_date;
    const end = schedule.end_date;
    if (start && end) {
      return `${start} ~ ${end}`;
    }
    return start ?? end;
  }

  const start = schedule.start_at;
  const end = schedule.end_at;
  if (start && end) {
    return `${start} ~ ${end}`;
  }
  return start ?? end;
}

function SectionArticle({
  item,
  sourcesById,
}: {
  item: SectionWithProvenance;
  sourcesById: Record<string, SourceDocumentSummary>;
}) {
  const { section } = item;

  return (
    <article className="flex flex-col gap-2 rounded-lg border border-zinc-200 px-4 py-4 dark:border-zinc-800">
      <h3 className="text-base font-medium leading-7">{section.title}</h3>
      <p className="whitespace-pre-wrap text-sm leading-6 text-zinc-700 dark:text-zinc-300">
        {section.content}
      </p>
      {section.applicability_text ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {section.applicability_text}
        </p>
      ) : null}
      <CitationDisclosure
        citations={item.citations}
        sourcesById={sourcesById}
      />
    </article>
  );
}

function ScheduleArticle({
  item,
  sourcesById,
}: {
  item: ScheduleWithProvenance;
  sourcesById: Record<string, SourceDocumentSummary>;
}) {
  const { schedule } = item;
  const windowLabel = scheduleWindowLabel(schedule);

  return (
    <article className="flex flex-col gap-2 rounded-lg border border-zinc-200 px-4 py-4 dark:border-zinc-800">
      <h3 className="text-base font-medium leading-7">{schedule.event_name}</h3>
      {windowLabel ? (
        <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
          {windowLabel}
        </p>
      ) : null}
      {schedule.timezone ? (
        <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
          {schedule.timezone}
        </p>
      ) : null}
      {schedule.location_text ? (
        <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
          {schedule.location_text}
        </p>
      ) : null}
      {schedule.description ? (
        <p className="whitespace-pre-wrap text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {schedule.description}
        </p>
      ) : null}
      <CitationDisclosure
        citations={item.citations}
        sourcesById={sourcesById}
      />
    </article>
  );
}

function LoadError() {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-12">
      <h1 className="text-2xl font-semibold tracking-tight">전형 상세</h1>
      <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
        전형 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.
      </p>
    </main>
  );
}

export default async function AdmissionDetailPage({
  params,
}: PageProps<"/universities/[slug]/admissions/[academicYear]/[admissionSlug]">) {
  const { slug, academicYear: academicYearParam, admissionSlug } =
    await params;
  const academicYear = parseAcademicYearParam(academicYearParam);
  if (academicYear === null) {
    notFound();
  }

  let detail;
  try {
    detail = await getAdmissionProgramDetailReadModel(
      slug,
      academicYear,
      admissionSlug,
    );
  } catch (error) {
    console.error("Failed to load admission program detail", error);
    return <LoadError />;
  }

  if (!detail) {
    notFound();
  }

  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-8 px-6 py-12">
      <header className="flex flex-col gap-4">
        <Link
          href={`/universities/${slug}`}
          className="text-sm font-medium text-zinc-700 underline-offset-4 hover:underline dark:text-zinc-300"
        >
          대학 상세로
        </Link>
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {detail.university.display_name}
        </p>
        <h1 className="text-2xl font-semibold tracking-tight">
          {detail.program.official_program_name}
        </h1>
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          {`${detail.program.academic_year}학년도`}
        </p>
        <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
          검증 상태: {verificationStatusLabel(detail.program.verification_status)}
        </p>
      </header>

      <section aria-labelledby="admission-sections-heading" className="flex flex-col gap-4">
        <h2 id="admission-sections-heading" className="text-lg font-semibold tracking-tight">
          전형 정보
        </h2>
        {detail.sections.length === 0 ? (
          <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
            현재 플랫폼에 등록된 전형 세부 정보가 없습니다.
          </p>
        ) : (
          <ul className="flex flex-col gap-3">
            {detail.sections.map((item) => (
              <li key={item.section.id}>
                <SectionArticle
                  item={item}
                  sourcesById={detail.sourcesById}
                />
              </li>
            ))}
          </ul>
        )}
      </section>

      <section aria-labelledby="admission-schedules-heading" className="flex flex-col gap-4">
        <h2 id="admission-schedules-heading" className="text-lg font-semibold tracking-tight">
          일정
        </h2>
        {detail.schedules.length === 0 ? (
          <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
            현재 플랫폼에 등록된 전형 일정 정보가 없습니다.
          </p>
        ) : (
          <ul className="flex flex-col gap-3">
            {detail.schedules.map((item) => (
              <li key={item.schedule.id}>
                <ScheduleArticle
                  item={item}
                  sourcesById={detail.sourcesById}
                />
              </li>
            ))}
          </ul>
        )}
      </section>

      <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
        {`연결된 출처 ${detail.programSources.length}건`}
      </p>

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
