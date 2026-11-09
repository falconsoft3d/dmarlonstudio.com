import 'dart:convert';

import '../core/errors.dart';
import '../i18n/tr.dart';
import 'tk_flutter.dart';
import 'tk_model.dart';
import 'tk_web_next.dart';

/// React Native (Expo) a partir de las pantallas: el mismo editor que
/// Flutter y que la web de Next.js. Cada pantalla es un componente con
/// View, Text, Pressable, TextInput, ScrollView… La navegación es una pila
/// propia (sin dependencias). La lógica es lib/app.js (la misma clase App
/// que en la web: DmsApp con notify()).
class TkReactNative {
  TkReactNative._();

  /// Versión de Expo (y de lo que la acompaña, con `expo install`).
  static const expoVersion = '~58.0.0';

  /// Lo que necesita la app (y el entorno compartido del estudio).
  static const dependencies = {
    'expo': expoVersion,
    '@expo/metro-runtime': expoVersion,
    '@expo/vector-icons': '^15.0.2',
    'react': '19.3.0',
    'react-dom': '19.3.0',
    'react-native': '0.88.1',
    'react-native-web': '^0.21.4',
  };

  static String _str(String s) => jsonEncode(s);

  static String? _expr(Object? v, String Function(String) literal) {
    if (v == null) return null;
    final s = '$v'.trim();
    if (s.isEmpty) return null;
    return s.startsWith('=') ? TkWebNext.js(s.substring(1).trim()) : literal(s);
  }

  static String? _num(Object? v) => _expr(v, (s) => '${num.tryParse(s) ?? 0}');

  static String? _bool(Object? v) =>
      v is bool ? '$v' : _expr(v, (s) => s == 'true' ? 'true' : 'false');

  /// Un color: #rrggbb, `=expresión` o un color del tema (T.primary…).
  static String? color(Object? v) => _expr(v, (s) {
    if (RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(s)) {
      return _str(s.startsWith('#') ? s : '#$s');
    }
    return 'T.$s';
  });

  /// Un icono de MaterialIcons (con guiones: local_shipping →
  /// local-shipping).
  static String _icon(String name) => name.startsWith('=')
      ? 'dmsIcon(${TkWebNext.js(name.substring(1).trim())})'
      : _str(_iconName(name.isEmpty ? 'circle' : name));

  static String _iconName(String n) =>
      n.replaceAll(RegExp(r'_outlined$'), '').replaceAll('_', '-');

  static String _cb(String a) =>
      a.trim().isEmpty ? 'undefined' : 'async () => { ${TkWebNext.action(a)} }';

  static String _text(String t) => '{${TkWebNext.tpl(t)}}';

  static String _style(Map<String, String?> m, [String? base]) {
    final e = [
      for (final MapEntry(:key, :value) in m.entries)
        if (value != null) '$key: $value',
    ];
    if (e.isEmpty) return base == null ? '' : ' style={$base}';
    return base == null
        ? ' style={{ ${e.join(', ')} }}'
        : ' style={[$base, { ${e.join(', ')} }]}';
  }

  static String? _justify(String v) => switch (v) {
    'center' => '"center"',
    'end' => '"flex-end"',
    'spaceBetween' => '"space-between"',
    'spaceAround' => '"space-around"',
    'spaceEvenly' => '"space-evenly"',
    _ => null,
  };

  static String? _align(String v) => switch (v) {
    'start' => '"flex-start"',
    'center' => '"center"',
    'end' => '"flex-end"',
    'stretch' => '"stretch"',
    _ => null,
  };

