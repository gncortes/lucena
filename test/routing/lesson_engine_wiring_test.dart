import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';

/// O motor da lição (T70, crit. 8) precisa chegar a todo `LessonCubit` criado
/// no router; sem ele, todo lance fora do roteiro daria erro no app real.
void main() {
  test('todo LessonCubit do router recebe o EngineFallback', () {
    final source = io.File('lib/routing/router.dart').readAsStringSync();
    final creations = RegExp(r'\bLessonCubit\(').allMatches(source).length;
    final engines = RegExp(r'engine:\s*_engineFallback\(context\)')
        .allMatches(source)
        .length;
    expect(creations, greaterThan(0));
    expect(engines, creations);
  });
}
