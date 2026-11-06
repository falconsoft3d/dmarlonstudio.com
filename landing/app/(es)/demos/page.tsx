import { Demos, demosText } from "@/components/demos";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const x = demosText("es");
export const metadata = pageMetadata("es", { title: x.title, description: x.intro, paths: PATHS.demos });

export default function Page() {
  return <Demos lang="es" />;
}
