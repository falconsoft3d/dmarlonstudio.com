"""Arma los cursos grandes de MiniLang con frases de Tatoeba (tatoeba.org, CC BY 2.0 FR).

    python3 build_course.py <carpeta con los .tsv de Tatoeba> <carpeta de salida> [palabras]

Hace falta, de https://downloads.tatoeba.org/exports/per_language/:
  eng/eng_sentences.tsv, spa/spa_sentences.tsv y eng/eng-spa_links.tsv (descomprimidos).

Sale un paquete por sentido: en-es-10k.json (inglés para quien habla español) y
es-en-10k.json (español para quien habla inglés), con el formato de los paquetes
de MiniLang. Cómo se ordena:
  1. Las palabras del idioma que se aprende, de la más usada a la menos, contadas
     en todas sus frases de Tatoeba. Los nombres propios (los que no se traducen,
     como Tom o Boston) no cuentan; «French» sí («francés»), y el «'s» del
     posesivo no hace otra palabra.
  2. Cada frase «se entiende» cuando se sabe su palabra más rara. Para cada
     palabra, en orden, se toman una o dos frases que ya se entienden con ella
     (las de 3 a 9 palabras primero): así cada frase solo usa palabras vistas
     más, como mucho, las que enseña.
  3. Cada unidad junta unas 25 palabras nuevas; el nivel (A1…C2) sale de
     cuántas palabras se llevan.
"""
import json
import re
import sys
from collections import Counter, defaultdict

TARGET_WORDS = int(sys.argv[3]) if len(sys.argv) > 3 else 10000
PER_UNIT = 25
# El nivel según las palabras que se llevan (aproximado, como los niveles del MCER).
LEVELS = [(600, 0), (1500, 1), (3000, 2), (5500, 3), (8000, 4), (10**9, 5)]
ICONS = ["📗", "📘", "📙", "📕", "📓", "📒"]
BAD = re.compile(r'[0-9"/|()\[\]{}<>_#@*=+~^\\]')
WORD = {
    "en": re.compile(r"[a-z]+(?:'[a-z]+)*"),
    "es": re.compile(r"[a-záéíóúüñ]+"),
}


def load(folder):
    global ALL_EN, ALL_ES

    def sentences(path):
        out = {}
        with open(path, encoding="utf-8") as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) == 3:
                    out[parts[0]] = parts[2].strip()
        return out

    en = sentences(f"{folder}/eng_sentences.tsv")
    es = sentences(f"{folder}/spa_sentences.tsv")
    ALL_EN, ALL_ES = list(en.values()), list(es.values())
    pairs = []
    with open(f"{folder}/eng-spa_links.tsv", encoding="utf-8") as f:
        for line in f:
            a, b = line.split()
            if a in en and b in es:
                pairs.append((en[a], es[b]))
    return pairs


def usable(s, lang):
    n = len(s.split())
    return 1 <= n <= (13 if lang == "en" else 14) and not BAD.search(s) and len(s) <= 90


SHORT_OK = {"en": {"a", "i"}, "es": {"a", "y", "o", "e", "u"}}


def tokens(s, lang):
    out = []
    for w in WORD[lang].findall(s.lower().replace("’", "'")):
        if w.endswith("'s"):
            w = w[:-2]
        if len(w) >= 2 or w in SHORT_OK[lang]:
            out.append(w)
    return out


