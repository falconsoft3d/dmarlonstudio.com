part of 'tk_examples.dart';

// Ejemplos web que se ven como webs de verdad: una sola Vista HTML a página
// completa, con el HTML y el CSS generados por el código de Python. Todo lo
// que escribe el visitante pasa por html.escape antes de llegar a la página.

/// Diseño de una web: solo la Vista HTML «Site», a página completa.
TkDesign _siteDesign(String title, String placeholder) =>
    TkDesign(
        width: 1200,
        height: 800,
        target: tkTargetWeb,
        props: {'title': title, 'bg': '#ffffff'},
        events: {'create': 'form_create'},
      )
      ..widgets.add(
        _w(
          'HtmlView',
          'Site',
          0,
          0,
          1200,
          800,
          {'html': placeholder, 'full_page': true},
          {'action': 'Site_action'},
        ),
      );

/// Las frases de una web como diccionario de Python (T["clave"]).
String _phrases(Map<String, String> m) =>
    'T = {\n${m.entries.map((e) => '    ${_py(e.key)}: ${_py(e.value)},').join('\n')}\n}';

// -------------------------------------------------------------------- blog
TkExample _siteBlog(String Function(String) t) {
  final brand = t(markTr('Bitácora'));
  final cats = [
    t(markTr('Producto')),
    t(markTr('Tutoriales')),
    t(markTr('Ingeniería')),
    t(markTr('Comunidad')),
  ];
  final phrases = _phrases({
    ..._authPhrases(t),
    'dash_title': t(markTr('Panel del blog')),
    'posts': t(markTr('Entradas')),
    'drafts': t(markTr('Borradores')),
    'comments_n': t(markTr('Comentarios')),
    'subscribers': t(markTr('Suscriptores')),
    'users': t(markTr('Usuarios')),
    'recent': t(markTr('Últimos comentarios')),
    'status': t(markTr('Estado')),
    'date': t(markTr('Fecha')),
    'role': t(markTr('Papel')),
    'change': t(markTr('Cambiar')),
    'role_saved': t(markTr('Papel actualizado.')),
    'comment_deleted': t(markTr('Comentario eliminado.')),
    'as': t(markTr('Comentas como {0}.')),
    'brand': brand,
    'tagline': t(markTr('Ideas, guías y novedades para quien crea software.')),
    'search': t(markTr('Buscar…')),
    'write': t(markTr('Escribir')),
    'latest': t(markTr('Últimas entradas')),
    'read': t(markTr('{0} min de lectura')),
    'results': t(markTr('Resultados para «{0}»')),
    'found': t(markTr('{0} entradas')),
    'none': t(markTr('No hay entradas que coincidan.')),
    'news_title': t(markTr('Lo mejor de {0}, en tu correo')),
    'news_text': t(
      markTr('Una vez al mes, sin ruido. Puedes darte de baja cuando quieras.'),
    ),
    'email': t(markTr('Tu correo electrónico')),
    'subscribe': t(markTr('Suscribirme')),
    'subscribed': t(markTr('¡Hecho! Te escribiremos pronto.')),
    'bad_email': t(markTr('Escribe un correo válido.')),
    'comments': t(markTr('Comentarios ({0})')),
    'first': t(markTr('Sé el primero en comentar.')),
    'name': t(markTr('Nombre')),
    'comment': t(markTr('Comentario')),
    'send': t(markTr('Publicar comentario')),
    'thanks': t(markTr('Gracias por comentar.')),
    'bad_comment': t(
      markTr('Escribe tu nombre (2-60 letras) y un comentario (3-500 letras).'),
    ),
    'related': t(markTr('Sigue leyendo')),
    'back': t(markTr('← Volver al inicio')),
    'edit': t(markTr('Editar')),
    'delete': t(markTr('Eliminar')),
    'new_post': t(markTr('Nueva entrada')),
    'edit_post': t(markTr('Editar entrada')),
    'title': t(markTr('Título')),
    'category': t(markTr('Categoría')),
    'author': t(markTr('Autor')),
    'summary': t(markTr('Resumen')),
    'body': t(markTr('Contenido')),
    'hint': t(
      markTr(
        'Formato sencillo: «## » para un subtítulo, «- » para una lista, **negrita** y `código`.',
      ),
    ),
    'published': t(markTr('Publicada')),
    'draft': t(markTr('Borrador')),
    'save': t(markTr('Guardar')),
    'saved': t(markTr('Entrada guardada.')),
    'deleted': t(markTr('Entrada eliminada.')),
    'need': t(markTr('Escribe el título y el contenido.')),
    'about': t(markTr('Sobre el blog')),
    'about_text': t(
      markTr(
        'Un blog de ejemplo hecho con DMarlon Studio y Flask: las entradas, los comentarios y los suscriptores se guardan en SQLite.',
      ),
    ),
    'categories': t(markTr('Categorías')),
    'rights': t(markTr('© {0} {1}. Todos los derechos reservados.')),
    'months': t(markTr('ene,feb,mar,abr,may,jun,jul,ago,sep,oct,nov,dic')),
  });
  final posts = [
    (
      0,
      0,
      0,
      t(markTr('Llegan los componentes de inteligencia artificial')),
      t(
        markTr(
          'Resumir, traducir, clasificar y conversar desde tus propias aplicaciones, con un solo componente y sin congelar la ventana.',
        ),
      ),
      t(
        markTr(
          'Hoy damos un paso que muchos nos pedíais: el componente **Asistente IA**. Se arrastra al formulario como un botón y desde el código basta una línea para pedirle algo a Claude.\n## Qué puede hacer\n- Resumir un texto largo en unas pocas frases\n- Traducir a cualquier idioma\n- Clasificar opiniones en positivas, neutras o negativas\n- Extraer datos (nombre, correo, teléfono) en un diccionario\n## Sin congelar la ventana\nCada llamada tiene su versión `_async`: la aplicación sigue respondiendo y el resultado llega al evento **done**. En la web, la petición simplemente espera a la respuesta.\nLa clave nunca va en el código: se lee de la variable de entorno, así que puedes compartir el proyecto sin miedo.',
        ),
      ),
    ),
    (
      2,
      1,
      1,
      t(markTr('Tu primera aplicación web en diez minutos')),
      t(
        markTr(
          'Del lienzo vacío a una página que guarda datos en SQLite: los pasos, uno a uno.',
        ),
      ),
      t(
        markTr(
          'Crear una aplicación web no debería empezar por configurar un servidor. En DMarlon Studio eliges **Web (Flask)** al crear el proyecto y ya tienes una página funcionando.\n## Los pasos\n- Arrastra una caja de texto, un botón y una tabla\n- Haz doble clic en el botón para escribir su evento\n- Pulsa el botón verde: la página se abre en el navegador\nEl código de los eventos es Python normal. Lo que cambias en los componentes llega al navegador sin escribir JavaScript.\n## Y después\nCuando quieras una web con aspecto propio, usa la **Vista HTML**: escribes el HTML y los enlaces llaman a tus eventos. Este mismo blog está hecho así.',
        ),
      ),
    ),
    (
      4,
      2,
      2,
      t(markTr('Cómo dibujamos las páginas en el servidor')),
      t(
        markTr(
          'Plantillas, parches de HTML y una sola petición por evento: el motor web por dentro.',
        ),
      ),
      t(
        markTr(
          'Cada componente de una página tiene su estado en el servidor. Cuando el visitante pulsa algo, el navegador envía un evento pequeño y recibe solo el HTML de lo que ha cambiado.\n## Por qué así\n- El código de la aplicación es el mismo que en el escritorio\n- No hay que mantener dos modelos de datos\n- El navegador no ejecuta código de terceros\nLas plantillas escapan cada texto por defecto. Solo la Vista HTML pinta HTML tal cual, y por eso en los ejemplos todo lo que escribe el visitante pasa antes por `html.escape`.',
        ),
      ),
    ),
    (
      7,
      3,
      0,
      t(markTr('Lo que construisteis este mes')),
      t(
        markTr(
          'Un panel de turnos para un taller, un catálogo de vinilos y un juego de memoria: vuestros proyectos favoritos.',
        ),
      ),
      t(
        markTr(
          'Cada mes recibimos proyectos que nos sorprenden. Estos son tres de los que más nos han gustado.\n## Turnos del taller\nUna tabla de datos, un calendario y un informe en PDF que se imprime cada lunes. Sin instalar nada más.\n## Catálogo de vinilos\nUna web con buscador y fichas de cada disco, hecha con la Vista HTML y una base de datos SQLite.\n## Memoria\nUn juego de parejas con temporizador y récords. Lo hizo una profesora para su clase de primaria.\n¿Quieres que tu proyecto aparezca aquí? Escríbenos y cuéntanos qué has hecho.',
        ),
      ),
    ),
    (
      10,
      1,
      1,
      t(markTr('Informes en PDF y Excel sin instalar nada')),
      t(
        markTr(
          'Tablas con totales, varias hojas y número de página, solo con la biblioteca estándar de Python.',
        ),
      ),
      t(
        markTr(
          'Los componentes **Informe PDF** e **Informe Excel** escriben los archivos ellos mismos, sin bibliotecas externas.\n## Un informe en tres líneas\n- `pdf.title(\'Ventas\')` para el título\n- `pdf.table(cabeceras, filas, totals=...)` para la tabla\n- `pdf.save_dialog()` para guardarlo\nEn una aplicación web, guardar se convierte en una descarga: el mismo código sirve para las dos.',
        ),
      ),
    ),
    (
      14,
      2,
      2,
      t(markTr('Seguridad por defecto en las aplicaciones web')),
      t(
        markTr(
          'Política de contenido, protección contra peticiones falsas y sesiones aisladas, sin configurar nada.',
        ),
      ),
      t(
        markTr(
          'Una aplicación web recién creada ya incluye varias defensas.\n## Lo que viene activado\n- Una política de contenido que solo permite los scripts del propio motor\n- Una cabecera secreta en cada evento contra las peticiones falsas\n- Una sesión distinta para cada visitante\nNada de esto cambia cómo escribes el código: siguen siendo eventos de Python. Lo único que te pedimos es escapar con `html.escape` lo que escriba el visitante si lo muestras en una Vista HTML.',
        ),
      ),
    ),
  ];
  final seed = [
    for (final (days, cat, author, title, summary, body) in posts)
      '    ($days, $cat, $author, ${_py(title)},\n'
          '     ${_py(summary)},\n'
          '     ${_py(body)}),',
  ].join('\n');
  final code =
      '''import datetime
import html
import re
import sqlite3
from contextlib import closing

DB = "blog.sqlite"
$phrases
CATEGORIES = [${cats.map(_py).join(', ')}]
AUTHORS = [("Lucía Ferrer", "#4f46e5"), ("Daniel Ortega", "#0f766e"), ("Marta Ruiz", "#c2410c")]
# (días atrás, categoría, autor, título, resumen, contenido)
SEED = [
$seed
]
FIRST_COMMENT = ("Ana", ${_py(t(markTr('¡Muy útil, gracias! Lo pruebo esta tarde.')))})
$_authCore$_blogCore''';
  return TkExample(
    'web_blog',
    t(markTr('Blog web')),
    t(
      markTr(
        'Un blog que parece un blog: portada con entrada destacada, categorías, buscador, artículos con comentarios, boletín, cuentas con login y registro, y un panel para escribir y moderar, guardado en SQLite.',
      ),
    ),
    _siteDesign(
      brand,
      '<h1>$brand</h1><p>${t(markTr('La página se genera al abrirla (form_create).'))}</p>',
    ),
    code,
  );
}

