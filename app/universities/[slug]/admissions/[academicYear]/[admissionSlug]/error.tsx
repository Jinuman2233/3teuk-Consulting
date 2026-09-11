"use client";

import Link from "next/link";
import type { ErrorInfo } from "next/error";

export default function AdmissionDetailError({ retry }: ErrorInfo) {
  return (
    <main className="mx-auto flex w-full max-w-3xl flex-1 flex-col gap-6 px-6 py-12">
      <h1 className="text-2xl font-semibold tracking-tight">
        전형 정보를 불러오지 못했습니다.
      </h1>
      <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
        일시적인 문제일 수 있습니다. 잠시 후 다시 시도해 주세요.
      </p>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        <button
          type="button"
          onClick={retry}
          className="inline-flex w-fit items-center rounded-lg border border-zinc-300 px-4 py-2 text-sm font-medium text-zinc-900 dark:border-zinc-700 dark:text-zinc-100"
        >
          다시 시도
        </button>
        <Link
          href="/universities"
          className="text-sm font-medium text-zinc-700 underline-offset-4 hover:underline dark:text-zinc-300"
        >
          대학 목록으로
        </Link>
      </div>
    </main>
  );
}
