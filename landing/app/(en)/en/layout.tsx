import "../../globals.css";
import { RootHtml } from "@/components/root-html";
import { homeMetadata } from "@/lib/metadata";

export { viewport } from "@/lib/metadata";
export const metadata = homeMetadata("en");

/** English pages (under /en). */
export default function EnglishLayout({ children }: LayoutProps<"/en">) {
  return <RootHtml lang="en">{children}</RootHtml>;
}
