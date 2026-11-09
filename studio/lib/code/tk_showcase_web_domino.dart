part of 'tk_examples.dart';

// --------------------------------------------- dominó doble 9 (web HTML)
/// El dominó de doble 9 como web en HTML, CSS y JavaScript: una pantalla
/// con un Lienzo que dibuja la mesa (App.dibujar) y recibe los toques
/// (App.tocar). Se juega en el navegador, también en el móvil.
TkExample _htmlDomino(String Function(String) t) {
  String tc(String id) {
    final k = contextKey('domino', id);
    final r = t(k);
    return r == k ? id : r;
  }

  final title = t(markTr('Dominó doble 9'));
  // Los mismos textos que el dominó de escritorio, con {} por cada dato.
  final texts = <String, String>{
    'YOU': t(markTr('Usted')),
    'TEAM_US': t(markTr('Nosotros')),
    'TEAM_THEM': t(markTr('Ellos')),
    'HAND': t(markTr('Mano {}')),
    'TO': t(markTr('a {}')),
    'EMPTY': t(markTr('La mesa está vacía')),
    'DOMINO': t(markTr('¡Dominó de {}!')),
    'TRANQUE': t(markTr('¡Tranque!')),
    'TRANQUE_WIN': t(markTr('Gana {} con {} tantos.')),
    'TIE': t(markTr('Empate en el tranque: nadie se anota.')),
    'POINTS': t(markTr('{} se anotan {} tantos')),
    'LEFT_TILES': t(markTr('Las fichas que quedaban')),
    'WIN_US': t(markTr('¡Ganamos la partida!')),
    'WIN_THEM': t(markTr('Ellos ganan la partida')),
    'AGAIN': t(markTr('Toque para una partida nueva')),
    'NEXT_HAND': t(markTr('Toque para la siguiente mano')),
    'OPENS': t(markTr('Sale')),
    'YOUR_TURN': t(markTr('Su turno: toque una ficha')),
    'CHOOSE_END': t(markTr('Esa ficha va por las dos puntas: elija una')),
    'YOU_PASS': t(markTr('No lleva: usted pasa')),
    'THINKING': t(markTr('Juega {}…')),
    'PASS': tc(markTrc('domino', 'Paso')),
  };
  final app = FlApp(
    title: title,
    primary: '#1F6E3D',
    screens: [
      FlScreen(
        name: 'Mesa',
        title: title,
        // Partida nueva y ver las fichas de todos.
        bar: 'refresh|app.newGame()\nvisibility|app.toggleAll()',
        body: _n('Column', {}, [
          _n('Canvas', {
            'paint': 'app.dibujar(ctx, w, h)',
            'onTap': 'app.tocar(x, y)',
            'aspect': 1.5714,
          }),
        ]),
      ),
    ],
  );
  final design = TkDesign(target: tkTargetWebHtml, props: {'title': title});
  app.saveTo(design);
  final code =
      '''// ${t(markTr('Dominó de doble 9 en la web: la mesa se dibuja en un Lienzo y se juega tocando las fichas.'))}
import { DmsApp } from "./dms";

// Los textos (los traduce el estudio con el resto del ejemplo).
const TX = ${const JsonEncoder.withIndent('  ').convert(texts)};
$_webDominoCode''';
  return TkExample(
    'html_domino',
    t(markTr('Dominó doble 9 (web)')),
    t(
      markTr(
        'El dominó cubano de doble 9 como web en HTML y JavaScript: una pantalla con un Lienzo que dibuja la mesa y recibe los toques. Se juega en el navegador, también en el móvil.',
      ),
    ),
    design,
    code,
  );
}
