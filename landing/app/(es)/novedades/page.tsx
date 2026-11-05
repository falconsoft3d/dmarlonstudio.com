import { Changelog, changelogText } from "@/components/changelog";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const x = changelogText("es");
export const metadata = pageMetadata("es", { title: x.title, description: x.intro, paths: PATHS.changelog });

export default function Page() {
  return <Changelog lang="es" />;
}
