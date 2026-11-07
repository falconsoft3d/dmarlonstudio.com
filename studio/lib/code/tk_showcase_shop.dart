part of 'tk_examples.dart';

// ------------------------------------------------------ la tienda del curso
// Un proyecto por curso de bases de datos de la web, con la tienda de los
// cursos (categories, products, customers, orders, order_items, reviews):
//
// - SQLite, PostgreSQL, MySQL y MongoDB: el «Panel de la tienda» de
//   escritorio, con una Conexión de datos a la conexión guardada «shop» y
//   tres Tablas de datos que cargan su propia consulta.
// - FalconDatabase y Firebase: el «Catálogo de la tienda», una app de
//   Flutter con App → Base de datos (lib/db.dart).
//
// El código de cada uno no lleva textos para el usuario (están en el
// diseño): es el mismo en español y en inglés.

/// Las consultas de un motor: las de las tablas (en sus propiedades) y las
/// del código.
class _ShopSql {
  const _ShopSql({
    required this.seed,
    required this.engine,
    required this.products,
    required this.orders,
    required this.customers,
    required this.summary,
    required this.byCategory,
    this.mongo = false,
  });

  final String seed, engine;
  final String products, orders, customers, summary, byCategory;
  final bool mongo;
}

/// JSON con espacios, como se escribe a mano: {"a": 1, "b": [2, 3]}.
String _json(Object? v) => switch (v) {
  Map m =>
    '{${m.entries.map((e) => '${jsonEncode('${e.key}')}: ${_json(e.value)}').join(', ')}}',
  List l => '[${l.map(_json).join(', ')}]',
  _ => jsonEncode(v),
};

/// Una consulta de MongoDB del módulo Bases de datos: una etapa por línea.
String _pipeline(String collection, List<Object> stages) =>
    '{"collection": "$collection", "aggregate": [\n'
    '${stages.map((s) => '  ${_json(s)}').join(',\n')}\n]}';

/// Un importe con dos decimales, en texto («1.20»), en MongoDB 4.4.
Map<String, Object> _money(Object amount) => {
  r'$let': {
    'vars': {
      'c': {
        r'$round': [
          {
            r'$multiply': [amount, 100],
          },
          0,
        ],
      },
    },
    'in': {
      r'$concat': [
        {
          r'$toString': {
            r'$toInt': {
              r'$floor': {
                r'$divide': [r'$$c', 100],
              },
            },
          },
        },
        '.',
        {
          r'$substrCP': [
            {
              r'$toString': {
                r'$toInt': {
                  r'$add': [
                    100,
                    {
                      r'$mod': [r'$$c', 100],
                    },
                  ],
                },
              },
            },
            1,
            2,
          ],
        },
      ],
    },
  },
};

Map<String, Object> _first(String array) => {
  r'$arrayElemAt': [array, 0],
};

Map<String, Object> _lookup(String from, String local, String as) => {
  r'$lookup': {
    'from': from,
    'localField': local,
    'foreignField': '_id',
    'as': as,
  },
};

const _notCancelled = {
  r'$match': {
    'status': {r'$ne': 'cancelled'},
  },
};

/// Las consultas de SQL de [engine] (sqlite, postgres o mysql).
_ShopSql _sql(String engine) {
  final sqlite = engine == 'sqlite';
  String money(String e) => sqlite ? "printf('%.2f', $e)" : e;
  final like = engine == 'postgres' ? 'ILIKE' : 'LIKE';
  return _ShopSql(
    seed: 'shop_$engine',
    engine: switch (engine) {
      'sqlite' => 'SQLite',
      'postgres' => 'PostgreSQL',
      _ => 'MySQL',
    },
    products:
        '''SELECT p.name, c.name AS category,
       ${money('p.price')} AS price, p.stock
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.name $like ?
ORDER BY p.name''',
    orders:
        '''SELECT o.id, o.ordered, c.name AS customer, o.status,
       ${money('SUM(i.qty * i.price)')} AS total
FROM orders o
JOIN customers c ON c.id = o.customer_id
JOIN order_items i ON i.order_id = o.id
GROUP BY o.id, o.ordered, c.name, o.status
ORDER BY o.ordered DESC, o.id DESC''',
    customers:
        '''SELECT c.name, c.city, COUNT(o.id) AS orders,
       ${money('SUM(o.total)')} AS spent
FROM customers c
JOIN orders o ON o.customer_id = c.id
WHERE o.status <> 'cancelled'
GROUP BY c.id, c.name, c.city
ORDER BY SUM(o.total) DESC, c.name
LIMIT 5''',
    summary: '''SUMMARY = """
SELECT COUNT(*) AS orders, SUM(total) AS sales, AVG(total) AS average,
       COUNT(DISTINCT customer_id) AS customers
FROM orders
WHERE status <> 'cancelled'
"""''',
    byCategory: '''BY_CATEGORY = """
SELECT c.name AS category, SUM(i.qty * i.price) AS sales
FROM order_items i
JOIN orders o ON o.id = i.order_id
JOIN products p ON p.id = i.product_id
JOIN categories c ON c.id = p.category_id
WHERE o.status <> 'cancelled'
GROUP BY c.name
ORDER BY c.name
"""''',
  );
}

