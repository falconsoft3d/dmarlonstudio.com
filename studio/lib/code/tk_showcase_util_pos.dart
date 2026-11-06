part of 'tk_examples.dart';

// ------------------------------------------------------------ punto de venta
/// Un punto de venta al estilo del de Odoo: categorías y productos a la
/// derecha, el pedido con su teclado numérico a la izquierda, el cobro en
/// efectivo o con tarjeta, el recibo y los pedidos del día en SQLite.
TkExample tkUtilPos(String Function(String) t) {
  const purple = '#714b67', teal = '#017e84', white = '#ffffff';
  const ink = '#1b1d22', muted = '#5f6672', key = '#f0eef0';
  final app = t(markTr('Punto de venta'));
  TkWidget inside(TkWidget w, String parent) => w..parent = parent;
  final categories = [
    t(markTr('Cafés y tés')),
    t(markTr('Bebidas')),
    t(markTr('Dulces')),
    t(markTr('Salados')),
  ];
  // Teclado numérico de Odoo: cuatro filas de cuatro teclas.
  final keys = [
    ('Key1', '1'),
    ('Key2', '2'),
    ('Key3', '3'),
    ('ModeQty', t(markTr('Cant.'))),
    ('Key4', '4'),
    ('Key5', '5'),
    ('Key6', '6'),
    ('ModeDisc', t(markTr('Desc. %'))),
    ('Key7', '7'),
    ('Key8', '8'),
    ('Key9', '9'),
    ('ModePrice', t(markTr('Precio'))),
    ('KeySign', '+/-'),
    ('Key0', '0'),
    ('KeyComma', ','),
    ('KeyBack', '⌫'),
  ];
  final design =
      TkDesign(
          width: 1100,
          height: 720,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {
            'create': 'form_create',
            'close': 'form_close',
            'key': 'form_key',
          },
        )
        ..widgets.addAll([
          // Barra de arriba.
          _w('Frame', 'TopBar', 0, 0, 1100, 48, {'bg': purple}),
          inside(
            _w('Label', 'Brand', 16, 8, 190, 32, {
              ..._label(app),
              'bg': purple,
              'fg': white,
              'font_size': 17,
              'font_bold': true,
            }),
            'TopBar',
          ),
          inside(
            _w('Label', 'Session', 214, 12, 250, 24, {
              'text': '',
              'anchor': 'w',
              'bg': purple,
              'fg': white,
            }),
            'TopBar',
          ),
          inside(
            _w('Label', 'OdooState', 470, 12, 210, 24, {
              'text': '',
              'anchor': 'e',
              'bg': purple,
              'fg': '#f3e3ef',
            }),
            'TopBar',
          ),
          inside(
            _w(
              'Button',
              'BtnOdoo',
              690,
              8,
              88,
              32,
              {'text': 'Odoo ▾', 'bg': '#8c6a84', 'fg': white},
              {'command': 'BtnOdoo_click'},
            ),
            'TopBar',
          ),
          inside(
            _w(
              'Button',
              'BtnOrders',
              786,
              8,
              140,
              32,
              {'text': t(markTr('Pedidos')), 'bg': '#8c6a84', 'fg': white},
              {'command': 'BtnOrders_click'},
            ),
            'TopBar',
          ),
          inside(
            _w(
              'Button',
              'BtnClear',
              936,
              8,
              148,
              32,
              {
                'text': t(markTr('Vaciar pedido')),
                'bg': '#8c6a84',
                'fg': white,
              },
              {'command': 'BtnClear_click'},
            ),
            'TopBar',
          ),
          // El pedido, a la izquierda.
          _w('Frame', 'Left', 0, 48, 420, 648, {'bg': white}),
          inside(
            _w(
              'Treeview',
              'Lines',
              8,
              8,
              404,
              300,
              {
                'columns': [
                  'product|${t(markTr('Producto'))}|128',
                  'qty|${t(markTr('Cant.'))}|38',
                  'price|${t(markTr('Precio'))}|60',
                  'disc|${t(markTr('Desc.'))}|42',
                  'subtotal|${t(markTr('Subtotal'))}|70',
                ].join('\n'),
              },
              {'select': 'Lines_select'},
            ),
            'Left',
          ),
          inside(
            _w('Label', 'Taxes', 12, 314, 396, 22, {
              'text': '',
              'anchor': 'e',
              'bg': white,
              'fg': muted,
            }),
            'Left',
          ),
          inside(
            _w('Label', 'Total', 12, 336, 396, 36, {
              'text': '',
              'anchor': 'e',
              'bg': white,
              'fg': ink,
              'font_size': 22,
              'font_bold': true,
            }),
            'Left',
          ),
          inside(
            _w(
              'Button',
              'BtnCustomer',
              8,
              384,
              132,
              52,
              {'text': t(markTr('Cliente'))},
              {'command': 'BtnCustomer_click'},
            ),
            'Left',
          ),
          inside(
            _w(
              'Button',
              'BtnPay',
              8,
              444,
              132,
              196,
              {
                'text': t(markTr('Cobrar')),
                'bg': purple,
                'fg': white,
                'font_size': 18,
                'font_bold': true,
              },
              {'command': 'BtnPay_click'},
            ),
            'Left',
          ),
          for (final (i, (name, text)) in keys.indexed)
            inside(
              _w(
                'Button',
                name,
                148 + (i % 4) * 66,
                384 + (i ~/ 4) * 64,
                64,
                62,
                {
                  'text': text,
                  'bg': key,
                  'font_size': name.startsWith('Mode') ? 12 : 16,
                },
                {'command': '${name}_click'},
              ),
              'Left',
            ),
          // Productos, a la derecha.
          _w('Label', 'LblSearch', 436, 64, 64, 24, {
            ..._label(t(markTr('Buscar'))),
            'bg': _paper,
          }),
          _w(
            'Entry',
            'Search',
            500,
            60,
            260,
            32,
            {'font_size': 13},
            {'key_up': 'Search_key_up', 'enter_key': 'Search_return'},
          ),
          _w(
            'Button',
            'BtnClearSearch',
            764,
            60,
            36,
            32,
            {'text': '✕'},
            {'command': 'BtnClearSearch_click'},
          ),
          for (final (i, text) in [t(markTr('Todo')), ...categories].indexed)
            _w(
              'Button',
              i == 0 ? 'BtnCatAll' : 'BtnCat$i',
              436 + i * 130,
              104,
              124,
              36,
              {'text': text, 'bg': white},
              {'command': i == 0 ? 'BtnCatAll_click' : 'BtnCat${i}_click'},
            ),
          _w('Frame', 'Products', 436, 152, 652, 532, {'bg': _paper}),
          _w('StatusBar', 'Status', 0, 696, 1100, 24, {
            'text': '',
            'icon': 'info',
          }),
        ]);
  String product(int id, String name, int category, String price) =>
      '    ($id, ${_py(name)}, $category, $price, 0.10),';
  final products = [
    product(1, t(markTr('Café solo')), 0, '1.30'),
    product(2, t(markTr('Café con leche')), 0, '1.60'),
    product(3, t(markTr('Cortado')), 0, '1.40'),
    product(4, t(markTr('Capuchino')), 0, '2.20'),
    product(5, t(markTr('Té verde')), 0, '1.50'),
    product(6, t(markTr('Agua mineral')), 1, '1.20'),
    product(7, t(markTr('Zumo de naranja')), 1, '2.50'),
    product(8, t(markTr('Refresco de cola')), 1, '1.80'),
    product(9, t(markTr('Batido de chocolate')), 1, '2.80'),
    product(10, t(markTr('Caña de cerveza')), 1, '2.00'),
    product(11, t(markTr('Cruasán')), 2, '1.50'),
    product(12, t(markTr('Magdalena')), 2, '1.10'),
    product(13, t(markTr('Napolitana de chocolate')), 2, '1.70'),
    product(14, t(markTr('Tarta de queso')), 2, '3.50'),
    product(15, t(markTr('Churros (6)')), 2, '2.40'),
    product(16, t(markTr('Tostada con tomate')), 3, '2.20'),
    product(17, t(markTr('Bocadillo de jamón')), 3, '4.50'),
    product(18, t(markTr('Sándwich mixto')), 3, '3.20'),
    product(19, t(markTr('Tortilla de patatas')), 3, '3.00'),
    product(20, t(markTr('Empanada gallega')), 3, '3.30'),
  ].join('\n');
  String pythonImages() {
    final b = StringBuffer('IMAGES = {\n');
    for (final MapEntry(key: id, value: png) in _tkPosImagesPng.entries) {
      b.writeln('    $id: (');
      for (var i = 0; i < png.length; i += 76) {
        final end = i + 76 < png.length ? i + 76 : png.length;
        b.writeln('        "${png.substring(i, end)}"');
      }
      b.writeln('    ),');
    }
    return (b..write('}')).toString();
  }

  final code =
      '''import datetime
import http.client
import http.cookiejar
import json
import math
import os
import queue
import shutil
import socket
import sqlite3
import sys
import threading
import tkinter as tk
import unicodedata
import urllib.error
import urllib.request
import uuid
from tkinter import filedialog, messagebox, ttk

APP = ${_py(app)}
SHOP = ${_py(t(markTr('Cafetería de demostración')))}
DB_FILE = "pos.sqlite"
IMAGE_DIR = "pos_images"  # imágenes propias, junto a la base de datos
IMAGE_SIZE = 96
THUMB_SIZE = 24
PURPLE, TEAL, WHITE, INK, MUTED = "$purple", "$teal", "$white", "$ink", "$muted"
PAPER, GREEN, RED, KEY = "$_paper", "#0a7a32", "#c62828", "$key"
CATEGORIES = ${TkPy.list(categories)}
ODOO_TIMEOUT = 10  # segundos
PRODUCT_LIMIT = 2000
# Catálogo de ejemplo: id, nombre, categoría, precio con IVA y tipo de IVA.
PRODUCTS = [
$products
]
SAMPLE_CUSTOMERS = ["Ana Torres", "Luis Moreno", "Marta Díaz", "Jorge Ruiz"]
WIDTH = 36  # caracteres del recibo
CASH = ${_py(t(markTr('Efectivo')))}
CARD = ${_py(t(markTr('Tarjeta')))}
CUSTOMER = ${_py(t(markTr('Cliente')))}
NO_CUSTOMER = ${_py(t(markTr('Sin cliente')))}
TAXES = ${_py(t(markTr('IVA incluido: {0}')))}
TOTAL = ${_py(t(markTr('Total: {0}')))}
SESSION = ${_py(t(markTr('Pedidos de hoy: {0} · {1}')))}
READY = ${_py(t(markTr('Pedidos guardados en {0}')))}
EMPTY = ${_py(t(markTr('Añada productos al pedido antes de pagar.')))}
NOT_POSITIVE = ${_py(t(markTr('El total del pedido debe ser mayor que cero.')))}
NO_MATCH = ${_py(t(markTr('No hay productos que coincidan.')))}
ASK_CLEAR = ${_py(t(markTr('¿Vaciar el pedido actual?')))}
PAID = ${_py(t(markTr('Pedido {0} cobrado: {1} ({2}).')))}
COPIED = ${_py(t(markTr('Recibo copiado al portapapeles.')))}
PAY_TITLE = ${_py(t(markTr('Pago')))}
DUE = ${_py(t(markTr('Total a pagar')))}
TENDERED = ${_py(t(markTr('Importe entregado')))}
EXACT = ${_py(t(markTr('Exacto')))}
CHANGE = ${_py(t(markTr('Cambio: {0}')))}
MISSING = ${_py(t(markTr('Falta: {0}')))}
PAY_HINT = ${_py(t(markTr('Escriba lo que entrega el cliente con el teclado de la izquierda o con el del ordenador.')))}
CARD_HINT = ${_py(t(markTr('Con tarjeta se cobra el importe exacto.')))}
BACK = ${_py(t(markTr('← Volver')))}
VALIDATE = ${_py(t(markTr('Validar')))}
PAID_TITLE = ${_py(t(markTr('Pedido cobrado')))}
NEW_ORDER = ${_py(t(markTr('Nuevo pedido')))}
COPY = ${_py(t(markTr('Copiar el recibo')))}
ORDERS_TITLE = ${_py(t(markTr('Pedidos de hoy')))}
SUMMARY = ${_py(t(markTr('Pedidos: {0} · Total {1} · Efectivo {2} · Tarjeta {3}')))}
COL_ORDER = ${_py(t(markTr('Pedido')))}
COL_TIME = ${_py(t(markTr('Hora')))}
COL_PAY = ${_py(t(markTr('Pago')))}
COL_TOTAL = ${_py(t(markTr('Total')))}
PICK_TITLE = ${_py(t(markTr('Elegir cliente')))}
PICK_NEW = ${_py(t(markTr('Nuevo cliente')))}
PICK_OK = ${_py(t(markTr('Elegir')))}
CANCEL = ${_py(t(markTr('Cancelar')))}
R_ORDER = ${_py(t(markTr('Pedido {0}')))}
R_CUSTOMER = ${_py(t(markTr('Cliente: {0}')))}
R_TOTAL = ${_py(t(markTr('TOTAL')))}
R_TAX = ${_py(t(markTr('IVA {0} %: base {1}  cuota {2}')))}
R_CHANGE = ${_py(t(markTr('Cambio')))}
R_THANKS = ${_py(t(markTr('¡Gracias por su visita!')))}
CHANGE_IMAGE = ${_py(t(markTr('Cambiar imagen…')))}
REMOVE_IMAGE = ${_py(t(markTr('Quitar imagen')))}
PICK_IMAGE = ${_py(t(markTr('Imagen de «{0}»')))}
IMAGE_FILES = ${_py(t(markTr('Imágenes PNG o GIF')))}
IMAGE_CHANGED = ${_py(t(markTr('Nueva imagen para «{0}».')))}
IMAGE_REMOVED = ${_py(t(markTr('«{0}» vuelve a tener su imagen de siempre.')))}
BAD_IMAGE = ${_py(t(markTr('No se pudo abrir la imagen: {0}')))}
TILE_HINT = ${_py(t(markTr('Clic derecho en un producto para cambiar su imagen.')))}
OTHER = ${_py(t(markTr('Otros')))}
MORE = ${_py(t(markTr('Más…')))}
ODOO_CONFIG = ${_py(t(markTr('Configurar Odoo…')))}
ODOO_DOWNLOAD = ${_py(t(markTr('Descargar productos')))}
ODOO_SYNC = ${_py(t(markTr('Sincronizar pedidos ({0} pendientes)')))}
ODOO_DEMO = ${_py(t(markTr('Volver al catálogo de ejemplo')))}
ODOO_OFF = ${_py(t(markTr('Odoo: no configurado')))}
ODOO_ON = ${_py(t(markTr('Odoo: conectado')))}
ODOO_DOWN = ${_py(t(markTr('Odoo: sin conexión')))}
ODOO_BUSY = ${_py(t(markTr('Odoo: conectando…')))}
ODOO_PENDING = ${_py(t(markTr(' · pendientes: {0}')))}
ODOO_TITLE = ${_py(t(markTr('Conexión con Odoo')))}
F_URL = ${_py(t(markTr('Dirección (URL)')))}
F_DB = ${_py(t(markTr('Base de datos (opcional)')))}
F_LOGIN = ${_py(t(markTr('Usuario')))}
F_PASSWORD = ${_py(t(markTr('Contraseña')))}
F_SHOW = ${_py(t(markTr('Mostrar')))}
F_PARTNER = ${_py(t(markTr('Cliente de las ventas sin cliente')))}
DEFAULT_PARTNER = ${_py(t(markTr('Cliente de mostrador')))}
ODOO_NOTE = ${_py(t(markTr('Use el usuario y la contraseña con los que entra en Odoo. La contraseña se guarda en la base de datos del punto de venta (pos.sqlite) de este equipo. Si el usuario tiene la verificación en dos pasos, use un usuario propio para el punto de venta, sin ella. Sin base de datos, se usa la única que tenga el servidor.')))}
TEST = ${_py(t(markTr('Probar conexión')))}
SAVE = ${_py(t(markTr('Guardar')))}
TESTING = ${_py(t(markTr('Probando la conexión…')))}
CONNECTED_AS = ${_py(t(markTr('Conectado como {0} ({1}), base de datos {2}.')))}
ERR_NEED_URL = ${_py(t(markTr('Escriba la dirección de Odoo, por ejemplo https://miempresa.odoo.com')))}
ERR_NEED_LOGIN = ${_py(t(markTr('Escriba el usuario y la contraseña.')))}
ERR_NETWORK = ${_py(t(markTr('No se pudo conectar con {0}: {1}')))}
ERR_TIMEOUT = ${_py(t(markTr('Odoo no responde (más de {0} s).')))}
ERR_NOT_ODOO = ${_py(t(markTr('La dirección no parece de un servidor Odoo ({0}).')))}
ERR_LOGIN = ${_py(t(markTr('Usuario o contraseña incorrectos.')))}
ERR_2FA = ${_py(t(markTr('Este usuario tiene la verificación en dos pasos: desactívela para él o use un usuario propio para el punto de venta.')))}
ERR_DB = ${_py(t(markTr('No se encontró la base de datos «{0}».')))}
ERR_NEED_DB = ${_py(t(markTr('El servidor tiene varias bases de datos (o no deja verlas): escriba cuál usar.')))}
ERR_SERVER = ${_py(t(markTr('Odoo respondió con un error: {0}')))}
DOWNLOADING = ${_py(t(markTr('Descargando los productos de Odoo…')))}
DOWNLOADED = ${_py(t(markTr('Descargados {0} productos de Odoo en {1} categorías.')))}
NO_PRODUCTS = ${_py(t(markTr('Odoo no tiene productos a la venta para el punto de venta.')))}
DEMO_BACK = ${_py(t(markTr('De nuevo con el catálogo de ejemplo.')))}
ASK_DEMO = ${_py(t(markTr('¿Volver al catálogo de ejemplo? Se quitan los productos descargados de Odoo.')))}
NEED_CONFIG = ${_py(t(markTr('Configure primero la conexión con Odoo.')))}
SETTINGS_SAVED = ${_py(t(markTr('Conexión con Odoo guardada.')))}
SENT = ${_py(t(markTr('Pedido {0} enviado a Odoo: {1}.')))}
NOT_SENT = ${_py(t(markTr('El pedido {0} queda pendiente de enviar a Odoo: {1}')))}
LOCAL_ONLY = ${_py(t(markTr('El pedido lleva productos del catálogo de ejemplo y no se envía a Odoo: descargue antes los productos de Odoo.')))}
R_ODOO = ${_py(t(markTr('Pedido de venta: {0}')))}
R_ODOO_PENDING = ${_py(t(markTr('Odoo: pendiente de enviar')))}


# ------------------------------------------------------------------ utilidades
def data_dir():
    """Carpeta de datos del usuario: AppData en Windows, Application Support
    en macOS y ~/.local/share en Linux."""
    home = os.path.expanduser("~")
    if sys.platform == "win32":
        base = os.environ.get("APPDATA") or home
    elif sys.platform == "darwin":
        base = os.path.join(home, "Library", "Application Support")
    else:
        base = os.environ.get("XDG_DATA_HOME") or os.path.join(home, ".local", "share")
    path = os.path.join(base, "DMarlon Studio")
    os.makedirs(path, exist_ok=True)
    return path


def money(value):
    """1234.5 -> 1.234,50 € (formato español)."""
    value = 0.0 if abs(value) < 0.005 else value
    text = "{:,.2f}".format(value).replace(",", "_").replace(".", ",").replace("_", ".")
    return text + " €"


def number(value):
    """Una cantidad sin decimales de más: 2, 0,5, -1."""
    if abs(value - round(value)) < 1e-9:
        return str(int(round(value)))
    return ("%g" % value).replace(".", ",")


def parse_number(text):
    text = (text or "").strip().replace(".", "").replace(",", ".")
    if text in ("", "-", ".", "-."):
        return 0.0
    return float(text)


def plain(text):
    """Sin mayúsculas ni tildes, para buscar."""
    text = unicodedata.normalize("NFD", text.lower())
    return "".join(c for c in text if unicodedata.category(c) != "Mn")


def two_columns(left, right, width=WIDTH):
    space = max(1, width - len(left) - len(right))
    return left + " " * space + right


# -------------------------------------------------------------------- pedido
class Order:
    """Las líneas del pedido y el teclado numérico de Odoo: la tecla escribe
    en la cantidad, el descuento o el precio de la línea elegida."""

    FIELDS = {"qty": "qty", "disc": "discount", "price": "price"}

    def __init__(self):
        self.lines = []
        self.customer = ""
        self.selected = None
        self.mode = "qty"
        self.buffer = ""

    @staticmethod
    def line_total(line):
        return round(line["qty"] * line["price"] * (1 - line["discount"] / 100.0), 2)

    def total(self):
        return round(sum(self.line_total(line) for line in self.lines), 2)

    def taxes(self):
        """[(tipo, base, cuota)]: los precios llevan el IVA incluido."""
        gross = {}
        for line in self.lines:
            gross[line["tax"]] = gross.get(line["tax"], 0.0) + self.line_total(line)
        out = []
        for rate in sorted(gross):
            base = round(gross[rate] / (1 + rate), 2)
            out.append((rate, base, round(gross[rate] - base, 2)))
        return out

    def tax_total(self):
        return round(sum(tax for _, _, tax in self.taxes()), 2)

    def select(self, index):
        self.selected = index if index is not None and 0 <= index < len(self.lines) else None
        self.buffer = ""

    def set_mode(self, mode):
        self.mode = mode
        self.buffer = ""

    def add(self, product):
        """Suma una unidad: a la línea del mismo producto si la hay."""
        pid, name, _, price, tax = product
        for index, line in enumerate(self.lines):
            if line["id"] == pid and line["price"] == price and not line["discount"] and line["qty"] > 0:
                line["qty"] += 1
                self.select(index)
                return index
        self.lines.append({
            "id": pid, "name": name, "qty": 1.0, "price": price,
            "list_price": price, "discount": 0.0, "tax": tax,
        })
        self.select(len(self.lines) - 1)
        return self.selected

    def remove(self, index):
        del self.lines[index]
        self.select(min(index, len(self.lines) - 1) if self.lines else None)

    def clean(self):
        """Quita las líneas con cantidad cero (antes de cobrar)."""
        self.lines = [line for line in self.lines if line["qty"] != 0]
        self.select(len(self.lines) - 1 if self.lines else None)

    def press(self, key):
        """Una tecla: "0"-"9", ",", "back" o "sign". True si cambia algo."""
        if self.selected is None:
            return False
        line = self.lines[self.selected]
        field = self.FIELDS[self.mode]
        if key == "sign":
            if self.mode == "disc":
                return False
            line[field] = -line[field] if line[field] else 0.0
            if self.buffer.startswith("-"):
                self.buffer = self.buffer[1:]
            elif self.buffer:
                self.buffer = "-" + self.buffer
            return True
        if key == "back":
            if not self.buffer:
                # Como en Odoo: primero a cero; otra vez, fuera la línea.
                if self.mode == "qty":
                    if line["qty"] == 0:
                        self.remove(self.selected)
                    else:
                        line["qty"] = 0.0
                elif self.mode == "disc":
                    line["discount"] = 0.0
                else:
                    line["price"] = line["list_price"]
                return True
            self.buffer = self.buffer[:-1]
            if self.buffer == "-":
                self.buffer = ""
        elif key == ",":
            if "," in self.buffer:
                return False
            self.buffer = (self.buffer or "0") + ","
        elif key.isdigit():
            if len(self.buffer.replace("-", "")) >= 8:
                return False
            if "," in self.buffer and len(self.buffer.split(",")[1]) >= 2:
                return False
            self.buffer += key
        else:
            return False
        value = parse_number(self.buffer)
        if self.mode == "disc" and value > 100:
            value = 100.0
            self.buffer = "100"
        line[field] = value
        return True


class Payment:
    """El cobro de un total: en efectivo, con lo entregado y el cambio, o
    con tarjeta, por el importe exacto."""

    def __init__(self, total):
        self.total = total
        self.method = "cash"
        self.buffer = ""

    def amount(self):
        if self.method == "card":
            return self.total
        return parse_number(self.buffer)

    def change(self):
        return round(self.amount() - self.total, 2)

    def valid(self):
        return self.total > 0 and self.amount() >= self.total - 0.004

    def set_amount(self, value):
        self.buffer = ("%.2f" % value).replace(".", ",")

    def press(self, key):
        if self.method == "card":
            return False
        if key == "back":
            self.buffer = self.buffer[:-1]
        elif key == ",":
            if "," in self.buffer:
                return False
            self.buffer = (self.buffer or "0") + ","
        elif key.isdigit():
            if "," in self.buffer and len(self.buffer.split(",")[1]) >= 2:
                return False
            if len(self.buffer) >= 9:
                return False
            self.buffer = (self.buffer if self.buffer != "0" else "") + key
        else:
            return False
        return True


# ------------------------------------------------------------ base de datos
def open_db(path):
    db = sqlite3.connect(path)
    db.row_factory = sqlite3.Row
    db.executescript("""
        CREATE TABLE IF NOT EXISTS pos_order (
            id INTEGER PRIMARY KEY,
            created TEXT NOT NULL,
            day TEXT NOT NULL,
            customer TEXT NOT NULL DEFAULT '',
            method TEXT NOT NULL,
            total REAL NOT NULL,
            tax REAL NOT NULL,
            tendered REAL NOT NULL,
            change REAL NOT NULL,
            receipt TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS pos_line (
            id INTEGER PRIMARY KEY,
            order_id INTEGER NOT NULL REFERENCES pos_order(id),
            product TEXT NOT NULL,
            qty REAL NOT NULL,
            price REAL NOT NULL,
            discount REAL NOT NULL,
            tax_rate REAL NOT NULL,
            subtotal REAL NOT NULL);
        CREATE TABLE IF NOT EXISTS customer (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL UNIQUE);
        CREATE TABLE IF NOT EXISTS product_image (
            product_id INTEGER PRIMARY KEY,
            file TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS setting (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS odoo_product (
            odoo_id INTEGER PRIMARY KEY,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            price REAL NOT NULL,
            tax REAL NOT NULL,
            included INTEGER NOT NULL,
            code TEXT NOT NULL DEFAULT '',
            barcode TEXT NOT NULL DEFAULT '',
            image TEXT NOT NULL DEFAULT '');
    """)
    # Columnas nuevas en una base de datos de antes.
    add_columns(db, "pos_order", (
        ("ref", "TEXT NOT NULL DEFAULT ''"), ("odoo_state", "TEXT NOT NULL DEFAULT ''"),
        ("odoo_id", "INTEGER"), ("odoo_name", "TEXT NOT NULL DEFAULT ''"), ("odoo_error", "TEXT NOT NULL DEFAULT ''"),
    ))
    add_columns(db, "pos_line", (
        ("product_key", "INTEGER"), ("odoo_product_id", "INTEGER"), ("price_include", "INTEGER NOT NULL DEFAULT 1"),
    ))
    if not db.execute("SELECT COUNT(*) FROM customer").fetchone()[0]:
        db.executemany("INSERT INTO customer (name) VALUES (?)", [(n,) for n in SAMPLE_CUSTOMERS])
    db.commit()
    return db


def add_columns(db, table, columns):
    have = {row[1] for row in db.execute("PRAGMA table_info(%s)" % table)}
    for name, kind in columns:
        if name not in have:
            db.execute("ALTER TABLE %s ADD COLUMN %s %s" % (table, name, kind))


def load_settings(db):
    return {row["key"]: row["value"] for row in db.execute("SELECT key, value FROM setting")}


def store_settings(db, values):
    db.executemany(
        "INSERT OR REPLACE INTO setting (key, value) VALUES (?, ?)",
        [(key, str(value)) for key, value in values.items()],
    )
    db.commit()


def order_number(order_id):
    return "%05d" % order_id


def receipt_text(order_id, when, order, payment):
    rule = "-" * WIDTH
    out = [SHOP.upper().center(WIDTH), "", two_columns(R_ORDER.format(order_number(order_id)), when.strftime("%d/%m/%Y %H:%M"))]
    if order.customer:
        out.append(R_CUSTOMER.format(order.customer))
    out.append(rule)
    for line in order.lines:
        out.append(line["name"][:WIDTH])
        detail = "  %s x %s" % (number(line["qty"]), money(line["price"]))
        if line["discount"]:
            detail += " -" + number(line["discount"]) + "%"
        out.append(two_columns(detail, money(order.line_total(line))))
    out.append(rule)
    out.append(two_columns(R_TOTAL, money(order.total())))
    for rate, base, tax in order.taxes():
        out.append(R_TAX.format(number(rate * 100), money(base), money(tax)))
    out.append(two_columns(CASH if payment.method == "cash" else CARD, money(payment.amount())))
    if payment.method == "cash":
        out.append(two_columns(R_CHANGE, money(payment.change())))
    out.append(rule)
    out.append(R_THANKS.center(WIDTH))
    return "\\n".join(out)


def save_order(db, order, payment, when=None, odoo=None):
    """Guarda el pedido cobrado; devuelve (id, recibo).

    odoo: {clave del producto: (id en Odoo, precio con impuestos)} si hay
    conexión con Odoo. Si todos los productos vienen de Odoo, el pedido
    queda «pending» hasta que se envíe; si no, «local» (no se envía).
    """
    when = when or datetime.datetime.now()
    if odoo is None:
        state = ""
    else:
        state = "pending" if all(line["id"] in odoo for line in order.lines) else "local"
    odoo = odoo or {}
    cursor = db.execute(
        "INSERT INTO pos_order (created, day, customer, method, total, tax, tendered, change, receipt, odoo_state) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, '', ?)",
        (when.isoformat(timespec="seconds"), when.date().isoformat(), order.customer, payment.method,
         order.total(), order.tax_total(), payment.amount(), max(0.0, payment.change()), state),
    )
    order_id = cursor.lastrowid
    rows = []
    for l in order.lines:
        odoo_id, included = odoo.get(l["id"], (None, 1))
        rows.append((order_id, l["name"], l["qty"], l["price"], l["discount"], l["tax"], order.line_total(l),
                     l["id"], odoo_id, included))
    db.executemany(
        "INSERT INTO pos_line (order_id, product, qty, price, discount, tax_rate, subtotal, product_key, "
        "odoo_product_id, price_include) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        rows,
    )
    receipt = receipt_text(order_id, when, order, payment)
    # Referencia única del pedido: en Odoo es la del cliente, para no repetirlo.
    ref = "TPV-%s-%s" % (order_number(order_id), uuid.uuid4().hex[:8])
    db.execute("UPDATE pos_order SET receipt = ?, ref = ? WHERE id = ?", (receipt, ref, order_id))
    db.commit()
    return order_id, receipt


def receipt_with_odoo(row):
    """El recibo con el pedido de venta de Odoo (o que está pendiente)."""
    if row["odoo_name"]:
        extra = R_ODOO.format(row["odoo_name"])
    elif row["odoo_state"] == "pending":
        extra = R_ODOO_PENDING
    else:
        return row["receipt"]
    lines = row["receipt"].split("\\n")
    return "\\n".join(lines[:-2] + [extra] + lines[-2:])


def pending_count(db):
    return db.execute("SELECT COUNT(*) FROM pos_order WHERE odoo_state = 'pending'").fetchone()[0]


def odoo_payload(db, row, default_partner):
    """Lo que hace falta para crear el pedido en Odoo (sin tocar SQLite en el hilo)."""
    lines = []
    for l in db.execute("SELECT * FROM pos_line WHERE order_id = ? ORDER BY id", (row["id"],)):
        price = l["price"]
        if not l["price_include"] and l["tax_rate"]:
            price = round(price / (1 + l["tax_rate"]), 4)
        lines.append({"odoo_id": l["odoo_product_id"], "qty": l["qty"], "price_unit": price, "discount": l["discount"]})
    return {"ref": row["ref"], "customer": row["customer"], "default_partner": default_partner, "lines": lines}


# ---------------------------------------------------------------------- Odoo
class OdooError(Exception):
    """Un error de Odoo con un texto para el usuario; kind dice de qué tipo:
    network, url, auth, 2fa, db, expired o server."""

    def __init__(self, message, kind="server"):
        super().__init__(message)
        self.kind = kind


class OdooClient:
    """Conexión con Odoo como la del navegador: entra con usuario y contraseña
    en /web/session/authenticate, guarda la cookie de sesión y llama a los
    modelos con /web/dataset/call_kw/<modelo>/<método> (JSON-RPC 2.0).
    Solo la usa el hilo de la red."""

    def __init__(self, url, db, login, password, timeout=ODOO_TIMEOUT):
        url = (url or "").strip().rstrip("/")
        if url and "://" not in url:
            url = "https://" + url
        self.url = url
        self.db = (db or "").strip()
        self.login = (login or "").strip()
        self.password = password or ""
        self.timeout = timeout
        self.uid = None
        self.info = {}
        self.calls = 0
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def rpc(self, path, params):
        self.calls += 1
        body = json.dumps({"jsonrpc": "2.0", "method": "call", "params": params, "id": self.calls})
        request = urllib.request.Request(
            self.url + path, data=body.encode("utf-8"), method="POST",
            headers={"Content-Type": "application/json", "Accept": "application/json"},
        )
        try:
            with self.opener.open(request, timeout=self.timeout) as response:
                reply = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            if error.code == 404:
                raise OdooError(ERR_NOT_ODOO.format("HTTP 404"), "url")
            raise OdooError(ERR_SERVER.format("HTTP %d" % error.code), "network")
        except urllib.error.URLError as error:
            if isinstance(error.reason, socket.timeout):
                raise OdooError(ERR_TIMEOUT.format(self.timeout), "network")
            raise OdooError(ERR_NETWORK.format(self.url, error.reason), "network")
        except socket.timeout:
            raise OdooError(ERR_TIMEOUT.format(self.timeout), "network")
        except (ValueError, UnicodeDecodeError):
            raise OdooError(ERR_NOT_ODOO.format(self.url), "url")
        except (OSError, http.client.HTTPException) as error:
            raise OdooError(ERR_NETWORK.format(self.url, error), "network")
        if not isinstance(reply, dict) or ("result" not in reply and "error" not in reply):
            raise OdooError(ERR_NOT_ODOO.format(self.url), "url")
        error = reply.get("error")
        if error:
            data = error.get("data") or {}
            name = data.get("name") or ""
            message = data.get("message") or error.get("message") or ""
            if error.get("code") == 100 or name.endswith("SessionExpiredException"):
                raise OdooError(message, "expired")
            if name.endswith("AccessDenied"):
                raise OdooError(ERR_LOGIN, "auth")
            raise OdooError(ERR_SERVER.format(message), "server")
        return reply["result"]

    def authenticate(self):
        db = self.db
        if not db:
            # Sin base de datos: la única del servidor, si deja verlas.
            try:
                names = self.rpc("/web/database/list", {})
            except OdooError as error:
                if error.kind in ("network", "url"):
                    raise
                names = None
            if not isinstance(names, list) or len(names) != 1:
                raise OdooError(ERR_NEED_DB, "db")
            db = names[0]
        try:
            info = self.rpc("/web/session/authenticate", {"db": db, "login": self.login, "password": self.password})
        except OdooError as error:
            text = str(error).lower()
            if error.kind == "server" and "database" in text and ("not found" in text or "does not exist" in text):
                raise OdooError(ERR_DB.format(db), "db")
            raise
        if not isinstance(info, dict) or not info.get("uid"):
            # Con la verificación en dos pasos la contraseña sola no abre sesión.
            raise OdooError(ERR_2FA, "2fa")
        self.db, self.uid, self.info = db, info["uid"], info
        return self

    def company(self):
        companies = self.info.get("user_companies") or {}
        allowed = companies.get("allowed_companies") or {}
        current = companies.get("current_company")
        return (allowed.get(str(current)) or allowed.get(current) or {}).get("name", "")

    def call(self, model, method, *args, **kwargs):
        if self.uid is None:
            self.authenticate()
        path = "/web/dataset/call_kw/%s/%s" % (model, method)
        params = {"model": model, "method": method, "args": list(args), "kwargs": kwargs}
        try:
            return self.rpc(path, params)
        except OdooError as error:
            if error.kind != "expired":
                raise
        # La sesión caducó: se entra otra vez (una sola) y se repite.
        self.uid = None
        self.authenticate()
        return self.rpc(path, params)


def is_tk_image(data):
    """PNG o GIF en base64: lo que lee tk.PhotoImage (JPEG y WebP no)."""
    return isinstance(data, str) and data.startswith(("iVBOR", "R0lGOD"))


def fetch_products(client):
    """Los productos a la venta (y del TPV, si existe el campo) con su precio
    con impuestos, el tipo de IVA, la categoría y la imagen."""
    fields = client.call("product.product", "fields_get", attributes=["type"])
    domain = [["sale_ok", "=", True]]
    if "available_in_pos" in fields:
        domain.append(["available_in_pos", "=", True])
    wanted = [f for f in ("name", "lst_price", "default_code", "barcode", "categ_id", "pos_categ_ids",
                          "taxes_id", "image_128") if f in fields]
    rows = client.call("product.product", "search_read", domain, fields=wanted, order="name", limit=PRODUCT_LIMIT)
    taxes, pos_names = {}, {}
    tax_ids = sorted({t for r in rows for t in (r.get("taxes_id") or [])})
    if tax_ids:
        try:
            tax_fields = client.call("account.tax", "fields_get", attributes=["type"])
            read = [f for f in ("amount", "amount_type", "price_include") if f in tax_fields]
            taxes = {t["id"]: t for t in client.call("account.tax", "read", tax_ids, fields=read)}
        except OdooError as error:
            if error.kind == "network":
                raise
    pos_ids = sorted({c for r in rows for c in (r.get("pos_categ_ids") or [])})
    if pos_ids:
        try:
            pos_names = {c["id"]: c["name"] for c in client.call("pos.category", "read", pos_ids, fields=["name"])}
        except OdooError as error:
            if error.kind == "network":
                raise
    out = []
    for r in rows:
        if r.get("pos_categ_ids") and r["pos_categ_ids"][0] in pos_names:
            category = pos_names[r["pos_categ_ids"][0]]
        elif r.get("categ_id"):
            category = str(r["categ_id"][1]).split(" / ")[-1]
        else:
            category = ""
        # Un solo impuesto en porcentaje; con otros, el precio tal cual.
        rate, included = 0.0, True
        found = [taxes[t] for t in (r.get("taxes_id") or []) if t in taxes]
        if len(found) == 1 and found[0].get("amount_type") == "percent":
            rate = float(found[0].get("amount") or 0) / 100.0
            included = bool(found[0].get("price_include"))
        price = float(r.get("lst_price") or 0.0)
        out.append({
            "odoo_id": r["id"], "name": r.get("name") or "", "category": category or OTHER,
            "price": price if included else round(price * (1 + rate), 2), "tax": rate,
            "included": 1 if included else 0, "code": r.get("default_code") or "",
            "barcode": r.get("barcode") or "", "image": r["image_128"] if is_tk_image(r.get("image_128")) else "",
        })
    return out


def send_order(client, order):
    """Crea y confirma el pedido de venta en Odoo, una sola vez: si ya hay uno
    con la misma referencia (un envío anterior a medias), se usa ese.
    Devuelve (id, nombre), p. ej. (42, "S00042")."""
    found = client.call("sale.order", "search_read", [["client_order_ref", "=", order["ref"]]],
                        fields=["name", "state"], limit=1)
    if found:
        sale = found[0]
        if sale.get("state") in ("draft", "sent"):
            client.call("sale.order", "action_confirm", [sale["id"]])
        return sale["id"], sale["name"]
    name = order["customer"] or order["default_partner"]
    partners = client.call("res.partner", "search_read", [["name", "=", name]], fields=["id"], limit=1)
    partner_id = partners[0]["id"] if partners else client.call("res.partner", "create", {"name": name})
    lines = [
        [0, 0, {"product_id": l["odoo_id"], "product_uom_qty": l["qty"], "price_unit": l["price_unit"],
                "discount": l["discount"]}]
        for l in order["lines"]
    ]
    sale_id = client.call("sale.order", "create", {
        "partner_id": partner_id, "client_order_ref": order["ref"], "order_line": lines,
    })
    client.call("sale.order", "action_confirm", [sale_id])
    sale = client.call("sale.order", "read", [sale_id], fields=["name"])
    return sale_id, sale[0]["name"]


def check_settings(values):
    if not values.get("url"):
        return ERR_NEED_URL
    if not values.get("login") or not values.get("password"):
        return ERR_NEED_LOGIN
    return None


class Worker:
    """Un hilo para la red, para que la ventana no se pare nunca: las tareas
    van en orden y los resultados vuelven por una cola que la ventana lee
    con after (tkinter solo se toca desde su hilo)."""

    def __init__(self):
        self.tasks = queue.Queue()
        self.results = queue.Queue()
        threading.Thread(target=self.loop, daemon=True).start()

    def submit(self, done, job, *args):
        self.tasks.put((done, job, args))

    def loop(self):
        while True:
            done, job, args = self.tasks.get()
            try:
                result, error = job(*args), None
            except Exception as exc:  # El error vuelve a la ventana.
                result, error = None, exc
            self.results.put((done, result, error))


def session(db, day=None):
    """(pedidos, total, en efectivo, con tarjeta) de un día."""
    day = day or datetime.date.today().isoformat()
    row = db.execute(
        "SELECT COUNT(*), COALESCE(SUM(total), 0), "
        "COALESCE(SUM(CASE WHEN method = 'cash' THEN total END), 0), "
        "COALESCE(SUM(CASE WHEN method = 'card' THEN total END), 0) "
        "FROM pos_order WHERE day = ?",
        (day,),
    ).fetchone()
    return row[0], round(row[1], 2), round(row[2], 2), round(row[3], 2)


# ------------------------------------------------------------------ imágenes
def fit(photo, size):
    """La imagen reducida (por un factor entero) para que quepa en size."""
    factor = int(math.ceil(max(photo.width(), photo.height()) / float(size)))
    return photo.subsample(factor) if factor > 1 else photo


# ------------------------------------------------------------------ clientes
class CustomerDialog(tk.Toplevel):
    """Elegir un cliente de la lista o crear uno nuevo; on_pick(nombre)."""

    def __init__(self, parent, names, current, on_pick):
        super().__init__(parent)
        self.title(PICK_TITLE)
        self.configure(bg=PAPER, padx=12, pady=12)
        self.resizable(False, False)
        self.transient(parent)
        self.on_pick = on_pick
        self.names = names
        self.listbox = tk.Listbox(self, height=8, width=32, bg=WHITE, fg=INK, activestyle="none", exportselection=False)
        for name in names:
            self.listbox.insert("end", name)
        if current in names:
            self.listbox.selection_set(names.index(current))
        self.listbox.grid(row=0, column=0, columnspan=3, sticky="ew")
        self.listbox.bind("<Double-Button-1>", lambda e: self.pick())
        tk.Label(self, text=PICK_NEW, bg=PAPER, fg=INK).grid(row=1, column=0, sticky="w", pady=(10, 2))
        self.new = tk.StringVar()
        entry = tk.Entry(self, textvariable=self.new, bg=WHITE, fg=INK, insertbackground=INK)
        entry.grid(row=2, column=0, columnspan=3, sticky="ew")
        entry.bind("<Return>", lambda e: self.pick())
        for column, (text, action) in enumerate(((PICK_OK, self.pick), (NO_CUSTOMER, lambda: self.done("")), (CANCEL, self.destroy))):
            ColorButton(self, text=text, command=action, bg=PURPLE if column == 0 else "#e4e5e7",
                        fg=WHITE if column == 0 else INK, padx=10, pady=4).grid(row=3, column=column, sticky="ew", padx=2, pady=(12, 0))
        self.bind("<Escape>", lambda e: self.destroy())
        entry.focus_set()
        # Modal: en cuanto se vea, las demás ventanas esperan.
        self.after(50, self.modal)

    def modal(self):
        try:
            self.grab_set()
        except tk.TclError:
            pass  # Todavía no se ve.

    def pick(self):
        name = self.new.get().strip()
        if not name:
            chosen = self.listbox.curselection()
            if not chosen:
                return
            name = self.names[chosen[0]]
        self.done(name)

    def done(self, name):
        self.on_pick(name)
        self.destroy()


# ------------------------------------------------------------------ Odoo
class OdooDialog(tk.Toplevel):
    """Dirección, base de datos, usuario y contraseña de Odoo."""

    FIELDS = (("url", F_URL), ("db", F_DB), ("login", F_LOGIN), ("password", F_PASSWORD), ("partner", F_PARTNER))

    def __init__(self, form):
        super().__init__(form.root)
        self.form = form
        self.title(ODOO_TITLE)
        self.configure(bg=PAPER, padx=16, pady=14)
        self.resizable(False, False)
        self.transient(form.root)
        self.vars = {}
        for row, (key, label) in enumerate(self.FIELDS):
            tk.Label(self, text=label, bg=PAPER, fg=INK, anchor="w").grid(row=row, column=0, sticky="w", padx=(0, 10), pady=3)
            value = form.settings.get(key, "")
            var = tk.StringVar(value=value or (DEFAULT_PARTNER if key == "partner" else ""))
            entry = tk.Entry(self, textvariable=var, width=38, bg=WHITE, fg=INK, insertbackground=INK,
                             show="•" if key == "password" else "")
            entry.grid(row=row, column=1, sticky="ew", pady=3)
            self.vars[key] = var
            if key == "password":
                self.password = entry
        self.reveal = tk.IntVar(value=0)
        tk.Checkbutton(self, text=F_SHOW, variable=self.reveal, command=self.toggle, bg=PAPER, fg=INK,
                       activebackground=PAPER, highlightthickness=0).grid(row=3, column=2, sticky="w", padx=(6, 0))
        tk.Label(self, text=ODOO_NOTE, bg=PAPER, fg=MUTED, justify="left", anchor="w",
                 wraplength=520).grid(row=5, column=0, columnspan=3, sticky="w", pady=(10, 4))
        self.result = tk.Label(self, text="", bg=PAPER, fg=MUTED, justify="left", anchor="w", wraplength=520)
        self.result.grid(row=6, column=0, columnspan=3, sticky="w", pady=(0, 8))
        buttons = tk.Frame(self, bg=PAPER)
        buttons.grid(row=7, column=0, columnspan=3, sticky="e")
        for text, action, primary in ((TEST, self.test, False), (SAVE, self.save, True), (CANCEL, self.destroy, False)):
            ColorButton(buttons, text=text, command=action, bg=PURPLE if primary else "#e4e5e7",
                        fg=WHITE if primary else INK, padx=12, pady=4).pack(side="left", padx=3)
        self.bind("<Escape>", lambda e: self.destroy())
        self.after(50, self.modal)

    def modal(self):
        try:
            self.grab_set()
        except tk.TclError:
            pass

    def values(self):
        out = {key: var.get().strip() for key, var in self.vars.items()}
        out["password"] = self.vars["password"].get()
        return out

    def toggle(self):
        self.password.configure(show="" if self.reveal.get() else "•")

    def show_result(self, text, ok=None):
        self.result.configure(text=text, fg=MUTED if ok is None else GREEN if ok else RED)

    def test(self):
        values = self.values()
        problem = check_settings(values)
        if problem:
            return self.show_result(problem, False)
        self.show_result(TESTING)
        self.form.test_connection(values, self.tested)

    def tested(self, client, error):
        if not self.winfo_exists():
            return
        if error is not None:
            return self.show_result(str(error), False)
        if not self.vars["db"].get().strip():
            self.vars["db"].set(client.db)  # la que se encontró
        self.show_result(CONNECTED_AS.format(client.info.get("name") or client.login, client.company() or "-", client.db), True)

    def save(self):
        values = self.values()
        problem = check_settings(values) if values["url"] else None
        if problem:
            return self.show_result(problem, False)
        self.form.save_settings(values)
        self.destroy()


# ------------------------------------------------------------------- ventana
class Form1(FormDesign):
    def form_create(self):
        self.db_path = os.path.join(data_dir(), DB_FILE)
        self.db = open_db(self.db_path)
        self.order = Order()
        self.payment = None
        self.category = None
        self.screen = "products"
        self.last_receipt = ""
        style = ttk.Style()
        style.configure("Light.Treeview", background=WHITE, fieldbackground=WHITE, foreground=INK, rowheight=24)
        style.configure("Light.Treeview.Heading", foreground=INK)
        style.map("Light.Treeview", background=[("selected", "#ead9e6")], foreground=[("selected", INK)])
        style.configure("Thumbs.Treeview", background=WHITE, fieldbackground=WHITE, foreground=INK, rowheight=30)
        style.configure("Thumbs.Treeview.Heading", foreground=INK)
        style.map("Thumbs.Treeview", background=[("selected", "#ead9e6")], foreground=[("selected", INK)])
        # La columna del árbol (#0) lleva la miniatura del producto.
        self.Lines.configure(style="Thumbs.Treeview", show=("tree", "headings"))
        self.Lines.column("#0", width=32, minwidth=32, stretch=False, anchor="center")
        self.Lines.tag_configure("zero", foreground="#9096a0")
        self.Lines.tag_configure("refund", foreground=RED)
        for column in ("qty", "price", "disc", "subtotal"):
            self.Lines.column(column, anchor="e")
        self.image_dir = os.path.join(os.path.dirname(self.db_path), IMAGE_DIR)
        self.photos, self.thumbs, self.tiles = {}, {}, {}
        self.cat_places = [dict(b.place_info()) for b in self.category_buttons()]
        self.load_catalog()
        # Odoo: la red va en otro hilo; la ventana lee sus resultados.
        self.worker = Worker()
        self.settings = load_settings(self.db)
        self.client = None
        self.odoo_state = "off"
        self.sending = set()
        self.receipt_order = None
        self.root.after(100, self.poll)
        self.root.after(60000, self.retry)
        self.build_grid()
        self.build_payment()
        self.build_receipt()
        self.build_orders()
        self.show_products()
        self.refresh_order()
        self.update_session()
        self.Status.set(READY.format(self.db_path) + "   ·   " + TILE_HINT, icon="info")
        self.Search.focus_set()
        self.make_client()
        self.connect()

    # ---------------------------------------------------------- productos
    def load_catalog(self):
        """Los productos descargados de Odoo o, si no hay, los de ejemplo. Los
        de Odoo usan su id en negativo como clave local."""
        rows = self.db.execute("SELECT * FROM odoo_product ORDER BY position").fetchall()
        self.odoo_products, self.default_images, self.codes = {}, {}, {}
        if rows:
            self.categories = []
            for row in rows:
                if row["category"] not in self.categories:
                    self.categories.append(row["category"])
            self.catalog = []
            for row in rows:
                key = -row["odoo_id"]
                self.catalog.append((key, row["name"], self.categories.index(row["category"]), row["price"], row["tax"]))
                self.odoo_products[key] = (row["odoo_id"], row["included"])
                self.default_images[key] = row["image"]
                self.codes[key] = (row["code"], row["barcode"])
        else:
            self.categories = list(CATEGORIES)
            self.catalog = list(PRODUCTS)
        self.category = None
        for product in self.catalog:
            self.load_image(product[0])

    def category_buttons(self):
        return (self.BtnCat1, self.BtnCat2, self.BtnCat3, self.BtnCat4)

    def show_categories(self):
        """Hasta cuatro botones; con más categorías, el cuarto es «Más…»."""
        many = len(self.categories) > 4
        for i, button in enumerate(self.category_buttons()):
            if i >= len(self.categories):
                button.place_forget()
                continue
            button.place(**{k: self.cat_places[i][k] for k in ("x", "y", "width", "height")})
            if many and i == 3:
                chosen = self.category is not None and self.category >= 3
                text = self.categories[self.category] + " ▾" if chosen else MORE
                active = chosen
            else:
                text, active = self.categories[i], self.category == i
            button.configure(text=text, bg=PURPLE if active else WHITE, fg=WHITE if active else INK)
        all_on = self.category is None
        self.BtnCatAll.configure(bg=PURPLE if all_on else WHITE, fg=WHITE if all_on else INK)

    def more_categories(self):
        menu = tk.Menu(self.root, tearoff=0)
        for index in range(3, len(self.categories)):
            menu.add_command(label=self.categories[index], command=lambda i=index: self.set_category(i))
        x, y = self.BtnCat4.winfo_rootx(), self.BtnCat4.winfo_rooty() + self.BtnCat4.winfo_height()
        try:
            menu.tk_popup(x, y)
        finally:
            menu.grab_release()

    def visible_products(self):
        query = plain(self.Search_var.get().strip())
        if query:
            return [p for p in self.catalog
                    if query in plain(p[1]) or any(query in plain(c) for c in self.codes.get(p[0], ()) if c)]
        return [p for p in self.catalog if self.category is None or p[2] == self.category]

    def build_grid(self):
        """Rejilla de productos con barra de desplazamiento, como en Odoo."""
        self.grid_canvas = tk.Canvas(self.Products, bg=PAPER, highlightthickness=0, bd=0, yscrollincrement=20)
        self.grid_canvas.place(x=0, y=0, width=636, height=532)
        bar = ttk.Scrollbar(self.Products, orient="vertical", command=self.grid_canvas.yview)
        bar.place(x=638, y=0, width=14, height=532)
        self.grid_canvas.configure(yscrollcommand=bar.set)
        self.grid = tk.Frame(self.grid_canvas, bg=PAPER)
        self.grid_canvas.create_window(0, 0, window=self.grid, anchor="nw")
        self.grid_canvas.bind("<MouseWheel>", self.wheel)
        self.grid.bind("<MouseWheel>", self.wheel)

    def wheel(self, event):
        # Windows da múltiplos de 120; macOS, pasos pequeños.
        delta = event.delta if abs(event.delta) < 120 else event.delta // 120
        self.grid_canvas.yview_scroll(-1 if delta > 0 else 1, "units")

    def show_products(self):
        for tile in self.grid.winfo_children():
            tile.destroy()
        self.tiles = {}
        found = self.visible_products()
        columns, gap, height = 4, 8, 168
        width = (636 - gap * (columns - 1)) // columns
        for index, product in enumerate(found):
            row, column = divmod(index, columns)
            # Como en Odoo: la imagen arriba y debajo el nombre y el precio.
            tile = ColorButton(
                self.grid,
                image=self.photos[product[0]], compound="top",
                text="%s\\n%s" % (product[1], money(product[3])),
                bg=WHITE, fg=INK, activebackground=WHITE,
                font=("TkDefaultFont", 11), wraplength=width - 12, justify="center",
                relief="flat", bd=0, highlightthickness=0, pady=6,
                command=lambda p=product: self.add_product(p),
            )
            tile.place(x=column * (width + gap), y=row * (height + gap), width=width, height=height)
            for sequence in ("<Button-2>", "<Button-3>"):
                tile.bind(sequence, lambda event, p=product: self.tile_menu(event, p))
            tile.bind("<MouseWheel>", self.wheel)
            self.tiles[product[0]] = tile
        rows = max(1, int(math.ceil(len(found) / float(columns))))
        total = rows * (height + gap) - gap
        self.grid.configure(width=636, height=max(total, 40))
        self.grid_canvas.configure(scrollregion=(0, 0, 636, total))
        self.grid_canvas.yview_moveto(0)
        if not found:
            tk.Label(self.grid, text=NO_MATCH, bg=PAPER, fg=MUTED).place(x=0, y=0, width=636, height=40)
        self.show_categories()

    # ------------------------------------------------------------ imágenes
    def custom_image(self, pid):
        row = self.db.execute("SELECT file FROM product_image WHERE product_id = ?", (pid,)).fetchone()
        return os.path.join(self.image_dir, row["file"]) if row else None

    def load_image(self, pid):
        """La imagen propia del producto, si la hay y se puede abrir; si no, la de siempre."""
        photo = None
        path = self.custom_image(pid)
        if path:
            try:
                photo = tk.PhotoImage(master=self.root, file=path)
            except tk.TclError:
                photo = None
        if photo is None:
            try:
                photo = tk.PhotoImage(master=self.root, data=self.default_images.get(pid) or IMAGES.get(pid, IMAGES[0]))
            except tk.TclError:
                photo = tk.PhotoImage(master=self.root, data=IMAGES[0])  # la bolsa genérica
        # Se guardan las referencias: sin ellas, Tk borra las imágenes.
        self.photos[pid] = fit(photo, IMAGE_SIZE)
        self.thumbs[pid] = fit(photo, THUMB_SIZE)

    def tile_menu(self, event, product):
        menu = tk.Menu(self.root, tearoff=0)
        menu.add_command(label=CHANGE_IMAGE, command=lambda: self.change_image(product))
        menu.add_command(
            label=REMOVE_IMAGE, command=lambda: self.remove_image(product),
            state="normal" if self.custom_image(product[0]) else "disabled",
        )
        try:
            menu.tk_popup(event.x_root, event.y_root)
        finally:
            menu.grab_release()

    def change_image(self, product, path=None):
        pid, name = product[0], product[1]
        if path is None:
            path = filedialog.askopenfilename(
                parent=self.root, title=PICK_IMAGE.format(name),
                filetypes=[(IMAGE_FILES, "*.png *.gif"), ("PNG", "*.png"), ("GIF", "*.gif")],
            )
        if not path:
            return False
        try:
            tk.PhotoImage(master=self.root, file=path)  # ¿Tk sabe leerla?
            os.makedirs(self.image_dir, exist_ok=True)
            old = self.custom_image(pid)
            target = "product_%d%s" % (pid, os.path.splitext(path)[1].lower())
            shutil.copyfile(path, os.path.join(self.image_dir, target))
            if old and os.path.basename(old) != target and os.path.exists(old):
                os.remove(old)
        except (tk.TclError, OSError) as error:
            self.Status.set(BAD_IMAGE.format(error), icon="⚠")
            return False
        self.db.execute("INSERT OR REPLACE INTO product_image (product_id, file) VALUES (?, ?)", (pid, target))
        self.db.commit()
        self.image_changed(pid)
        self.Status.set(IMAGE_CHANGED.format(name), icon="image")
        return True

    def remove_image(self, product):
        pid = product[0]
        path = self.custom_image(pid)
        if not path:
            return False
        self.db.execute("DELETE FROM product_image WHERE product_id = ?", (pid,))
        self.db.commit()
        try:
            os.remove(path)
        except OSError:
            pass
        self.image_changed(pid)
        self.Status.set(IMAGE_REMOVED.format(product[1]), icon="image")
        return True

    def image_changed(self, pid):
        self.load_image(pid)
        if pid in self.tiles:
            self.tiles[pid].configure(image=self.photos[pid])
        self.refresh_order()

    def add_product(self, product):
        if self.screen != "products":
            return
        self.order.add(product)
        self.refresh_order()

    def set_category(self, category):
        self.category = category
        self.Search_var.set("")
        self.show_products()

    # ------------------------------------------------------------ pedido
    def refresh_order(self):
        order = self.order
        self.Lines.delete(*self.Lines.get_children())
        for index, line in enumerate(order.lines):
            tags = ("zero",) if line["qty"] == 0 else ("refund",) if order.line_total(line) < 0 else ()
            thumb = self.thumbs.get(line["id"], "")
            self.Lines.insert("", "end", iid=str(index), tags=tags, image=thumb, values=(
                line["name"], number(line["qty"]), money(line["price"]),
                (number(line["discount"]) + " %") if line["discount"] else "",
                money(order.line_total(line)),
            ))
        if order.selected is not None:
            self.Lines.selection_set(str(order.selected))
            self.Lines.see(str(order.selected))
        self.Total.configure(text=TOTAL.format(money(order.total())))
        self.Taxes.configure(text=TAXES.format(money(order.tax_total())))
        self.BtnCustomer.configure(text=order.customer or CUSTOMER)
        for mode, button in (("qty", self.ModeQty), ("disc", self.ModeDisc), ("price", self.ModePrice)):
            active = order.mode == mode
            button.configure(bg=TEAL if active else KEY, fg=WHITE if active else INK)
        if self.payment is not None:
            self.payment.total = order.total()
            self.refresh_payment()

    def press(self, key):
        if self.screen == "payment":
            if self.payment.press(key):
                self.refresh_payment()
        elif self.screen == "products":
            if self.order.press(key):
                self.refresh_order()

    def set_mode(self, mode):
        if self.screen == "products":
            self.order.set_mode(mode)
            self.refresh_order()

    def set_customer(self, name):
        self.order.customer = name
        if name:
            try:
                self.db.execute("INSERT OR IGNORE INTO customer (name) VALUES (?)", (name,))
                self.db.commit()
            except sqlite3.Error:
                pass
        self.refresh_order()
        if self.screen == "payment":
            self.refresh_payment()

    def customers(self):
        return [row[0] for row in self.db.execute("SELECT name FROM customer ORDER BY name COLLATE NOCASE")]

    # ----------------------------------------------------------- pantallas
    def screen_frame(self):
        frame = tk.Frame(self.root, bg=PAPER)
        return frame

    def label(self, parent, text="", size=12, bold=False, fg=INK, **place):
        widget = tk.Label(parent, text=text, bg=PAPER, fg=fg, anchor="w", justify="left",
                          font=("TkDefaultFont", size, "bold" if bold else "normal"))
        widget.place(**place)
        return widget

    def button(self, parent, text, command, primary=False, size=13, **place):
        widget = ColorButton(parent, text=text, command=command, bg=PURPLE if primary else WHITE,
                             fg=WHITE if primary else INK, disabledforeground="#c9b8c5" if primary else "#9096a0",
                             font=("TkDefaultFont", size, "bold" if primary else "normal"))
        widget.place(**place)
        return widget

    def show(self, screen):
        self.screen = screen
        for name, frame in (("payment", self.PayScreen), ("receipt", self.ReceiptScreen), ("orders", self.OrdersScreen)):
            if name == screen:
                frame.place(x=428, y=48, width=672, height=648)
                frame.lift()
            else:
                frame.place_forget()
        state = "normal" if screen == "products" else "disabled"
        for button in (self.ModeQty, self.ModeDisc, self.ModePrice, self.KeySign, self.BtnPay, self.BtnClear):
            button.configure(state=state)
        if screen == "payment":
            self.KeySign.configure(state="disabled")
        self.BtnOrders.configure(state="normal" if screen in ("products", "orders") else "disabled")

    def build_payment(self):
        f = self.PayScreen = self.screen_frame()
        self.label(f, PAY_TITLE, 20, True, PURPLE, x=24, y=16, width=600, height=36)
        self.label(f, DUE, 12, False, MUTED, x=24, y=64, width=300, height=20)
        self.PayDue = self.label(f, "", 30, True, x=24, y=84, width=600, height=48)
        self.BtnCash = self.button(f, CASH, lambda: self.set_method("cash"), size=15, x=24, y=150, width=200, height=56)
        self.BtnCard = self.button(f, CARD, lambda: self.set_method("card"), size=15, x=236, y=150, width=200, height=56)
        self.label(f, TENDERED, 12, False, MUTED, x=24, y=226, width=300, height=20)
        self.PayAmount = tk.Label(f, text="", bg=WHITE, fg=INK, anchor="e", padx=12, relief="solid", bd=1,
                                  font=("TkDefaultFont", 24, "bold"))
        self.PayAmount.place(x=24, y=248, width=412, height=52)
        self.quick = []
        for i, value in enumerate((10, 20, 50)):
            self.quick.append(self.button(f, "+%d €" % value, lambda v=value: self.add_cash(v),
                                          x=24 + i * 104, y=312, width=96, height=44))
        self.quick.append(self.button(f, EXACT, self.exact_cash, x=336, y=312, width=100, height=44))
        self.PayChange = self.label(f, "", 20, True, x=24, y=376, width=600, height=36)
        self.PayHint = self.label(f, PAY_HINT, 11, False, MUTED, x=24, y=420, width=600, height=44)
        self.PayHint.configure(wraplength=600)
        self.PayCustomer = self.label(f, "", 12, False, MUTED, x=24, y=470, width=600, height=24)
        self.button(f, BACK, self.cancel_payment, x=24, y=568, width=180, height=56)
        self.BtnValidate = self.button(f, VALIDATE, self.validate, primary=True, size=17,
                                       x=420, y=568, width=228, height=56)

    def build_receipt(self):
        f = self.ReceiptScreen = self.screen_frame()
        self.label(f, PAID_TITLE, 20, True, PURPLE, x=24, y=16, width=600, height=36)
        self.ReceiptChange = self.label(f, "", 18, True, GREEN, x=24, y=58, width=600, height=32)
        self.Receipt = tk.Text(f, bg=WHITE, fg=INK, relief="solid", bd=1, padx=10, pady=10,
                               font="TkFixedFont", wrap="none", highlightthickness=0)
        self.Receipt.place(x=24, y=104, width=380, height=520)
        self.button(f, NEW_ORDER, self.new_order, primary=True, size=17, x=424, y=104, width=224, height=72)
        self.button(f, COPY, self.copy_receipt, x=424, y=188, width=224, height=44)

    def build_orders(self):
        f = self.OrdersScreen = self.screen_frame()
        self.label(f, ORDERS_TITLE, 20, True, PURPLE, x=24, y=16, width=600, height=36)
        self.OrdersSummary = self.label(f, "", 12, False, MUTED, x=24, y=56, width=624, height=24)
        columns = (("number", COL_ORDER, 54), ("time", COL_TIME, 44), ("customer", CUSTOMER, 74),
                   ("method", COL_PAY, 60), ("total", COL_TOTAL, 52))
        self.OrderList = ttk.Treeview(f, columns=[c[0] for c in columns], show="headings", style="Light.Treeview")
        for key, title, width in columns:
            self.OrderList.heading(key, text=title)
            self.OrderList.column(key, width=width, anchor="e" if key == "total" else "w")
        self.OrderList.place(x=24, y=92, width=284, height=460)
        scroll = ttk.Scrollbar(f, orient="vertical", command=self.OrderList.yview)
        scroll.place(x=308, y=92, width=16, height=460)
        self.OrderList.configure(yscrollcommand=scroll.set)
        self.OrderList.bind("<<TreeviewSelect>>", self.OrderList_select)
        self.OrderReceipt = tk.Text(f, bg=WHITE, fg=INK, relief="solid", bd=1, padx=8, pady=8,
                                    font="TkFixedFont", wrap="none", highlightthickness=0)
        self.OrderReceipt.place(x=336, y=92, width=312, height=460)
        self.button(f, BACK, lambda: self.show("products"), x=24, y=568, width=180, height=56)

    @staticmethod
    def put_text(widget, text):
        widget.configure(state="normal")
        widget.delete("1.0", "end")
        widget.insert("1.0", text)
        widget.configure(state="disabled")

    # ---------------------------------------------------------------- cobro
    def start_payment(self):
        self.order.clean()
        self.refresh_order()
        if not self.order.lines:
            self.Status.set(EMPTY, icon="⚠")
            return False
        if self.order.total() <= 0:
            self.Status.set(NOT_POSITIVE, icon="⚠")
            return False
        self.payment = Payment(self.order.total())
        self.show("payment")
        self.refresh_payment()
        return True

    def refresh_payment(self):
        pay = self.payment
        if pay is None:
            return
        self.PayDue.configure(text=money(pay.total))
        for method, button in (("cash", self.BtnCash), ("card", self.BtnCard)):
            active = pay.method == method
            button.configure(bg=TEAL if active else WHITE, fg=WHITE if active else INK)
        cash = pay.method == "cash"
        self.PayAmount.configure(text=money(pay.amount()) if (pay.buffer or not cash) else "")
        for button in self.quick:
            button.configure(state="normal" if cash else "disabled")
        change = pay.change()
        if not cash:
            self.PayChange.configure(text="")
        elif change >= -0.004:
            self.PayChange.configure(text=CHANGE.format(money(max(0.0, change))), fg=GREEN)
        else:
            self.PayChange.configure(text=MISSING.format(money(-change)), fg=RED)
        self.PayHint.configure(text=PAY_HINT if cash else CARD_HINT)
        self.PayCustomer.configure(text=R_CUSTOMER.format(self.order.customer) if self.order.customer else "")
        self.BtnValidate.configure(state="normal" if pay.valid() else "disabled")

    def set_method(self, method):
        if self.payment is None:
            return
        self.payment.method = method
        self.refresh_payment()

    def add_cash(self, value):
        if self.payment is None:
            return
        self.payment.set_amount(self.payment.amount() + value)
        self.refresh_payment()

    def exact_cash(self):
        if self.payment is None:
            return
        self.payment.set_amount(self.payment.total)
        self.refresh_payment()

    def cancel_payment(self):
        self.payment = None
        self.show("products")

    def validate(self):
        if self.payment is None or not self.payment.valid():
            return None
        pay = self.payment
        odoo = self.odoo_products if self.client is not None else None
        try:
            order_id, receipt = save_order(self.db, self.order, pay, odoo=odoo)
        except sqlite3.Error as error:
            messagebox.showerror(APP, str(error), parent=self.root)
            return None
        self.receipt_order = order_id
        self.show_receipt()
        self.ReceiptChange.configure(text=CHANGE.format(money(pay.change())) if pay.method == "cash" else "")
        self.Status.set(PAID.format(order_number(order_id), money(pay.total), CASH if pay.method == "cash" else CARD), icon="check")
        # El pedido siguiente empieza ya.
        self.payment = None
        self.order = Order()
        self.refresh_order()
        self.update_session()
        self.show("receipt")
        state = self.db.execute("SELECT odoo_state FROM pos_order WHERE id = ?", (order_id,)).fetchone()[0]
        if state == "pending":
            self.sync()
        elif state == "local":
            self.Status.set(LOCAL_ONLY, icon="⚠")
        self.update_odoo_label()
        return order_id

    def show_receipt(self):
        row = self.db.execute("SELECT * FROM pos_order WHERE id = ?", (self.receipt_order,)).fetchone()
        if row is None:
            return
        self.last_receipt = receipt_with_odoo(row)
        self.put_text(self.Receipt, self.last_receipt)

    def new_order(self):
        self.show("products")
        self.Search.focus_set()

    def copy_receipt(self):
        self.root.clipboard_clear()
        self.root.clipboard_append(self.last_receipt)
        self.Status.set(COPIED, icon="copy")

    # ------------------------------------------------------------- pedidos
    def update_session(self):
        count, total, _, _ = session(self.db)
        self.Session.configure(text=SESSION.format(count, money(total)))

    def show_orders(self):
        count, total, cash, card = session(self.db)
        self.OrdersSummary.configure(text=SUMMARY.format(count, money(total), money(cash), money(card)))
        self.OrderList.delete(*self.OrderList.get_children())
        rows = self.db.execute(
            "SELECT id, created, customer, method, total, odoo_state FROM pos_order WHERE day = ? ORDER BY id DESC",
            (datetime.date.today().isoformat(),),
        ).fetchall()
        self.OrderList.tag_configure("pending", foreground="#b25e00")
        for row in rows:
            self.OrderList.insert("", "end", iid=str(row["id"]), values=(
                order_number(row["id"]), row["created"][11:16], row["customer"],
                CASH if row["method"] == "cash" else CARD, money(row["total"]),
            ), tags=("pending",) if row["odoo_state"] == "pending" else ())
        self.put_text(self.OrderReceipt, "")
        if rows:
            self.OrderList.selection_set(str(rows[0]["id"]))
            self.OrderList_select()
        self.show("orders")

    def OrderList_select(self, event=None):
        chosen = self.OrderList.selection()
        if not chosen:
            return
        row = self.db.execute("SELECT * FROM pos_order WHERE id = ?", (int(chosen[0]),)).fetchone()
        self.put_text(self.OrderReceipt, receipt_with_odoo(row) if row else "")

    # ---------------------------------------------------------------- Odoo
    def make_client(self):
        s = self.settings
        configured = not check_settings(s)
        self.client = OdooClient(s.get("url"), s.get("db"), s.get("login"), s.get("password")) if configured else None

    def poll(self):
        """Lee los resultados del hilo de la red (cada 100 ms)."""
        try:
            while True:
                done, result, error = self.worker.results.get_nowait()
                done(result, error)
        except queue.Empty:
            pass
        self.root.after(100, self.poll)

    def update_odoo_label(self):
        text = {"off": ODOO_OFF, "on": ODOO_ON, "down": ODOO_DOWN, "busy": ODOO_BUSY}[self.odoo_state]
        pending = pending_count(self.db)
        if pending:
            text += ODOO_PENDING.format(pending)
        self.OdooState.configure(text=text)

    def set_odoo(self, state):
        self.odoo_state = state
        self.update_odoo_label()

    def odoo_failed(self, error):
        self.set_odoo("down")
        message = str(error) if isinstance(error, OdooError) else ERR_SERVER.format(error)
        self.Status.set(message, icon="⚠")

    def connect(self):
        """Entra en Odoo (al abrir y al guardar la conexión) y envía lo pendiente."""
        if self.client is None:
            return self.set_odoo("off")
        self.set_odoo("busy")
        self.worker.submit(self.connected, self.client.authenticate)

    def connected(self, client, error):
        if error is not None:
            return self.odoo_failed(error)
        self.set_odoo("on")
        self.sync()

    def retry(self):
        """Cada minuto, si hay pedidos pendientes, se vuelve a intentar."""
        if self.client is not None and not self.sending and pending_count(self.db):
            self.connect()
        self.root.after(60000, self.retry)

    def test_connection(self, values, callback):
        client = OdooClient(values.get("url"), values.get("db"), values.get("login"), values.get("password"))
        self.worker.submit(lambda result, error: callback(client, error), client.authenticate)

    def save_settings(self, values):
        store_settings(self.db, values)
        self.settings = load_settings(self.db)
        self.make_client()
        self.Status.set(SETTINGS_SAVED, icon="check")
        self.connect()

    def sync(self):
        """Envía a Odoo los pedidos pendientes (cada uno una sola vez a la vez)."""
        if self.client is None:
            return 0
        partner = self.settings.get("partner") or DEFAULT_PARTNER
        count = 0
        for row in self.db.execute("SELECT * FROM pos_order WHERE odoo_state = 'pending' ORDER BY id").fetchall():
            if row["id"] in self.sending:
                continue
            self.sending.add(row["id"])
            payload = odoo_payload(self.db, row, partner)
            self.worker.submit(lambda result, error, oid=row["id"]: self.order_sent(oid, result, error),
                               send_order, self.client, payload)
            count += 1
        return count

    def order_sent(self, order_id, result, error):
        self.sending.discard(order_id)
        if error is not None:
            self.db.execute("UPDATE pos_order SET odoo_error = ? WHERE id = ?", (str(error), order_id))
            self.db.commit()
            self.set_odoo("down" if getattr(error, "kind", "") in ("network", "url", "auth", "2fa", "db") else self.odoo_state)
            self.Status.set(NOT_SENT.format(order_number(order_id), error), icon="⚠")
        else:
            sale_id, name = result
            self.db.execute(
                "UPDATE pos_order SET odoo_state = 'sent', odoo_id = ?, odoo_name = ?, odoo_error = '' WHERE id = ?",
                (sale_id, name, order_id),
            )
            self.db.commit()
            self.set_odoo("on")
            self.Status.set(SENT.format(order_number(order_id), name), icon="check")
            # Con la conexión de vuelta, lo que quedara pendiente.
            self.sync()
        if self.receipt_order == order_id:
            self.show_receipt()
        if self.screen == "orders":
            self.OrderList_select()
        self.update_odoo_label()

    def download_products(self):
        if self.client is None:
            self.Status.set(NEED_CONFIG, icon="⚠")
            return False
        self.set_odoo("busy")
        self.Status.set(DOWNLOADING, icon="refresh")
        self.worker.submit(self.products_downloaded, fetch_products, self.client)
        return True

    def products_downloaded(self, products, error):
        if error is not None:
            return self.odoo_failed(error)
        self.set_odoo("on")
        if not products:
            return self.Status.set(NO_PRODUCTS, icon="⚠")
        self.db.execute("DELETE FROM odoo_product")
        self.db.executemany(
            "INSERT INTO odoo_product (odoo_id, position, name, category, price, tax, included, code, barcode, image) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [(p["odoo_id"], i, p["name"], p["category"], p["price"], p["tax"], p["included"], p["code"],
              p["barcode"], p["image"]) for i, p in enumerate(products)],
        )
        self.db.commit()
        self.load_catalog()
        self.show_products()
        self.Status.set(DOWNLOADED.format(len(products), len(self.categories)), icon="check")
        self.sync()

    def demo_catalog(self):
        if not messagebox.askyesno(APP, ASK_DEMO, parent=self.root):
            return
        self.db.execute("DELETE FROM odoo_product")
        self.db.commit()
        self.load_catalog()
        self.show_products()
        self.Status.set(DEMO_BACK, icon="refresh")

    # ------------------------------------------------------------ eventos
    def Lines_select(self, event=None):
        chosen = self.Lines.selection()
        if chosen and int(chosen[0]) != self.order.selected:
            self.order.select(int(chosen[0]))

    def Key0_click(self):
        self.press("0")

    def Key1_click(self):
        self.press("1")

    def Key2_click(self):
        self.press("2")

    def Key3_click(self):
        self.press("3")

    def Key4_click(self):
        self.press("4")

    def Key5_click(self):
        self.press("5")

    def Key6_click(self):
        self.press("6")

    def Key7_click(self):
        self.press("7")

    def Key8_click(self):
        self.press("8")

    def Key9_click(self):
        self.press("9")

    def KeyComma_click(self):
        self.press(",")

    def KeySign_click(self):
        self.press("sign")

    def KeyBack_click(self):
        self.press("back")

    def ModeQty_click(self):
        self.set_mode("qty")

    def ModeDisc_click(self):
        self.set_mode("disc")

    def ModePrice_click(self):
        self.set_mode("price")

    def form_key(self, event=None):
        # Las teclas del ordenador también valen, salvo al escribir en un campo.
        if event is None or isinstance(event.widget, (tk.Entry, ttk.Entry, tk.Text)):
            return
        key = event.char
        if key and key in "0123456789":
            self.press(key)
        elif key in (",", "."):
            self.press(",")
        elif event.keysym == "BackSpace":
            self.press("back")
        elif event.keysym in ("Return", "KP_Enter"):
            if self.screen == "payment":
                self.validate()
            elif self.screen == "receipt":
                self.new_order()

    def BtnOdoo_click(self):
        menu = tk.Menu(self.root, tearoff=0)
        on = "normal" if self.client is not None else "disabled"
        menu.add_command(label=ODOO_CONFIG, command=lambda: OdooDialog(self))
        menu.add_command(label=ODOO_DOWNLOAD, command=self.download_products, state=on)
        menu.add_command(label=ODOO_SYNC.format(pending_count(self.db)), command=self.connect, state=on)
        menu.add_separator()
        menu.add_command(label=ODOO_DEMO, command=self.demo_catalog,
                         state="normal" if self.odoo_products else "disabled")
        x, y = self.BtnOdoo.winfo_rootx(), self.BtnOdoo.winfo_rooty() + self.BtnOdoo.winfo_height()
        try:
            menu.tk_popup(x, y)
        finally:
            menu.grab_release()

    def Search_return(self, event=None):
        # Un lector de códigos de barras escribe el código y pulsa Intro.
        text = self.Search_var.get().strip()
        exact = [p for p in self.catalog if text and text in self.codes.get(p[0], ())]
        found = exact or self.visible_products()
        if len(found) == 1 or exact:
            self.add_product(found[0])
            self.Search_var.set("")
            self.show_products()

    def BtnCustomer_click(self):
        CustomerDialog(self.root, self.customers(), self.order.customer, self.set_customer)

    def BtnPay_click(self):
        self.start_payment()

    def BtnOrders_click(self):
        if self.screen == "orders":
            self.show("products")
        else:
            self.show_orders()

    def BtnClear_click(self):
        if self.order.lines and not messagebox.askyesno(APP, ASK_CLEAR, parent=self.root):
            return
        self.order = Order()
        self.refresh_order()

    def Search_key_up(self, event=None):
        self.show_products()

    def BtnClearSearch_click(self):
        self.Search_var.set("")
        self.show_products()
        self.Search.focus_set()

    def BtnCatAll_click(self):
        self.set_category(None)

    def BtnCat1_click(self):
        self.set_category(0)

    def BtnCat2_click(self):
        self.set_category(1)

    def BtnCat3_click(self):
        self.set_category(2)

    def BtnCat4_click(self):
        if len(self.categories) > 4:
            self.more_categories()
        else:
            self.set_category(3)

    def form_close(self, *args):
        self.db.close()
        self.root.destroy()


# Imágenes de los productos: ilustraciones dibujadas para este ejemplo, en
# PNG de 96 × 96 codificado en base64 (tk.PhotoImage las lee sin Pillow).
${pythonImages()}
''';
  return TkExample(
    'pos',
    app,
    t(
      markTr(
        'Caja al estilo de Odoo con imágenes, teclado, cobro, recibo y pedidos en SQLite; se conecta a Odoo para descargar los productos y enviar los pedidos a Ventas.',
      ),
    ),
    design,
    code,
  );
}

