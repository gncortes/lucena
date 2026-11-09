import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/coach/coach.dart';

import '../../../../testing/coach_fixtures.dart';

void main() {
  group('PartidaTreinador', () {
    test('lê a partida pronta do canvas', () {
      final p = CoachFixtures.tiago();
      expect(p.ready, isTrue);
      expect(p.platform, 'lichess');
      expect(p.opponent.name, 'Tiago_Rook');
      expect(p.color, GameColor.black);
      expect(p.result, GameResult.loss);
      expect(p.timeControl, TimeControl.blitz);
      expect(p.exercises.map((e) => e.type), [
        ExerciseType.opponent,
        ExerciseType.prophylaxis,
        ExerciseType.yourBest,
        ExerciseType.decisive,
      ]);
      expect(p.exercises.first.accepts('d3h7'), isTrue);
      expect(p.exercises.first.accepts('e5f6'), isFalse);
      expect(p.theory!.candidates.first.san, 'Bf5');
      expect(p.phases.ending, 62);
    });

    test('ida e volta pelo JSON', () {
      final p = CoachFixtures.tiago();
      final of = CoachGame.fromJson(p.id, p.toJson())!;
      expect(of.toJson(), p.toJson());
    });

    test('sem data ou resultado: ilegível', () {
      expect(CoachGame.fromJson('x', {'resultado': 'vitoria'}), isNull);
      expect(
        CoachGame.fromJson('x', {'jogadaEm': '2026-11-08T10:00:00Z'}),
        isNull,
      );
    });

    test('status desconhecido vira nova; exercício sem FEN sai', () {
      final p = CoachGame.fromJson('x', {
        'jogadaEm': DateTime.utc(2026, 11, 8).millisecondsSinceEpoch,
        'resultado': 'empate',
        'status': '???',
        'exercicios': [
          {'solucao': 'e2e4'},
          {'fen': CoachFixtures.fenEnding, 'solucao': 'b8c8'},
        ],
      })!;
      expect(p.status, GameStatus.newGame);
      expect(p.exercises, hasLength(1));
      expect(p.exercises.single.n, 2);
    });
  });

  group('ProgressoPartida', () {
    test('conta acertos e pontos e acha o próximo', () {
      var pr = GameProgress.empty;
      expect(pr.next(4), 1);
      pr = pr.withValue(const ExerciseResult(n: 1, solved: true, points: 3));
      pr = pr.withValue(
        const ExerciseResult(n: 2, solved: false, points: 0, sawSolution: true),
      );
      expect(pr.doneCount, 2);
      expect(pr.corrects, 1);
      expect(pr.points, 3);
      expect(pr.next(4), 3);
      expect(pr.isComplete(4), isFalse);
      expect(pr.toRemote(), {
        'feitos': 2,
        'acertos': 1,
        'pontos': 3,
        'resultados': {'1': true, '2': false},
      });
      final of = GameProgress.fromJson(pr.toJson());
      expect(of.doneCount, 2);
      expect(of.next(4), 3);
    });

    test('só o espelho do servidor: usa os números dele', () {
      final pr = GameProgress.fromJson({
        'feitos': 4,
        'acertos': 3,
        'pontos': 9,
      });
      expect(pr.doneCount, 4);
      expect(pr.corrects, 3);
      expect(pr.isComplete(4), isTrue);
    });
  });

  test('estatísticas do exemplo', () {
    final e = CoachFixtures.stats();
    expect(e.analyzedGames, 12);
    expect(e.errorsByPhase.total, 18);
    expect(e.errorsByMotif['final_de_torres'], hasLength(1));
    expect(e.openings.first.theoryExit!.chessMove, 5);
    expect(e.style.solve.single.motif, 'final_de_torres');
    expect(CoachStats.fromJson(e.toJson()).toJson(), e.toJson());
  });

  test('config: limita os exercícios de 1 a 6', () {
    expect(
      CoachConfig.fromJson({'exerciciosPorPartida': 9}).exercisesPerGame,
      6,
    );
    expect(CoachConfig.fromJson(null).exercisesPerGame, 4);
    expect(
      ModelGame.listFromJson({
        'modelos': [
          {'fonte': 'torneio', 'titulo': 'Carlsen x Caruana'},
          {'fonte': 'x'},
        ],
      }),
      hasLength(1),
    );
  });

  test('conta ligada', () {
    final c = CoachAccount.fromJson({
      'plataforma': 'chesscom',
      'usuario': 'gabriel',
      'avisoModelos': true,
    })!;
    expect(c.platform, Platform.chesscom);
    expect(CoachAccount.fromJson(c.toJson()), c);
  });
}