/// Las consultas de MongoDB: el JSON del módulo Bases de datos.
_ShopSql _mongoShop() => _ShopSql(
  seed: 'shop_mongodb',
  engine: 'MongoDB',
  mongo: true,
  products: _pipeline('products', [
    {
      r'$match': {
        'name': {r'$regex': '?', r'$options': 'i'},
      },
    },
    _lookup('categories', 'category_id', 'category'),
    {
      r'$project': {
        '_id': 0,
        'name': 1,
        'category': _first(r'$category.name'),
        'price': _money(r'$price'),
        'stock': 1,
      },
    },
    {
      r'$sort': {'name': 1},
    },
  ]),
  orders: _pipeline('orders', [
    _lookup('customers', 'customer_id', 'customer'),
    {
      r'$project': {
        '_id': 0,
        'id': r'$_id',
        'ordered': 1,
        'customer': _first(r'$customer.name'),
        'status': 1,
        'total': _money({
          r'$sum': {
            r'$map': {
              'input': r'$items',
              'as': 'i',
              'in': {
                r'$multiply': [r'$$i.qty', r'$$i.price'],
              },
            },
          },
        }),
      },
    },
    {
      r'$sort': {'ordered': -1, 'id': -1},
    },
  ]),
  customers: _pipeline('orders', [
    _notCancelled,
    {
      r'$group': {
        '_id': r'$customer_id',
        'orders': {r'$sum': 1},
        'spent': {r'$sum': r'$total'},
      },
    },
    {
      r'$sort': {'spent': -1, '_id': 1},
    },
    {r'$limit': 5},
    _lookup('customers', '_id', 'c'),
    {
      r'$project': {
        '_id': 0,
        'name': _first(r'$c.name'),
        'city': _first(r'$c.city'),
        'orders': 1,
        'spent': _money(r'$spent'),
      },
    },
  ]),
  summary: r'''SUMMARY = {"collection": "orders", "aggregate": [
    {"$match": {"status": {"$ne": "cancelled"}}},
    {"$group": {"_id": None, "orders": {"$sum": 1}, "sales": {"$sum": "$total"},
                "average": {"$avg": "$total"}, "customers": {"$addToSet": "$customer_id"}}},
    {"$project": {"_id": 0, "orders": 1, "sales": 1, "average": 1,
                  "customers": {"$size": "$customers"}}},
]}''',
  byCategory: r'''BY_CATEGORY = {"collection": "orders", "aggregate": [
    {"$match": {"status": {"$ne": "cancelled"}}},
    {"$unwind": "$items"},
    {"$lookup": {"from": "products", "localField": "items.product_id",
                 "foreignField": "_id", "as": "product"}},
    {"$lookup": {"from": "categories", "localField": "product.category_id",
                 "foreignField": "_id", "as": "category"}},
    {"$group": {"_id": {"$arrayElemAt": ["$category.name", 0]},
                "sales": {"$sum": {"$multiply": ["$items.qty", "$items.price"]}}}},
    {"$sort": {"_id": 1}},
    {"$project": {"_id": 0, "category": "$_id", "sales": 1}},
]}''',
);

/// Los cuatro paneles de escritorio: SQLite, PostgreSQL, MySQL y MongoDB.
List<TkExample> tkShopDesktopExamples(String Function(String) t) => [
  for (final s in [
    _sql('sqlite'),
    _sql('postgres'),
    _sql('mysql'),
    _mongoShop(),
  ])
    _shopDashboard(t, s),
];

