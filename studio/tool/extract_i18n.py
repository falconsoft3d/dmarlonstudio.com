#!/usr/bin/env python3
"""Catálogos de traducción (gettext) de DMarlon Studio a partir del código.

  python3 tool/extract_i18n.py            regenera assets/i18n/dmarlonstudio.pot
                                          y pone al día cada <idioma>.po: añade
                                          los textos nuevos (con la traducción
                                          de ERPSqlite si existe) y quita los
                                          que ya no se usan.
  python3 tool/extract_i18n.py --check    no escribe nada; falla si un .po no
                                          está al día o le faltan traducciones.
  python3 tool/extract_i18n.py --missing  lista los textos sin traducir.

Los textos se toman de tr('…'), markTr('…'), trc('ctx', '…') y
markTrc('ctx', '…') de lib/ (salvo lib/i18n/). Se ejecuta desde studio/.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
I18N = os.path.join(ROOT, 'assets', 'i18n')
POT = os.path.join(I18N, 'dmarlonstudio.pot')
# Traducciones que ya existen en ERPSqlite (el estudio sale de su app Código).
ERP_PO = os.path.expanduser(
    '~/Documents/odoo/erp-sqlite/assets/i18n/{lang}.po')

CALL = re.compile(r'(?<![\w$.])(tr|markTr|trc|markTrc)\(')


def skip_space(s, i):
    while i < len(s):
        if s.startswith('//', i):
            j = s.find('\n', i)
            if j < 0:
                return len(s)
            i = j
        elif s.startswith('/*', i):
            i = s.find('*/', i) + 2
        elif s[i] in ' \n\r\t':
            i += 1
        else:
            break
    return i


def literal(s, i):
    """Literal (o literales adyacentes) en i: (texto, fin) o None."""
    out = []
    found = False
    while True:
        i = skip_space(s, i)
        raw = False
        if i + 1 < len(s) and s[i] == 'r' and s[i + 1] in '\'"':
            raw = True
            i += 1
        if i >= len(s) or s[i] not in '\'"':
            break
        q = s[i:i + 3] if s.startswith("'''", i) or s.startswith('"""', i) \
            else s[i]
        i += len(q)
        while True:
            if i >= len(s):
                return None
            if s.startswith(q, i):
                i += len(q)
                break
            c = s[i]
            if c == '$' and not raw:
                return None  # interpolación
            if c == '\\' and not raw:
                n = s[i + 1]
                if n == 'n':
                    out.append('\n')
                elif n == 't':
                    out.append('\t')
                elif n == 'r':
                    out.append('\r')
                elif n == 'u':
                    if s[i + 2] == '{':
                        end = s.index('}', i)
                        out.append(chr(int(s[i + 3:end], 16)))
                        i = end + 1
                        continue
                    out.append(chr(int(s[i + 2:i + 6], 16)))
                    i += 6
                    continue
                else:
                    out.append(n)
                i += 2
                continue
            out.append(c)
            i += 1
        found = True
    return (''.join(out), i) if found else None


def extract():
    """{(ctx, msgid): [refs]} en orden de aparición."""
    msgs = {}
    lib = os.path.join(ROOT, 'lib')
    for d, _, files in sorted(os.walk(lib)):
        rel_dir = os.path.relpath(d, ROOT)
        if rel_dir.replace('\\', '/').startswith('lib/i18n'):
            continue
        for f in sorted(files):
            if not f.endswith('.dart'):
                continue
            path = os.path.join(d, f)
            rel = os.path.relpath(path, ROOT).replace('\\', '/')
            src = open(path, encoding='utf-8').read()
            for m in CALL.finditer(src):
                ctx = None
                at = m.end()
                if m.group(1) in ('trc', 'markTrc'):
                    c = literal(src, at)
                    if c is None:
                        continue
                    at = skip_space(src, c[1])
                    if at >= len(src) or src[at] != ',':
                        continue
                    ctx = c[0]
                    at += 1
                lit = literal(src, at)
                if lit is None:
                    continue
                nxt = skip_space(src, lit[1])
                if nxt >= len(src) or src[nxt] not in ',)':
                    continue
                line = src.count('\n', 0, m.start()) + 1
                msgs.setdefault((ctx, lit[0]), []).append(f'{rel}:{line}')
    return msgs


# ------------------------------------------------------------------- .po
def unescape(s):
    out = []
    i = 0
    while i < len(s):
        c = s[i]
        if c != '\\' or i + 1 >= len(s):
            out.append(c)
            i += 1
            continue
        n = s[i + 1]
        out.append({'n': '\n', 't': '\t', 'r': '\r'}.get(n, n))
        i += 2
    return ''.join(out)


def escape(s):
    return (s.replace('\\', '\\\\').replace('"', '\\"')
            .replace('\t', '\\t').replace('\r', '\\r'))


