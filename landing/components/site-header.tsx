import { Download } from "lucide-react";
import { LanguageSwitch } from "@/components/language";
import { Logo } from "@/components/logo";
import { ThemeToggle } from "@/components/theme-toggle";
import type { Content } from "@/content";
import { REPO_URL } from "@/lib/downloads";
import { HOME, PATHS, type Alternates, type Lang } from "@/lib/i18n";

export function SiteHeader({ lang, t, alternates }: { lang: Lang; t: Content; alternates?: Alternates }) {
  return (
    <header className="sticky top-0 z-40 border-b border-line bg-canvas/85 backdrop-blur supports-[backdrop-filter]:bg-canvas/70 print:hidden">
      <div className="mx-auto flex h-14 max-w-6xl items-center gap-4 px-4 sm:px-6">
        <a href={HOME[lang]} className="flex items-center gap-2 font-semibold tracking-tight">
          <Logo className="size-7" />
          <span>DMarlon Studio</span>
        </a>
        <nav aria-label={t.header.sectionsLabel} className="ml-6 hidden items-center gap-5 text-sm text-muted lg:flex">
          {t.header.nav.map((n) => (
            <a key={n.href} href={n.href} className="transition-colors hover:text-ink">
              {n.label}
            </a>
          ))}
        </nav>
        <div className="ml-auto flex items-center gap-2">
          <a href={PATHS.demos[lang]} className="rounded-md px-2 py-1.5 text-sm text-muted transition-colors hover:text-ink lg:hidden">
            {t.footer.demos}
          </a>
          <LanguageSwitch lang={lang} label={t.header.languageLabel} alternates={alternates} />
          <ThemeToggle labels={t.theme} />
          <a
            href={REPO_URL}
            className="hidden rounded-md px-3 py-1.5 text-sm text-muted transition-colors hover:text-ink sm:inline-block"
          >
            GitHub
          </a>
          <a
            href={`${HOME[lang]}#${t.downloads.id}`}
            className="inline-flex items-center gap-1.5 rounded-md bg-accent px-3 py-1.5 text-sm font-medium text-on-accent transition-colors hover:bg-accent-strong"
          >
            <Download className="size-4" aria-hidden />
            {t.header.download}
          </a>
        </div>
      </div>
    </header>
  );
}
