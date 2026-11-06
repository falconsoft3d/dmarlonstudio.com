import { Logo } from "@/components/logo";
import type { Content } from "@/content";
import { REPO_URL, RELEASES_URL } from "@/lib/downloads";
import { HOME, PATHS, type Lang } from "@/lib/i18n";
import { VERSION } from "@/lib/version";

/** Pie de todas las páginas: versión, GitHub, manual, dossier y descargas. */
export function SiteFooter({ lang, t }: { lang: Lang; t: Content }) {
  const { footer } = t;
  return (
    <footer className="border-t border-line bg-surface print:hidden">
      <div className="mx-auto flex max-w-6xl flex-col gap-4 px-4 py-8 text-sm text-muted sm:flex-row sm:items-center sm:px-6">
        <div className="flex items-center gap-2">
          <Logo className="size-5" />
          <span>DMarlon Studio · © {new Date().getFullYear()} Marlon Falcón</span>
          <a
            href={`${PATHS.changelog[lang]}#v${VERSION}`}
            className="rounded border border-line px-1.5 py-0.5 font-mono text-xs hover:text-ink"
            title={footer.changelogTitle}
          >
            v{VERSION}
          </a>
        </div>
        <nav aria-label={footer.linksLabel} className="flex flex-wrap gap-x-5 gap-y-2 sm:ml-auto">
          <a href={PATHS.demos[lang]} className="hover:text-ink">
            {footer.demos}
          </a>
          <a href={PATHS.manual[lang]} className="hover:text-ink">
            {footer.manual}
          </a>
          <a href={PATHS.dossier[lang]} className="hover:text-ink">
            {footer.dossier}
          </a>
          <a href={REPO_URL} className="hover:text-ink">
            GitHub
          </a>
          <a href={RELEASES_URL} className="hover:text-ink">
            {footer.versions}
          </a>
          <a href={`${HOME[lang]}#${t.downloads.id}`} className="hover:text-ink">
            {footer.download}
          </a>
        </nav>
      </div>
    </footer>
  );
}
