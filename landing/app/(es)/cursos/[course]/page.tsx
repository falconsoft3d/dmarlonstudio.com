import { notFound } from "next/navigation";
import { CoursePage } from "@/components/courses";
import { courseAlternates, courseById, courseParams } from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { pageMetadata } from "@/lib/metadata";

const ui = coursesUi("es");

export const dynamicParams = false;
export const generateStaticParams = courseParams;

export async function generateMetadata({ params }: PageProps<"/cursos/[course]">) {
  const course = courseById((await params).course);
  if (!course) return {};
  return pageMetadata("es", {
    title: fill(ui.courseTitle, course.name),
    description: fill(ui.courseMeta, course.name, course.tagline.es),
    paths: courseAlternates(course.id),
  });
}

export default async function Page({ params }: PageProps<"/cursos/[course]">) {
  const course = courseById((await params).course);
  if (!course) notFound();
  return <CoursePage lang="es" course={course} />;
}
