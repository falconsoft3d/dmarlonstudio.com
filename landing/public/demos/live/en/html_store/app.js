// Web shop: users, products, cart and orders. The screens use it as app.


const PRODUCTOS = [
  { nombre: "Basic T-shirt", categoria: "Clothes", precio: 12.9, icono: "checkroom", color: "#26A69A", descripcion: "Organic cotton, straight fit. Sizes S to XL." },
  { nombre: "Hoodie", categoria: "Clothes", precio: 34.5, icono: "checkroom", color: "#5C6BC0", descripcion: "Fleece lining and kangaroo pocket." },
  { nombre: "Table lamp", categoria: "Home", precio: 24, icono: "light", color: "#FFA726", descripcion: "Dimmable warm light, wooden base." },
  { nombre: "Nordic chair", categoria: "Home", precio: 59, icono: "chair", color: "#8D6E63", descripcion: "Beech legs and padded seat." },
  { nombre: "Headphones", categoria: "Electronics", precio: 79.99, icono: "headphones", color: "#42A5F5", descripcion: "Wireless, with noise cancelling and 30 h of battery." },
  { nombre: "Sports watch", categoria: "Electronics", precio: 129, icono: "watch", color: "#EF5350", descripcion: "GPS, heart rate and water resistant." },
];

class Linea {
  constructor(producto) {
    this.producto = producto;
    this.cantidad = 1;
  }

  get total() {
    return this.producto.precio * this.cantidad;
  }
}

class App extends DmsApp {
  // ---------------------------------------------------------- usuarios
  /// Usuarios de prueba: correo → [contraseña, nombre].
  usuarios = { "demo@tienda.com": ["1234", "Ana"] };
  email = "";
  clave = "";
  error = "";
  usuario = null;

  entrar() {
    const u = this.usuarios[this.email.trim().toLowerCase()];
    if (!u || u[0] !== this.clave) {
      this.error = "Wrong email or password.";
      this.notify();
      return false;
    }
    this.usuario = u[1];
    this.error = "";
    this.clave = "";
    this.notify();
    return true;
  }

  salir() {
    this.usuario = null;
    this.carrito = [];
    this.notify();
  }

  // ---------------------------------------------------------- catálogo
  productos = PRODUCTOS;
  busqueda = "";
  categoria = "";

  get visibles() {
    const q = this.busqueda.trim().toLowerCase();
    return this.productos
      .filter((p) => !this.categoria || p.categoria === this.categoria)
      .filter((p) => p.nombre.toLowerCase().includes(q));
  }

  elegir(c) {
    this.categoria = this.categoria === c ? "" : c;
    this.notify();
  }

  precio(v) {
    return v.toFixed(2).replace(".", ",") + " €";
  }

  // ----------------------------------------------------------- carrito
  carrito = [];

  get unidades() {
    return this.carrito.reduce((s, l) => s + l.cantidad, 0);
  }

  get total() {
    return this.carrito.reduce((s, l) => s + l.total, 0);
  }

  agregar(p) {
    const l = this.carrito.find((l) => l.producto === p);
    if (l) l.cantidad++;
    else this.carrito.push(new Linea(p));
    this.notify();
  }

  sumar(l) {
    l.cantidad++;
    this.notify();
  }

  quitar(l) {
    l.cantidad--;
    if (l.cantidad === 0) this.carrito = this.carrito.filter((x) => x !== l);
    this.notify();
  }

  // ------------------------------------------------------------ pedido
  numero = 1000;
  ultimoPedido = "";

  pagar() {
    if (this.carrito.length === 0) return;
    this.numero++;
    this.ultimoPedido = "PED-" + this.numero + " · " + this.precio(this.total);
    this.carrito = [];
    this.notify();
  }
}
