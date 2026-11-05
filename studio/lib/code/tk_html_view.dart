/// Componente «Vista HTML» en una ventana de escritorio: el HTML sencillo
/// (títulos, párrafos, listas, negritas, enlaces, tablas y formularios) en
/// un texto de tkinter. Los enlaces y formularios con data-action llaman a
/// su evento con un HtmlAction, igual que en la web, donde se ve completo.
const tkHtmlViewPython = r'''

# ------------------------------------------------------------- vista HTML
class HtmlAction:
    """Lo que trae un enlace o un formulario de una Vista HTML: name (su
    data-action), arg (su data-arg) y form (los campos enviados)."""

    def __init__(self, name, arg="", form=None):
        self.name = name
        self.arg = arg
        self.form = form or {}

    def get(self, key, default=""):
        value = self.form.get(key, default)
        if isinstance(value, list):
            return value[-1] if value else default
        return value

    def __repr__(self):
        return "HtmlAction(%r, %r)" % (self.name, self.arg)


class DesignHtml(tk.Frame):
    """Vista HTML: set_html(html) la cambia y command(HtmlAction) recibe los
    clics en <a data-action> y <button data-action>, y los envíos de
    <form data-action>. Los estilos CSS solo se aplican en la web."""

    BLOCKS = {"p", "div", "section", "article", "header", "footer", "nav",
              "main", "aside", "figure", "figcaption", "blockquote", "pre",
              "ul", "ol", "li", "table", "tr", "form", "h1", "h2", "h3",
              "h4", "h5", "h6", "dl", "dt", "dd", "label"}
    SPACED = {"p", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "table",
              "blockquote", "pre", "form", "figure"}
    SKIP = {"style", "script", "head", "title", "template", "svg", "noscript"}
    INLINE = {"b": "b", "strong": "b", "i": "i", "em": "i", "small": "small",
              "code": "pre", "th": "b", "h1": "h1", "h2": "h2", "h3": "h3",
              "h4": "h4", "h5": "h4", "h6": "h4", "pre": "pre",
              "blockquote": "quote", "del": "del", "s": "del", "mark": "mark"}

    def __init__(self, master, html="", command=None, bg="#ffffff",
                 fg="#1f2328", font_size=0, **options):
        super().__init__(master, bg=bg, bd=0, highlightthickness=0)
        import tkinter.font as tkfont
        self.command = command
        self._html = ""
        self._widgets = []
        self._actions = {}
        base = tkfont.nametofont("TkDefaultFont").actual()
        family, size = base["family"], int(font_size) or 12
        self.text = tk.Text(
            self, wrap="word", bd=0, highlightthickness=0, bg=bg, fg=fg,
            padx=18, pady=14, cursor="arrow", spacing1=1, spacing3=1,
            font=(family, size),
        )
        bar = ttk.Scrollbar(self, orient="vertical", command=self.text.yview)
        self.text.configure(yscrollcommand=bar.set)
        bar.pack(side="right", fill="y")
        self.text.pack(side="left", fill="both", expand=True)
        t = self.text.tag_configure
        t("h1", font=(family, size + 12, "bold"), spacing3=6)
        t("h2", font=(family, size + 7, "bold"), spacing3=4)
        t("h3", font=(family, size + 3, "bold"), spacing3=2)
        t("h4", font=(family, size + 1, "bold"))
        t("b", font=(family, size, "bold"))
        t("i", font=(family, size, "italic"))
        t("small", font=(family, max(8, size - 2)), foreground="#6b7280")
        t("pre", font=("Courier", size), background="#f3f4f6")
        t("quote", lmargin1=24, lmargin2=24, foreground="#4b5563")
        t("li", lmargin1=14, lmargin2=30)
        t("del", overstrike=True)
        t("mark", background="#fde68a")
        t("hr", foreground="#d1d5db")
        t("link", foreground="#0b63ce", underline=True)
        t("button", foreground="#ffffff", background="#0b63ce",
          font=(family, size, "bold"))
        self.set_html(html)

    # ------------------------------------------------------------ API
    def set_html(self, html, top=False):
        """Muestra otro HTML (top: vuelve al principio)."""
        self._html = str(html or "")
        for w in self._widgets:
            w.destroy()
        self._widgets = []
        self._actions = {}
        self.text.configure(state="normal")
        self.text.delete("1.0", "end")
        for tag in self.text.tag_names():
            if tag.startswith("act"):
                self.text.tag_delete(tag)
        _HtmlFiller(self).feed(self._html)
        self.text.configure(state="disabled")
        self.text.yview_moveto(0)

    def content(self):
        return self._html

    def _fire(self, name, arg="", form=None):
        if self.command:
            self.command(HtmlAction(name, arg, form))


try:
    from html.parser import HTMLParser as _HTMLParser
except ImportError:  # pragma: no cover
    _HTMLParser = object


class _HtmlFiller(_HTMLParser):
    """Escribe el HTML en el texto de una DesignHtml."""

    def __init__(self, view):
        super().__init__(convert_charrefs=True)
        self.view = view
        self.text = view.text
        self.tags = []
        self.skip = 0
        self.pre = 0
        self.lists = []
        self.forms = []
        self.links = []
        self.select = None
        self.area = None
        self.count = 0

    # ---------------------------------------------------------- texto
    def _last(self):
        return self.text.get("end-2c", "end-1c")

    def _newline(self, blank=False):
        content = self.text.get("1.0", "end-1c")
        if not content:
            return
        if not content.endswith("\n"):
            self.text.insert("end", "\n")
            content += "\n"
        if blank and not content.endswith("\n\n"):
            self.text.insert("end", "\n")

    def _insert(self, data, extra=()):
        tags = tuple(self.tags) + tuple(extra)
        self.text.insert("end", data, tags)

    def _action_tag(self, callback, look="link"):
        self.count += 1
        tag = "act%d" % self.count
        self.view._actions[tag] = callback
        self.text.tag_bind(tag, "<Button-1>", lambda e: callback())
        self.text.tag_bind(tag, "<Enter>",
                           lambda e: self.text.configure(cursor="hand2"))
        self.text.tag_bind(tag, "<Leave>",
                           lambda e: self.text.configure(cursor="arrow"))
        return (look, tag)

    def _submitter(self, form, arg=""):
        def send():
            fields = dict(form["fixed"])
            for name, get in form["fields"]:
                value = get()
                if value is None:
                    continue
                if name in fields:
                    old = fields[name]
                    fields[name] = (old if isinstance(old, list) else [old]) + [value]
                else:
                    fields[name] = value
            self.view._fire(form["action"], arg or form["arg"], fields)
        return send

    def _embed(self, widget):
        self.view._widgets.append(widget)
        self.text.window_create("end", window=widget, padx=2, pady=2)

    # ------------------------------------------------------- etiquetas
    def handle_starttag(self, tag, attrs):
        a = dict((k, v or "") for k, v in attrs)
        if tag in DesignHtml.SKIP:
            self.skip += 1
            return
        if self.skip:
            return
        if tag in DesignHtml.BLOCKS:
            self._newline(tag in DesignHtml.SPACED)
        if tag in DesignHtml.INLINE:
            self.tags.append(DesignHtml.INLINE[tag])
        if tag == "pre":
            self.pre += 1
        elif tag == "br":
            self._insert("\n")
        elif tag == "hr":
            self._newline()
            self.text.insert("end", "─" * 48 + "\n", ("hr",))
        elif tag in ("ul", "ol"):
            self.lists.append(0 if tag == "ol" else None)
        elif tag == "li":
            mark = "•"
            if self.lists and self.lists[-1] is not None:
                self.lists[-1] += 1
                mark = "%d." % self.lists[-1]
            self.tags.append("li")
            self._insert(mark + " ")
        elif tag in ("td", "th"):
            if self._last() not in ("", "\n"):
                self._insert("    ")
        elif tag == "img":
            if a.get("alt"):
                self._insert("[%s]" % a["alt"], ("small",))
        elif tag == "form":
            self.forms.append({"action": a.get("data-action", ""),
                               "arg": a.get("data-arg", ""),
                               "fields": [], "fixed": {}})
        elif tag in ("a", "button"):
            self._open_link(tag, a)
        elif tag == "input":
            self._input(a)
        elif tag == "textarea":
            self.area = (a, [])
        elif tag == "select":
            self.select = (a, [], [None])
        elif tag == "option" and self.select is not None:
            self.select[1].append([a.get("value"), ""])
            if "selected" in a:
                self.select[2][0] = len(self.select[1]) - 1

    def _open_link(self, tag, a):
        action = a.get("data-action")
        form = self.forms[-1] if self.forms else None
        look = "button" if tag == "button" else "link"
        if action and (tag == "a" or a.get("type") == "button" or not form):
            name, arg = action, a.get("data-arg", "")
            pushed = self._action_tag(lambda: self.view._fire(name, arg), look)
        elif tag == "button" and form and a.get("type", "submit") == "submit":
            pushed = self._action_tag(self._submitter(form, a.get("data-arg", "")), look)
        elif tag == "a" and a.get("href", "").startswith(("http://", "https://")):
            url = a["href"]
            import webbrowser
            pushed = self._action_tag(lambda: webbrowser.open(url))
        else:
            pushed = ()
        self.links.append(pushed)
        self.tags.extend(pushed)
        if look == "button" and pushed:
            self._insert(" ")

    def _input(self, a):
        kind = a.get("type", "text").lower()
        form = self.forms[-1] if self.forms else None
        name = a.get("name", "")
        if kind == "hidden":
            if form is not None and name:
                form["fixed"][name] = a.get("value", "")
            return
        if kind in ("submit", "button"):
            if form is not None and kind == "submit":
                look = self._action_tag(self._submitter(form), "button")
                self._insert(" %s " % (a.get("value") or "OK"), look)
            return
        if kind in ("checkbox", "radio"):
            var = tk.StringVar(value=a.get("value", "on") if "checked" in a else "")
            box = tk.Checkbutton(self.text, variable=var, onvalue=a.get("value", "on"),
                                 offvalue="", bg=self.text.cget("bg"), bd=0)
            self._embed(box)
            if form is not None and name:
                form["fields"].append((name, lambda v=var: v.get() or None))
            return
        var = tk.StringVar(value=a.get("value", ""))
        entry = ttk.Entry(self.text, textvariable=var,
                          width=int(a.get("size") or 28),
                          show="•" if kind == "password" else "")
        self._embed(entry)
        if form is not None and name:
            form["fields"].append((name, var.get))

    def handle_endtag(self, tag):
        if tag in DesignHtml.SKIP:
            self.skip = max(0, self.skip - 1)
            return
        if self.skip:
            return
        if tag == "textarea" and self.area is not None:
            a, parts = self.area
            self.area = None
            var = tk.StringVar(value="".join(parts).strip())
            self._embed(ttk.Entry(self.text, textvariable=var, width=40))
            if self.forms and a.get("name"):
                self.forms[-1]["fields"].append((a["name"], var.get))
            return
        if tag == "select" and self.select is not None:
            a, options, chosen = self.select
            self.select = None
            labels = [label.strip() for _, label in options]
            values = [label.strip() if v is None else v for v, label in options]
            box = ttk.Combobox(self.text, values=labels, state="readonly",
                               width=max([10] + [len(x) for x in labels]) + 2)
            if labels:
                box.current(chosen[0] or 0)
            self._embed(box)
            if self.forms and a.get("name"):
                self.forms[-1]["fields"].append(
                    (a["name"], lambda b=box, v=values: v[b.current()] if b.current() >= 0 else ""))
            return
        if tag in ("a", "button") and self.links:
            pushed = self.links.pop()
            if pushed and pushed[0] == "button":
                self._insert(" ")
            for t in pushed:
                if t in self.tags:
                    self.tags.remove(t)
        if tag == "li" and "li" in self.tags:
            self.tags.remove("li")
        if tag in DesignHtml.INLINE:
            name = DesignHtml.INLINE[tag]
            if name in self.tags:
                self.tags.reverse()
                self.tags.remove(name)
                self.tags.reverse()
        if tag == "pre":
            self.pre = max(0, self.pre - 1)
        elif tag in ("ul", "ol") and self.lists:
            self.lists.pop()
        elif tag == "form" and self.forms:
            self.forms.pop()
        if tag in DesignHtml.BLOCKS:
            self._newline(tag in DesignHtml.SPACED)

    def handle_data(self, data):
        if self.skip:
            return
        if self.area is not None:
            self.area[1].append(data)
            return
        if self.select is not None:
            if self.select[1]:
                self.select[1][-1][1] += data
            return
        if not self.pre:
            import re
            data = re.sub(r"\s+", " ", data)
            if self._last() in ("", "\n"):
                data = data.lstrip()
        if data:
            self._insert(data)
''';