/// Las dos apps de Flutter: FalconDatabase y Firebase.
List<TkExample> tkShopMobileExamples(String Function(String) t) => [
  _shopCatalogue(t, firebase: false),
  _shopCatalogue(t, firebase: true),
];

/// Los proyectos de los cursos de bases de datos, por curso de la web.
Map<String, TkExample> tkShopCourseExamples(String Function(String) t) {
  final all = [...tkShopDesktopExamples(t), ...tkShopMobileExamples(t)];
  TkExample of(String seed) => all.firstWhere((e) => e.seed == seed);
  return {
    'sqlite': of('shop_sqlite'),
    'postgres': of('shop_postgres'),
    'mysql': of('shop_mysql'),
    'mongodb': of('shop_mongodb'),
    'falcondatabase': of('shop_falcon'),
    'firebase': of('shop_firebase'),
  };
}

// ------------------------------------------------------- panel (escritorio)
TkExample _shopDashboard(String Function(String) t, _ShopSql s) {
  final app = t(markTr('Panel de la tienda'));
  const white = '#ffffff';
  const grey = '#5f6672';
  TkWidget heading(String name, int x, int y, String text) => _w(
    'Label',
    name,
    x,
    y,
    420,
    26,
    {..._title(text, size: 14), 'bg': _paper},
  );
  final cards = [
    ('Orders', t(markTr('Pedidos'))),
    ('Sales', t(markTr('Ventas'))),
    ('Average', t(markTr('Ticket medio'))),
    ('Customers', t(markTr('Clientes'))),
  ];
  String cols(List<(String, String, int)> c) =>
      [for (final (f, title, w) in c) '$f|$title|$w'].join('\n');
  final design =
      TkDesign(
          width: 1180,
          height: 780,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create'},
        )
        ..widgets.addAll([
          _w('Label', 'Heading', 16, 12, 700, 32, {
            ..._title(app),
            'bg': _paper,
          }),
          _w('Label', 'Intro', 16, 44, 1100, 22, {
            ..._label(
              t(
                markTr(
                  '{0} · la tienda del curso, leída de la conexión «shop» del módulo Bases de datos.',
                ),
              ).replaceAll('{0}', s.engine),
            ),
            'fg': grey,
            'bg': _paper,
          }),
          _w('Connection', 'Shop', 1132, 12, 32, 32, {'connection': 'shop'}),
          for (final (i, (name, caption)) in cards.indexed) ...[
            _w('Label', 'Cap$name', 16 + i * 291, 76, 275, 26, {
              'text': caption,
              'anchor': 'center',
              'bg': white,
              'fg': grey,
            }),
            _w('Label', 'Kpi$name', 16 + i * 291, 102, 275, 40, {
              'text': '—',
              'anchor': 'center',
              'bg': white,
              'fg': '#2b5797',
              'font_size': 20,
              'font_bold': true,
            }),
          ],
          heading('LblProducts', 16, 156, t(markTr('Productos'))),
          heading('LblOrders', 600, 156, t(markTr('Pedidos'))),
          _w('Entry', 'Search', 16, 190, 400, 28, {}, {
            'enter_key': 'Search_return',
          }),
          _w(
            'Button',
            'BtnSearch',
            424,
            188,
            152,
            32,
            {'text': t(markTr('Buscar'))},
            {'command': 'BtnSearch_click'},
          ),
          _w('Label', 'OrdersHint', 600, 192, 564, 24, {
            ..._label(
              t(
                markTr('Cada pedido, con su cliente y el total de sus líneas.'),
              ),
            ),
            'fg': grey,
            'bg': _paper,
          }),
          _w('Treeview', 'Products', 16, 226, 560, 300, {
            'source': 'Shop',
            'query': s.products,
            'autoload': false,
            'columns': cols([
              ('name', t(markTr('Producto')), 200),
              ('category', t(markTr('Categoría')), 130),
              ('price', t(markTr('Precio')), 100),
              ('stock', t(markTr('Stock')), 80),
            ]),
          }),
          _w('Treeview', 'OrderList', 600, 226, 564, 300, {
            'source': 'Shop',
            'query': s.orders,
            'columns': cols([
              ('id', t(markTr('Nº')), 50),
              ('ordered', t(markTr('Fecha')), 100),
              ('customer', t(markTr('Cliente')), 170),
              ('status', t(markTr('Estado')), 100),
              ('total', t(markTr('Total')), 100),
            ]),
          }),
          heading('LblSales', 16, 540, t(markTr('Ventas por categoría'))),
          heading('LblCustomers', 600, 540, t(markTr('Mejores clientes'))),
          _w('Chart', 'SalesChart', 16, 570, 560, 176, {
            'kind': 'bar',
            'legend': false,
            'decimals': 0,
            'suffix': ' €',
          }),
          _w('Treeview', 'TopCustomers', 600, 570, 564, 176, {
            'source': 'Shop',
            'query': s.customers,
            'columns': cols([
              ('name', t(markTr('Cliente')), 190),
              ('city', t(markTr('Ciudad')), 130),
              ('orders', t(markTr('Pedidos')), 90),
              ('spent', t(markTr('Gastado')), 110),
            ]),
          }),
          _w('StatusBar', 'Status', 0, 756, 1180, 24, {
            'text': t(
              markTr(
                'Conexión «shop» ({0}): créela en Bases de datos y cargue en ella los datos del curso.',
              ),
            ).replaceAll('{0}', s.engine),
            'icon': 'info',
          }),
        ]);
  final search = s.mongo
      ? '''        # The "?" of the query takes the text (escaped: it is a regex).
        text = re.escape(self.Search.get().strip())
        self.Products_refresh((text,))'''
      : '''        # The ? of the query takes the text: never joined into the SQL.
        text = "%" + self.Search.get().strip() + "%"
        self.Products_refresh((text,))''';
  final code =
      '''${s.mongo ? 'import re\n\n' : ''}# Shop dashboard (${s.engine}). The three tables load the query of their
# "Query" property from the Shop connection; this code runs the search and
# fills the four figures and the chart.
${s.summary}

${s.byCategory}


def money(value):
    return "%.2f €" % float(value or 0)


class Form1(FormDesign):
    def form_create(self):
        self.search()
        self.summary()

    def BtnSearch_click(self):
        self.search()

    def Search_return(self, event=None):
        self.search()

    def search(self):
$search

    def summary(self):
        try:
            row = self.Shop.query(SUMMARY)[0]
            sales = self.Shop.query(BY_CATEGORY)
        except DataError as error:
            tkinter.messagebox.showerror(self.root.title(), str(error))
            return
        self.KpiOrders.config(text=str(row["orders"]))
        self.KpiSales.config(text=money(row["sales"]))
        self.KpiAverage.config(text=money(row["average"]))
        self.KpiCustomers.config(text=str(row["customers"]))
        self.SalesChart.set_series(
            "sales",
            [float(r["sales"]) for r in sales],
            x=[r["category"] for r in sales],
        )
''';
  return TkExample(
    s.seed,
    t(markTr('Panel de la tienda ({0})')).replaceAll('{0}', s.engine),
    t(
      markTr(
        'Los productos, los pedidos y las ventas de la tienda del curso de {0}, con una Conexión de datos y tres Tablas de datos.',
      ),
    ).replaceAll('{0}', s.engine),
    design,
    code,
  );
}

