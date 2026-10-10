import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<ExerciseCubit> pump(WidgetTester tester, String exercise) async {
    final cubit = ExerciseCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', exercise, 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const ExerciseScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  Future<void> move(WidgetTester tester, String from, String to) async {
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    await tester.tapAt(squareCenter(board, from));
    await tester.pump();
    await tester.tapAt(squareCenter(board, to));
    await tester.pumpAndSettle();
  }

  String speech(WidgetTester tester) =>
      (tester.widget<Text>(find.byKey(ExerciseKeys.speech).last).data ??
      tester
          .widget<Text>(find.byKey(ExerciseKeys.speech).last)
          .textSpan!
          .toPlainText());

  testWidgets('o enunciado, as estrelas e a dica com a seta', (tester) async {
    await pump(tester, 'e03');
    expect(find.text('Exercise 3 of 3'), findsOneWidget);
    // O Viktor só entra quando fala.
    expect(find.byKey(ExerciseKeys.speech), findsNothing);
    expect(find.byKey(ExerciseKeys.stars), findsOneWidget);

    await tester.tap(find.byKey(ExerciseKeys.hintButton));
    await tester.pumpAndSettle();
    expect(speech(tester), 'The hard one. Same idea.');
    final board = tester.widget<Chessboard>(find.byKey(ExerciseKeys.board));
    expect(
      board.shapes.whereType<Arrow>().any(
        (arrow) => arrow.orig.name == 'c1' && arrow.dest.name == 'c4',
      ),
      isTrue,
    );
  });

  testWidgets('lance errado volta; o certo resolve e mostra a nota', (
    tester,
  ) async {
    final cubit = await pump(tester, 'e03');
    await move(tester, 'c1', 'c2');
    expect(cubit.state.mistakes, 1);
    expect(cubit.state.fen, FakeEndgameLessonRepository.lucenaFen);

    // Antes de resolver, a vez logo abaixo do tabuleiro.
    expect(
      tester.widget<Text>(find.byKey(ExerciseKeys.goal)).data,
      'Your turn: play White',
    );

    await move(tester, 'c1', 'c4');
    expect(find.byKey(ExerciseKeys.solved), findsOneWidget);
    // Houve erro: sem "Resolvido!".
    expect(find.text('Solved!'), findsNothing);
    // Com a correção do Viktor na tela, a estrela grande e os pontos saem
    // (T60): os pontos ficam na estrela da barra de cima.
    expect(find.byKey(ExerciseKeys.earned), findsNothing);
    expect(
      tester.getSemantics(find.byKey(ExerciseKeys.stars)).label,
      '2 of 3 points',
    );
    // Singular quando o total é 1.
    final l10n = lookupAppLocalizations(const Locale('pt'));
    expect(l10n.exerciseEarned(1, 1), '1 de 1 ponto');
    expect(l10n.exerciseEarned(0, 2), '0 de 2 pontos');
    expect(l10n.exercisePoints(1), '1 ponto');
    expect(l10n.exerciseHintLast, 'Dica (o exercício deixa de pontuar)');
    expect(l10n.exerciseHintFree, 'Dica');
    expect(find.byKey(ExerciseKeys.goal), findsNothing);
    // A linha da solução, com figurino (a torre).
    expect(
      tester
          .widget<Text>(find.byKey(ExerciseKeys.solution))
          .textSpan!
          .toPlainText(),
      'Solution: 1.♖c4',
    );
    // Houve erro: a correção do Viktor vem sozinha, sem o botão.
    expect(speech(tester), 'Same bridge.');
    expect(find.byKey(ExerciseKeys.explainButton), findsNothing);
    expect(find.byKey(ExerciseKeys.locked), findsNothing);
    // Os outros dois ainda estão por resolver.
    expect(find.byKey(ExerciseKeys.nextButton), findsOneWidget);
    expect(find.byKey(ExerciseKeys.hintButton), findsNothing);
  });

  testWidgets('exercício que não existe', (tester) async {
    await pump(tester, 'e99');
    expect(find.byKey(ExerciseKeys.missing), findsOneWidget);
  });

  testWidgets('T60: resolvendo, sem o Viktor em cima (só quando fala), o '
      'tabuleiro no centro da tela, a vez embaixo e o cronômetro no canto '
      'inferior direito; resolvido, o tabuleiro sobe e o resultado entra '
      'embaixo', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    await pump(tester, 'e03');
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    final goal = tester.getRect(find.byKey(ExerciseKeys.goal));
    expect(board.center.dx, closeTo(200, 1));
    expect(board.center.dy, closeTo(450, 2));
    expect(goal.top, greaterThan(board.bottom));
    expect(find.byKey(ExerciseKeys.speech), findsNothing);
    final timer = tester.getRect(find.byKey(ExerciseKeys.timer));
    expect(timer.right, closeTo(400 - 16, 1));
    expect(timer.top, greaterThan(board.bottom));
    expect(find.byKey(ExerciseKeys.scroll), findsNothing);

    await move(tester, 'c1', 'c4');
    // Acerto limpo: o tabuleiro não sai do lugar, e embaixo só "Ver
    // explicação" e o próximo, numa linha.
    expect(tester.getRect(find.byKey(ExerciseKeys.board)), board);
    expect(find.byKey(ExerciseKeys.timer), findsNothing);
    expect(find.byKey(ExerciseKeys.goal), findsNothing);
    expect(find.byKey(ExerciseKeys.earned), findsNothing);
    final explain = tester.getRect(find.byKey(ExerciseKeys.explainButton));
    final next = tester.getRect(find.byKey(ExerciseKeys.nextButton));
    expect(explain.center.dy, closeTo(next.center.dy, 1));

    // Com a explicação aberta, o tabuleiro sobe e o resultado entra embaixo.
    await tester.tap(find.byKey(ExerciseKeys.explainButton));
    await tester.pumpAndSettle();
    final raised = tester.getRect(find.byKey(ExerciseKeys.board));
    expect(raised.top, lessThan(board.top));
    expect(
      tester.getRect(find.byKey(ExerciseKeys.solution)).top,
      greaterThan(raised.bottom),
    );
  });

  testWidgets('T60: a dica traz uma fala comprida e o tabuleiro não sai do '
      'lugar', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    await pump(tester, 'e03');
    final before = tester.getRect(find.byKey(ExerciseKeys.board));
    await tester.tap(find.byKey(ExerciseKeys.hintButton));
    await tester.pumpAndSettle();
    expect(find.byKey(ExerciseKeys.speech), findsOneWidget);
    expect(tester.getRect(find.byKey(ExerciseKeys.board)), before);
    expect(
      tester.getRect(find.byKey(ExerciseKeys.speech)).bottom,
      lessThanOrEqualTo(before.top),
    );
  });
}
