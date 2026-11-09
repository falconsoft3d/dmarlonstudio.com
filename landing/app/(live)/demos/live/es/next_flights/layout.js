// Generado por DMarlon Studio. No lo edite.
import "./globals.css";
import { DmsShell } from "./_lib/dms";

export const metadata = { title: "Buscador de vuelos" };
export const viewport = { width: "device-width", initialScale: 1 };

export default function RootLayout({ children }) {
  return (
    <html lang="es">
      <head>
        <link
          rel="stylesheet"
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,400,0..1,0&display=block"
        />
      </head>
      <body>
        <DmsShell>{children}</DmsShell>
      </body>
    </html>
  );
}
