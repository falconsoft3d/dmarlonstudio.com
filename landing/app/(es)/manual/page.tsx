import { ManualIndex } from "@/components/manual/views";
import { manualOf } from "@/content/manual";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const m = manualOf("es");
export const metadata = pageMetadata("es", { title: m.ui.title, description: m.ui.intro, paths: PATHS.manual });

export default function Page() {
  return <ManualIndex lang="es" />;
}
