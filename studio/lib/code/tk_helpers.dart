/// Código de Python que acompaña a las ventanas con datos. Va dentro del
/// archivo generado, y solo en las que lo usan: las demás no saben nada de
/// bases de datos. No lleva ni fichas, ni contraseñas, ni direcciones: todo
/// eso llega al lanzar la ventana, por el entorno, y solo existe mientras
/// dura.
class TkHelpers {
  TkHelpers._();

  /// Botón con los colores del diseño. En macOS tk.Button pinta siempre el del
  /// sistema, sea cual sea su fondo: allí se dibuja sobre una etiqueta, que lo
  /// respeta y ocupa todo su tamaño. Las pulsaciones van en su propia etiqueta
  /// de eventos para que los eventos del diseño, que usan bind sin add, no las
  /// sustituyan.
  static const colorButton = r'''


class _MacColorButton(tk.Label):
    """tk.Button for macOS, where the real one ignores its background."""

    def __init__(self, master=None, command=None, **options):
        super().__init__(master, **options)
        self._command = command
        self._pressed = False
        self.bindtags(("ColorButton",) + self.bindtags())
        self.bind_class("ColorButton", "<Button-1>", _MacColorButton._press)
        self.bind_class(
            "ColorButton", "<ButtonRelease-1>", _MacColorButton._release
        )

    def configure(self, cnf=None, **options):
        if "command" in options:
            self._command = options.pop("command")
        return super().configure(cnf, **options)

    config = configure

    def invoke(self):
        if self._command and self.cget("state") != "disabled":
            return self._command()

    @staticmethod
    def _press(event):
        self = event.widget
        if self.cget("state") == "disabled":
            return
        self._pressed = True
        shade = [c * 3 // 4 for c in self.winfo_rgb(self.cget("bg"))]
        self.configure(
            state="active",
            activebackground="#%04x%04x%04x" % tuple(shade),
            activeforeground=self.cget("fg"),
        )

    @staticmethod
    def _release(event):
        self = event.widget
        if not self._pressed:
            return
        self._pressed = False
        self.configure(state="normal")
        if (0 <= event.x < self.winfo_width()
                and 0 <= event.y < self.winfo_height()):
            self.invoke()


ColorButton = _MacColorButton if sys.platform == "darwin" else tk.Button
''';

  static const dataError = r'''


class DataError(Exception):
    """A data source failed: the message is for the user."""
''';

  static const erpClient = r'''


class ErpClient:
    """ERP data through its API, with the rights of whoever opened the window.

    search, read, create and update work on the models of the ERP API.
    """

    def __init__(self):
        self.url = os.environ.get("DMSTUDIO_API_URL", "")
        self.token = os.environ.get("DMSTUDIO_API_TOKEN", "")
        # Never through a proxy: the token is for the local server only.
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))

    def call(self, model, method, args=(), kwargs=None):
        if not self.url or not self.token:
            raise DataError("Open this window from the ERP: it needs its API.")
        body = {
            "model": model,
            "method": method,
            "args": list(args),
            "kwargs": kwargs or {},
        }
        request = urllib.request.Request(
            self.url + "/api/tk/call",
            data=json.dumps(body).encode("utf-8"),
            headers={
                "Content-Type": "application/json",
                "Authorization": "Bearer " + self.token,
            },
        )
        try:
            with self.opener.open(request, timeout=30) as response:
                data = json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            try:
                data = json.loads(error.read().decode("utf-8"))
            except ValueError:
                raise DataError(str(error)) from None
        except (OSError, ValueError) as error:
            raise DataError("The ERP API did not answer: {}".format(error)) from None
        if "error" in data:
            raise DataError(data["error"].get("message", "ERP error"))
        return data["result"]

    def search(self, model, domain=(), fields=None, limit=100, order=None):
        options = {"limit": limit}
        if fields:
            options["fields"] = list(fields)
        if order:
            options["order"] = order
        return self.call(model, "search_read", [list(domain)], options)

    def read(self, model, ids, fields=None):
        options = {"fields": list(fields)} if fields else {}
        return self.call(model, "read", [list(ids)], options)

    def create(self, model, values):
        return self.call(model, "create", [values])

    def update(self, model, ids, values):
        return self.call(model, "write", [list(ids), values])
''';

