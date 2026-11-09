import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/domain/use_cases/coach/coach_rules.dart';

import '../../../../testing/coach_fixtures.dart';

void main() {
  final currentTime = DateTime.utc(2026, 11, 9, 12);

  group('TreinadorRegras.temAcesso', () {
    test('sem o direito treinador: sem acesso', () {
      expect(CoachRules.hasAccess(CourseGrants.empty, currentTime), isFalse);
    });

    test('com o direito treinador ativo: tem acesso', () {
      const grants = CourseGrants(
        courses: {'treinador': CourseGrant(origin: GrantOrigin.purchase)},
      );
      expect(CoachRules.hasAccess(grants, currentTime), isTrue);
    });
  });

  group('TreinadorRegras.abre', () {
    test('com o plano, qualquer partida abre', () {
      final newGame = CoachFixtures.tiago(status: 'nova');
      expect(CoachRules.opens(newGame, grant: true), isTrue);
    });

    test('sem o plano, a partida nova fica fechada', () {
      final newGame = CoachFixtures.tiago(status: 'nova');
      expect(CoachRules.opens(newGame, grant: false), isFalse);
    });

    test('sem o plano, a partida já analisada continua aberta', () {
      final ready = CoachFixtures.tiago();
      expect(CoachRules.opens(ready, grant: false), isTrue);
    });
  });

  group('TreinadorRegras.pontos', () {
    test('primeira tentativa vale 3', () {
      expect(CoachRules.points(attempts: 1, sawSolution: false), 3);
    });

    test('depois de errar vale 1', () {
      expect(CoachRules.points(attempts: 2, sawSolution: false), 1);
      expect(CoachRules.points(attempts: 5, sawSolution: false), 1);
    });

    test('ver a solução vale 0, mesmo na primeira tentativa', () {
      expect(CoachRules.points(attempts: 1, sawSolution: true), 0);
      expect(CoachRules.points(attempts: 3, sawSolution: true), 0);
    });
  });

  group('TreinadorRegras.nota', () {
    test('todos certos: perfeito', () {
      expect(CoachRules.note(4, 4), ExerciseGrade.perfect);
    });

    test('3 de 4 (75%): bom', () {
      expect(CoachRules.note(3, 4), ExerciseGrade.good);
    });

    test('2 de 4 (50%): aprovado', () {
      expect(CoachRules.note(2, 4), ExerciseGrade.passed);
    });

    test('1 de 4: abaixo', () {
      expect(CoachRules.note(1, 4), ExerciseGrade.below);
      expect(CoachRules.note(0, 4), ExerciseGrade.below);
    });

    test('sem exercícios: abaixo (sem dividir por zero)', () {
      expect(CoachRules.note(0, 0), ExerciseGrade.below);
    });
  });

  group('numeração dos lances', () {
    test('numeroDoLance: dois meio-lances por número', () {
      expect(CoachRules.moveNumber(1), 1);
      expect(CoachRules.moveNumber(2), 1);
      expect(CoachRules.moveNumber(15), 8);
      expect(CoachRules.moveNumber(16), 8);
    });

    test('meioLance: brancas ímpar, pretas par', () {
      expect(CoachRules.halfMove(8, white: true), 15);
      expect(CoachRules.halfMove(8, white: false), 16);
    });

    test('meioLance e numeroDoLance se desfazem', () {
      for (var n = 1; n <= 30; n++) {
        for (final white in [true, false]) {
          final middlegame = CoachRules.halfMove(n, white: white);
          expect(CoachRules.moveNumber(middlegame), n);
        }
      }
    });
  });
}
