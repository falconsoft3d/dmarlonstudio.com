import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../code/tk_model.dart';
import '../../i18n/i18n.dart';
import '../theme.dart' show metroColors;
import '../tk_project.dart';
import 'tk_canvas.dart';

/// Inspector de objetos: propiedades y eventos del componente seleccionado
/// o, sin selección, de la ventana.
class TkInspector extends StatelessWidget {
  const TkInspector({
    super.key,
    required this.design,
    required this.widgetName,
    required this.count,
    this.connections = const [],
    required this.onBegin,
    required this.onChanged,
    required this.onRename,
    required this.onSetHandler,
    required this.onOpenHandler,
  });

  final TkDesign design;

  /// Componente que se inspecciona (null = la ventana).
  final String? widgetName;

  /// Componentes seleccionados.
  final int count;

  /// Conexiones guardadas en Código.
  final List<String> connections;

  /// Antes de cambiar: [key] agrupa las pulsaciones de un mismo campo en un
  /// solo paso de deshacer.
  final ValueChanged<String> onBegin;
  final VoidCallback onChanged;

  /// Cambia el nombre del componente o, con [w] null, de la ventana.
  /// Devuelve el error, si lo hay.
  final String? Function(TkWidget? w, String name) onRename;

  /// Enlaza el evento [e] con el método [method] ('' = lo quita).
  final String? Function(TkWidget? w, TkEvent e, String method) onSetHandler;

  /// Va al método del evento [e], creándolo si hace falta.
  final void Function(TkWidget? w, TkEvent e) onOpenHandler;

