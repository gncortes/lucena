import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';

void main() {
  // `android/app/build.gradle.kts` tira do APK os conjuntos de peças do
  // chessground que o app não oferece.
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('nenhum conjunto de peças oferecido no app é tirado do APK', () {
    for (final pieces in PieceStyle.values) {
      expect(
        gradle.contains('"piece_sets/${pieces.name}"'),
        isFalse,
        reason: '${pieces.name} está na lista de exclusão do APK',
      );
    }
  });

  test('conjuntos de licença não livre ficam fora do APK', () {
    for (final name in ['alpha', 'chess7', 'staunty', 'horsey', 'xkcd']) {
      expect(gradle, contains('"piece_sets/$name"'));
    }
  });
}
