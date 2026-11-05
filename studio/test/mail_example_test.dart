import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Prueba el ejemplo de correo con tkinter de verdad y servidores IMAP y
/// SMTP falsos (sin red).
const _harness = r'''
import importlib.util, json, os, sys, time
from email.message import EmailMessage
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def raw(i, subject):
    msg = EmailMessage()
    msg["From"] = "Ana <ana@example.com>"
    msg["To"] = "yo@example.com"
    msg["Subject"] = subject
    msg["Date"] = "Thu, 05 Nov 2026 10:%02d:00 +0100" % i
    msg.set_content("Hola %d\nSegunda línea" % i)
    return msg.as_bytes()

SENT = []

class FakeImap:
    def __init__(self, host, port, ssl_context=None):
        assert host == "imap.test" and port == 993
    def __enter__(self): return self
    def __exit__(self, *a): pass
    def login(self, user, password):
        if password != "secreto":
            raise m.imaplib.IMAP4.error("AUTHENTICATIONFAILED")
    def select(self, box, readonly=False): return ("OK", [b"3"])
    def search(self, charset, query): return ("OK", [b"1 2 3"])
    def fetch(self, num, what):
        i = int(num)
        return ("OK", [(b"%d (RFC822)" % i, raw(i, "Asunto %d" % i)), b")"])

class FakeSmtp:
    def __init__(self, host, port, context=None):
        self.host = host
    def __enter__(self): return self
    def __exit__(self, *a): pass
    def starttls(self, context=None): pass
    def login(self, user, password): pass
    def send_message(self, msg): SENT.append(msg)

m.imaplib.IMAP4_SSL = FakeImap
m.smtplib.SMTP = FakeSmtp
m.smtplib.SMTP_SSL = FakeSmtp
m.messagebox.showwarning = lambda *a, **k: "ok"

out = {}
f = m.Form1()
f.root.withdraw()
# Como el bucle de la ventana: se ejecuta «Al abrir».
f.root.update()

def settle(cond, timeout=5):
    end = time.time() + timeout
    while time.time() < end and not cond():
        f.root.update()
        time.sleep(0.02)
    return cond()

# Sin cuenta no se conecta: avisa y va a la pestaña Cuenta.
f.BtnRefresh_click()
out["check_no_account"] = f.Inbox.get_children() == ()

f.Email_var.set("yo@example.com")
f.Secret_var.set("secreto")
f.ImapHost_var.set("imap.test")
f.SmtpHost_var.set("smtp.test")
f.KeepPassword_var.set(0)
f.BtnSaveAccount_click()
saved = json.load(open("account.json"))
out["check_no_password_saved"] = "password" not in saved and saved["imap_host"] == "imap.test"

f.BtnRefresh_click()
out["check_received"] = settle(lambda: len(f.Inbox.get_children()) == 3)
first = f.Inbox.get_children()[0]
out["check_newest_first"] = f.Inbox.item(first)["values"][1] == "Asunto 3"
f.Inbox.selection_set(first)
f.Inbox_select()
out["check_preview"] = "Hola 3" in f.Preview.get("1.0", "end")

f.BtnReply_click()
out["check_reply"] = (f.To_var.get() == "ana@example.com"
                      and f.Subject_var.get() == "Re: Asunto 3"
                      and "> Hola 3" in f.Body.get("1.0", "end"))

with open("nota.txt", "w") as fh:
    fh.write("adjunto")
f.attachments = [os.path.abspath("nota.txt")]
f.show_attachments()
f.BtnSend_click()
out["check_sent"] = settle(lambda: len(SENT) == 1)
msg = SENT[0]
names = [a.get_filename() for a in msg.iter_attachments()]
out["check_message"] = msg["To"] == "ana@example.com" and names == ["nota.txt"]
out["check_cleared"] = settle(lambda: f.To_var.get() == "" and f.attachments == [])

# Una contraseña errónea no rompe nada: lo dice la barra de estado.
f.Secret_var.set("mala")
f.BtnTest_click()
out["check_error_shown"] = settle(lambda: "AUTHENTICATIONFAILED" in f.Status.cget("text"))
f.root.destroy()
out["ok"] = all(v for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out))
''';

Future<String?> _python() async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
    '/opt/homebrew/bin/python3',
    '/usr/local/bin/python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, [
        '-c',
        'import tkinter; tkinter.Tk().destroy()',
      ]);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

void main() {
  late Directory tmp;
  late String path;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_mail_');
    final e = tkExamples((s) => s).firstWhere((e) => e.seed == 'mail_client');
    expect(e.design.problems(), isEmpty);
    path = p.join(tmp.path, 'app.py');
    await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
  });

  tearDown(() => tmp.delete(recursive: true));

  test('genera Python válido', () async {
    final r = await Process.run('python3', ['-m', 'py_compile', path]);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  });

  test('recibir, leer, responder y enviar con servidores falsos', () async {
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final r = await Process.run(py, ['-c', _harness, path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
  });
}
