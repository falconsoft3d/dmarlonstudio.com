import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/errors.dart';
import '../core/studio_db.dart';
import '../i18n/tr.dart';
import 'tk_electron_run.dart';
import 'tk_react_native.dart';
import 'tk_web_react.dart';

/// El entorno compartido de React Native: Expo, React Native y lo de la web
/// (react-native-web), instalado una vez en el soporte de la app y enlazado
/// desde cada proyecto (sus node_modules).
class TkRnRuntime {
  TkRnRuntime._();

  /// La carpeta fijada (las pruebas).
  static String? dirOverride;

  static Future<String> dir() async {
    final o = dirOverride;
    if (o != null) return o;
    final base =
        StudioDb.dirOverride ?? (await getApplicationSupportDirectory()).path;
    return p.join(base, 'rn-runtime');
  }

  static Future<String> nodeModules() async =>
      p.join(await dir(), 'node_modules');

  /// La orden de Expo (su cli).
  static Future<String> expoCli() async =>
      p.join(await nodeModules(), 'expo', 'bin', 'cli');

  static Future<bool> ready() async =>
      File(p.join(await nodeModules(), 'expo', 'package.json')).existsSync();

  /// Instala el entorno si falta (la primera vez tarda un poco).
  static Future<TkNode> ensure(void Function(String) log) async {
    final node = await TkElectronRuntime.findNode();
    if (node == null) {
      throw UserError(
        tr(
          'Las apps de React Native necesitan Node.js. Instálelo desde nodejs.org y vuelva a intentarlo.',
        ),
      );
    }
    if (await ready()) return node;
    final d = Directory(await dir());
    await d.create(recursive: true);
    await File(p.join(d.path, 'package.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': 'dms-rn-runtime',
        'private': true,
        'dependencies': TkReactNative.dependencies,
      }),
    );
    log(tr('Instalando React Native y Expo (solo la primera vez)…'));
    final r = await Process.run(
      node.npm,
      ['install', '--no-audit', '--no-fund', '--loglevel=error'],
      workingDirectory: d.path,
      environment: TkElectronRuntime.environment(node),
      includeParentEnvironment: false,
    );
    if (r.exitCode != 0 || !await ready()) {
      throw UserError(
        tr('No se pudo instalar React Native: {0}', ['${r.stderr}'.trim()]),
      );
    }
    return node;
  }

  /// La dirección de este equipo en la red (para Expo Go en el teléfono).
  static Future<String?> lanAddress() async {
    try {
      for (final i in await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      )) {
        for (final a in i.addresses) {
          if (!a.isLoopback && !a.address.startsWith('169.254')) {
            return a.address;
          }
        }
      }
    } on Object {
      // Sin red.
    }
    return null;
  }
}

/// El entorno compartido de la web de React: Vite, su complemento de React
/// y React, instalado una vez y enlazado desde cada proyecto.
class TkViteRuntime {
  TkViteRuntime._();

  /// La carpeta fijada (las pruebas).
  static String? dirOverride;

  static Future<String> dir() async {
    final o = dirOverride;
    if (o != null) return o;
    final base =
        StudioDb.dirOverride ?? (await getApplicationSupportDirectory()).path;
    return p.join(base, 'vite-runtime');
  }

  static Future<String> nodeModules() async =>
      p.join(await dir(), 'node_modules');

  static Future<String> vite() async =>
      p.join(await nodeModules(), 'vite', 'bin', 'vite.js');

  static Future<bool> ready() async => File(await vite()).existsSync();

  /// Instala el entorno si falta (unos segundos, la primera vez).
  static Future<TkNode> ensure(void Function(String) log) async {
    final node = await TkElectronRuntime.findNode();
    if (node == null) {
      throw UserError(
        tr(
          'Las webs de React necesitan Node.js. Instálelo desde nodejs.org y vuelva a intentarlo.',
        ),
      );
    }
    if (await ready()) return node;
    final d = Directory(await dir());
    await d.create(recursive: true);
    await File(p.join(d.path, 'package.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'name': 'dms-vite-runtime',
        'private': true,
        'dependencies': {
          ...TkWebReact.dependencies,
          ...TkWebReact.devDependencies,
        },
      }),
    );
    log(tr('Instalando Vite y React (solo la primera vez)…'));
    final r = await Process.run(
      node.npm,
      ['install', '--no-audit', '--no-fund', '--loglevel=error'],
      workingDirectory: d.path,
      environment: TkElectronRuntime.environment(node),
      includeParentEnvironment: false,
    );
    if (r.exitCode != 0 || !await ready()) {
      throw UserError(
        tr('No se pudo instalar Vite: {0}', ['${r.stderr}'.trim()]),
      );
    }
    return node;
  }
}
