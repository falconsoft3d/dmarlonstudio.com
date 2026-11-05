import { Changelog, changelogText } from "@/components/changelog";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const x = changelogText("en");
export const metadata = pageMetadata("en", { title: x.title, description: x.intro, paths: PATHS.changelog });

export default function Page() {
  return <Changelog lang="en" />;
}
