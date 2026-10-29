import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/race.dart';

void main() {
  group('RaceProblem.fromJson', () {
    final problem = RaceProblem.fromJson({
      'id': 'race.350.01',
      'fen': '7k/8/5K2/8/8/8/8/R7 w - - 0 1',
      'category': 'basic',
      'subcategory': 'rook',
      'level': 360,
      'tree': {
        'd': 3,
        'm': {
          'f6f7': {
            'r': 'h8h7',
            'n': {
              'd': 1,
              'm': {'a1h1': <String, dynamic>{}},
              'w': ['a1a2'],
            },
          },
        },
      },
    });

    test('lê a árvore, a resposta da defesa e os lances lentos', () {
      expect(problem.bucket, 350);
      expect(problem.tree.distance, 3);
      expect(problem.tree.mateIn, 2);
      final branch = problem.tree.moves['f6f7']!;
      expect(branch.reply, 'h8h7');
      expect(branch.isEnd, isFalse);
      expect(branch.next!.slower, {'a1a2'});
      expect(branch.next!.moves['a1h1']!.isEnd, isTrue);
    });
  });

  group('RaceNode alternativas', () {
    test('lê "a" (lance um lance mais lento, aceito) separado de "w"', () {
      final node = RaceNode.fromJson({
        'd': 31,
        'm': {'e1e2': <String, dynamic>{}},
        'a': ['e1d2'],
        'w': ['e1f1'],
      });
      expect(node.alternatives, {'e1d2'});
      expect(node.slower, {'e1f1'});
      expect(
        RaceNode.fromJson({'d': 1, 'm': <String, dynamic>{}}).alternatives,
        isEmpty,
      );
    });
  });

  group('RaceRun duração', () {
    test('guarda a duração no JSON e a Corrida antiga vale 3 minutos', () {
      final run = RaceRun(
        startedAt: DateTime.utc(2026),
        duration: RaceDuration.fiveMinutes,
      );
      expect(RaceRun.fromJson(run.toJson()).duration, RaceDuration.fiveMinutes);
      final old = RaceRun.fromJson({
        'startedAt': DateTime.utc(2026).millisecondsSinceEpoch,
        'answers': <dynamic>[],
      });
      expect(old.duration, RaceDuration.threeMinutes);
    });
  });

  group('RaceAnswer histórico por tipo de final', () {
    test('guarda tipo, Defender, nível e resultado (acerto, erro, lenta)', () {
      const base = {'id': 'p', 'level': 700, 'move': 'a1a2'};
      RaceAnswer parse(Map<String, dynamic> extra) => RaceAnswer.fromJson(
        RaceAnswer.fromJson({...base, 'correct': false, ...extra}).toJson(),
      );
      final ok = parse({'correct': true, 'subcategory': 'rook'});
      expect(ok.subcategory, 'rook');
      expect(ok.defend, isFalse);
      expect(parse({'defend': true}).defend, isTrue);
      expect(ok.level, 700);
      expect(ok.kind, RaceOutcomeKind.correct);
      expect(parse({'subcategory': 'queen'}).kind, RaceOutcomeKind.wrong);
      expect(
        parse({'subcategory': 'knightBishopVsKing', 'slower': true}).kind,
        RaceOutcomeKind.slowWin,
      );
      expect(parse({}).subcategory, isNull);
    });
  });

  group('RaceAnswer', () {
    test('guarda a posição, o melhor lance e a distância no JSON', () {
      const answer = RaceAnswer(
        problemId: 'p',
        level: 350,
        move: 'a1a2',
        correct: false,
        fen: '8/5K1k/8/8/8/8/8/R7 w - - 2 2',
        best: ['a1h1'],
        distance: 1,
        slower: true,
      );
      final round = RaceAnswer.fromJson(answer.toJson());
      expect(round.fen, answer.fen);
      expect(round.best, ['a1h1']);
      expect(round.distance, 1);
      expect(round.slower, isTrue);
      expect(round.mateIn, 1);
    });

    test('resposta do formato antigo (sem posição) ainda abre', () {
      final old = RaceAnswer.fromJson({
        'id': 'p',
        'level': 900,
        'move': 'e2e4',
        'correct': false,
      });
      expect(old.fen, isNull);
      expect(old.best, isEmpty);
      expect(old.slower, isFalse);
    });
  });
}
