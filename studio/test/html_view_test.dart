import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _html = '''<style>.x{color:red}</style>
<h1>Tienda &amp; blog</h1>
<p>Hola <b>mundo</b> <a href="#" data-action="open" data-arg="7">Leer</a></p>
<ul><li>Uno</li><li>Dos</li></ul>
<form data-action="search">
  <input type="hidden" name="page" value="2">
  <input name="q" value="sillas">
  <select name="sort"><option value="new">Nuevos</option><option value="cheap" selected>Baratos</option></select>
  <button type="submit">Buscar</button>
</form>''';

TkDesign htmlDesign({bool web = false, bool full = false}) =>
    TkDesign(
        width: 600,
        height: 400,
        target: web ? tkTargetWeb : tkTargetDesktop,
      )
      ..widgets.add(
        TkWidget(
          kind: 'HtmlView',
          name: 'Html1',
          x: 10,
          y: 10,
          width: 560,
          height: 360,
          props: {'html': _html, if (full) 'full_page': true},
          events: {'action': 'Html1_action'},
        ),
      );

const _unit = '''import html


class Form1(FormDesign):
    def Html1_action(self, action):
        self.last = (action.name, action.arg, dict(action.form))
        if action.name == "open":
            self.Html1.set_html("<h2>Art&iacute;culo %s</h2>" % html.escape(action.arg), top=True)
''';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dms_html_');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<String> write(String name, String source) async {
    final dir = Directory(p.join(tmp.path, name));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'app.py'));
    await file.writeAsString(source);
    return file.path;
  }

  Future<void> run(
    String py,
    String path,
    String harness,
    String scenario,
  ) async {
    final r = await Process.run(py, [
      '-c',
      harness,
      path,
      p.dirname(path),
      scenario,
    ]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '${r.stdout}\n${r.stderr}');
  }

  test('la Vista HTML está en la paleta y su evento llega a la web', () {
    final c = tkComponent('HtmlView')!;
    expect(c.visual, isTrue);
    expect(c.events.single.key, 'action');
    expect(tkWebHasEvent(c.events.single), isTrue);
    expect(htmlDesign().problems(), isEmpty);
  });

  test('de verdad en Flask: enlaces y formularios', () async {
    final py = await _python('import flask');
    if (py == null) return markTestSkipped('Sin Python con Flask.');
    await run(
      py,
      await write('web', TkCodegen.generate(htmlDesign(web: true), _unit)),
      _webHarness,
      _web,
    );
  });

  test('de verdad en Flask: página completa', () async {
    final py = await _python('import flask');
    if (py == null) return markTestSkipped('Sin Python con Flask.');
    await run(
      py,
      await write(
        'full',
        TkCodegen.generate(htmlDesign(web: true, full: true), _unit),
      ),
      _webHarness,
      _webFull,
    );
  });

  test('de verdad en tkinter: texto, enlaces y formularios', () async {
    final py = await _python('import tkinter; tkinter.Tk().destroy()');
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    await run(
      py,
      await write('tk', TkCodegen.generate(htmlDesign(), _unit)),
      _desktopHarness,
      _desktop,
    );
  });
}

Future<String?> _python(String check) async {
  final home = Platform.environment['HOME'] ?? '';
  for (final py in [
    'python3',
    '$home/micromamba/bin/python3',
    '/opt/homebrew/bin/python3',
    '/usr/local/bin/python3',
    '/usr/bin/python3',
  ]) {
    try {
      final r = await Process.run(py, ['-c', check]);
      if (r.exitCode == 0) return py;
    } on ProcessException {
      // No está.
    }
  }
  return null;
}

const _webHarness = r'''
import importlib.util, json, os, re, sys
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
client = m.app.test_client()
page = client.get("/").get_data(as_text=True)
boot = json.loads(re.search(r'id="tk-boot">(.*?)</script>', page).group(1))
headers = {"X-DMS-CSRF": boot["csrf"], "X-DMS-Process": boot["process"]}
def post(body):
    body = dict(body, sid=boot["sid"])
    reply = client.post("/event", json=body, headers=headers)
    assert reply.status_code == 200, reply.status_code
    return reply.get_json()
out = {}
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
''';

const _web = r'''
out["check_rendered"] = '<div id="Html1" class="tk tk-html"' in page and "<h1>Tienda &amp; blog</h1>" in page
out["check_framed"] = 'class="tk-form"' in page and "left:10px" in page
out["check_js"] = '.tk-html [data-action]' in page and 'addEventListener("submit"' in page
reply = post({"widget": "Html1", "event": "action", "data": {"action": "open", "arg": "7"}})
out["check_set_html"] = "<h2>Art&iacute;culo 7</h2>" in reply["html"].get("Html1", "")
out["check_top"] = reply.get("scroll_top") is True
reply = post({"widget": "Html1", "event": "action", "data": {"action": "open", "arg": "<script>"}})
out["check_escaped"] = "&lt;script&gt;" in reply["html"]["Html1"] and "<script>" not in reply["html"]["Html1"]
reply = post({"widget": "Html1", "event": "action", "data": {"action": "search", "form": {"q": "mesa", "sort": "cheap", "tag": ["a", 2]}}})
out["check_form"] = reply["notes"] == [] and "scroll_top" not in reply
reply = post({"widget": "Html1", "event": "submit", "data": {}})
out["check_unknown_event"] = reply.get("html") == {}
''';

const _webFull = r'''
out["check_full"] = 'class="tk-full"' in page and 'class="tk-form"' not in page
out["check_no_box"] = "tk-html tk-html-full" in page and "left:10px" not in page
reply = post({"widget": "Html1", "event": "action", "data": {"action": "open", "arg": "3"}})
out["check_set_html"] = "Art&iacute;culo 3" in reply["html"]["Html1"]
''';

const _desktopHarness = r'''
import importlib.util, json, os, sys
os.chdir(sys.argv[2])
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
f = m.Form1()
f.root.withdraw()
for _ in range(5):
    f.root.update()
exec(sys.argv[3])
out["ok"] = all(v is True for k, v in out.items() if k.startswith("check_"))
print(json.dumps(out, default=str))
try:
    f.root.destroy()
except Exception:
    pass
''';

const _desktop = r'''
v = f.Html1
text = v.text.get("1.0", "end")
out["text"] = text
out["check_text"] = "Tienda & blog" in text and "Hola mundo Leer" in text and "• Uno" in text
out["check_no_style"] = "color:red" not in text
out["check_tags"] = "h1" in v.text.tag_names("1.0")
out["check_fields"] = len(v._widgets) == 2
links = sorted(v._actions)
out["check_links"] = len(links) == 2
v._actions[links[1]]()
out["search"] = f.last
out["check_search"] = f.last == ("search", "", {"page": "2", "q": "sillas", "sort": "cheap"})
v._actions[links[0]]()
out["check_open"] = f.last[:2] == ("open", "7") and "Artículo 7" in v.text.get("1.0", "end")
out["check_cleared"] = v._widgets == [] and len(v._actions) == 0
''';
