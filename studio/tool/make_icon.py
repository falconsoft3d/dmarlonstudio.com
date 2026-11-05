#!/usr/bin/env python3
"""Genera los iconos de DMarlon Studio a partir de la misma geometría que
assets/icon/icon.svg (el maestro): una «D» blanca seleccionada en el
diseñador (caja de selección con tiradores) sobre un cuadrado redondeado
azul de la marca.

Uso (desde la raíz del repositorio):  python3 studio/tool/make_icon.py
Solo necesita Pillow.
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
STUDIO = ROOT / "studio"
LANDING = ROOT / "landing"

# Colores de la marca: del azul #2B5FD9 a un índigo profundo.
TOP_LEFT = (72, 126, 255)
MID = (43, 95, 217)
BOTTOM_RIGHT = (52, 36, 158)
WHITE = (255, 255, 255)

SS = 4  # supermuestreo para bordes suaves


def gradient(size):
    """Degradado diagonal (arriba-izquierda → abajo-derecha) en tres paradas."""
    small = 256
    g = Image.new("RGB", (small, small))
    px = g.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1))
            if t < 0.5:
                a, b, k = TOP_LEFT, MID, t / 0.5
            else:
                a, b, k = MID, BOTTOM_RIGHT, (t - 0.5) / 0.5
            px[x, y] = tuple(round(a[i] + (b[i] - a[i]) * k) for i in range(3))
    return g.resize((size, size), Image.BICUBIC)


def d_mask(size, x0, y0, x1, y1):
    """Máscara de una «D» maciza: lado recto a la izquierda y media
    circunferencia a la derecha, dentro de la caja (x0, y0, x1, y1)."""
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    r = (y1 - y0) / 2
    cx = x1 - r
    d.rectangle((x0, y0, cx, y1), fill=255)
    # Solo la mitad derecha del círculo: la izquierda asomaría por el lado
    # recto, que es más estrecho que el radio.
    d.pieslice((cx - r, y0, cx + r, y1), start=-90, end=90, fill=255)
    return m


def render(px, *, margin, shadow, detail, handles=True):
    """Icono de px × px. [margin]: fracción de margen alrededor del cuadrado
    (la rejilla de macOS deja ~10 %). [detail]: dibuja la línea discontinua
    de la selección (solo en tamaños grandes)."""
    S = px * SS
    u = S / 1024  # unidades del maestro (1024)

    def k(v):
        return v * u

    # Cuerpo: cuadrado redondeado.
    inset = k(1024 * margin)
    body = (inset, inset, S - inset, S - inset)
    side = body[2] - body[0]
    radius = side * 0.225
    body_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body_mask).rounded_rectangle(body, radius=radius, fill=255)

    out = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    if shadow:
        sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        sm = body_mask.filter(ImageFilter.GaussianBlur(k(18)))
        sm = ImageChops.offset(sm, 0, round(k(14)))
        sh.putalpha(sm.point(lambda a: a * 0.38))
        out = Image.alpha_composite(out, sh)

    bg = gradient(S).convert("RGBA")
    bg.putalpha(body_mask)
    out = Image.alpha_composite(out, bg)

    # Brillo suave en la mitad superior.
    hl = Image.new("L", (S, S), 0)
    ImageDraw.Draw(hl).ellipse(
        (body[0] - side * 0.25, body[1] - side * 0.9, body[2] + side * 0.25, body[1] + side * 0.45),
        fill=255,
    )
    hl = ImageChops.multiply(hl.filter(ImageFilter.GaussianBlur(k(40))), body_mask)
    white = Image.new("RGBA", (S, S), WHITE + (0,))
    white.putalpha(hl.point(lambda a: a * 0.10))
    out = Image.alpha_composite(out, white)

    # Escala del contenido: el maestro se dibuja sobre el cuerpo de 824 px
    # (margen 100); con otro margen se reescala al cuerpo real.
    s = side / k(824)

    def P(v, axis_offset=100):
        return body[0] + (k(v) - k(axis_offset)) * s

    def Q(v):
        return body[1] + (k(v) - k(100)) * s

    # «D» con trazo: maciza menos su interior. Sin tiradores (16 px) la
    # letra ocupa el sitio de la selección.
    x0, y0, x1, y1 = (302, 300, 722, 724) if handles else (272, 250, 772, 774)
    stroke = 88 if detail else (100 if handles else 128)
    outer = d_mask(S, P(x0), Q(y0), P(x1), Q(y1))
    inner = d_mask(S, P(x0 + stroke), Q(y0 + stroke), P(x1 - stroke), Q(y1 - stroke))
    dm = ImageChops.subtract(outer, inner)
    glyph = Image.new("RGBA", (S, S), WHITE + (255,))
    glyph.putalpha(dm)
    out = Image.alpha_composite(out, glyph)

    # Selección del diseñador: caja discontinua y tiradores en las esquinas.
    bx0, by0, bx1, by1 = 252, 250, 772, 774
    ov = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(ov)
    if detail:
        dash, gap, w = k(34) * s, k(22) * s, max(1, round(k(10) * s))
        col = WHITE + (150,)
        for (ax, ay, bx_, by_) in [
            (bx0, by0, bx1, by0),
            (bx0, by1, bx1, by1),
            (bx0, by0, bx0, by1),
            (bx1, by0, bx1, by1),
        ]:
            X0, Y0, X1, Y1 = P(ax), Q(ay), P(bx_), Q(by_)
            length = max(X1 - X0, Y1 - Y0)
            t = dash  # el tramo junto al tirador ya lo tapa el tirador
            while t < length - dash:
                e = min(t + dash, length - dash)
                if X1 > X0:
                    d.line((X0 + t, Y0, X0 + e, Y0), fill=col, width=w)
                else:
                    d.line((X0, Y0 + t, X0, Y0 + e), fill=col, width=w)
                t = e + gap
    h = (60 if detail else 92) / 2
    for cx, cy in [(bx0, by0), (bx1, by0), (bx0, by1), (bx1, by1)] if handles else []:
        X, Y = P(cx), Q(cy)
        r = k(h) * s
        d.rounded_rectangle((X - r, Y - r, X + r, Y + r), radius=r * 0.22, fill=WHITE + (255,))
        if detail:
            ri = r * 0.5
            d.rounded_rectangle(
                (X - ri, Y - ri, X + ri, Y + ri), radius=ri * 0.2, fill=MID + (255,)
            )
    out = Image.alpha_composite(out, ov)

    return out.resize((px, px), Image.LANCZOS)


def main():
    icon_dir = STUDIO / "assets" / "icon"
    icon_dir.mkdir(parents=True, exist_ok=True)

    # macOS: rejilla de Apple (margen ~10 %) y sombra.
    mac = STUDIO / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for size in (16, 32, 64, 128, 256, 512, 1024):
        render(
            size,
            margin=100 / 1024,
            shadow=size >= 64,
            detail=size >= 128,
            handles=size > 16,
        ).save(
            mac / f"app_icon_{size}.png"
        )

    # Plano (sin margen de macOS): Windows, Linux, la web y la barra lateral.
    def flat(size):
        return render(
            size, margin=0.03, shadow=False, detail=size >= 128, handles=size > 16
        )

    flat(1024).save(icon_dir / "icon_1024.png")
    flat(256).save(icon_dir / "icon_256.png")
    flat(64).save(icon_dir / "icon_64.png")

    sizes = [16, 24, 32, 48, 64, 128, 256]
    flat(256).save(
        STUDIO / "windows" / "runner" / "resources" / "app_icon.ico",
        sizes=[(s, s) for s in sizes],
        append_images=[flat(s) for s in sizes[:-1]],
    )

    (LANDING / "app").mkdir(parents=True, exist_ok=True)
    flat(512).save(LANDING / "app" / "icon.png")
    # Apple recorta sus propias esquinas: a sangre, sin transparencia y con
    # los tiradores lejos de las esquinas.
    full = render(180, margin=0.0, shadow=False, detail=True)
    bg = Image.new("RGB", (180, 180), MID)
    bg.paste(full, mask=full.split()[3])
    bg.save(LANDING / "app" / "apple-icon.png")
    print("Iconos generados.")


if __name__ == "__main__":
    main()
