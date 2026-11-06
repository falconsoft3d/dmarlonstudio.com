import { notFound } from "next/navigation";
import { LevelPage } from "@/components/courses";
import { LEVEL_NAME, courseById, lessonsOf, levelAlternates, levelBySlug, levelParams } from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("es");

export const dynamicParams = false;
export const generateStaticParams = () => levelParams("es");

async function find(params: PageProps<"/cursos/[course]/[level]">["params"]) {
  const p = await params;
  const course = courseById(p.course);
  const level = levelBySlug("es", p.level);
  return course && level ? { course, level } : null;
}

export async function generateMetadata({ params }: PageProps<"/cursos/[course]/[level]">) {
  const f = await find(params);
  if (!f) return {};
  const name = LEVEL_NAME[f.level].es.toLowerCase();
  return pageMetadata("es", {
    title: fill(ui.levelTitle, f.course.name, name),
    description: fill(ui.levelMeta, f.course.name, name, lessonsOf(f.course.id, f.level).length),
    paths: levelAlternates(f.course.id, f.level),
  });
}

export default async function Page({ params }: PageProps<"/cursos/[course]/[level]">) {
  const f = await find(params);
  if (!f) notFound();
  return <LevelPage lang="es" course={f.course} level={f.level} />;
}
