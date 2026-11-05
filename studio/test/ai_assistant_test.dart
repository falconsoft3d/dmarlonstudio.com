import 'dart:convert';
import 'dart:io';

import 'package:dmarlon_studio/code/tk_codegen.dart';
import 'package:dmarlon_studio/code/tk_examples.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Un SDK de Anthropic falso: apunta lo que se le pide y responde según el
/// esquema, sin red ni clave.
const _fakeSdk = r'''
import json, types
CALLS = []
class BadRequestError(Exception): pass
class AuthenticationError(Exception): pass
class RateLimitError(Exception): pass
class APIConnectionError(Exception): pass
class APIStatusError(Exception):
    status_code = 500
    message = "x"
class Block:
    def __init__(self, type, text=""):
        self.type, self.text = type, text
class Response:
    def __init__(self, text):
        self.content = [Block("thinking"), Block("text", text)]
        self.stop_reason = "end_turn"
def answer(params):
    CALLS.append(dict(params, messages=list(params["messages"])))
    fmt = params.get("output_config", {}).get("format")
    if fmt:
        props = fmt["schema"]["properties"]
        if "label" in props:
            return Response(json.dumps({"label": props["label"]["enum"][0]}))
        return Response(json.dumps({k: "x" for k in props}))
    last = params["messages"][-1]["content"]
    return Response("eco: " + (last if isinstance(last, str) else last[-1]["text"])[:40])
class _Messages:
    def create(self, **params):
        return answer(params)
class _Beta:
    def __init__(self):
        self.messages = _Messages()
class Anthropic:
    def __init__(self):
        self.messages = _Messages()
        self.beta = _Beta()
''';

const _harness = r'''
import importlib.util, json, os, sys, time
sys.path.insert(0, sys.argv[2])
import anthropic
os.chdir(os.path.dirname(sys.argv[1]))
spec = importlib.util.spec_from_file_location("form", sys.argv[1])
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
out = {}
f = m.Form1()
f.root.withdraw()
f.root.update()
def settle():
    end = time.time() + 5
    while time.time() < end and f.Ai1.busy:
        f.root.update(); time.sleep(0.02)
    f.root.update()
def result(): return f.Result.get("1.0", "end").strip()

f.BtnRun_click(); settle()
first = anthropic.CALLS[0]
out["check_request"] = (first["model"] == "claude-opus-5-5" and first["output_config"]["effort"] == "medium"
                        and first.get("fallbacks") == "default" and "server-side-fallback-2026-07-01" in first.get("betas", [])
                        and "español" in first["system"])
out["check_summary"] = result().startswith("eco:")
f.Action_var.set(m.ACTIONS[2]); f.BtnRun_click(); settle()
out["check_classify"] = result() == m.SENTIMENTS[0]
f.Action_var.set(m.ACTIONS[3]); f.BtnRun_click(); settle()
out["check_extract"] = set(json.loads(result())) == set(m.FIELDS)
f.Message_var.set("Hola"); f.BtnSend_click(); settle()
f.Message_var.set("¿Y tú?"); f.BtnSend_click(); settle()
last = anthropic.CALLS[-1]["messages"]
out["check_chat_memory"] = len(last) == 3 and last[1]["role"] == "assistant"
out["check_history"] = "Claude: eco: ¿Y tú?" in f.History.get("1.0", "end")
f.BtnNewChat_click()
out["check_reset"] = f.Ai1.history == []
out["check_idle"] = str(f.BtnRun.cget("state")) == "normal"
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
  test('asistente IA: peticiones, esquemas, chat con memoria', () async {
    final tmp = await Directory.systemTemp.createTemp('dms_ai_');
    addTearDown(() => tmp.delete(recursive: true));
    final sdk = Directory(p.join(tmp.path, 'fake'))..createSync();
    File(p.join(sdk.path, 'anthropic.py')).writeAsStringSync(_fakeSdk);
    final e = tkExamples((s) => s).firstWhere((e) => e.seed == 'ai_texts');
    expect(e.design.problems(), isEmpty);
    final path = p.join(tmp.path, 'app.py');
    await File(path).writeAsString(TkCodegen.generate(e.design, e.code));
    final c = await Process.run('python3', ['-m', 'py_compile', path]);
    expect(c.exitCode, 0, reason: '${c.stderr}');
    final web = tkWebExamples(
      (s) => s,
    ).firstWhere((e) => e.seed == 'web_ai_texts');
    final webPath = p.join(tmp.path, 'web.py');
    await File(webPath).writeAsString(TkCodegen.generate(web.design, web.code));
    final w = await Process.run('python3', ['-m', 'py_compile', webPath]);
    expect(w.exitCode, 0, reason: '${w.stderr}');
    final py = await _python();
    if (py == null) return markTestSkipped('Sin Python con tkinter.');
    final r = await Process.run(py, ['-c', _harness, path, sdk.path]);
    expect(r.exitCode, 0, reason: '${r.stdout}\n${r.stderr}');
    final out = jsonDecode('${r.stdout}'.trim().split('\n').last) as Map;
    expect(out['ok'], isTrue, reason: '$out\n${r.stderr}');
  });
}
