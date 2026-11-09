import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/progress.dart';

ExerciseResult _r(
  int n, {
  bool solved = true,
  int attempts = 1,
  bool sawSolution = false,
}) => ExerciseResult(
  n: n,
  solved: solved,
  points: solved ? 10 : 0,
  attempts: attempts,
  sawSolution: sawSolution,
);

void main() {
  group('ProgressoPartida.resultados do servidor (primeiras)', () {
    test('de primeira só com uma tentativa e sem a solução', () {
      final p = GameProgress.empty
          .withValue(_r(1))
          .withValue(_r(2, attempts: 2))
          .withValue(_r(3, solved: false, attempts: 3, sawSolution: true));
      expect(p.toRemote()['resultados'], {'1': true, '2': false, '3': false});
    });

    test('gravado uma vez: refazer e acertar depois não muda', () {
      final first = GameProgress.empty.withValue(
        _r(1, solved: false, sawSolution: true),
      );
      final redone = first.restartExercises().withValue(_r(1));
      expect(redone.doneCount, 1);
      expect(redone.corrects, 1);
      expect(redone.toRemote()['resultados'], {'1': false});
    });

    test('recomeçar zera a rodada e guarda a análise vista', () {
      final p = GameProgress.empty.withValue(_r(1)).withAnalysisViewed();
      final r = p.restartExercises();
      expect(r.doneCount, 0);
      expect(r.sawAnalysis, isTrue);
      expect(r.firstOnes, {1: true});
    });
  });

  group('viuAnalise', () {
    test('só vai ao servidor quando verdadeiro', () {
      expect(GameProgress.empty.toRemote().containsKey('viuAnalise'), isFalse);
      expect(
        GameProgress.empty.withAnalysisViewed().toRemote()['viuAnalise'],
        isTrue,
      );
    });

    test('marcar a análise mantém os resultados e o espelho', () {
      const remote = GameProgress(
        remoteDone: 3,
        remoteCorrect: 2,
        remotePoints: 20,
      );
      final p = remote.withAnalysisViewed();
      expect((p.doneCount, p.corrects, p.points), (3, 2, 20));
    });
  });

  group('json', () {
    test('o do aparelho volta igual (também depois de fechar o app)', () {
      final p = GameProgress.empty
          .withValue(_r(1))
          .withValue(_r(2, solved: false, sawSolution: true))
          .withAnalysisViewed();
      final read = GameProgress.fromJson(jsonDecode(jsonEncode(p.toJson())));
      expect(read.results.map((r) => r.n), [1, 2]);
      expect(read.firstOnes, {1: true, 2: false});
      expect(read.sawAnalysis, isTrue);
      expect(read.corrects, 1);
    });

    test('o espelho do servidor lê resultados em mapa', () {
      final read = GameProgress.fromJson({
        'feitos': 2,
        'acertos': 1,
        'pontos': 10,
        'resultados': {'1': true, '2': false, 'x': true, '3': 'sim'},
        'viuAnalise': true,
      });
      expect(read.results, isEmpty);
      expect(read.firstOnes, {1: true, 2: false});
      expect(read.doneCount, 2);
      expect(read.sawAnalysis, isTrue);
    });
  });
}
