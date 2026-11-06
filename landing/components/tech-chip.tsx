import { TargetLogo } from "@/components/target-logo";
import type { TargetIcon } from "@/content/types";

/** La tecnología de una captura: su logotipo y su nombre, sobre la imagen. */
export function TechChip({ icon, label, className = "" }: { icon: TargetIcon; label: string; className?: string }) {
  return (
    <span
      className={`pointer-events-none inline-flex items-center gap-1.5 rounded-full border border-line bg-surface/95 py-1 pr-2.5 pl-2 text-xs font-medium text-ink shadow-md backdrop-blur ${className}`}
    >
      <TargetLogo icon={icon} className="size-4" />
      {label}
    </span>
  );
}
