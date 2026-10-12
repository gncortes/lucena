import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/endgames/view_models/exercise_cubit.dart';
import 'package:lucena/ui/endgames/widgets/exercise_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_wiki.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<ExerciseCubit> pump(
    WidgetTester tester,
    String exercise, {
    FakeWebPages? webPages,
    FakeNow? now,
    FakeEndgameLessonRepository? lessons,
    EndgameProgress progress = const EndgameProgress(),
  }) async {
    final cubit = ExerciseCubit(
      now: now ?? FakeNow(DateTime.utc(2026, 10, 11)),
      lessons: lessons ?? FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(progress),
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
        webPages: webPages,
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

  testWidgets('T65: lifecycle congela o cronômetro do exercício', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 11));
    final cubit = await pump(tester, 'e03', now: now);
    now.advance(const Duration(seconds: 8));
    await tester.pump(const Duration(milliseconds: 250));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    now.advance(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(cubit.elapsed, const Duration(seconds: 8));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    now.advance(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(cubit.elapsed, const Duration(seconds: 10));
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets('B6b $size: exercício no centro real com e sem dica', (
      tester,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1
        ..viewPadding = const FakeViewPadding(top: 24, bottom: 32)
        ..padding = const FakeViewPadding(top: 24, bottom: 32);
      addTearDown(tester.view.reset);
      await pump(tester, 'e03');
      final board = tester.getRect(find.byKey(ExerciseKeys.board));
      expect(board.center.dy, closeTo((24 + size.height - 32) / 2, 1));
      expect(board.width, greaterThanOrEqualTo(200));
      await tester.tap(find.byKey(ExerciseKeys.hintButton));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(ExerciseKeys.board)), board);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o enunciado, as estrelas e a dica conceitual sem resposta', (
    tester,
  ) async {
    await pump(tester, 'e03');
    expect(find.text('Exercise 3 of 3'), findsOneWidget);
    // O Viktor só entra quando fala.
    expect(find.byKey(ExerciseKeys.speech), findsNothing);
    expect(find.byKey(ExerciseKeys.stars), findsOneWidget);

    await tester.tap(find.byKey(ExerciseKeys.hintButton));
    await tester.pumpAndSettle();
    expect(find.text('The hard one.\n\nSame idea.'), findsOneWidget);
    final board = tester.widget<Chessboard>(find.byKey(ExerciseKeys.board));
    expect(
      board.shapes.whereType<Arrow>().any(
        (arrow) => arrow.orig.name == 'c1' && arrow.dest.name == 'c4',
      ),
      isFalse,
    );
  });

  for (final goal in PositionGoal.values) {
    testWidgets('objetivo ${goal.name} permanece após erro silencioso', (
      tester,
    ) async {
      final sample = FakeEndgameLessonRepository.sample.lessons.first;
      final exercise = sample.exercise('e03')!;
      final lessons = FakeEndgameLessonRepository(
        trail: EndgameTrail(
          modules: [
            EndgameModule(
              id: sample.module,
              lessons: [
                EndgameLesson(
                  id: sample.id,
                  module: sample.module,
                  lesson: sample.lesson,
                  exercises: [
                    Exercise(
                      id: exercise.id,
                      stars: exercise.stars,
                      fen: exercise.fen,
                      goal: goal,
                      line: exercise.line,
                    ),
                  ],
                  passScore: sample.passScore,
                  keyPositions: sample.keyPositions,
                  practice: sample.practice,
                ),
              ],
            ),
          ],
        ),
      );
      final cubit = await pump(tester, 'e03', lessons: lessons);
      final expected = goal == PositionGoal.win
          ? 'White to play and win'
          : 'White to play and hold';
      expect(tester.widget<Text>(find.byKey(ExerciseKeys.goal)).data, expected);
      expect(find.byKey(ExerciseKeys.speech), findsNothing);

      await move(tester, 'c1', 'c2');
      expect(cubit.state.mistakes, 1);
      expect(cubit.state.phase, ExercisePhase.active);
      expect(cubit.state.fen, exercise.fen);
      expect(cubit.state.speech, isNull);
      expect(find.byKey(ExerciseKeys.speech), findsNothing);
      expect(tester.widget<Text>(find.byKey(ExerciseKeys.goal)).data, expected);
    });
  }

  testWidgets('lance errado volta; o certo resolve e mostra a nota', (
    tester,
  ) async {
    final cubit = await pump(tester, 'e03');
    await move(tester, 'c1', 'c2');
    expect(cubit.state.mistakes, 1);
    expect(cubit.state.fen, FakeEndgameLessonRepository.lucenaFen);

    // Antes de resolver, a vez e o objetivo logo abaixo do tabuleiro.
    expect(
      tester.widget<Text>(find.byKey(ExerciseKeys.goal)).data,
      'White to play and win',
    );

    await move(tester, 'c1', 'c4');
    expect(find.byKey(ExerciseKeys.solved), findsOneWidget);
    // Houve erro: sem "Resolvido!" nem o selo de acerto limpo (fala o Viktor).
    expect(find.text('Solved!'), findsNothing);
    expect(find.byKey(ExerciseKeys.correct), findsNothing);
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
    // Sem linha de "Solução": a fala do Viktor já explica.
    expect(find.byKey(ExerciseKeys.solution), findsNothing);
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
      'tabuleiro no centro do espaço útil, a vez embaixo e o cronômetro no canto '
      'inferior direito; resolvido, o tabuleiro fica e o resultado entra '
      'embaixo', (tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(400, 900);
    addTearDown(tester.view.reset);
    await pump(tester, 'e03');
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    final goal = tester.getRect(find.byKey(ExerciseKeys.goal));
    expect(board.center.dx, closeTo(200, 1));
    // No centro do espaço útil (T64): entre a barra do app e o rodapé.
    final footer = tester.getRect(
      find
          .ancestor(
            of: find.byKey(ExerciseKeys.timer),
            matching: find.byType(AnimatedSwitcher),
          )
          .first,
    );
    expect(board.center.dy, closeTo(450, 1));
    expect(board.bottom, lessThanOrEqualTo(footer.top));
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
    if (find.byKey(ExerciseKeys.solvedStacked).evaluate().isEmpty) {
      expect(explain.center.dy, closeTo(next.center.dy, 1));
    } else {
      expect(explain.bottom, lessThanOrEqualTo(next.top));
    }

    // A explicação entra embaixo sem alterar a geometria do tabuleiro.
    await tester.tap(find.byKey(ExerciseKeys.explainButton));
    await tester.pumpAndSettle();
    final raised = tester.getRect(find.byKey(ExerciseKeys.board));
    expect(raised, board);
    expect(
      tester.getRect(find.byKey(ExerciseKeys.speech)).top,
      greaterThan(raised.bottom),
    );
  });

  for (final (width, scale) in [(400.0, 1.0), (320.0, 1.3)]) {
    testWidgets('T65 ${width}dp ${scale}x: acerto limpo mostra "Correct!" sob '
        'o tabuleiro e "Ver explicação" legível, do tamanho do próximo', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, 800);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, 'e03');
      expect(find.byKey(ExerciseKeys.correct), findsNothing);

      await move(tester, 'c1', 'c4');
      expect(tester.takeException(), isNull);
      // O selo de acerto, abaixo do tabuleiro e sem cobri-lo.
      final board = tester.getRect(find.byKey(ExerciseKeys.board));
      final badge = tester.getRect(find.byKey(ExerciseKeys.correct));
      expect(find.text('Correct!'), findsOneWidget);
      expect(badge.top, greaterThanOrEqualTo(board.bottom));
      expect(badge.center.dx, closeTo(width / 2, 1));

      // O texto do botão não encolhe (antes um FittedBox o levava a ~10 px).
      final explain = find.byKey(ExerciseKeys.explainButton);
      expect(
        find.descendant(of: explain, matching: find.byType(FittedBox)),
        findsNothing,
      );
      final label = find.descendant(
        of: explain,
        matching: find.text('See explanation'),
      );
      final next = tester.getRect(find.byKey(ExerciseKeys.nextButton));
      final explainRect = tester.getRect(explain);
      expect(tester.getSize(label).height, greaterThanOrEqualTo(14 * scale));
      expect(explainRect.height, greaterThanOrEqualTo(48));
      final paragraph = tester.renderObject<RenderParagraph>(label);
      expect(paragraph.didExceedMaxLines, isFalse);
      // Lado a lado só quando os dois cabem inteiros em metades (a fonte de
      // teste é larga: aqui costuma empilhar); senão, um sobre o outro.
      if (find.byKey(ExerciseKeys.solvedStacked).evaluate().isNotEmpty) {
        expect(explainRect.bottom, lessThanOrEqualTo(next.top));
      } else {
        expect(explainRect.center.dy, closeTo(next.center.dy, 1));
        expect(explainRect.width, closeTo(next.width, 0.5));
        expect(explainRect.height, closeTo(next.height, 0.5));
      }

      // Com a explicação aberta, o selo sai e a fala ocupa o lugar.
      await tester.tap(explain);
      await tester.pumpAndSettle();
      expect(find.byKey(ExerciseKeys.correct), findsNothing);
    });
  }

  testWidgets('T65: com reduzir movimento, o selo aparece já parado', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester, 'e03');
    final board = tester.getRect(find.byKey(ExerciseKeys.board));
    await tester.tapAt(squareCenter(board, 'c1'));
    await tester.pump();
    await tester.tapAt(squareCenter(board, 'c4'));
    // Sem esperar a animação: no primeiro quadro em que aparece, já inteiro.
    for (var i = 0; i < 10; i++) {
      if (find.byKey(ExerciseKeys.correct).evaluate().isNotEmpty) break;
      await tester.pump();
    }
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byKey(ExerciseKeys.correct),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  for (final size in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets('B5 $size: jogar, dica e explicação preservam o tabuleiro', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size
        ..viewPadding = const FakeViewPadding(top: 52, bottom: 24)
        ..padding = const FakeViewPadding(top: 52, bottom: 24);
      addTearDown(tester.view.reset);
      await pump(tester, 'e03');
      final board = tester.getRect(find.byKey(ExerciseKeys.board));
      expect(board.center.dy, closeTo((52 + size.height - 24) / 2, 1));
      expect(board.width, greaterThanOrEqualTo(200));
      expect(find.byKey(ExerciseKeys.speech), findsNothing);
      await tester.tap(find.byKey(ExerciseKeys.hintButton));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(ExerciseKeys.board)), board);
      expect(
        tester.getRect(find.byKey(ExerciseKeys.scroll)).top,
        greaterThan(board.bottom),
      );
      // Com o balão completo (retrato e cabeçalho em cima), a fala começa
      // à vista, acima dos botões que flutuam sobre a folha.
      expect(
        tester.getRect(find.byKey(ExerciseKeys.speech)).top,
        lessThanOrEqualTo(
          tester.getRect(find.byKey(ExerciseKeys.hintButton)).top,
        ),
      );
      await tester.tapAt(
        tester.getTopLeft(find.byKey(ExerciseKeys.scroll)) +
            const Offset(40, 12),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(ExerciseKeys.hintButton).hitTestable(), findsNothing);
      expect(find.byKey(ExerciseKeys.closeSheet).hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(ExerciseKeys.closeSheet));
      await tester.pumpAndSettle();
      await move(tester, 'c1', 'c4');
      // Depois de pedir dica, a correção já aparece ao resolver.
      expect(find.byKey(ExerciseKeys.speech), findsOneWidget);
      expect(tester.getRect(find.byKey(ExerciseKeys.board)), board);
      expect(
        tester.getRect(find.byKey(ExerciseKeys.scroll)).top,
        greaterThan(board.bottom),
      );
      expect(tester.takeException(), isNull);
    });
  }

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
      tester.getRect(find.byKey(ExerciseKeys.speech)).top,
      greaterThanOrEqualTo(before.bottom),
    );
  });

  testWidgets('treino livre: "Analisar no Lichess" abre a posição dentro do '
      'app e o X volta ao exercício', (tester) async {
    final pages = FakeWebPages(title: 'Analysis board • lichess.org');
    await pump(
      tester,
      'e03',
      webPages: pages,
      // Todos resolvidos: a nota fechada põe o botão do Lichess na tela.
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            stars: {'e01': 1, 'e02': 2, 'e03': 1},
          ),
        },
      ),
    );
    await tester.ensureVisible(find.byKey(ExerciseKeys.lichessButton));
    await tester.tap(find.byKey(ExerciseKeys.lichessButton));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsOneWidget);
    expect(pages.opened.single.host, 'lichess.org');
    expect(find.text('Analysis board • lichess.org'), findsOneWidget);

    await tester.tap(find.byKey(ExternalPageKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsNothing);
    expect(find.byKey(ExerciseKeys.lichessButton), findsOneWidget);
  });
}