def proper_names(pairs, target):
    """Los nombres: palabras con mayúscula que quedan igual en la traducción (Tom, Boston)."""
    cap, same = Counter(), Counter()
    for t, s in pairs:
        src = set(re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", s))
        for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", t):
            if w[0].isupper() and w != "I":
                cap[w.lower()] += 1
                if w in src:
                    same[w.lower()] += 1
    return {w for w in cap if same[w] / cap[w] >= 0.6}


def build(pairs, target, source):
    # Las frases del idioma que se aprende, con sus traducciones (y las otras formas que valen).
    tr = defaultdict(list)       # frase → traducciones
    back = defaultdict(list)     # traducción → frases (otras formas de decirlo)
    seen = {}
    for en, es in pairs:
        t, s = (en, es) if target == "en" else (es, en)
        if not usable(t, target) or not usable(s, source):
            continue
        key = t.lower()
        if key in seen:
            t = seen[key]
        else:
            seen[key] = t
        if s not in tr[t]:
            tr[t].append(s)
        if t not in back[s]:
            back[s].append(t)
    sents = list(tr)
    oriented = [(en, es) if target == "en" else (es, en) for en, es in pairs]
    names = proper_names(oriented, target)
    # Lo que se usa cada palabra: en todas las frases del idioma (millones en inglés).
    freq = Counter()
    for t in ALL_EN if target == "en" else ALL_ES:
        freq.update(w for w in tokens(t, target) if w not in names)
    vocab = {}
    for t in sents:
        ws = {w for w in tokens(t, target) if w not in names}
        if ws and all(w in freq for w in ws):
            vocab[t] = ws
    used_words = set().union(*vocab.values())
    freq = Counter({w: c for w, c in freq.items() if w in used_words})
    rank = {w: i for i, (w, _) in enumerate(sorted(freq.items(), key=lambda kv: (-kv[1], kv[0])))}
    # Cada frase, con su palabra más rara: se entiende al llegar a ella.
    by_rank = defaultdict(list)
    for t, ws in vocab.items():
        by_rank[max(rank[w] for w in ws)].append(t)

    def score(t):
        n = len(t.split())
        return (0 if 3 <= n <= 9 else 1, abs(n - 6), len(tr[t]) * -1, t)

    known, order, items = set(), [], []
    for r in range(len(rank)):
        cands = sorted(by_rank.get(r, []), key=score)
        if not cands:
            continue
        for t in cands[:2]:
            new = sorted(vocab[t] - known, key=lambda w: rank[w])
            for w in new:
                known.add(w)
                order.append(w)
            items.append((t, tr[t], new))
        if len(known) >= TARGET_WORDS:
            break
    # Las unidades: unas 25 palabras nuevas cada una.
    units, cur, cur_words = [], [], []
    for t, ss, new in items:
        cur.append((t, ss))
        cur_words += new
        if len(cur_words) >= PER_UNIT and len(cur) >= 8:
            units.append((cur, cur_words))
            cur, cur_words = [], []
    if cur:
        if len(cur) >= 3:
            units.append((cur, cur_words))
        elif units:
            units[-1][0].extend(cur)
            units[-1][1].extend(cur_words)
    out_units, total = [], 0
    for cur, ws in units:
        total += len(ws)
        section = next(s for lim, s in LEVELS if total <= lim)
        items_json = []
        for t, ss in cur:
            others = [x for s in ss[:1] for x in back[s] if x != t][:3]
            src = "/".join(dict.fromkeys(x.replace("/", " ") for x in ss[:3]))
            tgt = "/".join(dict.fromkeys([t] + others))
            items_json.append([src, tgt])
        lessons = max(2, (len(cur) + 6) // 7)
        out_units.append(
            {
                "section": section,
                "title": ", ".join(ws[:3]) + ("…" if len(ws) > 3 else ""),
                "icon": ICONS[section],
                "lessons": lessons,
                "words": ws,
                "items": items_json,
            }
        )
    return out_units, len(known), len(items)


def write(units, target, source, path, words):
    names = {
        ("en", "es"): ("Inglés · 10.000 palabras", "🇬🇧"),
        ("es", "en"): ("Spanish · 10,000 words", "🇪🇸"),
    }
    name, flag = names[(target, source)]
    head = {
        "minilang": 1,
        "id": f"{target}-{source}-10k",
        "target": target,
        "source": source,
        "name": name,
        "flag": flag,
        "full": True,
        "words": words,
        "credit": "Tatoeba (tatoeba.org), CC BY 2.0 FR",
    }
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(head, ensure_ascii=False)[:-1] + ',"units":[\n')
        f.write(",\n".join(json.dumps(u, ensure_ascii=False) for u in units))
        f.write("\n]}\n")


def main():
    pairs = load(sys.argv[1])
    out = sys.argv[2]
    for target, source in (("en", "es"), ("es", "en")):
        units, words, sentences = build(pairs, target, source)
        path = f"{out}/{target}-{source}-10k.json"
        write(units, target, source, path, words)
        levels = Counter(u["section"] for u in units)
        print(f"{path}: {words} palabras, {sentences} frases, {len(units)} unidades, niveles {dict(sorted(levels.items()))}")


if __name__ == "__main__":
    main()