def parse_po(text):
    """{(ctx, msgid): (msgstr, fuzzy)}"""
    out = {}
    field = None
    ctx = msgid = msgstr = None
    fuzzy = False
    has = False

    def flush():
        nonlocal ctx, msgid, msgstr, fuzzy, has, field
        if has and msgid:
            out[(ctx, msgid)] = (msgstr or '', fuzzy)
        ctx = msgid = msgstr = None
        fuzzy = False
        has = False
        field = None

    def quoted(l):
        a, z = l.find('"'), l.rfind('"')
        return '' if a < 0 or z <= a else unescape(l[a + 1:z])

    for raw in text.split('\n'):
        l = raw.strip()
        if not l:
            continue
        if l.startswith('#,'):
            if has:
                flush()
            fuzzy = 'fuzzy' in l
        elif l.startswith('#'):
            if has:
                flush()
        elif l.startswith('msgctxt'):
            if has:
                flush()
            field = 'ctx'
            ctx = quoted(l)
        elif l.startswith('msgid_plural'):
            field = 'plural'
        elif l.startswith('msgid'):
            if has:
                flush()
            has = True
            field = 'id'
            msgid = quoted(l)
        elif l.startswith('msgstr'):
            if not l.startswith('msgstr[') or l.startswith('msgstr[0]'):
                field = 'str'
                msgstr = quoted(l)
            else:
                field = 'skip'
        elif l.startswith('"'):
            if field == 'ctx':
                ctx += quoted(l)
            elif field == 'id':
                msgid += quoted(l)
            elif field == 'str':
                msgstr += quoted(l)
    flush()
    return out


def block(key, v):
    if '\n' not in v:
        return f'{key} "{escape(v)}"\n'
    lines = v.split('\n')
    b = [f'{key} ""\n']
    for i, l in enumerate(lines):
        last = i == len(lines) - 1
        if last and not l:
            break
        b.append(f'"{escape(l)}{"" if last else chr(92) + "n"}"\n')
    return ''.join(b)


def write_po(entries, language):
    """entries: [(ctx, msgid, msgstr, fuzzy, refs)]"""
    b = [
        '# Traducción de DMarlon Studio.\n',
        '# Edite este archivo con Poedit o cualquier editor de texto y\n',
        '# ejecute «python3 tool/extract_i18n.py» tras cambiar textos del código.\n',
        'msgid ""\n',
        'msgstr ""\n',
        '"Project-Id-Version: DMarlon Studio\\n"\n',
        f'"Language: {language}\\n"\n',
        '"MIME-Version: 1.0\\n"\n',
        '"Content-Type: text/plain; charset=UTF-8\\n"\n',
        '"Content-Transfer-Encoding: 8bit\\n"\n',
    ]
    for ctx, msgid, msgstr, fuzzy, refs in entries:
        b.append('\n')
        if refs:
            b.append(f'#: {" ".join(refs)}\n')
        if fuzzy:
            b.append('#, fuzzy\n')
        if ctx is not None:
            b.append(block('msgctxt', ctx))
        b.append(block('msgid', msgid))
        b.append(block('msgstr', msgstr))
    return ''.join(b)


def main(args):
    check = '--check' in args
    missing_only = '--missing' in args
    msgs = extract()
    ids = sorted(msgs, key=lambda k: (msgs[k][0], k[1]))
    failed = False

    pot = write_po([(c, m, '', False, msgs[(c, m)]) for c, m in ids], '')
    old_pot = open(POT, encoding='utf-8').read() if os.path.exists(POT) else None
    if check:
        if old_pot != pot:
            print('dmarlonstudio.pot no está al día: ejecute '
                  'python3 tool/extract_i18n.py', file=sys.stderr)
            failed = True
    elif not missing_only:
        os.makedirs(I18N, exist_ok=True)
        open(POT, 'w', encoding='utf-8').write(pot)

    for f in sorted(os.listdir(I18N)):
        if not f.endswith('.po'):
            continue
        lang = f[:-3]
        path = os.path.join(I18N, f)
        old = parse_po(open(path, encoding='utf-8').read())
        erp_path = ERP_PO.format(lang=lang)
        erp = parse_po(open(erp_path, encoding='utf-8').read()) \
            if os.path.exists(erp_path) else {}
        entries = []
        reused = 0
        for c, m in ids:
            msgstr, fuzzy = old.get((c, m), ('', False))
            if not msgstr and (c, m) in erp and not erp[(c, m)][1]:
                msgstr = erp[(c, m)][0]
                if msgstr:
                    reused += 1
            entries.append((c, m, msgstr, fuzzy, msgs[(c, m)]))
        missing = [e for e in entries if not e[2] or e[3]]
        obsolete = len([k for k in old if k not in msgs])
        if missing_only:
            for e in missing:
                print(repr(e[1]) if e[0] is None else repr((e[0], e[1])))
            continue
        print(f'{lang}.po: {len(entries)} textos, '
              f'{len(entries) - len(missing)} traducidos '
              f'({reused} nuevos tomados de ERPSqlite), '
              f'{len(missing)} pendientes, {obsolete} obsoletos')
        text = write_po(entries, lang)
        if check:
            if open(path, encoding='utf-8').read() != text:
                print(f'{lang}.po no está al día: ejecute '
                      'python3 tool/extract_i18n.py', file=sys.stderr)
                failed = True
            if missing:
                failed = True
        else:
            open(path, 'w', encoding='utf-8').write(text)
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main(sys.argv[1:])
