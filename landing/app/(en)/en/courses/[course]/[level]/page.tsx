import { notFound } from "next/navigation";
import { LevelPage } from "@/components/courses";
import { LEVEL_NAME, courseById, lessonsOf, levelAlternates, levelBySlug, levelParams } from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("en");

export const dynamicParams = false;
export const generateStaticParams = () => levelParams("en");

async function find(params: PageProps<"/en/courses/[course]/[level]">["params"]) {
  const p = await params;
  const course = courseById(p.course);
  const level = levelBySlug("en", p.level);
  return course && level ? { course, level } : null;
}

export async function generateMetadata({ params }: PageProps<"/en/courses/[course]/[level]">) {
  const f = await find(params);
  if (!f) return {};
  const name = LEVEL_NAME[f.level].en;
  return pageMetadata("en", {
    title: fill(ui.levelTitle, f.course.name, name),
    description: fill(ui.levelMeta, f.course.name, name, lessonsOf(f.course.id, f.level).length),
    paths: levelAlternates(f.course.id, f.level),
  });
}

export default async function Page({ params }: PageProps<"/en/courses/[course]/[level]">) {
  const f = await find(params);
  if (!f) notFound();
  return <LevelPage lang="en" course={f.course} level={f.level} />;
}
