part of 'tk_examples.dart';

// Web con Next.js hecha con pantallas: la tienda de Flutter (las mismas
// pantallas) con la lógica en JavaScript.

TkExample _webStore(String Function(String) t) {
  final base = _flutterStore(t);
  String q(String s) => t(s).replaceAll(r'\', r'\\').replaceAll('"', r'\"');
  final code =
      '''// ${t(markTr('Tienda web: usuarios, productos, carrito y pedidos. Las pantallas lo usan como app.'))}
import { DmsApp } from "./dms";

const PRODUCTOS = [
  { nombre: "${q(markTr('Camiseta básica'))}", categoria: "${q(markTr('Ropa'))}", precio: 12.9, icono: "checkroom", color: "#26A69A", descripcion: "${q(markTr('Algodón orgánico, corte recto. Tallas de la S a la XL.'))}" },
  { nombre: "${q(markTr('Sudadera con capucha'))}", categoria: "${q(markTr('Ropa'))}", precio: 34.5, icono: "checkroom", color: "#5C6BC0", descripcion: "${q(markTr('Interior afelpado y bolsillo canguro.'))}" },
  { nombre: "${q(markTr('Lámpara de mesa'))}", categoria: "${q(markTr('Hogar'))}", precio: 24, icono: "light", color: "#FFA726", descripcion: "${q(markTr('Luz cálida regulable, base de madera.'))}" },
  { nombre: "${q(markTr('Silla nórdica'))}", categoria: "${q(markTr('Hogar'))}", precio: 59, icono: "chair", color: "#8D6E63", descripcion: "${q(markTr('Patas de haya y asiento acolchado.'))}" },
  { nombre: "${q(markTr('Auriculares'))}", categoria: "${q(markTr('Electrónica'))}", precio: 79.99, icono: "headphones", color: "#42A5F5", descripcion: "${q(markTr('Inalámbricos, con cancelación de ruido y 30 h de batería.'))}" },
  { nombre: "${q(markTr('Reloj deportivo'))}", categoria: "${q(markTr('Electrónica'))}", precio: 129, icono: "watch", color: "#EF5350", descripcion: "${q(markTr('GPS, pulso y resistente al agua.'))}" },
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

export class App extends DmsApp {
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
      this.error = "${q(markTr('Correo o contraseña incorrectos.'))}";
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
''';
  final design = TkDesign.fromJson({
    ...base.design.toJson(),
    'target': tkTargetWebNext,
  });
  return TkExample(
    'web_next_store',
    t(markTr('Tienda web (Next.js)')),
    t(
      markTr(
        'Una web de verdad hecha con pantallas: login, catálogo con búsqueda y categorías, ficha, carrito y pago, adaptable a escritorio y móvil.',
      ),
    ),
    design,
    code,
  );
}