// ---------------------------------------------------- catálogo (Flutter)
/// La lógica del catálogo con FalconDatabase: el filtro y la búsqueda van
/// al servidor (where con «ilike»).
const _falconCatalogue =
    r'''// Shop catalogue: categories, products and reviews read from FalconDatabase
// with lib/db.dart (App → Database). The anon key only reads: the shop
// tables are public_read.
import 'package:flutter/material.dart';

import 'db.dart';

class App extends ChangeNotifier {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> reviews = [];
  String search = '';
  Object? category;
  bool loading = false;
  String error = '';

  Future<void> start() async {
    try {
      categories = await db.table('categories').list(order: 'name');
    } on DbError catch (e) {
      error = e.message;
    }
    await load();
  }

  /// The products of the chosen category whose name contains the search:
  /// GET /tables/products?category_id=eq.2&name=ilike.%tea%&order=name
  Future<void> load() async {
    loading = true;
    notifyListeners();
    final text = search.trim();
    try {
      products = await db.table('products').list(
        where: {
          if (category != null) 'category_id': category,
          if (text.isNotEmpty) 'name': 'ilike.%$text%',
        },
        order: 'name',
      );
      error = '';
    } on DbError catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  void pick(Map<String, dynamic>? c) {
    category = c?['id'];
    load();
  }

  /// The reviews of a product (a second query: the REST API has no joins).
  Future<void> open(Map<String, dynamic> p) async {
    reviews = [];
    notifyListeners();
    try {
      reviews = await db.table('reviews').list(where: {'product_id': p['id']}, order: 'id');
    } on DbError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ to show
  Object? categoryId(Map<String, dynamic> p) => p['category_id'];

  String categoryName(Object? id) =>
      '${categories.where((c) => c['id'] == id).firstOrNull?['name'] ?? ''}';

  String get filter => categoryName(category);

  String price(Map<String, dynamic> p) => '${(p['price'] as num).toStringAsFixed(2)} €';

  bool soldOut(Map<String, dynamic> p) => (p['stock'] as num? ?? 0) <= 0;

  String tags(Map<String, dynamic> p) =>
      [for (final t in (p['tags'] as List?) ?? const []) '#$t'].join('  ');

  String stars(Map<String, dynamic> r) {
    final n = (r['rating'] as num? ?? 0).toInt().clamp(0, 5);
    return '★' * n + '☆' * (5 - n);
  }

  String get rating => reviews.isEmpty
      ? '—'
      : '${(reviews.fold<num>(0, (s, r) => s + (r['rating'] as num)) / reviews.length).toStringAsFixed(1)} ★ (${reviews.length})';

  static const _icons = {1: Icons.bakery_dining, 2: Icons.local_cafe, 3: Icons.icecream, 4: Icons.eco};
  static const _colors = {1: Color(0xFF8D6E63), 2: Color(0xFF5C6BC0), 3: Color(0xFF26A69A), 4: Color(0xFF7CB342)};

  IconData icon(Object? category) => _icons[category] ?? Icons.shopping_basket;

  Color color(Object? category) => _colors[category] ?? const Color(0xFF78909C);
}
''';

