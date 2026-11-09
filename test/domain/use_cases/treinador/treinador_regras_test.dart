import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/course_grant.dart';
import 'package:lucena/domain/use_cases/endgame_lesson_rules.dart';
import 'package:lucena/domain/use_cases/treinador/treinador_regras.dart';

import '../../../../testing/treinador_fixtures.dart';

void main() {
  final agora = DateTime.utc(2026, 11, 9, 12);

  group('TreinadorRegras.temAcesso', () {
    test('sem o direito treinador: sem acesso', () {
      expect(TreinadorRegras.temAcesso(CourseGrants.empty, agora), isFalse);
    });

    test('com o direito treinador ativo: tem acesso', () {
      const grants = CourseGrants(
        courses: {'treinador': CourseGrant(origin: GrantOrigin.purchase)},
      );
      expect(TreinadorRegras.temAcesso(grants, agora), isTrue);
    });
  });

  group('TreinadorRegras.abre', () {
    test('com o plano, qualquer partida abre', () {
      final nova = TreinadorFixtures.tiago(status: 'nova');
      expect(TreinadorRegras.abre(nova, acesso: true), isTrue);
    });

    test('sem o plano, a partida nova fica fechada', () {
      final nova = TreinadorFixtures.tiago(status: 'nova');
      expect(TreinadorRegras.abre(nova, acesso: false), isFalse);
    });

    test('sem o plano, a partida já analisada continua aberta', () {
      final pronta = TreinadorFixtures.tiago();
      expect(TreinadorRegras.abre(pronta, acesso: false), isTrue);
    });
  });

  group('TreinadorRegras.pontos', () {
    test('primeira tentativa vale 3', () {
      expect(TreinadorRegras.pontos(tentativas: 1, viuSolucao: false), 3);
    });

    test('depois de errar vale 1', () {
      expect(TreinadorRegras.pontos(tentativas: 2, viuSolucao: false), 1);
      expect(TreinadorRegras.pontos(tentativas: 5, viuSolucao: false), 1);
    });

    test('ver a solução vale 0, mesmo na primeira tentativa', () {
      expect(TreinadorRegras.pontos(tentativas: 1, viuSolucao: true), 0);
      expect(TreinadorRegras.pontos(tentativas: 3, viuSolucao: true), 0);
    });
  });

  group('TreinadorRegras.nota', () {
    test('todos certos: perfeito', () {
      expect(TreinadorRegras.nota(4, 4), ExerciseGrade.perfect);
    });

    test('3 de 4 (75%): bom', () {
      expect(TreinadorRegras.nota(3, 4), ExerciseGrade.good);
    });

    test('2 de 4 (50%): aprovado', () {
      expect(TreinadorRegras.nota(2, 4), ExerciseGrade.passed);
    });

    test('1 de 4: abaixo', () {
      expect(TreinadorRegras.nota(1, 4), ExerciseGrade.below);
      expect(TreinadorRegras.nota(0, 4), ExerciseGrade.below);
    });

    test('sem exercícios: abaixo (sem dividir por zero)', () {
      expect(TreinadorRegras.nota(0, 0), ExerciseGrade.below);
    });
  });

  group('numeração dos lances', () {
    test('numeroDoLance: dois meio-lances por número', () {
      expect(TreinadorRegras.numeroDoLance(1), 1);
      expect(TreinadorRegras.numeroDoLance(2), 1);
      expect(TreinadorRegras.numeroDoLance(15), 8);
      expect(TreinadorRegras.numeroDoLance(16), 8);
    });

    test('meioLance: brancas ímpar, pretas par', () {
      expect(TreinadorRegras.meioLance(8, brancas: true), 15);
      expect(TreinadorRegras.meioLance(8, brancas: false), 16);
    });

    test('meioLance e numeroDoLance se desfazem', () {
      for (var n = 1; n <= 30; n++) {
        for (final brancas in [true, false]) {
          final meio = TreinadorRegras.meioLance(n, brancas: brancas);
          expect(TreinadorRegras.numeroDoLance(meio), n);
        }
      }
    });
  });
}
