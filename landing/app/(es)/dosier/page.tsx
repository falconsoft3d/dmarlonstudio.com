import { Dossier } from "@/components/dossier";
import { dossierOf } from "@/content/dossier";
import { PATHS } from "@/lib/i18n";
import { pageMetadata } from "@/lib/metadata";

const d = dossierOf("es");
export const metadata = pageMetadata("es", { title: d.meta.title, description: d.meta.description, paths: PATHS.dossier });

export default function Page() {
  return <Dossier lang="es" />;
}