/// Imágenes de los productos del punto de venta (id → PNG en base64):
/// ilustraciones planas propias de 96 × 96, hechas para este ejemplo.
const _tkPosImagesPng = <int, String>{
  0:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////8/P76+f36+P35'
      '9/z39vv49Pv29Pn28/n48vv18vj18vf08vf38fn08ff08fbz8ff18Pfz8Pfz8Pb17/jz7/b1'
      '7vfy7vXx7fXx7PTx7PPw7PTw6vPu6vPv6PLt6fLt6PHt5/Ds6PHs5/Hs5/Ds5u/r5vHr5vDr'
      '5u/q5u/x5e/r5fDr5e/q5fDq5e/q5e7p5e7p5O7n4Ozl3Ojc0+LY0OLX0OLYzd/VzN/UxNXN'
      'vdPOvNHKtcnMrMbLqsXKqMTDqcDJp8PJpsPIpsLDp7/Aobu2l7G5lbO2lbG2krC1kK+0kK6q'
      'kKa0j66uj6q0jq6zjq2zja2yjKyyi6uvi6mwiqqrh6WkgJ+ffZqfe5qdeZeZdJKRb4uObIiJ'
      'ZoOGYoAyjgdqAAAGs0lEQVR42rWaf1uiShTHUVSQkNYQoZA0sWU3ttlUivVmrXtXc2XX1nJN'
      '8+f7fxd3SEVEwOGufv/oyfA5nzlzzhxmOoNhlkLhGP/+FCh/J1lJUXgI21QoIqbj6Zzy15K5'
      'REKMhZ32CS4kFAFQdiCgAAlPk2tehCg8V9yJ9QUDADxpcyJM4h93aP5NHxPpqDV+Dr9Sdq6i'
      'wEUWABG/kpV9EMR5HA5CH5W96CqSmU+QBJQ9KWZOEhMqIn35EqiKUjAFf79ES6a4BB3ICwDB'
      'uJKTRJ5nj0zxvJjJKSoC5FIMY9HUVvvgPCtwzAF1QDNvomnqgGH5jKyqW11gscO4P0AFOZGl'
      'D5gNHRwwQlbxdwMIWUzy90DN8gxlM3t4aGcwXEbx90LG3ud8ACAvMLbBcxxNkhTHs9ZfaJrP'
      '+hMwyW/4GfvoOSYc5s7ORDxE8IwNIfg6gXmPX5V5emWI5cLM7eNgNBr+qp6FmJUTDMX6TQLm'
      'M/us3T4Vrgxm0+lkMp3ORjUqytsDnlGDA0DGZp5hY+zDbDoeT6Dgz1m/FOFsjykhMABk7CNk'
      'yZP+zDQ8GY0mJmg6LiMSMBT7DIs/zsaT6aiuZbPl6mA2GU+HIplEIWBe6WMXH6qa9n+dhyIk'
      'GQ1RjelkPHsI213wJGDu8V0ff7Q0hhZ/hQmeTSZZPonV4HxNKw6CCJABhaN1B8IPMzgnGXJh'
      'MMlFHqfj6YByFA/XJecKsOc/tEdlRtCB25CVmVykDLNpqq3FmWGOCmgAdS1BoblwxRzvkdOn'
      'WT20thhgGD6hANR8knGEuAGt1ezWOFyHzD7pmCNaUhEAQFh3AMb4BVrTcdt8JMkCXHPjD+T6'
      'WGgOwQNHBpnGsiNorBRbM0aaUA3nHC6I6nYPeNoJKIyns3FubbQc/jKbznQnwCXOToCas+xQ'
      'S7GarmsstSairOt6lqAXHy0XNsqeEwBE68vHSwkklHC8phMqRsb4k+UnzjMKTkCBtXKuen+3'
      '0D3UnUP39j/WyxHWY7U5AKq0TB2i9B1ZXxuV5ZrbKBiYM0epFeAbqu4b1WVdorlzX8A5ZyW/'
      '9v0rov3vd806vpyid3lfQP6dBdCDABoWgHLsdDH3EDBJooIOuG/+We76YHL4AVZJmiRugwBe'
      'DpcAmvedImsZU/zdv18R9e2u0S8SrPti9gIwVK3VRNbz4DORRAEUuFUJrfXaHUQZ/b5tC5BT'
      'fQCrtwrV6BptRLX6Ng8ca9kLQGV+PLWRAS8jzaoVqICT5n4BxHnrdxCAjgcDsNEyeghMQHW1'
      'SfIDWGkaDGD0bQC0dcBGtJ4L4KfReTIMN0ANDWBVay5ScQEYT71Ws7fpGgQ8RFn3d5oDIPkB'
      'jOemfnGqbS4QE7DMIv9ip+aszeHtJuCpeYEnErFE3fkIAn5SHntgzH3by0Y3rLSNno4fp9Pp'
      'eGlzioZ9a1uzXik2XvqLKJulyAnotC4SaVOJhvPZYNjPLADOnZHznbwMgkspemqezgFxp3cd'
      'CCjOi5EzBJvbliPPUmT0tNibAxetjsO311erVkj+2xbl0zxR3UqR0W0k4tA+XnXO0ApAc4Vt'
      'W8esdykyuvVSIn5RfXY+MAHzYnQgXm7d/HK0Z6Uwer/rtVavvQkYLGrF9s3v/HzjVYqMdrfX'
      '2VyAvSWA3jzjYK4nNI9SZBpzc+zPcDAvRkcyyhEq61WKPIupCTCLkdtJ1u0QKNL/BxBh3U5Q'
      'rsfYAse6lSJ/gFmMcioaAJ5yXEqRL+AVFiNCQj6IX0qRWi/IG9MEnHAgwD9D+Ho3KKAkBQDI'
      'pR+ddiDA66giBgI0AwP0IIBcudUO7IGADgCSHiAEbwC4lPkgAC0IAL4xzWIUBCDqvcCAWpAp'
      'Em+DAl5HP6Q9Ax7EIIBqcMBjXgkQ5HpgwLBfzu8L0B68moBSPsBKbjwbxk9UdUzAa7+cRQbI'
      'JaPX7T49I6o7HA5HQ49ihLn2AIGm6ZXbf1BVrd5W9C9eU+RKkCQpW9Kub25urrcIfuVGK2VF'
      'UXS1D7BMGrj3az/JSrGsXX/ZomutXAKFD8C9Fw1OMcGnzSXnc0qxVC5r2pszdrNw2JpWLpeK'
      'l3LOu9MKMmcYsaWPVoCUvCzDERZLlormgGUZPihsadTxsNWI2istyCuhdsZTsGnN43trxoJU'
      '1uy3p/ZlX7nCCbOhzO+j4b5yADZ8xURxH/aLOWFxMSGcFvZAKMoxYnktIRoXPu98fuTY4epi'
      'ReQoBnaaSwCkUsT61ZBYHOyKAddkau1iyNwJMhcXdmL/MpNIp6Iu93PCpLCL+xvg9Jiyjf4/'
      'H583/EroOwkAAAAASUVORK5CYII=',
  1:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7//v7+/v7+'
      '/v3+/fz+/Pv9/Pz9+/n7/Pz9+vj9+fT+9+37+PT49/b79O798ub59O758+358uv48uz48uv4'
      '8ur19PH88eX48ev48er48eny8fD88OP48Or48On48Oj38Oj77uH47+f37+b37uX47eH46972'
      '7uX27OH17OLv7ev16t/06d316dzt6eT16Nr06Nrz6Nvz59nz59jq6OT05tn05tjz5tnz5tj0'
      '5tfz5tfw5trz5djz5dfz5dby5djy5dfy5dby5NXx5dfv5Nnr49ro493n4t3l5ODl4t3k4t/k'
      '4Nzj4uDj4N3j4Nzi4N3i39vi3trh3trf2NDXxbXNqovGlmvFjVzBiFa6g1OqeE6DWjxkQCtY'
      'NyRRMSAdk6QAAAAGdElEQVR42s2ae1viOBSHMwKCxUIFuwxFJoKUa0WlssjyTKfdRZCOCC2K'
      'qDO73/9bbHoB2tLrAPvs7w9DAc+b03OSnKQAoOkAgEg8Wf79WuhuJ/aOzsUjYFOxZK1IFK+7'
      'W4st5vOVZNxqP1k+rvQFobsD8d1+87iYjhrNRz8fX/d3Yl2TwAvHeYMTGEHwOzSv+ZEv40v7'
      'EZrod3eufmVFKBN9trsHQrlyiKyHQPqY7+5FPFFD5kGs3BT2A+jeEcpNoo59BaDHcVzvjlXU'
      'Q697vpKJYFCEWxVvBziue8PUaLoAFdF0jWkp73nqayUO8KLg2fe7y3qJIpEoVeqrQpW58WQI'
      'xDk4zwsenb+pFUgyS1lFkrnqZc8dIVSagHH1oMddVim141BnQAOLzJYYDwQLXOdP7qZO6fcF'
      'DyehsV26QTddCTxwmz85JqebhzE0H8J1a0TU79wQwLn/HEvr5imIg0jK0JqDUWi5EICz/Uu4'
      'tK90PHlhaM3KUgwXHMAxpKGTBweksbXqtN4LCuAYY2J6ASjSkQD82KeoQ5BSQpvT2wAE4Mv+'
      'OQ5iFAlzyzYAAdjHd2PgRkAkjKUgqbV2hNMa5xvAbtwGmFLWjnBab20Dkb3kfAJ69KYBSJ2k'
      'MIDBZWtHgKw/gClBDf8OT9UcWrY2YaA5P4CvN18oeynDDBraTYLNgNsEcGXyVwG/XfjwwCaD'
      '1ql0kDK1my5sZhLwE2FNBTQIoKG1dfLWC+AcARLN1Cdw3VL+omAFcDUnB0gQUe/8srX/Uqnn'
      'AWDPHSOQJKGptVXWusAB90nIPNbMrb8wA7856lMbmWq9RRfUtmq5Alpb27fmEfAdAr+Auiug'
      'Rm4NoHsuAOdh7F+WSfs/Btxun0QojThnAAu3t29ZOf8ngLQiqqBJu9ghIJ0uVK/aw6H4faRI'
      'HA7bV/UC5QQJCkgXrobieDQaj6fPquSxcvX9oV2wR7gCNtI0XWhL05H0/DKfv74uXl+VP/P5'
      '/OVlNhpLw2p623GQroqz0fP8dbF4e3t714VeviHM80iSrtIBAVzd4gGy/7J4+/j4gfRzKeXi'
      '4/1t/l2abvpAlrquk50F8PgkL95+/KPqb13a1c/395eRbAMou052LdNsCpOZ2Xj+rjiAOr4E'
      'aD58vM/lWSNZgoGm6+6tZUkOJ0bjl/lCDcCHLjUMi1cU5zMQwawFQLblCrBEGdVwoUxjhJLo'
      'VQn0YqH8QamE0mjSyBxpp1nmGuD81mPRNwEKmHrgdpQ4a8jy84uqZ1luNxKJowPV/CcADkmX'
      'EGyWLdBSzC0VCh3pCoXA0vYn7cDS8D9ZxgPAme4RPFmdqpqlv4Gr+xGAw3VRcetV2VlqX7sj'
      '1rVS51C5iYfQufrdLH5LRhcKcTf7yDBMIWfWxfYX1rt8N4U5l3ID4PrpxWq7YC0pbDcg5kzV'
      '8shekeUxyQpgs0uz2eE0s2YXognM2QGKDKNXJ477D9tNoKk4glgokwjZRqCAPi7hS1c25znH'
      'bezthWm0hTF7QiwFYVodKLg+wdxw/gBc07wHjyQyiaidD7FYGBgcYDjfRwnMqW4cnWOSqJeJ'
      'DO4Sa+18xFozuh6G9Oqnyo47e4Jjh2onMZcBh1M5ZetWYgOdF6GjzCTmPozX80YMP83RbC8I'
      '4E8WD4MAOogzf90FAHxjYiCgwqVv/gF/8IHtI136DnLnXoz+AqA9uPXrgThrgOVq4ltn0oTv'
      '+APwjxO5nfAfYDWPr6TJ9L7j9xZNJ5LUPsOAw3q2Mq07eZRpT+TJdNDxe4s6gwlCzCbtRgbz'
      'iEYIFQRtcYbM29t3SNMOP3icPiGGPBm1G41MIhGNRo0THrpMJDKNRnskoi9Nn6aT4X0nyEDr'
      'IMTw8Wk6nUrSbCZLkoh2B+2VRqIoTmRZ+QR9ZfooDvhOJ+jhOGLcI4hKUTiSJK+kXKlvPz2K'
      'w8F9v+Nk3g2gMjpdRBkMHh4ekZ5WUq7Eh+EA2e66GFcBns8AO6p4pPuV+uhK+8DzQRS48/+U'
      'sbNSgOeyHg+Jtn7uew3o/B4BQrMFknsF5Ksgct3cH0EoorWcJvj92WfQuogV9+YAf5xUHljT'
      '+3pgjRxQp9tILd/fh/3+NXrYq86Q8XJlHz8aYImTVen0efcEgSWo9VKFFwlhp8kq8MVi0lTG'
      'nhMIsSOG0O8XTT8M0ZwgronKTux/beaL+WTYUpWgKyxd3sXvN4Sbci6+Nv4vUuL1rXCFSAIA'
      'AAAASUVORK5CYII=',
  2:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7+///+/v39'
      '/f39/Pv8+vf9+fH3+fr0+Pv0+Prz+Pz89uz99Of79On79Oj79Of69Ov+8uT78un68+n68ur6'
      '8uf59O348uz48uv48un19vfx9vj68ej48ev48er48ej38er77+H48Oj37+X28On47eD369j2'
      '7OL27Nr169716t316tj26tf16dny7OL06dv06Nrz59nq6+rq6OLd6/PY6fT05tjz5tnz5tjz'
      '5tfs5tzb5uzz5djz5dfy5dfx5djx5Nfx5NLu5Nnj4+HZ5OrV4+vm4dvj4Nzi4NzY4eXS4OjR'
      '4evi3trT0c27t7S6noewhWGxfVKwfFGwfFCwfE+vek2peE+sdUdqRzJbOidaOCZaOCVYNSFU'
      'MBxRLBdL33AqAAAGwklEQVR42tWaCVPiSBiG2wWCB2DA0cjgEM0lhKMIYTgyTgIiAQdRwQtZ'
      'R///v9hOwpV0zh2srX1Lq6gQ3ifd/fWXL90BwNAWAKFokmsISuvPVG0yR9EIQBWJcVSKElp/'
      'rCqVSvExzOpPcDGuoyitDUhptStx6sDUishRTOhsxH3OUJQYtdYILB5vbdDeEMVFF/4hJt5u'
      'bVwdjlu0IRdvV1ufQtDGIQSSsdbnSInnoD2IcBXlkwjNuDYMZKzj52RJlmWpWdUkwc+Sryak'
      'eNhFAufdAFluCYUcw9C6GCbHV7RjnvoJxzlKKZ7X3izkaDINRerSP9EML3gylBQN6JTicfFC'
      'jk6ns6RV6fRpriC5IxSuAnjXFkhygSHTpIPSWYb3QFSBa/6EV+9sbzSDqbgTQNmte/hTV3sD'
      'kWu6IYDz9ctVxtNeR9BujQDO/gXalz9JZkleDg6QeZ/2mo5zUlCAzGfJAEo7EsBG/F0IYDP+'
      'zgRgP76B/bVxkH0DqvTaD1k266Q0y56tBVNB9gmQ1uOf7fVOdh20czEUD1en0lV/AHOAsj11'
      'd0fXHvw3fHf29oxDZkCakf0Afgqmrl0AdjMEQSQTmuCHTEbnmQFk2qaTUICcM8+wnnqys5NJ'
      'JvA4juP7mnA8Ht9PEpDbU9l1wFfaRwusEXR4MTzZTsbn3ivheCKzp/bOLLEqewIkS4bTADEc'
      'CyX2rcL3M2qPNccqOs7AfQQ0gFrBEyEQwxHCPo8A0kjaAx4joAHKPB5BAYkEVe4hAEbyAJjm'
      '2AJQKkZBdD+xbp7YZ/KlMtICMmu9NwCvJHR4cfPjXPoCYtwRHGg9THH8iOLypWKpoKoskpI8'
      'ANYeIg9EDZAESalYLOZ1FTWV4N+Pm541IyGRau0iaw+drQBl3XVNEHBxiCQ9wRVgjSELoOgN'
      'sMYR8MjTBqB4BKIln4CcKwAZgjmAA1ip6A9gCVTgOo0NwNV5kfENsE7mPwLUAgOQaaaHqRPg'
      '/OpGPEDvneap5gk4ZDVAfitSLtkCzpAyrBAQoLcgHwrl/8+A0n8FqAUGoGE6B5SwLa5YMqtY'
      'sm1BwHkAo0jtnefPMcDMc+lK9mHqCkBTBaxb1F+Xl5dRULlE9OtGtEkVbtnU7qGArd9OxpNL'
      'cP84tmhyWxeDJrtK1g4wfZhCwPTx2aSnqS3ANV3bhREEPE2md+BuOnkwaWILsN6UQctrlNne'
      'cPxoAB7X9fA0uVVRgLUyAp5PZqzqAHge/0IBXjd9mz46vXAEDM2lqd5DvAdARvromwsAKYu+'
      'IrUj8Hx6goDJ0/QeXPoBoNWvZ/GrlXbjZ78AsupdvvMIoH5vD5ggAD/lu039bg+YTMc+qne7'
      'J5xK1g4Q6j4/WAD3dUtpatMA24dAc8Y7uFDvp09jDBubCRqgZ1l28fkYW11fZoF1S90RYKla'
      'BNkfQK6YC6M6nAIa4GlikhWQ5mXfSwn8saUFL+MINpm+mGQBoA83Losh0moYzg6uvt+/z17F'
      '7de3mUnvL997h2sDUA2ynLMi6ICP2cctePmYva1p9nG/BoD+UqAFqSVhDngbuQIc/Z2X1KTc'
      '8aI4rd+9/z0bhF/fEcDVgZe/y6KglMvO6xYImP1+ff1t8p8DzozxbUrBVx31ZcdTmv6mA2a/'
      'zddvAMQDlobrzvy/WtZsNRUlRxBY5EQDwAh6QwB1MYJFCbrZaTX/zbqpUjnFtsBfIKMDEOkA'
      '+DXACF5WggMUgQhpGzwa4BY2AAW83xkAqCjfCb5uGtH3H6HDrjq0zjFjoi0A8LQtWg4I6EZ0'
      'e03bF8PZxzuqj7v6ybwF8Dp+KEEAje4gvNzGC/eGd7YaqrsLwBao9RtBWtAfiWsA9but1OES'
      'AIjRoN0IABgMRjVsvg0cVodOggC9IyPiaHDdtQdU7bvoejAa1DJGHO06Su/HrW2xD/2duqhp'
      'n2W7A4gYXYnH22HgojBGiLXr0QD6O0S70yZRo92HiOvRaNCviWwmg4XDa6RwJIxlMqxYu4JX'
      'AU8b9O37p6WUAeOwzdVotH9ABtRI06Df79eWuur3B/ph7Xv4Vbfh4F8QAOG4jwZ/1O5CJ52y'
      'JC19dW/NvN1ysNc26hgQEcrOiaSh/bTbhRjIMQsegl+0jVMc8w0Fd0uZuMdeY6MxN2l3FzId'
      'dvMvwDjEKL+7t42lfG8oE9qGNRP7pP1k2AB9GoZyVOcz/DsC3OzVpyrGcZ9A6FRTxGLeRFPc'
      'xl9LUKopcpnx4UCnlI0OhKJQFGF6NeRbCiI2xFDaHSpOWd9uiR4JKW4j/j/zKYqKhVb9s3j9'
      'B/vCbeL9DUXgjqIr838AnWTXOE/KfH4AAAAASUVORK5CYII=',
  3:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7+///+/v39'
      '/f39+vf9+O/3+fn89uz39fD0+f30+Pr09/ny9vn88uj68ur58+v48+v48uz48uv48urx8/L6'
      '8ej48ev48er48en28ev48On48Oj37+f77uH37uT28Oj27eP37OD269j26tb26tX26db17OH1'
      '6t706dv06Nv059nz59nz59jt7evq6Obc7Pbc6fD05tn05tjz5tnz5tjz5tfp5uDz5djz5dfy'
      '5djy5dfy5dXx5dfv5Nnu4Mvs2bvr1rbq1rnq1rjq1rfm4tzl4dvj4Nzi4N3k39zi39rm3s3m'
      '2MLb5OnW4+rS4uze3trS3+fO2uDr1bbp1bbm07jWyLSxsLB6YVNgPyxbOidbOSZaOCVXNSFU'
      'MBxSLRj+YdNxAAAGO0lEQVR42rWae0OiShjGp1W8dMFOrEleICkPiKZ5FHeRvGSZrrvaWlZq'
      'at//W5wZMEPuFD5/AdHz4513nGHmBQBFOwD4sBD9Hy8JX1OuQh8HfEAvLMRQOMULX1aOoigm'
      'hGn9Q1SIqUuS4IFqQj0boiJ+tb3/OMTXPXFXJNWkEKUKAsPxmof2ShwUFX7399F4XfBcdWod'
      'QzpUzwtbIDAMyoMPHIZqwlZUw1loDzAqK20HIFTwAAyBDDhKQFUUxWolj1SFx1VHnQnnYBPx'
      'jH0AoijwHEvTyQRSKsVyPLpmq58MBgKUZPvsFS6dIgkoUpZ8lKS5nC1DwpMgiUs2D8+zSYKI'
      'kVoRxEmaq1ojJCYLOMsIqiJHkwRpIiKWskPkgOX4KfJpc3sljFTWklADWavmYU8s7RVEumKF'
      'AObPL+ZpW3sZkeQtCMDcn0s48ifJGMmK7gEi59Ae6ShddQsQuRjpQoQpAXjib0EA3vibE4BH'
      '/jAPxpk2BOQT5CcU40SHgCpNfAZAJvLOACL7OX+SoEUngJ98gvykCING0gPENPFZwPeUgwg+'
      '1YPWIeh7EvAqw6s8X9gBvpAB4ywAr7rQCpCq2gDySfJLimknOOBhig3TDDzroyY9VdtEKfKr'
      '4i0B/Jf9tf0IeJsCNC9YAljiywC6agEw/BnH4zFjEfG4/aBtD4gPhgd7e3v7SHuy1oelYSHi'
      'DnBh8DOLD2XALpLirRzCS6WRAYDcfA0D9nPl4P4guLu7Hz5NM2eyGOY0vo9ow+Gp7cxpD4gM'
      'RtHdaPo8s6FzNrx7MBwmvAEcHEFHjTKZFATEPQHcR88yAexMy8hEPQP8aZ75AKMBnDWb7gFG'
      '3TRSvP/z2DoExyoAzHSmef3nfuDF7wACfl+Ps4Bu/ps5l3tRJnPVbLbHj7/vBxGXAKPR+h2Q'
      'HbfbLVnt9u14fNt+vDMCECnBcrAzAzTB4Rj5It3eIJkBrAc7PmYFuFGrbdxE2ilNMx8YjBWR'
      'wv1fCNgJ397oAEU9IMZbAgyyrABaPl9LQ7juGQGSFzaTvgvADwOANgX615aEEeCxfRveaWqS'
      '8GgUgW6RoHvx0rURBAza7fEh0AH+6gHfUxd2b3b6WRlOCLCD/gMBN2O1IEA3HejffvUvvylC'
      'D2i1rjlwdt3a1EAP0C9ygP0CPD4cPT0950Hz+en5Q0/PT3qALsVGCxBdCKfDh+l0PgEv8+mm'
      'HnRTssEqzWCFk9VkIVF6mC7eJuD5bb5QSw8wWH84WQRGBqXJcgkBy9nrh2aLyUgzHRAph8vY'
      'iyShAyymwcJ08Tpfa/Y2udTON7zoDCBm9RHMp8HgJmA5KW0CCFZ0vJXAHm0ALifL12nRBqB9'
      'Z7TcDKmqJx4IeHmbLf6CydtsEzDYSEDezXaOmhApIsDslx/GsZkD1XQA/auuNqRUBAWwmG74'
      'Q8CLCmDqb76lVk2jPJzAnWQF8LrY8FcAh/DvJ5b+FpuCAksmEkdhDPMVSi/L2fx1NtcCSjsY'
      'FjgiEySdd71nJ1TEKzbgh9Wvb+DgEgE0QoAC/CMqj6WuriquAVd8WKmG2QJgEQ5jr1zvOrLv'
      'xbZvYB+OdvOZVsuX0jsAIpKiS0ADQ8XBD8DbUitVBOgu7soNoNzorets30BwOHox0MMw+hEB'
      'KN5duImg0y+oynjD4aWBhqO9jwii/W6j7BxQ63b7xeCqiAoBI2MhgNyQ/kK/23MDgE3U7XeL'
      'q37kU9Z+qzXmep25v680406w0IH+nbK7JHchot8pRoN+YCE/Fi386Pd/QX+TYhzICSYxdGRE'
      'v9v5USxEg0G/X0WCJ8FguFAoduRbet074/ZBgIoZoVzr3HV7PZmCOB1Iehc8US730Q13nUbZ'
      'zF+yKBLBf6o1OncypdeDjP6Hun35YheZNwRTe0HiAW1VhSrLkEajAzmQtBY660DrRl2+xbzM'
      'xfGwFG5XqCuXZU4NkVaCJ6vLNoU6ioalRse10vJajivjFKyW0tuq9iJ/Ti73bstfqIUOUcF6'
      'ayHAAOSBxMdQ9W3413lY7JUHG4xhtvHRQA5ff5YQxr0nSDmcfJ+zUKJxydPCvqT+rEImHOMQ'
      '4RFDqtepjQ9DZAWOeZzxxP9nFn4+Az/Q2dnwh2dYhMl58fw8c4x9mP8PtLQkOS2PSBAAAAAA'
      'SUVORK5CYII=',
  4:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7+/////v7+'
      '/v7+/fz9/f39+/r7/Pv8+vf9+PH89u74+Pf59vT99Oj69O788uf59O358uv49O/48uz48uv4'
      '8ur29PL98eT48ev48er48enx8fD77+L48Or48On48Oj47+f38Oj37+b67uD37uX27eT37OD3'
      '6tz17OPw7ev06uDy6d/06Nvq6OX059nz59nz59jp5+T05tn05tjz5tnz5tjz5tfv5tzz5djz'
      '5dfz5dby5djy5dfy5dby5Nbx5dfv5Nnt5Nnp5N/o4tvl4t7m4drk4dzj4d7j4N3i4N3j4Nzh'
      '4N/k3tbi39vi3trh3trk2cvqzaXoyaHoyaDoyZ/l0LTkyqnpyJ3ox5vjyKXOroyleFeQYUKK'
      'WjyHVTdx2dJjAAAGx0lEQVR42rWaC1eqShiGx6NomJe0OCrlpvAuoeZBXZstWeKldIu3NN1l'
      '/v9/cWYg3V5hvL2rxbIR3ofh++aKAGgyA0DYXeH/eCl/mNK5yIWdAOuyncfC/jCfP1jpsN8f'
      'PydX/d1hV7wkSfkjqJh/irvCXtvS7V+4+KejuGuSipIruFAJ8sJVPKK9Vo9g2DnzJyKup/zR'
      'VQrPCVHXUyZ/CkIMZZMFeF3F/ElUdCWgPbCF49JpAPmcyw6rQJ9jBaAgimIhl0EqwM8FrGTy'
      'czDCfMy4AqKY57lYJMIySJFIguNRmaF+xklgD0uG957joiGagqJVqZ/YKJc2ZEj+W3Drlwxu'
      'nk+wFBWgV0VR11G+oI+QYjzgdGtQEPkITdFbRAVCnAEiDXT7T5GPbrfXqhHhdQlFENd7PNy1'
      'rr2GSOT0EGD7/YuZiKG9imD1KgF0Hg+D5U/TAZoTdweIHKY90lW0sCtA5AL0DqK2EsBR/HUI'
      '4Dj+2wlgc3x39odxiInYgAxD76HAxmzdBChEqH0ANJPBA+yUoMthEHEAP/kf9J6iNjS4dYAY'
      'pfYF/HuHUYO9MmhehfVMAseK8HecH4wAB0RgcxRWAWKCOggQKhgAMrf0QVprbeDgTmilCgkD'
      'QJQ6DLCWqauP6I4+VLwugD/YfzWPwHFDsB6EFUCMOhgQKegAdJvx9cIRv9M2BHg1XbPUFRti'
      'Q1fwOCvz7g54uFv1ZkOJ+1RKrqRSra6cyqrHqizL2dR9IsrSmyjLTQ1sGyvhlaF7Wa6+/Ibq'
      'ZIefk8nnH/X4ISuNBip9eZHl++iPFUYAD+BlU8hbaXW73eFw+GcynUymX/Dvazr9GKrqdlsK'
      'pFTl6BICD8DKzUaj1R2+9wej8Xjc/5x+Qk2+VE3GgxEsHY36PUhp/lZk1rsrQO68tIZv0GTw'
      '1u/3e+PJ1wJg+tFDpf03xBm9d1+U+gIBD1Bt13tj1UQTfEJz/68vCNCEzhiNWw0FF/Cdpozb'
      'ISvd/mg0Ui36g97HdDpz/5p+9gaat1qHt2HnxWdnd2wHZuBLqSEYqYKEiYaAR+g/GGjlb73h'
      'sJVNEsDD4AFm4xmD9mLOfEm5hVLo/R2F4eMDuk8/P8a9Abz39+E7zKNWNelzwL0sM7UwpuV1'
      'O7sFAJLV4btJplK1Wr3VbcFW8KeF8rZWq2VTyRuf48yCTjIBgmKZLbMvsHHOwtq1C2eyWK1n'
      'DofFcfOPA+rMarXOvzKrZxKkm8HprvMP2pDMuOcGJvPizpVp4bPZtLRnRlLMpkEZbJ4VUeYN'
      '23rAYgHbBGGEeuntg8GgvxIEPGlgG7NhAgw2Lw20IOCKpN3qDTkZOsAZAGbTis3PaIvcDMMi'
      'AsEE7h6MZnazPCLx/Qk4yjEe1Bw867Pf9clvSK3CtQcf4GRmUXOzGePp+yzM5C4V+AZcJgrG'
      'C5CFTDXh+Ju1JkahTPLkcFY431GAXaoTqwIMAoRQhc1YS6h5j/fj0ofVGkgPw3idqK05pRzW'
      'MvbhTiNc+XxWrCjYbGpLI3gRb50szmaol4YE88KbAlO0lMPdSuCu5gTdZDLbA/OnaLl9xN8M'
      'KcyWCZDg3B4IwhNiWKcNJRtBsoWd9ouiAbQFSwcunT7H9vA6ne5LOIfyeLx0JLPDdo74WPoV'
      'cTtJG2ExARthFAYbaXdfZ0olMY8Xg8dHPuImCbBbh026Q5xYwlnpPyacFrCXTGQo/8sIIKbt'
      'q0Mjrj26huR+GQCK5F7u84GTuC/oAYTnqhWYwQEAkC0/6NWg3smezeYie7iDf5JKsyhsBxTr'
      'TaWaPPs74dnFHLY2n9yuN591AEK52VA69dSNY55IZl2QaT45MpO+ZLWjvDYqgt4jEp5rzUaz'
      '3VGqKTjrxOtLgZV03qTkZgfZ18sGWSTknyv1RqOptDvtZjWbTSZv4GQRzhWty40DlcAvbpLJ'
      'VLYK76itwCVRs1bOC4YtWRCK5UoNQiAFYuB9KUoVKbWgLCpothX4dVtB3o1mvVIuCsJ6S05v'
      '6IvgeU/lcqVSr7++NjQSVHtBagHybTRem/VapVwuwquETZ1dLr25F4SnC8Wn5zICQVIdwf6q'
      'iQrgF9D5+Vn1Fra8JjJ4SSRoKkI9PS8KlXx/Kei9huJB1I/7olFYFOZ75TgPzv2nepOpvqiL'
      'wqlA/HQEKQz75sip3vYifw62HjJ4sgoUXW60ODlZFaQgp/ZURCxYOoV/iY+R2uKKDMdO8aOB'
      'tH++xnD6w0cnSGk//XdMcQZd0lGTVSoGg+7ln4b4/dKxGNJTKbz0wxBV9gveHz+K/8+4Pxw8'
      't6xMTuB/pDeWPsb987EL+1/z/wEzi5LmYdN+aQAAAABJRU5ErkJggg==',
  5:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7//v7//v3+'
      '/v7+/f39/f39/Pv9+/n8+/z8+vn6+fn8+PL79vH99uv59vL69O759O/58+758uz48u758uv4'
      '8uv88+b28/L88eX48ev48er48en28e/78OP48Or48On48Oj38Oj47+f37ub57uH47N/07+v2'
      '7eT07OL16t716dvv6ub06Nrz59nz59fr6OP05tn05tjz5tnz5tjz5tbw5trz5djz5dfy5djy'
      '5dfw5Nnt5Nro493y5NHl4t/m4eLk4dzj4N7j4Nzi4Nzk39vi39vi3trg3tfnz5fR1bfrxWzp'
      'xW3pxGvpxGrpxGjgxITmwm/owmW1y4SjxWadwl2dwlucw1qcwlucwlqbwljdtFa8vIKZwVWY'
      'wFOWwFFrhHsuAAAHPklEQVR42rWaCXeaShTHJ0ajUXGtuGAtIhjEJValRdyXqqVZemySl+TF'
      '9Pt/izcDoqgIY57+T05GRO9v7tw7KwKgyQGAyx/gvpblxv9TpZ5J+91gV55Qnkty5cb/VoXL'
      'ZPIB77b9EBfIy7LcOIKaDbkY4GIbXriTgXLrKNY1yU05kDE44Y3Hm0c0r/mR4YK6fRcXP7Z5'
      '5EWe8y8BfECuNE5ByKM4OEEs0GycRM14AZoHHq4onwbQqMdRI1EBLPuiJElivYIkwtciViMl'
      'BRjhct4eIEmNslBgWYZGYtmCUETv2ep73g8ITrate13gcxQJRalSXzG8ULZlyMksyCZlm8qX'
      'CwxJpqhtkWSaF0TJJpGKQLD0QJQEnlpWnF5S6BWNTLF2iAqwHD+l8so8RfmdIdpYam6wRUtC'
      'ExStmkdIr8zTHjgi0utyjeDrVgiwv/5ShV2Zp2gCuCOG0hgMxsoJYFF9em0fVZzIGUqjUpQg'
      'HQ6QBHKjmg4HaSw3FeXFQwGSsJmY1gCK3EsAePYpyg0iKLTpZYlNAJj2s37goUg6rZfYBIBn'
      'H8oFXE5vhCa1cpcQLUjYgIpJI9ARNHucR5elSSBSprlkBhBZszjSVDjqBV5aL00+UcEDbCWo'
      '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',
  6:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////+///6/f72+/72'
      '+v3w/P7x+Pzw9/vv9/zu9vvt9vzt9vvs9vzu9fvt9fvs9fvs9fro+P7r9fvm9f3s9Pvr9Pvr'
      '9Prq9Prp8/ro8/ro8vrl8/zk8/zm8vrl8fni8frg7/jf7vjf7fjd7fjd7ffc7ffe7Pfc7Pfc'
      '7Pbb7fnb7PfY7Pnc6/bb6/fb6/bc6vbW6/fS5/bI4PHF3O7E3O7B3vLD2+692u+z3PSz2fGt'
      '2PO31++r1/Oq1/Kq1vOq1vKp1vKo1vKv1O+o1fKn1fKm1fKm1fGm1PGk0vCh0O+gzu6gze6f'
      'ze6azvKYyu6JwOhpqt49icw2hcsxgckwgckwgcgugckwgMgvgMgvgMcugMgtf8ctfscrfscq'
      'fMYmesWgTpZ+AAAGg0lEQVR42r2afV/iRhDHcyKIl2vSgDRwEpJAJG3ORBIEBLFAkeIpIg+l'
      'ciLw/t9FN4A87C674cT+PvcH4XC+md3Z7M5MGGauT+CfLyilVUt/n1Lp2BffJwbVgV8OC2FV'
      'f7dScUGQgz7YfjDuly3L0vegc91S/PHPBxu3H/KrF3uxPpd1bvnDhyv7vi/+8z2an+lCCAeW'
      '93/qv9D3Lit++uZDwn+h6R9BkA9m8cn5z/UP0YWQcMP/IK5YHwPQ04I7SL96mwDDBJp/dD8Z'
      'ngZJUMAQJWW6A8C0qsixEHvsihdlWQVED0tCPmQO4yb13jVFEvnQIZ9UVFdJycdzoiRrhkF1'
      '4TdGFCyKeTUR4VhODDjdXnehB5/Is2xIUiluWHGFkcMkgGGoEs/yPB/hT7rTl/FMo8nYDojg'
      'S5aLyhQvUgzx+Wkm5+YBIJjuvfQHMz33p9c+cfY1x8VUIuF3hvT8NOSFeReQ7I4Hw7n608IC'
      '4CISOgnBbL9/Q/vK8TwNAAZKVAkzwWy3r0RW9kkAnuNlY3eAKa+ZnwNGK8D1OgA4IRm7AiD7'
      'fOSz1J0sJnkwmGYPNwAEAuPNPh86Vjqvk7nGk44diPDeCMyW8IHsA8Bf909L3d9JLO+NgAUY'
      'Kmw/ErDbre93b3poF2AXeDZhegZo8B/zvFhvPbTWlQqGoJ9w2CWHAxgx1AGnfb9u/qFdPIIB'
      'fETzBkAngD+WN8zPCDY6SLhpwADSyPhEAoU2RHho1ZGf8ZxieACYEhJBR9+gCQC6bzuIC7zo'
      'wQM0gkCIFtsIoNVCQ5XnEgYdEMOF6EPrHlILF6p85IwKUNGhFZutu2Z9U9X63T0uVJHHHgww'
      'EywmRCs3VUQ3N/fFAAKI0gDIGgsF5btqtVJBCdXydzRUkdXGwJsAGkKFu5tqs4kBVBqVKE97'
      'YDBwjLJICOUaN41cro4h3JZiSCCJZ0TAmYjE6C9Xt7e5cMhpoKNUL0nH8O9P0kRA+gTxOVaq'
      'NnOn8QwGUGn8gTyRWMUkANApmAEaV/FTz4AECYAG6c4ALmaQPIi92wP4of0/A9Ag2h3Aby41'
      'hrZX7gzgfgKwS5j+JCActj8QUK/eOna5Xq3Bqu4J8Ge5XKvdlDGq7QrAhmnz+1a1vr17Hbin'
      '6t5W/VvwiTsBMPtZMNmbvIzw+jFFAVyU9DQ1FQyg+9rv94ejl2G/P3h2tbzqYwCsRHyaqhwW'
      'MJkOer3+ZDIEKcjzYHmFBcjmThvOLHUadzvuob3THY4Hg9Hq6nWCGSLVIO7J8CxHgkrvn077'
      'sQ1MPj4+dafj/voVCqBsmcgkRI7S3adHcLs9kOZ32k/d3sbVNQyApwA9tpzAp6KLzlNnOB2P'
      'RuPJpPPU7bbXrxAAcv6FAQZ0rHCHqNcb993Z7b8Me5Px+hU6RCLt6AjHkTvJkx9v+etwNBi8'
      'viyv0HWA5lHo4TeK5MevS4uunlcf0TA90einazQBH28AhgQAJ9GP71Ck7gbAZGkMJYfdCYDL'
      'ZHFJYAIqgoyWJQRIcFEk6jVPFjfKOL3peILXGCqKqIbHPHk9yzlOPBFkr6UgnGx4LiXI7NqO'
      'dlUqXZXKVziVUqsdbUuxYksxZLWe2Vi5WW/mcs3bOqJqc7Unc9GzXco5K4J7bPl7S36wdmwB'
      '9o2dClJLgreD11b720tqxiJ58XR0ZLfaJxUF58vBC4CV0sbuVcdF2ZEOIBYdSQBQOAUTQQWw'
      'UVLZlAhwd9DoMRkQEMmFXwpAN88TEhEQ1SndAYbaYzDLW8O0emunaS0EKiBtFGvb8oNq1U7r'
      '7wUYyVzzpmbbJbSWULkt0rssVICuZoCtRhNTq6g0beXdgKRl29cNfDmnUXRsS6MMEpMiT4Cd'
      'zecvr0G2hKhWK17m81nHIncRmTSR4OQvgbKFYgXJz0qFrPt/+SyxyWQxStyiAi6z2XwBUv5y'
      'Zh8QMgQXLJX5SmpzaRknn587gWhuPe/YJPuyygSIfTRNy9gOMLPArGn2Vdax9RSxUfeVOUiS'
      'e6VaUs/YtuM44KbzCwF/wBe2nTGSKfKTxm2LR6ndXi2VTGk66Phn5rIzpmVqmvslpdMYVkC7'
      '1xf23L3V5kp5bW9f+INuw/rrRzTcVw6AjrUsfEjH2lJlHzMjHIbjH0CwUsLR22sJASG+97a+'
      'pQknzPIVlMNTwdqrE9Z5ePVaxWweREGw9sUAhsIbL4bMnRBUIb4X+6YsgNvHvKBzwJ6m9hM8'
      'obX3f/4D/MSCOKG5EsQAAAAASUVORK5CYII=',
  7:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////9///9/f36+vvv'
      '/P/y+f30+Pvu9/7v9vzt9vzt9vvs9vz49e3t9f3t9fvt9frs9fzs9fvs9fnq9/3l9v708uzs'
      '8/br9Prq9Pro8/rn8vrn8Pbk8vrh8fvg7/je7vjf7ffd7fjd7ffc7ffg7PXc7Pjc7Pfc7Pba'
      '7/rb7Pf/2pH/1X7+0oH/0Hf8yGz7wmH7vlb8vVH6u1X5tk34sEX4qDX6pSv3pS/3pS73pS37'
      'pCr3pC33pCz3pCv4oij5oSP5nyDe6/Pb6/fb6/bb6/Xb6vXa6/bf5eXf1LznyZnwsVb1pjX2'
      'oSbzoS7xkyHviBDwhAbU5/TW5O3R5fTR4/HW4ujQ4e3L3urR0LfE3O7B3Oy+1+F6u6o5pJYi'
      'nI8fmIhwGps6AAAIM0lEQVR42rWa61riSBCGYwiCjMsOEAiJgUicRTMsB4ewMMPRMCAHIRBA'
      '1xHx/u9iqwNIyKGBlakfmEdNvVRX1ded7hDE0k4IgnR7uEuhmfyYJUT2k/uEsJrLHaNDtJD8'
      'sCVomuY9LrN/L0/FWs1m8gh2nWzGKfqMNLonQ5TQOor3pTWvm1To1DA8Ier6iO51a9H0O4Hk'
      'qVby6NaK8WsC+BePD0i2eZ7U69NPXSd/i7VCFwSJBiiOHf92+38TxJAbQgjiE9DmWP2npCiS'
      'JOomoeu9iikUhwAuY7gAmtzLXEgoSlKI8xwbZZCxLB8TgLgHInZKuGkFm6iXt7c5d8lFAz6f'
      'zx/Qze/3+QJRLgah7AyBIaIhXADtz/O3xaubWfs2GEC4+I4wmrE4EaexAO5l8TZ3RwO25vOz'
      '8Wt8FAkCq59K8o/HxeL1wmvnnolEPns87GXrJ06YCJx+SjzjvXhdLB7dNv4jHooKhsMRir5p'
      'YRqJcP7+ksj5A1H3fPH24rKMEcNQ4W5vMBwOet372I1zEISz/zgDmWXJOZQRyZr8Bz2e7nC0'
      'MrV3f3N3MECJ6YXDkqhOzREEPZEeOB72Zbk/VNXRoHPTOhCw8g9D9AJZ9jLb4/Mp3Af3uXQK'
      'LJ0dqKNhx2mUCLz/QMA9fl28/twuo2CoN1L76VQ6lZXhI5UHwv3N9QEAKWZoLCijl61OiFBd'
      '8J96B6QRoefQT4R9fjf+oy7I8ovLkOXgp/BwNEyn5UwKAVLooq+OOnRrb4BoGHJrGekB5FKp'
      'DDhGEchZuB6OetQXZU+AxBoGiHWhMjIOUYTqoQDSqUwhk5FT4B+uB6NB5LO4H0DijcoWdT9B'
      'GXF/bH7zKTIY9VH9QAw5GX1/sPxIvfdcSHsBLrdr3vsFykhzG3oAUiCnsmCZXKGfz6CrVBaS'
      'QAXj0h4AhTMGwEQDXlRGLsa/sj+XAFm3fl/Oo5/pJSC6RwTGCgL/mvYngcroxHu6Nnd4PUQp'
      '5D2jX31TVQD4eWk3gN0GzCIIMCc2gNN1kqF+MnnINEpyfzSMeJgAc7UTIGwl4AwBXt4Wc/LU'
      'AIAyzaL6z6EyRdWaTkOZhoIwm1qyYAYovM8MIDUoo4g+OLrBGKnqYFn/qNEQQVZHXSoCAHYX'
      'QGQsEbgikOXxCbg+Dy+NyozUfCq7looMSjG0QRAtCAQJC9hOMdTo3ezCfQIT/79f//47nV1a'
      'Lp1RVSCsAPCp6inWp2lewQIUzmdqgkc+/BUAczmfz9+uLH8rg8s+1A94h7FS0QAFV415hQVc'
      'mWYWiKCbl+eLxfz2Wy63BuRuc4igDvLZ7DeYcUaqnoClXWIBpi6GCGaZ29suZPl223J5NJON'
      'VPQBE9rGvy+uYADmFATOLibdQr4LYtG7/bZNyMkD5F4d9rrBjX9LEghckSLAtFOvZ1/fFjog'
      'tzSUBujhQrnR/bcTpqjPwc0d5kIlMG28jKBTb2Qhy70fxWJhZcVSsVqt1WqlemcS8wQjwa0J'
      'WzwEEGDGneqDjMrox6BqsEqlXK4AYHrhM9+BA1xZF1jarP8gg1i8/ihXTFauFe4fL87Mt2y3'
      'GoHr4xWg9k8HymhQ3Q9gkqNdgIA2k2v1DpTR4IcFUO3PNEvMBwLOtEmv3uhAEvqWMSrV8zON'
      '+TBgCgBdLKyARnY8+zDgbpIFgG2WS/Xe9ECAtUy9d5Nu4yFLzl/7/1SsEUw0SxEd2AcrABFu'
      'WPxXio3uoQCLVCwBVZk871fLewH8LE5NlbgZoGtFtUCShZot4M78+ObjsGoq+O0A5dI5mX8o'
      'WfoAlMIKwKqpVSt0OS02OkS2UbQkGbTOAjBPykRyl5yCVlQBkLEHfDEDdkyZ1iQgMao0vhJf'
      'LQBbKTKnwLpssVO7qhNgZgFYVl5mgGRaVgSYGWgFNEKnXrLTOjMgumvpaJ2VtRWgUdpD6yzL'
      'ol2L3zUgT56XzJ1WavSsWiceuHzX9brbqNh1mo3W+bndy3dzCLpWfC+ck/KDDUDD6pADIG4F'
      '2HaaVYqsGdjjIRAA0Mr1fQBmnXN+To76jYtHBLBrBKvWCdKez8mCWe1sAWYpsnlAc9xKMEwL'
      'ZxeP9/1yI2NtBBPAx0kHbIZs+hkASCtsOq3UMAL87NUh2zkGgi5GD9/IcM2sFCVYOJ5t/EsH'
      'bUhtCMxM68Gc5jJ3WrnW32ido3/nLbV3AjODpVelcO4yA6obgM/RP25TcN0OSIxKlbC5Eco1'
      'eb1w9HGidPiu42rbEYlRpoFmZXl7VgalWGqdP8Bjdn8J3L6syMGeta52xZqcN2nRWut8rIDb'
      'wCawO89KPOpfAsq1+ncbMQ34GD6J3b3GA2Dzmj/T1a7yvWS77OLEHccIxK4jBkXQJtbpcgWY'
      'CTtPKYjdR4cAaDgB/kp+HHDVmnaK30sWK9ZhiBIfBoiC0AKtaNStBlKkCYL4IYCQHE8fn7RZ'
      'x9Zm2uPTdNzEMwhskJPn51+/nmfaxNa02RP89XnaxhEIEUN4hNvBZo72pP/9GXOU18QdEknL'
      '25+fHG31D84hNAWCcwaI7cfnX887DP5h7Ow/JsBBnfMpjii2J09LJw6+IQPjpPMgN2kOjhpx'
      'Z6WiICrj8WT6ZHX/NJ2Ox+0ktoYUdGjN7jrtFRNCQoRD2eb43dpwRJuAFhHxXdCk43Dc66L3'
      'Pr19t30PlCkvnMYS3O84cF8FcLI80qd/C6El8C5Cf/nBRcfav8F/IuRdv5ZwGood/Vi/KcJZ'
      '8vsrKKdsqHnUFyua1zTt3XqzJRoCxJEYzZ8teuvFEN3cISEUO4p/JUbTrJu0eT/HxyeO8f0F'
      'PmR4/+c/T+SHtnu50d0AAAAASUVORK5CYII=',
  8:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////8///9/f74/P/4'
      '+fvv/P70+Pvy+Pvy9/vu9vzt9vzt9vvs9vz09fft9fvs9fvs9frp+P3j9v7x8/br9Prq8/rn'
      '8vrk8/zk8Pfh8frf7/nf7vje7fjd7fjd7ffd7fbc7fff7Pbc7Pjc7Pfc7PXb7Pfb7PXm6u7u'
      '4uPd6fPb6/fb6/bb6/Tb6PHa6vTZ5e3W5vHU4uzU4OfO4OzI3u3E3O7D3O7U1dnD2+7C2+3R'
      'wMGysrW/oJ6ZjIqqa12KcWqkYFGIVESATj5+TDx+Szx1VEp9Sjt8Sjp5SjrlQzqoQjZzRTdc'
      'MCRUMCZSKh9OJhtMJRtNIxZLJRpLJBlLIxhKIxlKIxhKIRZHIxhIIRdHIRZGHxREGw9DGQ1B'
      'Fws+FAiPuWFtAAAIT0lEQVR42rWafUOiShTG5/pWakq6gCjKutdYS1LULEtzXS3TUpHCtcW3'
      'vv+3uDOgrgIOenOf/tiX6vyYmXOeGecAwEoOp5f+FhNSn1OCo088/wCznO5oOBRmU59WIhwO'
      'R91OY3xvxB3NCULqABJSQswd8TnWwztCbvYw0RcMQXCHXGvTE3IfMrzOCEeOVs8fcedSB1cu'
      'ElmOgXEL3OEBKSES1dch6BZSf0VCiAEQ4Yz8/9y/vMB+mwt54ABOd1sAPpPheU4Tj/6uL2TY'
      'dgjAEY/YDyCTSbExhqYpEommmSgLiUK0cp9IYn8v6gKeSMb22TmWpgi/3x8kNAWDfj9B0d/C'
      'lefn+/AldggkoEKCTXiWIYPL2Gvyn7rvn59/4AERFjBhHIDnWZrwE5YiEaASxq9gAnxjMYBM'
      'fGt4NAbXeeU8xPI4wBmI4Z6fwYQnyGMAAml3kE7hEGD78/McHSQwIt3AEaBOCD/FYvIEbI8f'
      'I7HxCSIQAOcQQAQJht8fkInahNfX2E1qq0Hz+wJs40PAjxUAQwD/N/7pCfn8/FxeALYTrAG8'
      'bXwISENAOnRK4AmWAJ61jQ+n6ChwXkmfnK6qgsnsDOBIYgcA3K+0JFoqaFlyVgCe3mEABOEE'
      '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',
  9:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////v//fb/+/T/'
      '+vT/+vP/+vL/+fL+/Pr++fL5/P33+fr9+PD29/ft+/7u9vvt9vzt9vvs9vz19fPt9fvt9frs'
      '9fzs9fvs9fr08fDs9Prp+P7p9fzr9Pvq9Pvl9P3o8/rk8vrm8Pfi7/jf7vne7fjb8Prd7fjd'
      '7ffc7ffk7PLc7Pjc7Pfc7Pbb7Pfa7Pfn5efc6vTb6/fb6/bb6/Xb6fPZ6vXY6fPY5u7V5vLU'
      '4+3V4uvU4enK3+3H3u/K3evE3O7D3O7i19rlyMjD2+7JysrduLj0qLjBt7L1orTGnJSrkIGn'
      'emmZb1aSaE+PYEONXT+MXD6MWz2LWz2MWjyLWj2LWjyLWjuJWDmIVDWvRDzVIzWFUjOETy94'
      'RyxdJw/HOA5CAAAIKklEQVR42q2a+2OayhLH11dSDYLmmFClCvhoiNdLrTQ+ouYkmodRfN8m'
      'eoL6//8Xdxc0ARYWPc38Ui1xPuzMfGeXXQD4sEhMLOSV0p/ZhSScngAHi9Aiz/H50h/bBc9x'
      'Ih2x+2d4WqwqSukTTCkpeZqPWRCRb3T+c7xvGYpCfzMFKsLR/969yy8Vjn8nRET617+/2e/f'
      'nS9UxXeCSCvSoWH+8N/pXLgRRCMPCfrg8LwXM/T//Nz97hIlOqsHiD+89lv87tPlkzugJHEo'
      'SF/3S4BcqciyhOyX+LDu8z+NAZSfn57q390iyeUgoCB6D6BSKRVyoiBk0tAEerjp8T/lCgJ0'
      'CQOAvxNPwAlf8bx3KSdm2Hg8nmChZSO9jRpJZYScVLm8enp67rgDFC4NBE7xcF8Q0wnDN8um'
      'Uqd0UVuXYykITGdhip+efl66V5uYAzmeBJDlvMDG2Z2laLr4V3/Tiwj610TsiRgh1JmARKoh'
      'ePcm99B/uf/29o/KJb7qXzmU4jIR8F9A6p9yzuyeTZ2W33Tr0imDh1J8KpZkgg/gjpclIcGa'
      'LUX3DcA/+gDY0yxMcZk+y+QJdQLc/efTNv+nxbc30xBSNEpx6pxNsDn5cEAlZ3VvitAuRqco'
      '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'
      'Tk9A3jIAAAAASUVORK5CYII=',
  10:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX//////vj//fb//fX/'
      '/fT//PP+/fn++/X5/Pv4+fbx9/vt/P7u9vzt9vzt9vvt9vrs9vzt9fvs9fvs9fro+P7p9fz1'
      '8+rr9Pvr9Prr8/np8/rp8vnm8vrk8/zl8Pjl7/Ti8frg7/jf7vje7fjd7fjd7ffc7ffl7O3c'
      '7Pjc7Pfc7Pbb7Pjb7Pfc6/bb6/fb6/bc6vbe6e/65q3Z6vXY5OvV5/XT5fXT5PPT4/DV4enW'
      '39/L4PDI3u3t16ra0rrH3e3E3O7D3O7D2+7syoX3xV3uvWDzt0fytEDytD7vtk3zsz3ysz7y'
      'sz3zszvysjr0sTTuskTxsDjxsDXxrjHrpzLqoijpoinpoijooinpoSjpoSfqoSXooSjpoCPq'
      'nh7qnRw6PKyGAAAG70lEQVR42rWaeXuiSBDG2yRKvJjBYSSr4iDKPMsugYz3kVsicXXMKhmz'
      'k1n1+3+LbcCDo2lwY95/TIKpH9VVXd10AcBOp6mCwCvi21QRCh8TAKHTBMfSLC++WRWWprnk'
      'qdt+ik1yNUURD6BzUSkl2bQDcfo5yV8cxLol5VxJfrYRTj8mzw9o3tQF/XkXCjZ5IR5cNZbd'
      '+FBMXgjiexA4i0Alz8V30UWyaAaALSnvAxAF2gjDp3ABkGRZkgRTkvFzqGSiDRfKXLADsizy'
      'pWI+x5jK5YocD4khpgSMQoKVA+9dKBXOMiRJUhlTFEWSGabAQVcCXTgDOVoJMM8XGWpj2yaS'
      'ZAp8gBsKWwIciwNIEl/IkBkfkVSOC/CiArD1Uy5jzFujleOxhD8Arn5KHN68hSiIOATwv39J'
      'yFOZECLPeEwkgL/9EhPKPnQiw0n7A2QupHnTiYK0L2Av+zgCCG2fyRjTi9l+hiQAn/Rx22c+'
      'xAnimIh/oNafYQlIgMR77CeIY0ubz4RnlIpyaIDAeOwfexR3f4lCTjkUQMq5HGBIwgs4Tnhu'
      'QwgHcAWAgdMhjrB/TFAw2IFhQADKzvtKGFFFiyDilB1BlaQQALlgd4CMH2NFOAaKCeGBM4OY'
      'APuQYC+HVFEKBtgdQGUPNpuYr4EAPrOXA24XPGXPDZCL9u+TRDDAka5ULgjgnGN7A7yzDbgX'
      'AeccswFOTmxG7T9/wBYM4M5R0icGJ7HIyc58bIcgnBPaHWYX4Ktr+lPE+u6PItl4JLq2f0Rk'
      'jyLRE3TFKGMBZVQVPYlGjkB/NMwC02g0ElFHahZYCLd9siRjAO4QQEIqTkRANAv6+sw0Gj0C'
      'sb4+1gfVKIgQ8YR3XcABnElqKvWtdaUOrsCVrs2g0RiIVlVdG2kTfaheNeofPTsAV6ICfKE2'
      'AM2+rpsAaHSgqsPZTBuPxyNtrPeb9bRneXYV7VCAp1kfVHUNGp3M9OmjNn58hAjtaX+AO4mg'
      '0l8MgAqy6/vWRvBjOjUA0INvKe8OwznVAH6tNACt64mumh5spaqmB1ctBID6H4DpVI1l4QhZ'
      '1h+narWqTh9HT9eHAjyNB0RsMHkfQCYPPZgMYsQWsBkiA/Al/XbAWb07+D7JAnWmPW4AZpBH'
      '36/bxT0BiDS1ALMqUPXJdAMw0nQ0GdQ7xbfPgzUAeqCbA7MVBHT3BriqtalP9e7wu14F/YEZ'
      'WgegnU97SwWumsolLyBdbz08GbUCAaifITby2GrKUwhA2wK4hkibPdQ7CAAn77PgbABmMdoF'
      '2QQ8PbQQAPeiDDC7ou0QbYrRowvQRgxRwJKJCIJVTjfVbpOka0A6KATebUsGCYC1YjeVzWlm'
      'VOuWF+DZ/wLPzpEMBFjB1vQrxHLABG0dvXlkrJk2wKbUmcuBB+B9jgKBjzdmOdXMqay5Ad5i'
      'KgTvrjk0oLoG7Ibo6coDoArB23ePC16AFWTUcoB4SgOBz7DpL+3uSLP2FfY0RQBQT7Koh8Ci'
      'g5DOw2r3lx2wrkXGepPC1Tn/52TnMYtRrye6UStGdsDYu6DxUsjnZMdTTua3evf5x/IBVJfz'
      'Hzb9eu46FzSKk0IfJXCkC/BrBQGr+etOPxcugM9hhc9hiH0+n9Xbw+VyCLKLn/O5L4DKfd3n'
      'OMdOMFac5eszcfS8WCwdAFsxhfalvQ6kbAQIGEJAjHheDIe/NoD5cljfAXzt+x+pSYXUFtB8'
      'WP07z8ae4aI5XKxHab56aG0BpK993KHgZjpAQH81X2TBg+YDIAuCtP+p4/bY0ajXq3/mWfD3'
      '0j5EBiD40BEHgAenBePM2gTMF9Ph4udyF2QIsKo1mcMdm2IBxgp6RhqAq9X8ZbF8eX15sQHM'
      '5YBkitiD3wCAKItFBq4418v564t9mq0BKaYgBHQHQGBvQuQsgEsG4BsmuKEBovhnrekDqP8e'
      '/N8hAJVau/v8Ondred2sl98OEMrCnxAwXy3dWkGABC+/CVAWG63ezWWnc41Qt9677fUaCp4B'
      'Krirrcv7+/u7206n2Wi61Wh3Lu/g5ZuegiMAAUPo3d/fGuqgVb+8gxfv7m9qmDYRKPk3iaRL'
      'y/7tpY+sq3f3NV8XFB7k/dtcQq13a4wQtIEWvALH6LLhb5/jQQLTRxOEGoyxYWQ9VjbdWX/t'
      'tWpiBdOoy4PTMq5XCtNQrsFM6vVub9Yk0+4NzJ9eq9lQRGwOySzsluaCur1CpVwRREVRao2N'
      '4C/w9YNyWRACG4FGPz9093ar0A3llNFQzr9Hw33nABRH197Dfo1ft9xhT5x9B0KtQm9fS0jQ'
      '7MHb+opAf7K9WFGglYM29pVzlk04Xw2haeVQDJjQrOPFkPUw8TR7EPsyR7OfUS/onJJs5RD3'
      'z3P2u/8PFZc3xZ+VyzQAAAAASUVORK5CYII=',
  11:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////+/f3+9/r+9Pz+'
      '8vz98ff98Pb+7/b87/b87/T87/P77/T+7vb87vT87vP87vL77vP/7fX87fT87fL87PL77PL8'
      '7fH87e796vP76/H66vD96fH76ez85u/65u765O355e364+755Oj64uv54uv54uX54ev64er5'
      '4er44er54ef54Or54On44On34On43+f33Mfz1d/xztvwy9rvytn22Kr31pfz0JvzzYrvydnv'
      'ydbvyb/vyNXux9Xux9TuxtTuxcftwqLvxoLtwX3svHXrumrquG3quWfquGfquGbquGTqtmnp'
      'tmPqtl/ptF3osmjnsFzlq1rkqFbkplLjpVLcpVrjpFHjpFDjpE7jo0/jo07iok7iokzioUrh'
      'n0bGhDv/6h/kAAAH/klEQVR42rWafUO6yhLHSaDUW3jUpHzEAruc1ONTD2ba7wgoaUSC3gwT'
      'fP/v4g5ohqWIpd8/wmCZz87s7qA7IMhcex48zpzl2d+JZk/3PXvId+2hyXgwTrG/Fh0PBlO4'
      '56t9PI4mC/k8uwXl2TyFxQ8WvNgjMGo71meMfB4L2ZzwHGDbNG/pMniKz/t/im3bPKgQj3/4'
      'EMPyDLsLQnI6Dj50B/23RuIgYQUoTu0IwLKHZpD+49KBXC6bZRkQy2bhsysXDlPgAJPMuzDO'
      'UulkLBq2FI0mUxRQXHQq6UE88XUNs7mLdOyY8Pl8fsKS3+/zEeFYismu8yMf/Ashg/k15qlk'
      '2O8jvgkgMWqNG/lkGknHHQFZKkYssT5j+KMp1tkLGmGc5lCOcTA/jVaUciT8jZw5dT/lbH6K'
      'iDk6gazuf5aJ+gkX8oUph5FAHKIfdmUfnCBS2c0BuZRL85YTseymgI3sOxGQrdh3ICArps+G'
      '9lcTkOXju7F9ICRzrgFMmPiB/EuX3DJANur/CYAIM+4APxgAh2FYAqCJn8q/ZMF9B+Ri/h8D'
      'jl148KMZNCcks+sB0V8AiPDFWgBF/EbfRwH5NgKOT4AAyBEQWQe4cFhjYZL0guCwwWr7Asim'
      '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'
      's1jQ1vv/A7Oht5Csae3rAAAAAElFTkSuQmCC',
  12:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////++/3+9vv98vz9'
      '8fn+7/f87/b87/T87/P77/T+7vb87vT87vP87vL77vP/7fX87fL87fH87PL87fD77PH+6vP7'
      '6vD66vD76uv85+/65u765Oz55Ob64uv54uv54uf54ev54er44er44eP54Or54On44On44OX3'
      '3eH01tbwzt3yzczvydbvyNXux9TvwZ7yw2zwwWvvwGruv2nru2brs5PmrVjnq1HjqFHjp1Dj'
      'qU/jp0/jqE7yoIjxnonynoTwn33jpk/ipk/ipk3ipUrgpE7fo0zhoUPxmX/vknbuj3PUkFvr'
      'hWbqgGDpe17pelzmfFDpd1noclTncVPncFLnb1HnblDnbVLnbU/na0zmbU/mbE7maEmXUDNm'
      'PSRVMB50os7lAAAHyElEQVR42rWaa3uiSBOGEfCwE11RlBWJXPEdIB6SGOMhJJpkJ7rjJGvM'
      '63Gics3+/3+x1YCACg3JmvrQA4x57q6qPtENQVgWIsOcKCjF/2aFYjpChoh9C5F8NpkViv/Z'
      'CtlkMk+Tu/o0R/GKohQPYEpREahsZMuLUJwSDqNuMhSFyjqcCEWoQ8objGSWtvTT1KHlEYG3'
      'fOAoRSx+BoE38hD9jPrrhDCvB4gTPglQLIZRkH4jg+nLsiQVRbBiUYLrQC58yYMDIq8EEC8K'
      'eZ7jGN0yGT4vACVApXiSILN+P5TkE4FLx6PRaCyuWywWjcYZLi9Kkm9b/Z1IJRUfeYFnYtH4'
      'ngGEE3zcUHiByGexAEng4i7qJiOWyRfxXhQI7Pgpixh5I1oZAUv4H4EbP6U8Xt5AcFgnCO/6'
      'SyIXiwewKCNgMkFgos8E0gcn4rz0foCcDyivO8FJ7wW8Sx9HIA6ijyEQHs3nnfreBMI9v+/W'
      'BwIvBwaITPwDFnPtcm4AKRP7CCDOiMEAuAQkkL0rDS6Agrt0ik2ljiLIUnDpSonlpQAA2WWA'
      'SLCpCAXG5JChq3CC3U9ULB3AA5cWxKTCFJUr11r1ZhvZVatWPQ5TNJPaI+yPGYRvhhmWpo6r'
      '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'
      'Gg+XdNT+X75N/nAnGDp3AAAAAElFTkSuQmCC',
  13:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX////+/f3+9fv+8fr+'
      '7/b87/b87/T87/P77/T+7vb87vT87vP87vL77vP87fL86vH86fH66ej75e/55u764+364+v6'
      '4uv54uj54ev54er44er54ej54Or54On44On43+X11+Lyzt/xzd7z0s3xzYvwzIrwy9fvydfv'
      'ydbvydXvyNXuyNTux9X0xYHsvHf0wWzwvmrvvWntu2nsu2nrumntu2jtumjsumjrumjsumfh'
      's6vquGrquGfpt2brt2Tosl/lqlzlqlbmqlXkp1fjpVHjpFHkpVDjpFDjo1DkpU/jo0/io0/i'
      'oUvioEvgn0fSkkbFgja3iE3AfDi7djC7dS+ueT+5ciu2byS2biOlbjacaTR5Ty9fOSNWMB5P'
      'KhtMJxlVsAweAAAGDklEQVR42rWae3uaSBTGEaIuYgeiOBsqNzU1Vm1IZbva1Hi3dNVovcT4'
      'pIn5/t9iB1SMqFyMvn/kyXnwvL85c2BQBgwz5cPP6I+syL1PkKP9uA/blg+PMCTDcu8WZEgy'
      'SuBW/zMGj4iiyB1BIidGCOZsowofRbDHcV8yRJEIvSnCd0Yc095QnKRNgo8mjm2vV8EwKwJD'
      'iJA7BSGy6EMAP8H4DQIRNSaIYU8E4DhSn6S/XBYgCDzPQSSO49H/rkogUQm+GCO6MOfYKEPT'
      'wBBNM1EWUVwMKoJjOOP0QV64YBlABQKBIGUoGAwEKEBHIc87lvABA6ToYI/cgwFqSwhCsw5l'
      'iAyLRe1niGdpaof7khGko5x9FRCzXT+FGLPffjFbqAo7wEfMbv3kI/b2CwRjWwS2f/w8pIOU'
      'CwUAa9MJzGb2gSt/VAQV4b0DhKhLe6MIhvcK8ORvR8CO4m9D2A3gvfrvJ2C7++vZXycIrgEQ'
      'UAcouPOS2wXg6eAhAApAd4ADGrCcJJp3BYDUoQpGeRcA4cAJ0gHARQUHnUEmYftcxY7V4WWf'
      'LxwBLPUebXfBChCYwLsAwAlwAaj3lWC92rC910DYm/YtGJj1HF3MEAAhvycFAAjvbDO2a4ZA'
      'iMDBuSfRBO43csMxW0BMHwYgQOpTtVnzoGbtOnWOA4QIRAQbgN6CcBhP3fX7rWrFg6qNfr+W'
      'Is7AVhOwrZM07L/s3TcrakH1oEKhXO/1v5z7w0HLiodZL2OAX/bb9bJa9Cj1W63dvybC1kXb'
      'CggTqV67VVbL5dJGfrlcdIrVeqt/ifpgB7gAIXDXa1fVsqJ8fUso3ygbjluxoqA/rY4mEeHN'
      'Sw2z3CuJFJog5D98qN6U3uQ3BzdFu3j48PVftdrWS7AH4J/67eo/ynD+8mdoDvJOGb7MnxTT'
      'cUc8f31SSpVW744K2AE4oM9QpaQ8vD4/mwQ9/+V57bgrfp7/UUrfW100RzE7QOi82WuVi6Wb'
      'p7lJMPJf5qbjznj+5+5rWa1rvRTuAKgZgG+KSVjmP60c98R3N/p55AQQwAKA8laEVb6ydNwX'
      'I/8FgIhzLgAmYWDmLx33xkVXAHoFWBGeVvmL+HVvXHQHiJzXOq1KcU14eVnlO8W6GghASk6A'
      'X1X1DWGd7xQXi5V2u5cK2QJYBOjWCkWT8Pq6zneK1Wqn1UvZLtdx+Het81OrLNfS0reb4YOZ'
      '7xw3dUDErgfxCwn1oFNfLdalkqIU3qxqtnGh1tHaTgBWbnbaWqemquYybF2298WFakfTWn1H'
      'wP1/mqZ16uWCp1uOWiii8RsAy6MJCyAiD3SA1kG35O/ub5jFcrXZRWndxuDWHsDKo/uWTtC6'
      'WqvuWo12t2NkNcaOgPHvRtf4rNZxraW7XsAs5VjB42BF8Kruz/vxzKECKI0ex4OG1m55l9a4'
      'H02n9hVwcaY5m0wHWu/eu34OJtPpSIJ2pyknMbcI8Dj6cf3Dq64Hj9PJrMZItt9N9SZMJ9Px'
      'l0uv+nT5+3Ey2WrB1g+QOCphPJ2ODxAaFypAdPqNJqIujCe/D9BkPBtJbNwJILDSYDYZHKDR'
      'bJRi4s4/xEWWuZ7O0Hx603Q2a0rb/jsAUE4mbmtDxPCg2XQ0uE0k5AvoBIBiMpvPJRNXtx6V'
      'SyRy+Vxagk4VJPOZTCabyyQTnpRM53IocZtgBYjpbMZQNudNn5dpTgAopfNLxAHKf5YdpwiK'
      'cjp3CCObz18lJOjigVRMkBPJK9Rq15Qsam8mnZBFCF0+FIyhOhAlncnl8vmc0b6dvugosr5C'
      '3rLExWJenvxCyEJOkCRZlpPJZBrpKrsWGi8SOoAOS5Kojwh6fji+wMRYlAvR1qEgSmvJkqBv'
      'fC4P21pg7ndZN+Q6DTvFHuBmBacliE6bRO+UwGI0eUKAyLIYcVIASaOtxtPtlaLHQ2i3FBAn'
      'A6CNQLSjjNOnmyHCr28o03j8RP40u9jSj5ymz+jbw3JTH2dOcS2IkPSvXkvAyeMTkP+H9YsV'
      'OH123BcrRJGm/RuvhoRIUjgWA63kDAGsb7fgJEsyx7m6IiQDiB0v6OABGh7n5CHfjP5/N5OW'
      'Kq133acAAAAASUVORK5CYII=',
  14:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7+//7//v7+'
      '/v3+/P7+/Pz+++T++Pv+9fr79+3/99X+8vj+7/f87/T87/P48vT/9NP58O3/9NH/89H/89D+'
      '8tD+8c//8cT/8bX+7vb87vX87vP77vP87un/7fX87fL87PL77PH96vT76/D66+/86fH85+/6'
      '5+765Oz967v96K795qv85av85Kr45Ov54uvs59774ev64ev64er54ev54er24ejt4dn64Or5'
      '4Or54On53+n44On43+Tt4ODk4Nzi4Nzi4Nvi39vh4Nvl3tbx1L7nwZneq4rTmGvMjVPLi1TJ'
      'i0zbiGbJikzJikvIiEjHhUTGg0PRd1LEVEXAPS/BOyzAOizAOCq9NSevNSm9MCKqMCS8LB+i'
      'LSKfJRqrkj3qAAAG+UlEQVR42rWaC1PaShTH18tjEhsT9Po2LSGkeYjVIAotGAXx8nC0FXlL'
      '0e//Le7ZTUQeySYgnJl2ZAj/357/nj3JsiBkRwihCMOpZ4aV/VyYZoJnI2g2oqyWjCeN7KfD'
      'VONxnWOm9TmV1SzLyi4hrKxlcMmN6MTwRdZYjrrDsCw2OZYEc8QtU95mxJPcu35Y5ZYtjwma'
      '+p4D6JvLB2SvVC1C6pNnVzB+ksOGjss/qhorAmSzGyykEDSBQiGfN0lk8/B3oBQOdZhhU7MC'
      'iGcNQ1MUiYSiaLoBlACD0hjEJv0uzBcuDTUh8jwviCQEgedFSdHNfN63Vr8iKW75yBuaJPDi'
      'TABEMXzSsDQD6UkqIG8ooou6wxAUPUvPwkTU/lkwVW952y3IgkpAtP6Z1+nyNkKlJoG8x583'
      'FUEMELxkUGYCUdyXAulDEqKenx9Q0APKkyTU/LyAufRpBLQUfQoBeZTPnPreBOQ+v3PrA0Er'
      'BAaYkrhACK5Lzg2QV4RFAKJkBgMsMAGOSUo+EMAUFw3BZcHNAgoLGoQBiQAZLFRBI4KW9wco'
      'nwCI0qUvwBA/E7OzMA0oqPzco1a+yyOA7Ae4nHuNyVwoxMqeqw19dopl9rpW/4+RvRoGmq5R'
      'fj5rZLbSHry91RjdQSQuqYBLeU5rJLY1aL68veQQ694v0KJtzrFm4/rv68vr61ut2qwQn3i9'
      'QAEEn4KRNV9bb68Q/cGwFlHIfYEGKGh8wIIcWSM8YsBLpz1okgyEqY6H5ljGYwWZOLSteW21'
      'ev2/f196vU6vpfDS7CTMARgVpKTIfCRiWzPogzaO/nBYIXQq4DIRwHWFi0TOqo8t25put9vp'
      '9YeDdrOWIxmIk0sN0YvIxXWdva42W4NhH1sDQ+8Nhr3WY/X0YJ2TXNYyHTDmusQ5BfnYbA+H'
      '/U672+m0O/3BoN2qV1MHB6nT66O5AR9tQFZkznF9OOi12+BLpwvGtJq1U6L+I3XybW7ARxsQ'
      '2QhzXbVdb3ewOhjTbz3WTkH85PQklTo5WQDw7vpZSPpZA2OI6z1iOzHmBNR//DjB4qnU8f63'
      'I9EXMFGmI9drtVYPG9MF8XbXrpiRMVj9eH9ve/NfBxB0HUiyAhnYtY7VP4xpOsYQ9dTx8f7O'
      '5ub29s5OEMD7/Qx2qjwT4a+bThvoOuq4HlO2MY4vu5tEfRv+2QBBpnXTgm4DYCnplTp0AacN'
      'dBxjxtWJL4749geAV4J002tYqCDZ65I28GHMARjjJj4OoLZr0iskXm/BUuoS27ug3iULFYaO'
      '1bHpxJedcfUxi4w89Z6MZ1lmmgNiexcv1Ka9ULF6ynXokwCJfsskk6BEasM27mATxtDEPwDT'
      'UzDz2IKXmhypDvtOB8NDPx0rxm3PsAF+jy3gEXzPwf58N+YUqn2iGP0ACb9HR1JH/HdsTIoM'
      'ne7LNGB2HzX78CsL4tEWGXpw8RFgdpOD3PY3AEh5FCMVIAmq/+M7qVRpN9jQd3Z2dnd39yDg'
      'f8jAZZeGXPew0qbnyMc1cY5fRvHtSHDZybptAlUeAIE09/f3KpVKtVqt1ev1CqsE3SdLwnYw'
      'zfv7+6dG4xlH47nCmgF3mQVT+BJE87nx9PT058GJRiV5ZQYCXBl8dC+Q5sPD799/nHho/GTO'
      'roIACmIEsfUgmhMBABTmzIIv4Bf+Un79vvHHX3MWgBjjFx1g5mIoFALA04OH0G9CfJgNDAgh'
      'NpehAqybKP5CHgPcZR6e7HgejwaOZ5wB+ic9RZgEnN8UIzag4SVzT6Jew1Gvkqj8JBFDa+Bu'
      'ukgDWMU726K6p8zWemydXY8ij4gWS5MpTAPKRQYGEgUVmgx8aR8Kh8OhqB1hEmvwwXC6TAVk'
      'bu7KxRhVJkRizR3LpMvFIm2SM7liqVxOYwSWWkNzBZMGA+6ok4wJd0WMsN0JRFgjV4VjWP62'
      '6FOm2Uz2Bq4ql4vpGBNyBDwzGb0RxerlYun2ZlrfpVWc5wBRIox0LBYN+4w/GottYXUYPZbP'
      'BGh2GYwABswGfKyY3tqKYVB4HAUvGVDeShPt8m0JhuQm73E/uDi/yN3YkNuyHUWI9Efgl/Yb'
      'cE0JxG9y2fOM6xezHmeAGbicQIolErfld5Qt6yiX4AIQz2Xc1QnA+5QRPnVh5QCDOSOUI4uF'
      'sbSV9RbHSxfpKv0U6iJzfp7JZOAANzcW8CqbIe/4HKQZSIkHPWi8yIziIuhppmEgLr6yk0x8'
      'UPcdRYzVnZVmC0k4LZW5lQGspAGLh0muziGWw7cvZWUH1kmDtLOItpp5tgw47CUERtWuVqBv'
      'bvDvrYs9VK3l6x9+RaHRvUjdWO4PKywr+fGzCtJ+kxvxwrIY0FaSXGL61y3soRHXlrO6tHgy'
      'wbncqBheNZdSPGp8bPT/A/TLT6EFYX9bAAAAAElFTkSuQmCC',
  15:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX//////v7+/P3++f3/'
      '9f789fj98fj+7/b87/T87/P48e7+7vf97vP87vP77vP77vL/7fX87fL77fH77PD+6vT76vD8'
      '5vD66ez65O3w6Ob64+z54uv44+v54uf64ev54ev54er44er34eX64Or54Or54On44Onu4OH4'
      '3+jw3OHz0t7p1Mzwy9fvydbvyNbvyM3myczvxZzvxHjuv3LruG/ptGXdvarjsW7jrGfmqlfn'
      'qlblqVbkqFbnqVTmqFTlqFTlp1PkplHjpVHkpFDjpFHjpFDjpE/ipFDjo0/io1Dio0/io07i'
      'ok7iok3ioUzhoU3gn0rTnmrTlVHVk0DOizzJhDTAiFXCgDq/ejC9dSm2cy+rbC9kQC1bNSJa'
      'NCBULBcluRvzAAAJnUlEQVR42rVaa1fi2BINEBBwGA2Q8EhPN7cvBASleyliAxITJAoxvCYk'
      'BNqx//+/mKoTWpQ8xDVSqz8g9Nr7nKrau5KcUJQdAYoKhg/YT3mh8N+CLzAH4SDljFCYSx+n'
      '84X/HDx3nOYioW38CEdzFUEofEAIBSEbSR+82kXwDzr/MehrDkGg0+EX6TmIfCS8zZHeMATZ'
      'yEfDQ1Q49jcD4POFfTBwQdKfUXoP6ydZOsyQ9ueyeyIoFA4xSbtuoFQqFgs8RKFQhM+7boEK'
      '8pywA3ghn2VZliEBH7JZYNlhUVyICqff+o/F0pcsyySi0WgsQSIWi0YTDJvli2/tQzj+k2KO'
      'hTfg8ywTiyYcASRs9o1tCFyWyqZ9CYpZNuGCvuaIsZAqf2eifP2zxPvA29mCXfgR/I/K+i2f'
      '84dfU/hugvJef5FnY4kdIspkfSpB+WSf2QkfNpHgiu8nKGV3hCebYIvvJXDFT6ZSqfcyULvj'
      'HzF0KERHmfcxUB75d+IzCbrWvGpGI8l3MVC74h8l6NnSMJZmxpOhtDMB75KGFODL7bZomJlo'
      'yrUWMVfJuREUXfqfDX1fSvJQ67WWTTriXguG343ALUEpumZNpXutc3E5N0MetXAtgwsBn3DF'
      '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'
      'AABJRU5ErkJggg==',
  16:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////78/vv0/vLy'
      '/fTw/uf0+vHx+e7w+evx9+zw9+zw9+vw9+rs+uTs9+bw9unv9ens9ebs8+Pm9N7l8t3k8tvk'
      '8dvj89zj8dvj8drj8dni9d7i8dri8dnq8N7i8Nng79fn58Xz3KLR5sTL6MPL473K5L3L4rzK'
      '4rvL3bX02aD015/0157y153z1Zzy1pzy1Jvy05ry0prx0pni2bzvz5fNzI7vyJHdwnDms3/c'
      'qm/goGvUnWDdmVjRnmbNklfNjlHKjU/KjE7KjE3Ki0zJi03JikvIiUrJiEnHh0jJhkbHhkfH'
      'hkXGhkbIhUXMgETcXz3bTzXZSTDbRzDZRzDZRy/aRi/ZRi/YRi/ZRC7ZQi3YQCvSQizYPSnG'
      'Oya4Mx+JD9YyAAAH/0lEQVR42rWaaUPaTBDHUwlEhJibFlsIBvGIllOahqrcAaykCFIKlD7f'
      '/1s8s4lHyEVs8f9Gkw3z25nd2ewRDDP1DsN2QgQrcGLy3yQkyHhoB3NqJ8KSYZJP/rMEkiQ5'
      'ImS3T5AhLiOKya1I5MLk7poXO/thflvWDYIohkmLEzvhcHKL5k2RZMRS/62bTyYz5LMPTFgU'
      'km9B4HaM/hkNJd9GYpg1uv8+J74R4UMYNUMsFMj+QQqUMGT8G8yFNDjAB3AA7PEcyzB0HIlh'
      'WI7/EITxiQthEVLcaP0Dx9CxKChmyPiPZjhhI0MM0xi9oYumUjxLR6N7Mbui0TjDbUCIHIdx'
      'vh4cpDgmFo15KBpluAN/hIAJvA8gxTN7nuafEP4EjPMLDwe1j1PxuLt1aG8KEGzSD4F51z8l'
      'MFGKpvYIgqBomrIZp59LojTvQ8B8qg8mcBxn0ywbwXHCiqBoawlFsanXA1IcReDspVqrg27U'
      'yzSO00+hou0lPgTM034UT3+p67o+6Pf78KehHuJ7hhMU5SwhPAmYl30Crzb0frfVane0ntZt'
      'aXpfpXEa7Jslra6m9brtVrvdM0q8CJiH/QhbQ0a63cHwe7PRaA6GPU2vH+IUhUp6vce7d9+1'
      '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'
      'RJ7dDb0Y/x+W1ZLxwqr4oQAAAABJRU5ErkJggg==',
  17:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////73/vX1+/Px'
      '+u3x9+zw9+zw9+vw9+rr+uTq9+Xw9unu9Obq9ePo8+Dl9N7l8t3k8tvk8dvj893j8dvj8drj'
      '8dni8dri8dnk8Nni8Nnh8Njk7dXb7NDS6cfL6cXL6MPL6MLO5cHN477L477L473L47zK47zk'
      '4cXL4rzJ4rvf2bfKzJ7xxYPxxIHww4Hvwn7lworls2/ZtoHaqGbVn13UnFXTm1TTm1PSnFDS'
      'm1DSm0/TmlPTmlLTmlHPmlbSmVHUl1fSlkzRl1DQk0rIjUrIi0fIi0bIi0XIikbIikXJi0TH'
      'i0LjiHzpg4vpgovpgYzmfofXiGTIiETIhkDIhj/GiD7OgVHccnjabXTZa3XZa3TYa3TZanXZ'
      'aXbXaXOCWbWJAAAGP0lEQVR42t2afVfiOBTGa1uEQt+ClikBdEbHoQK6MpTC7MjaA4gDuigi'
      'I6ij3/9b7E1bebNAgfLPPkeP3JI8v9wmTY5NKMrWFvzQrIAkrKwnFOVCzBb1UTQjcBwnK2sL'
      'gY3I0tP+LMeKCYwVX4QllgtNZLEVYmW/3C0Cxiw3lgQdYhUf7W1xHDNsf5j13V5REsIwB4HF'
      'SNkEQdiyxmeAVTYjzArW8A9LeEOEXasbgkzCS+GYCopasj56SoETIQFZWJwA+MmiwPOREBHP'
      'C6K864XxSaQphsML3XdFIRIMgIKWrE8RXkQLGZgLUZEFAFWVhUggsB2cViAQ4qUFCCzIlDgX'
      'EFMlPhgIzlAgwIux+QhEIXkOAFq/PdPeQUjzCZQ07/aIwbn2NkJQ5iGo2e1XEb/Q3kJE5DkE'
      'ara/FPHkD4SgoC4PUEWP9hZiNoHyw38egfLFfw6B8sd/NoFy79+l/WcSXAHRkLtH6F3uBNdH'
      'zg2gTo3/UMTWNuto27kQmeJHvQHGO8D2ZRiaZlgmIvKWRJ6xrjA2aZQCr3oCoFHDQyxDg6+m'
      '5fKFQkEvOtIhyOezWpKHr9ngEBIQVQ8A+waB+zZDs3EtB77Vap2oatYsmbW6HRt6IZ9NBiEV'
      'mxGIeMjAGkHEneG1vG5UiW+5ZBilUql87qgMAVwpmwRc0fNZ0WK4jiTKJYFIhKXBvUi8S+Bz'
      'XpklIJcqQCkWCAMQocUZyMQ+Sdxr0MhJu3LFLYZ8zHrdKGgE8aEXqA9DiGGS+Uq9Bm2r1Sb9'
      'ZsfnhFElCB7PB8Tjln3FgNtS03Vz3HB+XDZqMLo0WkrMA8RROGuAPZQ3Tf2vk+9DBy/xyYle'
      'z4tSfDYgLiULddOw0je+n5yNDDzHdV0Lx2cB4juaXjesMVMrnp1CeePdwHNsVI3sRA7UuH+y'
      'WDWcdE/Pzk510xym7zkumdXseA4jQAzFdcv/3Er39KzoDJIl45JpaGM5UGMdkK8T/4qp2+nW'
      'nGG/bFyq6kiJfQDEdjTT7q73dJ3HaMkYZNTHumEIiIfz9ZJd4WSU/vKxnYILQNnRq/bMYH4f'
      'pbtKXDn/x9B2YlOAGAwh05nVzJo5MessG1fK1dE9cgOcT02fy8YLAWvr/wmA56xgP2frq2QW'
      'kx9GEQC0arVcOV9bMErrObfnIC5l9Z8//v65rn78LOYk99mUy/7ri9rusykQ2p07P3Sr7bgC'
      'ULJ9e9vu9PuDQb/faUOwWtTuuE/XBNBp95/eXp6eXt5e+qTWShEAdlwBsCB0Om9Pjt6gZH+l'
      'qNMejtHJFU1K3Xf6z+8Fn146t4OnVaK7+6zgvqLpv++fXtYFPL/e/74cPWfjD1q217i5f3VS'
      'eP7Tv7vrrxC9Dm4avULYbUUr9Bq/moPXV1Luz+vLI2iFaPB43Xi4UHZdVrRir9G6bj0OnqHs'
      '4LF5A1opaja7l24rWuqy22y1WjetBjSoeXPdBK0UtVpXPbfp2gE0W9ekQeTjypEbQEH44uG9'
      'rPN39ehKkz5O12Ed+sAXNR8u3NaDcM4vgPswhYF14Q+h2epqMxach64PhGajlwu7T3Zwk7qN'
      'q/XsrxqtXmE/hVwXHLyXu+w9dK/WUKvb6xY+p48SyBVw+CVTuGj0HlZWr3mp5/aPjtIpVwBK'
      'Haf3jzK5dXS8/+U4k9lzv0UKSuwdZ75+XkNfvmYy6YOxLpj6NxYB4iADOl5JpObhXmoXzflP'
      'H8lKKrV3cARF09+OQF+d35myvvyWhgpHYJ7CMlr4vkhGaoJQDg/TpB5RGjTpm7bkfHl4eADe'
      'KYxk5PG1JoKiUQwYAtrbOyB6h9kiV8DWMk4lMGkWWurNL5msdoEjQ0XY/IA3TqIsypZEIrJB'
      'gREiJRCKOhWWenc9BoLNG9hhgW0K+50g2ZoQJDRWQFnl5fj0RgjZ7LAziEZVjFWPFb0CRhhV'
      'XaoKtYk9wAlAdLMEvGCTaP2dZSq8SQCWoh426tYBcGHYapTwBgGwW8qzeHP+Mmz30tzmEmBZ'
      'smHNs/FNJSBaRxO2BC6xCf+ELNCURaA5YQOEBOLY92MJDCf43tEYcUFqeHiD5ljsKwLjsWMV'
      'Vj9EOA77dvIEJzg2PH26hQ7JnOiL/ycJjs/AAZ3JIzrkgWDDfsysWBZC9Mj8P/gHB50Z3IZF'
      'AAAAAElFTkSuQmCC',
  18:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////78/vvz/vLy'
      '+vPx+e/x9+zw9+zw9+vw9+rs+uXn9+Pw9ujt9eft9OXm9N/k8tzl8dvj89zj8tzj8dvj8drj'
      '8dnj8dji8tvt8N7j8Nji8Nno7tDh79jh6tHu5bfW6crL58L12qH015/z1p3z1Zz02X7i2r3t'
      '2KLL4rzM37nt1Krz1Jvy1Jvy1Jry05rx05rx0prPzKPx0pnvz5b1zk/2ykn2yUb2yUX3y0P2'
      'yEb2xz7dyXTkuYH0wkbWu5LmpnLUnWDQpG/dlnLMkVbMj1HMj1DLkVTSjl3Ki03Ji0zJikzJ'
      'ikvHikjohInog4nqgo3ogorogondhXXnf4zofIrJiUnIiUrIiEfHh0jGh0nJhkbIhkXHhkfH'
      'hkXHgkHz6FXZAAAGGUlEQVR42rXaeVfaShgHYGogko0JhcRzE4OAC8XW4lVRKoebQt1ACsIt'
      'Ym8Rvv+3uJMJ2SY7y+8vj+j7ZCa8k8AkkdDzIZHYIVJMlpeF9cJnaYrYSbizQzA0TfPC2uFh'
      'HZAi8PophgCKLAsbiQwImnKMYoci+E1VR4IsE3TSXp8SNlheD20JOzSx8fKCoDCmkCFkXtiG'
      'wOyg9ydJCNuJTGfQ258B8paEPJqkNKFE+WNRSxYF/RhtCAAOgGfkCNUFHmQ4jqW0cFwG8PlI'
      'BkgmkrQcWj0PMmyahEmjoJ9YDvChhkxTCSoEEEU+w5LkbhoPSVIZEELIDEiAQEAUAZcm0z4h'
      'SS6M4BN80PoJj37Xt7xJBAqJoBYTgXX0lE9IMgOXGdGMC5ADDp+zHX3KP7vgo5U8DgQcPmWr'
      'z/4VFKlgRspHAeBIRWCffCqlvt0F5NFIt8JI4YCYyznrp6l0srXoz9/C8rqIAuwxBydcik07'
      'BaKzuHu4D063N4sA7OX2682TDCawqUz7++FVYP5u/44AiAI4aV4362zSQyifHfvny2EkYE+r'
      '34DCvqdwWTvzSy0CAF+UIHDTgMK1t7AWIAFISC/fvzWQcOASuLt2eXVABAUVSECd/ILCbeOm'
      '0YQC5RCI/f/8hXDgY+G1w1Qmo6EplJNUdCEKcLdQXyZDKPy4/QaFm+ZJMo0LUz8hCvDYnz0N'
      'X8ZQGJjCLhtRiAS8dn8+jaEw+DX4BwrwVOMtpwmd8urA81IYmgLechxRWUChtirQf3YJWEOw'
      'xOdF5/C4tirgFq49hPblUc0D+FMB4SMwhRF8u956tZy3EHEEvWkfF9wt5yksATkYmD62fmvC'
      '/b9QGGkCrO9uOZZQXYIO0EoI8HDcmmtCFwlGU7tajk26BB3YDQWuyq13b8HecvASh4RzHEiF'
      'A2eYgJYNV8sthcNzDEhKocDxJSYMbr1aTheuDmvxgbNzXPBsOYoiWovHq/KlAyCyYjjgKzhb'
      'Dl7iOot7U4gDGML0Jy4c+AuxAEPoG8LQs+UcQjxgKfQNwWpqR8vZhZiAlwDvBfCW0241Fg9I'
      'iAtggr5suFuOTe7fz5EQ423qLSybGm85lihAoVU+jw/YhZEueLUcEvqt8mXUpcICDAEu30vB'
      'bOp9TJj9bpWP4gO4MDCFa1yYQiHacu0APMbg1XLajcDze6v9Di84MQE/AWs57RLXf37oR7ii'
      '4YBDGDsEe8shoQ8/4QApLuAWlsuGs+WQ0Au/6HsANmHsWDacLQeFeXc1wFNoNPCW024E3lYD'
      'DGF5W2lvanvLaTcCKwK2MQxHmGA1BEWmOqsC5hjenrQPEPZlw9ZyLC8UcsJqgCnM2y+TsWPZ'
      'MFuOzMhCTlgVsAnqr/HQWjbMliM5r++LogM2YWCMwdlyvLgeYAmP6otDQC1HMuKaI7CE2R38'
      'rDjABE4S1gYMoTe7+/wyGVlNrbWclJPWB2xCBRfqEpBiAF/N+M1SBc3SyFo26vsegi/wyYzf'
      'eXhcClZTXx8wUmTgs5mjrz6z1LtQXQLYW3eKbMLrXFUn+lXuh9Fyn5g9ca2T7BD6M00YWssG'
      'EvLi2oBNuLiYLO82zIYIH8GXWmjgZ6D51BDGjruNupQTg4HLwwg5Krf6yzGcDqymvmnWi87z'
      '7AL63XbEPEyR8Ee1Cc36aUnhQ75KeI8WbYq0a1xv0akiYTCafK9XS9VCMNDrdSOmt0x30SkN'
      'JqPJZKBeVEunRT7oJHcXs9lsPv8TK29QUEfqxWmpVK1i9Z0bFDmlgnIRO6clVL1UVPANj0TW'
      '8RvAoHxUiqVYqVZR9SyP70/ICeC4WZX0iFlBVgpF/R9PqwHRXywVi4rM87yAX9NkPsH57ULx'
      '2j8okCkWS8WSV3F45PDFQkER0d967lxnQzbq8rweKEHLFkVW9Low2YCNOg5uNYbtlaJh5y3M'
      'KJo3XwwA4G4pR2xrM1bbLNW2e2lhawCR0jastzYEfQDajjWtbKO+wsMtd12gGWUb9emU8VhC'
      'kmY2PksyT6f149cFWt4oIcu0dfz6LGnEpp48kRWaoPGnWwiKp8FmAACPNvXBmh/z8R9yEw/n'
      'wMlnKMIq/j+PJcu9zEqGgQAAAABJRU5ErkJggg==',
  19:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7//v3//vz/'
      '/fz+/v38/fz7+vfz/PLx+vPw+O/59/Lx9+3x9+zx9+vw9+zw9+v3/N/w9+rt+uTt9+f29PLw'
      '9unu9ujz9N3s9eXp9OHm893m8t3k8dvj89rj8tvj8trj8dvj8drj8dni8dri8dnx7ejj7Nvn'
      '5+Hl5d/k4t3k4d3j4d3j4dzk4Nzj4N3j4Nzj4Nvi4Nvl79ji8Nni79nh79j75qf745rw58nj'
      '39zj3tzi39vh3trt3LH32Ijxz4HyzG7wxmbxxV3wxFzwxFvww13ww1rvw1rww1nvwl/wwljw'
      'wVbuwFrwv1DpuVnhqk3eoDvbmjTamDHalzDZlzDZly/Zli/Zli7Zli3ZlS3YlCvYkyrXkijX'
      'kSXWjh/74mYKAAAIZUlEQVR42rWai3aiyBaGSxPvMXGgg4p6htjjJXacIb3QiCdeQGmPR4eI'
      'tJcBxfd/i9mFJkHDxaTNv7rXElr/r/bexS67SoS28iEUCEXpXIbL/5pyOZIIB9FbBcM0SZKZ'
      '/C8rBzZ0OHToHyXDdJ3j8idRLXNJEntRBL+EM7UTuWNxHBcmLUGEiMv8Ce23Isnwy/jTl7X8'
      'yVWnX2IA/1z+Mwg0rkMAxcP5zxFH0mAPCcpwn0S4McuQCNePefPXAihnynx5bAgokKW9AwC/'
      'LE2n0xSBlUym6ezNMYw/6BAKk5yn+00mnUzEQQlT5isqTec8GRyZREkPQKGQpal4/CpxqHic'
      'SGc8EBydQbQr4Gshk07EEw6Kx7/QX90ROeTaPwvZ9JWj/RaRzLgTkFv/LNAJV/stIp13QyDn'
      '8RdySU97E0FlXQjI2T9DHeUPhARdeD+gQB9pj3WRLrwX8C5/CMKRgE7i70JAp/F3JiD7+r7b'
      'H+pgX2lbQI5IfEBx20fODlBIxj8CSBC54wAfKIBLGWwAucRHFbcpw1tAIR3/KOAyeUQEH5pB'
      'LiGgEwaA6+wdQTbxK3obAjppAIl40guQJxK/FsLh04ZOWGLbZwGdNEOgpEeKku6TxJQ7IesK'
      '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'
      '/i/6RucxT6FySAAAAABJRU5ErkJggg==',
  20:
      'iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAMAAADVRocKAAABIFBMVEX///////7+/v32/fPy'
      '/fTx/PDy+e/w+O3x9+zx9+vw9+zw9+vw9+rs+uTr9+bw9urv9ens9ebu8uPn9d/m897l8t3k'
      '8tvk8dvj893j8dvj8drj8dni8dri8dnm8Nvr5cnxzYzvwXjnsWHkqVrlqVLlp1LjpVLkpVDj'
      'pFHjpFDkpE7i8Nng7dXW6srL6cTN5MDL5cDL477L473L47zg4MDL4rvL4LfcyaXXr3/K4brK'
      'yJrKx5mJxYPjo1Djo0/io1Djo03io07hoUzdnU3RlVPOkE/MikbJi03JikzJikvJiEjIiErG'
      'h0pQmEPHfTbKei7HdS/FazOceDjEWDOdXzW1RC65Oiu4Oiu4OSu5OCu2Oiu8Niq3Niu1Nyu5'
      'Mym7MSmOxK/OAAAFsUlEQVR42r2aC1eiWhTHz4gYDaIgHJws7kxTRt2j2fiorFXmKzNnrO7N'
      'NB/1/b/F3VCmIO/0/ledBe7F/8c+57BhcUDoTV8QClGRmIxJ6nOSk1yUCqFFhSiR4zic+rRk'
      'sBFpyuwf4WiREJJaiohEc+uGLEJRGi/LXScQQnNzSVBROrVE+zdxM0IoRi/dHrIQPwgCTeTU'
      'CgicqI1DCDF0ajUiXALsoYMksiLCht5JLOXJf1MBJXXpm95SkCABLLoDwA9LgiDwUU2wIeIN'
      'L4wtkUIUR1zdNySBZxkQq0vf4gVRdmUQjke8C0BRsMAzzFfWLIaJCpILgogSEh0Bm4oksAxr'
      'I4YRxE1nhIwc6yec/Vdb+3eE5ExAklP3iKyj/Tsi5YRA9uevyIKrvY7gnZJA9v5S3JM/EFhR'
      '8Q9QRI/2OkJQ/AJ8+TsR0FL8HQhoOf72BGQ9vr79bQmWgGSUDSDGcrZaARSBCQJgo0lvgAAD'
      '4NBJFgCZDSrG4oJDS+sg0DrvIQOYQVF9jIO0Fp20CBDia5F4nOUDtVH3DDAbTiTCkXiwdnEU'
      'zAAiRE4azdMEHaiNrPNugM3wSbfT6Z4Ga+k4a77akPkunWjctm5aLfj3395+D68LLgAh0ezc'
      'tNvtTrvtu23dFsNx3qWLhPBpt9X+3Wz+bvttW7eNOExX7AjA8Uji9PamWTtodjo+25vrncRa'
      '1DyPkPkq48PFev1APVD9t3u1H+G4+VpD5jIRp7dr6QOQqvpt968ghXUXwPpaYudq/yCY9mrf'
      'w3FT0f6fASme/TSAxYo9AO6VBsB+9dIGZhnRAaY7pzPgaiddtSZYRvwC9qs7P7b35n1UtVLR'
      '5sxiJFgGl+ltg49ab7bbzbq6GAkI2K/uzfuo9Q6UnE6noZojngHmaWr0qbTab4WtbkMIcB0Y'
      'fCrtGcCS4AXAmK6DeR+18Vuryp2mVf99AHinagrPXOYLzeDTaMEoNCqqDUEHONcivFgqDDlU'
      '6vWqaj1CU4BjuYZasVgq3n0u368E1SYyBWBHgCJEFmvRm0/VsmAYIhrA5ZapSBYA8Elv/7yy'
      'LknzEQ2QcL7pp5LW1fSyWrWpoPMRDeDy2KI9VnyqXNObbk92YmLv74D+B+lacY24Pdl9+6uu'
      'BvS/SNeLMXdA5rqevgzkv5++K4qb7oBut5JWL0CVyoWjjHE1rV7fn3gBXN93r2vp3d3dtNY4'
      'yBiv1rtdr4Bev/evb/X6g4c7j4Cn5/HLy8vjnz//TF60rTe9Tiavc7tz8Qn8jceDsQ9AfziC'
      '48FhNHyaSjPsPfXfdubi/afRsDd67vf9AAbDV93gz2g40DUzfN+fiz9r6OGzP8Dgeagd37My'
      '1PURn6E9AYDQ0AGD59Hj4/DDzwycxWfo8UO3+M0VQGKn9z3o0D4Mw+hpOOhPNTX8+GEan6Ef'
      'GgsJWGWQuX0Z65pMxga9vo4Nv0zjMKEeJ6+TwctD0QMAyl3xIaDOY8TDuwo5c3jc6N75Vrdx'
      'dpiVPQC2cuWjw+Oz8zN/Oj8+OizlM7KHLsrlS6WjQ986KpV+lbwA5GypkAeGb+XzZU9dBIOQ'
      'K5fyv/I+VSjnLfwt39lhks0VgOHLvZTLZrDXt44bOJXJwlCUtc5yykULFUrlcgHcFSz7ebUs'
      'AyOTzeZ+leD4kgYqGM5YM4YI5JnLZW3dHd++p2QZy4pGyeYAlMvNDXwhBz8cgnM2kyFJjB3W'
      '+ZDLGmBSxnC8rC1/ZuYEu4oMZ4DlpMs6EUq6rjLq5WVDY82k//Aecl4mQhK3qnVA3R+j2CoB'
      'REzCUvgqAZzgbakxOIDSV5NX5y/Bci/FrS4BOqItWK8sBUjgi76kL65mnAmGxV794weKW8U4'
      'E5mLfHz2sAIC+LPoy4zAkaUiCOFm56+PA6chlvXlCdjTMfPXLVQUc+JS/Le0r3AioVn/TD//'
      'odZi8nImT5Samf8HT/Oo5+EPx2MAAAAASUVORK5CYII=',
};
