import fs from "node:fs";
import path from "node:path";
import type { Alternates, Lang } from "@/lib/i18n";
import { PATHS } from "@/lib/i18n";
import { COURSES, LEVELS, LEVEL_SLUG, courseById, type CourseInfo, type Level } from "./catalog";

export { COURSES, LEVELS, LEVEL_NAME, LEVEL_SLUG, courseById } from "./catalog";
export type { CourseInfo, Level } from "./catalog";

/** Los textos de una lección en un idioma (lesson.json). */
export type LessonText = {
  slug: string;
  title: string;
  summary: string;
  body: string[];
  points: string[];
  exercise: string;
};

/** Una lección tal como la deja scripts/build-courses.mjs. */
export type Lesson = {
  n: number;
  es: LessonText;
  en: LessonText;
  code: string;
  /** El código resaltado (Shiki, tema dark-plus). */
  html: string;
  input?: string;
  /** Lo que escribe el programa al ejecutarlo de verdad. */
  output: string;
  image: string;
  /** Ancho y alto de la imagen. */
  size?: [number, number];
};

type CourseData = { id: string; levels: Partial<Record<Level, Lesson[]>> };

const DATA = path.join(process.cwd(), "content", "courses", "data");
const cache = new Map<string, CourseData | null>();

/** Las lecciones del curso [id] (vacío si aún no tiene). */
function dataOf(id: string): CourseData | null {
  if (!cache.has(id)) {
    const file = path.join(DATA, `${id}.json`);
    cache.set(id, fs.existsSync(file) ? (JSON.parse(fs.readFileSync(file, "utf8")) as CourseData) : null);
  }
  return cache.get(id) ?? null;
}

export const lessonsOf = (id: string, level: Level): Lesson[] => dataOf(id)?.levels[level] ?? [];

/** ¿Tiene ya lecciones el nivel? */
export const hasLevel = (id: string, level: Level) => lessonsOf(id, level).length > 0;

/** Los cursos que ya tienen alguna lección. */
export const publishedCourses = (): CourseInfo[] => COURSES.filter((c) => LEVELS.some((l) => hasLevel(c.id, l)));

export const levelBySlug = (lang: Lang, slug: string): Level | undefined =>
  LEVELS.find((l) => LEVEL_SLUG[l][lang] === slug);

// --------------------------------------------------------------- rutas

export const coursesPath = (lang: Lang) => PATHS.courses[lang];
export const coursePath = (lang: Lang, id: string) => `${PATHS.courses[lang]}/${id}`;
export const levelPath = (lang: Lang, id: string, level: Level) =>
  `${coursePath(lang, id)}/${LEVEL_SLUG[level][lang]}`;
export const lessonPath = (lang: Lang, id: string, level: Level, lesson: Lesson) =>
  `${levelPath(lang, id, level)}/${lesson[lang].slug}`;

export const courseAlternates = (id: string): Alternates => ({ es: coursePath("es", id), en: coursePath("en", id) });
export const levelAlternates = (id: string, level: Level): Alternates => ({
  es: levelPath("es", id, level),
  en: levelPath("en", id, level),
});
export const lessonAlternates = (id: string, level: Level, lesson: Lesson): Alternates => ({
  es: lessonPath("es", id, level, lesson),
  en: lessonPath("en", id, level, lesson),
});

/** Para generateStaticParams: cada curso publicado. */
export const courseParams = () => publishedCourses().map((c) => ({ course: c.id }));

/** Para generateStaticParams: cada nivel con lecciones, en [lang]. */
export const levelParams = (lang: Lang) =>
  publishedCourses().flatMap((c) =>
    LEVELS.filter((l) => hasLevel(c.id, l)).map((l) => ({ course: c.id, level: LEVEL_SLUG[l][lang] })),
  );

/** Para generateStaticParams: cada lección, en [lang]. */
export const lessonParams = (lang: Lang) =>
  publishedCourses().flatMap((c) =>
    LEVELS.flatMap((l) =>
      lessonsOf(c.id, l).map((x) => ({ course: c.id, level: LEVEL_SLUG[l][lang], lesson: x[lang].slug })),
    ),
  );

/** La lección de la ruta (o null). */
export function findLesson(lang: Lang, courseId: string, levelSlug: string, lessonSlug: string) {
  const course = courseById(courseId);
  const level = levelBySlug(lang, levelSlug);
  if (!course || !level) return null;
  const lessons = lessonsOf(course.id, level);
  const i = lessons.findIndex((x) => x[lang].slug === lessonSlug);
  return i < 0 ? null : { course, level, lessons, index: i, lesson: lessons[i] };
}
