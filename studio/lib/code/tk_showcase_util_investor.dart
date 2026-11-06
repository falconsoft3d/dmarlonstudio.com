part of 'tk_examples.dart';

// --------------------------------------------------- inversor de bolsa (demo)
/// Un mercado simulado con empresas inventadas: los precios se mueven cada
/// segundo, se compra y se vende con comisión y la cartera se guarda en la
/// carpeta de datos del usuario.
TkExample tkUtilInvestor(String Function(String) t) {
  const up = '#0a7a32', down = '#c62828', muted = '#5f6672';
  const card = '#ffffff';
  final app = t(markTr('Inversor de bolsa (demo)'));
  TkWidget inCard(TkWidget w, String frame) => w..parent = frame;
  TkWidget onPage(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  final cards = [
    ('CardCash', 'Cash', t(markTr('Efectivo'))),
    ('CardStocks', 'Stocks', t(markTr('Valor de las acciones'))),
    ('CardTotal', 'Total', t(markTr('Patrimonio total'))),
    ('CardGain', 'Gain', t(markTr('Ganancia / pérdida'))),
  ];
  final design =
      TkDesign(
          width: 1080,
          height: 700,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 16, 10, 520, 32, {
            ..._title(t(markTr('Inversor de bolsa'))),
            'bg': _paper,
          }),
          _w('Label', 'Note', 16, 42, 780, 20, {
            ..._label(
              t(
                markTr(
                  'Demo con datos simulados: empresas ficticias y precios aleatorios. No es una inversión real.',
                ),
              ),
            ),
            'bg': _paper,
            'fg': muted,
            'font_size': 11,
          }),
          _w(
            'Button',
            'BtnPause',
            836,
            16,
            112,
            30,
            {'text': t(markTr('Pausar'))},
            {'command': 'BtnPause_click'},
          ),
          _w(
            'Button',
            'BtnReset',
            956,
            16,
            108,
            30,
            {'text': t(markTr('Reiniciar'))},
            {'command': 'BtnReset_click'},
          ),
          for (final (i, (frame, name, caption)) in cards.indexed) ...[
            _w('Frame', frame, 16 + i * 266, 72, 250, 60, {
              'bg': card,
              'relief': 'solid',
              'bd': 1,
            }),
            inCard(
              _w('Label', '${name}Caption', 12, 6, 226, 18, {
                ..._label(caption),
                'bg': card,
                'fg': muted,
                'font_size': 10,
              }),
              frame,
            ),
            inCard(
              _w('Label', '${name}Value', 12, 24, 226, 30, {
                ..._label(''),
                'bg': card,
                'fg': '#1b1d22',
                'font_size': 17,
                'font_bold': true,
              }),
              frame,
            ),
          ],
          _w(
            'Treeview',
            'Market',
            16,
            146,
            430,
            258,
            {
              'columns': [
                'ticker|${t(markTr('Símbolo'))}|64',
                'name|${t(markTr('Empresa'))}|170',
                'price|${t(markTr('Precio'))}|86',
                'change|${t(markTr('Variación'))}|84',
              ].join('\n'),
            },
            {'select': 'Market_select'},
          ),
          _w('Chart', 'Chart1', 462, 146, 602, 258, {
            'kind': 'line',
            'decimals': 2,
            'suffix': ' €',
            'maxpoints': 90,
          }),
          _w('Label', 'LblTicker', 16, 419, 56, 24, {
            ..._label(t(markTr('Símbolo'))),
            'bg': _paper,
          }),
          _w(
            'Combobox',
            'OrderTicker',
            72,
            416,
            96,
            30,
            {'state': 'readonly'},
            {'select': 'OrderTicker_select'},
          ),
          _w('Label', 'LblQty', 180, 419, 70, 24, {
            ..._label(t(markTr('Cantidad'))),
            'bg': _paper,
          }),
          _w(
            'Entry',
            'Qty',
            250,
            416,
            72,
            30,
            {'font_size': 13, 'justify': 'right'},
            {'key_up': 'Qty_key_up'},
          ),
          _w(
            'Button',
            'BtnMax',
            330,
            416,
            56,
            30,
            {'text': t(markTr('Máx.'))},
            {'command': 'BtnMax_click'},
          ),
          _w(
            'Button',
            'BtnBuy',
            396,
            416,
            110,
            30,
            {
              'text': t(markTr('Comprar')),
              'bg': up,
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnBuy_click'},
          ),
          _w(
            'Button',
            'BtnSell',
            514,
            416,
            110,
            30,
            {
              'text': t(markTr('Vender')),
              'bg': down,
              'fg': '#ffffff',
              'font_bold': true,
            },
            {'command': 'BtnSell_click'},
          ),
          _w('Label', 'Estimate', 636, 419, 428, 24, {
            ..._label(''),
            'bg': _paper,
            'fg': muted,
          }),
          _w('PageControl', 'Pages', 16, 456, 1048, 214, {
            'pages': [t(markTr('Cartera')), t(markTr('Órdenes'))].join('\n'),
          }),
          onPage(
            _w(
              'Treeview',
              'Holdings',
              8,
              32,
              992,
              168,
              {
                'columns': [
                  'ticker|${t(markTr('Símbolo'))}|70',
                  'name|${t(markTr('Empresa'))}|190',
                  'shares|${t(markTr('Acciones'))}|80',
                  'avg|${t(markTr('Precio medio'))}|115',
                  'price|${t(markTr('Precio actual'))}|115',
                  'value|${t(markTr('Valor'))}|125',
                  'gain|${t(markTr('Ganancia / pérdida'))}|150',
                  'pct|%|85',
                ].join('\n'),
              },
              {'select': 'Holdings_select'},
            ),
            0,
          ),
          onPage(
            _w('Treeview', 'Orders', 8, 32, 992, 168, {
              'columns': [
                'when|${t(markTr('Fecha'))}|160',
                'side|${t(markTr('Operación'))}|100',
                'ticker|${t(markTr('Símbolo'))}|80',
                'shares|${t(markTr('Acciones'))}|80',
                'price|${t(markTr('Precio'))}|110',
                'fee|${t(markTr('Comisión'))}|100',
                'total|${t(markTr('Importe'))}|140',
                'result|${t(markTr('Resultado'))}|140',
              ].join('\n'),
            }),
            1,
          ),
          _w(
            'Timer',
            'Timer1',
            1040,
            60,
            32,
            32,
            {'interval': 1000, 'enabled': false},
            {'command': 'Timer1_timer'},
          ),
          _w('StatusBar', 'Status', 0, 676, 1080, 24, {
            'text': '',
            'icon': 'chart',
          }),
        ]);
  final code =
      '''import collections
import datetime
import json
import math
import os
import random
import sys
from tkinter import messagebox, ttk

APP = ${_py(app)}
START_CASH = 10000.0
FEE_RATE = 0.001  # 0,1 % del importe...
MIN_FEE = 1.0  # ...y como mínimo 1 euro.
HISTORY = 90
SAVE_FILE = "investor_portfolio.json"
UP, DOWN, FLAT = "$up", "$down", "#1b1d22"
# Empresas inventadas (cualquier parecido con una real es casualidad):
# símbolo, nombre, sector, precio inicial y volatilidad por segundo.
COMPANIES = [
    ("LUMX", "Lumexa", ${_py(t(markTr('Energía')))}, 42.0, 0.006),
    ("BRVA", "Bravia", ${_py(t(markTr('Alimentación')))}, 18.5, 0.004),
    ("NBTR", "Nubeterra", ${_py(t(markTr('Nube')))}, 126.0, 0.010),
    ("ORTG", "Ortigal", ${_py(t(markTr('Farmacia')))}, 64.0, 0.005),
    ("KPLG", "Kappalog", ${_py(t(markTr('Logística')))}, 23.8, 0.007),
    ("VLMR", "Velamar", ${_py(t(markTr('Navieras')))}, 9.4, 0.009),
    ("ZNKR", "Zincora", ${_py(t(markTr('Minería')))}, 31.2, 0.012),
    ("PXLB", "Pixolab", ${_py(t(markTr('Videojuegos')))}, 77.5, 0.014),
]
TICKERS = [c[0] for c in COMPANIES]
NAMES = dict((c[0], "%s · %s" % (c[1], c[2])) for c in COMPANIES)
AVERAGE = ${_py(t(markTr('Precio medio')))}
PAUSE = ${_py(t(markTr('Pausar')))}
RESUME = ${_py(t(markTr('Reanudar')))}
BUY = ${_py(t(markTr('Compra')))}
SELL = ${_py(t(markTr('Venta')))}
RUNNING = ${_py(t(markTr('Mercado en marcha: precios nuevos cada segundo.')))}
PAUSED = ${_py(t(markTr('Mercado en pausa.')))}
LOADED = ${_py(t(markTr('Cartera recuperada de {0}')))}
FRESH = ${_py(t(markTr('Cartera nueva con {0} de efectivo. Se guarda en {1}')))}
SAVE_ERROR = ${_py(t(markTr('No se pudo guardar la cartera: {0}')))}
BAD_QTY = ${_py(t(markTr('Escriba una cantidad entera mayor que cero.')))}
NO_CASH = ${_py(t(markTr('Efectivo insuficiente: necesita {0} y tiene {1}.')))}
NO_SHARES = ${_py(t(markTr('Solo tiene {0} acciones de {1}.')))}
BOUGHT = ${_py(t(markTr('Compra: {0} {1} a {2}, comisión {3}.')))}
SOLD = ${_py(t(markTr('Venta: {0} {1} a {2}. Resultado: {3}.')))}
ESTIMATE = ${_py(t(markTr('{0} × {1} = {2}  ·  comisión {3}  ·  tiene {4}')))}
ASK_RESET = ${_py(t(markTr('¿Reiniciar la demo? Se borran la cartera y las órdenes, y vuelve a tener 10.000 € de efectivo.')))}
RESET_DONE = ${_py(t(markTr('Demo reiniciada: 10.000 € de efectivo y precios nuevos.')))}


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
    text = "{:,.2f}".format(value).replace(",", "_").replace(".", ",").replace("_", ".")
    return text + " €"


def signed(value):
    return ("+" if value > 0.004 else "") + money(value)


def percent(value):
    return ("{:+.2f} %".format(value)).replace(".", ",")


def fee_for(amount):
    return round(max(MIN_FEE, abs(amount) * FEE_RATE), 2)


class TradeError(Exception):
    """Una orden que no se puede hacer; el texto dice por qué."""


# ------------------------------------------------------------------- cartera
class Portfolio:
    """Efectivo, posiciones (acciones y lo que costaron, con comisiones) y
    el historial de órdenes. No sabe nada de la ventana."""

    def __init__(self):
        self.cash = START_CASH
        self.positions = {}  # símbolo -> {"shares": int, "cost": float}
        self.orders = []
        self.realized = 0.0

    def shares(self, ticker):
        return self.positions.get(ticker, {}).get("shares", 0)

    def average(self, ticker):
        pos = self.positions.get(ticker)
        return pos["cost"] / pos["shares"] if pos and pos["shares"] else 0.0

    def stocks_value(self, prices):
        return sum(p["shares"] * prices[t] for t, p in self.positions.items() if t in prices)

    def total(self, prices):
        return self.cash + self.stocks_value(prices)

    def max_buy(self, price):
        """Cuántas acciones se pueden comprar con el efectivo, comisión incluida."""
        if price <= 0:
            return 0
        n = int(self.cash // price)
        while n > 0 and round(n * price, 2) + fee_for(n * price) > self.cash + 1e-9:
            n -= 1
        return n

    def _record(self, side, ticker, shares, price, fee, total, result, when):
        order = {
            "when": (when or datetime.datetime.now()).strftime("%Y-%m-%d %H:%M:%S"),
            "side": side, "ticker": ticker, "shares": shares, "price": price,
            "fee": fee, "total": total, "result": result,
        }
        self.orders.append(order)
        return order

    def buy(self, ticker, shares, price, when=None):
        if not isinstance(shares, int) or shares <= 0:
            raise TradeError(BAD_QTY)
        amount = round(shares * price, 2)
        fee = fee_for(amount)
        total = round(amount + fee, 2)
        if total > self.cash + 1e-9:
            raise TradeError(NO_CASH.format(money(total), money(self.cash)))
        self.cash = round(self.cash - total, 2)
        pos = self.positions.setdefault(ticker, {"shares": 0, "cost": 0.0})
        pos["shares"] += shares
        pos["cost"] = round(pos["cost"] + total, 2)
        return self._record("buy", ticker, shares, price, fee, -total, None, when)

    def sell(self, ticker, shares, price, when=None):
        if not isinstance(shares, int) or shares <= 0:
            raise TradeError(BAD_QTY)
        held = self.shares(ticker)
        if shares > held:
            raise TradeError(NO_SHARES.format(held, ticker))
        pos = self.positions[ticker]
        amount = round(shares * price, 2)
        fee = fee_for(amount)
        proceeds = round(amount - fee, 2)
        # Lo que costaron las acciones vendidas, a precio medio.
        cost = round(pos["cost"] * shares / held, 2)
        result = round(proceeds - cost, 2)
        pos["shares"] -= shares
        pos["cost"] = round(pos["cost"] - cost, 2)
        if pos["shares"] == 0:
            del self.positions[ticker]
        self.cash = round(self.cash + proceeds, 2)
        self.realized = round(self.realized + result, 2)
        return self._record("sell", ticker, shares, price, fee, proceeds, result, when)

    def to_dict(self):
        return {
            "cash": self.cash, "positions": self.positions,
            "orders": self.orders, "realized": self.realized,
        }

    @classmethod
    def from_dict(cls, data):
        book = cls()
        book.cash = round(float(data.get("cash", START_CASH)), 2)
        book.realized = round(float(data.get("realized", 0.0)), 2)
        for ticker, pos in dict(data.get("positions") or {}).items():
            shares = int(pos.get("shares", 0))
            if ticker in NAMES and shares > 0:
                book.positions[ticker] = {"shares": shares, "cost": round(float(pos.get("cost", 0.0)), 2)}
        book.orders = [o for o in list(data.get("orders") or []) if isinstance(o, dict) and o.get("ticker") in NAMES]
        return book


# ------------------------------------------------------------------- mercado
class Market:
    """Precios de un paseo aleatorio geométrico, con su historia reciente."""

    def __init__(self, prices=None, rng=None):
        self.rng = rng or random.Random()
        prices = prices or {}
        self.prices = {}
        self.history = {}
        now = datetime.datetime.now()
        labels = [(now - datetime.timedelta(seconds=HISTORY - i)).strftime("%H:%M:%S") for i in range(HISTORY)]
        for ticker, _, _, start, vol in COMPANIES:
            # Una historia inventada que acaba en el último precio guardado.
            path = [start]
            for _ in range(HISTORY - 1):
                path.append(path[-1] * math.exp(self.rng.gauss(0, vol)))
            last = float(prices.get(ticker) or path[-1])
            scale = last / path[-1]
            self.history[ticker] = collections.deque(
                ((x, round(p * scale, 2)) for x, p in zip(labels, path)), maxlen=HISTORY
            )
            self.prices[ticker] = round(last, 2)
        self.open = dict(self.prices)

    def step(self, label=None):
        label = label or datetime.datetime.now().strftime("%H:%M:%S")
        for ticker, _, _, _, vol in COMPANIES:
            price = self.prices[ticker] * math.exp(self.rng.gauss(0.00005, vol))
            price = round(max(0.5, price), 2)
            self.prices[ticker] = price
            self.history[ticker].append((label, price))
        return label

    def change(self, ticker):
        start = self.open.get(ticker) or self.prices[ticker]
        return (self.prices[ticker] / start - 1) * 100


def load_state(path):
    """La cartera y los últimos precios guardados (o una cartera nueva)."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        return Portfolio.from_dict(data), dict(data.get("prices") or {}), True
    except (OSError, ValueError, TypeError, AttributeError):
        return Portfolio(), {}, False


def save_state(path, book, market):
    data = book.to_dict()
    data["prices"] = market.prices
    data["saved"] = datetime.datetime.now().isoformat(timespec="seconds")
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    os.replace(tmp, path)


# ------------------------------------------------------------------- ventana
class Form1(FormDesign):
    def form_create(self):
        # Tablas claras también con el modo oscuro de macOS.
        style = ttk.Style()
        style.configure("Light.Treeview", background="#ffffff", fieldbackground="#ffffff", foreground=FLAT)
        style.configure("Light.Treeview.Heading", foreground=FLAT)
        style.map("Light.Treeview", background=[("selected", "#d6e4f7")], foreground=[("selected", FLAT)])
        for tree in (self.Market, self.Holdings, self.Orders):
            tree.configure(style="Light.Treeview")
            tree.tag_configure("up", foreground=UP)
            tree.tag_configure("down", foreground=DOWN)
        for column in ("price", "change"):
            self.Market.column(column, anchor="e")
        for column in ("shares", "avg", "price", "value", "gain", "pct"):
            self.Holdings.column(column, anchor="e")
        for column in ("shares", "price", "fee", "total", "result"):
            self.Orders.column(column, anchor="e")
        self.path = os.path.join(data_dir(), SAVE_FILE)
        self.book, prices, restored = load_state(self.path)
        self.market = Market(prices)
        self.selected = None
        self.ticks = 0
        self.save_failed = False
        self.OrderTicker.configure(values=TICKERS)
        self.Qty_var.set("10")
        for ticker in TICKERS:
            self.Market.insert("", "end", iid=ticker, values=(ticker, NAMES[ticker], "", ""))
        self.select_ticker(TICKERS[0])
        self.refresh(orders=True)
        self.start()
        if restored:
            self.Status.set(LOADED.format(self.path), icon="check")
        else:
            self.Status.set(FRESH.format(money(START_CASH), self.path), icon="info")

    # ------------------------------------------------------------- vista
    def tag(self, value):
        return ("up",) if value > 0.004 else ("down",) if value < -0.004 else ()

    def sync_rows(self, tree, rows):
        """Pone las filas (iid, valores, etiquetas) sin perder la selección."""
        wanted = [iid for iid, _, _ in rows]
        for iid in tree.get_children():
            if iid not in wanted:
                tree.delete(iid)
        for index, (iid, values, tags) in enumerate(rows):
            if tree.exists(iid):
                tree.item(iid, values=values, tags=tags)
                tree.move(iid, "", index)
            else:
                tree.insert("", index, iid=iid, values=values, tags=tags)

    def fill_market(self):
        for ticker in TICKERS:
            change = self.market.change(ticker)
            arrow = "▲ " if change > 0.004 else "▼ " if change < -0.004 else ""
            self.Market.item(
                ticker,
                values=(ticker, NAMES[ticker], money(self.market.prices[ticker]), arrow + percent(change)),
                tags=self.tag(change),
            )

    def fill_holdings(self):
        rows = []
        for ticker in TICKERS:
            shares = self.book.shares(ticker)
            if not shares:
                continue
            price = self.market.prices[ticker]
            cost = self.book.positions[ticker]["cost"]
            value = shares * price
            gain = value - cost
            pct = gain / cost * 100 if cost else 0.0
            rows.append((ticker, (
                ticker, NAMES[ticker], shares, money(self.book.average(ticker)), money(price),
                money(value), signed(gain), percent(pct),
            ), self.tag(gain)))
        self.sync_rows(self.Holdings, rows)

    def fill_orders(self):
        self.Orders.delete(*self.Orders.get_children())
        for order in self.book.orders:
            self.add_order_row(order)

    def add_order_row(self, order):
        result = order.get("result")
        when = order.get("when", "")
        try:
            when = datetime.datetime.strptime(when, "%Y-%m-%d %H:%M:%S").strftime("%d/%m/%Y %H:%M:%S")
        except ValueError:
            pass
        self.Orders.insert("", 0, values=(
            when,
            BUY if order.get("side") == "buy" else SELL,
            order.get("ticker", ""),
            order.get("shares", 0),
            money(order.get("price", 0)),
            money(order.get("fee", 0)),
            signed(order.get("total", 0)),
            "" if result is None else signed(result),
        ), tags=() if result is None else self.tag(result))

    def update_summary(self):
        prices = self.market.prices
        stocks = self.book.stocks_value(prices)
        total = self.book.cash + stocks
        gain = total - START_CASH
        self.CashValue.configure(text=money(self.book.cash))
        self.StocksValue.configure(text=money(stocks))
        self.TotalValue.configure(text=money(total))
        arrow = "▲ " if gain > 0.004 else "▼ " if gain < -0.004 else ""
        self.GainValue.configure(
            text="%s%s (%s)" % (arrow, signed(gain), percent(gain / START_CASH * 100)),
            fg=UP if gain > 0.004 else DOWN if gain < -0.004 else FLAT,
        )

    def show_chart(self):
        ticker = self.selected
        rows = list(self.market.history[ticker])
        labels = [x for x, _ in rows]
        self.Chart1.clear()
        self.Chart1.set_title("%s · %s" % (ticker, NAMES[ticker]))
        self.Chart1.set_series(ticker, [p for _, p in rows], x=labels)
        if self.book.shares(ticker):
            self.Chart1.set_series(AVERAGE, [self.book.average(ticker)] * len(labels), x=labels)

    def quantity(self):
        try:
            value = int(self.Qty_var.get().strip())
        except ValueError:
            return None
        return value if value > 0 else None

    def update_estimate(self):
        qty = self.quantity()
        if qty is None:
            self.Estimate.configure(text=BAD_QTY)
            return
        price = self.market.prices[self.selected]
        amount = qty * price
        self.Estimate.configure(text=ESTIMATE.format(
            qty, money(price), money(amount), money(fee_for(amount)), self.book.shares(self.selected),
        ))

    def refresh(self, orders=False):
        self.fill_market()
        self.fill_holdings()
        if orders:
            self.fill_orders()
        self.update_summary()
        self.update_estimate()

    def select_ticker(self, ticker, force=False):
        if ticker not in NAMES or (ticker == self.selected and not force):
            return
        self.selected = ticker
        self.OrderTicker_var.set(ticker)
        if self.Market.selection() != (ticker,):
            self.Market.selection_set(ticker)
            self.Market.see(ticker)
        self.show_chart()
        self.update_estimate()

    # ----------------------------------------------------------- guardar
    def save(self):
        try:
            save_state(self.path, self.book, self.market)
            self.save_failed = False
            return True
        except OSError as error:
            if not self.save_failed:
                self.Status.set(SAVE_ERROR.format(error), icon="⚠")
            self.save_failed = True
            return False

    # ----------------------------------------------------------- órdenes
    def trade(self, side):
        qty = self.quantity()
        ticker = self.selected
        price = self.market.prices[ticker]
        try:
            if qty is None:
                raise TradeError(BAD_QTY)
            if side == "buy":
                order = self.book.buy(ticker, qty, price)
            else:
                order = self.book.sell(ticker, qty, price)
        except TradeError as error:
            self.Status.set(str(error), icon="⚠")
            self.Qty.focus_set()
            return None
        self.add_order_row(order)
        self.refresh()
        self.show_chart()
        self.save()
        if side == "buy":
            self.Status.set(BOUGHT.format(qty, ticker, money(price), money(order["fee"])), icon="check")
        else:
            self.Status.set(SOLD.format(qty, ticker, money(price), signed(order["result"])), icon="check")
        return order

    # ---------------------------------------------------------- mercado
    def start(self):
        self.running = True
        self.Timer1.start()
        self.BtnPause.configure(text=PAUSE)

    def stop(self):
        self.running = False
        self.Timer1.stop()
        self.BtnPause.configure(text=RESUME)

    def Timer1_timer(self):
        label = self.market.step()
        self.ticks += 1
        ticker = self.selected
        self.Chart1.add_point(ticker, self.market.prices[ticker], x=label)
        if self.book.shares(ticker):
            self.Chart1.add_point(AVERAGE, self.book.average(ticker), x=label)
        self.refresh()
        # Los precios también se guardan, cada medio minuto.
        if self.ticks % 30 == 0:
            self.save()

    # ----------------------------------------------------------- eventos
    def Market_select(self, event=None):
        chosen = self.Market.selection()
        if chosen:
            self.select_ticker(chosen[0])

    def Holdings_select(self, event=None):
        chosen = self.Holdings.selection()
        if chosen:
            # Elegir una posición deja lista la venta de todas sus acciones.
            self.select_ticker(chosen[0])
            self.Qty_var.set(str(self.book.shares(chosen[0])))
            self.update_estimate()

    def OrderTicker_select(self, event=None):
        self.select_ticker(self.OrderTicker_var.get())

    def Qty_key_up(self, event=None):
        self.update_estimate()

    def BtnMax_click(self):
        self.Qty_var.set(str(self.book.max_buy(self.market.prices[self.selected])))
        self.update_estimate()

    def BtnBuy_click(self):
        self.trade("buy")

    def BtnSell_click(self):
        self.trade("sell")

    def BtnPause_click(self):
        if self.running:
            self.stop()
            self.save()
            self.Status.set(PAUSED, icon="stop")
        else:
            self.start()
            self.Status.set(RUNNING, icon="play")

    def BtnReset_click(self):
        if not messagebox.askyesno(APP, ASK_RESET, parent=self.root):
            return
        self.book = Portfolio()
        self.market = Market()
        self.Qty_var.set("10")
        self.refresh(orders=True)
        self.select_ticker(self.selected, force=True)
        self.save()
        self.Status.set(RESET_DONE, icon="refresh")

    def form_close(self, *args):
        self.Timer1.stop()
        self.save()
        self.root.destroy()
''';
  return TkExample(
    'investor',
    app,
    t(
      markTr(
        'Mercado simulado de empresas ficticias: compre y venda con comisión, siga su cartera y sus ganancias, y todo queda guardado.',
      ),
    ),
    design,
    code,
  );
}
