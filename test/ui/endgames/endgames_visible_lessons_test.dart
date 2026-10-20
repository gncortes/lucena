import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/endgames/endgame_lesson_repository_asset.dart';
import 'package:lucena/data/repositories/endgames/visible_endgame_lesson_repository.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

class _Assets extends AssetService {
  @override
  Future<String> loadString(String path) => io.File(path).readAsString();
}

// Print com sombra real: --dart-define=PRINT=<pasta> --update-goldens.
const _print = String.fromEnvironment('PRINT');

/// As aulas de finais escondidas (VisibleLessons): o catálogo de verdade
/// mostra só a Oposição, Partes 1 e 2, num módulo só.
void main() {
  testWidgets('o catálogo real mostra só as aulas com roteiro novo', (
    tester,
  ) async {
    await Goldens.loadFonts();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final repository = VisibleEndgameLessonRepository(
      AssetEndgameLessonRepository(
        _Assets(),
        school: AssetLessonRepository(_Assets()),
      ),
    );
    final cubit = EndgamesCubit(
      lessons: repository,
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.runAsync(() => cubit.load('pt'));
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(EndgamesKeys.module('pawns')), findsOneWidget);
    // O bispo e cavalo (T77) abre o módulo de mates.
    expect(find.byKey(EndgamesKeys.module('mates')), findsOneWidget);
    expect(
      find.byKey(EndgamesKeys.lesson('mates.bishopKnight.deletang')),
      findsOneWidget,
    );
    for (final module in ['basics', 'queen', 'rook', 'minor']) {
      expect(find.byKey(EndgamesKeys.module(module)), findsNothing);
    }
    expect(find.byKey(EndgamesKeys.lesson('pawns.keySquares')), findsOneWidget);
    expect(
      find.byKey(EndgamesKeys.lesson('pawns.distantOpposition')),
      findsOneWidget,
    );
    // A Parte 2 aparece quando o primeiro capítulo dela tem roteiro (T76).
    expect(
      find.byKey(EndgamesKeys.lesson('pawns.waitingMoves')),
      findsOneWidget,
    );
    expect(find.byKey(EndgamesKeys.lesson('pawns.square')), findsNothing);
    expect(find.text('0 de 4 concluídas'), findsOneWidget);

    if (_print.isNotEmpty) {
      debugDisableShadows = false;
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EndgamesScreen),
        matchesGoldenFile('$_print/catalogo_412.png'),
      );
      debugDisableShadows = true;
    }
  });
}
