import type {
  SourceCitationRow,
  SourceDocumentSummary,
} from "@/lib/admissions";

type CitationDisclosureProps = {
  citations: SourceCitationRow[];
  sourcesById: Record<string, SourceDocumentSummary>;
};

function isNonEmpty(value: string | null | undefined): value is string {
  return typeof value === "string" && value.trim() !== "";
}

function getSafeSourceUrl(value: string): string | null {
  try {
    const url = new URL(value);
    if (url.protocol !== "https:" && url.protocol !== "http:") {
      return null;
    }
    return url.href;
  } catch {
    return null;
  }
}

function utcCalendarDate(value: string): string | null {
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed.toISOString().slice(0, 10);
}

function requireSourceDocument(
  citation: SourceCitationRow,
  sourcesById: Record<string, SourceDocumentSummary>,
): SourceDocumentSummary {
  const source = sourcesById[citation.source_document_id];
  if (!source) {
    throw new Error(
      `Source document ${citation.source_document_id} referenced by citation ${citation.id} was not found in sourcesById`,
    );
  }
  return source;
}

function CitationItem({
  citation,
  source,
}: {
  citation: SourceCitationRow;
  source: SourceDocumentSummary;
}) {
  const safeUrl = getSafeSourceUrl(source.source_url);
  const checkedOnUtc = utcCalendarDate(source.last_checked_at);

  return (
    <li className="flex flex-col gap-1">
      <p className="text-sm leading-6 text-zinc-700 dark:text-zinc-300">
        {source.title}
      </p>
      {isNonEmpty(source.issuing_organization) ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`발행기관: ${source.issuing_organization}`}
        </p>
      ) : null}
      {citation.file_page_number != null ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`PDF 실제 ${citation.file_page_number}페이지`}
        </p>
      ) : null}
      {isNonEmpty(citation.printed_page_label) ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`문서 표기: ${citation.printed_page_label}`}
        </p>
      ) : null}
      {isNonEmpty(citation.section) ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`문서 위치: ${citation.section}`}
        </p>
      ) : null}
      {isNonEmpty(citation.anchor_description) ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`위치 설명: ${citation.anchor_description}`}
        </p>
      ) : null}
      {isNonEmpty(source.published_at) ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`발표일: ${source.published_at}`}
        </p>
      ) : null}
      {checkedOnUtc ? (
        <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
          {`자료 최종 확인(UTC): ${checkedOnUtc}`}
        </p>
      ) : null}
      {safeUrl ? (
        <p className="text-sm leading-6">
          <a
            href={safeUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="font-medium text-zinc-700 underline-offset-4 hover:underline dark:text-zinc-300"
          >
            원문 열기
          </a>
        </p>
      ) : null}
    </li>
  );
}

export function CitationDisclosure({
  citations,
  sourcesById,
}: CitationDisclosureProps) {
  if (citations.length === 0) {
    return (
      <p className="text-sm leading-6 text-zinc-600 dark:text-zinc-400">
        현재 연결된 근거 없음
      </p>
    );
  }

  return (
    <details className="mt-1">
      <summary className="cursor-pointer text-sm font-medium leading-6 text-zinc-700 dark:text-zinc-300">
        {`근거 ${citations.length}건 보기`}
      </summary>
      <ul className="mt-3 flex flex-col gap-4">
        {citations.map((citation) => (
          <CitationItem
            key={citation.id}
            citation={citation}
            source={requireSourceDocument(citation, sourcesById)}
          />
        ))}
      </ul>
    </details>
  );
}
