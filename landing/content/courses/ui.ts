import type { Lang } from "@/lib/i18n";

/** Textos de las páginas de los cursos. {0}, {1}…: lo que va dentro. */
const ES = {
  menu: "Cursos",
  title: "Cursos de programación gratis con ejemplos",
  metaTitle: "Cursos de programación gratis: Python, JavaScript, C, C++, Pascal, Go y Dart",
  intro:
    "Aprenda a programar con ejemplos que funcionan: cada lección es un programa completo, con su explicación, su salida real y una imagen de cómo se ve en DMarlon Studio, el IDE visual con el que puede probarlo con un clic.",
  lessons: "{0} lecciones",
  levels: "Básico y avanzado",
  soon: "Próximamente",
  start: "Empezar",
  courseTitle: "Curso de {0}",
  levelTitle: "Curso de {0} {1}",
  levelMeta: "Curso de {0} {1} gratis: {2} lecciones con ejemplos que se ejecutan y su salida real. Pruébelos en DMarlon Studio.",
  courseMeta: "Curso de {0} gratis, básico y avanzado: 40 ejemplos explicados con su salida real. {1}",
  basicIntro: "Desde cero: lo imprescindible para escribir sus primeros programas.",
  advancedIntro: "Para quien ya domina lo básico: las técnicas que se usan en proyectos reales.",
  lesson: "Lección {0}",
  ofLevel: "{0} de {1}",
  code: "Código",
  output: "Salida",
  input: "Entrada (lo que se teclea)",
  keyPoints: "Para recordar",
  exercise: "Ejercicio",
  tryIt: "Pruébelo en DMarlon Studio",
  tryItIntro: "DMarlon Studio es un IDE visual y gratuito para Windows, macOS y Linux: diseña la ventana, escribe el código y lo ejecuta con un clic.",
  inStudio: "{0} en DMarlon Studio",
  download: "Descargar DMarlon Studio",
  allLessons: "Todas las lecciones",
  previous: "Anterior",
  next: "Siguiente",
  nextLevel: "Siga con el curso avanzado",
  allCourses: "Todos los cursos",
  imageAlt: "{0} en DMarlon Studio: el código del ejemplo y su salida en la terminal",
  whyTitle: "Por qué aprender con DMarlon Studio",
  why: [
    "Cada ejemplo se ha ejecutado de verdad: la salida que ve es la que obtendrá.",
    "El mismo IDE sirve para siete lenguajes y para crear aplicaciones con ventana, webs y apps móviles.",
    "Gratis y en español, con su versión en inglés.",
  ],
};

type Ui = typeof ES;

const EN: Ui = {
  menu: "Courses",
  title: "Free programming courses with examples",
  metaTitle: "Free programming courses: Python, JavaScript, C, C++, Pascal, Go and Dart",
  intro:
    "Learn to code with examples that work: every lesson is a complete program with its explanation, its real output and a picture of how it looks in DMarlon Studio, the visual IDE where you can try it with one click.",
  lessons: "{0} lessons",
  levels: "Basic and advanced",
  soon: "Coming soon",
  start: "Start",
  courseTitle: "{0} course",
  levelTitle: "{1} {0} course",
  levelMeta: "Free {1} {0} course: {2} lessons with runnable examples and their real output. Try them in DMarlon Studio.",
  courseMeta: "Free {0} course, basic and advanced: 40 explained examples with their real output. {1}",
  basicIntro: "From scratch: everything you need to write your first programs.",
  advancedIntro: "For those who know the basics: the techniques used in real projects.",
  lesson: "Lesson {0}",
  ofLevel: "{0} of {1}",
  code: "Code",
  output: "Output",
  input: "Input (what gets typed)",
  keyPoints: "Key points",
  exercise: "Exercise",
  tryIt: "Try it in DMarlon Studio",
  tryItIntro: "DMarlon Studio is a free visual IDE for Windows, macOS and Linux: design the window, write the code and run it with one click.",
  inStudio: "{0} in DMarlon Studio",
  download: "Download DMarlon Studio",
  allLessons: "All lessons",
  previous: "Previous",
  next: "Next",
  nextLevel: "Continue with the advanced course",
  allCourses: "All courses",
  imageAlt: "{0} in DMarlon Studio: the example's code and its output in the terminal",
  whyTitle: "Why learn with DMarlon Studio",
  why: [
    "Every example has actually been run: the output you see is the output you will get.",
    "One IDE for seven languages, and for building windowed apps, websites and mobile apps.",
    "Free, in English and Spanish.",
  ],
};

export const coursesUi = (lang: Lang): Ui => (lang === "es" ? ES : EN);

/** [text] con {0}, {1}… cambiados por [args]. */
export const fill = (text: string, ...args: (string | number)[]) =>
  text.replace(/\{(\d)\}/g, (_, i) => String(args[Number(i)] ?? ""));
