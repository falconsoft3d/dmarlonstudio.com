// Generado por DMarlon Studio a partir de las pantallas. No lo edite.
const SCREENS = {};

SCREENS["Login"] = (app, ui, router) => {
  return dmsScreen(ui, router, {
    title: null,
    back: false,
    actions: [],
    fab: null,
    body: `<div class="center"><div style="padding:${css(28)}"><div class="col st" style="gap:${css(14)};justify-content:${css("center")}"><span class="ms" style="font-size:${css(72)};color:${css("var(--primary)")}">storefront</span><h2 class="t-headlineMedium" style="font-weight:${css(700)};text-align:${css("center")}">${esc(`Shop`)}</h2><p class="t-bodyMedium" style="text-align:${css("center")}">${esc(`Sign in to shop`)}</p><label class="field" data-stop><span class="field-label">${esc(`Email`)}</span><span class="field-box"><span class="ms">email</span><input type="email" data-key="Login.0.0.3" data-input="${ui.on((v) => { app.email = v; app.notify(); })}" value="${esc(app.email ?? "")}" /></span></label><label class="field" data-stop><span class="field-label">${esc(`Password`)}</span><span class="field-box"><span class="ms">lock</span><input type="password" data-key="Login.0.0.4" data-input="${ui.on((v) => { app.clave = v; app.notify(); })}" data-enter="${ui.on(async () => { if (app.entrar()) { app.home(router, 'Catalogo'); } })}" value="${esc(app.clave ?? "")}" /></span></label>${(app.error.length > 0) ? `<p class="t-bodyLarge" style="color:${css("var(--error)")}">${esc(`${app.error}`)}</p>` : ""}<button type="button" class="btn btn-filled" data-click="${ui.on(async () => { if (app.entrar()) { app.home(router, 'Catalogo'); } })}" data-stop><span class="ms">login</span>${esc(`Log in`)}</button><p class="t-bodySmall" style="text-align:${css("center")}">${esc(`Try demo@tienda.com and 1234`)}</p></div></div></div>`,
  });
};

SCREENS["Catalogo"] = (app, ui, router) => {
  return dmsScreen(ui, router, {
    title: `Hello, ${app.usuario}`,
    back: true,
    actions: [{ icon: "shopping_cart", badge: `${app.unidades}`, on: ui.on(async () => { app.go(router, 'Carrito'); }) }, { icon: "logout", badge: null, on: ui.on(async () => { app.salir(); app.home(router, 'Login'); }) }],
    fab: null,
    body: `<div class="col st"><div style="padding:${css(12)}"><label class="field" data-stop><span class="field-box"><span class="ms">search</span><input type="text" data-key="Catalogo.0.0" placeholder="${esc(`Search products`)}" data-input="${ui.on((v) => { app.busqueda = v; app.notify(); })}" value="${esc(app.busqueda ?? "")}" /></span></label></div><div style="padding:${css(6)}"><div class="row wrap" style="gap:${css(6)};align-items:${css("center")}"><button type="button" class="chip${(app.categoria == 'Clothes') ? " on" : ""}" data-click="${ui.on(async () => { app.elegir('Clothes'); })}" data-stop>${esc(`Clothes`)}</button><button type="button" class="chip${(app.categoria == 'Home') ? " on" : ""}" data-click="${ui.on(async () => { app.elegir('Home'); })}" data-stop>${esc(`Home`)}</button><button type="button" class="chip${(app.categoria == 'Electronics') ? " on" : ""}" data-click="${ui.on(async () => { app.elegir('Electronics'); })}" data-stop>${esc(`Electronics`)}</button></div></div><div class="list" style="padding:${css(8)}">${(app.visibles).map((p, i) => `<div class="item"><div class="card tap" data-click="${ui.on(async () => { app.go(router, 'Producto', p); })}" style="padding:${css(10)}"><div class="row" style="gap:${css(12)};align-items:${css("center")}"><div class="box" style="height:${css(64)};width:${css(64)};background:${css(p.color)};border-radius:${css(14)}"><div class="center"><span class="ms" style="font-size:${css(32)};color:${css("#FFFFFF")}">${esc(p.icono)}</span></div></div><div class="grow" style="flex:${css(1)}"><div class="col" style="gap:${css(2)};align-items:${css("flex-start")}"><h4 class="t-titleMedium">${esc(`${p.nombre}`)}</h4><p class="t-bodySmall">${esc(`${p.categoria}`)}</p><p class="t-bodyLarge" style="color:${css("var(--primary)")};font-weight:${css(700)}">${esc(`${app.precio(p.precio)}`)}</p></div></div><button class="icon-btn" type="button" title="${esc(`Add to cart`)}" aria-label="${esc(`Add to cart`)}" data-click="${ui.on(async () => { app.agregar(p); })}" data-stop><span class="ms">add_shopping_cart</span></button></div></div></div>`).join("")}${(app.visibles).length === 0 ? `<p class="empty">${esc(`No products match.`)}</p>` : ""}</div></div>`,
  });
};

