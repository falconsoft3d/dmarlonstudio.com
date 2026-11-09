import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    // Las demos compiladas (scripts/build_live_demos.py).
    "public/demos/live/**",
    // Las demos de Next.js con servidor: código generado por el estudio.
    "app/(live)/**",
    // Los ejemplos de los cursos: programas de cada lenguaje (Node con
    // require, a propósito), no código de la web.
    "content/courses/*/basic/**",
    "content/courses/*/advanced/**",
  ]),
]);

export default eslintConfig;
