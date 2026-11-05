import { ManualPrint } from "@/components/manual/views";
import { manualOf } from "@/content/manual";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const m = manualOf("es");
export const metadata = pageMetadata("es", {
  title: m.ui.title,
  description: m.ui.intro,
  paths: PATHS.manualPrint,
  noIndex: true,
});

/** El manual entero, para imprimirlo a PDF (scripts/build-docs.mjs). */
export default function Page() {
  return <ManualPrint lang="es" />;
}