SCREENS["Producto"] = (app, ui, router) => {
  const arg = app.arg("Producto");
  if (arg === undefined) return dmsMissing(ui, router);
  return dmsScreen(ui, router, {
    title: `${arg.nombre}`,
    back: true,
    actions: [{ icon: "shopping_cart", badge: `${app.unidades}`, on: ui.on(async () => { app.go(router, 'Carrito'); }) }],
    fab: null,
    body: `<div class="col st" style="gap:${css(12)};padding:${css(16)}"><div class="box" style="height:${css(220)};background:${css(arg.color)};border-radius:${css(24)}"><div class="center"><span class="ms" style="font-size:${css(110)};color:${css("#FFFFFF")}">${esc(arg.icono)}</span></div></div><h2 class="t-headlineSmall" style="font-weight:${css(700)}">${esc(`${arg.nombre}`)}</h2><button type="button" class="chip${(false) ? " on" : ""}" data-stop><span class="ms">shopping_bag</span>${esc(`${arg.categoria}`)}</button><p class="t-bodyLarge">${esc(`${arg.descripcion}`)}</p><h2 class="t-headlineMedium" style="color:${css("var(--primary)")}">${esc(`${app.precio(arg.precio)}`)}</h2><div class="grow"></div><button type="button" class="btn btn-filled" data-click="${ui.on(async () => { app.agregar(arg); })}" data-stop><span class="ms">add_shopping_cart</span>${esc(`Add to cart`)}</button><button type="button" class="btn btn-outlined" data-click="${ui.on(async () => { app.go(router, 'Carrito'); })}" data-stop><span class="ms">shopping_cart</span>${esc(`View cart`)}</button></div>`,
  });
};

SCREENS["Carrito"] = (app, ui, router) => {
  return dmsScreen(ui, router, {
    title: `Cart`,
    back: true,
    actions: [],
    fab: null,
    body: `<div class="col st"><div class="list sep">${(app.carrito).map((l, i) => `<div class="item"><div class="row" style="align-items:${css("center")}"><div class="grow" style="flex:${css(1)}"><div class="tile"><div class="tile-text"><div class="tile-title">${esc(`${l.producto.nombre}`)}</div><div class="tile-sub">${esc(`${l.cantidad} × ${app.precio(l.producto.precio)}`)}</div></div><span class="tile-trail">${esc(`${app.precio(l.total)}`)}</span></div></div><button class="icon-btn" type="button" data-click="${ui.on(async () => { app.quitar(l); })}" data-stop><span class="ms">remove_circle_outline</span></button><button class="icon-btn" type="button" data-click="${ui.on(async () => { app.sumar(l); })}" data-stop><span class="ms">add_circle_outline</span></button></div></div>`).join("")}${(app.carrito).length === 0 ? `<p class="empty">${esc(`Your cart is empty.`)}</p>` : ""}</div><div style="padding:${css(16)}"><div class="col st" style="gap:${css(12)}"><div class="row" style="justify-content:${css("space-between")};align-items:${css("center")}"><h3 class="t-titleLarge">${esc(`Total`)}</h3><h3 class="t-titleLarge" style="font-weight:${css(700)}">${esc(`${app.precio(app.total)}`)}</h3></div><button type="button" class="btn btn-filled" ${(app.carrito.length > 0) ? "" : "disabled"} data-click="${ui.on(async () => { app.pagar(); app.go(router, 'Gracias'); })}" data-stop><span class="ms">payments</span>${esc(`Payable`)}</button></div></div></div>`,
  });
};

SCREENS["Gracias"] = (app, ui, router) => {
  return dmsScreen(ui, router, {
    title: null,
    back: true,
    actions: [],
    fab: null,
    body: `<div class="center"><div style="padding:${css(28)}"><div class="col" style="gap:${css(14)};justify-content:${css("center")};align-items:${css("center")}"><span class="ms" style="font-size:${css(96)};color:${css("var(--primary)")}">check_circle</span><h2 class="t-headlineSmall" style="text-align:${css("center")}">${esc(`Thank you for your purchase, ${app.usuario}!`)}</h2><p class="t-bodyLarge" style="text-align:${css("center")}">${esc(`${app.ultimoPedido}`)}</p><button type="button" class="btn btn-filled" data-click="${ui.on(async () => { app.home(router, 'Catalogo'); })}" data-stop><span class="ms">storefront</span>${esc(`Continue shopping`)}</button></div></div></div>`,
  });
};

