import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/assistant.dart';
import '../../core/settings.dart';
import '../../i18n/i18n.dart';
import '../../version.dart';
import '../widgets.dart';
import 'mcp_settings.dart';

/// Tema elegido: sistema, claro u oscuro. Se guarda en los ajustes.
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> loadThemeMode() async {
  themeMode.value = switch (await Settings.get('ui.theme')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

Future<void> setThemeMode(ThemeMode m) async {
  themeMode.value = m;
  await Settings.set('ui.theme', switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => null,
  });
}

/// Ajustes del estudio: apariencia, inteligencia artificial y acerca de.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AiConfig? _ai;
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _url = TextEditingController();
  bool _showKey = false;
  List<String> _models = const [];
  bool _loadingModels = false;

  @override
  void initState() {
    super.initState();
    AiConfig.load().then((c) {
      if (!mounted) return;
      setState(() => _ai = c);
      _fill();
    });
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    _url.dispose();
    super.dispose();
  }

  void _fill() {
    final c = _ai!;
    _key.text = c.apiKey;
    _model.text = c.model;
    _url.text = c.baseUrl;
    _models = c.provider.models;
  }

  void _read() {
    final c = _ai!;
    c
      ..apiKey = _key.text.trim()
      ..model = _model.text.trim()
      ..baseUrl = _url.text.trim();
  }

  Future<void> _saveAi() async {
    _read();
    await runAction(
      context,
      () => _ai!.save(),
      success: tr('Ajustes de la IA guardados.'),
    );
  }

  Future<void> _listModels() async {
    _read();
    setState(() => _loadingModels = true);
    final r = await runAction(
      context,
      () => AiConfig.listModels(
        _ai!.baseUrl,
        _ai!.apiKey,
        provider: _ai!.provider,
      ),
    );
    if (!mounted) return;
    setState(() {
      _loadingModels = false;
      if (r != null && r.chat.isNotEmpty) _models = r.chat;
    });
  }

  Widget _section(ThemeData t, String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: t.textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );

  Widget _aiSection(ThemeData t) {
    final c = _ai;
    if (c == null) return const LinearProgressIndicator();
    final p = c.provider;
    return _section(t, tr('Inteligencia artificial'), [
      Text(
        tr(
          'La IA diseña ventanas, escribe los manejadores de eventos, propone cambios en el Editor y dibuja diagramas. La clave se guarda solo en este equipo.',
        ),
        style: t.textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: p.id,
        decoration: InputDecoration(labelText: tr('Proveedor')),
        items: [
          for (final x in AiProvider.all)
            DropdownMenuItem(value: x.id, child: Text(x.name)),
        ],
        onChanged: (id) {
          final np = AiProvider.byId(id);
          if (np == null) return;
          _read();
          setState(() {
            c.select(np);
            _fill();
          });
        },
      ),
      const SizedBox(height: 10),
      if (p.needsKey)
        TextField(
          controller: _key,
          obscureText: !_showKey,
          decoration: InputDecoration(
            labelText: tr('Clave de la API'),
            hintText: p.keyHint,
            suffixIcon: IconButton(
              icon: Icon(_showKey ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _showKey = !_showKey),
            ),
          ),
        ),
      if (p.editableUrl) ...[
        const SizedBox(height: 10),
        TextField(
          controller: _url,
          decoration: InputDecoration(labelText: tr('URL base de la API')),
        ),
      ],
      const SizedBox(height: 10),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Autocomplete<String>(
              initialValue: TextEditingValue(text: _model.text),
              optionsBuilder: (v) => _models.where(
                (m) => m.toLowerCase().contains(v.text.toLowerCase()),
              ),
              onSelected: (m) => _model.text = m,
              fieldViewBuilder: (context, ctl, focus, submit) {
                ctl.addListener(() => _model.text = ctl.text);
                return TextField(
                  controller: ctl,
                  focusNode: focus,
                  decoration: InputDecoration(labelText: tr('Modelo')),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _loadingModels ? null : _listModels,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(tr('Consultar modelos')),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _saveAi,
          icon: const Icon(LucideIcons.save, size: 16),
          label: Text(tr('Guardar')),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      children: [
        ControlPanel(crumbs: [Crumb(tr('Ajustes'))]),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      _section(t, tr('Idioma'), [
                        ValueListenableBuilder(
                          valueListenable: I18n.lang,
                          builder: (_, lang, _) => SegmentedButton<String>(
                            key: const ValueKey('settings-lang'),
                            segments: [
                              for (final e in I18n.languages.entries)
                                ButtonSegment(
                                  value: e.key,
                                  label: Text(e.value),
                                ),
                            ],
                            selected: {lang},
                            onSelectionChanged: (s) =>
                                runAction(context, () => I18n.choose(s.first)),
                          ),
                        ),
                      ]),
                      _section(t, tr('Apariencia'), [
                        ValueListenableBuilder(
                          valueListenable: themeMode,
                          builder: (_, mode, _) => SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(tr('Sistema')),
                                icon: const Icon(LucideIcons.monitor, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(tr('Claro')),
                                icon: const Icon(LucideIcons.sun, size: 16),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(tr('Oscuro')),
                                icon: const Icon(LucideIcons.moon, size: 16),
                              ),
                            ],
                            selected: {mode},
                            onSelectionChanged: (s) => setThemeMode(s.first),
                          ),
                        ),
                      ]),
                      _aiSection(t),
                      _section(t, tr('Conectar con Claude (MCP)'), [
                        const McpSettings(),
                      ]),
                      _section(t, tr('Acerca de'), [
                        Text('DMarlon Studio $appVersion'),
                        const SizedBox(height: 4),
                        Text(
                          tr(
                            'IDE visual al estilo de Delphi para crear aplicaciones de Python (tkinter y Flask). Próximamente, Electron.',
                          ),
                          style: t.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          'https://dmarlonstudio.com',
                          style: t.textTheme.bodySmall,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
