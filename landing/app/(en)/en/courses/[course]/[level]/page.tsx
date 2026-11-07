import { notFound } from "next/navigation";
import { LevelPage, ProjectPage } from "@/components/courses";
import {
  LEVEL_NAME,
  PROJECT_SLUG,
  courseById,
  lessonsOf,
  levelAlternates,
  levelBySlug,
  levelParams,
  projectAlternates,
  projectOf,
} from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("en");

export const dynamicParams = false;
export const generateStaticParams = () => levelParams("en");

/** Un nivel o, en su lugar, el proyecto con el IDE ({PROJECT_SLUG}). */
async function find(params: PageProps<"/en/courses/[course]/[level]">["params"]) {
  const p = await params;
  const course = courseById(p.course);
  if (!course) return null;
  const project = p.level === PROJECT_SLUG.en ? projectOf(course.id) : null;
  if (project) return { course, project, level: null };
  const level = levelBySlug("en", p.level);
  return level ? { course, level, project: null } : null;
}

export async function generateMetadata({ params }: PageProps<"/en/courses/[course]/[level]">) {
  const f = await find(params);
  if (!f) return {};
  if (f.project) {
    return pageMetadata("en", {
      title: `${fill(ui.projectTitle, f.project.en.title)} · ${f.course.name}`,
      description: f.project.en.summary,
      paths: projectAlternates(f.course.id),
      image: f.project.app.src,
    });
  }
  const name = LEVEL_NAME[f.level!].en;
  return pageMetadata("en", {
    title: fill(ui.levelTitle, f.course.name, name),
    description: fill(ui.levelMeta, f.course.name, name, lessonsOf(f.course.id, f.level!).length),
    paths: levelAlternates(f.course.id, f.level!),
  });
}

export default async function Page({ params }: PageProps<"/en/courses/[course]/[level]">) {
  const f = await find(params);
  if (!f) notFound();
  if (f.project) return <ProjectPage lang="en" course={f.course} project={f.project} />;
  return <LevelPage lang="en" course={f.course} level={f.level!} />;
}
