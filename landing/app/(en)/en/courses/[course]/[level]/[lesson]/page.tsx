import { notFound } from "next/navigation";
import { LessonPage } from "@/components/courses";
import { LEVEL_NAME, findLesson, lessonAlternates, lessonParams } from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("en");

export const dynamicParams = false;
export const generateStaticParams = () => lessonParams("en");

async function find(params: PageProps<"/en/courses/[course]/[level]/[lesson]">["params"]) {
  const p = await params;
  return findLesson("en", p.course, p.level, p.lesson);
}

export async function generateMetadata({ params }: PageProps<"/en/courses/[course]/[level]/[lesson]">) {
  const f = await find(params);
  if (!f) return {};
  const name = LEVEL_NAME[f.level].en;
  return pageMetadata("en", {
    title: `${f.lesson.en.title} · ${fill(ui.levelTitle, f.course.name, name)}`,
    description: f.lesson.en.summary,
    paths: lessonAlternates(f.course.id, f.level, f.lesson),
    image: f.lesson.image,
  });
}

export default async function Page({ params }: PageProps<"/en/courses/[course]/[level]/[lesson]">) {
  const f = await find(params);
  if (!f) notFound();
  return <LessonPage lang="en" course={f.course} level={f.level} lessons={f.lessons} index={f.index} />;
}