/// La lógica del catálogo con Firebase: Firestore filtra por categoría
/// (where) y la búsqueda se hace en la app (Firestore no busca dentro de un
/// texto).
const _firebaseCatalogue =
    r'''// Shop catalogue: categories, products and reviews read from Cloud Firestore
// with lib/db.dart (App → Database). Firestore filters by category; the
// search runs here, because Firestore cannot search inside a text.
import 'package:flutter/material.dart';

import 'db.dart';

class App extends ChangeNotifier {
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> all = [];
  List<Map<String, dynamic>> reviews = [];
  String search = '';
  Object? category;
  bool loading = false;
  String error = '';

  Future<void> start() async {
    try {
      categories = await db.table('categories').list();
      categories.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    } on DbError catch (e) {
      error = e.message;
    }
    await load();
  }

  /// The products of the chosen category (a structured query with where).
  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      all = await db.table('products').list(
        where: {if (category != null) 'category': category},
      );
      all.sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
      error = '';
    } on DbError catch (e) {
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  /// What the list shows: the products whose name contains the search.
  List<Map<String, dynamic>> get products {
    final text = search.trim().toLowerCase();
    return [
      for (final p in all)
        if ('${p['name']}'.toLowerCase().contains(text)) p,
    ];
  }

  void pick(Map<String, dynamic>? c) {
    category = c?['id'];
    load();
  }

  /// The reviews of a product: the documents of reviews whose product is
  /// its id.
  Future<void> open(Map<String, dynamic> p) async {
    reviews = [];
    notifyListeners();
    try {
      reviews = await db.table('reviews').list(where: {'product': p['id']});
    } on DbError catch (e) {
      error = e.message;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------ to show
  Object? categoryId(Map<String, dynamic> p) => p['category'];

  String categoryName(Object? id) =>
      '${categories.where((c) => c['id'] == id).firstOrNull?['name'] ?? ''}';

  String get filter => categoryName(category);

  String price(Map<String, dynamic> p) => '${(p['price'] as num).toStringAsFixed(2)} €';

  bool soldOut(Map<String, dynamic> p) => (p['stock'] as num? ?? 0) <= 0;

  String tags(Map<String, dynamic> p) =>
      [for (final t in (p['tags'] as List?) ?? const []) '#$t'].join('  ');

  String stars(Map<String, dynamic> r) {
    final n = (r['rating'] as num? ?? 0).toInt().clamp(0, 5);
    return '★' * n + '☆' * (5 - n);
  }

  String get rating => reviews.isEmpty
      ? '—'
      : '${(reviews.fold<num>(0, (s, r) => s + (r['rating'] as num)) / reviews.length).toStringAsFixed(1)} ★ (${reviews.length})';

  static const _icons = {'cat1': Icons.bakery_dining, 'cat2': Icons.local_cafe, 'cat3': Icons.icecream, 'cat4': Icons.eco};
  static const _colors = {'cat1': Color(0xFF8D6E63), 'cat2': Color(0xFF5C6BC0), 'cat3': Color(0xFF26A69A), 'cat4': Color(0xFF7CB342)};

  IconData icon(Object? category) => _icons[category] ?? Icons.shopping_basket;

  Color color(Object? category) => _colors[category] ?? const Color(0xFF78909C);
}
''';

