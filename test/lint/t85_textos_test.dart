import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T85-D0 (H-LIC-16 e erro padrão): o texto em PT-BR diz "lição", nunca
/// "aula"; "salvo", nunca "guardado"; e erro nunca expõe a peça técnica: usa
/// "Ocorreu um erro inesperado".
void main() {
  final pt = jsonDecode(
    File('lib/l10n/app_pt.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  final values = {
    for (final e in pt.entries)
      if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
  };

  List<String> offending(RegExp pattern) => [
    for (final e in values.entries)
      // Placeholder (`{aula}`) é nome de variável, não texto.
      if (pattern.hasMatch(e.value.replaceAll(RegExp(r'\{\w+\}'), '')))
        '${e.key}: ${e.value}',
  ];

  test('nenhum texto em PT-BR diz "aula"', () {
    final found = offending(RegExp(r'\b[Aa]ulas?\b'));
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('nenhum texto em PT-BR diz "guardado"', () {
    final found = offending(RegExp(r'\b[Gg]uardad[oa]s?\b'));
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('erro não fala em termo técnico', () {
    final found = offending(
      RegExp(
        r'Erro ao |resposta do motor|computador não respondeu|'
        r'motor não|Stockfish não',
        caseSensitive: false,
      ),
    );
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('falha de gravar ou de abrir diz "Ocorreu um erro inesperado"', () {
    const generic = 'Ocorreu um erro inesperado';
    expect(values['loadErrorGenericTitle'], generic);
    for (final key in const [
      'lessonSaveRetry',
      'trainingPlanSaveError',
      'trainingExerciseSaveError',
      'learningAnalysisSaveError',
      'practiceSolutionUnavailable',
      'practiceOpponentUnavailable',
    ]) {
      expect(values[key], generic, reason: key);
    }
    // A variante "motor" do erro padrão saiu: usa a genérica.
    expect(values.containsKey('loadErrorEngineTitle'), isFalse);
  });
}
