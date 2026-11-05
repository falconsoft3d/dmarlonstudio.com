/** Forma de los textos de la portada: content/es.ts y content/en.ts la cumplen. */
export type Feature = { title: string; text: string };
export type Section = { id: string; eyebrow: string; title: string; intro: string; features: Feature[] };
export type StepStatus = "ready" | "next" | "later";
export type TargetIcon =
  | "python"
  | "flask"
  | "electron"
  | "chrome"
  | "next"
  | "cpp"
  | "lazarus"
  | "node"
  | "sqlite"
  | "postgres"
  | "mysql"
  | "mongodb"
  | "api"
  | "falcon"
  | "console"
  | "flutter"
  | "react"
  | "html";
export type Target = { name: string; sub: string; icon: TargetIcon };
export type Step = { name: string; status: StepStatus; text: string; icon?: TargetIcon };
export type PlatformNotes = { requirements: string; steps: string[] };

export type Content = {
  meta: { title: string; description: string };
  header: {
    sectionsLabel: string;
    nav: { href: string; label: string }[];
    download: string;
    languageLabel: string;
  };
  theme: { system: string; dark: string; light: string; change: string };
  hero: {
    eyebrow: string;
    title: string;
    text: string;
    primary: string;
    secondary: string;
    targetsLabel: string;
    targets: Target[];
    backendsLabel: string;
    backends: Target[];
    databasesLabel: string;
    databases: Target[];
  };
  examples: {
    label: string;
    previous: string;
    next: string;
    pause: string;
    play: string;
    goTo: string;
    items: { seed: string; name: string; text: string }[];
  };
  sections: Section[];
  roadmap: {
    id: string;
    eyebrow: string;
    title: string;
    status: Record<StepStatus, string>;
    steps: Step[];
  };
  downloads: {
    id: string;
    eyebrow: string;
    title: string;
    intro: string;
    yours: string;
    download: string;
    soon: string;
    notes: { macos: PlatformNotes; windows: PlatformNotes; linux: PlatformNotes };
    /** Párrafo de requisitos: texto, Python, texto, Flask, texto, comando, texto, enlace, final. */
    requirement: {
      before: string;
      python: string;
      middle: string;
      flask: string;
      afterFlask: string;
      electron: string;
      after: string;
      releases: string;
    };
  };
  footer: {
    changelogTitle: string;
    linksLabel: string;
    versions: string;
    download: string;
    manual: string;
    dossier: string;
  };
  mock: {
    save: string;
    properties: string;
    events: string;
    design: string;
    code: string;
    generated: string;
    window: string;
    name: string;
    email: string;
    phone: string;
  };
  notFound: { title: string; home: string };
};
