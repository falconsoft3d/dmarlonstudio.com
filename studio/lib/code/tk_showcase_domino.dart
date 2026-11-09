part of 'tk_examples.dart';

// ------------------------------------------------- dominó doble 9 (tkinter)
/// Dominó cubano de doble 9 en Python con tkinter: una mesa con cuatro
/// jugadores en dos parejas (usted y su compañero contra dos rivales que
/// juega la computadora), 10 fichas cada uno, pasar cuando no se lleva,
/// dominó y tranque, y partida a 100 o a 200 tantos. Las fichas, la mesa y
/// la cadena que gira como una serpiente se dibujan en el lienzo.
TkExample tkDomino(String Function(String) t) {
  final app = t(markTr('Dominó doble 9'));
  // Con contexto (msgctxt «domino»): «Paso» es «no llevo», no un paso.
  String tc(String id) {
    final k = contextKey('domino', id);
    final r = t(k);
    return r == k ? id : r;
  }

  final mGame = t(markTr('Juego')), mView = t(markTr('Ver'));
  final mHelp = t(markTr('Ayuda'));
  final lines = <String>[];
  final paths = <String, String>{};
  void item(String id, String label, String prefix) {
    lines.add('  $label');
    paths['MP_$id'] = '$prefix/$label';
  }

  lines.add(mGame);
  item('NEW', t(markTr('Nueva partida')), mGame);
  lines.add('  -');
  item('TO100', t(markTr('Partida a 100 tantos')), mGame);
  item('TO200', t(markTr('Partida a 200 tantos')), mGame);
  lines.add('  -');
  item('QUIT', t(markTr('Salir')), mGame);
  lines.add(mView);
  item('FULLSCREEN', t(markTr('Pantalla completa')), mView);
  item('SHOW_ALL', t(markTr('Ver las fichas de todos')), mView);
  lines.add(mHelp);
  item('RULES', t(markTr('Reglas del dominó')), mHelp);
  item('ABOUT', t(markTr('Acerca de Dominó doble 9')), mHelp);

  final texts = <String, String>{
    'APP': app,
    ...paths,
    'L_RULES': t(markTr('Reglas del dominó')),
    'L_ABOUT': t(markTr('Acerca de Dominó doble 9')),
    'TEAM_US': t(markTr('Nosotros')),
    'TEAM_THEM': t(markTr('Ellos')),
    'HAND_FMT': t(markTr('Mano {}')),
    'TO_FMT': t(markTr('a {}')),
    'EMPTY_BOARD': t(markTr('La mesa está vacía')),
    'DOMINO_FMT': t(markTr('¡Dominó de {}!')),
    'TRANQUE': t(markTr('¡Tranque!')),
    'TRANQUE_WIN_FMT': t(markTr('Gana {} con {} tantos.')),
    'TIE': t(markTr('Empate en el tranque: nadie se anota.')),
    'POINTS_FMT': t(markTr('{} se anotan {} tantos')),
    'LEFT_TILES': t(markTr('Las fichas que quedaban')),
    'WIN_US': t(markTr('¡Ganamos la partida!')),
    'WIN_THEM': t(markTr('Ellos ganan la partida')),
    'AGAIN': t(markTr('Clic o Intro para una partida nueva')),
    'NEXT_HAND': t(markTr('Clic o Intro para la siguiente mano')),
    'OPENS_FLASH': t(markTr('Sale')),
    'YOUR_TURN': t(markTr('Su turno: haga clic en una ficha')),
    'CHOOSE_END': t(markTr('Esa ficha va por las dos puntas: elija una')),
    'YOU_PASS': t(markTr('No lleva: usted pasa')),
    'THINKING_FMT': t(markTr('Juega {}…')),
    'PASS': tc(markTrc('domino', 'Paso')),
    'YOU': t(markTr('Usted')),
    'RULES_TEXT': t(
      markTr(
        'Dominó cubano de doble 9: 55 fichas, cuatro jugadores en dos parejas. Usted juega con Yuniel, que está enfrente, contra Mayelín y Osmany.\n\nCada uno recibe 10 fichas; las 15 que sobran no se juegan. La primera mano la abre quien tenga el doble más alto; después sale el siguiente jugador. Se juega por turnos hacia la derecha poniendo una ficha que coincida con una de las dos puntas. Quien no lleva, pasa.\n\nDominó: el que se queda sin fichas gana la mano para su pareja, que se anota los tantos de todas las fichas que quedan. Tranque: si nadie puede jugar, gana el jugador con menos tantos (si empatan las dos parejas, nadie se anota). La partida es a 100 tantos (o a 200, en el menú Juego).',
      ),
    ),
    'ABOUT_TEXT': t(
      markTr(
        'Una demo de DMarlon Studio: dominó de doble 9 en Python con tkinter. La ventana, el menú y el reloj se diseñaron en el Diseñador del estudio; la mesa, las fichas y los jugadores de la computadora están en el código.',
      ),
    ),
  };
  final consts = [
    for (final MapEntry(:key, :value) in texts.entries)
      '$key = ${TkPy.str(value)}',
  ].join('\n');
  // Los jugadores: usted (abajo), y a su derecha, enfrente y a su izquierda.
  final names =
      'PLAYER_NAMES = [YOU, "Mayelín", "Yuniel", "Osmany"]  # sur, este, norte, oeste';

  final design =
      TkDesign(
          width: 1100,
          height: 700,
          props: {
            'title': app,
            'bg': '#1f6e3d',
            'position': 'center',
            'resizable': true,
          },
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w(
            'Menu',
            'Menu1',
            1040,
            8,
            32,
            32,
            {'items': lines.join('\n')},
            {'command': 'Menu1_click'},
          ),
          // Juegan los de la computadora y pasa el que no lleva.
          _w(
            'Timer',
            'Tick',
            1000,
            8,
            32,
            32,
            {'interval': 150},
            {'command': 'Tick_timer'},
          ),
          _w(
            'Canvas',
            'Table',
            0,
            0,
            1100,
            700,
            {'bg': '#1f6e3d'},
            {
              'click': 'Table_click',
              'motion': 'Table_motion',
              'leave': 'Table_leave',
            },
          ),
          // Solo para el Diseñador: el juego la quita al arrancar.
          _w('Label', 'TableHint', 250, 320, 600, 40, {
            'text': t(
              markTr(
                'La mesa, las fichas y los jugadores los dibuja el código en este lienzo',
              ),
            ),
            'fg': '#cfe9d6',
            'bg': '#1f6e3d',
            'font_size': 15,
          }),
        ]);

  final code =
      '''# ${t(markTr('Dominó de doble 9 en Python con tkinter: cuatro jugadores en dos parejas, dominó, tranque y partida a 100 tantos.'))}
import os
import random
import sys
import time
import tkinter as tk
import tkinter.font as tkfont
from tkinter import messagebox

# Los textos de la interfaz (los traduce el estudio con el resto del ejemplo).
$consts
$names
$_dominoCode''';
  return TkExample(
    'domino',
    t(markTr('Dominó doble 9')),
    t(
      markTr(
        'Dominó cubano de doble 9 en una mesa de cuatro: usted y su compañero contra dos rivales de la computadora, 10 fichas cada uno, dominó, tranque y partida a 100 tantos, todo dibujado en un lienzo.',
      ),
    ),
    design,
    code,
  );
}
