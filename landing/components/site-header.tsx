import { Download } from "lucide-react";
import { Logo } from "@/components/logo";
import { REPO_URL } from "@/lib/downloads";

const NAV = [
  { href: "#disenador", label: "Diseñador" },
  { href: "#editor", label: "Editor" },
  { href: "#herramientas", label: "Herramientas" },
  { href: "#ia", label: "IA" },
  { href: "#hoja-de-ruta", label: "Hoja de ruta" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-line bg-canvas/85 backdrop-blur supports-[backdrop-filter]:bg-canvas/70">
      <div className="mx-auto flex h-14 max-w-6xl items-center gap-4 px-4 sm:px-6">
        <a href="#inicio" className="flex items-center gap-2 font-semibold tracking-tight">
          <Logo className="size-7" />
          <span>DMarlon Studio</span>
        </a>
        <nav aria-label="Secciones" className="ml-6 hidden items-center gap-5 text-sm text-muted md:flex">
          {NAV.map((n) => (
            <a key={n.href} href={n.href} className="transition-colors hover:text-ink">
              {n.label}
            </a>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-2">
          <a
            href={REPO_URL}
            className="hidden rounded-md px-3 py-1.5 text-sm text-muted transition-colors hover:text-ink sm:inline-block"
          >
            GitHub
          </a>
          <a
            href="#descargas"
            className="inline-flex items-center gap-1.5 rounded-md bg-accent px-3 py-1.5 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
          >
            <Download className="size-4" aria-hidden />
            Descargar
          </a>
        </div>
      </div>
    </header>
  );
}