const _blogCore = r'''
COLORS = [("#4f46e5", "#0ea5e9"), ("#f59e0b", "#e11d48"), ("#059669", "#0d9488"), ("#c026d3", "#7c3aed")]
e = html.escape


def query(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        db.row_factory = sqlite3.Row
        return db.execute(sql, args).fetchall()


def execute(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        with db:
            return db.execute(sql, args).lastrowid


def create_tables():
    execute("""CREATE TABLE IF NOT EXISTS post (
        id INTEGER PRIMARY KEY, title TEXT NOT NULL, summary TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL DEFAULT '', category INTEGER NOT NULL DEFAULT 0,
        author INTEGER NOT NULL DEFAULT 0, date TEXT NOT NULL,
        published INTEGER NOT NULL DEFAULT 1)""")
    execute("""CREATE TABLE IF NOT EXISTS comment (
        id INTEGER PRIMARY KEY, post_id INTEGER NOT NULL, name TEXT NOT NULL,
        text TEXT NOT NULL, date TEXT NOT NULL)""")
    execute("CREATE TABLE IF NOT EXISTS subscriber (email TEXT PRIMARY KEY, date TEXT NOT NULL)")
    if query("SELECT COUNT(*) AS n FROM post")[0]["n"]:
        return
    today = datetime.date.today()
    for days, category, author, title, summary, body in SEED:
        date = (today - datetime.timedelta(days=days)).isoformat()
        execute("INSERT INTO post (title, summary, body, category, author, date) VALUES (?, ?, ?, ?, ?, ?)",
                (title, summary, body, category, author, date))
    first = query("SELECT id FROM post ORDER BY date DESC, id LIMIT 1")[0]["id"]
    execute("INSERT INTO comment (post_id, name, text, date) VALUES (?, ?, ?, ?)",
            (first,) + FIRST_COMMENT + (today.isoformat(),))


def number(text, default=None):
    try:
        return int(text)
    except (TypeError, ValueError):
        return default


def nice_date(iso):
    day = datetime.date.fromisoformat(iso)
    return "%d %s %d" % (day.day, T["months"].split(",")[day.month - 1], day.year)


def minutes(text):
    return max(1, round(len(text.split()) / 200))


def inline(text):
    """Negrita y código sobre el texto ya escapado: nunca entra HTML del autor."""
    text = e(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    return re.sub(r"`(.+?)`", r"<code>\1</code>", text)


def body_html(text):
    out, items = [], []

    def flush():
        if items:
            out.append("<ul>%s</ul>" % "".join("<li>%s</li>" % inline(i) for i in items))
            items.clear()

    for line in text.replace("\r", "").split("\n"):
        line = line.strip()
        if line.startswith("- "):
            items.append(line[2:])
            continue
        flush()
        if line.startswith("## ") or line.startswith("# "):
            out.append("<h2>%s</h2>" % inline(line.lstrip("#").strip()))
        elif line:
            out.append("<p>%s</p>" % inline(line))
    flush()
    return "".join(out)


def link(action, label, arg="", css=""):
    return '<a href="#" data-action="%s" data-arg="%s"%s>%s</a>' % (
        action, e(str(arg)), ' class="%s"' % css if css else "", label)


def cover(category, big=False):
    a, b = COLORS[category % len(COLORS)]
    letter = e(CATEGORIES[category % len(CATEGORIES)][:1])
    return ('<div class="cover%s" style="background:radial-gradient(circle at 85%% 15%%,rgba(255,255,255,.35),transparent 40%%),'
            'linear-gradient(135deg,%s,%s)"><b>%s</b>%s</div>') % (
        " big" if big else "", a, b, letter,
        '<span class="tag">%s</span>' % e(CATEGORIES[category % len(CATEGORIES)]) if big else "")


def byline(post):
    name, color = AUTHORS[post["author"] % len(AUTHORS)]
    initials = "".join(part[0] for part in name.split()[:2])
    return ('<div class="meta"><span class="avatar" style="background:%s">%s</span>'
            '<span><strong>%s</strong><br>%s · %s</span></div>') % (
        color, e(initials), e(name), nice_date(post["date"]), T["read"].format(minutes(post["body"])))


def card(post):
    return ('<a href="#" class="card" data-action="post" data-arg="%d">%s'
            '<span class="chip">%s</span><h3>%s</h3><p>%s</p>%s</a>') % (
        post["id"], cover(post["category"]), e(CATEGORIES[post["category"] % len(CATEGORIES)]),
        e(post["title"]), e(post["summary"]), byline(post))


CSS = """
.site{--ink:#14161f;--muted:#5d6475;--line:#e6e8ef;--soft:#f5f6fa;--brand:#4f46e5;
  font:16px/1.6 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:var(--ink);background:#fff;min-height:100vh}
.site *{box-sizing:border-box}
.site a{color:inherit}
.wrap{max-width:1140px;margin:0 auto;padding:0 24px}
.top{position:sticky;top:0;z-index:5;background:rgba(255,255,255,.94);border-bottom:1px solid var(--line)}
.bar{display:flex;align-items:center;gap:28px;height:68px}
.logo{display:flex;align-items:center;gap:10px;font-weight:800;font-size:21px;letter-spacing:-.02em;text-decoration:none}
.logo i{width:30px;height:30px;border-radius:9px;background:linear-gradient(135deg,#4f46e5,#0ea5e9)}
.cats{display:flex;gap:22px;flex:1}
.cats a{color:var(--muted);text-decoration:none;font-weight:500;font-size:15px}
.cats a:hover,.cats a.on{color:var(--ink)}
.search{margin:0}
.search input{border:1px solid var(--line);background:var(--soft);border-radius:999px;padding:8px 16px;width:210px;font:inherit;font-size:14px}
.btn{display:inline-block;border:0;border-radius:999px;padding:10px 20px;background:var(--ink);color:#fff!important;font:inherit;font-size:14px;font-weight:600;text-decoration:none;cursor:pointer}
.btn.light{background:#fff;color:var(--ink)!important;border:1px solid var(--line)}
.btn.small{padding:6px 12px;font-size:13px}
.btn.danger{background:#fff;color:#b91c1c!important;border:1px solid #fecaca}
.hero{padding:56px 0 8px}
.feature{display:grid;grid-template-columns:1.15fr 1fr;gap:48px;align-items:center;text-decoration:none}
.cover{position:relative;overflow:hidden;border-radius:16px;aspect-ratio:16/10;display:flex;align-items:flex-end;padding:16px}
.cover.big{border-radius:24px}
.cover b{position:absolute;right:22px;top:-14px;font-size:150px;font-weight:900;color:rgba(255,255,255,.22);line-height:1}
.cover.big b{font-size:230px}
.cover .tag{background:rgba(255,255,255,.92);color:var(--ink);font-size:12px;font-weight:700;border-radius:999px;padding:4px 12px}
.chip{font-size:12px;font-weight:700;text-transform:uppercase;letter-spacing:.08em;color:var(--brand)}
.feature h1{font-size:46px;line-height:1.08;letter-spacing:-.035em;margin:12px 0 14px}
.lead{color:var(--muted);font-size:19px;margin:0}
.meta{display:flex;align-items:center;gap:12px;color:var(--muted);font-size:13px;line-height:1.4;margin-top:auto;padding-top:8px}
.meta strong{color:var(--ink);font-weight:600}
.avatar{flex:none;width:36px;height:36px;border-radius:50%;display:inline-flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:13px}
.heading{display:flex;justify-content:space-between;align-items:baseline;gap:16px;margin:56px 0 24px;border-top:1px solid var(--line);padding-top:28px}
.heading h2{font-size:28px;letter-spacing:-.025em;margin:0}
.heading span{color:var(--muted);font-size:14px}
.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:40px 32px}
.card{display:flex;flex-direction:column;gap:10px;text-decoration:none}
.card h3{font-size:21px;line-height:1.25;letter-spacing:-.015em;margin:0}
.card p{margin:0;color:var(--muted);font-size:15px}
.card:hover h3,.feature:hover h1{color:var(--brand)}
.empty{color:var(--muted);padding:40px 0}
.news{margin:72px 0 56px;border-radius:24px;padding:48px;color:#fff;background:radial-gradient(circle at 90% 0,#6366f1,transparent 55%),#1e1b4b;
  display:grid;grid-template-columns:1fr 1fr;gap:32px;align-items:center}
.news h2{font-size:30px;letter-spacing:-.025em;margin:0 0 8px}
.news p{margin:0;color:#c7d2fe}
.news form{display:flex;gap:10px;margin:0}
.news input{flex:1;min-width:0;border:0;border-radius:999px;padding:13px 20px;font:inherit}
.news .btn{background:#fff;color:#1e1b4b!important}
.notice{border-radius:12px;padding:12px 16px;margin:20px 0 0;background:#ecfdf5;color:#065f46;font-weight:500}
.notice.err{background:#fef2f2;color:#991b1b}
.foot{border-top:1px solid var(--line);background:var(--soft);padding:48px 0 32px;color:var(--muted);font-size:14px}
.foot .cols{display:grid;grid-template-columns:2fr 1fr 1fr;gap:32px}
.foot h4{color:var(--ink);margin:0 0 10px;font-size:14px}
.foot a{display:block;text-decoration:none;margin:4px 0}
.foot a.logo{display:flex;color:var(--ink);margin:0 0 8px}
.foot a:hover{color:var(--ink)}
.foot .legal{border-top:1px solid var(--line);margin-top:32px;padding-top:20px}
.post{max-width:760px;margin:0 auto;padding:48px 24px 0}
.post .back{color:var(--muted);text-decoration:none;font-size:14px}
.post h1{font-size:46px;line-height:1.08;letter-spacing:-.035em;margin:14px 0}
.post .lead{margin-bottom:20px}
.post .wide{max-width:1000px;margin:32px auto}
.wide{max-width:1000px;margin:36px auto 8px}
.wide .cover{aspect-ratio:21/8}
.body{font-size:18px;line-height:1.8}
.body h2{font-size:26px;letter-spacing:-.02em;margin:40px 0 8px;line-height:1.25}
.body li{margin:6px 0}
.body code,.hint code{background:var(--soft);border:1px solid var(--line);padding:1px 6px;border-radius:6px;font-size:.88em}
.tools{display:flex;gap:10px;margin:28px 0 0}
.comments{border-top:1px solid var(--line);margin-top:48px;padding-top:28px}
.comments h2{font-size:22px;margin:0 0 8px}
.comment{display:flex;gap:14px;padding:16px 0;border-bottom:1px solid var(--line)}
.comment p{margin:4px 0 0}
.comment small{color:var(--muted)}
.form{display:grid;gap:14px;margin:24px 0}
.form label{display:grid;gap:6px;font-size:14px;font-weight:600}
.form input,.form textarea,.form select{border:1px solid var(--line);border-radius:12px;padding:11px 14px;font:inherit;font-weight:400;background:#fff}
.form textarea{min-height:110px;resize:vertical}
.form .row{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px}
.form .check{display:flex;align-items:center;gap:8px}
.hint{color:var(--muted);font-size:13px;margin:-6px 0 0}
.editor{max-width:860px;margin:0 auto;padding:48px 24px 0}
.editor h1{font-size:34px;letter-spacing:-.03em;margin:8px 0}
.editor textarea[name=body]{min-height:300px;font-family:ui-monospace,Menlo,monospace;font-size:14px}
@media (max-width:900px){.feature,.news{grid-template-columns:1fr}.grid{grid-template-columns:1fr}
  .cats,.search{display:none}.feature h1,.post h1{font-size:34px}.foot .cols,.form .row{grid-template-columns:1fr}}
"""


WRITERS = ("admin", "author")


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        auth_start(self)
        self.notice = None
        self.where = ("home", None)
        self.go("home")

    # ----------------------------------------------------------- navegación
    def go(self, page, arg=None, top=True):
        self.where = (page, arg)
        self.Site.set_html(self.page(), top=top)

    def say(self, text, error=False):
        self.notice = (text, error)

    def writer(self):
        return self.user is not None and self.user["role"] in WRITERS

    def Site_action(self, action):
        name, arg = action.name, action.arg
        if auth_action(self, action):
            return
        # Escribir y moderar: solo con una cuenta de autor o de administración.
        private = {"dashboard": ("dashboard", None), "write": ("write", None), "edit": ("write", number(arg)),
                   "save": ("dashboard", None), "delete": ("dashboard", None),
                   "uncomment": ("dashboard", None), "role": ("dashboard", None)}
        if name in private and not auth_require(self, *private[name], roles=WRITERS):
            return
        if name == "home":
            self.go("home")
        elif name == "dashboard":
            self.go("dashboard")
        elif name == "uncomment":
            execute("DELETE FROM comment WHERE id = ?", (number(arg),))
            self.say(T["comment_deleted"])
            self.go("dashboard", top=False)
        elif name == "role":
            if self.user["role"] == "admin" and number(arg) != self.user["id"] and action.get("role") in ROLES:
                execute("UPDATE account SET role = ? WHERE id = ?", (action.get("role"), number(arg)))
                self.say(T["role_saved"])
            self.go("dashboard", top=False)
        elif name == "category":
            self.go("category", number(arg, 0))
        elif name == "post":
            self.go("post", number(arg))
        elif name == "search":
            self.go("search", action.get("q").strip()[:80])
        elif name == "write":
            self.go("write", None)
        elif name == "edit":
            self.go("write", number(arg))
        elif name == "save":
            self.save_post(number(arg), action)
        elif name == "delete":
            self.delete_post(number(arg))
        elif name == "comment":
            self.add_comment(number(arg), action)
        elif name == "subscribe":
            self.add_subscriber(action.get("email").strip())

    # --------------------------------------------------------------- acciones
    def save_post(self, post_id, action):
        title, body = action.get("title").strip()[:160], action.get("body").strip()
        if not title or not body:
            self.say(T["need"], True)
            return self.go("write", post_id, top=False)
        data = (title, action.get("summary").strip()[:300], body,
                number(action.get("category"), 0) % len(CATEGORIES),
                number(action.get("author"), 0) % len(AUTHORS),
                1 if action.get("published") else 0)
        if post_id and query("SELECT id FROM post WHERE id = ?", (post_id,)):
            execute("UPDATE post SET title = ?, summary = ?, body = ?, category = ?, author = ?,"
                    " published = ? WHERE id = ?", data + (post_id,))
        else:
            post_id = execute("INSERT INTO post (title, summary, body, category, author, published, date)"
                              " VALUES (?, ?, ?, ?, ?, ?, ?)", data + (datetime.date.today().isoformat(),))
        self.say(T["saved"])
        self.go("post", post_id)

    def delete_post(self, post_id):
        execute("DELETE FROM comment WHERE post_id = ?", (post_id,))
        execute("DELETE FROM post WHERE id = ?", (post_id,))
        self.say(T["deleted"])
        self.go("dashboard")

    def add_comment(self, post_id, action):
        name, text = action.get("name").strip(), action.get("text").strip()
        if self.user is not None:
            name = self.user["name"]
        if not query("SELECT id FROM post WHERE id = ?", (post_id,)):
            return self.go("home")
        if not 2 <= len(name) <= 60 or not 3 <= len(text) <= 500:
            self.say(T["bad_comment"], True)
        else:
            execute("INSERT INTO comment (post_id, name, text, date) VALUES (?, ?, ?, ?)",
                    (post_id, name, text, datetime.date.today().isoformat()))
            self.say(T["thanks"])
        self.go("post", post_id, top=False)

    def add_subscriber(self, email):
        if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email) or len(email) > 120:
            self.say(T["bad_email"], True)
        else:
            execute("INSERT OR IGNORE INTO subscriber (email, date) VALUES (?, ?)",
                    (email.lower(), datetime.date.today().isoformat()))
            self.say(T["subscribed"])
        self.go(*self.where, top=False)

    # ---------------------------------------------------------------- páginas
    def page(self):
        name, arg = self.where
        main = {
            "home": self.home_html,
            "category": self.category_html,
            "search": self.search_html,
            "post": self.post_html,
            "write": self.editor_html,
            "dashboard": self.dashboard_html,
            "login": self.auth_page,
            "signup": self.auth_page,
        }[name](arg)
        self.root.title(T["brand"])
        return '<div class="site"><style>%s%s</style>%s<main>%s</main>%s</div>' % (
            CSS, AUTH_CSS, self.header_html(), main, self.footer_html())

    def auth_page(self, arg):
        return '<div class="wrap">%s</div>' % auth_html(self.where[0], self.notice_html())

    def notice_html(self):
        if not self.notice:
            return ""
        text, error = self.notice
        self.notice = None
        return '<div class="notice%s">%s</div>' % (" err" if error else "", e(text))

    def header_html(self):
        page, arg = self.where
        cats = "".join(
            link("category", e(c), i, "on" if page == "category" and arg == i else "")
            for i, c in enumerate(CATEGORIES))
        q = arg if page == "search" else ""
        return ('<header class="top"><div class="wrap bar">'
                '<a href="#" class="logo" data-action="home"><i></i>%s</a>'
                '<nav class="cats">%s</nav>'
                '<form class="search" data-action="search"><input name="q" value="%s" placeholder="%s"></form>'
                '%s</div></header>') % (e(T["brand"]), cats, e(q), e(T["search"]), self.account_html())

    def account_html(self):
        if self.user is None:
            return '<div class="who">%s%s</div>' % (link("login", e(T["login"])), link("signup", e(T["signup"]), css="btn"))
        panel = link("dashboard", e(T["dashboard"]), css="btn") if self.writer() else ""
        return '<div class="who"><span>%s</span>%s%s</div>' % (
            e(self.user["name"]), link("logout", e(T["logout"])), panel)

    def footer_html(self):
        cats = "".join(link("category", e(c), i) for i, c in enumerate(CATEGORIES))
        return ('<div class="wrap"><section class="news"><div><h2>%s</h2><p>%s</p></div>'
                '<form data-action="subscribe"><input name="email" type="email" placeholder="%s" required>'
                '<button class="btn" type="submit">%s</button></form></section></div>'
                '<footer class="foot"><div class="wrap"><div class="cols">'
                '<div><a href="#" class="logo" data-action="home"><i></i>%s</a><p>%s</p></div>'
                '<div><h4>%s</h4>%s</div><div><h4>%s</h4><p>%s</p></div></div>'
                '<div class="legal">%s</div></div></footer>') % (
            e(T["news_title"].format(T["brand"])), e(T["news_text"]), e(T["email"]), e(T["subscribe"]),
            e(T["brand"]), e(T["tagline"]), e(T["categories"]), cats, e(T["about"]), e(T["about_text"]),
            e(T["rights"].format(datetime.date.today().year, T["brand"])))

    def posts(self, where="1", args=()):
        return query("SELECT * FROM post WHERE published = 1 AND " + where +
                     " ORDER BY date DESC, id DESC", args)

    def home_html(self, arg):
        rows = self.posts()
        if not rows:
            return '<div class="wrap">%s<p class="empty">%s</p></div>' % (self.notice_html(), e(T["none"]))
        top, rest = rows[0], rows[1:]
        feature = ('<a href="#" class="feature" data-action="post" data-arg="%d">%s<div>'
                   '<span class="chip">%s</span><h1>%s</h1><p class="lead">%s</p>%s</div></a>') % (
            top["id"], cover(top["category"], True), e(CATEGORIES[top["category"] % len(CATEGORIES)]),
            e(top["title"]), e(top["summary"]), byline(top))
        return ('<div class="wrap">%s<section class="hero">%s</section>'
                '<div class="heading"><h2>%s</h2><span>%s</span></div><div class="grid">%s</div></div>') % (
            self.notice_html(), feature, e(T["latest"]), e(T["found"].format(len(rows))),
            "".join(card(p) for p in rest))

    def listing(self, title, rows):
        cards = "".join(card(p) for p in rows) or '<p class="empty">%s</p>' % e(T["none"])
        return ('<div class="wrap">%s<div class="heading"><h2>%s</h2><span>%s</span></div>'
                '<div class="grid">%s</div></div>') % (
            self.notice_html(), e(title), e(T["found"].format(len(rows))), cards)

    def category_html(self, category):
        return self.listing(CATEGORIES[category % len(CATEGORIES)],
                            self.posts("category = ?", (category % len(CATEGORIES),)))

    def search_html(self, text):
        like = "%" + text + "%"
        return self.listing(T["results"].format(text),
                            self.posts("(title LIKE ? OR summary LIKE ? OR body LIKE ?)", (like, like, like)))

    def post_html(self, post_id):
        rows = query("SELECT * FROM post WHERE id = ?", (post_id,))
        if not rows:
            self.where = ("home", None)
            return self.home_html(None)
        post = rows[0]
        comments = query("SELECT * FROM comment WHERE post_id = ? ORDER BY id", (post_id,))
        listed = "".join(
            '<div class="comment"><span class="avatar" style="background:#64748b">%s</span>'
            '<div><strong>%s</strong> <small>%s</small><p>%s</p></div></div>' % (
                e(c["name"][:1].upper()), e(c["name"]), nice_date(c["date"]), e(c["text"]))
            for c in comments) or '<p class="empty">%s</p>' % e(T["first"])
        same = self.posts("category = ? AND id != ?", (post["category"], post_id))
        ids = {p["id"] for p in same}
        related = (same + [p for p in self.posts("id != ?", (post_id,)) if p["id"] not in ids])[:3]
        draft = "" if post["published"] else ' · <span class="chip">%s</span>' % e(T["draft"])
        return ('<article class="post">%s%s<p><span class="chip">%s</span>%s</p><h1>%s</h1>'
                '<p class="lead">%s</p>%s</article>'
                '<div class="wrap"><div class="wide">%s</div></div>'
                '<div class="post"><div class="body">%s</div>'
                '<div class="tools">%s%s</div>'
                '<section class="comments"><h2>%s</h2>%s'
                '<form class="form" data-action="comment" data-arg="%d">'
                '%s'
                '<label>%s<textarea name="text" maxlength="500"></textarea></label>'
                '<div><button class="btn" type="submit">%s</button></div></form></section></div>'
                '<div class="wrap"><div class="heading"><h2>%s</h2></div><div class="grid">%s</div></div>') % (
            link("home", e(T["back"]), css="back"), self.notice_html(),
            e(CATEGORIES[post["category"] % len(CATEGORIES)]), draft, e(post["title"]), e(post["summary"]),
            byline(post), cover(post["category"], True), body_html(post["body"]),
            link("edit", e(T["edit"]), post_id, "btn light") if self.writer() else "",
            link("delete", e(T["delete"]), post_id, "btn danger") if self.writer() else "",
            e(T["comments"].format(len(comments))), listed, post_id, self.who_comments(),
            e(T["comment"]), e(T["send"]), e(T["related"]), "".join(card(p) for p in related))

    def who_comments(self):
        if self.user is not None:
            return '<p class="hint">%s</p>' % e(T["as"].format(self.user["name"]))
        return '<label>%s<input name="name" maxlength="60"></label>' % e(T["name"])

    def editor_html(self, post_id):
        rows = query("SELECT * FROM post WHERE id = ?", (post_id,)) if post_id else []
        post = rows[0] if rows else None
        value = (lambda key, default="": post[key] if post else default)

        def options(names, chosen):
            return "".join('<option value="%d"%s>%s</option>' % (i, " selected" if i == chosen else "", e(n))
                           for i, n in enumerate(names))

        return ('<div class="editor">%s%s<h1>%s</h1>'
                '<form class="form" data-action="save" data-arg="%s">'
                '<label>%s<input name="title" maxlength="160" value="%s"></label>'
                '<div class="row"><label>%s<select name="category">%s</select></label>'
                '<label>%s<select name="author">%s</select></label>'
                '<label class="check"><input type="checkbox" name="published" value="1"%s> %s</label></div>'
                '<label>%s<input name="summary" maxlength="300" value="%s"></label>'
                '<label>%s<textarea name="body">%s</textarea></label><p class="hint">%s</p>'
                '<div><button class="btn" type="submit">%s</button></div></form></div>') % (
            link("home", e(T["back"]), css="back"), self.notice_html(),
            e(T["edit_post"] if post else T["new_post"]), post["id"] if post else "",
            e(T["title"]), e(value("title")),
            e(T["category"]), options(CATEGORIES, value("category", 0)),
            e(T["author"]), options([a[0] for a in AUTHORS], value("author", 0)),
            " checked" if value("published", 1) else "", e(T["published"]),
            e(T["summary"]), e(value("summary")), e(T["body"]), e(value("body")),
            inline(T["hint"]), e(T["save"]))

    def dashboard_html(self, arg):
        count = lambda sql: query(sql)[0][0]
        stats = [(T["posts"], count("SELECT COUNT(*) FROM post WHERE published = 1")),
                 (T["drafts"], count("SELECT COUNT(*) FROM post WHERE published = 0")),
                 (T["comments_n"], count("SELECT COUNT(*) FROM comment")),
                 (T["subscribers"], count("SELECT COUNT(*) FROM subscriber"))]
        cards = "".join('<div class="stat"><small>%s</small><b>%d</b></div>' % (e(k), v) for k, v in stats)
        posts = "".join(
            '<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td class="num">%d</td><td><div class="acts">%s%s</div></td></tr>' % (
                link("post", e(p["title"]), p["id"]), e(CATEGORIES[p["category"] % len(CATEGORIES)]),
                e(T["published"] if p["published"] else T["draft"]), nice_date(p["date"]), p["n"],
                link("edit", e(T["edit"]), p["id"]), link("delete", e(T["delete"]), p["id"], "del"))
            for p in query("SELECT post.*, (SELECT COUNT(*) FROM comment WHERE post_id = post.id) AS n"
                           " FROM post ORDER BY date DESC, id DESC"))
        comments = "".join(
            '<tr><td><strong>%s</strong><br><small>%s</small></td><td>%s</td><td><div class="acts">%s</div></td></tr>' % (
                e(c["name"]), e(c["title"]), e(c["text"][:120]), link("uncomment", e(T["delete"]), c["id"], "del"))
            for c in query("SELECT comment.*, post.title FROM comment JOIN post ON post.id = comment.post_id"
                           " ORDER BY comment.id DESC LIMIT 8")) or '<tr><td>%s</td></tr>' % e(T["first"])
        users = ""
        if self.user["role"] == "admin":
            names = {"admin": T["role_admin"], "author": T["role_author"], "user": T["role_user"]}
            users = '<div class="panel"><h3>%s</h3><table><tr><th>%s</th><th>%s</th></tr>%s</table></div>' % (
                e(T["users"]), e(T["u_name"]), e(T["role"]), "".join(
                    '<tr><td><strong>%s</strong><br><small>%s</small></td><td>%s</td></tr>' % (
                        e(u["name"]), e(u["email"]),
                        e(names[u["role"]]) if u["id"] == self.user["id"] else
                        '<form data-action="role" data-arg="%d"><select name="role">%s</select>'
                        '<button class="btn small light" type="submit">%s</button></form>' % (
                            u["id"], "".join('<option value="%s"%s>%s</option>' % (
                                r, " selected" if r == u["role"] else "", e(names[r])) for r in ROLES), e(T["change"])))
                    for u in query("SELECT * FROM account ORDER BY id")))
        return ('<div class="wrap">%s<div class="heading"><h2>%s</h2>%s</div><div class="stats">%s</div>'
                '<div class="panel"><h3>%s</h3><table><tr><th>%s</th><th>%s</th><th>%s</th><th>%s</th>'
                '<th class="num">%s</th><th></th></tr>%s</table></div>'
                '<div class="cols2"><div class="panel"><h3>%s</h3><table>%s</table></div>%s</div></div>') % (
            self.notice_html(), e(T["dash_title"]), link("write", e(T["new_post"]), css="btn"), cards,
            e(T["posts"]), e(T["title"]), e(T["category"]), e(T["status"]), e(T["date"]), e(T["comments_n"]), posts,
            e(T["recent"]), comments, users)
''';

