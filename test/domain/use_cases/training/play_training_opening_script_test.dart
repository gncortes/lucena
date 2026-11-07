import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/opening_track.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/training/play_training_opening.dart';
import 'package:lucena/domain/use_cases/training/opening_trecho_rules.dart';

import '../../../../testing/fakes/fake_now.dart';

OpeningTrecho example(Map<String, dynamic> script) => OpeningTrecho.fromJson({
  'id': 'ideia.example',
  'titulo': 'Example',
  'exemplo': script,
  'fen': script['fen'],
  'cor': script['vira'] == true ? 'pretas' : 'brancas',
});
Map<String, dynamic> script(String fen) => {
  'id': 'example',
  'fen': fen,
  'vira': false,
  'objetivo': 'ganhar',
  'fim': 'fim',
  'entrada': <Object>[],
  'linha': <Object>[],
};
Map<String, dynamic> question(
  String fen,
  String primary,
  List<String> right, {
  Map<String, List<Map<String, dynamic>>> alternatives = const {},
}) => {
  't': 'question',
  'certos': right,
  'certo': step(fen, primary),
  'revela': step(fen, primary),
  'alternativos': alternatives,
  'erros': <String, Object>{},
};
String after(String fen, String uci) =>
    GameRules.play(GameRules.fromFen(fen)!, Move.parse(uci)!)!.position.fen;
Map<String, dynamic> step(String fen, String uci) => {
  'fen': after(fen, uci),
  'lance': uci,
  't': 'move',
};
OpeningTrack complete(OpeningTrecho trecho, List<bool> results) =>
    OpeningTrechoRules(FakeNow(DateTime(2026, 10, 29))).complete(
      OpeningTrack(lessonId: 'opening', startedOn: '2026-10-28'),
      trecho,
      results,
    );
