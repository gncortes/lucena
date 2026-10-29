import 'package:lucena/domain/models/training/training_content.dart';

/// Same synthetic corridor-mate contract as exportar_treino.py; no private data.
abstract final class MockExerciseBank {
  static const blackFen = 'r5k1/5ppp/8/8/8/8/5PPP/6K1 b - - 0 1';
  static const fen = '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1';
  static List<TrainingExercise> forLesson(String id) => [
    for (final (stars, count) in [(1, 6), (2, 5), (3, 3)])
      for (var i = 1; i <= count; i++)
        TrainingExercise(
          id: 'mock-$id-$stars-$i',
          stars: stars,
          fen: fen,
          solution: ['a1a8'],
          mock: true,
        ),
  ];
}
