import { ManualChapter } from "@/components/manual/views";
import { manualOf } from "@/content/manual";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const m = manualOf("en");
export const metadata = pageMetadata("en", { title: m.ui.title, description: m.ui.intro, paths: PATHS.manual });

export default function Page() {
  // El manual abre en su primer capítulo, con el índice al lado.
  return <ManualChapter lang="en" index={0} />;
}
