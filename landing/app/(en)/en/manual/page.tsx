import { ManualIndex } from "@/components/manual/views";
import { manualOf } from "@/content/manual";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const m = manualOf("en");
export const metadata = pageMetadata("en", { title: m.ui.title, description: m.ui.intro, paths: PATHS.manual });

export default function Page() {
  return <ManualIndex lang="en" />;
}
