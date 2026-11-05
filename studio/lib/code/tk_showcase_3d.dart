part of 'tk_examples.dart';

// --------------------------------------------------------------- visor 3D
/// Visor 3D en un lienzo de tkinter, sin bibliotecas: mallas (cubo,
/// pirámide, esfera y toro), giro con el ratón, animación con un
/// temporizador, perspectiva, orden por profundidad y luz por cara.
TkExample _viewer3d(String Function(String) t) {
  final app = t(markTr('Visor 3D'));
  final shapes = [
    t(markTr('Cubo')),
    t(markTr('Pirámide')),
    t(markTr('Esfera')),
    t(markTr('Toro')),
  ];
  Map<String, Object?> radio(String text, String value, {bool on = false}) => {
    'text': text,
    'group': 'Mode',
    'value': value,
    'checked': on,
    'bg': _paper,
  };
  final design =
      TkDesign(
          width: 880,
          height: 560,
          props: {'title': app, 'bg': _paper, 'position': 'center'},
          events: {'create': 'form_create', 'close': 'form_close'},
        )
        ..widgets.addAll([
          _w('Label', 'Title', 16, 12, 600, 32, {..._title(app), 'bg': _paper}),
          _w(
            'Canvas',
            'View',
            16,
            52,
            600,
            464,
            {'bg': '#10141c'},
            {'click': 'View_mouse_down', 'drag': 'View_drag'},
          ),
          _w('Label', 'LblShape', 640, 56, 220, 24, {
            ..._label(t(markTr('Figura'))),
            'bg': _paper,
          }),
          _w(
            'Combobox',
            'Shape',
            640,
            82,
            220,
            28,
            {
              'items': shapes.join('\n'),
              'text': shapes[0],
              'state': 'readonly',
            },
            {'select': 'Shape_select'},
          ),
          _w('Label', 'LblMode', 640, 124, 220, 24, {
            ..._label(t(markTr('Dibujo'))),
            'bg': _paper,
          }),
          _w(
            'Radiobutton',
            'RadSolid',
            640,
            150,
            110,
            24,
            radio(t(markTr('Sólido')), 'solid', on: true),
            {'command': 'mode_change'},
          ),
          _w(
            'Radiobutton',
            'RadWire',
            750,
            150,
            110,
            24,
            radio(t(markTr('Alambre')), 'wire'),
            {'command': 'mode_change'},
          ),
          _w('Checkbutton', 'Spin', 640, 186, 220, 24, {
            'text': t(markTr('Girar solo')),
            'checked': true,
            'bg': _paper,
          }),
          _w(
            'Scale',
            'Zoom',
            640,
            220,
            220,
            64,
            {
              'label': t(markTr('Zoom (%)')),
              'from': 40,
              'to': 220,
              'value': 100,
              'orient': 'horizontal',
              'bg': _paper,
            },
            {'command': 'Zoom_change'},
          ),
          _w('Scale', 'Speed', 640, 292, 220, 64, {
            'label': t(markTr('Velocidad')),
            'from': 0,
            'to': 10,
            'value': 3,
            'orient': 'horizontal',
            'bg': _paper,
          }),
          _w(
            'Button',
            'BtnReset',
            640,
            372,
            220,
            32,
            {'text': t(markTr('Reiniciar la vista'))},
            {'command': 'BtnReset_click'},
          ),
          _w('Label', 'Help', 640, 420, 220, 96, {
            ..._label(
              t(
                markTr(
                  'Arrastre la figura con el ratón para girarla. Todo se dibuja con Python en un lienzo de tkinter: proyección en perspectiva, orden por profundidad y luz en cada cara.',
                ),
              ),
            ),
            'wraplength': 216,
            'bg': _paper,
          }),
          _w(
            'Timer',
            'Timer1',
            600,
            16,
            24,
            24,
            {'interval': 33},
            {'timer': 'Timer1_timer'},
          ),
          _w('StatusBar', 'Status', 0, 536, 880, 24, {
            'text': t(markTr('Listo')),
            'icon': 'info',
          }),
        ]);
  final code =
      '''import math
import time

SHAPES = [${shapes.map(_py).join(', ')}]
STATUS = ${_py(t(markTr('{0} · {1} caras · {2} fps')))}
BACKGROUND = "#10141c"
BASE = (91, 141, 239)  # Azul de la marca, iluminado en cada cara.
LIGHT = (0.4, -0.6, -0.7)


def normalize(v):
    n = math.sqrt(sum(c * c for c in v)) or 1.0
    return tuple(c / n for c in v)


def cube():
    v = [(x, y, z) for x in (-1, 1) for y in (-1, 1) for z in (-1, 1)]
    f = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    return v, f


def pyramid():
    v = [(-1, 1, -1), (1, 1, -1), (1, 1, 1), (-1, 1, 1), (0, -1.2, 0)]
    f = [(0, 1, 2, 3), (0, 4, 1), (1, 4, 2), (2, 4, 3), (3, 4, 0)]
    return v, f


def sphere(rings=12, segments=20):
    v = []
    for i in range(rings + 1):
        a = math.pi * i / rings
        for j in range(segments):
            b = 2 * math.pi * j / segments
            v.append((math.sin(a) * math.cos(b) * 1.3, math.cos(a) * 1.3, math.sin(a) * math.sin(b) * 1.3))
    f = []
    for i in range(rings):
        for j in range(segments):
            a = i * segments + j
            b = i * segments + (j + 1) % segments
            f.append((a, b, b + segments, a + segments))
    return v, f


def torus(rings=24, sides=12, big=1.0, small=0.42):
    v = []
    for i in range(rings):
        a = 2 * math.pi * i / rings
        for j in range(sides):
            b = 2 * math.pi * j / sides
            r = big + small * math.cos(b)
            v.append((r * math.cos(a), small * math.sin(b), r * math.sin(a)))
    f = []
    for i in range(rings):
        for j in range(sides):
            a = i * sides + j
            b = i * sides + (j + 1) % sides
            c = ((i + 1) % rings) * sides + (j + 1) % sides
            d = ((i + 1) % rings) * sides + j
            f.append((a, b, c, d))
    return v, f


MESHES = [cube, pyramid, sphere, torus]


class Form1(FormDesign):
    def form_create(self):
        self.mesh = MESHES[0]()
        self.ax, self.ay = -0.5, 0.6
        self.last = None
        self.frames, self.fps, self.clock = 0, 0, time.time()
        self.draw()

    # ------------------------------------------------------------- dibujo
    def project(self, points, w, h):
        """Gira los puntos y los proyecta en perspectiva: [(x, y, z)]."""
        ca, sa = math.cos(self.ax), math.sin(self.ax)
        cb, sb = math.cos(self.ay), math.sin(self.ay)
        scale = min(w, h) * 0.32 * float(self.Zoom_var.get()) / 100
        out = []
        for x, y, z in points:
            x, z = x * cb + z * sb, -x * sb + z * cb
            y, z = y * ca - z * sa, y * sa + z * ca
            d = 5.0 / (5.0 + z)
            out.append((w / 2 + x * scale * d, h / 2 + y * scale * d, z))
        return out

    def draw(self):
        c = self.View
        w, h = max(c.winfo_width(), 2), max(c.winfo_height(), 2)
        c.delete("all")
        vertices, faces = self.mesh
        p = self.project(vertices, w, h)
        solid = self.Mode_var.get() != "wire"
        light = normalize(LIGHT)
        shown = []
        for face in faces:
            pts = [p[i] for i in face]
            (x0, y0, z0), (x1, y1, z1), (x2, y2, z2) = pts[0], pts[1], pts[2]
            # Normal en pantalla: las caras de espaldas no se dibujan.
            nz = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0)
            if solid and nz <= 0:
                continue
            depth = sum(q[2] for q in pts) / len(pts)
            # Luz: el ángulo entre la cara y la luz.
            u = (x1 - x0, y1 - y0, z1 - z0)
            v = (x2 - x0, y2 - y0, z2 - z0)
            n = normalize((u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]))
            shade = 0.25 + 0.75 * max(0.0, -(n[0] * light[0] + n[1] * light[1] + n[2] * light[2]))
            shown.append((depth, pts, shade))
        # Pintor: lo más lejano primero.
        shown.sort(key=lambda s: -s[0])
        for depth, pts, shade in shown:
            flat = [k for q in pts for k in q[:2]]
            if solid:
                color = "#%02x%02x%02x" % tuple(int(min(255, c * shade)) for c in BASE)
                c.create_polygon(flat, fill=color, outline=color)
            else:
                c.create_polygon(flat, fill="", outline="#7aa2f7")
        self.frames += 1
        now = time.time()
        if now - self.clock >= 1:
            self.fps = round(self.frames / (now - self.clock))
            self.frames, self.clock = 0, now
        self.Status.set(STATUS.format(self.Shape_var.get(), len(shown), self.fps))

    # ------------------------------------------------------------ eventos
    def Timer1_timer(self):
        if self.Spin_var.get():
            speed = float(self.Speed_var.get()) / 100
            self.ay += speed
            self.ax += speed / 3
        self.draw()

    def View_mouse_down(self, event=None):
        self.last = (event.x, event.y)

    def View_drag(self, event=None):
        if self.last is not None:
            self.ay += (event.x - self.last[0]) / 120
            self.ax += (event.y - self.last[1]) / 120
        self.last = (event.x, event.y)
        self.draw()

    def Shape_select(self, event=None):
        name = self.Shape_var.get()
        self.mesh = MESHES[SHAPES.index(name) if name in SHAPES else 0]()
        self.draw()

    def mode_change(self):
        self.draw()

    def Zoom_change(self, value=None):
        self.draw()

    def BtnReset_click(self):
        self.ax, self.ay = -0.5, 0.6
        self.Zoom_var.set(100)
        self.draw()

    def form_close(self, *args):
        self.root.destroy()
''';
  return TkExample(
    'viewer_3d',
    app,
    t(
      markTr(
        'Figuras en 3D dibujadas con Python en un lienzo: cubo, pirámide, esfera y toro, giro con el ratón, animación, luz y modo alambre.',
      ),
    ),
    design,
    code,
  );
}
