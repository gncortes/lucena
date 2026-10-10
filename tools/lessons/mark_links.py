#!/usr/bin/env python3
"""Marca como link (`{{texto|chave}}`) toda menção não marcada de nomes que já têm chave.

Os apelidos (texto -> chave) vêm das marcações que já existem nas aulas do mesmo idioma,
mais os sobrenomes derivados dos nomes completos de pessoas. Apelido que aponta para mais
de uma chave, ou que também é palavra comum/nome de posição, NÃO é marcado: sai no relatório.

Não mexe em `title`, `summary`, `part.*` e `lesson.*` (saem sem link).

Uso:
  python3 tools/lessons/mark_links.py --check            # só lista o que marcaria
  python3 tools/lessons/mark_links.py                    # grava em todas as aulas
  python3 tools/lessons/mark_links.py --lang pt assets/lessons/pt/endgames/rook.lucena.json
"""
import argparse
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LESSONS = os.path.join(ROOT, 'assets', 'lessons')
MARK = re.compile(r'\{\{([^|}]*)\|([^}]*)\}\}')
PROTECTED = re.compile(r'\{\{.*?\}\}|https?://\S+')

# Chaves que não são pessoas (não geram sobrenome derivado).
NOT_PERSON = {
    'aleppo', 'amsterdam', 'altensteig', 'berlin', 'british-championship', 'buenos-aires',
    'bundesliga', 'candidates', 'cannes', 'daugavpils', 'denver', 'fide-world-cup', 'geneva',
    'glasgow', 'grand-swiss', 'groningen', 'hamburg', 'horgen', 'hove', 'huaian', 'interzonal',
    'karlsbad', 'katowice', 'khanty-mansiysk', 'las-tunas', 'leon', 'linares', 'london',
    'lugano', 'malinska', 'melody-amber', 'mexico-city', 'monte-carlo', 'moscow',
    'mtel-masters', 'new-delhi', 'nice', 'niksic', 'norway-chess', 'norwich',
    'olympiad-hague-1928', 'pamplona', 'philadelphia', 'portoroz', 'prague', 'reykjavik',
    'rethymnon', 'riga', 'saint-louis', 'saint-petersburg', 'sinquefield-cup', 'skelleftea',
    'sofia', 'soviet-championship', 'stavanger', 'tal-memorial', 'tbilisi', 'tilburg',
    'vancouver', 'world-blitz', 'world-junior', 'womens-grand-prix', 'yerevan', 'zagan',
    'zurich',
}
# Pedaços de nome que não valem como sobrenome sozinho.
NO_SURNAME = {'Liem', 'Minh', 'Liren', 'Quang', 'Tuan', 'Chess'}
# Sobrenomes a mais, à mão (variantes sem acento etc.).
EXTRA = {
    'Polgar': 'judit-polgar',
    'Nimzowitsch': 'aron-nimzowitsch',
    'Praggnanandhaa': 'praggnanandhaa',
}
# Ambíguos ou palavras comuns/nomes de posição: nunca marcar sozinhos.
SKIP = {
    'Lasker': 'Emanuel ou Edward',
    'Philidor': 'posição de Philidor x François-André Philidor',
    'Lucena': 'posição de Lucena, não pessoa',
    'Tal': 'Mikhail Tal x Tal Shaked / palavra "tal" no começo de frase',
    'So': 'Wesley So x "so"/"So" em inglês',
    'Nice': 'cidade x palavra inglesa',
    'Fine': 'Reuben Fine x palavra inglesa',
    'Berlin': 'cidade x Defesa Berlim',
    'Marshall': 'Frank Marshall x clube/ataque Marshall',
    'Leon': 'cidade x nome próprio',
    'Hove': 'cidade x palavra',
    'Amber': 'torneio x palavra',
}


def is_text_key(k):
    return not (k in ('title', 'summary') or k.startswith('part.') or k.startswith('lesson.'))


def load(path):
    with open(path, encoding='utf8') as f:
        s = f.read()
    return s, json.loads(s)


