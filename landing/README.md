# Landing de DMarlon Studio

Web pública de [dmarlonstudio.com](https://dmarlonstudio.com): portada del
estudio y descargas. Next.js 16 (App Router), React 19, Tailwind CSS 4 y
TypeScript.

## Desarrollo

```bash
cd landing
npm install
npm run dev      # http://localhost:3000
```

```bash
npm run build    # compilación de producción (comprueba también los tipos)
npm run start    # sirve la compilación
npm run lint
```

## Estructura

| Ruta | Contenido |
|---|---|
| `app/layout.tsx` | `<html lang="es">`, fuentes y metadatos (título, descripción, Open Graph) |
| `app/page.tsx` | La portada: secciones, hoja de ruta, descargas y pie |
| `app/robots.ts`, `app/sitemap.ts` | `robots.txt` y `sitemap.xml` |
| `content/es.ts` | Todos los textos de la portada |
| `components/ide-mock.tsx` | Maqueta del diseñador en HTML y CSS (sin imágenes) |
| `components/downloads.tsx` | Tarjetas de descarga; resalta el sistema del visitante |
| `lib/downloads.ts` | Repositorio, etiqueta y nombres de los .zip |
| `lib/site.ts` | URL pública del sitio |

### Descargas

Los enlaces apuntan a la release de etiqueta fija `latest` de
`falconsoft3d/dmarlonstudio.com`, que publica el flujo de GitHub Actions:

- `https://github.com/falconsoft3d/dmarlonstudio.com/releases/download/latest/DMarlonStudio-macOS.zip`
- `https://github.com/falconsoft3d/dmarlonstudio.com/releases/download/latest/DMarlonStudio-Windows.zip`

Si cambian el repositorio, la etiqueta o los nombres de los archivos,
edite solo `lib/downloads.ts`. Linux figura como «Próximamente»
(`url: null`); al publicarlo, basta con darle su `url` y `file`.

### Inglés (/en)

Hoy solo hay español en `/`. Para añadir `/en`: traduzca `content/es.ts` a
`content/en.ts` y pase a dos layouts raíz con grupos de rutas, `app/(es)` y
`app/(en)`, cada uno con su `<html lang>`, como en la landing de ERPSqlite.

## Despliegue en Vercel

1. Importe el repositorio en Vercel y elija **Root Directory: `landing`**
   (el resto del monorepo es la app de Flutter en `studio/`).
2. Framework: Next.js (se detecta solo). No necesita variables de entorno.
3. Añada el dominio `dmarlonstudio.com` en *Settings → Domains*.
