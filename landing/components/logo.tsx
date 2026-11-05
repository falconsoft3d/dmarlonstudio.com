/** Marca: una «D» seleccionada en el diseñador (caja y tiradores), como el
 *  icono de la aplicación (studio/assets/icon/icon.svg). */
export function Logo({ className = "size-7" }: { className?: string }) {
  return (
    <svg viewBox="0 0 32 32" className={className} aria-hidden>
      <defs>
        <linearGradient id="dms-logo-bg" x1="0" y1="0" x2="32" y2="32" gradientUnits="userSpaceOnUse">
          <stop offset="0" stopColor="#487EFF" />
          <stop offset="0.5" stopColor="#2B5FD9" />
          <stop offset="1" stopColor="#34249E" />
        </linearGradient>
      </defs>
      <rect width="32" height="32" rx="7.2" fill="url(#dms-logo-bg)" />
      <path
        fill="#fff"
        fillRule="evenodd"
        d="M10.3 9.7H16.3A6.3 6.3 0 0 1 16.3 22.3H10.3ZM12.9 12.3V19.7H16.3A3.7 3.7 0 0 0 16.3 12.3Z"
      />
      {[
        [8.3, 7.7],
        [23.7, 7.7],
        [8.3, 24.3],
        [23.7, 24.3],
      ].map(([x, y]) => (
        <rect key={`${x}-${y}`} x={x - 1.4} y={y - 1.4} width="2.8" height="2.8" rx="0.6" fill="#fff" />
      ))}
    </svg>
  );
}
