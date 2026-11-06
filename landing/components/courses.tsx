import { ArrowLeft, ArrowRight, Download, GraduationCap, Lightbulb, ListChecks, Play, Terminal } from "lucide-react";
import { siC, siCplusplus, siDart, siGo, siJavascript, siLazarus, siPython } from "simple-icons";
import { Inline } from "@/components/manual/rich";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { contentOf } from "@/content";
import {
  COURSES,
  LEVELS,
  LEVEL_NAME,
  courseAlternates,
  coursePath,
  coursesPath,
  hasLevel,
  lessonAlternates,
  lessonPath,
  lessonsOf,
  levelAlternates,
  levelPath,
  type CourseInfo,
  type Lesson,
  type Level,
} from "@/content/courses";
import { coursesUi, fill } from "@/content/courses/ui";
import { HOME, PATHS, type Alternates, type Lang } from "@/lib/i18n";
import { SITE_URL } from "@/lib/site";

const ICONS: Record<string, { path: string; hex: string }> = {
  python: siPython,
  javascript: siJavascript,
  c: siC,
  cpp: siCplusplus,
  pascal: siLazarus,
  go: siGo,
  dart: siDart,
};

/** El logotipo del lenguaje en su color. */
export function CourseIcon({ course, className = "size-8" }: { course: CourseInfo; className?: string }) {
  const icon = ICONS[course.id];
  return (
    <span
      aria-hidden
      className={`inline-flex shrink-0 items-center justify-center rounded-lg ${className}`}
      style={{ background: `${course.color}1f` }}
    >
      {icon && (
        <svg viewBox="0 0 24 24" className="size-[60%]" fill={course.id === "javascript" ? "#c9a800" : course.color}>
          <path d={icon.path} />
        </svg>
      )}
    </span>
  );
}

/** Datos estructurados (schema.org) para Google. */
function JsonLd({ data }: { data: object }) {
  return <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(data) }} />;
}

const levelName = (lang: Lang, level: Level) =>
  lang === "es" ? LEVEL_NAME[level].es.toLowerCase() : LEVEL_NAME[level].en;

function courseLd(lang: Lang, course: CourseInfo, level?: Level) {
  const ui = coursesUi(lang);
  const url = `${SITE_URL}${level ? levelPath(lang, course.id, level) : coursePath(lang, course.id)}`;
  return {
    "@context": "https://schema.org",
    "@type": "Course",
    name: level ? fill(ui.levelTitle, course.name, levelName(lang, level)) : fill(ui.courseTitle, course.name),
    description: course.tagline[lang],
    url,
    inLanguage: lang,
    isAccessibleForFree: true,
    educationalLevel: level ? LEVEL_NAME[level][lang] : ui.levels,
    teaches: course.name,
    provider: { "@type": "Organization", name: "DMarlon Studio", url: SITE_URL },
    offers: { "@type": "Offer", price: 0, priceCurrency: "EUR", category: "Free" },
    hasCourseInstance: {
      "@type": "CourseInstance",
      courseMode: "online",
      courseWorkload: "PT10H",
    },
  };
}

function breadcrumbLd(items: { name: string; path: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((x, i) => ({ "@type": "ListItem", position: i + 1, name: x.name, item: `${SITE_URL}${x.path}` })),
  };
}

function Shell({ lang, alternates, children }: { lang: Lang; alternates: Alternates; children: React.ReactNode }) {
  const t = contentOf(lang);
  return (
    <>
      <SiteHeader lang={lang} t={t} alternates={alternates} />
      <main className="flex-1">{children}</main>
      <SiteFooter lang={lang} t={t} />
    </>
  );
}