  /// El JSX de [n].
  static String jsx(
    FlNode n, {
    String indent = '',
    bool inRow = false,
    bool inStretch = false,
  }) {
    final p = n.props;
    final i2 = '$indent  ';
    String kids({bool row = false, bool stretch = false}) => [
      for (final c in n.children)
        _child(c, indent: i2, inRow: row, inStretch: stretch),
    ].join();
    String one() => n.children.isEmpty ? '' : jsx(n.children.first, indent: i2);
    final tap = n.text('onTap');
    String press(String w) => tap.isEmpty
        ? w
        : '<Pressable accessibilityRole="button" onPress={${_cb(tap)}}>$w</Pressable>';
    return switch (n.type) {
      'Column' || 'Row' =>
        '<View${_style({'flexDirection': n.type == 'Row' ? '"row"' : null, 'flexWrap': p['wrap'] == true ? '"wrap"' : null, 'gap': _num(p['gap']), 'padding': _num(p['padding']), 'justifyContent': _justify(n.text('main', 'start')), 'alignItems': _align(n.text('cross', n.type == 'Column' ? 'stretch' : 'center')), 'flex': inRow ? null : null})}>\n'
            '${kids(row: n.type == 'Row', stretch: n.type == 'Column' && n.text('cross', 'stretch') == 'stretch')}$indent</View>',
      'ListView' => _list(n, indent),
      'Card' => press(
        '<View${_style({'padding': _num(p['padding']) ?? '12', 'backgroundColor': color(p['color'])}, 'S.card')}>\n$i2${one()}\n$indent</View>',
      ),
      'Container' => press(
        '<View${_style({'height': _num(p['height']), 'width': _num(p['width']), 'padding': _num(p['padding']), 'backgroundColor': color(p['color']), 'borderRadius': _num(p['radius']), 'overflow': '"hidden"'})}>\n$i2${one()}\n$indent</View>',
      ),
      'Padding' =>
        '<View${_style({'padding': _num(p['padding']) ?? '16'})}>\n$i2${one()}\n$indent</View>',
      'Center' => '<View style={S.center}>\n$i2${one()}\n$indent</View>',
      'Expanded' =>
        '<View${_style({'flex': _num(p['flex']) ?? '1', 'minWidth': '0'})}>\n$i2${one()}\n$indent</View>',
      'Text' => press(_textNode(n)),
      'Button' => _button(n),
      'IconButton' =>
        '<Pressable accessibilityRole="button" style={S.iconBtn} accessibilityLabel=${_str(n.text('tooltip', n.text('icon')))} onPress={${_cb(n.text('onTap'))}}>'
            '<MaterialIcons name={${_icon(n.text('icon', 'add'))}} size={24} color={T.onSurface} /></Pressable>',
      'TextField' => _field(n),
      'ListTile' => _tile(n),
      'Checkbox' =>
        '<Pressable accessibilityRole="button" onPress={async () => { const v = !(${_bool(p['value']) ?? 'false'}); ${TkWebNext.action(n.text('onChanged'))} }}>'
            '<MaterialIcons name={(${_bool(p['value']) ?? 'false'}) ? "check-box" : "check-box-outline-blank"} size={24} color={T.primary} /></Pressable>',
      'Switch' =>
        '<Switch value={!!(${_bool(p['value']) ?? 'false'})} onValueChange={async (v) => { ${TkWebNext.action(n.text('onChanged'))} }} trackColor={{ true: T.primary }} />',
      'Chip' =>
        '<Pressable accessibilityRole="button" onPress={${_cb(tap)}} style={[S.chip, (${_bool(p['selected']) ?? 'false'}) && S.chipOn${color(p['color']) == null ? '' : ', { backgroundColor: ${color(p['color'])} }'}]}>'
            '${n.text('icon').isEmpty ? '' : '<MaterialIcons name={${_icon(n.text('icon'))}} size={16} color={T.onSurface} />'}'
            '<Text style={S.chipText}>${_text(n.text('text', 'Etiqueta'))}</Text></Pressable>',
      'Icon' => press(
        '<MaterialIcons name={${_icon(n.text('icon', 'star'))}} size={${_num(p['size']) ?? '24'}} color={${color(p['color']) ?? 'T.onSurface'}}${inStretch ? ' style={{ alignSelf: "center" }}' : ''} />',
      ),
      'Image' => press(_image(n)),
      'Progress' =>
        '<View style={S.track}><View style={[S.progress, { width: ((${_num(p['value']) ?? '0.4'}) * 100) + "%" }]} /></View>',
      // El lienzo aún no se dibuja en el móvil de React Native: un aviso.
      'Canvas' =>
        '<View style={[S.canvas, { aspectRatio: ${_num(p['aspect']) ?? '1.6'} }]}><Text style={S.canvasText}>Lienzo: en la web y en Flutter</Text></View>',
      'Divider' => '<View style={S.divider} />',
      'SizedBox' =>
        '<View${_style({'height': _num(p['height']) ?? '16', 'width': _num(p['width'])})} />',
      'Spacer' => '<View style={{ flex: 1 }} />',
      _ => throw UserError(tr('Widget desconocido: {0}', [n.type])),
    };
  }