// ------------------------------------------------------------------ tienda
TkExample _siteShop(String Function(String) t) {
  final brand = 'Voltia';
  final cats = [
    t(markTr('Portátiles')),
    t(markTr('Móviles')),
    t(markTr('Audio')),
    t(markTr('Relojes')),
    t(markTr('Fotografía')),
    t(markTr('Gaming')),
  ];
  final phrases = _phrases({
    ..._authPhrases(t),
    'account': t(markTr('Mi cuenta')),
    'my_orders': t(markTr('Mis pedidos')),
    'no_my_orders': t(markTr('Aún no has hecho ningún pedido.')),
    'shop_dash': t(markTr('Panel de la tienda')),
    'sales': t(markTr('Ventas')),
    'pending': t(markTr('Pendientes')),
    'customers': t(markTr('Clientes')),
    'low': t(markTr('Poco stock')),
    'by_cat': t(markTr('Ventas por categoría')),
    'products': t(markTr('Productos')),
    'restock': t(markTr('Reponer')),
    'restocked': t(markTr('Stock actualizado.')),
    'stock': t(markTr('Stock')),
    'price': t(markTr('Precio')),
    'sold': t(markTr('Vendidos')),
    'units': t(markTr('{0} uds.')),
    'buyer': t(markTr('Comprarás como {0} ({1}).')),
    'brand': brand,
    'promo': t(
      markTr('Envío gratis en pedidos de más de 50 € · Devolución en 30 días'),
    ),
    'search': t(markTr('Buscar productos…')),
    'cart': t(markTr('Carrito')),
    'all': t(markTr('Todo')),
    'hero_tag': t(markTr('Novedad')),
    'hero_text': t(
      markTr('Pantalla de 14 pulgadas, 18 horas de batería y menos de 1,3 kg.'),
    ),
    'buy_now': t(markTr('Comprar ahora')),
    'see': t(markTr('Ver detalles')),
    'shop_by': t(markTr('Compra por categoría')),
    'deals': t(markTr('Ofertas de la semana')),
    'best': t(markTr('Lo más vendido')),
    'add': t(markTr('Añadir')),
    'add_cart': t(markTr('Añadir al carrito')),
    'added': t(markTr('«{0}» se ha añadido al carrito.')),
    'reviews': t(markTr('{0} opiniones')),
    'save': t(markTr('Ahorras {0}')),
    'in_stock': t(markTr('En stock: {0} unidades')),
    'low_stock': t(markTr('¡Solo quedan {0}!')),
    'no_stock': t(markTr('Agotado')),
    'only': t(markTr('Solo quedan {0} unidades de «{1}».')),
    'qty': t(markTr('Cantidad')),
    'b1': t(markTr('Envío en 24/48 h')),
    'b1t': t(markTr('Gratis desde 50 €')),
    'b2': t(markTr('Devolución fácil')),
    'b2t': t(markTr('30 días para pensarlo')),
    'b3': t(markTr('Pago seguro')),
    'b3t': t(markTr('Tus datos, cifrados')),
    'b4': t(markTr('2 años de garantía')),
    'b4t': t(markTr('En todos los productos')),
    'sort': t(markTr('Ordenar')),
    'sort_pop': t(markTr('Más vendidos')),
    'sort_low': t(markTr('Precio: de menor a mayor')),
    'sort_high': t(markTr('Precio: de mayor a menor')),
    'results': t(markTr('Resultados para «{0}»')),
    'count': t(markTr('{0} productos')),
    'none': t(markTr('No hay productos que coincidan.')),
    'home': t(markTr('Inicio')),
    'your_cart': t(markTr('Tu carrito')),
    'empty': t(markTr('Tu carrito está vacío.')),
    'keep': t(markTr('Seguir comprando')),
    'remove': t(markTr('Quitar')),
    'subtotal': t(markTr('Subtotal')),
    'shipping': t(markTr('Envío')),
    'free': t(markTr('Gratis')),
    'total': t(markTr('Total')),
    'checkout': t(markTr('Finalizar compra')),
    'details': t(markTr('Datos de envío')),
    'name': t(markTr('Nombre y apellidos')),
    'email': t(markTr('Correo electrónico')),
    'address': t(markTr('Dirección')),
    'city': t(markTr('Ciudad')),
    'zip': t(markTr('Código postal')),
    'payment': t(markTr('Forma de pago')),
    'pay_card': t(markTr('Tarjeta (simulado)')),
    'pay_transfer': t(markTr('Transferencia')),
    'pay_cod': t(markTr('Contra reembolso')),
    'place': t(markTr('Pagar {0}')),
    'demo': t(markTr('Es una tienda de ejemplo: no se cobra nada.')),
    'bad_order': t(
      markTr(
        'Revise sus datos: nombre, un correo válido, dirección, ciudad y código postal.',
      ),
    ),
    'thanks': t(markTr('¡Gracias, {0}!')),
    'order_ok': t(
      markTr(
        'Su pedido n.º {0} está confirmado. Le enviaremos un correo a {1}.',
      ),
    ),
    'orders': t(markTr('Pedidos')),
    'find': t(markTr('Buscar')),
    'order': t(markTr('Pedido')),
    'date': t(markTr('Fecha')),
    'customer': t(markTr('Cliente')),
    'status': t(markTr('Estado')),
    'new': t(markTr('Nuevo')),
    'shipped': t(markTr('Enviado')),
    'mark': t(markTr('Marcar como enviado')),
    'no_orders': t(markTr('Aún no hay pedidos.')),
    'help': t(markTr('Ayuda')),
    'about': t(markTr('Sobre Voltia')),
    'about_text': t(
      markTr(
        'Una tienda de ejemplo hecha con DMarlon Studio y Flask: el catálogo, los carritos y los pedidos se guardan en SQLite.',
      ),
    ),
    'rights': t(markTr('© {0} {1}. Todos los derechos reservados.')),
    'offer': t(markTr('Oferta')),
  });
  // (nombre, categoría, dibujo, color, precio, antes, estrellas, opiniones, stock, descripción)
  final products = [
    (
      'Voltia Book 14',
      0,
      'laptop',
      '#64748b',
      99900,
      119900,
      4.7,
      412,
      18,
      t(
        markTr(
          'Portátil ligero con pantalla de 14 pulgadas, 16 GB de memoria y 18 horas de batería.',
        ),
      ),
    ),
    (
      'Nimbus Pro 16',
      0,
      'laptop',
      '#1e293b',
      179900,
      0,
      4.8,
      208,
      6,
      t(
        markTr(
          'Portátil de 16 pulgadas para crear: pantalla de alta precisión y procesador de 12 núcleos.',
        ),
      ),
    ),
    (
      'Slate 11',
      0,
      'tablet',
      '#a1a1aa',
      44900,
      52900,
      4.5,
      530,
      25,
      t(
        markTr(
          'Tableta de 11 pulgadas con lápiz, ideal para tomar notas y dibujar.',
        ),
      ),
    ),
    (
      'Aria X2',
      1,
      'phone',
      '#6366f1',
      79900,
      0,
      4.6,
      980,
      30,
      t(
        markTr(
          'Móvil con triple cámara, pantalla de 120 Hz y carga rápida de 65 W.',
        ),
      ),
    ),
    (
      'Aria Lite',
      1,
      'phone',
      '#10b981',
      29900,
      34900,
      4.3,
      1450,
      40,
      t(
        markTr(
          'Lo esencial, bien hecho: batería para dos días y una cámara sorprendente.',
        ),
      ),
    ),
    (
      'Pulse ANC',
      2,
      'headphones',
      '#0f172a',
      24900,
      29900,
      4.8,
      2210,
      3,
      t(
        markTr(
          'Auriculares inalámbricos con cancelación de ruido y 40 horas de autonomía.',
        ),
      ),
    ),
    (
      'Echo Mini',
      2,
      'speaker',
      '#f97316',
      5900,
      7900,
      4.4,
      760,
      50,
      t(
        markTr('Altavoz portátil resistente al agua con sonido de 360 grados.'),
      ),
    ),
    (
      'Orbit Watch S',
      3,
      'watch',
      '#0ea5e9',
      32900,
      0,
      4.6,
      640,
      14,
      t(
        markTr(
          'Reloj inteligente con GPS, pulsómetro y pantalla siempre activa.',
        ),
      ),
    ),
    (
      'Orbit Fit',
      3,
      'watch',
      '#ec4899',
      8900,
      11900,
      4.2,
      1120,
      60,
      t(
        markTr(
          'Pulsera de actividad con seguimiento del sueño y 14 días de batería.',
        ),
      ),
    ),
    (
      'Lumen Z50',
      4,
      'camera',
      '#334155',
      89900,
      99900,
      4.9,
      185,
      5,
      t(
        markTr(
          'Cámara sin espejo de 26 megapíxeles con vídeo 4K y estabilizador.',
        ),
      ),
    ),
    (
      'Lumen Go',
      4,
      'camera',
      '#eab308',
      19900,
      0,
      4.1,
      340,
      22,
      t(markTr('Cámara compacta para viajar, con zoom de 10 aumentos.')),
    ),
    (
      'Arcade Pad',
      5,
      'gamepad',
      '#8b5cf6',
      5900,
      6900,
      4.5,
      890,
      35,
      t(
        markTr(
          'Mando inalámbrico con vibración y batería recargable para PC y móvil.',
        ),
      ),
    ),
  ];
  final seed = [
    for (final (name, cat, art, color, price, old, stars, reviews, stock, desc)
        in products)
      '    (${_py(name)}, $cat, ${_py(art)}, ${_py(color)}, $price, $old, $stars, $reviews, $stock,\n'
          '     ${_py(desc)}),',
  ].join('\n');
  final code =
      '''import datetime
import html
import re
import sqlite3
from contextlib import closing

DB = "tienda.sqlite"
$phrases
CATEGORIES = [${cats.map(_py).join(', ')}]
# (nombre, categoría, dibujo, color, precio en céntimos, antes, estrellas, opiniones, stock, descripción)
SEED = [
$seed
]
$_authCore$_shopCore''';
  return TkExample(
    'web_shop',
    t(markTr('Tienda web')),
    t(
      markTr(
        'Una tienda de electrónica que parece una tienda: portada con ofertas, categorías, buscador, ficha de producto, carrito, cuentas con login y registro, pago simulado, «Mi cuenta» con los pedidos y un panel de ventas y stock, guardado en SQLite.',
      ),
    ),
    _siteDesign(
      brand,
      '<h1>$brand</h1><p>${t(markTr('La página se genera al abrirla (form_create).'))}</p>',
    ),
    code,
  );
}

