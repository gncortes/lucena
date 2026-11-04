import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations_pt.dart';

/// No PT-BR o 0 cai na regra `one` do plural (CLDR: i = 0,1). Sem `=0`, um
/// plural com `=1{1 partida}` ou `one{...}` mostra o singular para zero.
/// Todo plural do `app_pt.arb` com `=1`/`one` precisa do `=0`
/// (`tools/plural_zero_pt.py` corrige).
void main() {
  test('todo plural do PT-BR tem o caso =0', () {
    final arb = jsonDecode(
      File('lib/l10n/app_pt.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final semZero = <String>[];
    arb.forEach((chave, valor) {
      if (chave.startsWith('@') || valor is! String) return;
      for (final seletores in _plurais(valor)) {
        final temSingular =
            seletores.contains('=1') || seletores.contains('one');
        if (temSingular && !seletores.contains('=0')) semZero.add(chave);
      }
    });
    expect(semZero, isEmpty, reason: 'plurais sem =0: $semZero');
  });

  test('o zero sai no plural', () {
    final pt = AppLocalizationsPt();
    expect(pt.levelGamesCount(0), '0 partidas');
    expect(pt.levelGamesCount(1), '1 partida');
  });
}

/// Os seletores de cada plural da mensagem.
Iterable<Set<String>> _plurais(String mensagem) sync* {
  var i = 0;
  while (true) {
    final achou = mensagem.indexOf(', plural,', i);
    if (achou < 0) return;
    final abre = mensagem.lastIndexOf('{', achou);
    final fim = _fecha(mensagem, abre);
    final corpo = mensagem.substring(achou + ', plural,'.length, fim);
    final seletores = <String>{};
    var j = 0;
    while (j < corpo.length) {
      final chave = corpo.indexOf('{', j);
      if (chave < 0) break;
      seletores.add(corpo.substring(j, chave).trim());
      j = _fecha(corpo, chave) + 1;
    }
    yield seletores;
    i = fim + 1;
  }
}

int _fecha(String texto, int abre) {
  var nivel = 0;
  for (var i = abre; i < texto.length; i++) {
    if (texto[i] == '{') nivel++;
    if (texto[i] == '}' && --nivel == 0) return i;
  }
  throw StateError('chave sem fechamento: $texto');
}
