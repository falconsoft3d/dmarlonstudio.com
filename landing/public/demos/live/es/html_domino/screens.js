// Generado por DMarlon Studio a partir de las pantallas. No lo edite.
const SCREENS = {};

SCREENS["Mesa"] = (app, ui, router) => {
  return dmsScreen(ui, router, {
    title: `Dominó doble 9`,
    back: false,
    actions: [{ icon: "refresh", badge: null, on: ui.on(async () => { app.newGame(); }) }, { icon: "visibility", badge: null, on: ui.on(async () => { app.toggleAll(); }) }],
    fab: null,
    body: `<div class="col st"><canvas class="canvas" data-paint="${ui.paint((ctx, w, h) => { app.dibujar(ctx, w, h); })}" data-tap="${ui.on(async (x, y) => { app.tocar(x, y); })}" style="aspect-ratio:${css("1.5714")};width:${css("min(100%, calc((100dvh - 96px) * 1.5714))")}"></canvas></div>`,
  });
};

