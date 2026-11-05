/** Marca: una ventana con un componente seleccionado (tiradores del diseñador). */
export function Logo({ className = "size-7" }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden>
      <rect x="2" y="4" width="28" height="24" rx="5" fill="var(--accent)" />
      <rect x="2" y="4" width="28" height="6" rx="3" fill="var(--accent-strong)" />
      <rect x="8" y="14" width="16" height="9" rx="1.5" fill="none" stroke="var(--on-accent)" strokeWidth="1.6" strokeDasharray="2.5 2" />
      {[
        [8, 14],
        [24, 14],
        [8, 23],
        [24, 23],
      ].map(([x, y]) => (
        <rect key={`${x}-${y}`} x={x - 1.6} y={y - 1.6} width="3.2" height="3.2" fill="var(--on-accent)" />
      ))}
    </svg>
  );
}
