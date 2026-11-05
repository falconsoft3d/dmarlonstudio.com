import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'code/tk_run.dart';
import 'core/mcp_server.dart';
import 'core/studio_db.dart';
import 'i18n/i18n.dart';
import 'ui/screens/code_studio.dart';
import 'ui/screens/dev_tools.dart';
import 'ui/screens/diagrams.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/tk_designer.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StudioDb.open();
  await I18n.load();
  await loadThemeMode();
  // El MCP para Claude, si está activado en Ajustes.
  await McpServer.startFromSettings();
  runApp(const StudioApp());
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: I18n.lang,
    builder: (_, lang, _) => ValueListenableBuilder(
      valueListenable: themeMode,
      builder: (_, mode, _) => MaterialApp(
        title: 'DMarlon Studio',
        debugShowCheckedModeBanner: false,
        theme: studioTheme(Brightness.light),
        darkTheme: studioTheme(Brightness.dark),
        themeMode: mode,
        locale: Locale(lang),
        supportedLocales: const [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const StudioShell(),
      ),
    ),
  );
}

/// Un módulo del estudio en la barra lateral.
class _Module {
  const _Module(this.label, this.icon, this.build);
  final String label;
  final IconData icon;
  final Widget Function() build;
}

final _modules = <_Module>[
  _Module(
    markTr('Diseñador'),
    LucideIcons.layoutTemplate,
    () => const TkDesignerScreen(),
  ),
  _Module(
    markTr('Editor'),
    LucideIcons.codeXml,
    () => const CodeStudioScreen(),
  ),
  _Module(
    markTr('Bases de datos'),
    LucideIcons.database,
    () => const DbManagerScreen(),
  ),
  _Module(markTr('API'), LucideIcons.send, () => const ApiClientScreen()),
  _Module(markTr('FTP'), LucideIcons.folderSync, () => const FtpScreen()),
  _Module(
    markTr('Diagramas'),
    LucideIcons.workflow,
    () => const DiagramsScreen(),
  ),
  _Module(
    markTr('Ajustes'),
    LucideIcons.settings,
    () => const SettingsScreen(),
  ),
];

/// Ventana principal: barra lateral con los módulos. Cada módulo se crea la
/// primera vez que se abre y conserva su estado (lo no guardado no se pierde
/// al cambiar de módulo).
class StudioShell extends StatefulWidget {
  const StudioShell({super.key});

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  int _index = 0;
  final _built = <int, Widget>{};

  /// Al cerrar el estudio se detienen las ventanas y servidores lanzados.
  late final _exit = AppLifecycleListener(
    onExitRequested: () async {
      TkRunner.stopAll();
      return AppExitResponse.exit;
    },
  );

  @override
  void initState() {
    super.initState();
    _exit;
  }

  @override
  void dispose() {
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    _built.putIfAbsent(_index, () => _modules[_index].build());
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 76,
            decoration: BoxDecoration(
              color: t.colorScheme.surfaceContainer,
              border: Border(right: BorderSide(color: t.dividerColor)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 14),
                Tooltip(
                  message: 'DMarlon Studio',
                  child: Image.asset(
                    'assets/icon/icon_256.png',
                    width: 36,
                    height: 36,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const SizedBox(height: 14),
                for (final (i, m) in _modules.indexed) ...[
                  if (i == _modules.length - 1) ...[
                    const Spacer(),
                    // Modo oscuro o claro con un clic (Ajustes deja también
                    // seguir al del sistema).
                    _NavButton(
                      key: const ValueKey('nav-theme'),
                      label: t.brightness == Brightness.dark
                          ? tr('Claro')
                          : tr('Oscuro'),
                      icon: t.brightness == Brightness.dark
                          ? LucideIcons.sun
                          : LucideIcons.moon,
                      selected: false,
                      onTap: () => setThemeMode(
                        t.brightness == Brightness.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      ),
                    ),
                  ],
                  _NavButton(
                    key: ValueKey('nav-$i'),
                    label: tr(m.label),
                    icon: m.icon,
                    selected: i == _index,
                    onTap: () => setState(() => _index = i),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                for (var i = 0; i < _modules.length; i++)
                  _built[i] ?? const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final color = selected
        ? t.colorScheme.primary
        : t.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: selected
            ? t.colorScheme.primary.withValues(alpha: .12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: 10.5, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
