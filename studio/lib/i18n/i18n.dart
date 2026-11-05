import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../core/settings.dart';
import 'po.dart';
import 'tr.dart';

export 'tr.dart';

/// Idioma de la interfaz: los textos se escriben en español en el código y
/// se traducen con los catálogos `assets/i18n/<idioma>.po` (como gettext).
class I18n {
  I18n._();

  /// Idiomas disponibles (el código está escrito en español).
  static const languages = {'es': 'Español', 'en': 'English'};

  static const _key = 'ui.lang';

  static final lang = ValueNotifier<String>('es');

  /// Idioma del sistema: español si lo es, inglés en otro caso.
  static String get systemLanguage =>
      PlatformDispatcher.instance.locale.languageCode == 'es' ? 'es' : 'en';

  /// El idioma guardado en Ajustes o, si no hay, el del sistema.
  static Future<void> load() async {
    String? saved;
    try {
      saved = await Settings.get(_key);
    } on Object {
      saved = null;
    }
    await use(saved ?? systemLanguage);
  }

  /// Cambia el idioma, lo guarda y vuelve a pintar toda la interfaz.
  static Future<void> choose(String code) async {
    await use(code);
    await Settings.set(_key, lang.value);
    rebuildAll();
  }

  static Future<void> use(String code) async {
    final l = languages.containsKey(code) ? code : 'es';
    if (l == 'es') {
      setCatalog(const {});
    } else {
      // Se decodifica aquí: loadString usa un isolate para archivos grandes.
      final data = await rootBundle.load('assets/i18n/$l.po');
      setCatalog(catalogOf(utf8.decode(data.buffer.asUint8List())));
    }
    await initializeDateFormatting(l);
    Intl.defaultLocale = l;
    lang.value = l;
  }

  /// Marca toda la interfaz para volver a construirse: los textos se
  /// traducen al construir, y así cambian sin perder el estado de nada (lo
  /// abierto en el Diseñador o el Editor sigue igual).
  static void rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
