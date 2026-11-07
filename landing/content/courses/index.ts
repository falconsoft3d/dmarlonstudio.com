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
  /** Abre ventanas (tkinter): la imagen es la ventana de verdad. */
  gui?: boolean;
  /** Ancho y alto de la imagen. */
  size?: [number, number];
  /** Base de datos: el resultado de cada consulta del script. */
  results?: DbResult[];
  /** La consulta que falla a propósito (la última). */
  error?: { index: number; message: string };
  /** Tablas o colecciones al terminar. */
  schema?: string[];
  /** FalconDatabase: el usuario con el que entra (ana, luis o anon). */
  as?: string;
};

/** Lo que muestra el módulo Bases de datos tras una consulta. */
export type DbResult = {
  columns?: string[];
  rows?: (string | number | boolean | null)[][];
  message?: string;
  message_en?: string;
  affected?: number;
};

type CourseData = { id: string; levels: Partial<Record<Level, Lesson[]>> };

/** El proyecto con el IDE de un curso de base de datos
 * (content/courses/projects/<curso>.json). */
export type ProjectText = { title: string; summary: string; intro: string[]; steps: string[]; points: string[] };
export type CourseProject = {
  seed: string;
  /** El destino del estudio («Escritorio (Python)», «Flutter (móvil)»…). */
  target: Record<Lang, string>;
  es: ProjectText;
  en: ProjectText;
  /** El código que se escribe (la unidad), no el generado. */
  files: { name: string; lang: string; code: string; html?: string }[];
  /** El proyecto abierto en el Diseñador, en cada idioma. */
  designer: { es: string; en: string; size: [number, number] };
  /** La app funcionando con los datos del curso. */
  app: { src: string; size: [number, number] };
  /** La carpeta del proyecto, para «Abrir proyecto». */
  download: string;
};

/** La parte de la ruta del proyecto (en el lugar del nivel). */
export const PROJECT_SLUG: Record<Lang, string> = { es: "proyecto", en: "project" };

const PROJECTS = path.join(process.cwd(), "content", "courses", "projects");
const projects = new Map<string, CourseProject | null>();

/** El proyecto del curso [id] (null si no tiene). */
export function projectOf(id: string): CourseProject | null {
  if (!projects.has(id)) {
    const file = path.join(PROJECTS, `${id}.json`);
    projects.set(id, fs.existsSync(file) ? (JSON.parse(fs.readFileSync(file, "utf8")) as CourseProject) : null);
  }
  return projects.get(id) ?? null;
}

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
export const projectPath = (lang: Lang, id: string) => `${coursePath(lang, id)}/${PROJECT_SLUG[lang]}`;
export const projectAlternates = (id: string): Alternates => ({ es: projectPath("es", id), en: projectPath("en", id) });
export const lessonAlternates = (id: string, level: Level, lesson: Lesson): Alternates => ({
  es: lessonPath("es", id, level, lesson),
  en: lessonPath("en", id, level, lesson),
});

/** Para generateStaticParams: cada curso publicado. */
export const courseParams = () => publishedCourses().map((c) => ({ course: c.id }));

/** Para generateStaticParams: cada nivel con lecciones, en [lang]. */
export const levelParams = (lang: Lang) =>
  publishedCourses().flatMap((c) => [
    ...LEVELS.filter((l) => hasLevel(c.id, l)).map((l) => ({ course: c.id, level: LEVEL_SLUG[l][lang] })),
    // El proyecto va en el lugar de un nivel: /cursos/<curso>/proyecto.
    ...(projectOf(c.id) ? [{ course: c.id, level: PROJECT_SLUG[lang] }] : []),
  ]);

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
