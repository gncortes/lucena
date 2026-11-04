import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H-LIC-16: o aluno lê "lição", nunca "aula", e "salvo", nunca "guardado".
/// Nomes de chave e placeholders (`{aula}`) podem manter o termo interno.
void main() {
  final values =
      (jsonDecode(File('lib/l10n/app_pt.arb').readAsStringSync())
              as Map<String, dynamic>)
          .entries
          .where((e) => !e.key.startsWith('@') && e.value is String)
          .map((e) => MapEntry(e.key, _semPlaceholders(e.value as String)));

  test('nenhum valor do app_pt.arb diz "aula"', () {
    final hits = [
      for (final e in values)
        if (RegExp(r'\b[Aa]ulas?\b').hasMatch(e.value)) e.key,
    ];
    expect(hits, isEmpty);
  });

  test('nenhum valor do app_pt.arb diz "guardado"', () {
    final hits = [
      for (final e in values)
        if (RegExp('[Gg]uardad').hasMatch(e.value)) e.key,
    ];
    expect(hits, isEmpty);
  });

  test('nenhum erro do app_pt.arb cita motor, Stockfish ou computador', () {
    final hits = [
      for (final e in values)
        if (RegExp('[Ee]rror|[Ff]ail').hasMatch(e.key) &&
            RegExp(r'\bmotor\b|Stockfish|computador').hasMatch(e.value))
          e.key,
    ];
    expect(hits, isEmpty);
  });
}

/// Tira só os nomes de placeholder (`{aula}`, `{n, plural, …`), mantendo o
/// texto dos ramos do plural.
String _semPlaceholders(String s) =>
    s.replaceAll(RegExp(r'\{\w+(,\s*\w+,)?'), '{');
