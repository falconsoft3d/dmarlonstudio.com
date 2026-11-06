import { notFound } from "next/navigation";
import { DemoDetail, demoMeta } from "@/components/demo-detail";
import { ALL_DEMOS } from "@/components/demos";
import { demoAlternates } from "@/lib/demos";
import { pageMetadata } from "@/lib/metadata";

export const dynamicParams = false;

export function generateStaticParams() {
  return ALL_DEMOS.map((d) => ({ seed: d.seed }));
}

export async function generateMetadata({ params }: PageProps<"/demos/[seed]">) {
  const { seed } = await params;
  const m = demoMeta("es", seed);
  return m ? pageMetadata("es", { ...m, paths: demoAlternates(seed) }) : {};
}

export default async function Page({ params }: PageProps<"/demos/[seed]">) {
  const { seed } = await params;
  if (!demoMeta("es", seed)) notFound();
  return <DemoDetail lang="es" seed={seed} />;
}