  @override
  Widget build(BuildContext context) {
    if (count > 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            tr('{0} componentes seleccionados', [count]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final w = widgetName == null ? null : design.byName(widgetName!);
    final id = w?.name ?? '#form';
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(height: 32, text: tr('Propiedades')),
              Tab(height: 32, text: tr('Eventos')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListView(
                  key: PageStorageKey('tk-props-$id'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: w == null ? _formProps() : _widgetProps(w),
                ),
                ListView(
                  key: PageStorageKey('tk-events-$id'),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final e in w?.component.events ?? tkFormEvents)
                      if (design.isWeb && !tkWebHasEvent(e, form: w == null))
                        _Note(
                          key: ValueKey('tk-web-gap-$id-${e.key}'),
                          tr('{0}: sin equivalente en una aplicación web.', [
                            tr(e.label),
                          ]),
                        )
                      else
                        _EventRow(
                          key: ValueKey('tk-event-$id-${e.key}'),
                          label: tr(e.label),
                          method: (w?.events ?? design.events)[e.key] ?? '',
                          hint: e.sequences.isEmpty
                              ? 'command'
                              : e.sequences.first,
                          onSet: (m) => onSetHandler(w, e, m),
                          onOpen: () => onOpenHandler(w, e),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _formProps() => [
    _NameRow(
      key: ValueKey('tk-name-form-${design.name}'),
      value: design.name,
      onRename: (n) => onRename(null, n),
    ),
    _Row(
      label: tr('Destino'),
      child: Text(
        tkTargetLabel(design.target),
        key: const ValueKey('tk-target'),
        style: const TextStyle(fontSize: 12),
      ),
    ),
    if (design.isWeb)
      _Note(
        key: const ValueKey('tk-web-note'),
        tr(
          'El código corre en Python, en el servidor. Solo se abre en este equipo: esta versión no publica ni escucha en la red. Siempre encima y Redimensionable no existen en una página.',
        ),
      ),
    for (final (key, label, get, set)
        in <(String, String, int Function(), void Function(int))>[
          ('width', tr('Ancho'), () => design.width, (v) => design.width = v),
          ('height', tr('Alto'), () => design.height, (v) => design.height = v),
        ])
      _PropRow(
        key: ValueKey('tk-form-$key'),
        label: label,
        type: TkPropType.integer,
        value: get(),
        onChanged: (v) {
          onBegin('form.$key');
          final n = v is num ? v.toInt() : 0;
          set(n < 40 ? 40 : n);
          onChanged();
        },
      ),
    for (final p in tkFormProps)
      if ((!design.isWeb || !tkWebNoFormProps.contains(p.key)) &&
          (!tkFormManualProps.contains(p.key) ||
              design.prop(tkFormPosition) == 'manual'))
        _PropRow(
          key: ValueKey('tk-form-${p.key}'),
          label: tr(p.label),
          type: p.type,
          choices: p.choices,
          labels: p.labels,
          value: design.prop(p),
          onChanged: (v) {
            onBegin('form.${p.key}');
            design.setProp(p, v);
            onChanged();
          },
        ),
  ];

  List<Widget> _widgetProps(TkWidget w) => [
    if (design.isWeb && tkWebGap(w.kind) != null)
      _Note(key: ValueKey('tk-web-gap-${w.name}'), tkWebGap(w.kind)!),
    if (tkJsGap(design, w.kind) != null)
      _Note(
        key: ValueKey('tk-electron-gap-${w.name}'),
        tkJsGap(design, w.kind)!,
      ),
    if (w.kind == 'RestClient')
      _Note(
        key: ValueKey('tk-api-note-${w.name}'),
        tr(
          'No escriba tokens ni contraseñas aquí: guárdelos como variables en el módulo API (Variables) y ponga su nombre en «Variable con el token o la clave». En la URL y las cabeceras, {{nombre}} usa esas variables al ejecutar.',
        ),
      ),
    _NameRow(
      key: ValueKey('tk-name-${w.name}'),
      value: w.name,
      onRename: (n) => onRename(w, n),
    ),
    for (final (key, label, get, set)
        in <(String, String, int Function(), void Function(int))>[
          ('x', 'X', () => w.x, (v) => w.x = v),
          ('y', 'Y', () => w.y, (v) => w.y = v),
          ('width', tr('Ancho'), () => w.width, (v) => w.width = v < 1 ? 1 : v),
          (
            'height',
            tr('Alto'),
            () => w.height,
            (v) => w.height = v < 1 ? 1 : v,
          ),
        ])
      // La barra de estado va abajo y la cinta arriba, de lado a lado: solo
      // cuenta su alto.
      if (!const {'StatusBar', 'Ribbon'}.contains(w.kind) || key == 'height')
        _PropRow(
          key: ValueKey('tk-prop-${w.name}-$key'),
          label: label,
          type: TkPropType.integer,
          value: get(),
          onChanged: (v) {
            onBegin('${w.name}.$key');
            set(v is num ? v.toInt() : 0);
            onChanged();
          },
        ),
    if (design.pageControlOf(w) case final pc?)
      _PropRow(
        key: ValueKey('tk-prop-${w.name}-page'),
        label: tr('Página'),
        type: TkPropType.choice,
        choices: [for (final (i, t) in tkPages(pc).indexed) '${i + 1}. $t'],
        value: '${design.pageOf(w) + 1}. ${tkPages(pc)[design.pageOf(w)]}',
        onChanged: (v) {
          final i = int.tryParse('$v'.split('.').first);
          if (i == null) return;
          onBegin('${w.name}.page');
          w.page = i - 1;
          // Se ve la página a la que va.
          pc.setProp(pc.component.prop('active')!, i - 1);
          onChanged();
        },
      ),
    if (w.kind == 'Image')
      _ImagePick(
        key: ValueKey('tk-image-pick-${w.name}'),
        onPicked: (rel) {
          onBegin('${w.name}.file');
          w.setProp(w.component.prop('file')!, rel);
          onChanged();
        },
      ),
    for (final p in w.component.props)
      _PropRow(
        key: ValueKey('tk-prop-${w.name}-${p.key}'),
        label: tr(p.label),
        type: p.type,
        choices: switch (p.type) {
          TkPropType.connection => ['', ...connections],
          TkPropType.reference => [
            '',
            for (final o in design.widgets)
              if (o.kind == p.refKind) o.name,
          ],
          _ => p.choices,
        },
        labels: p.labels,
        blank: p.type == TkPropType.connection
            ? tr('Sin conexión (guárdela en Bases de datos)')
            : p.type == TkPropType.reference
            ? tr('(ninguna)')
            : null,
        value: w.prop(p),
        onChanged: (v) {
          onBegin('${w.name}.${p.key}');
          w.setProp(p, v);
          onChanged();
        },
      ),
  ];
}

/// Aviso del inspector: lo que en una aplicación web no funciona igual.
class _Note extends StatelessWidget {
  const _Note(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, size: 13, color: t.hintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: t.textTheme.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

const _dense = InputDecoration(
  isDense: true,
  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 7),
  border: OutlineInputBorder(),
);

/// Nombre: se aplica al confirmar, porque cambia también el código.
class _NameRow extends StatefulWidget {
  const _NameRow({super.key, required this.value, required this.onRename});
  final String value;
  final String? Function(String) onRename;

  @override
  State<_NameRow> createState() => _NameRowState();
}

class _NameRowState extends State<_NameRow> {
  late final _c = TextEditingController(text: widget.value);
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _apply();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply() {
    final v = _c.text.trim();
    if (v == widget.value) {
      if (_error != null) setState(() => _error = null);
      return;
    }
    final e = widget.onRename(v);
    if (mounted) setState(() => _error = e);
  }

  @override
  Widget build(BuildContext context) => _Row(
    label: tr('Nombre'),
    child: TextField(
      key: const ValueKey('tk-name-field'),
      controller: _c,
      focusNode: _focus,
      style: const TextStyle(fontSize: 12),
      decoration: _dense.copyWith(errorText: _error, errorMaxLines: 3),
      onSubmitted: (_) => _apply(),
    ),
  );
}

class _PropRow extends StatefulWidget {
  const _PropRow({
    super.key,
    required this.label,
    required this.type,
    required this.value,
    required this.onChanged,
    this.choices = const [],
    this.blank,
    this.labels = const {},
  });
  final String label;
  final TkPropType type;
  final Object? value;
  final List<String> choices;

  /// Nombre de cada opción (sin traducir); sin él, la opción tal cual.
  final Map<String, String> labels;

  /// Cómo se llama la opción vacía.
  final String? blank;
  final ValueChanged<Object?> onChanged;

  @override
  State<_PropRow> createState() => _PropRowState();
}

class _PropRowState extends State<_PropRow> {
  late final _c = TextEditingController(text: '${widget.value ?? ''}');
  final _focus = FocusNode();

  @override
  void didUpdateWidget(_PropRow old) {
    super.didUpdateWidget(old);
    // Lo que cambia desde fuera (arrastrar, deshacer) se ve al momento.
    final v = '${widget.value ?? ''}';
    if (!_focus.hasFocus && _c.text != v) _c.text = v;
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _text(String v) => widget.onChanged(switch (widget.type) {
    TkPropType.integer => int.tryParse(v.trim()) ?? 0,
    TkPropType.number => double.tryParse(v.trim().replaceAll(',', '.')) ?? 0,
    _ => v,
  });

  Future<void> _pickColor() async {
    final extra = TextEditingController(text: _c.text);
    final v = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('Elegir color')),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final hex in [
                    0xFFFFFFFF,
                    0xFFF0F0F0,
                    0xFF000000,
                    ...metroColors.map((e) => e.$1),
                  ])
                    InkWell(
                      onTap: () => Navigator.pop(
                        c,
                        '#${(hex & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
                      ),
                      child: Container(
                        width: 34,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Color(hex),
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: extra,
                decoration: InputDecoration(
                  labelText: tr('Color (#rrggbb o nombre de Tk)'),
                ),
                onSubmitted: (s) => Navigator.pop(c, s.trim()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, ''),
            child: Text(tr('Sin color')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(tr('Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, extra.text.trim()),
            child: Text(tr('Aceptar')),
          ),
        ],
      ),
    );
    extra.dispose();
    if (v == null || !mounted) return;
    _c.text = v;
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 12);
    final Widget editor = switch (widget.type) {
      TkPropType.boolean => Align(
        alignment: Alignment.centerLeft,
        child: Checkbox(
          visualDensity: VisualDensity.compact,
          value: widget.value == true,
          onChanged: (v) => widget.onChanged(v ?? false),
        ),
      ),
      TkPropType.choice ||
      TkPropType.connection ||
      TkPropType.reference => DropdownButtonFormField<String>(
        key: ValueKey('${widget.value}'),
        initialValue: widget.choices.contains('${widget.value}')
            ? '${widget.value}'
            : null,
        isDense: true,
        isExpanded: true,
        style: style,
        decoration: _dense,
        items: [
          for (final c in widget.choices)
            DropdownMenuItem(
              value: c,
              child: Text(
                c.isEmpty
                    ? widget.blank ?? tr('(de serie)')
                    : widget.labels[c] == null
                    ? c
                    : tr(widget.labels[c]!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
        ],
        onChanged: (v) => widget.onChanged(v ?? ''),
      ),
      TkPropType.color => Row(
        children: [
          Expanded(
            child: TextField(
              controller: _c,
              focusNode: _focus,
              style: style,
              decoration: _dense,
              onChanged: (v) => widget.onChanged(v.trim()),
            ),
          ),
          const SizedBox(width: 4),
          Tooltip(
            message: tr('Elegir color'),
            child: InkWell(
              onTap: _pickColor,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: tkColor('${widget.value}', Colors.transparent),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: '${widget.value ?? ''}'.isEmpty
                    ? const Icon(LucideIcons.palette, size: 14)
                    : null,
              ),
            ),
          ),
        ],
      ),
      TkPropType.multiline => TextField(
        controller: _c,
        focusNode: _focus,
        style: style,
        minLines: 2,
        maxLines: 6,
        decoration: _dense,
        onChanged: _text,
      ),
      _ => TextField(
        controller: _c,
        focusNode: _focus,
        style: style,
        decoration: _dense,
        onChanged: _text,
      ),
    };
    return _Row(label: widget.label, child: editor);
  }
}

class _EventRow extends StatefulWidget {
  const _EventRow({
    super.key,
    required this.label,
    required this.method,
    required this.hint,
    required this.onSet,
    required this.onOpen,
  });
  final String label, method, hint;
  final String? Function(String) onSet;
  final VoidCallback onOpen;

  @override
  State<_EventRow> createState() => _EventRowState();
}

class _EventRowState extends State<_EventRow> {
  late final _c = TextEditingController(text: widget.method);
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _apply();
    });
  }

  @override
  void didUpdateWidget(_EventRow old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _c.text != widget.method) _c.text = widget.method;
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _apply() {
    final v = _c.text.trim();
    if (v == widget.method) return;
    final e = widget.onSet(v);
    if (mounted) setState(() => _error = e);
  }

  @override
  Widget build(BuildContext context) => _Row(
    label: widget.label,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _c,
            focusNode: _focus,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: _dense.copyWith(
              hintText: widget.hint,
              hintStyle: const TextStyle(fontSize: 10.5),
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _apply(),
          ),
        ),
        IconButton(
          key: ValueKey('tk-event-open-${widget.label}'),
          visualDensity: VisualDensity.compact,
          iconSize: 15,
          tooltip: tr('Ir al código'),
          icon: Icon(
            widget.method.isEmpty ? LucideIcons.plus : LucideIcons.arrowRight,
          ),
          onPressed: widget.onOpen,
        ),
      ],
    ),
  );
}

/// Elige una imagen del equipo, la copia en la carpeta `images` del
/// proyecto y da su ruta relativa: así el proyecto se lleva sus imágenes.
class _ImagePick extends StatelessWidget {
  const _ImagePick({super.key, required this.onPicked});
  final ValueChanged<String> onPicked;

  static Future<String?> copyIntoProject(String dir, String from) async {
    final images = Directory(p.join(dir, 'images'));
    await images.create(recursive: true);
    final source = File(from);
    final base = p.basenameWithoutExtension(from);
    final ext = p.extension(from);
    var name = '$base$ext';
    for (var i = 1; ; i++) {
      final target = File(p.join(images.path, name));
      if (!await target.exists()) {
        await source.copy(target.path);
        break;
      }
      // La misma imagen ya copiada: se reutiliza.
      if (await target.length() == await source.length()) break;
      name = '${base}_$i$ext';
    }
    return 'images/$name';
  }

  Future<void> _pick(BuildContext context) async {
    final dir = TkProject.current?.id;
    if (dir == null) return;
    final file = await openFile(
      acceptedTypeGroups: [
        XTypeGroup(
          label: tr('Imágenes'),
          extensions: const ['png', 'gif', 'jpg', 'jpeg', 'webp', 'bmp'],
        ),
      ],
    );
    if (file == null) return;
    final rel = await copyIntoProject(dir, file.path);
    if (rel != null) onPicked(rel);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: OutlinedButton.icon(
      onPressed: TkProject.current == null ? null : () => _pick(context),
      icon: const Icon(LucideIcons.imagePlus, size: 14),
      label: Text(tr('Elegir imagen…'), style: const TextStyle(fontSize: 12)),
    ),
  );
}
