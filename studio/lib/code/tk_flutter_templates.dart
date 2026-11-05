import '../i18n/tr.dart';
import 'tk_flutter.dart';

/// Una plantilla de pantalla: las 20 más usadas en las apps móviles. Su
/// contenido es de ejemplo y sus botones escriben en la Salida
/// (debugPrint): se enlazan después con App.
class FlTemplate {
  const FlTemplate(this.id, this.name, this.description, this.icon, this.build);

  final String id;

  /// Nombre y descripción (para traducir con tr).
  final String name, description;

  /// Icono de Material (su nombre).
  final String icon;

  /// La pantalla, con el nombre que se le dé.
  final FlScreen Function(String name, String Function(String) t) build;
}

FlNode _n(String type, [Map<String, Object?>? p, List<FlNode>? c]) =>
    FlNode(type, p, c);

String _say(String what) => "debugPrint('${what.replaceAll("'", r"\'")}')";

FlNode _field(
  String label,
  String icon, {
  bool obscure = false,
  String keyboard = 'text',
}) => _n('TextField', {
  'label': label,
  'icon': icon,
  if (obscure) 'obscure': true,
  if (keyboard != 'text') 'keyboard': keyboard,
});

FlNode _tile(
  String title,
  String subtitle,
  String icon, {
  String? trailing,
  String? trailingIcon,
  String? color,
}) => _n('ListTile', {
  'title': title,
  'subtitle': subtitle,
  'icon': icon,
  'trailing': ?trailing,
  'trailingIcon': ?trailingIcon,
  'leadingColor': ?color,
});

FlNode _form(List<FlNode> kids) => _n(
  'ListView',
  {'padding': 20},
  [
    _n('Column', {'gap': 14}, kids),
  ],
);

