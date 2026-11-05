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
| `app/(es)/` | Layout raíz y portada en español (`/`) |
| `app/(en)/en/` | Layout raíz y portada en inglés (`/en`) |
| `app/global-not-found.tsx` | 404 en los dos idiomas |
| `app/robots.ts`, `app/sitemap.ts` | `robots.txt` y `sitemap.xml` (con hreflang) |
| `components/home.tsx` | La portada, compartida por los dos idiomas |
| `content/es.ts`, `content/en.ts` | Todos los textos, con la forma de `content/types.ts` |
| `lib/i18n.ts`, `lib/metadata.ts` | Idiomas, rutas y metadatos por idioma |
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

### Idiomas

Español en `/` e inglés en `/en`, con dos layouts raíz (`app/(es)` y
`app/(en)/en`) para que cada uno tenga su `<html lang>`, como en la landing de
ERPSqlite. El selector ES / EN de la cabecera lleva a la otra portada. Un
texto nuevo se añade a `content/types.ts` y a los dos archivos de
`content/`: TypeScript avisa si falta en alguno.

## Despliegue en Vercel

1. Importe el repositorio en Vercel y elija **Root Directory: `landing`**
   (el resto del monorepo es la app de Flutter en `studio/`).
2. Framework: Next.js (se detecta solo). No necesita variables de entorno.
3. Añada el dominio `dmarlonstudio.com` en *Settings → Domains*.
