import { notFound } from "next/navigation";
import { ManualChapter } from "@/components/manual/views";
import { chapterAlternates, manualOf } from "@/content/manual";
import { pageMetadata } from "@/lib/metadata";

const m = manualOf("en");
const indexOf = (slug: string) => m.chapters.findIndex((c) => c.slug === slug);

export const dynamicParams = false;

export function generateStaticParams() {
  return m.chapters.map((c) => ({ slug: c.slug }));
}

export async function generateMetadata({ params }: PageProps<"/en/manual/[slug]">) {
  const i = indexOf((await params).slug);
  if (i < 0) return {};
  const c = m.chapters[i];
  return pageMetadata("en", { title: `${c.title} · ${m.ui.title}`, description: c.summary, paths: chapterAlternates(i) });
}

export default async function Page({ params }: PageProps<"/en/manual/[slug]">) {
  const i = indexOf((await params).slug);
  if (i < 0) notFound();
  return <ManualChapter lang="en" index={i} />;
}
