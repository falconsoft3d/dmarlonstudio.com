import 'package:flutter/material.dart';

import '../i18n/tr.dart';

/// Colores de la marca DMarlon Studio y de estado.
class AppColors {
  AppColors._();

  /// Azul de la marca.
  static const brand = Color(0xFF2B5FD9);
  static const success = Color(0xFF2F9E44);
  static const info = Color(0xFF1C7ED6);
  static const warning = Color(0xFFE67700);
  static const danger = Color(0xFFE03131);
  static const muted = Color(0xFF868E96);

  /// Texto e iconos principales según el modo.
  static Color ink(BuildContext c) => Theme.of(c).brightness == Brightness.dark
      ? const Color(0xFFE6E8EB)
      : Theme.of(c).colorScheme.onSurface;
}

/// Colores para series de diagramas y gráficos (validados en cada modo).
List<Color> biPalette(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? _darkPalette
    : _lightPalette;

const _lightPalette = [
  Color(0xFF2A78D6),
  Color(0xFFEB6834),
  Color(0xFF1BAF7A),
  Color(0xFFEDA100),
  Color(0xFFE87BA4),
  Color(0xFF008300),
  Color(0xFF6250D6),
  Color(0xFFE34948),
];
const _darkPalette = [
  Color(0xFF3987E5),
  Color(0xFFD95926),
  Color(0xFF199E70),
  Color(0xFFC98500),
  Color(0xFFD55181),
  Color(0xFF008300),
  Color(0xFF9085E9),
  Color(0xFFE66767),
];

/// Colores con nombre para el selector de color del inspector (el nombre se
/// traduce al mostrarlo con tr).
final metroColors = <(int, String)>[
  (0xFF2D89EF, markTr('Azul')),
  (0xFF2B5797, markTr('Azul oscuro')),
  (0xFF00ABA9, markTr('Turquesa')),
  (0xFF1E7145, markTr('Verde oscuro')),
  (0xFF00A300, markTr('Verde')),
  (0xFF99B433, markTr('Lima')),
  (0xFFE3A21A, markTr('Ámbar')),
  (0xFFDA532C, markTr('Naranja')),
  (0xFFEE1111, markTr('Rojo')),
  (0xFFB91D47, markTr('Granate')),
  (0xFFFF0097, markTr('Magenta')),
  (0xFF9F00A7, markTr('Púrpura')),
  (0xFF603CBA, markTr('Violeta')),
  (0xFF7E3878, markTr('Ciruela')),
  (0xFF525252, markTr('Gris')),
  (0xFF1D1D1D, markTr('Negro')),
];

final _squared = ButtonStyle(
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  ),
);

/// Tema del estudio: denso, como un IDE de escritorio.
ThemeData studioTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: b,
    surface: dark ? const Color(0xFF1E1F22) : const Color(0xFFFFFFFF),
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Lato',
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF1E1F22)
        : const Color(0xFFF7F8FA),
    dividerColor: dark ? const Color(0xFF393B40) : const Color(0xFFE1E3E8),
    // Esquinas sobrias, como en un IDE de escritorio (Material 3 usa 28).
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    // Botones con esquinas de 6 px (Material 3 los hace de píldora).
    filledButtonTheme: FilledButtonThemeData(style: _squared),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _squared),
    textButtonTheme: TextButtonThemeData(style: _squared),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _squared),
    iconButtonTheme: IconButtonThemeData(style: _squared),
    segmentedButtonTheme: SegmentedButtonThemeData(style: _squared),
    chipTheme: const ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    menuButtonTheme: MenuButtonThemeData(style: _squared),
    popupMenuTheme: PopupMenuThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 400),
    ),
  );
}
