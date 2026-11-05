/**
 * Manual de usuario como datos: content/manual/es.ts y en.ts tienen la misma
 * forma (los capítulos van en el mismo orden en los dos idiomas).
 *
 * En los textos, **negrita** marca un texto de la interfaz y `código` un
 * nombre de archivo, una orden o código.
 */
export type Block =
  | { type: "p"; text: string }
  | { type: "ul"; items: string[] }
  | { type: "ol"; items: string[] }
  | { type: "table"; head: string[]; rows: string[][] }
  | { type: "code"; code: string }
  | { type: "note"; tone?: "info" | "warn"; text: string }
  | { type: "img"; src: string; alt: string; caption?: string };

export type ManualSection = { id: string; title: string; blocks: Block[] };

export type Chapter = {
  slug: string;
  title: string;
  summary: string;
  sections: ManualSection[];
};

export type Manual = {
  ui: {
    title: string;
    subtitle: string;
    intro: string;
    contents: string;
    chapter: string;
    previous: string;
    next: string;
    onThisPage: string;
    downloadPdf: string;
    allChapters: string;
    version: string;
    printTitle: string;
  };
  chapters: Chapter[];
};
