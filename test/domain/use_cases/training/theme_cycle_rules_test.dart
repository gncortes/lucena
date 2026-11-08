import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/theme_cycle.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/use_cases/training/theme_cycle_rules.dart';

import '../../../../testing/fakes/fake_now.dart';

/// H-TRE-12: nota do ciclo e regra de subida de nível.
void main() {
  late FakeNow now;
  setUp(() => now = FakeNow(DateTime(2026, 10, 26, 12)));

  TrainingExercise exercise(String id, int stars) => TrainingExercise(
    id: id,
    stars: stars,
    fen: '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1',
    solution: ['a1a8'],
  );
  ThemeCycle fresh() => ThemeCycle(lessonId: 'theme1', startedOn: '2026-10-23');

  ThemeCycle play(ThemeCycle start, List<({bool ok, bool hint})> answers) {
    var cycle = start;
    for (final (i, a) in answers.indexed) {
      cycle = ThemeCycleRules(now).record(
        cycle,
        exercise('e$i', cycle.level),
        correct: a.ok,
        hint: a.hint,
      );
      now.advance(const Duration(days: 1));
    }
    return cycle;
  }

  /// Ciclo de 7 dias com as estrelas dadas: 0 = erro; o resto é acerto.
  ThemeCycle withStars(List<int> stars, {int level = 1}) => ThemeCycle(
    lessonId: 'theme1',
    startedOn: '2026-10-20',
    level: level,
    days: [
      for (final (i, s) in stars.indexed)
        ThemeDay(
          date: '2026-10-${20 + i}',
          exerciseId: 'old$i',
          stars: s == 0 ? 1 : s,
          correct: s != 0,
        ),
    ],
  );

  group('nota e fase do ciclo fechado', () {
    test('15 de 15 estrelas sem dica: nota 100 e tema firme', () {
      final closed = ThemeCycleRules(now).record(
        withStars([1, 1, 2, 2, 3, 3], level: 3),
        exercise('last', 3),
        correct: true,
      );
      expect(closed.score, 100);
      expect(closed.phase, ThemePhase.firm);
    });

    test('5 de 15 estrelas: nota 33 e reforço', () {
      // 1+1+3 = 5 estrelas em acertos; o resto é erro.
      final closed = ThemeCycleRules(now).record(
        withStars([1, 1, 3, 0, 0, 0]),
        exercise('last', 1),
        correct: false,
      );
      expect(closed.score, 33);
      expect(closed.phase, ThemePhase.reinforce);
    });

    test('4 de 15 estrelas: nota 27 e refazer', () {
      final closed = ThemeCycleRules(now).record(
        withStars([1, 1, 2, 0, 0, 0]),
        exercise('last', 1),
        correct: false,
      );
      expect(closed.score, 27);
      expect(closed.phase, ThemePhase.redo);
    });

    test('acerto com dica vale como erro e não soma estrelas', () {
      final closed = ThemeCycleRules(now).record(
        withStars([1, 1, 2, 2, 3, 3], level: 3),
        exercise('last', 3),
        correct: true,
        hint: true,
      );
      expect(closed.score, 80); // 12 de 15
      expect(closed.days.last.earned, isFalse);
      expect(closed.hadError, isTrue);
    });

    test('sétimo dia fecha o ciclo; o sexto ainda não', () {
      final sixth = ThemeCycleRules(now).record(
        withStars([1, 1, 2, 2], level: 3),
        exercise('s5', 3),
        correct: true,
      );
      expect(sixth.cycleDays.length, 5);
      expect(sixth.phase, ThemePhase.cycle);
      final closed = ThemeCycleRules(now).record(
        withStars([1, 1, 2, 2, 3, 3], level: 3),
        exercise('s7', 3),
        correct: true,
      );
      expect(closed.cycleDays.length, 7);
      expect(closed.phase, isNot(ThemePhase.cycle));
      expect(
        () =>
            ThemeCycleRules(now)
                .record(closed, exercise('s8', closed.level), correct: true),
        throwsStateError,
      );
    });
  });

  group('subida de nível', () {
    test('antes do primeiro erro: sobe só com 2 acertos seguidos', () {
      var cycle = fresh();
      final levels = <int>[];
      for (var i = 0; i < 4; i++) {
        levels.add(cycle.level);
        cycle = play(cycle, [(ok: true, hint: false)]);
      }
      expect(levels, [1, 1, 2, 2]);
    });

    test('depois de um erro: 1 acerto já sobe', () {
      var cycle = play(fresh(), [
        (ok: false, hint: false), // erro no nível 1 (não desce abaixo de 1)
      ]);
      expect(cycle.level, 1);
      cycle = play(cycle, [(ok: true, hint: false)]);
      expect(cycle.level, 2);
      cycle = play(cycle, [(ok: true, hint: false)]);
      expect(cycle.level, 3);
    });

    test('erro desce um nível e o piso é 1', () {
      var cycle = play(fresh(), [
        (ok: true, hint: false),
        (ok: true, hint: false),
      ]);
      expect(cycle.level, 2);
      cycle = play(cycle, [(ok: false, hint: false)]);
      expect(cycle.level, 1);
      cycle = play(cycle, [(ok: false, hint: false)]);
      expect(cycle.level, 1);
    });

    test('dica conta como erro: desce e passa a subir com 1 acerto', () {
      var cycle = play(fresh(), [
        (ok: true, hint: false),
        (ok: true, hint: false),
        (ok: true, hint: true),
      ]);
      expect(cycle.level, 1);
      expect(cycle.hadError, isTrue);
      cycle = play(cycle, [(ok: true, hint: false)]);
      expect(cycle.level, 2);
    });

    test('o nível nunca passa de 3', () {
      var cycle = fresh();
      cycle = play(cycle, [
        for (var i = 0; i < 6; i++) (ok: true, hint: false),
      ]);
      expect(cycle.level, 3);
    });
  });
}
