/**
 * Descargas de DMarlon Studio. Los .zip los publica el flujo de GitHub
 * Actions en la release de etiqueta fija `latest` (prerelease): cambie aquí
 * el repositorio, la etiqueta o los nombres si cambian allí.
 */
export const REPO = "falconsoft3d/dmarlonstudio.com";
export const RELEASE_TAG = "latest";

export const REPO_URL = `https://github.com/${REPO}`;
export const RELEASES_URL = `${REPO_URL}/releases`;

export type Platform = "macos" | "windows" | "linux";

export type Download = {
  platform: Platform;
  label: string;
  /** URL del archivo; null mientras no exista (se muestra «Próximamente»). */
  url: string | null;
  file: string | null;
};

const asset = (name: string) => `${REPO_URL}/releases/download/${RELEASE_TAG}/${name}`;

export const DOWNLOADS: Download[] = [
  {
    platform: "macos",
    label: "macOS",
    url: asset("DMarlonStudio-macOS.zip"),
    file: "DMarlonStudio-macOS.zip",
  },
  {
    platform: "windows",
    label: "Windows",
    url: asset("DMarlonStudio-Windows.zip"),
    file: "DMarlonStudio-Windows.zip",
  },
  { platform: "linux", label: "Linux", url: null, file: null },
];