  static String _child(
    FlNode c, {
    required String indent,
    bool inRow = false,
    bool inStretch = false,
  }) {
    final w = jsx(c, indent: indent, inRow: inRow, inStretch: inStretch);
    final vis = _bool(c.props['visible']);
    return vis == null || vis == 'true'
        ? '$indent$w\n'
        : '$indent{($vis) && (\n$indent  $w\n$indent)}\n';
  }

  static String _list(FlNode n, String indent) {
    final items = n.text('items').trim();
    final i2 = '$indent  ';
    final sep = n.props['separated'] == true;
    final pad = _num(n.props['padding']);
    final cs = pad == null ? '' : ' contentContainerStyle={{ padding: $pad }}';
    if (items.isEmpty) {
      return '<ScrollView style={{ flex: 1 }}$cs>\n'
          '${[for (final c in n.children) _child(c, indent: i2)].join()}$indent</ScrollView>';
    }
    final expr = TkWebNext.js(
      items.startsWith('=') ? items.substring(1).trim() : items,
    );
    final name = n.text('as', 'item');
    final body = n.children.isEmpty
        ? '<Text>{String($name)}</Text>'
        : jsx(n.children.first, indent: '$i2    ');
    final empty = n.text('empty');
    return '<ScrollView style={{ flex: 1 }}$cs>\n'
        '$i2{($expr).map(($name, i) => (\n'
        '$i2  <View key={i}${sep ? ' style={i > 0 ? S.sep : null}' : ''}>\n'
        '$i2    $body\n'
        '$i2  </View>\n'
        '$i2))}\n'
        '${empty.isEmpty ? '' : '$i2{($expr).length === 0 && <Text style={S.empty}>${_text(empty)}</Text>}\n'}'
        '$indent</ScrollView>';
  }

  static String _textNode(FlNode n) {
    final p = n.props;
    final st = n.text('style', 'bodyLarge');
    final strike = _bool(p['strike']);
    return '<Text${_style({'color': color(p['color']), if (p['bold'] == true) 'fontWeight': '"700"', if (strike != null && strike != 'false') 'textDecorationLine': '($strike) ? "line-through" : "none"', if (p['align'] != null) 'textAlign': _str('${p['align']}')}, 'S.$st')}'
        '${_num(p['maxLines']) == null ? '' : ' numberOfLines={${_num(p['maxLines'])}}'}>'
        '${_text(n.text('text', 'Texto'))}</Text>';
  }

  static String _button(FlNode n) {
    final enabled = _bool(n.props['enabled']);
    final v = n.text('variant', 'filled');
    final icon = n.text('icon');
    final on = enabled == null || enabled == 'true' ? 'true' : '!!($enabled)';
    final fg = v == 'filled' || v == 'elevated' ? 'T.onPrimary' : 'T.primary';
    return '<Pressable accessibilityRole="button" disabled={!($on)} onPress={${_cb(n.text('onTap'))}}'
        ' style={[S.btn, S.btn_$v, !($on) && S.off]}>'
        '${icon.isEmpty ? '' : '<MaterialIcons name={${_icon(icon)}} size={20} color={$fg} />'}'
        '<Text style={[S.btnText, { color: $fg }]}>${_text(n.text('text', 'Botón'))}</Text></Pressable>';
  }