/// Las 20 plantillas.
final flTemplates = <FlTemplate>[
  FlTemplate(
    'login',
    markTr('Inicio de sesión'),
    markTr('Correo, contraseña y entrar.'),
    'login',
    (name, t) => FlScreen(
      name: name,
      appBar: false,
      body: _n('Center', {}, [
        _n(
          'Padding',
          {'padding': 28},
          [
            _n(
              'Column',
              {'main': 'center', 'gap': 14},
              [
                _n('Icon', {'icon': 'lock', 'size': 64, 'color': 'primary'}),
                _n('Text', {
                  'text': t(markTr('Bienvenido')),
                  'style': 'headlineMedium',
                  'bold': true,
                  'align': 'center',
                }),
                _n('Text', {
                  'text': t(markTr('Entre con su cuenta')),
                  'align': 'center',
                }),
                _field(t(markTr('Correo')), 'email', keyboard: 'email'),
                _field(t(markTr('Contraseña')), 'lock', obscure: true),
                _n('Button', {
                  'text': t(markTr('Entrar')),
                  'icon': 'login',
                  'onTap': _say('entrar'),
                }),
                _n('Button', {
                  'text': t(markTr('¿Olvidó la contraseña?')),
                  'variant': 'text',
                  'onTap': _say('recuperar'),
                }),
                _n('Button', {
                  'text': t(markTr('Crear una cuenta')),
                  'variant': 'outlined',
                  'onTap': _say('registro'),
                }),
              ],
            ),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'signup',
    markTr('Registro'),
    markTr('Nombre, correo, contraseña y condiciones.'),
    'person_add',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Crear una cuenta')),
      body: _form([
        _field(t(markTr('Nombre')), 'person'),
        _field(t(markTr('Correo')), 'email', keyboard: 'email'),
        _field(t(markTr('Contraseña')), 'lock', obscure: true),
        _field(t(markTr('Repita la contraseña')), 'lock', obscure: true),
        _n('Row', {}, [
          _n('Checkbox', {'value': '=true', 'onChanged': _say('condiciones')}),
          _n('Expanded', {}, [
            _n('Text', {'text': t(markTr('Acepto las condiciones de uso'))}),
          ]),
        ]),
        _n('Button', {
          'text': t(markTr('Crear la cuenta')),
          'icon': 'person_add',
          'onTap': _say('crear cuenta'),
        }),
      ]),
    ),
  ),
  FlTemplate(
    'forgot',
    markTr('Recuperar contraseña'),
    markTr('Envía un enlace al correo.'),
    'lock_reset',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Recuperar contraseña')),
      body: _n(
        'Column',
        {'padding': 24, 'gap': 16},
        [
          _n('Icon', {'icon': 'lock_reset', 'size': 64, 'color': 'primary'}),
          _n('Text', {
            'text': t(
              markTr(
                'Escriba su correo y le enviaremos un enlace para crear una contraseña nueva.',
              ),
            ),
            'align': 'center',
          }),
          _field(t(markTr('Correo')), 'email', keyboard: 'email'),
          _n('Button', {
            'text': t(markTr('Enviar el enlace')),
            'icon': 'send',
            'onTap': _say('enviar enlace'),
          }),
          _n('Button', {
            'text': t(markTr('Volver')),
            'variant': 'text',
            'onTap': 'back',
          }),
        ],
      ),
    ),
  ),
  FlTemplate(
    'welcome',
    markTr('Bienvenida'),
    markTr('Presentación de la app con un botón para empezar.'),
    'waving_hand',
    (name, t) => FlScreen(
      name: name,
      appBar: false,
      body: _n(
        'Column',
        {'padding': 28, 'gap': 16, 'main': 'center'},
        [
          _n(
            'Container',
            {'height': 220, 'radius': 28, 'color': 'primaryContainer'},
            [
              _n('Center', {}, [
                _n('Icon', {
                  'icon': 'rocket_launch',
                  'size': 96,
                  'color': 'primary',
                }),
              ]),
            ],
          ),
          _n('Text', {
            'text': t(markTr('Todo lo que necesita, en un solo lugar')),
            'style': 'headlineSmall',
            'bold': true,
            'align': 'center',
          }),
          _n('Text', {
            'text': t(
              markTr(
                'Organice su día, encuentre lo que busca y compártalo con quien quiera.',
              ),
            ),
            'align': 'center',
          }),
          _n('Progress', {'value': 0.33}),
          _n('Button', {
            'text': t(markTr('Empezar')),
            'icon': 'arrow_forward',
            'onTap': _say('empezar'),
          }),
          _n('Button', {
            'text': t(markTr('Ya tengo cuenta')),
            'variant': 'text',
            'onTap': _say('ya tengo cuenta'),
          }),
        ],
      ),
    ),
  ),
  FlTemplate(
    'home',
    markTr('Inicio'),
    markTr('Saludo, accesos rápidos y novedades.'),
    'home',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Inicio')),
      bar: 'notifications|${_say('avisos')}|3',
      body: _n(
        'ListView',
        {'padding': 16},
        [
          _n(
            'Column',
            {'gap': 14},
            [
              _n('Text', {
                'text': t(markTr('Hola, Ana')),
                'style': 'headlineSmall',
                'bold': true,
              }),
              _n(
                'Row',
                {'gap': 10},
                [
                  for (final (icon, label) in [
                    ('shopping_cart', t(markTr('Compras'))),
                    ('calendar_today', t(markTr('Agenda'))),
                    ('chat', t(markTr('Mensajes'))),
                  ])
                    _n('Expanded', {}, [
                      _n(
                        'Card',
                        {'padding': 12, 'onTap': _say(label)},
                        [
                          _n(
                            'Column',
                            {'cross': 'center', 'gap': 6},
                            [
                              _n('Icon', {'icon': icon, 'color': 'primary'}),
                              _n('Text', {
                                'text': label,
                                'style': 'labelLarge',
                              }),
                            ],
                          ),
                        ],
                      ),
                    ]),
                ],
              ),
              _n('Text', {
                'text': t(markTr('Novedades')),
                'style': 'titleMedium',
              }),
              _n(
                'Card',
                {'padding': 0},
                [
                  _n('Column', {}, [
                    _n('Image', {'height': 140}),
                    _tile(
                      t(markTr('Nueva función disponible')),
                      t(markTr('Descubra lo nuevo de esta semana')),
                      'star',
                    ),
                  ]),
                ],
              ),
              _tile(
                t(markTr('Su pedido está en camino')),
                t(markTr('Llega mañana')),
                'local_shipping',
                trailingIcon: 'chevron_right',
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  FlTemplate(
    'list',
    markTr('Lista'),
    markTr('Búsqueda y una lista de elementos.'),
    'list',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Elementos')),
      fabIcon: 'add',
      fabAction: _say('nuevo'),
      body: _n('Column', {}, [
        _n(
          'Padding',
          {'padding': 12},
          [
            _n('TextField', {'hint': t(markTr('Buscar')), 'icon': 'search'}),
          ],
        ),
        _n(
          'ListView',
          {'separated': true},
          [
            for (var i = 1; i <= 6; i++)
              _tile(
                '${t(markTr('Elemento'))} $i',
                t(markTr('Descripción breve')),
                'circle',
                trailingIcon: 'chevron_right',
              ),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'detail',
    markTr('Detalle'),
    markTr('Imagen, título, datos y acción principal.'),
    'article',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Detalle')),
      bar: 'favorite_border|${_say('favorito')}\nshare|${_say('compartir')}',
      body: _n('ListView', {}, [
        _n('Image', {'height': 220}),
        _n(
          'Column',
          {'padding': 16, 'gap': 10},
          [
            _n('Text', {
              'text': t(markTr('Título del elemento')),
              'style': 'headlineSmall',
              'bold': true,
            }),
            _n(
              'Row',
              {'gap': 8, 'wrap': true},
              [
                _n('Chip', {'text': t(markTr('Categoría')), 'icon': 'sell'}),
                _n('Chip', {'text': '4,8', 'icon': 'star'}),
              ],
            ),
            _n('Text', {
              'text': t(
                markTr(
                  'Una descripción con los detalles más importantes: qué es, para qué sirve y por qué le interesa.',
                ),
              ),
            }),
            _tile(t(markTr('Ubicación')), 'Madrid', 'place'),
            _tile(t(markTr('Fecha')), '12/05/2026', 'calendar_today'),
            _n('Button', {
              'text': t(markTr('Reservar')),
              'icon': 'check',
              'onTap': _say('reservar'),
            }),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'profile',
    markTr('Perfil'),
    markTr('Foto, nombre y opciones de la cuenta.'),
    'person',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Perfil')),
      bar: 'edit|${_say('editar')}',
      body: _n(
        'ListView',
        {'padding': 16},
        [
          _n(
            'Column',
            {'cross': 'center', 'gap': 8},
            [
              _n(
                'Container',
                {
                  'width': 96,
                  'height': 96,
                  'radius': 48,
                  'color': 'primaryContainer',
                },
                [
                  _n('Center', {}, [
                    _n('Icon', {
                      'icon': 'person',
                      'size': 56,
                      'color': 'primary',
                    }),
                  ]),
                ],
              ),
              _n('Text', {
                'text': 'Ana López',
                'style': 'titleLarge',
                'bold': true,
              }),
              _n('Text', {'text': 'ana@correo.com'}),
            ],
          ),
          _n('SizedBox', {'height': 12}),
          _tile(
            t(markTr('Mis pedidos')),
            t(markTr('3 en curso')),
            'shopping_bag',
            trailingIcon: 'chevron_right',
          ),
          _tile(
            t(markTr('Direcciones')),
            t(markTr('Casa y trabajo')),
            'place',
            trailingIcon: 'chevron_right',
          ),
          _tile(
            t(markTr('Métodos de pago')),
            'Visa •••• 4242',
            'credit_card',
            trailingIcon: 'chevron_right',
          ),
          _tile(
            t(markTr('Ajustes')),
            t(markTr('Notificaciones y privacidad')),
            'settings',
            trailingIcon: 'chevron_right',
          ),
          _n('Button', {
            'text': t(markTr('Cerrar sesión')),
            'variant': 'outlined',
            'icon': 'logout',
            'onTap': _say('salir'),
          }),
        ],
      ),
    ),
  ),
  FlTemplate(
    'edit_profile',
    markTr('Editar perfil'),
    markTr('Formulario con los datos del usuario.'),
    'edit',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Editar perfil')),
      body: _form([
        _field(t(markTr('Nombre')), 'person'),
        _field(t(markTr('Correo')), 'email', keyboard: 'email'),
        _field(t(markTr('Teléfono')), 'phone', keyboard: 'phone'),
        _n('TextField', {
          'label': t(markTr('Sobre mí')),
          'lines': 3,
          'keyboard': 'multiline',
        }),
        _n('Button', {
          'text': t(markTr('Guardar')),
          'icon': 'save',
          'onTap': '${_say('guardar')}; back',
        }),
      ]),
    ),
  ),
  FlTemplate(
    'settings',
    markTr('Ajustes'),
    markTr('Interruptores y opciones agrupadas.'),
    'settings',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Ajustes')),
      body: _n('ListView', {}, [
        for (final (label, icon) in [
          (t(markTr('Notificaciones')), 'notifications'),
          (t(markTr('Tema oscuro')), 'dark_mode'),
          (t(markTr('Ubicación')), 'location_on'),
        ])
          _n(
            'Row',
            {'padding': 4},
            [
              _n('Expanded', {}, [_tile(label, '', icon)]),
              _n('Switch', {'value': '=true', 'onChanged': _say(label)}),
            ],
          ),
        _n('Divider'),
        _tile(
          t(markTr('Idioma')),
          'Español',
          'language',
          trailingIcon: 'chevron_right',
        ),
        _tile(
          t(markTr('Privacidad')),
          '',
          'lock',
          trailingIcon: 'chevron_right',
        ),
        _tile(
          t(markTr('Acerca de')),
          '1.0.0',
          'info',
          trailingIcon: 'chevron_right',
        ),
      ]),
    ),
  ),
  FlTemplate(
    'notifications',
    markTr('Notificaciones'),
    markTr('Avisos recientes con su icono.'),
    'notifications',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Notificaciones')),
      bar: 'done_all|${_say('marcar leídas')}',
      body: _n(
        'ListView',
        {'separated': true},
        [
          _tile(
            t(markTr('Pedido enviado')),
            t(markTr('Hace 5 minutos')),
            'local_shipping',
            color: 'primary',
          ),
          _tile(
            t(markTr('Nuevo mensaje de Luis')),
            t(markTr('Hace 1 hora')),
            'chat',
            color: 'tertiary',
          ),
          _tile(
            t(markTr('Pago confirmado')),
            t(markTr('Ayer')),
            'payments',
            color: 'secondary',
          ),
          _tile(
            t(markTr('Oferta especial para usted')),
            t(markTr('Hace 2 días')),
            'sell',
            color: 'error',
          ),
        ],
      ),
    ),
  ),
  FlTemplate(
    'messages',
    markTr('Mensajes'),
    markTr('Conversaciones con el último mensaje.'),
    'chat',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Mensajes')),
      fabIcon: 'edit',
      fabAction: _say('nuevo mensaje'),
      body: _n(
        'ListView',
        {'separated': true},
        [
          for (final (who, last, time) in [
            ('Luis Pérez', t(markTr('¿Nos vemos mañana?')), '10:24'),
            ('Marta Gil', t(markTr('¡Gracias!')), '09:02'),
            (
              t(markTr('Equipo')),
              t(markTr('La reunión pasa a las 5')),
              t(markTr('Ayer')),
            ),
          ])
            _tile(who, last, 'person', trailing: time, color: 'primary'),
        ],
      ),
    ),
  ),
  FlTemplate(
    'chat',
    markTr('Conversación'),
    markTr('Mensajes y un campo para escribir.'),
    'forum',
    (name, t) => FlScreen(
      name: name,
      title: 'Luis Pérez',
      bar: 'call|${_say('llamar')}',
      body: _n('Column', {}, [
        _n(
          'ListView',
          {'padding': 12},
          [
            _n(
              'Column',
              {'gap': 8},
              [
                _n('Row', {}, [
                  _n(
                    'Container',
                    {'padding': 10, 'radius': 14, 'color': 'surfaceContainer'},
                    [
                      _n('Text', {'text': t(markTr('Hola, ¿cómo va todo?'))}),
                    ],
                  ),
                ]),
                _n(
                  'Row',
                  {'main': 'end'},
                  [
                    _n(
                      'Container',
                      {
                        'padding': 10,
                        'radius': 14,
                        'color': 'primaryContainer',
                      },
                      [
                        _n('Text', {'text': t(markTr('¡Muy bien! ¿Y tú?'))}),
                      ],
                    ),
                  ],
                ),
                _n('Row', {}, [
                  _n(
                    'Container',
                    {'padding': 10, 'radius': 14, 'color': 'surfaceContainer'},
                    [
                      _n('Text', {'text': t(markTr('¿Nos vemos mañana?'))}),
                    ],
                  ),
                ]),
              ],
            ),
          ],
        ),
        _n(
          'Padding',
          {'padding': 8},
          [
            _n(
              'Row',
              {'gap': 6},
              [
                _n('Expanded', {}, [
                  _n('TextField', {'hint': t(markTr('Escriba un mensaje'))}),
                ]),
                _n('IconButton', {'icon': 'send', 'onTap': _say('enviar')}),
              ],
            ),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'search',
    markTr('Búsqueda'),
    markTr('Campo de búsqueda, filtros y resultados.'),
    'search',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Buscar')),
      body: _n('Column', {}, [
        _n(
          'Padding',
          {'padding': 12},
          [
            _n('TextField', {
              'hint': t(markTr('¿Qué busca?')),
              'icon': 'search',
            }),
          ],
        ),
        _n(
          'Padding',
          {'padding': 6},
          [
            _n(
              'Row',
              {'gap': 6, 'wrap': true},
              [
                for (final c in [
                  t(markTr('Todo')),
                  t(markTr('Cerca')),
                  t(markTr('Abierto')),
                  t(markTr('Mejor valorado')),
                ])
                  _n('Chip', {
                    'text': c,
                    'selected': c == t(markTr('Todo')) ? '=true' : '=false',
                    'onTap': _say(c),
                  }),
              ],
            ),
          ],
        ),
        _n(
          'ListView',
          {'separated': true},
          [
            for (var i = 1; i <= 5; i++)
              _tile(
                '${t(markTr('Resultado'))} $i',
                t(markTr('A 1,2 km · abierto')),
                'place',
                trailing: '4,${9 - i}',
              ),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'cart',
    markTr('Carrito'),
    markTr('Productos, cantidades y total.'),
    'shopping_cart',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Carrito')),
      body: _n('Column', {}, [
        _n(
          'ListView',
          {'separated': true},
          [
            for (final (p, q, price) in [
              (t(markTr('Camiseta')), 2, '25,80 €'),
              (t(markTr('Gorra')), 1, '14,90 €'),
            ])
              _n('Row', {}, [
                _n('Expanded', {}, [
                  _tile(p, '$q ×', 'shopping_bag', trailing: price),
                ]),
                _n('IconButton', {
                  'icon': 'remove_circle_outline',
                  'onTap': _say('quitar'),
                }),
                _n('IconButton', {
                  'icon': 'add_circle_outline',
                  'onTap': _say('sumar'),
                }),
              ]),
          ],
        ),
        _n(
          'Padding',
          {'padding': 16},
          [
            _n(
              'Column',
              {'gap': 12},
              [
                _n(
                  'Row',
                  {'main': 'spaceBetween'},
                  [
                    _n('Text', {
                      'text': t(markTr('Total')),
                      'style': 'titleLarge',
                    }),
                    _n('Text', {
                      'text': '40,70 €',
                      'style': 'titleLarge',
                      'bold': true,
                    }),
                  ],
                ),
                _n('Button', {
                  'text': t(markTr('Pagar')),
                  'icon': 'payments',
                  'onTap': _say('pagar'),
                }),
              ],
            ),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'checkout',
    markTr('Pago'),
    markTr('Dirección, tarjeta y resumen.'),
    'payments',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Pago')),
      body: _form([
        _n('Text', {'text': t(markTr('Envío')), 'style': 'titleMedium'}),
        _field(t(markTr('Dirección')), 'place'),
        _field(t(markTr('Ciudad')), 'location_city'),
        _n('Text', {'text': t(markTr('Tarjeta')), 'style': 'titleMedium'}),
        _field(
          t(markTr('Número de la tarjeta')),
          'credit_card',
          keyboard: 'number',
        ),
        _n(
          'Row',
          {'gap': 10},
          [
            _n('Expanded', {}, [
              _field('MM/AA', 'calendar_today', keyboard: 'number'),
            ]),
            _n('Expanded', {}, [
              _field('CVC', 'lock', keyboard: 'number', obscure: true),
            ]),
          ],
        ),
        _n(
          'Card',
          {'padding': 12},
          [
            _n(
              'Row',
              {'main': 'spaceBetween'},
              [
                _n('Text', {
                  'text': t(markTr('Total')),
                  'style': 'titleMedium',
                }),
                _n('Text', {
                  'text': '40,70 €',
                  'style': 'titleMedium',
                  'bold': true,
                }),
              ],
            ),
          ],
        ),
        _n('Button', {
          'text': t(markTr('Confirmar el pago')),
          'icon': 'lock',
          'onTap': _say('confirmar pago'),
        }),
      ]),
    ),
  ),
  FlTemplate(
    'success',
    markTr('Pedido confirmado'),
    markTr('Mensaje de éxito con el siguiente paso.'),
    'check_circle',
    (name, t) => FlScreen(
      name: name,
      appBar: false,
      body: _n('Center', {}, [
        _n(
          'Column',
          {'padding': 28, 'gap': 14, 'main': 'center', 'cross': 'center'},
          [
            _n('Icon', {
              'icon': 'check_circle',
              'size': 96,
              'color': 'primary',
            }),
            _n('Text', {
              'text': t(markTr('¡Listo!')),
              'style': 'headlineMedium',
              'bold': true,
            }),
            _n('Text', {
              'text': t(
                markTr(
                  'Su pedido PED-1024 está confirmado. Le avisaremos cuando salga.',
                ),
              ),
              'align': 'center',
            }),
            _n('Button', {
              'text': t(markTr('Ver el pedido')),
              'icon': 'receipt_long',
              'onTap': _say('ver pedido'),
            }),
            _n('Button', {
              'text': t(markTr('Volver al inicio')),
              'variant': 'text',
              'onTap': 'back',
            }),
          ],
        ),
      ]),
    ),
  ),
  FlTemplate(
    'dashboard',
    markTr('Panel'),
    markTr('Cifras clave y progreso.'),
    'insights',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Panel')),
      body: _n(
        'ListView',
        {'padding': 16},
        [
          _n(
            'Column',
            {'gap': 12},
            [
              _n(
                'Row',
                {'gap': 10},
                [
                  for (final (label, value, icon) in [
                    (t(markTr('Ventas')), '1.240 €', 'payments'),
                    (t(markTr('Pedidos')), '38', 'receipt_long'),
                  ])
                    _n('Expanded', {}, [
                      _n(
                        'Card',
                        {'padding': 14},
                        [
                          _n(
                            'Column',
                            {'cross': 'start', 'gap': 4},
                            [
                              _n('Icon', {'icon': icon, 'color': 'primary'}),
                              _n('Text', {
                                'text': value,
                                'style': 'headlineSmall',
                                'bold': true,
                              }),
                              _n('Text', {
                                'text': label,
                                'style': 'labelLarge',
                              }),
                            ],
                          ),
                        ],
                      ),
                    ]),
                ],
              ),
              _n(
                'Card',
                {'padding': 14},
                [
                  _n(
                    'Column',
                    {'cross': 'stretch', 'gap': 8},
                    [
                      _n('Text', {
                        'text': t(markTr('Objetivo del mes')),
                        'style': 'titleMedium',
                      }),
                      _n('Progress', {'value': 0.68}),
                      _n('Text', {
                        'text': t(markTr('68 % conseguido')),
                        'style': 'bodySmall',
                      }),
                    ],
                  ),
                ],
              ),
              _tile(
                t(markTr('Clientes nuevos')),
                t(markTr('Esta semana')),
                'group',
                trailing: '+12',
              ),
              _tile(
                t(markTr('Valoración media')),
                t(markTr('Últimos 30 días')),
                'star',
                trailing: '4,7',
              ),
            ],
          ),
        ],
      ),
    ),
  ),
  FlTemplate(
    'contact',
    markTr('Contacto'),
    markTr('Formulario para escribirnos.'),
    'mail',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Contacto')),
      body: _form([
        _n('Text', {
          'text': t(markTr('¿En qué podemos ayudarle?')),
          'style': 'titleMedium',
        }),
        _field(t(markTr('Nombre')), 'person'),
        _field(t(markTr('Correo')), 'email', keyboard: 'email'),
        _n('TextField', {
          'label': t(markTr('Mensaje')),
          'lines': 5,
          'keyboard': 'multiline',
        }),
        _n('Button', {
          'text': t(markTr('Enviar')),
          'icon': 'send',
          'onTap': '${_say('enviar mensaje')}; back',
        }),
        _tile(t(markTr('Teléfono')), '+34 900 000 000', 'call'),
      ]),
    ),
  ),
  FlTemplate(
    'help',
    markTr('Ayuda'),
    markTr('Preguntas frecuentes y contacto.'),
    'help',
    (name, t) => FlScreen(
      name: name,
      title: t(markTr('Ayuda')),
      body: _n(
        'ListView',
        {'padding': 12},
        [
          _n(
            'Column',
            {'gap': 10},
            [
              _n('TextField', {
                'hint': t(markTr('Buscar en la ayuda')),
                'icon': 'search',
              }),
              for (final (q, a) in [
                (
                  t(markTr('¿Cómo cambio mi contraseña?')),
                  t(markTr('En Perfil → Ajustes → Privacidad.')),
                ),
                (
                  t(markTr('¿Cuánto tarda un envío?')),
                  t(markTr('Entre 24 y 72 horas laborables.')),
                ),
                (
                  t(markTr('¿Puedo devolver un pedido?')),
                  t(markTr('Sí, durante 30 días desde la entrega.')),
                ),
              ])
                _n(
                  'Card',
                  {'padding': 12},
                  [
                    _n(
                      'Column',
                      {'cross': 'start', 'gap': 4},
                      [
                        _n('Text', {
                          'text': q,
                          'style': 'titleSmall',
                          'bold': true,
                        }),
                        _n('Text', {'text': a}),
                      ],
                    ),
                  ],
                ),
              _n('Button', {
                'text': t(markTr('Hablar con soporte')),
                'variant': 'tonal',
                'icon': 'chat',
                'onTap': _say('soporte'),
              }),
            ],
          ),
        ],
      ),
    ),
  ),
];