/// El proyecto del curso de FalconDatabase: lectura pública con la clave
/// anon (funciona tal cual).
const tkShopFalconRef = 'ddbsnwfthlcufjjezqqf';
const tkShopFalconKey =
    'fdb_anon_01574d098100502b15344a0d9ba01bb4bcaeb60953030895';

/// Firebase: el proyecto del curso en el emulador de Firestore de serie
/// (`firebase emulators:start --only firestore`).
const tkShopFirebaseProject = 'dms-cursos';
const tkShopFirebaseEmulator = '127.0.0.1:8080';

TkExample _shopCatalogue(String Function(String) t, {required bool firebase}) {
  final stock = t(markTr('{0} en stock'));
  final app = FlApp(
    title: t(markTr('Catálogo de la tienda')),
    primary: '#6D4C41',
    backend: firebase
        ? const FlBackend(
            kind: 'firebase',
            url: tkShopFirebaseEmulator,
            project: tkShopFirebaseProject,
          )
        : const FlBackend(
            kind: 'falcon',
            project: tkShopFalconRef,
            key: tkShopFalconKey,
          ),
    screens: [
      FlScreen(
        name: 'Catalogo',
        title: t(markTr('Catálogo de la tienda')),
        bar: 'filter_list|go:Categorias\nrefresh|app.load()',
        body: _n('Column', {}, [
          _n(
            'Padding',
            {'padding': 12},
            [
              _n('TextField', {
                'hint': t(markTr('Buscar productos')),
                'icon': 'search',
                'bind': 'app.search',
                if (!firebase) 'onSubmit': 'app.load()',
              }),
            ],
          ),
          _n(
            'Padding',
            {'padding': 4},
            [
              _n(
                'Row',
                {'gap': 8, 'wrap': true},
                [
                  _n('Chip', {
                    'text': t(markTr('Todas')),
                    'icon': 'list',
                    'selected': '=app.category == null',
                    'onTap': 'app.pick(null)',
                  }),
                  _n('Chip', {
                    'text': r'${app.filter}',
                    'icon': 'close',
                    'selected': 'true',
                    'visible': '=app.category != null',
                    'onTap': 'app.pick(null)',
                  }),
                  _n('Chip', {
                    'text': t(markTr('Elegir categoría')),
                    'icon': 'filter_list',
                    'selected': 'false',
                    'onTap': 'go:Categorias',
                  }),
                ],
              ),
            ],
          ),
          _n('Progress', {'visible': '=app.loading'}),
          _n('Text', {
            'text': r'${app.error}',
            'color': 'error',
            'visible': '=app.error.isNotEmpty',
          }),
          _n(
            'ListView',
            {
              'items': '=app.products',
              'as': 'p',
              'padding': 8,
              'empty': t(markTr('No hay productos que coincidan.')),
            },
            [
              _n(
                'Card',
                {'padding': 10, 'onTap': 'app.open(p); go:Producto(p)'},
                [
                  _n(
                    'Row',
                    {'gap': 12},
                    [
                      _n(
                        'Container',
                        {
                          'width': 56,
                          'height': 56,
                          'radius': 14,
                          'color': '=app.color(app.categoryId(p))',
                        },
                        [
                          _n('Center', {}, [
                            _n('Icon', {
                              'icon': '=app.icon(app.categoryId(p))',
                              'size': 30,
                              'color': '#FFFFFF',
                            }),
                          ]),
                        ],
                      ),
                      _n('Expanded', {}, [
                        _n(
                          'Column',
                          {'cross': 'start', 'gap': 2},
                          [
                            _n('Text', {
                              'text': r"${p['name']}",
                              'style': 'titleMedium',
                            }),
                            _n('Text', {
                              'text':
                                  '\${app.categoryName(app.categoryId(p))} · ${stock.replaceAll('{0}', r"${p['stock']}")}',
                              'style': 'bodySmall',
                              'color':
                                  "=app.soldOut(p) ? Colors.red : Colors.grey.shade700",
                            }),
                          ],
                        ),
                      ]),
                      _n('Text', {
                        'text': r'${app.price(p)}',
                        'bold': true,
                        'color': 'primary',
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Categorias',
        title: t(markTr('Categorías')),
        body: _n('Column', {}, [
          _n('ListTile', {
            'title': t(markTr('Todas las categorías')),
            'icon': 'all_inbox',
            'onTap': 'app.pick(null); back',
          }),
          _n('Divider'),
          _n(
            'ListView',
            {'items': '=app.categories', 'as': 'c', 'separated': true},
            [
              _n('ListTile', {
                'title': r"${c['name']}",
                'icon': "=app.icon(c['id'])",
                'leadingColor': "=app.color(c['id'])",
                'trailingIcon': 'chevron_right',
                'onTap': 'app.pick(c); back',
              }),
            ],
          ),
        ]),
      ),
      FlScreen(
        name: 'Producto',
        title: r"${arg['name']}",
        arg: 'Map<String, dynamic>',
        body: _n(
          'Column',
          {'padding': 16, 'gap': 10},
          [
            _n(
              'Container',
              {
                'height': 150,
                'radius': 24,
                'color': '=app.color(app.categoryId(arg))',
              },
              [
                _n('Center', {}, [
                  _n('Icon', {
                    'icon': '=app.icon(app.categoryId(arg))',
                    'size': 84,
                    'color': '#FFFFFF',
                  }),
                ]),
              ],
            ),
            _n('Text', {
              'text': r"${arg['name']}",
              'style': 'headlineSmall',
              'bold': true,
            }),
            _n(
              'Row',
              {'gap': 8, 'wrap': true},
              [
                _n('Chip', {
                  'text': r'${app.categoryName(app.categoryId(arg))}',
                  'icon': 'sell',
                }),
                _n('Chip', {
                  'text': stock.replaceAll('{0}', r"${arg['stock']}"),
                  'icon': 'inventory_2_outlined',
                }),
              ],
            ),
            _n('Text', {
              'text': r'${app.price(arg)}',
              'style': 'headlineMedium',
              'color': 'primary',
            }),
            _n('Text', {'text': r'${app.tags(arg)}', 'style': 'bodyMedium'}),
            _n('Divider'),
            _n('Text', {
              'text': t(
                markTr('Opiniones · {0}'),
              ).replaceAll('{0}', r'${app.rating}'),
              'style': 'titleMedium',
            }),
            _n(
              'ListView',
              {
                'items': '=app.reviews',
                'as': 'r',
                'separated': true,
                'empty': t(markTr('Aún no hay opiniones de este producto.')),
              },
              [
                _n('ListTile', {
                  'title': r'${app.stars(r)}',
                  'subtitle': r"${r['comment'] ?? ''}",
                  'icon': 'person',
                }),
              ],
            ),
          ],
        ),
      ),
    ],
  );
  final engine = firebase ? 'Firebase' : 'FalconDatabase';
  return TkExample(
    firebase ? 'shop_firebase' : 'shop_falcon',
    t(markTr('Catálogo de la tienda ({0})')).replaceAll('{0}', engine),
    firebase
        ? t(
            markTr(
              'Una app móvil con la tienda del curso en Cloud Firestore (el emulador): productos, filtro por categoría, búsqueda y opiniones.',
            ),
          )
        : t(
            markTr(
              'Una app móvil con la tienda del curso en FalconDatabase, de solo lectura: productos, filtro por categoría, búsqueda y opiniones.',
            ),
          ),
    _flutterDesign(app),
    firebase ? _firebaseCatalogue : _falconCatalogue,
  );
}
