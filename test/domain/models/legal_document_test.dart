import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/legal_document.dart';

void main() {
  test('lê seções, itens, negrito e a tabela', () {
    final doc = LegalDocument.parse('''
# TÍTULO

Versão 1, em vigor desde [DATA].

## 1. Primeira
Texto com **negrito** no meio.
- **Item:** um.

| Dado | Para quê |
|---|---|
| Nome | Conta |

## 2. Segunda
Fim.
''');

    expect(doc.intro, hasLength(1));
    expect(doc.sections.map((s) => s.title), ['1. Primeira', '2. Segunda']);
    final first = doc.sections.first.blocks;
    expect((first[0] as LegalParagraph).spans, [
      (text: 'Texto com ', bold: false),
      (text: 'negrito', bold: true),
      (text: ' no meio.', bold: false),
    ]);
    expect((first[1] as LegalBullet).spans.first, (text: 'Item:', bold: true));
    final table = first[2] as LegalTable;
    expect(table.header, ['Dado', 'Para quê']);
    expect(table.rows, [
      ['Nome', 'Conta'],
    ]);
  });

  test('os textos embarcados: 16 seções nos Termos e 13 na Política', () {
    final terms = LegalDocument.parse(
      File('assets/legal/termos_pt.md').readAsStringSync(),
    );
    final privacy = LegalDocument.parse(
      File('assets/legal/privacidade_pt.md').readAsStringSync(),
    );
    expect(terms.sections, hasLength(16));
    expect(privacy.sections, hasLength(13));
    expect(
      privacy.sections[1].blocks.whereType<LegalTable>().single.rows,
      hasLength(9),
    );
  });
}