const _shopCore = r'''
e = html.escape
SHIPPING, FREE_FROM = 495, 5000


def query(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        db.row_factory = sqlite3.Row
        return db.execute(sql, args).fetchall()


def execute(sql, args=()):
    with closing(sqlite3.connect(DB)) as db:
        with db:
            return db.execute(sql, args).lastrowid


def create_tables():
    execute("""CREATE TABLE IF NOT EXISTS product (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, category INTEGER NOT NULL, art TEXT NOT NULL,
        color TEXT NOT NULL, price INTEGER NOT NULL, old_price INTEGER NOT NULL DEFAULT 0,
        stars REAL NOT NULL DEFAULT 0, reviews INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0, sold INTEGER NOT NULL DEFAULT 0, description TEXT NOT NULL DEFAULT '')""")
    execute("""CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY, user_id INTEGER, date TEXT NOT NULL, name TEXT NOT NULL, email TEXT NOT NULL,
        address TEXT NOT NULL, payment TEXT NOT NULL, total INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'new')""")
    execute("""CREATE TABLE IF NOT EXISTS order_line (
        id INTEGER PRIMARY KEY, order_id INTEGER NOT NULL, product_id INTEGER NOT NULL,
        name TEXT NOT NULL, qty INTEGER NOT NULL, price INTEGER NOT NULL)""")
    if query("SELECT COUNT(*) AS n FROM product")[0]["n"]:
        return
    for i, row in enumerate(SEED):
        execute("INSERT INTO product (name, category, art, color, price, old_price, stars, reviews, stock,"
                " description, sold) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", row + ((len(SEED) - i) * 37 % 101,))


def number(text, default=None):
    try:
        return int(text)
    except (TypeError, ValueError):
        return default


def money(cents):
    text = "{:,.2f}".format(cents / 100)
    return text.replace(",", "_").replace(".", ",").replace("_", ".") + " €"


def stars(value):
    full = int(round(value))
    return '<span class="stars" title="%.1f">%s<i>%s</i></span>' % (value, "★" * full, "★" * (5 - full))


def link(action, label, arg="", css=""):
    return '<a href="#" data-action="%s" data-arg="%s"%s>%s</a>' % (
        action, e(str(arg)), ' class="%s"' % css if css else "", label)


def art(kind, color, size=""):
    """Dibujo del producto en SVG (sin imágenes)."""
    c = e(color)
    shapes = {
        "laptop": '<rect x="40" y="30" width="120" height="78" rx="6" fill="%s"/><rect x="47" y="37" width="106" height="64" rx="3" fill="#cbd5e1"/>'
                  '<path d="M26 112h148l-10 12H36z" fill="%s"/><rect x="88" y="112" width="24" height="3" rx="1.5" fill="#94a3b8"/>',
        "tablet": '<rect x="42" y="28" width="116" height="96" rx="10" fill="%s"/><rect x="50" y="36" width="100" height="80" rx="4" fill="#e2e8f0"/>'
                  '<rect x="60" y="48" width="44" height="6" rx="3" fill="%s" opacity=".5"/><rect x="60" y="62" width="70" height="4" rx="2" fill="#94a3b8"/>',
        "phone": '<rect x="70" y="18" width="60" height="118" rx="12" fill="%s"/><rect x="76" y="26" width="48" height="102" rx="7" fill="#e2e8f0"/>'
                 '<rect x="90" y="30" width="20" height="5" rx="2.5" fill="%s"/>',
        "headphones": '<path d="M52 92v-14a48 48 0 0 1 96 0v14" fill="none" stroke="%s" stroke-width="10" stroke-linecap="round"/>'
                      '<rect x="40" y="84" width="28" height="44" rx="12" fill="%s"/><rect x="132" y="84" width="28" height="44" rx="12" fill="%s"/>',
        "speaker": '<rect x="62" y="22" width="76" height="112" rx="22" fill="%s"/><circle cx="100" cy="94" r="24" fill="#1f2937"/>'
                   '<circle cx="100" cy="94" r="9" fill="%s"/><circle cx="100" cy="48" r="9" fill="#1f2937"/>',
        "watch": '<rect x="84" y="12" width="32" height="132" rx="10" fill="%s" opacity=".75"/><rect x="66" y="44" width="68" height="70" rx="18" fill="#111827"/>'
                 '<rect x="73" y="51" width="54" height="56" rx="12" fill="%s"/><text x="100" y="85" text-anchor="middle" font-size="16" font-weight="700" fill="#fff" font-family="system-ui">10:09</text>',
        "camera": '<rect x="34" y="46" width="132" height="84" rx="12" fill="%s"/><rect x="58" y="34" width="36" height="16" rx="4" fill="%s"/>'
                  '<circle cx="104" cy="88" r="30" fill="#0f172a"/><circle cx="104" cy="88" r="18" fill="#475569"/><circle cx="110" cy="82" r="5" fill="#cbd5e1"/>',
        "gamepad": '<path d="M48 64h104c18 0 28 30 26 52-2 14-16 18-26 8l-14-14H62l-14 14c-10 10-24 6-26-8-2-22 8-52 26-52z" fill="%s"/>'
                   '<path d="M64 82h6v-6h8v6h6v8h-6v6h-8v-6h-6z" fill="#fff"/><circle cx="128" cy="80" r="5" fill="#fff"/>'
                   '<circle cx="140" cy="92" r="5" fill="#fff"/><circle cx="116" cy="92" r="5" fill="%s" opacity=".4"/>',
    }
    body = shapes.get(kind, shapes["phone"])
    return '<svg class="art%s" viewBox="0 0 200 150" role="img">%s</svg>' % (
        size, body.replace("%s", c))


def product_card(p):
    badge = ""
    if p["old_price"]:
        badge = '<span class="badge">-%d%%</span>' % round(100 - p["price"] * 100 / p["old_price"])
    old = '<s>%s</s>' % money(p["old_price"]) if p["old_price"] else ""
    return ('<div class="pcard">%s<a href="#" class="pimg" data-action="product" data-arg="%d">%s</a>'
            '<span class="pcat">%s</span>%s<div class="rate">%s <small>(%d)</small></div>'
            '<div class="buy"><div class="price"><b>%s</b>%s</div>%s</div></div>') % (
        badge, p["id"], art(p["art"], p["color"]), e(CATEGORIES[p["category"]]),
        link("product", "<h3>%s</h3>" % e(p["name"]), p["id"], "pname"), stars(p["stars"]), p["reviews"],
        money(p["price"]), old,
        link("add", e(T["add"]), p["id"], "btn small") if p["stock"] > 0 else '<span class="out">%s</span>' % e(T["no_stock"]))


CSS = """
.shop{--ink:#0f172a;--muted:#64748b;--line:#e2e8f0;--soft:#f1f5f9;--brand:#2563eb;--accent:#f97316;
  font:15px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;color:var(--ink);background:#fff;min-height:100vh}
.shop *{box-sizing:border-box}
.shop a{color:inherit;text-decoration:none}
.wrap{max-width:1240px;margin:0 auto;padding:0 24px}
.promo{background:var(--ink);color:#e2e8f0;font-size:13px;text-align:center;padding:8px 16px}
.head{display:flex;align-items:center;gap:28px;height:76px}
.logo{display:flex;align-items:center;gap:8px;font-size:24px;font-weight:800;letter-spacing:-.03em}
.logo svg{width:30px;height:30px}
.find{flex:1;display:flex;margin:0}
.find input{flex:1;min-width:0;border:2px solid var(--ink);border-right:0;border-radius:10px 0 0 10px;padding:10px 16px;font:inherit}
.find button{border:0;background:var(--ink);color:#fff;border-radius:0 10px 10px 0;padding:0 22px;font:inherit;font-weight:600;cursor:pointer}
.cartbtn{display:flex;align-items:center;gap:8px;font-weight:600}
.cartbtn span{background:var(--accent);color:#fff;border-radius:999px;min-width:22px;height:22px;display:inline-flex;align-items:center;justify-content:center;font-size:12px;padding:0 6px}
.nav{border-top:1px solid var(--line);border-bottom:1px solid var(--line)}
.nav .wrap{display:flex;gap:6px;overflow-x:auto}
.nav a{padding:12px 14px;font-weight:600;font-size:14px;color:var(--muted);border-bottom:2px solid transparent}
.nav a:hover,.nav a.on{color:var(--ink);border-color:var(--brand)}
.hero{margin:28px 0;border-radius:24px;overflow:hidden;color:#fff;
  background:radial-gradient(circle at 75% 40%,#3b82f6 0,transparent 45%),linear-gradient(120deg,#0f172a,#1e3a8a);
  display:grid;grid-template-columns:1fr 1fr;align-items:center;min-height:380px}
.hero .copy{padding:48px 56px}
.hero .tag{display:inline-block;background:var(--accent);border-radius:999px;font-size:12px;font-weight:700;padding:4px 12px;text-transform:uppercase;letter-spacing:.06em}
.hero h1{font-size:54px;line-height:1.02;letter-spacing:-.04em;margin:16px 0 12px}
.hero p{color:#cbd5e1;font-size:18px;margin:0 0 8px}
.hero .from{font-size:22px;font-weight:700;margin:18px 0 24px}
.hero .from s{color:#94a3b8;font-weight:400;font-size:16px;margin-left:10px}
.hero .art{width:100%;max-width:520px;filter:drop-shadow(0 30px 40px rgba(0,0,0,.45))}
.btn{display:inline-block;border:0;border-radius:10px;background:var(--brand);color:#fff!important;padding:12px 22px;font:inherit;font-weight:700;cursor:pointer}
.btn.light{background:#fff;color:var(--ink)!important}
.btn.ghost{background:transparent;color:var(--ink)!important;border:1px solid var(--line)}
.btn.small{padding:8px 14px;font-size:13px}
.btn.wide{display:block;width:100%;text-align:center}
.title{display:flex;justify-content:space-between;align-items:baseline;margin:44px 0 18px}
.title h2{font-size:26px;letter-spacing:-.025em;margin:0}
.title span{color:var(--muted);font-size:14px}
.cats{display:grid;grid-template-columns:repeat(6,minmax(0,1fr));gap:16px}
.cat{background:var(--soft);border-radius:18px;padding:18px 12px 14px;text-align:center;font-weight:600;font-size:14px;transition:transform .15s}
.cat:hover{transform:translateY(-3px)}
.cat .art{height:84px}
.grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:22px}
.pcard{position:relative;border:1px solid var(--line);border-radius:18px;padding:14px 16px 16px;display:flex;flex-direction:column;gap:4px;transition:box-shadow .15s}
.pcard:hover{box-shadow:0 12px 30px rgba(15,23,42,.10)}
.pimg{display:block;background:var(--soft);border-radius:12px;margin-bottom:8px}
.art{display:block;width:100%;height:auto}
.badge{position:absolute;top:22px;left:24px;background:#dc2626;color:#fff;font-size:12px;font-weight:700;border-radius:6px;padding:2px 8px;z-index:1}
.pcat{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.06em;font-weight:600}
.pcard h3{font-size:16px;margin:0}
.pname:hover h3{color:var(--brand)}
.rate{font-size:13px;color:var(--muted)}
.stars{color:#f59e0b;letter-spacing:1px}
.stars i{color:#cbd5e1;font-style:normal}
.buy{display:flex;align-items:flex-end;justify-content:space-between;gap:8px;margin-top:auto;padding-top:8px}
.price b{font-size:19px;display:block}
.price s{color:var(--muted);font-size:13px}
.out{color:#b91c1c;font-weight:600;font-size:13px}
.perks{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin:48px 0;background:var(--soft);border-radius:18px;padding:22px 26px}
.perks div{display:flex;gap:12px;align-items:center}
.perks i{flex:none;width:40px;height:40px;border-radius:12px;background:#dbeafe;display:inline-flex;align-items:center;justify-content:center;font-style:normal;font-size:19px}
.perks b{display:block;font-size:14px}
.perks small{color:var(--muted)}
.notice{border-radius:12px;padding:12px 16px;margin:18px 0 0;background:#ecfdf5;color:#065f46;font-weight:600}
.notice.err{background:#fef2f2;color:#991b1b}
.crumbs{color:var(--muted);font-size:13px;margin:22px 0}
.crumbs a:hover{color:var(--ink)}
.detail{display:grid;grid-template-columns:1.1fr 1fr;gap:48px;align-items:start}
.detail .stage{background:var(--soft);border-radius:24px;padding:40px}
.detail h1{font-size:38px;letter-spacing:-.03em;margin:6px 0 8px}
.detail .now{font-size:34px;font-weight:800;margin:18px 0 0}
.detail .was{color:var(--muted)}
.detail .was s{margin-right:10px}
.detail .was b{color:#16a34a}
.stock{margin:14px 0;font-weight:600;color:#16a34a}
.stock.low{color:#ea580c}
.stock.none{color:#b91c1c}
.addform{display:flex;gap:12px;align-items:center;margin:18px 0}
.addform select{border:1px solid var(--line);border-radius:10px;padding:11px 12px;font:inherit}
.ticks{list-style:none;padding:0;margin:22px 0;display:grid;gap:8px;color:var(--muted)}
.ticks li:before{content:"✓";color:#16a34a;font-weight:800;margin-right:10px}
.desc{border-top:1px solid var(--line);padding-top:18px;font-size:16px}
.layout{display:grid;grid-template-columns:1fr 360px;gap:32px;align-items:start;margin-bottom:56px}
.lines{border:1px solid var(--line);border-radius:18px}
.line{display:grid;grid-template-columns:96px 1fr auto auto;gap:18px;align-items:center;padding:16px;border-bottom:1px solid var(--line)}
.line:last-child{border-bottom:0}
.line .pimg{margin:0}
.line small{color:var(--muted)}
.qty{display:flex;align-items:center;border:1px solid var(--line);border-radius:10px}
.qty a{padding:6px 12px;font-weight:700}
.qty span{min-width:28px;text-align:center;font-weight:600}
.line .del{color:var(--muted);font-size:13px;text-decoration:underline}
.box{border:1px solid var(--line);border-radius:18px;padding:22px;position:sticky;top:16px}
.box h3{margin:0 0 12px}
.sum{display:flex;justify-content:space-between;margin:8px 0;color:var(--muted)}
.sum.total{color:var(--ink);font-size:20px;font-weight:800;border-top:1px solid var(--line);padding-top:14px;margin-top:14px}
.form{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.form label{display:grid;gap:6px;font-size:13px;font-weight:600}
.form .full{grid-column:1/-1}
.form input,.form select{border:1px solid var(--line);border-radius:10px;padding:11px 13px;font:inherit;font-weight:400}
.muted{color:var(--muted);font-size:13px}
.done{max-width:620px;margin:64px auto;text-align:center}
.done .ok{width:72px;height:72px;border-radius:50%;background:#dcfce7;color:#16a34a;font-size:36px;display:inline-flex;align-items:center;justify-content:center}
.done h1{font-size:38px;letter-spacing:-.03em;margin:18px 0 8px}
table.orders{width:100%;border-collapse:collapse;margin-bottom:56px}
.orders th,.orders td{text-align:left;padding:12px;border-bottom:1px solid var(--line)}
.orders th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.05em}
.pill{border-radius:999px;padding:3px 10px;font-size:12px;font-weight:700;background:#fef3c7;color:#92400e}
.pill.shipped{background:#dcfce7;color:#166534}
.empty{color:var(--muted);padding:32px 0}
.foot{background:var(--ink);color:#94a3b8;padding:48px 0 28px;font-size:14px;margin-top:24px}
.foot .cols{display:grid;grid-template-columns:2fr 1fr 1fr;gap:32px}
.foot h4{color:#fff;margin:0 0 12px}
.foot a{display:block;margin:5px 0}
.foot a:hover{color:#fff}
.foot .logo{color:#fff}
.foot a.logo{display:flex}
.foot .legal{border-top:1px solid #1e293b;margin-top:32px;padding-top:18px}
@media (max-width:980px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.cats{grid-template-columns:repeat(3,minmax(0,1fr))}
  .hero,.detail,.layout,.foot .cols{grid-template-columns:1fr}.perks{grid-template-columns:1fr 1fr}.hero h1{font-size:38px}
  .cartbtn b{display:none}}
"""

LOGO = ('<svg viewBox="0 0 32 32"><rect width="32" height="32" rx="9" fill="#2563eb"/>'
        '<path d="M18 5 9 18h6l-2 9 9-13h-6z" fill="#fff"/></svg>')


class Form1(FormDesign):
    def form_create(self):
        create_tables()
        auth_start(self)
        self.cart = {}
        self.notice = None
        self.last_order = None
        self.where = ("home", None)
        self.go("home")

    # ----------------------------------------------------------- navegación
    def go(self, page, arg=None, top=True):
        self.where = (page, arg)
        self.Site.set_html(self.page(), top=top)

    def say(self, text, error=False):
        self.notice = (text, error)

    def Site_action(self, action):
        name, arg = action.name, action.arg
        if auth_action(self, action):
            return
        # Comprar pide una cuenta; el panel, la de administración.
        if name in ("checkout", "pay", "account") and not auth_require(self, "checkout" if name == "pay" else name):
            return
        if name in ("dashboard", "ship", "restock") and not auth_require(self, "dashboard", roles=("admin",)):
            return
        if name in ("home", "cart", "checkout", "account", "dashboard"):
            self.go(name)
        elif name == "restock":
            more = number(action.get("qty"), 0)
            if 0 < more <= 1000:
                execute("UPDATE product SET stock = stock + ? WHERE id = ?", (more, number(arg)))
                self.say(T["restocked"])
            self.go("dashboard", top=False)
        elif name == "category":
            self.go("category", (number(arg, 0), action.get("sort", "pop")))
        elif name == "search":
            self.go("search", action.get("q").strip()[:80])
        elif name == "product":
            self.go("product", number(arg))
        elif name == "add":
            self.add_to_cart(number(arg), number(action.get("qty", "1"), 1))
        elif name == "plus":
            self.add_to_cart(number(arg), 1, stay=True)
        elif name == "minus":
            self.set_qty(number(arg), self.cart.get(number(arg), 0) - 1)
        elif name == "remove":
            self.set_qty(number(arg), 0)
        elif name == "pay":
            self.place_order(action)
        elif name == "ship":
            execute("UPDATE orders SET status = 'shipped' WHERE id = ?", (number(arg),))
            self.go("dashboard", top=False)

    # ---------------------------------------------------------------- carrito
    def product(self, product_id):
        rows = query("SELECT * FROM product WHERE id = ?", (product_id,))
        return rows[0] if rows else None

    def add_to_cart(self, product_id, qty, stay=False):
        p = self.product(product_id)
        if p is None or qty < 1:
            return self.go("home")
        want = self.cart.get(product_id, 0) + min(qty, 99)
        if want > p["stock"]:
            self.say(T["only"].format(p["stock"], p["name"]), True)
        else:
            self.cart[product_id] = want
            if not stay:
                self.say(T["added"].format(p["name"]))
        self.go(*(("cart", None) if stay else self.where), top=False)

    def set_qty(self, product_id, qty):
        if qty <= 0:
            self.cart.pop(product_id, None)
        elif product_id in self.cart:
            self.cart[product_id] = qty
        self.go("cart", top=False)

    def lines(self):
        out = []
        for product_id, qty in list(self.cart.items()):
            p = self.product(product_id)
            if p is None:
                self.cart.pop(product_id)
            else:
                out.append((p, qty))
        return out

    def totals(self):
        subtotal = sum(p["price"] * qty for p, qty in self.lines())
        shipping = 0 if subtotal >= FREE_FROM or not subtotal else SHIPPING
        return subtotal, shipping, subtotal + shipping

    def place_order(self, action):
        lines = self.lines()
        if not lines:
            return self.go("cart")
        name, email = action.get("name").strip()[:80], self.user["email"]
        address = ", ".join(x for x in (action.get("address").strip()[:160], action.get("zip").strip()[:10],
                                        action.get("city").strip()[:80]) if x)
        ok = (len(name) >= 2 and re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email)
              and action.get("address").strip() and action.get("city").strip() and action.get("zip").strip())
        if not ok:
            self.say(T["bad_order"], True)
            return self.go("checkout", top=False)
        for p, qty in lines:
            if qty > p["stock"]:
                self.say(T["only"].format(p["stock"], p["name"]), True)
                return self.go("cart")
        payment = {"card": T["pay_card"], "transfer": T["pay_transfer"], "cod": T["pay_cod"]}.get(
            action.get("payment"), T["pay_card"])
        total = self.totals()[2]
        order_id = execute("INSERT INTO orders (user_id, date, name, email, address, payment, total)"
                           " VALUES (?, ?, ?, ?, ?, ?, ?)", (self.user["id"], datetime.datetime.now().strftime(
                               "%Y-%m-%d %H:%M"), name, email, address, payment, total))
        for p, qty in lines:
            execute("INSERT INTO order_line (order_id, product_id, name, qty, price) VALUES (?, ?, ?, ?, ?)",
                    (order_id, p["id"], p["name"], qty, p["price"]))
            execute("UPDATE product SET stock = stock - ?, sold = sold + ? WHERE id = ?", (qty, qty, p["id"]))
        self.cart = {}
        self.last_order = (order_id, name, email, total)
        self.go("done")

    # ---------------------------------------------------------------- páginas
    def page(self):
        page, arg = self.where
        if page in ("login", "signup"):
            main = auth_html(page, self.notice_html())
        else:
            main = self.notice_html() + getattr(self, "page_" + page)(arg)
        self.root.title(T["brand"])
        return '<div class="shop"><style>%s%s</style>%s<main class="wrap">%s</main>%s</div>' % (
            CSS, AUTH_CSS, self.header_html(), main, self.footer_html())

    def notice_html(self):
        if not self.notice:
            return ""
        text, error = self.notice
        self.notice = None
        return '<div class="notice%s">%s</div>' % (" err" if error else "", e(text))

    def header_html(self):
        page, arg = self.where
        count = sum(self.cart.values())
        current = arg[0] if page == "category" else None
        nav = link("home", e(T["all"]), css="on" if page == "home" else "") + "".join(
            link("category", e(c), i, "on" if current == i else "") for i, c in enumerate(CATEGORIES))
        q = arg if page == "search" else ""
        return ('<div class="promo">%s</div><header class="wrap head">'
                '<a href="#" class="logo" data-action="home">%s%s</a>'
                '<form class="find" data-action="search"><input name="q" value="%s" placeholder="%s">'
                '<button type="submit">%s</button></form>'
                '%s<a href="#" class="cartbtn" data-action="cart">&#x1F6D2; <b>%s</b> <span>%d</span></a></header>'
                '<nav class="nav"><div class="wrap">%s</div></nav>') % (
            e(T["promo"]), LOGO, e(T["brand"]), e(q), e(T["search"]), e(T["find"]), self.account_html(), e(T["cart"]), count, nav)

    def account_html(self):
        if self.user is None:
            return '<div class="who">%s%s</div>' % (link("login", e(T["login"])), link("signup", e(T["signup"])))
        panel = link("dashboard", e(T["dashboard"]), css="btn small") if self.user["role"] == "admin" else ""
        return '<div class="who">%s%s%s</div>' % (
            link("account", e(self.user["name"])), link("logout", e(T["logout"])), panel)

    def footer_html(self):
        cats = "".join(link("category", e(c), i) for i, c in enumerate(CATEGORIES))
        return ('<footer class="foot"><div class="wrap"><div class="cols">'
                '<div><a href="#" class="logo" data-action="home">%s%s</a><p>%s</p></div>'
                '<div><h4>%s</h4>%s</div><div><h4>%s</h4>%s%s</div></div>'
                '<div class="legal">%s</div></div></footer>') % (
            LOGO, e(T["brand"]), e(T["about_text"]), e(T["shop_by"]), cats, e(T["help"]),
            link("account", e(T["account"])), link("dashboard", e(T["shop_dash"])),
            e(T["rights"].format(datetime.date.today().year, T["brand"])))

    def perks(self):
        icons = ["&#x1F69A;", "&#x21A9;", "&#x1F512;", "&#x1F6E1;"]
        return '<section class="perks">%s</section>' % "".join(
            '<div><i>%s</i><span><b>%s</b><small>%s</small></span></div>' % (icon, e(T["b%d" % n]), e(T["b%dt" % n]))
            for n, icon in enumerate(icons, 1))

    def page_home(self, arg):
        hero = self.product(1) or query("SELECT * FROM product LIMIT 1")[0]
        tiles = "".join(
            '<a href="#" class="cat" data-action="category" data-arg="%d">%s%s</a>' % (
                i, art(p["art"], p["color"]), e(CATEGORIES[i]))
            for i in range(len(CATEGORIES))
            for p in query("SELECT * FROM product WHERE category = ? ORDER BY sold DESC LIMIT 1", (i,)))
        deals = query("SELECT * FROM product WHERE old_price > 0 ORDER BY (old_price - price) * 1.0 / old_price DESC LIMIT 4")
        best = query("SELECT * FROM product ORDER BY sold DESC, reviews DESC LIMIT 8")
        old = "<s>%s</s>" % money(hero["old_price"]) if hero["old_price"] else ""
        return ('<section class="hero"><div class="copy"><span class="tag">%s</span><h1>%s</h1><p>%s</p>'
                '<div class="from">%s%s</div>%s %s</div><div>%s</div></section>'
                '<div class="title"><h2>%s</h2></div><div class="cats">%s</div>'
                '<div class="title"><h2>%s</h2></div><div class="grid">%s</div>%s'
                '<div class="title"><h2>%s</h2></div><div class="grid">%s</div>') % (
            e(T["hero_tag"]), e(hero["name"]), e(T["hero_text"]), money(hero["price"]), old,
            link("add", e(T["buy_now"]), hero["id"], "btn"), link("product", e(T["see"]), hero["id"], "btn light"),
            art(hero["art"], hero["color"]),
            e(T["shop_by"]), tiles, e(T["deals"]), "".join(product_card(p) for p in deals), self.perks(),
            e(T["best"]), "".join(product_card(p) for p in best))

    def listing(self, title, rows, sort_form=""):
        cards = "".join(product_card(p) for p in rows) or '<p class="empty">%s</p>' % e(T["none"])
        return ('<div class="crumbs">%s / %s</div><div class="title"><h2>%s</h2><span>%s</span>%s</div>'
                '<div class="grid">%s</div>%s') % (
            link("home", e(T["home"])), e(title), e(title), e(T["count"].format(len(rows))), sort_form,
            cards, self.perks())

    def page_category(self, arg):
        category, sort = arg
        category %= len(CATEGORIES)
        order = {"low": "price ASC", "high": "price DESC"}.get(sort, "sold DESC")
        rows = query("SELECT * FROM product WHERE category = ? ORDER BY " + order, (category,))
        options = "".join('<option value="%s"%s>%s</option>' % (k, " selected" if k == sort else "", e(T["sort_" + k]))
                          for k in ("pop", "low", "high"))
        form = ('<form class="addform" data-action="category" data-arg="%d" style="margin:0">'
                '<select name="sort">%s</select><button class="btn ghost small" type="submit">%s</button></form>') % (
            category, options, e(T["sort"]))
        return self.listing(CATEGORIES[category], rows, form)

    def page_search(self, text):
        like = "%" + text + "%"
        rows = query("SELECT * FROM product WHERE name LIKE ? OR description LIKE ? ORDER BY sold DESC", (like, like))
        return self.listing(T["results"].format(text), rows)

    def page_product(self, product_id):
        p = self.product(product_id)
        if p is None:
            self.where = ("home", None)
            return self.page_home(None)
        if p["stock"] <= 0:
            stock = '<div class="stock none">%s</div>' % e(T["no_stock"])
        elif p["stock"] <= 5:
            stock = '<div class="stock low">%s</div>' % e(T["low_stock"].format(p["stock"]))
        else:
            stock = '<div class="stock">%s</div>' % e(T["in_stock"].format(p["stock"]))
        was = ""
        if p["old_price"]:
            was = '<div class="was"><s>%s</s><b>%s</b></div>' % (
                money(p["old_price"]), e(T["save"].format(money(p["old_price"] - p["price"]))))
        qty = "".join('<option>%d</option>' % n for n in range(1, min(p["stock"], 10) + 1))
        buy = ('<form class="addform" data-action="add" data-arg="%d"><select name="qty" aria-label="%s">%s</select>'
               '<button class="btn" type="submit">%s</button></form>') % (p["id"], e(T["qty"]), qty, e(T["add_cart"])) \
            if p["stock"] > 0 else ""
        related = query("SELECT * FROM product WHERE category = ? AND id != ? ORDER BY sold DESC LIMIT 4",
                        (p["category"], p["id"]))
        if len(related) < 4:
            related += query("SELECT * FROM product WHERE id != ? AND category != ? ORDER BY sold DESC LIMIT ?",
                             (p["id"], p["category"], 4 - len(related)))
        return ('<div class="crumbs">%s / %s / %s</div><div class="detail"><div class="stage">%s</div><div>'
                '<span class="pcat">%s</span><h1>%s</h1><div class="rate">%s %s</div>'
                '<div class="now">%s</div>%s%s%s<ul class="ticks"><li>%s</li><li>%s</li><li>%s</li></ul>'
                '<div class="desc">%s</div></div></div>'
                '<div class="title"><h2>%s</h2></div><div class="grid">%s</div>%s') % (
            link("home", e(T["home"])), link("category", e(CATEGORIES[p["category"]]), p["category"]), e(p["name"]),
            art(p["art"], p["color"]), e(CATEGORIES[p["category"]]), e(p["name"]), stars(p["stars"]),
            e(T["reviews"].format(p["reviews"])), money(p["price"]), was, stock, buy,
            e(T["b1"]), e(T["b2"]), e(T["b4"]), e(p["description"]),
            e(T["best"]), "".join(product_card(r) for r in related), self.perks())

    def summary_box(self, button):
        subtotal, shipping, total = self.totals()
        return ('<aside class="box"><h3>%s</h3><div class="sum"><span>%s</span><span>%s</span></div>'
                '<div class="sum"><span>%s</span><span>%s</span></div>'
                '<div class="sum total"><span>%s</span><span>%s</span></div>%s</aside>') % (
            e(T["your_cart"]), e(T["subtotal"]), money(subtotal), e(T["shipping"]),
            e(T["free"]) if not shipping else money(shipping), e(T["total"]), money(total), button)

    def page_cart(self, arg):
        lines = self.lines()
        if not lines:
            return '<div class="done"><h1>%s</h1><p>%s</p></div>' % (
                e(T["empty"]), link("home", e(T["keep"]), css="btn"))
        rows = "".join(
            ('<div class="line"><a href="#" class="pimg" data-action="product" data-arg="%d">%s</a>'
             '<div><b>%s</b><br><small>%s</small><br>%s</div>'
             '<div class="qty">%s<span>%d</span>%s</div><b>%s</b></div>') % (
                p["id"], art(p["art"], p["color"]), e(p["name"]), money(p["price"]),
                link("remove", e(T["remove"]), p["id"], "del"),
                link("minus", "&minus;", p["id"]), qty, link("plus", "+", p["id"]), money(p["price"] * qty))
            for p, qty in lines)
        return ('<div class="crumbs">%s / %s</div><div class="title"><h2>%s</h2></div>'
                '<div class="layout"><div class="lines">%s</div>%s</div>') % (
            link("home", e(T["home"])), e(T["cart"]), e(T["your_cart"]), rows,
            self.summary_box(link("checkout", e(T["checkout"]), css="btn wide") +
                             '<p class="muted">%s</p>' % e(T["demo"])))

    def page_checkout(self, arg):
        if not self.cart:
            return self.page_cart(None)
        total = self.totals()[2]
        pay = "".join('<option value="%s">%s</option>' % (k, e(T["pay_" + k])) for k in ("card", "transfer", "cod"))
        field = lambda name, label, kind="text", css="", value="": (
            '<label class="%s">%s<input name="%s" type="%s" value="%s"></label>' % (css, e(T[label]), name, kind, e(value)))
        return ('<div class="crumbs">%s / %s / %s</div><div class="title"><h2>%s</h2></div>'
                '<div class="layout"><form class="form" data-action="pay">%s%s%s%s%s'
                '<label class="full">%s<select name="payment">%s</select></label>'
                '<div class="full"><button class="btn" type="submit">%s</button> <span class="muted">%s</span></div>'
                '</form>%s</div>') % (
            link("home", e(T["home"])), link("cart", e(T["cart"])), e(T["checkout"]), e(T["details"]),
            field("name", "name", css="full", value=self.user["name"]),
            '<p class="full muted">%s</p>' % e(T["buyer"].format(self.user["name"], self.user["email"])),
            field("address", "address", css="full"), field("city", "city"), field("zip", "zip"),
            e(T["payment"]), pay, e(T["place"].format(money(total))), e(T["demo"]), self.summary_box(""))

    def page_done(self, arg):
        if not self.last_order:
            return self.page_home(None)
        order_id, name, email, total = self.last_order
        return '<div class="done"><span class="ok">✓</span><h1>%s</h1><p>%s</p><p><b>%s %s</b></p><p>%s</p></div>' % (
            e(T["thanks"].format(name)), e(T["order_ok"].format(order_id, email)), e(T["total"]), money(total),
            link("home", e(T["keep"]), css="btn"))

    def page_account(self, arg):
        orders = query("SELECT * FROM orders WHERE user_id = ? ORDER BY id DESC", (self.user["id"],))
        rows = "".join(
            '<tr><td>#%d</td><td>%s</td><td>%s</td><td class="num">%s</td><td><span class="pill %s">%s</span></td></tr>' % (
                o["id"], e(o["date"]), e(", ".join("%s × %d" % (l["name"], l["qty"]) for l in
                                                   query("SELECT * FROM order_line WHERE order_id = ?", (o["id"],)))),
                money(o["total"]), e(o["status"]), e(T["shipped"] if o["status"] == "shipped" else T["new"]))
            for o in orders)
        body = ('<div class="panel"><table><tr><th>%s</th><th>%s</th><th>%s</th><th class="num">%s</th><th>%s</th></tr>'
                '%s</table></div>' % (e(T["order"]), e(T["date"]), e(T["products"]), e(T["total"]), e(T["status"]), rows)
                if orders else '<p class="empty">%s</p>' % e(T["no_my_orders"]))
        return '<div class="crumbs">%s / %s</div><div class="title"><h2>%s</h2><span>%s</span></div>%s' % (
            link("home", e(T["home"])), e(T["account"]), e(T["my_orders"]),
            e("%s · %s" % (self.user["name"], self.user["email"])), body)

    def page_dashboard(self, arg):
        one = lambda sql: query(sql)[0][0] or 0
        stats = [(T["sales"], money(one("SELECT SUM(total) FROM orders"))),
                 (T["orders"], one("SELECT COUNT(*) FROM orders")),
                 (T["pending"], one("SELECT COUNT(*) FROM orders WHERE status = 'new'")),
                 (T["customers"], one("SELECT COUNT(*) FROM account"))]
        cards = "".join('<div class="stat"><small>%s</small><b>%s</b></div>' % (e(k), v) for k, v in stats)
        per = {r["category"]: r["amount"] for r in query(
            "SELECT product.category, SUM(order_line.qty * order_line.price) AS amount FROM order_line"
            " JOIN product ON product.id = order_line.product_id GROUP BY product.category")}
        top = max(per.values() or [1])
        bars = "".join('<div><span>%s</span><span class="bar"><i style="width:%d%%"></i></span><b>%s</b></div>' % (
            e(c), round(per.get(i, 0) * 100 / top), money(per.get(i, 0))) for i, c in enumerate(CATEGORIES))
        orders = "".join(
            '<tr><td>#%d</td><td>%s</td><td><strong>%s</strong><br><small>%s</small></td><td class="num">%s</td>'
            '<td><span class="pill %s">%s</span></td><td><div class="acts">%s</div></td></tr>' % (
                o["id"], e(o["date"]), e(o["name"]), e(o["email"]), money(o["total"]), e(o["status"]),
                e(T["shipped"] if o["status"] == "shipped" else T["new"]),
                "" if o["status"] == "shipped" else link("ship", e(T["mark"]), o["id"]))
            for o in query("SELECT * FROM orders ORDER BY id DESC LIMIT 20")) or \
            '<tr><td>%s</td></tr>' % e(T["no_orders"])
        products = "".join(
            '<tr><td>%s</td><td class="num">%s</td><td class="num">%s</td><td class="num">%s</td>'
            '<td><form data-action="restock" data-arg="%d"><input name="qty" type="number" min="1" max="1000" value="10" '
            'style="width:70px"><button class="btn small ghost" type="submit">%s</button></form></td></tr>' % (
                link("product", e(p["name"]), p["id"]), money(p["price"]),
                '<span class="pill">%d</span>' % p["stock"] if p["stock"] <= 5 else p["stock"],
                p["sold"], p["id"], e(T["restock"]))
            for p in query("SELECT * FROM product ORDER BY stock, name"))
        return ('<div class="title"><h2>%s</h2><span>%s</span></div><div class="stats">%s</div>'
                '<div class="cols2"><div class="panel"><h3>%s</h3><div class="bars">%s</div></div>'
                '<div class="panel"><h3>%s</h3><table><tr><th>%s</th><th>%s</th><th>%s</th><th class="num">%s</th>'
                '<th>%s</th><th></th></tr>%s</table></div></div>'
                '<div class="panel"><h3>%s</h3><table><tr><th>%s</th><th class="num">%s</th><th class="num">%s</th>'
                '<th class="num">%s</th><th></th></tr>%s</table></div>') % (
            e(T["shop_dash"]), e(T["low"] + ": %d" % one("SELECT COUNT(*) FROM product WHERE stock <= 5")), cards,
            e(T["by_cat"]), bars, e(T["orders"]), e(T["order"]), e(T["date"]), e(T["customer"]), e(T["total"]),
            e(T["status"]), orders, e(T["products"]), e(T["u_name"]), e(T["price"]), e(T["stock"]), e(T["sold"]),
            products)
''';

