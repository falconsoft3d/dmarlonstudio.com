# DMarlon Studio

IDE visual de escritorio al estilo de Delphi: diseñe ventanas arrastrando
componentes, escriba en Python el código de sus eventos y ejecútelas. Hoy
genera aplicaciones de **tkinter** (escritorio) y **Flask** (web); el siguiente
entorno será **Electron**.

Nace de la app «Código» de [ERPSqlite](https://github.com/falconsoft3d/erp-sqlite),
separada del ERP para crecer como producto propio.

## Repositorio

| Carpeta | Qué es |
|---|---|
| [`studio/`](studio/) | La aplicación de escritorio (Flutter: macOS, Windows y Linux). |
| [`landing/`](landing/) | La web dmarlonstudio.com (Next.js), con las descargas. |
| [`.github/workflows/build.yml`](.github/workflows/build.yml) | Compila macOS y Windows y publica los zips en la release `latest`. |

## Módulos del estudio

- **Diseñador**: paleta de componentes, árbol, inspector de propiedades y
  eventos, rejilla, alinear, copiar y pegar, deshacer, F9 para ejecutar y F12
  para pasar del diseño al código. Pestañas *Diseño*, *Código* y *Python
  generado*. Exporta el `.py`. La IA diseña ventanas y escribe manejadores.
- **Editor**: al estilo de VS Code. Explorador, pestañas, resaltado, buscar y
  reemplazar, búsqueda en archivos, terminal (⌘J), git (cambios, confirmar,
  subir, traer, clonar), GitHub y chat con la IA sobre el archivo abierto.
- **Bases de datos**: SQLite, PostgreSQL, MySQL/MariaDB y MongoDB.
- **API**: cliente HTTP con colecciones, variables de entorno e historial.
- **FTP**: explorador de servidores FTP.
- **Diagramas**: de flujo y entidad-relación, con exportación a PDF.
- **Ajustes**: tema y proveedor de IA (OpenAI, Anthropic, Gemini, compatibles…).

## Dónde se guarda todo

- **Proyectos del Diseñador**: una carpeta por proyecto en
  `~/Documents/DMarlon Studio/Proyectos` (se puede cambiar). Cada una tiene
  `project.dmsproj` (el diseño), el código de la ventana (`<Formulario>.py`)
  y `build/` con el Python generado. Se pueden versionar con git.
- **Ajustes, conexiones, peticiones de API y diagramas**: `studio.sqlite` en la
  carpeta de soporte de la aplicación.

## Desarrollo

```bash
cd studio
flutter pub get
flutter run -d macos      # o windows / linux
flutter analyze && flutter test
```

Para ejecutar las ventanas hace falta Python 3 con tkinter
(`brew install python-tk` en macOS; el instalador de python.org en Windows) y,
para las aplicaciones web, Flask (`python3 -m pip install flask`).

Landing:

```bash
cd landing
npm install
npm run dev
```

## Hoja de ruta

1. ✅ Separar la app «Código» de ERPSqlite: tkinter y Flask.
2. Varios formularios por proyecto (nodo «Proyecto») con el icono de la
   aplicación.
3. **Destinos de compilación**: el mismo diseñador genera la aplicación para
   cada lenguaje o entorno elegido al crear el proyecto.

| Destino | Estado |
|---|---|
| Python · tkinter (escritorio) | ✅ |
| Python · Flask (web) | ✅ |
| Electron + React (escritorio) | ⏳ |
| Web con Next.js | ⏳ |
| C++ (escritorio, FLTK) | ⏳ |
| Pascal (escritorio, Lazarus/LCL) | ⏳ |
| Flutter (escritorio y móvil) | ⏳ |
| React Native (móvil) | ⏳ |
