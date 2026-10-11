import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/exercise_error_feedback.dart';

void main() {
  const fen = '6k1/8/8/8/8/8/3P4/7K w - - 0 1';
  final row = ExerciseErrorFeedback.fromJson('pawns.distantOpposition', {
    'kind': 'exercise',
    'turn': 1,
    'id': 'e09',
    'fen': fen,
    'uci': 'd2d3',
    'pt': 'Texto recebido.',
    'en': 'Received text.',
  });
  bool matches(
    String position, {
    String id = 'e09',
    String uci = 'd2d3',
    String lesson = 'pawns.distantOpposition',
    String kind = 'exercise',
    int turn = 1,
  }) => row.matches(
    lessonId: lesson,
    exerciseId: id,
    kind: kind,
    turn: turn,
    fen: position,
    uci: uci,
  );

  test('identidade composta exige decisão, tipo e FEN completa', () {
    expect(matches('  6k1/8/8/8/8/8/3P4/7K   w - - 0 1  '), isTrue);
    expect(matches(fen.replaceFirst('0 1', '12 40')), isFalse);
    expect(matches(fen.replaceFirst('0 1', '1 1')), isFalse);
    expect(matches(fen.replaceFirst('0 1', '0 2')), isFalse);
    expect(matches(fen.split(' ').take(4).join(' ')), isFalse);
    expect(matches(fen, turn: 2), isFalse);
    expect(matches(fen, kind: 'move'), isFalse);
    expect(matches(fen.replaceFirst(' w ', ' b ')), isFalse);
    expect(matches(fen.replaceFirst(' w - - ', ' w K - ')), isFalse);
    expect(matches(fen.replaceFirst(' w - - ', ' w - d6 ')), isFalse);
    expect(matches(fen.replaceFirst('6k1', '5k2')), isFalse);
    expect(matches(fen, id: 'e10'), isFalse);
    expect(matches(fen, lesson: 'other'), isFalse);
    expect(matches(fen, uci: 'd2d4'), isFalse);
    expect(matches('invalid'), isFalse);
  });

  test('idioma recebido e fallback inglês sem reescrever o conteúdo', () {
    expect(row.text('pt'), 'Texto recebido.');
    expect(row.text('en'), 'Received text.');
    expect(row.text('es'), 'Received text.');
    expect(
      () => ExerciseErrorFeedback.fromJson('lesson', {
        'kind': 'unknown',
        'turn': 1,
        'id': 'e09',
        'fen': fen,
        'uci': 'd2d3',
      }),
      throwsFormatException,
    );
  });
}
