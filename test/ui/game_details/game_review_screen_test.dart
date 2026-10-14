import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_review.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/game_details_keys.dart';
import 'package:lucena/ui/game_details/view_models/game_details_cubit.dart';
import 'package:lucena/ui/game_details/widgets/game_details_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_school_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;

  // Dama e rei contra rei: as brancas deixam passar o mate (Qg2) e só depois
  // dão o mate (Qg7#).
  const start = '7k/8/5K2/8/8/8/8/6Q1 w - - 0 1';
  final game = Attempt(
    positionId: 'basic.queen.0001',
    playedAt: DateTime.utc(2026, 10, 6, 12),
    outcome: AttemptOutcome.win,
    fulfilled: true,
    opponent: OpponentKind.maia,
    opponentLevel: 1000,
    startFen: start,
    moves: const ['g1g2', 'h8h7', 'g2g7'],
    userSide: Side.white,
    endReason: GameEndReason.checkmate,
  );

  EngineLine line(String uci, {int? cp, int? mate}) => EngineLine(
    score: EngineScore(centipawns: cp, mate: mate),
    moves: [uci],
  );

  setUp(() {
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository()
      ..answer[start] = [line('g1g7', mate: 1), line('f6f7', mate: 2)];
  });

  Future<GameDetailsCubit> pump(
    WidgetTester tester,
    int id, {
    Size? viewport,
    FakeSettingsRepository? preferences,
  }) async {
    tester.view.physicalSize = viewport ?? const Size(1080, 5000);
    tester.view.devicePixelRatio = viewport == null ? 2.625 : 1;
    addTearDown(tester.view.reset);
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      characters: FakeCharacterRepository(),
      analysis: analysis,
      reviews: FakeGameReviewRepository(),
      lessons: FakeLessonRepository(
        texts: const LessonTexts({
          'review.stories': [
            'A story about Morphy.',
            'A story about Capablanca.',
          ],
        }),
      ),
      // Sem preferências gravadas, a engine abre desligada.
      settings: preferences,
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      preferences ?? FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  String text(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data ?? '';

  testWidgets('revisar: o resumo com a precisão, os símbolos na tabela e a '
      'anotação no tabuleiro', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);
    expect(find.byKey(GameDetailsKeys.reviewSummary), findsOneWidget);

    await tester.tap(find.byKey(GameDetailsKeys.reviewButton));
    await tester.pumpAndSettle();

    expect(find.byKey(GameDetailsKeys.reviewSummary), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.accuracyWhite), findsOneWidget);
    // Qg2, com o mate na mão, deixou escapar o mate em um lance: a engine de
    // mentira avalia o resto pelo material (+9), ainda ganho.
    expect(find.byKey(GameDetailsKeys.moveQuality(0)), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.moveQuality(2)), findsOneWidget);
    final board = tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board));
    expect(board.annotations, isNotEmpty);
  });

  testWidgets('navegar: os botões andam lance a lance e a explicação '
      'acompanha', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    // A Rápida terminou; o usuário pode voltar ao início.
    cubit.first();
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, -1);
    await tester.tap(find.byKey(GameDetailsKeys.last));
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, 2);

    await tester.tap(find.byKey(GameDetailsKeys.first));
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, -1);
    expect(find.text('Starting position'), findsOneWidget);

    await tester.tap(find.byKey(GameDetailsKeys.next));
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, 0);

    await tester.tap(find.byKey(GameDetailsKeys.last));
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, 2);

    await tester.tap(find.byKey(GameDetailsKeys.previous));
    await tester.pumpAndSettle();
    expect(cubit.state.shownIndex, 1);
  });

  testWidgets('depois de um erro, a explicação diz o lance que era melhor e '
      'a seta mostra', (tester) async {
    // Depois de Qg2 a engine (de mentira) diz que está igual: erro grave.
    analysis.answer['7k/8/5K2/8/8/8/6Q1/8 b - - 1 1'] = [line('h8h7', cp: 0)];
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    await tester.tap(find.byKey(GameDetailsKeys.reviewButton));
    await tester.pumpAndSettle();
    expect(cubit.state.review!.moves.first.quality, MoveQuality.blunder);

    await tester.tap(find.byKey(GameDetailsKeys.move(0)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Blunder'), findsWidgets);
    expect(find.textContaining('Best was'), findsOneWidget);
    final board = tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board));
    expect(board.shapes.whereType<Arrow>().single.dest, Square.g7);
    expect(find.byKey(GameDetailsKeys.explanation), findsOneWidget);
  });

  testWidgets('a engine ligada mostra três linhas e a seta do melhor lance', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);
    await tester.tap(find.byKey(GameDetailsKeys.first));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(GameDetailsKeys.engineButton));
    await tester.pumpAndSettle();

    expect(find.byKey(GameDetailsKeys.engineLines), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.engineLine(0)), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.engineLine(1)), findsOneWidget);
    // A primeira linha e a barra mostram o mate.
    expect(find.text('M1'), findsNWidgets(2));
    final board = tester.widget<Chessboard>(find.byKey(GameDetailsKeys.board));
    expect(board.shapes.whereType<Arrow>().single.dest, Square.g7);
    expect(text(tester, GameDetailsKeys.result), contains('Win'));
  });

  testWidgets('a legenda no fim explica os símbolos e, depois da revisão, '
      'conta os lances de cada lado', (tester) async {
    final id = await progress.addAttempt(game);
    await pump(tester, id);
    expect(find.byKey(GameDetailsKeys.legend), findsOneWidget);
    expect(find.text('The move Stockfish would play'), findsOneWidget);
    expect(find.textContaining('Lichess'), findsNothing);
    expect(
      find.byKey(GameDetailsKeys.count('best', white: true)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(GameDetailsKeys.reviewButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(GameDetailsKeys.count('best', white: true)),
      findsOneWidget,
    );
  });

  testWidgets('barra visível só com a engine ligada: abre ligada pela '
      'preferência, o botão desliga (a barra some) e liga de novo; a escolha '
      'fica gravada', (tester) async {
    final id = await progress.addAttempt(game);
    final preferences = FakeSettingsRepository(const AppSettings());
    final cubit = await pump(tester, id, preferences: preferences);
    await tester.tap(find.byKey(GameDetailsKeys.first));
    await tester.pumpAndSettle();
    expect(cubit.state.engine, isTrue);
    expect(find.byKey(GameDetailsKeys.evalBar), findsOneWidget);
    expect(find.byKey(GameDetailsKeys.engineLines), findsOneWidget);
    final chip = tester.widget<FilterChip>(
      find.byKey(GameDetailsKeys.engineButton),
    );
    expect(chip.selected, isTrue);
    // A barra e a primeira linha mostram o mate.
    expect(find.text('M1'), findsNWidgets(2));
    final withBar = tester.getSize(find.byKey(GameDetailsKeys.board)).width;

    await tester.tap(find.byKey(GameDetailsKeys.engineButton));
    await tester.pump();
    // A barra sai deslizando: no meio, ainda está lá.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(GameDetailsKeys.evalBar), findsOneWidget);
    await tester.pumpAndSettle();
    expect(cubit.state.engine, isFalse);
    expect(find.byKey(GameDetailsKeys.evalBar), findsNothing);
    expect(find.byKey(GameDetailsKeys.engineLines), findsNothing);
    expect(
      tester
          .widget<FilterChip>(find.byKey(GameDetailsKeys.engineButton))
          .selected,
      isFalse,
    );
    // O tabuleiro ocupa o lugar da barra.
    expect(
      tester.getSize(find.byKey(GameDetailsKeys.board)).width,
      greaterThan(withBar),
    );
    expect(preferences.settings.evalBar, isFalse);

    await tester.tap(find.byKey(GameDetailsKeys.engineButton));
    await tester.pumpAndSettle();
    expect(cubit.state.engine, isTrue);
    expect(find.byKey(GameDetailsKeys.evalBar), findsOneWidget);
    expect(preferences.settings.evalBar, isTrue);
  });

  testWidgets('preferência desligada: abre sem a barra e sem as linhas', (
    tester,
  ) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(
      tester,
      id,
      preferences: FakeSettingsRepository(const AppSettings(evalBar: false)),
    );
    expect(cubit.state.engine, isFalse);
    expect(find.byKey(GameDetailsKeys.evalBar), findsNothing);
    expect(find.byKey(GameDetailsKeys.engineLines), findsNothing);
  });

  testWidgets('ao abrir, com a Rápida rodando e o Viktor contando a '
      'história: a folha fica recolhida, com o tabuleiro e a navegação à '
      'vista e o ✕ escondido', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final id = await progress.addAttempt(game);
    final hold = Completer<void>();
    analysis.hold = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      characters: FakeCharacterRepository(),
      analysis: analysis,
      reviews: FakeGameReviewRepository(),
      lessons: FakeLessonRepository(
        texts: const LessonTexts({
          'review.stories': ['A story about Morphy.'],
        }),
      ),
      settings: FakeSettingsRepository(const AppSettings()),
    );
    addTearDown(cubit.close);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    // Como no app: a tela abre carregando e a partida chega depois.
    unawaited(cubit.load());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(cubit.state.reviewing, isTrue);
    expect(find.byKey(GameDetailsKeys.story), findsOneWidget);
    final sheetTop = tester.getTopLeft(find.byKey(GameDetailsKeys.panel)).dy;
    final board = tester.getRect(find.byKey(GameDetailsKeys.board));
    expect(board.bottom, lessThanOrEqualTo(sheetTop));
    for (final key in [
      GameDetailsKeys.first,
      GameDetailsKeys.previous,
      GameDetailsKeys.next,
      GameDetailsKeys.last,
      GameDetailsKeys.engineButton,
    ]) {
      expect(find.byKey(key).hitTestable(), findsOneWidget);
      expect(tester.getRect(find.byKey(key)).bottom, lessThan(sheetTop));
    }
    expect(find.byKey(GameDetailsKeys.closeSheet).hitTestable(), findsNothing);
    hold.complete();
    analysis.hold = null;
    await tester.pumpAndSettle();
  });

  testWidgets('ao abrir sem revisão guardada, a Rápida começa sozinha (sem '
      'tocar em nada); com revisão guardada, nada é refeito', (tester) async {
    final id = await progress.addAttempt(game);
    final hold = Completer<void>();
    analysis.hold = hold;
    addTearDown(() {
      if (!hold.isCompleted) hold.complete();
    });
    final cubit = GameDetailsCubit(
      id,
      progress: progress,
      analysis: analysis,
      reviews: FakeGameReviewRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const GameDetailsScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(cubit.state.reviewing, isTrue);
    expect(
      cubit.state.reviewWeight,
      GameDetailsCubit.reviewWeights[ReviewSpeed.quick],
    );
    expect(find.byKey(GameDetailsKeys.reviewProgress), findsOneWidget);
    hold.complete();
    analysis.hold = null;
    await tester.pumpAndSettle();
    expect(find.byKey(GameDetailsKeys.accuracyWhite), findsOneWidget);

    // Reaberta com a revisão guardada: a engine não é chamada de novo.
    final saved = cubit.state.review!;
    final reviews = FakeGameReviewRepository()..reviews[id] = saved;
    analysis.requests.clear();
    final again = GameDetailsCubit(
      id,
      progress: progress,
      analysis: analysis,
      reviews: reviews,
    );
    addTearDown(again.close);
    await again.load();
    await tester.pumpAndSettle();
    expect(again.state.reviewing, isFalse);
    expect(again.state.review, same(saved));
    expect(analysis.requests, isEmpty);
  });

  testWidgets('revisão rápida feita: ela aparece marcada e sem toque; a '
      'média e a profunda continuam', (tester) async {
    final id = await progress.addAttempt(game);
    final cubit = await pump(tester, id);
    await cubit.review(speed: ReviewSpeed.quick);
    await tester.pumpAndSettle();

    final quick = tester.widget<ButtonStyleButton>(
      find.byKey(GameDetailsKeys.reviewQuick),
    );
    expect(quick.onPressed, isNull);
    expect(
      find.descendant(
        of: find.byKey(GameDetailsKeys.reviewQuick),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ButtonStyleButton>(find.byKey(GameDetailsKeys.reviewButton))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'ao abrir: precisão da Rápida e opções Média/Profunda sob demanda',
    (tester) async {
      final id = await progress.addAttempt(game);
      final cubit = await pump(tester, id);
      expect(find.byKey(GameDetailsKeys.reviewQuick), findsOneWidget);
      expect(find.byKey(GameDetailsKeys.reviewButton), findsOneWidget);
      expect(find.byKey(GameDetailsKeys.reviewDeep), findsOneWidget);
      expect(find.byKey(GameDetailsKeys.accuracyWhite), findsOneWidget);

      await tester.tap(find.byKey(GameDetailsKeys.reviewDeep));
      await tester.pumpAndSettle();

      expect(
        cubit.state.review!.depth,
        GameDetailsCubit.reviewWeights[ReviewSpeed.deep],
      );
      expect(find.byKey(GameDetailsKeys.accuracyWhite), findsOneWidget);
    },
  );

  for (final viewport in [
    const Size(360, 640),
    const Size(360, 800),
    const Size(412, 915),
  ]) {
    testWidgets('progresso visível na folha recolhida em $viewport', (
      tester,
    ) async {
      final id = await progress.addAttempt(game);
      final cubit = await pump(tester, id, viewport: viewport);
      final hold = Completer<void>();
      analysis.hold = hold;
      addTearDown(() {
        if (!hold.isCompleted) hold.complete();
      });

      unawaited(cubit.review());
      await tester.pump(const Duration(seconds: 3));

      expect(cubit.state.reviewing, isTrue);
      final indicator = find.descendant(
        of: find.byKey(GameDetailsKeys.reviewProgress),
        matching: find.byType(LinearProgressIndicator),
      );
      expect(indicator.hitTestable(), findsOneWidget);
      expect(tester.getRect(indicator).bottom, lessThan(viewport.height));

      hold.complete();
      analysis.hold = null;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'o Viktor conta uma história; pronta a revisão, ela fica sem ✕ no balão',
    (tester) async {
      final id = await progress.addAttempt(game);
      final cubit = await pump(tester, id);
      analysis.hold = Completer<void>();

      await tester.tap(find.byKey(GameDetailsKeys.reviewButton));
      await tester.pump(const Duration(seconds: 3));

      expect(cubit.state.reviewing, isTrue);
      await tester.drag(
        find.byKey(GameDetailsKeys.panel),
        const Offset(0, 3000),
      );
      await tester.pump();
      expect(find.byKey(GameDetailsKeys.story), findsOneWidget);
      expect(find.textContaining('A story about'), findsOneWidget);

      analysis.hold!.complete();
      analysis.hold = null;
      await tester.pumpAndSettle();
      expect(cubit.state.reviewing, isFalse);
      expect(find.byKey(GameDetailsKeys.story), findsOneWidget);

      // Sem ✕ por cima da fala: o fechar é o da folha.
      expect(
        find.descendant(
          of: find.byKey(GameDetailsKeys.story),
          matching: find.byIcon(Icons.close_rounded),
        ),
        findsNothing,
      );
    },
  );
}
