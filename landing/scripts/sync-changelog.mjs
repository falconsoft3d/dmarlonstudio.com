// Copia ../CHANGELOG.md a content/CHANGELOG.md antes de compilar: la página
// «Novedades» lo lee de ahí (en Vercel, con la raíz en landing/, puede que
// no se vea lo que hay fuera de esta carpeta: entonces vale la copia
// confirmada en el repositorio).
import { copyFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const from = join(here, "..", "..", "CHANGELOG.md");
const to = join(here, "..", "content", "CHANGELOG.md");
if (existsSync(from)) copyFileSync(from, to);
