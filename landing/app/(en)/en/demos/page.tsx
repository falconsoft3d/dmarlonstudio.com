import { Demos, demosText } from "@/components/demos";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const x = demosText("en");
export const metadata = pageMetadata("en", { title: x.title, description: x.intro, paths: PATHS.demos });

export default function Page() {
  return <Demos lang="en" />;
}
