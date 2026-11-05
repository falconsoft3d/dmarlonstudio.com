/// Traducción de la interfaz al estilo gettext (como Odoo): los textos se
/// escriben en español en el código y se traducen con los catálogos
/// `assets/i18n/<idioma>.po`. Sin traducción se muestra el texto original.
///
/// Los valores variables van como `{0}`, `{1}`… para que el traductor pueda
/// reordenarlos: `tr('Mesa {0} · {1}', [numero, planta])`.
library;

final _catalog = <String, String>{};
final _placeholder = RegExp(r'\{(\d+)\}');

/// Sube con cada cambio de catálogo: lo que se calcula a partir de los
/// textos traducidos sabe así cuándo rehacerse.
int catalogGeneration = 0;

/// Sustituye el catálogo activo (vacío = español, el idioma del código).
void setCatalog(Map<String, String> entries) {
  catalogGeneration++;
  _catalog
    ..clear()
    ..addAll(entries);
}

String _format(String text, List<Object?> args) => args.isEmpty
    ? text
    : text.replaceAllMapped(_placeholder, (m) {
        final i = int.parse(m[1]!);
        return i < args.length ? '${args[i]}' : m[0]!;
      });

/// Texto traducido al idioma del usuario.
String tr(String msgid, [List<Object?> args = const []]) {
  final s = _catalog[msgid];
  return _format(s == null || s.isEmpty ? msgid : s, args);
}

/// Como [tr] para un texto que en otro sitio significa otra cosa (msgctxt de
/// gettext): `trc('pos', 'Ticket')` es el recibo, no un ticket de asistencia.
String trc(String context, String msgid, [List<Object?> args = const []]) {
  final s = _catalog[contextKey(context, msgid)];
  return _format(s == null || s.isEmpty ? msgid : s, args);
}

/// Clave de catálogo de un texto con contexto (separador EOT, como gettext).
String contextKey(String context, String msgid) => '$context\u0004$msgid';

/// Marca un texto de una tabla global (menús, estados…) para el catálogo sin
/// traducirlo: se traduce al mostrarlo con [tr].
String markTr(String msgid) => msgid;

/// Como [markTr] con contexto (se traduce con [trc] y el mismo contexto).
String markTrc(String context, String msgid) => msgid;