def build_table(lang):
    found = collections.defaultdict(set)  # alias -> chaves
    full = {}  # chave -> aliases de 2+ palavras
    for p in glob.glob(os.path.join(LESSONS, lang, 'endgames', '*.json')):
        _, d = load(p)
        for v in d.values():
            for m in MARK.finditer(v):
                found[m.group(1)].add(m.group(2))
    for a, ks in list(found.items()):
        for k in ks:
            if k not in NOT_PERSON and ' ' in a:
                parts = a.split()
                if len(parts) >= 2 and a.split()[-1] not in NO_SURNAME:
                    found[parts[-1]].add(k)
    for a, k in EXTRA.items():
        found[a].add(k)
    table, ambiguous = {}, {}
    for a, ks in found.items():
        if a in SKIP:
            ambiguous[a] = SKIP[a]
        elif len(ks) > 1:
            ambiguous[a] = ' x '.join(sorted(ks))
        else:
            table[a] = next(iter(ks))
    for a, why in SKIP.items():
        if a not in ambiguous and a in {'Lucena', 'Philidor'}:
            ambiguous[a] = why
    return table, ambiguous


def make_regex(table):
    alts = sorted(table, key=len, reverse=True)
    pat = '|'.join(re.escape(a) for a in alts)
    return re.compile(r'(?<!\w)(?:' + pat + r')(?!\w)')


def mark_text(text, table, rx):
    out, last, n, hits = [], 0, 0, []
    # divide em trechos protegidos (marcações, URLs) e livres
    for m in PROTECTED.finditer(text):
        free = text[last:m.start()]
        out.append(rx.sub(lambda g: (hits.append(g.group(0)), '{{%s|%s}}' % (g.group(0), table[g.group(0)]))[1], free))
        out.append(m.group(0))
        last = m.end()
    free = text[last:]
    out.append(rx.sub(lambda g: (hits.append(g.group(0)), '{{%s|%s}}' % (g.group(0), table[g.group(0)]))[1], free))
    return ''.join(out), hits


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='só lista o que marcaria')
    ap.add_argument('--lang', choices=['pt', 'en'], help='só este idioma')
    ap.add_argument('files', nargs='*', help='arquivos (padrão: todas as aulas)')
    a = ap.parse_args()
    total = 0
    amb_seen = collections.Counter()
    for lang in ([a.lang] if a.lang else ['pt', 'en']):
        table, ambiguous = build_table(lang)
        rx = make_regex(table)
        amb_rx = re.compile(r'(?<!\w)(?:%s)(?!\w)' % '|'.join(re.escape(x) for x in sorted(ambiguous, key=len, reverse=True)))
        paths = [os.path.abspath(f) for f in a.files if '/%s/' % lang in os.path.abspath(f)] if a.files \
            else sorted(glob.glob(os.path.join(LESSONS, lang, 'endgames', '*.json')))
        for p in paths:
            s, d = load(p)
            changed = False
            for k, v in d.items():
                if not isinstance(v, str) or not is_text_key(k):
                    continue
                for m in amb_rx.finditer(PROTECTED.sub(lambda g: ' ' * len(g.group(0)), v)):
                    amb_seen[(lang, m.group(0))] += 1
                new, hits = mark_text(v, table, rx)
                if hits:
                    total += len(hits)
                    changed = True
                    d[k] = new
                    for h in hits:
                        print('%s %s [%s] %s' % (lang, os.path.basename(p), k, h))
            if changed and not a.check:
                nl = '\n' if s.endswith('\n') else ''
                with open(p, 'w', encoding='utf8') as f:
                    f.write(json.dumps(d, ensure_ascii=False, indent=2) + nl)
    print('\n%s: %d marcações' % ('a marcar' if a.check else 'novas', total), file=sys.stderr)
    print('Ambíguos/pulados (ocorrências não marcadas):', file=sys.stderr)
    for (lang, w), c in sorted(amb_seen.items()):
        print('  %s %s x%d' % (lang, w, c), file=sys.stderr)


if __name__ == '__main__':
    main()