  static const sqlClient = r'''


class SqlClient:
    """Another database. Its connection data arrives in the environment.

    Queries always go with parameters: write ? and pass the values apart,
    never joined into the text. SQLite needs nothing else; PostgreSQL needs
    psycopg or psycopg2, and MySQL needs pymysql.
    """

    def __init__(self, name):
        self.prefix = "DMSTUDIO_DB_" + name.upper() + "_"
        self.name = name
        self.kind = self.value("KIND")
        self.connection = None

    def value(self, key):
        return os.environ.get(self.prefix + key, "")

    def open(self):
        if self.connection is not None:
            return self.connection
        ssl = self.value("SSL") == "1"
        try:
            if self.kind == "sqlite":
                import sqlite3

                self.connection = sqlite3.connect(self.value("PATH"))
            elif self.kind == "postgres":
                try:
                    import psycopg as driver
                except ImportError:
                    import psycopg2 as driver
                self.connection = driver.connect(
                    host=self.value("HOST"),
                    port=int(self.value("PORT") or 5432),
                    dbname=self.value("DATABASE"),
                    user=self.value("USER"),
                    password=self.value("PASSWORD"),
                    sslmode="require" if ssl else "disable",
                )
            elif self.kind == "mysql":
                import pymysql

                self.connection = pymysql.connect(
                    host=self.value("HOST"),
                    port=int(self.value("PORT") or 3306),
                    database=self.value("DATABASE"),
                    user=self.value("USER"),
                    password=self.value("PASSWORD"),
                    ssl={"ssl": {}} if ssl else None,
                )
            else:
                raise DataError(
                    "Open this window from DMarlon Studio: it needs " + self.name + "."
                )
        except DataError:
            raise
        except Exception as error:
            raise DataError(str(error)) from None
        return self.connection

    def statement(self, text, params):
        """Turn the ? marks into those of the driver (never inside quotes)."""
        if self.kind == "sqlite" or not params:
            return text
        out, quote = [], None
        for char in text:
            if quote:
                quote = None if char == quote else quote
                out.append("%%" if char == "%" else char)
            elif char in "'\"`":
                quote = char
                out.append(char)
            elif char == "?":
                out.append("%s")
            elif char == "%":
                out.append("%%")
            else:
                out.append(char)
        return "".join(out)

    def run(self, text, params):
        connection = self.open()
        cursor = connection.cursor()
        values = tuple(params)
        try:
            if values:
                cursor.execute(self.statement(text, values), values)
            else:
                cursor.execute(text)
            return cursor
        except Exception as error:
            connection.rollback()
            raise DataError(str(error)) from None

    def query(self, text, params=()):
        """The rows of a SELECT, as dictionaries."""
        cursor = self.run(text, params)
        names = [column[0] for column in cursor.description or []]
        rows = [dict(zip(names, row)) for row in cursor.fetchall()]
        cursor.close()
        self.connection.commit()
        return rows

    def execute(self, text, params=()):
        """Run INSERT, UPDATE or DELETE; returns the rows changed."""
        cursor = self.run(text, params)
        count = cursor.rowcount
        cursor.close()
        self.connection.commit()
        return count
''';

  static const gridFill = r'''

    @staticmethod
    def _text(value):
        if value is None or value is False:
            return ""
        if isinstance(value, list) and len(value) == 2:
            return str(value[1])
        return str(value)

    def _fill(self, grid, columns, load):
        try:
            rows = load()
        except Exception as error:
            tkinter.messagebox.showerror(self.root.title(), str(error))
            return []
        if not columns and rows:
            columns = list(rows[0])
            grid.configure(columns=columns)
            for column in columns:
                grid.heading(column, text=column)
        grid.delete(*grid.get_children())
        for index, row in enumerate(rows):
            values = [self._text(row.get(column)) for column in columns]
            grid.insert("", "end", iid=str(index), values=values)
        return rows
''';
}
