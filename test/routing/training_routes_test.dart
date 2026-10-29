import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';

void main() {
  test('private Pilares lesson IDs resolve chapter and scripted part', () {
    final uri = Uri.parse(Routes.trainingLesson('pilares.c4.part2'));
    expect(uri.path, '/endgames/pilares.c4/roteiro');
    expect(uri.queryParameters['part'], 'part2');
    expect(uri.queryParameters['origem'], 'treino_guia');
  });

  test('whole chapter references keep their actual endgame IDs', () {
    for (final id in ['pawns.keySquares', 'rook.lucena', 'pilares.c5']) {
      final uri = Uri.parse(Routes.trainingLesson(id));
      expect(uri.path, '/endgames/$id');
      expect(uri.queryParameters['origem'], 'treino_guia');
      expect(uri.queryParameters.containsKey('part'), isFalse);
    }
  });
}
