import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../code/claude_code.dart';
import '../../core/mcp_server.dart';
import '../../core/settings.dart';
import '../../i18n/i18n.dart';
import '../theme.dart';
import '../widgets.dart';

/// Ajustes del servidor MCP: activarlo, su dirección y su token, y darlo de
/// alta en Claude Code.
class McpSettings extends StatefulWidget {
  const McpSettings({super.key});

  @override
  State<McpSettings> createState() => _McpSettingsState();
}

class _McpSettingsState extends State<McpSettings> {
  bool _showToken = false;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    McpServer.ensureToken().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggle(bool on) async {
    setState(() => _busy = true);
    await runAction(context, () async {
      if (on) {
        await McpServer.start();
      } else {
        await McpServer.stop();
      }
      await Settings.set('mcp.enabled', on ? '1' : null);
    });
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addToClaudeCode() async {
    final exe = ClaudeCode.find();
    if (exe == null) {
      await showErrorDialog(
        context,
        tr(
          'No se encontró Claude Code. Instálelo desde https://claude.com/claude-code o copie la orden y ejecútela en una terminal.',
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // Si ya estaba, se quita primero: así toma el token de ahora.
      await Process.run(exe, [
        'mcp',
        'remove',
        '--scope',
        'user',
        'dmarlon-studio',
      ]);
      final r = await Process.run(exe, [
        'mcp',
        'add',
        '--transport',
        'http',
        '--scope',
        'user',
        'dmarlon-studio',
        McpServer.url,
        '--header',
        'Authorization: Bearer ${McpServer.token}',
      ]);
      _message = r.exitCode == 0
          ? tr(
              'Añadido a Claude Code: en una sesión nueva, Claude verá las herramientas de DMarlon Studio.',
            )
          : '${r.stderr}${r.stdout}'.trim();
    } on ProcessException catch (e) {
      _message = e.message;
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _copyField(
    ThemeData t,
    String label,
    String value, {
    bool secret = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: t.textTheme.bodySmall),
          ),
          Expanded(
            child: SelectableText(
              secret && !_showToken ? '•' * 24 : value,
              style: const TextStyle(
                fontFamily: 'DejaVuSansMono',
                fontSize: 12,
              ),
            ),
          ),
          if (secret)
            IconButton(
              tooltip: _showToken ? tr('Ocultar') : tr('Mostrar'),
              iconSize: 16,
              icon: Icon(_showToken ? LucideIcons.eyeOff : LucideIcons.eye),
              onPressed: () => setState(() => _showToken = !_showToken),
            ),
          IconButton(
            tooltip: tr('Copiar'),
            iconSize: 16,
            icon: const Icon(LucideIcons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(tr('Copiado.'))));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final on = McpServer.running;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(
            'Claude (Claude Code u otro cliente MCP) puede listar, leer, crear y modificar sus proyectos, generar el Python y ejecutarlos mientras DMarlon Studio está abierto. Solo responde en este equipo y con el token.',
          ),
          style: t.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: on,
          onChanged: _busy ? null : _toggle,
          title: Text(tr('Servidor MCP activo')),
          subtitle: Row(
            children: [
              Icon(
                on ? LucideIcons.circleCheck : LucideIcons.circleOff,
                size: 14,
                color: on ? AppColors.success : t.hintColor,
              ),
              const SizedBox(width: 6),
              Text(
                on ? tr('En marcha') : tr('Parado'),
                style: t.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _copyField(t, tr('Dirección'), McpServer.url),
        _copyField(t, tr('Token'), McpServer.token, secret: true),
        _copyField(t, tr('Claude Code'), McpServer.claudeCommand),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _busy || !on ? null : _addToClaudeCode,
              icon: const Icon(LucideIcons.bot, size: 16),
              label: Text(tr('Añadir a Claude Code')),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await confirmDialog(
                        context,
                        tr('Cambiar el token'),
                        tr(
                          'Los clientes ya configurados dejarán de conectarse hasta que les dé el token nuevo.',
                        ),
                      );
                      if (!ok) return;
                      await McpServer.regenerateToken();
                      if (mounted) setState(() {});
                    },
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(tr('Cambiar el token')),
            ),
          ],
        ),
        if (_message != null) ...[
          const SizedBox(height: 10),
          Text(_message!, style: t.textTheme.bodySmall),
        ],
      ],
    );
  }
}
