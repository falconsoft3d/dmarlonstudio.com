part of 'tk_examples.dart';

// ------------------------------------------------------ asistente de textos
/// El componente Asistente IA: resumir, traducir, clasificar y extraer
/// datos de un texto, y un chat con memoria, sin congelar la ventana.
TkExample _aiTexts(String Function(String) t) {
  final app = t(markTr('Asistente de textos'));
  TkWidget on(TkWidget w, int page) => w
    ..parent = 'Pages'
    ..page = page;
  final actions = [
    t(markTr('Resumir')),
    t(markTr('Traducir al inglés')),
    t(markTr('Clasificar el sentimiento')),
    t(markTr('Extraer datos de contacto')),
  ];
  final pages = [t(markTr('Textos')), t(markTr('Chat'))].join('\n');
  final design =
      TkDesign(
          width: 860,
          height: 600,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('PageControl', 'Pages', 8, 8, 844, 560, {'pages': pages}),
          // Textos.
          on(
            _w('Label', 'LblSource', 16, 40, 400, 24, {
              ..._label(t(markTr('Texto'))),
            }),
            0,
          ),
          on(
            _w('Text', 'Source', 16, 64, 812, 180, {
              'wrap': 'word',
              'text': t(
                markTr(
                  'Hola, soy Laura Gómez, de Talleres Norte. Me encantó la demostración de ayer: el equipo está muy contento y queremos el plan anual. Escríbame a laura@talleresnorte.es o llámeme al 600 123 456.',
                ),
              ),
            }),
            0,
          ),
          on(
            _w('Combobox', 'Action', 16, 256, 320, 30, {
              'items': actions.join('\n'),
              'text': actions[0],
              'state': 'readonly',
            }),
            0,
          ),
          on(
            _w(
              'Button',
              'BtnRun',
              352,
              254,
              200,
              34,
              {'text': t(markTr('Pedir a Claude'))},
              {'command': 'BtnRun_click'},
            ),
            0,
          ),
          on(
            _w('Progressbar', 'Busy', 568, 264, 260, 14, {
              'mode': 'indeterminate',
            }),
            0,
          ),
          on(
            _w('Label', 'LblResult', 16, 300, 400, 24, {
              ..._label(t(markTr('Resultado'))),
            }),
            0,
          ),
          on(_w('Text', 'Result', 16, 324, 812, 220, {'wrap': 'word'}), 0),
          // Chat.
          on(_w('Text', 'History', 16, 40, 812, 440, {'wrap': 'word'}), 1),
          on(
            _w('Entry', 'Message', 16, 494, 560, 32, {}, {
              'return': 'BtnSend_click',
            }),
            1,
          ),
          on(
            _w(
              'Button',
              'BtnSend',
              588,
              492,
              112,
              36,
              {'text': t(markTr('Enviar'))},
              {'command': 'BtnSend_click'},
            ),
            1,
          ),
          on(
            _w(
              'Button',
              'BtnNewChat',
              712,
              492,
              116,
              36,
              {'text': t(markTr('Nueva'))},
              {'command': 'BtnNewChat_click'},
            ),
            1,
          ),
          _w(
            'AiAssistant',
            'Ai1',
            820,
            8,
            24,
            24,
            {
              'system': t(
                markTr('Responde en español, de forma clara y breve.'),
              ),
            },
            {'done': 'Ai1_done', 'error': 'Ai1_error'},
          ),
          _w('StatusBar', 'Status', 0, 576, 860, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import json

ACTIONS = [${actions.map(_py).join(', ')}]
SENTIMENTS = [${[t(markTr('positivo')), t(markTr('neutral')), t(markTr('negativo'))].map(_py).join(', ')}]
FIELDS = {
    ${_py(t(markTr('nombre')))}: "",
    ${_py(t(markTr('empresa')))}: "",
    ${_py(t(markTr('correo')))}: "",
    ${_py(t(markTr('teléfono')))}: "",
}
YOU = ${_py(t(markTr('Usted')))}
THINKING = ${_py(t(markTr('Claude está pensando…')))}
READY = ${_py(t(markTr('Listo')))}
FAILED = ${_py(t(markTr('No se pudo: {0}')))}


class Form1(FormDesign):
    def form_create(self):
        self.mode = None

    # ------------------------------------------------------------- estado
    def working(self, on):
        self.mode = self.mode if on else None
        self.BtnRun.configure(state="disabled" if on else "normal")
        self.BtnSend.configure(state="disabled" if on else "normal")
        if on:
            self.Busy.start(12)
            self.Status.set(THINKING, icon="refresh")
        else:
            self.Busy.stop()
            self.Status.set(READY, icon="check")

    def show(self, text):
        self.Result.delete("1.0", "end")
        self.Result.insert("1.0", text)

    # ------------------------------------------------------------- textos
    def BtnRun_click(self):
        text = self.Source.get("1.0", "end-1c").strip()
        if not text:
            return
        action = self.Action_var.get()
        self.mode = "text"
        self.working(True)
        self.mode = "text"
        if action == ACTIONS[1]:
            self.Ai1.translate_async(text, "English")
        elif action == ACTIONS[2]:
            self.Ai1.classify_async(text, SENTIMENTS)
        elif action == ACTIONS[3]:
            self.Ai1.extract_async(text, FIELDS)
        else:
            self.Ai1.summarize_async(text, 40)

    # --------------------------------------------------------------- chat
    def BtnSend_click(self, event=None):
        message = self.Message_var.get().strip()
        if not message:
            return
        self.Message_var.set("")
        self.History.insert("end", "%s: %s\\n" % (YOU, message))
        self.History.see("end")
        self.mode = "chat"
        self.working(True)
        self.mode = "chat"
        self.Ai1.chat_async(message)

    def BtnNewChat_click(self):
        self.Ai1.reset()
        self.History.delete("1.0", "end")

    # ------------------------------------------------------- respuestas
    def Ai1_done(self, result):
        mode = self.mode
        self.working(False)
        if mode == "chat":
            self.History.insert("end", "Claude: %s\\n\\n" % result)
            self.History.see("end")
        elif isinstance(result, dict):
            self.show(json.dumps(result, ensure_ascii=False, indent=2))
        else:
            self.show(str(result))

    def Ai1_error(self, error):
        self.working(False)
        self.Status.set(FAILED.format(error), icon="warning")

    def form_close(self, *args):
        self.root.destroy()
''';
  return TkExample(
    'ai_texts',
    app,
    t(
      markTr(
        'El componente Asistente IA (Claude): resumir, traducir, clasificar el sentimiento y extraer datos de un texto, y un chat con memoria, sin congelar la ventana.',
      ),
    ),
    design,
    code,
  );
}
