import "../globals.css";
import { RootHtml } from "@/components/root-html";
import { homeMetadata } from "@/lib/metadata";

export { viewport } from "@/lib/metadata";
export const metadata = homeMetadata("es");

/** Páginas en español (en la raíz). */
export default function SpanishLayout({ children }: LayoutProps<"/">) {
  return <RootHtml lang="es">{children}</RootHtml>;
}