  static String _field(FlNode n) {
    final bind = n.text('bind').trim();
    final keyboard = switch (n.text('keyboard')) {
      'number' => '"numeric"',
      'email' => '"email-address"',
      'phone' => '"phone-pad"',
      _ => '"default"',
    };
    final lines = _num(n.props['lines']);
    final multi =
        n.text('keyboard') == 'multiline' || (lines != null && lines != '1');
    final submit = n.text('onSubmit');
    final attrs = [
      'style={S.input}',
      'keyboardType={$keyboard}',
      if (n.props['obscure'] == true) 'secureTextEntry',
      if (multi) 'multiline numberOfLines={${lines ?? 4}}',
      if (n.text('hint').isNotEmpty) 'placeholder=${_text(n.text('hint'))}',
      'placeholderTextColor={T.muted}',
      if (bind.isNotEmpty) ...[
        'value={$bind ?? ""}',
        'onChangeText={(v) => { $bind = v; app.notify(); }}',
      ],
      if (submit.isNotEmpty)
        'onSubmitEditing={async () => { ${TkWebNext.action(submit)} }}',
    ].join(' ');
    return '<View style={S.field}>'
        '${n.text('label').isEmpty ? '' : '<Text style={S.fieldLabel}>${_text(n.text('label'))}</Text>'}'
        '<View style={S.fieldBox}>'
        '${n.text('icon').isEmpty ? '' : '<MaterialIcons name={${_icon(n.text('icon'))}} size={20} color={T.muted} />'}'
        '<TextInput $attrs /></View></View>';
  }

