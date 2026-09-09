import type { SupabaseClient } from "@supabase/supabase-js";

export const FAKE_TABLES = [
  "universities",
  "admission_programs",
  "admission_categories",
  "admission_sections",
  "admission_schedules",
  "required_documents",
  "document_submissions",
  "required_document_choice_groups",
  "required_document_choice_group_items",
  "admission_program_sources",
  "source_documents",
  "source_citations",
  "admission_section_citations",
  "required_document_citations",
  "document_submission_citations",
  "admission_schedule_citations",
] as const;

export type FakeTable = (typeof FAKE_TABLES)[number];

export type FakeDataset = Record<FakeTable, Record<string, unknown>[]>;

export type FakeQueryCall = {
  table: FakeTable;
  columns: string;
  filters: { kind: "eq" | "in"; column: string; value: unknown }[];
  orders: string[];
  maybeSingle: boolean;
};

const ALLOWED_FILTER_COLUMNS: Record<FakeTable, ReadonlySet<string>> = {
  universities: new Set(["slug"]),
  admission_programs: new Set([
    "university_id",
    "academic_year",
    "admission_slug",
  ]),
  admission_categories: new Set(["id"]),
  admission_sections: new Set(["admission_program_id"]),
  admission_schedules: new Set(["admission_program_id"]),
  required_documents: new Set(["admission_program_id"]),
  document_submissions: new Set(["required_document_id"]),
  required_document_choice_groups: new Set(["admission_program_id"]),
  required_document_choice_group_items: new Set(["choice_group_id"]),
  admission_program_sources: new Set(["admission_program_id"]),
  source_documents: new Set(["id"]),
  source_citations: new Set(["id"]),
  admission_section_citations: new Set(["admission_section_id"]),
  required_document_citations: new Set(["required_document_id"]),
  document_submission_citations: new Set(["document_submission_id"]),
  admission_schedule_citations: new Set(["admission_schedule_id"]),
};

export type FakeClientOptions = {
  dataset: FakeDataset;
  queryErrors?: Partial<Record<FakeTable, { message: string }>>;
  injectAfterFilter?: Partial<FakeDataset>;
};

export type StrictFakeClient = {
  client: SupabaseClient;
  calls: FakeQueryCall[];
};

function isFakeTable(table: string): table is FakeTable {
  return (FAKE_TABLES as readonly string[]).includes(table);
}

function forbidWrite(method: string): never {
  throw new Error(`Fake admissions client forbids ${method}`);
}

function rowValue(row: Record<string, unknown>, column: string): unknown {
  return row[column];
}

function applyFilters(
  rows: Record<string, unknown>[],
  filters: FakeQueryCall["filters"],
): Record<string, unknown>[] {
  return rows.filter((row) =>
    filters.every((filter) => {
      const value = rowValue(row, filter.column);
      if (filter.kind === "eq") {
        return value === filter.value;
      }
      if (!Array.isArray(filter.value)) {
        throw new Error(`.in() value must be an array`);
      }
      return filter.value.includes(value);
    }),
  );
}

class FakeQueryBuilder implements PromiseLike<{
  data: unknown;
  error: { message: string } | null;
}> {
  private readonly filters: FakeQueryCall["filters"] = [];
  private readonly orders: string[] = [];
  private columns: string | null = null;

  constructor(
    private readonly table: FakeTable,
    private readonly options: FakeClientOptions,
    private readonly calls: FakeQueryCall[],
  ) {}

  select(columns: string): this {
    this.columns = columns;
    return this;
  }

  eq(column: string, value: unknown): this {
    this.assertFilterColumn(column);
    this.filters.push({ kind: "eq", column, value });
    return this;
  }

  in(column: string, value: unknown[]): this {
    this.assertFilterColumn(column);
    if (value.length === 0) {
      throw new Error(`Unexpected empty .in() on ${this.table}.${column}`);
    }
    this.filters.push({ kind: "in", column, value });
    return this;
  }

  order(column: string): this {
    this.orders.push(column);
    return this;
  }

  maybeSingle(): Promise<{ data: unknown; error: { message: string } | null }> {
    return this.execute(true);
  }

  then<TResult1 = { data: unknown; error: { message: string } | null }, TResult2 = never>(
    onfulfilled?:
      | ((
          value: { data: unknown; error: { message: string } | null },
        ) => TResult1 | PromiseLike<TResult1>)
      | null,
    onrejected?: ((reason: unknown) => TResult2 | PromiseLike<TResult2>) | null,
  ): Promise<TResult1 | TResult2> {
    return this.execute(false).then(onfulfilled, onrejected);
  }

  insert(): never {
    return forbidWrite("insert");
  }

  update(): never {
    return forbidWrite("update");
  }

  delete(): never {
    return forbidWrite("delete");
  }

  upsert(): never {
    return forbidWrite("upsert");
  }

  private assertFilterColumn(column: string): void {
    if (!ALLOWED_FILTER_COLUMNS[this.table].has(column)) {
      throw new Error(
        `Unexpected filter column ${column} on ${this.table}`,
      );
    }
  }

  private execute(
    maybeSingle: boolean,
  ): Promise<{ data: unknown; error: { message: string } | null }> {
    if (!this.columns) {
      throw new Error(`select() was not called for ${this.table}`);
    }

    this.calls.push({
      table: this.table,
      columns: this.columns,
      filters: [...this.filters],
      orders: [...this.orders],
      maybeSingle,
    });

    const queryError = this.options.queryErrors?.[this.table];
    if (queryError) {
      return Promise.resolve({ data: null, error: queryError });
    }

    const injected = this.options.injectAfterFilter?.[this.table] ?? [];
    const filtered = applyFilters(
      this.options.dataset[this.table],
      this.filters,
    );
    const rows = [...filtered, ...injected];

    if (maybeSingle) {
      return Promise.resolve({ data: rows[0] ?? null, error: null });
    }
    return Promise.resolve({ data: rows, error: null });
  }
}

/**
 * Isolated test-only cast. Production types are unchanged.
 * Unexpected tables, filter columns, empty .in(), and writes fail.
 */
export function createStrictFakeClient(
  options: FakeClientOptions,
): StrictFakeClient {
  const calls: FakeQueryCall[] = [];

  const client = {
    from(table: string) {
      if (!isFakeTable(table)) {
        throw new Error(`Unexpected table ${table}`);
      }
      return new FakeQueryBuilder(table, options, calls);
    },
    rpc() {
      return forbidWrite("rpc");
    },
    get storage() {
      return forbidWrite("storage");
    },
    channel() {
      return forbidWrite("realtime");
    },
  };

  return { client: client as unknown as SupabaseClient, calls };
}

export function cloneDataset(dataset: FakeDataset): FakeDataset {
  return structuredClone(dataset);
}

export function queryTables(calls: readonly FakeQueryCall[]): FakeTable[] {
  return calls.map((call) => call.table);
}
