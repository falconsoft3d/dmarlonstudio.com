"use client";
// DMarlon Studio: el estado de la app. Generado: no lo edite.
import { useSyncExternalStore } from "react";
import { App } from "./app";

export const app = new App();

let started = false;

/// Las pantallas se vuelven a dibujar cuando App llama a notify().
export function useApp() {
  if (typeof window !== "undefined" && !started) {
    started = true;
    Promise.resolve(app.start()).then(() => app.notify());
  }
  useSyncExternalStore(app.subscribe, app.version, app.version);
  return app;
}