  static String _tile(FlNode n) {
    final p = n.props;
    final tap = n.text('onTap');
    final lead = n.text('icon');
    final c = color(p['leadingColor']);
    final trailing = n.text('trailing');
    final trailingIcon = n.text('trailingIcon');
    final body =
        '${lead.isEmpty
            ? ''
            : c == null
            ? '<MaterialIcons name={${_icon(lead)}} size={24} color={T.muted} />'
            : '<View style={[S.avatar, { backgroundColor: $c }]}><MaterialIcons name={${_icon(lead)}} size={22} color="#fff" /></View>'}'
        '<View style={{ flex: 1 }}><Text style={S.tileTitle}>${_text(n.text('title', 'Título'))}</Text>'
        '${n.text('subtitle').isEmpty ? '' : '<Text style={S.tileSub}>${_text(n.text('subtitle'))}</Text>'}</View>'
        '${trailing.isNotEmpty
            ? '<Text style={S.tileSub}>${_text(trailing)}</Text>'
            : trailingIcon.isNotEmpty
            ? '<MaterialIcons name={${_icon(trailingIcon)}} size={22} color={T.muted} />'
            : ''}';
    return tap.isEmpty
        ? '<View style={S.tile}>$body</View>'
        : '<Pressable accessibilityRole="button" style={S.tile} onPress={${_cb(tap)}}>$body</Pressable>';
  }

  static String _image(FlNode n) {
    final src = n.text('src').trim();
    final h = _num(n.props['height']) ?? '160';
    final r = _num(n.props['radius']) ?? '0';
    if (src.isEmpty || !(src.startsWith('http') || src.startsWith('='))) {
      return '<View style={[S.imgPh, { height: $h, borderRadius: $r }]}><MaterialIcons name="image" size={40} color={T.muted} /></View>';
    }
    final uri = src.startsWith('=')
        ? TkWebNext.js(src.substring(1).trim())
        : _str(src);
    return '<Image source={{ uri: $uri }} resizeMode=${_str(n.text('fit', 'cover'))} style={{ width: "100%", height: $h, borderRadius: $r }} />';
  }

  static String _cls(String s) =>
      '${s[0].toUpperCase()}${s.substring(1).replaceAll(RegExp(r'\W'), '')}Screen';

  /// screens/Pantalla.js.
  static String screen(FlApp app, FlScreen s) {
    final first = app.screens.first.name == s.name;
    final bar = [
      for (final (icon, act, badge) in s.barButtons)
        '{ icon: ${_icon(icon)}, badge: ${badge.isEmpty ? 'null' : TkWebNext.tpl(badge)}, onPress: ${_cb(act)} }',
    ];
    return '''// Generado por DMarlon Studio a partir de la pantalla «${s.name}». No lo edite.
import { View, Text, Pressable, TextInput, ScrollView, Switch, Image } from "react-native";
import { MaterialIcons } from "@expo/vector-icons";
import { app, useApp } from "../lib/state";
import { DmsScreen, DmsMissing, useRouter, dmsIcon, S, T } from "../lib/dms";

export default function ${_cls(s.name)}() {
  useApp();
  const router = useRouter();
${s.arg.isEmpty ? '' : '  const arg = router.arg;\n  if (arg === undefined) return <DmsMissing />;\n'}  return (
    <DmsScreen
      title={${s.appBar ? TkWebNext.tpl(s.title.isEmpty ? s.name : s.title) : 'null'}}
      back={${!first && !app.inNav(s.name)}}
      actions={[${bar.join(', ')}]}
${s.fabIcon.isEmpty ? '' : '      fab={{ icon: ${_icon(s.fabIcon)}, onPress: ${_cb(s.fabAction)} }}\n'}    >
      ${jsx(s.body, indent: '      ')}
    </DmsScreen>
  );
}
''';
  }

  /// lib/dms.js: la base de App, la navegación, la pantalla y el tema.
  static String dms(FlApp app) {
    final hex =
        RegExp(r'#?([0-9a-fA-F]{6})').firstMatch(app.primary)?[1] ?? '2B5FD9';
    final dark = app.dark;
    return '''// DMarlon Studio: la base de la app de React Native. Generado: no lo edite.
import { createContext, useContext } from "react";
import { View, Text, Pressable, StyleSheet, SafeAreaView, Platform, StatusBar } from "react-native";
import { MaterialIcons } from "@expo/vector-icons";

/// El tema (del color principal de la app).
export const T = {
  primary: "#$hex",
  onPrimary: "#ffffff",
  primaryContainer: "${_mix(hex, 0.16, dark ? '1b1c20' : 'ffffff')}",
  secondaryContainer: "${_mix(hex, 0.10, dark ? '1b1c20' : 'f1f2f5')}",
  error: "#ba1a1a",
  surface: "${dark ? '#121316' : '#fbfbfd'}",
  surfaceContainer: "${dark ? '#1e2024' : '#f0f1f4'}",
  onSurface: "${dark ? '#e4e4e8' : '#1b1c20'}",
  muted: "${dark ? '#a3a6ad' : '#5b5f69'}",
  line: "${dark ? '#34363c' : '#dfe1e6'}",
};
T.secondary = T.muted;
T.tertiary = T.primary;

/// El menú de la app: pantallas en la barra de abajo.
export const NAV = ${jsonEncode([
      for (final (screen, icon, label) in app.navItems) {'screen': screen, 'icon': _iconName(icon), 'label': label},
    ])};

/// Un icono a partir de su nombre de Material (local_shipping).
export function dmsIcon(name) {
  return String(name || "circle").replace(/_outlined\$/, "").replace(/_/g, "-");
}

/// La navegación: una pila de pantallas.
export const RouterContext = createContext(null);
export const useRouter = () => useContext(RouterContext);

/// La base de App: notify() vuelve a dibujar; go y home cambian de pantalla.
export class DmsApp {
  _subs = new Set();
  _version = 0;

  subscribe = (f) => {
    this._subs.add(f);
    return () => this._subs.delete(f);
  };

  version = () => this._version;

  notify() {
    this._version++;
    for (const f of this._subs) f();
  }

  go(router, screen, arg) {
    router.push(screen, arg);
  }

  home(router, screen) {
    router.reset(screen);
  }

  inNav(screen) {
    return NAV.some((n) => n.screen === screen);
  }

  async start() {}
}

export function DmsScreen({ title, back, actions = [], fab, children }) {
  const router = useRouter();
  const tab = NAV.some((n) => n.screen === router.current);
  return (
    <SafeAreaView style={S.screen}>
      {title !== null && (
        <View style={S.bar}>
          {back && (
            <Pressable accessibilityRole="button" style={S.iconBtn} accessibilityLabel="Volver" onPress={() => router.back()}>
              <MaterialIcons name="arrow-back" size={24} color={T.onSurface} />
            </Pressable>
          )}
          <Text style={S.barTitle} numberOfLines={1}>{title}</Text>
          {actions.map((a, i) => (
            <Pressable accessibilityRole="button" key={i} style={S.iconBtn} onPress={a.onPress}>
              <MaterialIcons name={a.icon} size={24} color={T.onSurface} />
              {a.badge !== null && a.badge !== "0" && a.badge !== "" && (
                <View style={S.badge}><Text style={S.badgeText}>{a.badge}</Text></View>
              )}
            </Pressable>
          ))}
        </View>
      )}
      <View style={{ flex: 1 }}>{children}</View>
      {fab && (
        <Pressable accessibilityRole="button" style={[S.fab, tab && { bottom: 88 }]} onPress={fab.onPress}>
          <MaterialIcons name={fab.icon} size={26} color={T.onSurface} />
        </Pressable>
      )}
      {tab && (
        <View style={S.nav}>
          {NAV.map((n) => (
            <Pressable accessibilityRole="button" key={n.screen} style={S.navItem} onPress={() => router.reset(n.screen)}>
              <View style={[S.navIcon, n.screen === router.current && { backgroundColor: T.primaryContainer }]}>
                <MaterialIcons name={n.icon} size={24} color={T.onSurface} />
              </View>
              <Text style={S.navLabel}>{n.label}</Text>
            </Pressable>
          ))}
        </View>
      )}
    </SafeAreaView>
  );
}

export function DmsMissing() {
  const router = useRouter();
  return (
    <SafeAreaView style={[S.screen, S.center]}>
      <Text>Esta pantalla se abre desde la app.</Text>
    </SafeAreaView>
  );
}

export const S = StyleSheet.create({
  screen: { flex: 1, backgroundColor: T.surface, paddingTop: Platform.OS === "android" ? StatusBar.currentHeight : 0 },
  bar: { flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 12, paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: T.line },
  barTitle: { flex: 1, fontSize: 20, fontWeight: "600", color: T.onSurface, marginLeft: 6 },
  iconBtn: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  badge: { position: "absolute", top: 2, right: 2, minWidth: 18, height: 18, borderRadius: 9, backgroundColor: T.error, alignItems: "center", justifyContent: "center", paddingHorizontal: 4 },
  badgeText: { color: "#fff", fontSize: 11 },
  center: { flex: 1, alignItems: "center", justifyContent: "center" },
  card: { backgroundColor: T.surfaceContainer, borderRadius: 14, borderWidth: 1, borderColor: T.line },
  sep: { borderTopWidth: 1, borderTopColor: T.line },
  empty: { padding: 24, textAlign: "center", color: T.muted },
  displayMedium: { fontSize: 44, color: T.onSurface },
  displaySmall: { fontSize: 36, color: T.onSurface },
  headlineMedium: { fontSize: 28, color: T.onSurface },
  headlineSmall: { fontSize: 24, color: T.onSurface },
  titleLarge: { fontSize: 22, fontWeight: "500", color: T.onSurface },
  titleMedium: { fontSize: 16, fontWeight: "600", color: T.onSurface },
  titleSmall: { fontSize: 15, fontWeight: "600", color: T.onSurface },
  bodyLarge: { fontSize: 16, color: T.onSurface },
  bodyMedium: { fontSize: 15, color: T.onSurface },
  bodySmall: { fontSize: 13, color: T.muted },
  labelLarge: { fontSize: 14, fontWeight: "500", color: T.onSurface },
  labelSmall: { fontSize: 12, color: T.muted },
  btn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, minHeight: 44, paddingHorizontal: 20, borderRadius: 22 },
  btn_filled: { backgroundColor: T.primary },
  btn_elevated: { backgroundColor: T.primary },
  btn_tonal: { backgroundColor: T.primaryContainer },
  btn_outlined: { borderWidth: 1, borderColor: T.line },
  btn_text: {},
  btnText: { fontSize: 15, fontWeight: "600" },
  off: { opacity: 0.45 },
  field: { gap: 6 },
  fieldLabel: { fontSize: 13, color: T.muted },
  fieldBox: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 12, borderWidth: 1, borderColor: T.line, borderRadius: 10, backgroundColor: T.surface },
  input: { flex: 1, paddingVertical: 11, fontSize: 16, color: T.onSurface },
  tile: { flexDirection: "row", alignItems: "center", gap: 14, paddingHorizontal: 16, paddingVertical: 12 },
  avatar: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  tileTitle: { fontSize: 16, fontWeight: "500", color: T.onSurface },
  tileSub: { fontSize: 14, color: T.muted },
  chip: { flexDirection: "row", alignItems: "center", gap: 6, height: 34, paddingHorizontal: 14, borderRadius: 10, borderWidth: 1, borderColor: T.line },
  chipOn: { backgroundColor: T.primaryContainer, borderColor: "transparent" },
  chipText: { fontSize: 14, color: T.onSurface },
  imgPh: { width: "100%", alignItems: "center", justifyContent: "center", backgroundColor: T.secondaryContainer },
  track: { height: 6, borderRadius: 3, backgroundColor: T.line, overflow: "hidden" },
  progress: { height: 6, borderRadius: 3, backgroundColor: T.primary },
  divider: { height: 1, backgroundColor: T.line, marginVertical: 4 },
  canvas: { width: "100%", borderRadius: 12, backgroundColor: "#1f2937", alignItems: "center", justifyContent: "center" },
  canvasText: { color: "#cbd5e1" },
  fab: { position: "absolute", right: 20, bottom: 24, width: 56, height: 56, borderRadius: 16, backgroundColor: T.primaryContainer, alignItems: "center", justifyContent: "center", elevation: 4, shadowColor: "#000", shadowOpacity: 0.2, shadowRadius: 8, shadowOffset: { width: 0, height: 3 } },
  nav: { flexDirection: "row", justifyContent: "space-around", borderTopWidth: 1, borderTopColor: T.line, paddingVertical: 8, backgroundColor: T.surface },
  navItem: { alignItems: "center", gap: 4, minWidth: 72 },
  navIcon: { paddingHorizontal: 18, paddingVertical: 4, borderRadius: 16 },
  navLabel: { fontSize: 12, fontWeight: "500", color: T.onSurface },
});
''';
  }

  /// Mezcla #[hex] con [base] en la proporción [k] (para los tonos claros).
  static String _mix(String hex, double k, String base) {
    int ch(String h, int i) => int.parse(h.substring(i, i + 2), radix: 16);
    String c(int i) => ((ch(hex, i) * k + ch(base, i) * (1 - k)).round().clamp(
      0,
      255,
    )).toRadixString(16).padLeft(2, '0');
    return '#${c(0)}${c(2)}${c(4)}';
  }

  /// App.js: la pila de pantallas.
  static String appJs(FlApp app) =>
      '''// Generado por DMarlon Studio. No lo edite.
import { useState, useMemo } from "react";
import { RouterContext } from "./lib/dms";
${[for (final s in app.screens) 'import ${_cls(s.name)} from "./screens/${s.name}";'].join('\n')}

const SCREENS = { ${[for (final s in app.screens) '${s.name}: ${_cls(s.name)}'].join(', ')} };

export default function App() {
  const [stack, setStack] = useState([{ screen: ${_str(app.screens.first.name)}, arg: undefined }]);
  const top = stack[stack.length - 1];
  const router = useMemo(
    () => ({
      current: top.screen,
      arg: top.arg,
      push: (screen, arg) => setStack((s) => [...s, { screen, arg }]),
      back: () => setStack((s) => (s.length > 1 ? s.slice(0, -1) : s)),
      reset: (screen) => setStack([{ screen, arg: undefined }]),
    }),
    [top],
  );
  const Screen = SCREENS[top.screen];
  return (
    <RouterContext.Provider value={router}>
      <Screen key={stack.length + ":" + top.screen} />
    </RouterContext.Provider>
  );
}
''';

  static const state =
      '''// DMarlon Studio: el estado de la app. Generado: no lo edite.
import { useSyncExternalStore } from "react";
import { App } from "./app";

export const app = new App();

let started = false;

/// Las pantallas se vuelven a dibujar cuando App llama a notify().
export function useApp() {
  if (!started) {
    started = true;
    Promise.resolve(app.start()).then(() => app.notify());
  }
  useSyncExternalStore(app.subscribe, app.version, app.version);
  return app;
}
''';

  /// Todos los archivos (sin node_modules).
  static Map<String, String> files(
    TkDesign d,
    String code, {
    required String name,
  }) {
    final app = FlApp.of(d);
    if (app.screens.isEmpty) throw UserError(tr('La app no tiene pantallas.'));
    final names = <String>{};
    for (final s in app.screens) {
      if (!RegExp(r'^[A-Za-z]\w*$').hasMatch(s.name)) {
        throw UserError(
          tr('«{0}» no sirve como nombre de pantalla.', [s.name]),
        );
      }
      if (!names.add(s.name.toLowerCase())) {
        throw UserError(tr('Hay dos pantallas llamadas «{0}».', [s.name]));
      }
    }
    for (final (screen, _, _) in app.navItems) {
      if (app.screen(screen) == null) {
        throw UserError(
          tr('El menú nombra la pantalla «{0}», que no existe.', [screen]),
        );
      }
    }
    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final title = app.title.isEmpty ? name : app.title;
    return {
      'package.json': const JsonEncoder.withIndent('  ').convert({
        'name': slug.isEmpty ? 'dmarlon-app' : slug,
        'version': '1.0.0',
        'private': true,
        'main': 'index.js',
        'scripts': {
          'start': 'expo start',
          'web': 'expo start --web',
          'android': 'expo start --android',
          'ios': 'expo start --ios',
        },
        'dependencies': dependencies,
      }),
      'app.json': const JsonEncoder.withIndent('  ').convert({
        'expo': {
          'name': title,
          'slug': slug.isEmpty ? 'dmarlon-app' : slug,
          'platforms': ['ios', 'android', 'web'],
          'web': {'bundler': 'metro'},
        },
      }),
      'index.js':
          '// Generado por DMarlon Studio. No lo edite.\n'
          'import { registerRootComponent } from "expo";\n'
          'import App from "./App";\n\n'
          'registerRootComponent(App);\n',
      'App.js': appJs(app),
      for (final s in app.screens) 'screens/${s.name}.js': screen(app, s),
      'lib/dms.js': dms(app),
      'lib/state.js': state,
      'lib/app.js': code.replaceAll('\r\n', '\n'),
      'README.md':
          '# $title\n\n'
          '${tr('App de React Native (Expo) creada con DMarlon Studio.')}\n\n'
          '```\nnpm install\nnpx expo start\n```\n',
    };
  }

  /// Lo que se ve en la pestaña «JavaScript generado».
  static String preview(TkDesign d) {
    final app = FlApp.of(d);
    return [
      for (final s in app.screens)
        '// ---- screens/${s.name}.js\n${screen(app, s)}',
    ].join('\n');
  }
}