void main() {
  test(
    'question precedes its duplicate snapshot and authored continuation',
    () {
      final start = GameRules.initial.fen;
      final e4 = after(start, 'e2e4');
      final e5 = after(e4, 'e7e5');
      final e = script(start)
        ..['pergunta'] = question(start, 'e2e4', ['e2e4'])
        ..['linha'] = [
          {'fen': e4, 't': 'after question'},
          step(e4, 'e7e5'),
          step(e5, 'g1f3'),
        ];
      final line = PlayTrainingOpening(example(e));
      expect(line.initialCursor, 0);
      expect(line.acceptedAt(0), ['e2e4']);
      expect(line.studentMoves, 2);
      expect(line.fens.length, 4);
      expect(line.play(0, 'e2e4'), (cursor: 2, correct: true));
      expect(line.san, ['e4', 'e5', 'Nf3']);
      expect(line.play(2, 'g1f3').cursor, 3);
    },
  );
  for (final blackTurn in [false, true]) {
    final start = GameRules.initial.fen.replaceFirst(
      ' w ',
      blackTurn ? ' b ' : ' w ',
    );
    final uci = blackTurn ? 'e7e5' : 'e2e4';
    test(
      'explicit question accepts real turn with flipped view: $blackTurn',
      () {
        final e = script(start)
          ..['vira'] = !blackTurn
          ..['pergunta'] = question(start, uci, [uci])
          ..['linha'] = [
            {'fen': after(start, uci), 't': 'after question'},
          ];
        final line = PlayTrainingOpening(example(e));
        expect(line.acceptedAt(line.initialCursor), [uci]);
        expect(line.play(line.initialCursor, uci).correct, true);
      },
    );
    test('practice accepts real turn with flipped view: $blackTurn', () {
      final e = script(start)
        ..['vira'] = !blackTurn
        ..['pratica'] = {
          'tipo': 'lance',
          'maquina': 'b',
          't': 'practice',
          'linha': [
            {
              'certos': [uci],
            },
          ],
          'erros': <String, String>{},
        };
      final line = PlayTrainingOpening(example(e));
      expect(line.play(line.initialCursor, uci).correct, true);
    });
  }
  test(
    'accepted question without its own continuation ends at actual move',
    () {
      final start = GameRules.initial.fen;
      final e4 = after(start, 'e2e4');
      final e = script(start)
        ..['pergunta'] = question(start, 'e2e4', ['e2e4', 'd2d4'])
        ..['linha'] = [
          {'fen': e4, 't': 'main snapshot'},
          step(e4, 'e7e5'),
          step(after(e4, 'e7e5'), 'g1f3'),
        ];
      final line = PlayTrainingOpening(example(e));
      final result = line.play(0, 'd2d4');
      expect(result.correct, true);
      expect(line.isComplete(result.cursor), true);
      expect(line.fens, [start, after(start, 'd2d4')]);
      expect(line.san, ['d4']);
      expect(complete(example(e), const [true]).seenMoves, 1);
      expect(complete(example(e), const [true, true]).seenMoves, 2);
      expect(() => complete(example(e), const []), throwsArgumentError);
      expect(
        () => complete(example(e), const [true, true, true]),
        throwsArgumentError,
      );
    },
  );
  test('good alternative retains its own authored continuation', () {
    final start = GameRules.initial.fen;
    final e4 = after(start, 'e2e4');
    final e5 = after(e4, 'e7e5');
    final nf3 = after(e5, 'g1f3');
    final nc6 = after(nf3, 'b8c6');
    final e = script(start)
      ..['pergunta'] = question(
        start,
        'd2d4',
        ['d2d4'],
        alternatives: {
          'e2e4': [
            step(start, 'e2e4'),
            step(e4, 'e7e5'),
            step(e5, 'g1f3'),
            step(nf3, 'b8c6'),
            step(nc6, 'f1b5'),
          ],
        },
      )
      ..['linha'] = [
        {'fen': after(start, 'd2d4'), 't': 'main snapshot'},
      ];
    final line = PlayTrainingOpening(example(e));
    expect(line.acceptedAt(0), ['d2d4', 'e2e4']);
    expect(line.play(0, 'e2e4'), (cursor: 2, correct: true));
    expect(line.moveAt(0), 'e2e4');
    expect(line.fens[1], e4);
    expect(line.play(2, 'g1f3'), (cursor: 4, correct: true));
    expect(line.play(4, 'f1b5'), (cursor: 5, correct: true));
    expect(line.san, ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5']);
    expect(complete(example(e), const [true]).seenMoves, 1);
    expect(complete(example(e), const [true, false, true]).seenMoves, 3);
    expect(() => complete(example(e), const [true, true]), throwsArgumentError);
    expect(
      () => complete(example(e), const [true, true, true, true]),
      throwsArgumentError,
    );
  });
  test('legacy retains automatic opponent and cursor behavior', () {
    final line = PlayTrainingOpening(
      OpeningTrecho(id: 'old', title: '', moves: ['e2e4', 'e7e5', 'g1f3']),
    );
    expect(line.initialCursor, 0);
    expect(line.play(0, 'e2e4'), (cursor: 2, correct: true));
    expect(line.studentMoves, 2);
  });
  test('snapshots preserve authored setup and real turn numbering', () {
    const fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 12';
    final e = script(GameRules.initial.fen)..['vira'] = true;
    e['linha'] = [
      {'fen': fen, 't': 'jump'},
      {
        'fen': 'rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq e6 0 13',
        't': 'move',
        'lance': 'e7e5',
      },
    ];
    final line = PlayTrainingOpening(example(e));
    expect(line.initialCursor, 1);
    expect(line.fens[1], fen);
    expect(line.moveNumberAt(1), 12);
    expect(line.questionIndex(1), 0);
    expect(line.play(1, 'e7e5').correct, true);
    expect(line.studentMoves, 1);
  });
  test(
    'practice accepts all alternatives and retains actual final position',
    () {
      final e = script(GameRules.initial.fen);
      e['pratica'] = {
        'tipo': 'lance',
        'maquina': 'b',
        't': 'practice',
        'linha': [
          {
            'certos': ['e2e4', 'd2d4'],
          },
        ],
        'erros': <String, String>{},
      };
      final trecho = example(e);
      expect(trecho.toJson()['exemplo'], e);
      final line = PlayTrainingOpening(trecho);
      expect(line.play(0, 'd2d4').correct, true);
      expect(line.fens.last, contains('/3P4/'));
      expect(line.san.last, 'd4');
      expect(line.isComplete(1), true);
    },
  );
  test('practice plays explicit reply and indexes student questions', () {
    final e = script(GameRules.initial.fen);
    e['pratica'] = {
      'tipo': 'lance',
      'maquina': 'b',
      't': 'practice',
      'linha': [
        {
          'certos': ['e2e4'],
          'resposta': 'e7e5',
        },
        {
          'certos': ['g1f3'],
        },
      ],
      'erros': <String, String>{},
    };
    final line = PlayTrainingOpening(example(e));
    expect(line.play(0, 'e2e4').cursor, 2);
    expect(line.questionIndex(2), 1);
    expect(line.play(2, 'g1f3').cursor, 3);
  });
  for (final first in ['e2e4', 'd2d4']) {
    test('practice $first preserves every remaining authored turn', () {
      final e = script(GameRules.initial.fen)
        ..['pratica'] = {
          'tipo': 'lance',
          'maquina': 'b',
          't': 'practice',
          'linha': [
            {
              'certos': ['e2e4', 'd2d4'],
              'resposta': 'e7e5',
            },
            {
              'certos': ['g1f3'],
            },
          ],
          'erros': <String, String>{},
        };
      final trecho = example(e);
      final line = PlayTrainingOpening(trecho);
      expect(line.validStudentMoveCounts, {2});
      final result = line.play(0, first);
      expect(result, (cursor: 2, correct: true));
      expect(line.isComplete(result.cursor), isFalse);
      expect(line.acceptedAt(result.cursor), ['g1f3']);
      expect(line.fens[1], after(GameRules.initial.fen, first));
      expect(line.san, [first == 'e2e4' ? 'e4' : 'd4', 'e5', 'Nf3']);
      expect(line.play(result.cursor, 'g1f3'), (cursor: 3, correct: true));
      expect(complete(trecho, [true, false]).seenMoves, 2);
      expect(() => complete(trecho, [true]), throwsArgumentError);
    });
  }
  test('practice retains later alternatives after an earlier alternative', () {
    final e = script(GameRules.initial.fen)
      ..['pratica'] = {
        'tipo': 'lance',
        'maquina': 'b',
        't': 'practice',
        'linha': [
          {
            'certos': ['e2e4', 'd2d4'],
            'resposta': 'e7e5',
          },
          {
            'certos': ['g1f3', 'b1c3'],
            'resposta': 'b8c6',
          },
          {
            'certos': ['a2a3'],
          },
        ],
        'erros': <String, String>{},
      };
    final line = PlayTrainingOpening(example(e));
    expect(line.validStudentMoveCounts, {3});
    expect(line.play(0, 'd2d4').cursor, 2);
    expect(line.acceptedAt(2), ['g1f3', 'b1c3']);
    expect(line.play(2, 'b1c3').cursor, 4);
    expect(line.isComplete(4), false);
    expect(line.play(4, 'a2a3').cursor, 5);
    expect(line.san, ['d4', 'e5', 'Nc3', 'Nc6', 'a3']);
  });
  test(
    'illegal practice continuation for any accepted answer rejects definition',
    () {
      final e = script(GameRules.initial.fen)
        ..['pratica'] = {
          'tipo': 'lance',
          'maquina': 'b',
          't': 'practice',
          'linha': [
            {
              'certos': ['e2e4', 'd2d4'],
              'resposta': 'a7a6',
            },
            {
              'certos': ['e4e5'],
            },
          ],
          'erros': <String, String>{},
        };
      expect(() => PlayTrainingOpening(example(e)), throwsFormatException);
    },
  );
  test('original payload is deeply immutable and isolated from input', () {
    final raw = script(GameRules.initial.fen);
    final trecho = example(raw);
    (raw['linha'] as List).add({'fen': 'changed'});
    expect(trecho.example!['linha'], isEmpty);
    expect(
      () => (trecho.example!['linha'] as List).add({}),
      throwsUnsupportedError,
    );
    expect(() => trecho.example!['id'] = 'changed', throwsUnsupportedError);
  });
  test('empty authored and legacy examples are unavailable', () {
    expect(
      () => PlayTrainingOpening(example(script(GameRules.initial.fen))),
      throwsFormatException,
    );
    expect(
      () =>
          PlayTrainingOpening(OpeningTrecho(id: 'empty', title: '', moves: [])),
      throwsFormatException,
    );
  });
}