// ------------------------------------------------------------------ cuentas
/// Frases de las cuentas (entrar, registrarse, salir), comunes a las webs.
Map<String, String> _authPhrases(String Function(String) t) => {
  'login': t(markTr('Entrar')),
  'signup': t(markTr('Crear cuenta')),
  'logout': t(markTr('Salir')),
  'dashboard': t(markTr('Panel')),
  'login_title': t(markTr('Entra en tu cuenta')),
  'signup_title': t(markTr('Crea tu cuenta')),
  'login_text': t(markTr('¿Aún no tienes cuenta?')),
  'signup_text': t(markTr('¿Ya tienes cuenta?')),
  'first_admin': t(
    markTr('La primera cuenta que se registra es la de administración.'),
  ),
  'u_name': t(markTr('Nombre')),
  'u_email': t(markTr('Correo electrónico')),
  'u_password': t(markTr('Contraseña')),
  'u_password2': t(markTr('Repite la contraseña')),
  'bad_login': t(markTr('El correo o la contraseña no son correctos.')),
  'locked': t(
    markTr('Demasiados intentos. Espera un minuto y vuelve a probar.'),
  ),
  'bad_name': t(markTr('Escribe tu nombre (2-60 letras).')),
  'bad_mail': t(markTr('Escribe un correo válido.')),
  'bad_password': t(markTr('La contraseña debe tener al menos 8 caracteres.')),
  'mismatch': t(markTr('Las contraseñas no coinciden.')),
  'taken': t(markTr('Ya hay una cuenta con ese correo.')),
  'welcome': t(markTr('Hola, {0}.')),
  'bye': t(markTr('Has salido de tu cuenta.')),
  'need_login': t(markTr('Entra con tu cuenta para continuar.')),
  'need_admin': t(markTr('Esa página es solo para administración.')),
  'role_admin': t(markTr('Administración')),
  'role_author': t(markTr('Autor')),
  'role_user': t(markTr('Usuario')),
};

