part of 'tk_examples.dart';

// ------------------------------------------------------------------ correo
/// Cliente de correo: recibe por IMAP, envía por SMTP (con adjuntos) y
/// guarda la cuenta en la carpeta del proyecto. Solo la biblioteca estándar
/// de Python; la red va en un hilo para no congelar la ventana.
TkExample _mail(String Function(String) t) {
  final app = t(markTr('Correo'));
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  TkWidget label(String name, int x, int y, String text, int page) =>
      on(_w('Label', name, x, y, 120, 24, _label(text)), page);
  TkWidget entry(String name, int x, int y, int width, int page) =>
      on(_w('Entry', name, x, y, width, 26), page);
  final pages = [
    t(markTr('Bandeja de entrada')),
    t(markTr('Redactar')),
    t(markTr('Cuenta')),
  ].join('\n');
  final design =
      TkDesign(
          width: 880,
          height: 620,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('PageControl', 'Pages', 8, 8, 864, 580, {'pages': pages}),
          // Bandeja de entrada.
          on(
            _w(
              'Button',
              'BtnRefresh',
              16,
              40,
              136,
              30,
              {'text': t(markTr('Recibir'))},
              {'command': 'BtnRefresh_click'},
            ),
            0,
          ),
          on(
            _w(
              'Label',
              'InboxInfo',
              168,
              43,
              520,
              24,
              _label(
                t(markTr('Pulse «Recibir» para traer los últimos mensajes.')),
              ),
            ),
            0,
          ),
          on(
            _w(
              'Button',
              'BtnReply',
              712,
              40,
              136,
              30,
              {'text': t(markTr('Responder'))},
              {'command': 'BtnReply_click'},
            ),
            0,
          ),
          on(
            _w(
              'Treeview',
              'Inbox',
              16,
              80,
              832,
              220,
              {
                'columns': [
                  'from|${t(markTr('De'))}|220',
                  'subject|${t(markTr('Asunto'))}|440',
                  'date|${t(markTr('Fecha'))}|150',
                ].join('\n'),
              },
              {'select': 'Inbox_select'},
            ),
            0,
          ),
          on(_w('Text', 'Preview', 16, 312, 832, 248, {'wrap': 'word'}), 0),
          // Redactar.
          label('LblTo', 16, 44, t(markTr('Para')), 1),
          entry('To', 136, 42, 712, 1),
          label('LblSubject', 16, 80, t(markTr('Asunto')), 1),
          entry('Subject', 136, 78, 712, 1),
          on(_w('Text', 'Body', 16, 116, 832, 384, {'wrap': 'word'}), 1),
          on(
            _w(
              'Button',
              'BtnAttach',
              16,
              516,
              136,
              30,
              {'text': t(markTr('Adjuntar…'))},
              {'command': 'BtnAttach_click'},
            ),
            1,
          ),
          on(
            _w(
              'Label',
              'Attached',
              168,
              519,
              440,
              24,
              _label(t(markTr('Sin adjuntos'))),
            ),
            1,
          ),
          on(
            _w(
              'Button',
              'BtnSend',
              712,
              516,
              136,
              30,
              {'text': t(markTr('Enviar'))},
              {'command': 'BtnSend_click'},
            ),
            1,
          ),
          // Cuenta.
          label('LblEmail', 16, 44, t(markTr('Correo')), 2),
          entry('Email', 160, 42, 320, 2),
          label('LblUser', 16, 80, t(markTr('Usuario')), 2),
          entry('User', 160, 78, 320, 2),
          label('LblPassword', 16, 116, t(markTr('Contraseña')), 2),
          on(_w('Password', 'Secret', 160, 114, 320, 26), 2),
          label('LblImap', 16, 164, t(markTr('Servidor IMAP')), 2),
          entry('ImapHost', 160, 162, 240, 2),
          entry('ImapPort', 408, 162, 72, 2),
          label('LblSmtp', 16, 200, t(markTr('Servidor SMTP')), 2),
          entry('SmtpHost', 160, 198, 240, 2),
          entry('SmtpPort', 408, 198, 72, 2),
          on(
            _w('Checkbutton', 'KeepPassword', 160, 236, 320, 24, {
              'text': t(markTr('Recordar la contraseña en este equipo')),
            }),
            2,
          ),
          on(
            _w(
              'Label',
              'AccountHelp',
              500,
              44,
              348,
              200,
              _label(
                t(
                  markTr(
                    'IMAP con SSL (puerto 993) para recibir y SMTP con STARTTLS (587) o SSL (465) para enviar. En Gmail y Outlook use una contraseña de aplicación. La contraseña solo se guarda si marca la casilla, en account.json dentro del proyecto: no lo suba a GitHub.',
                  ),
                ),
              )..['wraplength'] = 340,
            ),
            2,
          ),
          on(
            _w(
              'Button',
              'BtnSaveAccount',
              160,
              276,
              152,
              30,
              {'text': t(markTr('Guardar la cuenta'))},
              {'command': 'BtnSaveAccount_click'},
            ),
            2,
          ),
          on(
            _w(
              'Button',
              'BtnTest',
              328,
              276,
              152,
              30,
              {'text': t(markTr('Probar la conexión'))},
              {'command': 'BtnTest_click'},
            ),
            2,
          ),
          _w('Progressbar', 'Busy', 720, 14, 144, 12, {
            'mode': 'indeterminate',
          }),
          _w('OpenDialog', 'AttachFile', 840, 8, 24, 24, {
            'title': t(markTr('Adjuntar un archivo')),
            'multiple': true,
          }),
          _w('StatusBar', 'Status', 0, 596, 880, 24, {
            'text': t(markTr('Listo')),
            'icon': 'mail',
          }),
        ]);
  final code =
      '''import email
import email.policy
import imaplib
import json
import mimetypes
import os
import queue
import smtplib
import ssl
import threading
from email.header import decode_header, make_header
from email.message import EmailMessage
from email.utils import parseaddr, parsedate_to_datetime
from tkinter import messagebox

APP = ${_py(app)}
ACCOUNT = "account.json"
LAST = 30
T_RECEIVING = ${_py(t(markTr('Recibiendo…')))}
T_RECEIVED = ${_py(t(markTr('{0} mensajes en la bandeja de entrada (se muestran los últimos {1}).')))}
T_SENDING = ${_py(t(markTr('Enviando…')))}
T_SENT = ${_py(t(markTr('Mensaje enviado a {0}.')))}
T_TESTING = ${_py(t(markTr('Probando la conexión…')))}
T_TEST_OK = ${_py(t(markTr('IMAP y SMTP responden: la cuenta funciona.')))}
T_SAVED = ${_py(t(markTr('Cuenta guardada.')))}
T_NO_ACCOUNT = ${_py(t(markTr('Configure primero la cuenta en la pestaña «Cuenta».')))}
T_NO_TO = ${_py(t(markTr('Escriba al menos un destinatario.')))}
T_ERROR = ${_py(t(markTr('Error: {0}')))}
T_NO_ATTACH = ${_py(t(markTr('Sin adjuntos')))}
T_ATTACHED = ${_py(t(markTr('{0} adjuntos: {1}')))}
T_REPLY = ${_py(t(markTr('El {0}, {1} escribió:')))}
T_NO_SUBJECT = ${_py(t(markTr('(sin asunto)')))}


def decoded(value):
    """Cabecera legible (los asuntos pueden venir codificados)."""
    try:
        return str(make_header(decode_header(value or "")))
    except Exception:
        return value or ""


def body_of(msg):
    """Texto del mensaje: la parte text/plain o, si no hay, el HTML sin más."""
    if msg.is_multipart():
        for part in msg.walk():
            if part.get_content_type() == "text/plain" and not part.get_filename():
                return part.get_content()
        for part in msg.walk():
            if part.get_content_type() == "text/html":
                return part.get_content()
        return ""
    return msg.get_content()


class MailAccount:
    """La cuenta y sus dos servidores."""

    def __init__(self, data):
        self.email = data.get("email", "").strip()
        self.user = data.get("user", "").strip() or self.email
        self.password = data.get("password", "")
        self.imap_host = data.get("imap_host", "").strip()
        self.imap_port = int(data.get("imap_port") or 993)
        self.smtp_host = data.get("smtp_host", "").strip()
        self.smtp_port = int(data.get("smtp_port") or 587)

    @property
    def ready(self):
        return bool(self.email and self.password and self.imap_host and self.smtp_host)

    def receive(self, last=LAST):
        """[(id, de, asunto, fecha, texto)] de los últimos mensajes."""
        context = ssl.create_default_context()
        with imaplib.IMAP4_SSL(self.imap_host, self.imap_port, ssl_context=context) as box:
            box.login(self.user, self.password)
            box.select("INBOX", readonly=True)
            status, data = box.search(None, "ALL")
            ids = data[0].split()
            out = []
            for num in reversed(ids[-last:]):
                status, parts = box.fetch(num, "(RFC822)")
                raw = next(p[1] for p in parts if isinstance(p, tuple))
                msg = email.message_from_bytes(raw, policy=email.policy.default)
                try:
                    date = parsedate_to_datetime(msg["Date"]).strftime("%d/%m/%Y %H:%M")
                except Exception:
                    date = msg["Date"] or ""
                out.append((
                    num.decode(),
                    decoded(msg["From"]),
                    decoded(msg["Subject"]) or T_NO_SUBJECT,
                    date,
                    body_of(msg),
                ))
            return len(ids), out

    def send(self, to, subject, body, attachments=()):
        msg = EmailMessage()
        msg["From"] = self.email
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        for path in attachments:
            kind, _ = mimetypes.guess_type(path)
            main, sub = (kind or "application/octet-stream").split("/", 1)
            with open(path, "rb") as f:
                msg.add_attachment(f.read(), maintype=main, subtype=sub,
                                   filename=os.path.basename(path))
        context = ssl.create_default_context()
        if self.smtp_port == 465:
            server = smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, context=context)
        else:
            server = smtplib.SMTP(self.smtp_host, self.smtp_port)
            server.starttls(context=context)
        with server:
            server.login(self.user, self.password)
            server.send_message(msg)

    def test(self):
        context = ssl.create_default_context()
        with imaplib.IMAP4_SSL(self.imap_host, self.imap_port, ssl_context=context) as box:
            box.login(self.user, self.password)
        if self.smtp_port == 465:
            server = smtplib.SMTP_SSL(self.smtp_host, self.smtp_port, context=context)
        else:
            server = smtplib.SMTP(self.smtp_host, self.smtp_port)
            server.starttls(context=context)
        with server:
            server.login(self.user, self.password)


class Form1(FormDesign):
    def form_create(self):
        self.messages = {}
        self.attachments = []
        self.jobs = queue.Queue()
        self.load_account()
        self.root.after(100, self.poll)

    # ------------------------------------------------------------- cuenta
    def load_account(self):
        data = {}
        if os.path.exists(ACCOUNT):
            with open(ACCOUNT, encoding="utf-8") as f:
                data = json.load(f)
        self.Email_var.set(data.get("email", ""))
        self.User_var.set(data.get("user", ""))
        self.Secret_var.set(data.get("password", ""))
        self.KeepPassword_var.set(1 if data.get("password") else 0)
        self.ImapHost_var.set(data.get("imap_host", "imap.gmail.com"))
        self.ImapPort_var.set(str(data.get("imap_port", 993)))
        self.SmtpHost_var.set(data.get("smtp_host", "smtp.gmail.com"))
        self.SmtpPort_var.set(str(data.get("smtp_port", 587)))

    def account_data(self):
        return {
            "email": self.Email_var.get().strip(),
            "user": self.User_var.get().strip(),
            "password": self.Secret_var.get(),
            "imap_host": self.ImapHost_var.get().strip(),
            "imap_port": int(self.ImapPort_var.get() or 993),
            "smtp_host": self.SmtpHost_var.get().strip(),
            "smtp_port": int(self.SmtpPort_var.get() or 587),
        }

    def account(self):
        return MailAccount(self.account_data())

    def BtnSaveAccount_click(self):
        data = self.account_data()
        if not self.KeepPassword_var.get():
            data.pop("password")
        with open(ACCOUNT, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
        self.Status.set(T_SAVED, icon="check")

    # ----------------------------------------------- red en segundo plano
    def background(self, label, work, done):
        """Ejecuta work() en un hilo y luego done(resultado) en la ventana."""
        account = self.account()
        if not account.ready:
            messagebox.showwarning(APP, T_NO_ACCOUNT, parent=self.root)
            self.Pages.select(2)
            return
        self.Status.set(label, icon="refresh")
        self.Busy.start(12)

        def job():
            try:
                self.jobs.put((done, work(account), None))
            except Exception as error:
                self.jobs.put((done, None, error))

        threading.Thread(target=job, daemon=True).start()

    def poll(self):
        try:
            while True:
                done, result, error = self.jobs.get_nowait()
                self.Busy.stop()
                if error is not None:
                    self.Status.set(T_ERROR.format(error), icon="warning")
                else:
                    done(result)
        except queue.Empty:
            pass
        self.root.after(100, self.poll)

    # ------------------------------------------------------------ recibir
    def BtnRefresh_click(self):
        self.background(T_RECEIVING, lambda account: account.receive(), self.received)

    def received(self, result):
        total, rows = result
        self.Inbox.delete(*self.Inbox.get_children())
        self.messages = {}
        for num, sender, subject, date, body in rows:
            self.messages[num] = (sender, subject, date, body)
            self.Inbox.insert("", "end", iid=num, values=(sender, subject, date))
        text = T_RECEIVED.format(total, min(total, LAST))
        self.InboxInfo.configure(text=text)
        self.Status.set(text, icon="mail")

    def Inbox_select(self, event=None):
        chosen = self.Inbox.selection()
        if not chosen:
            return
        sender, subject, date, body = self.messages[chosen[0]]
        self.Preview.delete("1.0", "end")
        self.Preview.insert("1.0", "%s\\n%s\\n%s\\n\\n%s" % (sender, subject, date, body))

    def BtnReply_click(self):
        chosen = self.Inbox.selection()
        if not chosen:
            return
        sender, subject, date, body = self.messages[chosen[0]]
        self.To_var.set(parseaddr(sender)[1])
        self.Subject_var.set(subject if subject.lower().startswith("re:") else "Re: " + subject)
        quoted = "\\n".join("> " + line for line in body.splitlines())
        self.Body.delete("1.0", "end")
        self.Body.insert("1.0", "\\n\\n" + T_REPLY.format(date, sender) + "\\n" + quoted)
        self.Pages.select(1)
        self.Body.mark_set("insert", "1.0")
        self.Body.focus_set()

    # ------------------------------------------------------------- enviar
    def BtnAttach_click(self):
        paths = self.AttachFile.execute()
        if paths:
            self.attachments.extend(paths if isinstance(paths, list) else [paths])
        self.show_attachments()

    def show_attachments(self):
        names = ", ".join(os.path.basename(p) for p in self.attachments)
        self.Attached.configure(
            text=T_ATTACHED.format(len(self.attachments), names) if self.attachments else T_NO_ATTACH
        )

    def BtnSend_click(self):
        to = self.To_var.get().strip()
        if not to:
            messagebox.showwarning(APP, T_NO_TO, parent=self.root)
            return
        subject = self.Subject_var.get().strip()
        body = self.Body.get("1.0", "end-1c")
        files = list(self.attachments)
        self.background(
            T_SENDING,
            lambda account: account.send(to, subject, body, files),
            lambda result: self.sent(to),
        )

    def sent(self, to):
        self.To_var.set("")
        self.Subject_var.set("")
        self.Body.delete("1.0", "end")
        self.attachments = []
        self.show_attachments()
        self.Status.set(T_SENT.format(to), icon="check")

    def BtnTest_click(self):
        self.background(
            T_TESTING,
            lambda account: account.test(),
            lambda result: self.Status.set(T_TEST_OK, icon="check"),
        )

    def form_close(self, *args):
        self.root.destroy()
''';
  return TkExample(
    'mail_client',
    app,
    t(
      markTr(
        'Cliente de correo: recibir por IMAP, leer, responder y enviar por SMTP con adjuntos, sin congelar la ventana.',
      ),
    ),
    design,
    code,
  );
}