function Crumbs({ items }: { items: { name: string; path?: string }[] }) {
  return (
    <nav aria-label="Breadcrumb" className="text-sm text-muted">
      <ol className="flex flex-wrap items-center gap-1.5">
        {items.map((x, i) => (
          <li key={i} className="flex items-center gap-1.5">
            {i > 0 && <span aria-hidden>/</span>}
            {x.path ? (
              <a href={x.path} className="hover:text-ink">
                {x.name}
              </a>
            ) : (
              <span className="text-ink">{x.name}</span>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}

/** El recuadro que lleva al IDE: qué es, cómo se prueba y la descarga. */
function StudioBox({ lang, course }: { lang: Lang; course: CourseInfo }) {
  const ui = coursesUi(lang);
  const t = contentOf(lang);
  return (
    <aside className="rounded-xl border border-accent/30 bg-accent/5 p-5">
      <p className="flex items-center gap-2 font-semibold">
        <Play className="size-4 fill-current text-accent" aria-hidden />
        {ui.tryIt}
      </p>
      <p className="mt-2 text-sm leading-relaxed text-muted">{ui.tryItIntro}</p>
      <ol className="mt-3 list-decimal space-y-1.5 pl-5 text-sm leading-relaxed">
        {course.steps[lang].map((s, i) => (
          <li key={i}>
            <Inline text={s} />
          </li>
        ))}
      </ol>
      <a
        href={`${HOME[lang]}#${t.downloads.id}`}
        className="mt-4 inline-flex items-center gap-2 rounded-md bg-accent px-4 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
      >
        <Download className="size-4" aria-hidden />
        {ui.download}
      </a>
    </aside>
  );
}

// ------------------------------------------------------------- portada

/** /cursos: los siete lenguajes. */
export function CoursesIndex({ lang }: { lang: Lang }) {
  const ui = coursesUi(lang);
  return (
    <Shell lang={lang} alternates={PATHS.courses}>
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "ItemList",
          name: ui.title,
          itemListElement: COURSES.filter((c) => LEVELS.some((l) => hasLevel(c.id, l))).map((c, i) => ({
            "@type": "ListItem",
            position: i + 1,
            url: `${SITE_URL}${coursePath(lang, c.id)}`,
            name: fill(ui.courseTitle, c.name),
          })),
        }}
      />
      <section className="mx-auto max-w-6xl px-4 pt-14 pb-10 sm:px-6">
        <p className="inline-flex items-center gap-2 text-sm font-medium text-accent">
          <GraduationCap className="size-4" aria-hidden />
          {ui.menu}
        </p>
        <h1 className="mt-3 text-3xl font-semibold tracking-tight text-balance sm:text-4xl">{ui.title}</h1>
        <p className="mt-4 max-w-3xl text-lg leading-relaxed text-muted text-pretty">{ui.intro}</p>
      </section>
      <section className="border-t border-line bg-surface">
        <ul className="mx-auto grid max-w-6xl gap-4 px-4 py-12 sm:grid-cols-2 sm:px-6 lg:grid-cols-3">
          {COURSES.map((c) => {
            const ready = LEVELS.filter((l) => hasLevel(c.id, l));
            const body = (
              <>
                <div className="flex items-center gap-3">
                  <CourseIcon course={c} className="size-10" />
                  <div>
                    <h2 className="font-semibold">{fill(ui.courseTitle, c.name)}</h2>
                    <p className="text-xs text-muted">
                      {ready.length
                        ? ready.map((l) => `${LEVEL_NAME[l][lang]} · ${fill(ui.lessons, lessonsOf(c.id, l).length)}`).join(" — ")
                        : ui.soon}
                    </p>
                  </div>
                </div>
                <p className="mt-3 text-sm leading-relaxed text-muted">{c.tagline[lang]}</p>
              </>
            );
            return (
              <li key={c.id}>
                {ready.length ? (
                  <a
                    href={coursePath(lang, c.id)}
                    className="block h-full rounded-xl border border-line bg-canvas p-5 transition-colors hover:border-accent"
                  >
                    {body}
                  </a>
                ) : (
                  <div className="h-full rounded-xl border border-dashed border-line bg-canvas p-5 opacity-70">{body}</div>
                )}
              </li>
            );
          })}
        </ul>
      </section>
      <section className="mx-auto max-w-6xl px-4 py-12 sm:px-6">
        <h2 className="text-xl font-semibold tracking-tight">{ui.whyTitle}</h2>
        <ul className="mt-4 grid gap-3 sm:grid-cols-3">
          {ui.why.map((w) => (
            <li key={w} className="rounded-lg border border-line p-4 text-sm leading-relaxed text-muted">
              {w}
            </li>
          ))}
        </ul>
      </section>
    </Shell>
  );
}

// ------------------------------------------------------------- un curso

function LessonList({ lang, course, level }: { lang: Lang; course: CourseInfo; level: Level }) {
  const ui = coursesUi(lang);
  return (
    <ol className="grid gap-2 sm:grid-cols-2">
      {lessonsOf(course.id, level).map((x) => (
        <li key={x.n}>
          <a
            href={lessonPath(lang, course.id, level, x)}
            className="flex h-full gap-3 rounded-lg border border-line bg-canvas p-3 transition-colors hover:border-accent"
          >
            <span className="w-6 shrink-0 text-right font-mono text-xs leading-6 text-muted">{x.n}</span>
            <span>
              <span className="font-medium">{x[lang].title}</span>
              <span className="mt-0.5 line-clamp-2 block text-xs leading-relaxed text-muted">{x[lang].summary}</span>
            </span>
            <span className="sr-only">{fill(ui.lesson, x.n)}</span>
          </a>
        </li>
      ))}
    </ol>
  );
}

/** /cursos/<lenguaje>: los dos niveles. */
export function CoursePage({ lang, course }: { lang: Lang; course: CourseInfo }) {
  const ui = coursesUi(lang);
  return (
    <Shell lang={lang} alternates={courseAlternates(course.id)}>
      <JsonLd data={courseLd(lang, course)} />
      <section className="mx-auto max-w-6xl px-4 pt-10 pb-8 sm:px-6">
        <Crumbs items={[{ name: ui.menu, path: coursesPath(lang) }, { name: course.name }]} />
        <div className="mt-6 flex items-center gap-4">
          <CourseIcon course={course} className="size-14" />
          <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">{fill(ui.courseTitle, course.name)}</h1>
        </div>
        <p className="mt-4 max-w-3xl text-lg leading-relaxed text-muted text-pretty">{course.tagline[lang]}</p>
        <p className="mt-3 max-w-3xl leading-relaxed text-pretty">{course.studio[lang]}</p>
      </section>
      {LEVELS.filter((l) => hasLevel(course.id, l)).map((level) => (
        <section key={level} className="border-t border-line bg-surface">
          <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
            <div className="flex flex-wrap items-baseline justify-between gap-3">
              <h2 className="text-xl font-semibold tracking-tight">
                <a href={levelPath(lang, course.id, level)} className="hover:text-accent">
                  {fill(ui.levelTitle, course.name, levelName(lang, level))}
                </a>
              </h2>
              <span className="text-sm text-muted">{fill(ui.lessons, lessonsOf(course.id, level).length)}</span>
            </div>
            <p className="mt-1 mb-5 text-sm text-muted">{level === "basic" ? ui.basicIntro : ui.advancedIntro}</p>
            <LessonList lang={lang} course={course} level={level} />
          </div>
        </section>
      ))}
      <section className="mx-auto max-w-3xl px-4 py-12 sm:px-6">
        <StudioBox lang={lang} course={course} />
      </section>
    </Shell>
  );
}

/** /cursos/<lenguaje>/<nivel>: las 20 lecciones. */
export function LevelPage({ lang, course, level }: { lang: Lang; course: CourseInfo; level: Level }) {
  const ui = coursesUi(lang);
  const first = lessonsOf(course.id, level)[0];
  const title = fill(ui.levelTitle, course.name, levelName(lang, level));
  return (
    <Shell lang={lang} alternates={levelAlternates(course.id, level)}>
      <JsonLd data={courseLd(lang, course, level)} />
      <section className="mx-auto max-w-6xl px-4 pt-10 pb-8 sm:px-6">
        <Crumbs
          items={[
            { name: ui.menu, path: coursesPath(lang) },
            { name: course.name, path: coursePath(lang, course.id) },
            { name: LEVEL_NAME[level][lang] },
          ]}
        />
        <div className="mt-6 flex items-center gap-4">
          <CourseIcon course={course} className="size-14" />
          <h1 className="text-3xl font-semibold tracking-tight sm:text-4xl">{title}</h1>
        </div>
        <p className="mt-4 max-w-3xl text-lg leading-relaxed text-muted text-pretty">
          {level === "basic" ? ui.basicIntro : ui.advancedIntro} {course.studio[lang]}
        </p>
        {first && (
          <a
            href={lessonPath(lang, course.id, level, first)}
            className="mt-6 inline-flex items-center gap-2 rounded-md bg-accent px-4 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
          >
            {ui.start}
            <ArrowRight className="size-4" aria-hidden />
          </a>
        )}
      </section>
      <section className="border-t border-line bg-surface">
        <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6">
          <LessonList lang={lang} course={course} level={level} />
        </div>
      </section>
    </Shell>
  );
}

// ------------------------------------------------------------- una lección

function Panel({ icon, title, children }: { icon: React.ReactNode; title: string; children: React.ReactNode }) {
  return (
    <section className="overflow-hidden rounded-xl border border-line bg-[#1e1e1e] text-[#d4d4d4]">
      <h2 className="flex items-center gap-2 border-b border-white/10 bg-[#252528] px-4 py-2 font-mono text-xs text-[#a8a8b0]">
        {icon}
        {title}
      </h2>
      {children}
    </section>
  );
}

/** /cursos/<lenguaje>/<nivel>/<lección>. */
export function LessonPage({
  lang,
  course,
  level,
  lessons,
  index,
}: {
  lang: Lang;
  course: CourseInfo;
  level: Level;
  lessons: Lesson[];
  index: number;
}) {
  const ui = coursesUi(lang);
  const lesson = lessons[index];
  const text = lesson[lang];
  const prev = index > 0 ? lessons[index - 1] : null;
  const next = index < lessons.length - 1 ? lessons[index + 1] : null;
  const levelTitle = fill(ui.levelTitle, course.name, levelName(lang, level));
  const crumbs = [
    { name: ui.menu, path: coursesPath(lang) },
    { name: course.name, path: coursePath(lang, course.id) },
    { name: LEVEL_NAME[level][lang], path: levelPath(lang, course.id, level) },
    { name: text.title, path: lessonPath(lang, course.id, level, lesson) },
  ];
  const [w, h] = lesson.size ?? [1200, 600];
  return (
    <Shell lang={lang} alternates={lessonAlternates(course.id, level, lesson)}>
      <JsonLd data={breadcrumbLd(crumbs)} />
      <JsonLd
        data={{
          "@context": "https://schema.org",
          "@type": "LearningResource",
          name: `${text.title} · ${levelTitle}`,
          description: text.summary,
          inLanguage: lang,
          learningResourceType: "Lesson",
          educationalLevel: LEVEL_NAME[level][lang],
          teaches: course.name,
          isAccessibleForFree: true,
          image: `${SITE_URL}${lesson.image}`,
          isPartOf: { "@type": "Course", name: levelTitle, url: `${SITE_URL}${levelPath(lang, course.id, level)}` },
          provider: { "@type": "Organization", name: "DMarlon Studio", url: SITE_URL },
        }}
      />
      <div className="mx-auto grid w-full max-w-6xl gap-10 px-4 py-10 sm:px-6 lg:grid-cols-[260px_1fr]">
        <aside className="order-2 lg:order-1 lg:sticky lg:top-20 lg:max-h-[calc(100vh-6rem)] lg:self-start lg:overflow-y-auto">
          <a href={levelPath(lang, course.id, level)} className="flex items-center gap-2 font-semibold hover:text-accent">
            <CourseIcon course={course} className="size-7" />
            {levelTitle}
          </a>
          <ol className="mt-3 space-y-0.5 text-sm">
            {lessons.map((x, i) => (
              <li key={x.n}>
                <a
                  href={lessonPath(lang, course.id, level, x)}
                  aria-current={i === index ? "page" : undefined}
                  className={`flex gap-2 rounded-md px-2 py-1 transition-colors ${
                    i === index ? "bg-accent/10 font-medium text-accent" : "text-muted hover:bg-soft hover:text-ink"
                  }`}
                >
                  <span className="w-5 shrink-0 text-right font-mono text-xs leading-5 opacity-70">{x.n}</span>
                  <span>{x[lang].title}</span>
                </a>
              </li>
            ))}
          </ol>
        </aside>
        <article className="order-1 min-w-0 lg:order-2">
          <Crumbs items={crumbs.slice(0, 3)} />
          <p className="mt-6 font-mono text-sm text-muted">
            {fill(ui.lesson, lesson.n)} · {fill(ui.ofLevel, lesson.n, lessons.length)}
          </p>
          <h1 className="mt-1 text-3xl font-semibold tracking-tight text-balance sm:text-4xl">
            {text.title} <span className="text-muted">· {course.name}</span>
          </h1>
          <p className="mt-3 text-lg leading-relaxed text-muted text-pretty">{text.summary}</p>
          {/* eslint-disable-next-line @next/next/no-img-element -- ya es un JPEG a su tamaño */}
          <img
            src={lesson.image}
            width={w}
            height={h}
            alt={fill(ui.imageAlt, `${course.name} · ${text.title}`)}
            className="mt-6 h-auto w-full rounded-xl"
            loading={index < 2 ? "eager" : "lazy"}
          />
          <div className="mt-8 space-y-4 leading-relaxed text-pretty">
            {text.body.map((p, i) => (
              <p key={i}>
                <Inline text={p} />
              </p>
            ))}
          </div>
          <div className="mt-8 space-y-4">
            <Panel icon={<Terminal className="size-3.5" aria-hidden />} title={`${ui.code} · main.${course.ext}`}>
              <div
                className="overflow-x-auto px-4 py-3 font-mono text-[13.5px] leading-relaxed [&_.line]:block [&_.line]:min-h-[1.4em] [&_pre]:!bg-transparent"
                dangerouslySetInnerHTML={{ __html: lesson.html }}
              />
            </Panel>
            {lesson.input && (
              <Panel icon={<Terminal className="size-3.5" aria-hidden />} title={`${ui.input} · input.txt`}>
                <pre className="overflow-x-auto px-4 py-3 font-mono text-[13.5px] leading-relaxed">{lesson.input}</pre>
              </Panel>
            )}
            <Panel icon={<Play className="size-3.5 fill-current" aria-hidden />} title={`${ui.output} · ${course.command}`}>
              <pre className="overflow-x-auto px-4 py-3 font-mono text-[13.5px] leading-relaxed whitespace-pre-wrap">
                {lesson.output}
              </pre>
            </Panel>
          </div>
          <section className="mt-8 rounded-xl border border-line p-5">
            <h2 className="flex items-center gap-2 font-semibold">
              <ListChecks className="size-4 text-accent" aria-hidden />
              {ui.keyPoints}
            </h2>
            <ul className="mt-3 list-disc space-y-1.5 pl-5 text-sm leading-relaxed">
              {text.points.map((p, i) => (
                <li key={i}>
                  <Inline text={p} />
                </li>
              ))}
            </ul>
          </section>
          <section className="mt-4 rounded-xl border border-line p-5">
            <h2 className="flex items-center gap-2 font-semibold">
              <Lightbulb className="size-4 text-accent" aria-hidden />
              {ui.exercise}
            </h2>
            <p className="mt-2 text-sm leading-relaxed">
              <Inline text={text.exercise} />
            </p>
          </section>
          <div className="mt-8">
            <StudioBox lang={lang} course={course} />
          </div>
          <nav className="mt-10 flex flex-wrap justify-between gap-3 border-t border-line pt-6 text-sm">
            {prev ? (
              <a href={lessonPath(lang, course.id, level, prev)} className="flex items-center gap-2 text-muted hover:text-ink">
                <ArrowLeft className="size-4" aria-hidden />
                <span>
                  {ui.previous}: <span className="text-ink">{prev[lang].title}</span>
                </span>
              </a>
            ) : (
              <span />
            )}
            {next ? (
              <a href={lessonPath(lang, course.id, level, next)} className="flex items-center gap-2 text-muted hover:text-ink">
                <span>
                  {ui.next}: <span className="text-ink">{next[lang].title}</span>
                </span>
                <ArrowRight className="size-4" aria-hidden />
              </a>
            ) : level === "basic" && hasLevel(course.id, "advanced") ? (
              <a href={levelPath(lang, course.id, "advanced")} className="flex items-center gap-2 font-medium text-accent">
                {ui.nextLevel}
                <ArrowRight className="size-4" aria-hidden />
              </a>
            ) : (
              <a href={coursesPath(lang)} className="flex items-center gap-2 text-muted hover:text-ink">
                {ui.allCourses}
                <ArrowRight className="size-4" aria-hidden />
              </a>
            )}
          </nav>
        </article>
      </div>
    </Shell>
  );
}

// ------------------------------------------------------------- portada de la web

/** En la portada: los cursos, que llevan al IDE. */
export function CoursesBand({ lang }: { lang: Lang }) {
  const ui = coursesUi(lang);
  return (
    <section id={lang === "es" ? "cursos" : "courses"} className="border-t border-line">
      <div className="mx-auto grid max-w-6xl gap-8 px-4 py-16 sm:px-6 sm:py-20 lg:grid-cols-[1fr_1.1fr] lg:items-center">
        <div>
          <p className="inline-flex items-center gap-2 text-sm font-medium text-accent">
            <GraduationCap className="size-4" aria-hidden />
            {ui.menu}
          </p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight text-balance sm:text-3xl">{ui.title}</h2>
          <p className="mt-3 leading-relaxed text-muted text-pretty">{ui.intro}</p>
          <a
            href={coursesPath(lang)}
            className="mt-6 inline-flex items-center gap-2 rounded-md bg-accent px-4 py-2 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
          >
            {ui.allCourses}
            <ArrowRight className="size-4" aria-hidden />
          </a>
        </div>
        <ul className="grid grid-cols-2 gap-3 sm:grid-cols-3">
          {COURSES.filter((c) => LEVELS.some((l) => hasLevel(c.id, l))).map((c) => (
            <li key={c.id}>
              <a
                href={coursePath(lang, c.id)}
                className="flex items-center gap-3 rounded-lg border border-line bg-surface p-3 transition-colors hover:border-accent"
              >
                <CourseIcon course={c} className="size-9" />
                <span>
                  <span className="block text-sm font-medium">{c.name}</span>
                  <span className="block text-xs text-muted">
                    {fill(ui.lessons, LEVELS.reduce((n, l) => n + lessonsOf(c.id, l).length, 0))}
                  </span>
                </span>
              </a>
            </li>
          ))}
        </ul>
      </div>
    </section>
  );
}