/// Cuentas de usuario: contraseñas con PBKDF2 y sal (nunca en claro), la
/// primera cuenta es la de administración y tras cinco fallos seguidos se
/// espera un minuto. Las funciones reciben la página (form) que las usa.
const _authCore = r'''

# ---------------------------------------------------------------- cuentas
import hashlib
import hmac
import secrets
import time

ROLES = ("admin", "author", "user")


def create_users():
    execute("""CREATE TABLE IF NOT EXISTS account (
        id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
        salt TEXT NOT NULL, hash TEXT NOT NULL, role TEXT NOT NULL, date TEXT NOT NULL)""")


def password_hash(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), bytes.fromhex(salt), 200_000).hex()


def find_user(user_id):
    rows = query("SELECT id, name, email, role, date FROM account WHERE id = ?", (user_id,))
    return dict(rows[0]) if rows else None


def check_login(form, email, password):
    """La cuenta de email y password (None si no). Cinco fallos: un minuto."""
    if form._auth_fails >= 5 and time.monotonic() - form._auth_last < 60:
        return None, T["locked"]
    rows = query("SELECT * FROM account WHERE email = ?", (email.strip().lower(),))
    # Sin la cuenta también se calcula un hash: tarda lo mismo.
    salt = rows[0]["salt"] if rows else "00" * 16
    digest = password_hash(password, salt)
    if rows and hmac.compare_digest(digest, rows[0]["hash"]):
        form._auth_fails = 0
        return find_user(rows[0]["id"]), None
    form._auth_fails += 1
    form._auth_last = time.monotonic()
    return None, T["bad_login"]


def create_account(name, email, password, password2):
    name, email = name.strip(), email.strip().lower()
    if not 2 <= len(name) <= 60:
        return None, T["bad_name"]
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email) or len(email) > 120:
        return None, T["bad_mail"]
    if not 8 <= len(password) <= 200:
        return None, T["bad_password"]
    if password != password2:
        return None, T["mismatch"]
    if query("SELECT id FROM account WHERE email = ?", (email,)):
        return None, T["taken"]
    first = not query("SELECT id FROM account LIMIT 1")
    salt = secrets.token_hex(16)
    user_id = execute(
        "INSERT INTO account (name, email, salt, hash, role, date) VALUES (?, ?, ?, ?, ?, ?)",
        (name, email, salt, password_hash(password, salt), "admin" if first else "user",
         datetime.date.today().isoformat()))
    return find_user(user_id), None


def auth_start(form):
    create_users()
    form.user = None
    form._auth_fails = 0
    form._auth_last = 0.0
    form._auth_next = ("home", None)


def auth_action(form, action):
    """Entrar, registrarse y salir. True si la acción era de cuentas."""
    name = action.name
    if name in ("login", "signup"):
        form.go(name)
    elif name == "signin":
        user, error = check_login(form, action.get("email"), action.get("password"))
        if error:
            form.say(error, True)
            return form.go("login", top=False) or True
        auth_enter(form, user)
    elif name == "register":
        user, error = create_account(action.get("name"), action.get("email"),
                                     action.get("password"), action.get("password2"))
        if error:
            form.say(error, True)
            return form.go("signup", top=False) or True
        auth_enter(form, user)
    elif name == "logout":
        form.user = None
        form.say(T["bye"])
        form.go("home")
    else:
        return False
    return True


def auth_enter(form, user):
    form.user = user
    form.say(T["welcome"].format(user["name"]))
    page, form._auth_next = form._auth_next, ("home", None)
    form.go(*page)


def auth_require(form, page, arg=None, roles=None):
    """Lleva a entrar (y después a page) si no hay cuenta, o si su papel no
    está en roles. True si se puede seguir."""
    if form.user is None:
        form._auth_next = (page, arg)
        form.say(T["need_login"], True)
        form.go("login")
        return False
    if roles and form.user["role"] not in roles:
        form.say(T["need_admin"], True)
        form.go("home")
        return False
    return True


def auth_html(mode, notice=""):
    """Tarjeta de entrar (mode "login") o de registrarse ("signup")."""
    signup = mode == "signup"
    field = lambda name, label, kind="text", extra="": (
        '<label>%s<input name="%s" type="%s"%s></label>' % (e(T[label]), name, kind, extra))
    fields = (field("name", "u_name", extra=' maxlength="60" autocomplete="name"') if signup else "") + \
        field("email", "u_email", "email", ' autocomplete="email"') + \
        field("password", "u_password", "password",
              ' autocomplete="%s"' % ("new-password" if signup else "current-password")) + \
        (field("password2", "u_password2", "password", ' autocomplete="new-password"') if signup else "")
    switch = '<p class="switch">%s %s</p>' % (
        e(T["signup_text" if signup else "login_text"]),
        '<a href="#" data-action="%s">%s</a>' % ("login" if signup else "signup", e(T["login" if signup else "signup"])))
    return ('<section class="auth"><h1>%s</h1>%s<form data-action="%s">%s'
            '<button class="btn wide" type="submit">%s</button></form>%s<p class="hint">%s</p></section>') % (
        e(T["signup_title" if signup else "login_title"]), notice, "register" if signup else "signin", fields,
        e(T["signup" if signup else "login"]), switch, e(T["first_admin"]))


AUTH_CSS = """
.auth{max-width:420px;margin:56px auto 72px;border:1px solid var(--line);border-radius:20px;padding:32px;background:#fff;
  box-shadow:0 20px 50px rgba(15,23,42,.08)}
.auth h1{font-size:28px;letter-spacing:-.03em;margin:0 0 18px}
.auth form{display:grid;gap:14px;margin:18px 0}
.auth label{display:grid;gap:6px;font-size:13px;font-weight:600}
.auth input{border:1px solid var(--line);border-radius:10px;padding:11px 13px;font:inherit;font-weight:400}
.auth .switch{text-align:center;color:var(--muted);margin:0}
.auth .switch a{color:var(--brand);font-weight:600}
.auth .btn{display:block;width:100%;text-align:center}
.panel a,.who a,.auth a{text-decoration:none}
.auth .hint{text-align:center;color:var(--muted);font-size:12px;margin:12px 0 0}
.who{display:flex;align-items:center;gap:14px;font-size:14px;font-weight:600}
.who a{color:var(--muted)}
.who a:hover{color:var(--ink)}
.stats{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:16px;margin:8px 0 28px}
.stat{border:1px solid var(--line);border-radius:16px;padding:18px 20px}
.stat small{color:var(--muted);font-size:13px;font-weight:600}
.stat b{display:block;font-size:30px;letter-spacing:-.03em;margin-top:2px}
.panel{border:1px solid var(--line);border-radius:16px;padding:6px 20px 14px;margin-bottom:24px;overflow-x:auto}
.panel h3{margin:14px 0 6px;font-size:17px}
.panel table{width:100%;border-collapse:collapse}
.panel th,.panel td{text-align:left;padding:10px 8px;border-bottom:1px solid var(--line);font-size:14px;vertical-align:middle}
.panel tr:last-child td{border-bottom:0}
.panel th{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.05em}
.panel td.num,.panel th.num{text-align:right;white-space:nowrap}
.panel .acts{display:flex;gap:10px;justify-content:flex-end;white-space:nowrap}
.panel .acts a{color:var(--brand);font-weight:600;font-size:13px}
.panel .acts a.del{color:#b91c1c}
.panel form{display:flex;gap:8px;margin:0;align-items:center}
.panel select,.panel input{border:1px solid var(--line);border-radius:8px;padding:6px 8px;font:inherit;font-size:13px}
.bars{display:grid;gap:10px;margin:10px 0}
.bars div{display:grid;grid-template-columns:110px 1fr 90px;gap:12px;align-items:center;font-size:13px}
.bars span.bar{height:10px;border-radius:999px;background:var(--soft);overflow:hidden;display:block}
.bars span.bar i{display:block;height:100%;border-radius:999px;background:var(--brand)}
.cols2{display:grid;grid-template-columns:1fr 1fr;gap:24px}
@media (max-width:900px){.stats{grid-template-columns:1fr 1fr}.cols2{grid-template-columns:1fr}}
"""
''';
