import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/domain/use_cases/lesson_rules.dart';
import 'package:lucena/domain/use_cases/star_challenge_rules.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/time_display.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/school/widgets/star_challenges_screen.dart';
import 'package:lucena/ui/school/widgets/star_scoreboard.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/board_gestures.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeNow now;
  late FakeStarChallengeRepository progress;

  setUp(() {
    now = FakeNow(DateTime(2026, 10, 6, 10));
    progress = FakeStarChallengeRepository();
  });

  Future<SettingsCubit> settings() async {
    final cubit = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(cubit.close);
    await cubit.load();
    return cubit;
  }

  Future<StarChallengeCubit> pump(
    WidgetTester tester, {
    ChallengeLevel level = ChallengeLevel.easy,
    Size size = const Size(412, 915),
    double textScale = 1,
    bool systemBars = false,
    ThemeMode themeMode = ThemeMode.light,
    TextDirection direction = TextDirection.ltr,
    Locale locale = const Locale('en'),
  }) async {
    // Tela de celular: o tabuleiro ocupa a largura.
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (systemBars) {
      tester.view.viewPadding = const FakeViewPadding(top: 72, bottom: 96);
      tester.view.padding = const FakeViewPadding(top: 72, bottom: 96);
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final cubit = StarChallengeCubit(
      progress: progress,
      now: now,
      random: Random(5),
      tickEvery: const Duration(hours: 1),
    );
    addTearDown(cubit.close);
    await cubit.load(ChallengePiece.rook, level);
    await tester.pumpWidget(
      TestApp(
        themeMode: themeMode,
        locale: locale,
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: Directionality(
            textDirection: direction,
            child: const StarChallengeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  /// "Centralizar igual" (T65): a sobra meio a meio entre a barra do app e o
  /// rodapé (o topo da ação fixa, com a borda e a margem de 8; sem ação, o
  /// fim da área segura, [bottomInset] acima do fim da tela).
  void expectBalanced(
    WidgetTester tester,
    Size size, {
    double bottomInset = 0,
  }) {
    final appBar = tester.getRect(find.byType(AppBar)).bottom;
    final top = tester.getRect(find.byKey(StarChallengeKeys.blockTop)).top;
    final score = tester.getRect(find.byKey(StarChallengeKeys.scoreboard));
    final action = [
      StarChallengeKeys.goButton,
      StarChallengeKeys.retryButton,
    ].where((key) => find.byKey(key).evaluate().isNotEmpty);
    final footer = action.isEmpty
        ? size.height - bottomInset
        : tester.getRect(find.byKey(action.single)).top - 8 - 1;
    expect(
      top - appBar,
      closeTo(footer - score.bottom, 1),
      reason: 'vão de cima × vão de baixo',
    );
  }

  testWidgets('às cegas: a estrela vem pelo nome da casa, sem desenho', (
    tester,
  ) async {
    final cubit = await pump(tester, level: ChallengeLevel.named);
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();

    final star = cubit.state.star!;
    final boardWidget = tester.widget<Chessboard>(
      find.byKey(StarChallengeKeys.board),
    );
    expect(boardWidget.settings.enableCoordinates, isFalse);
    expect(boardWidget.settings.showLastMove, isFalse);
    final settings = tester
        .element(find.byKey(StarChallengeKeys.board))
        .read<SettingsCubit>()
        .state!
        .board;
    expect(settings.coordinates, isTrue);
    expect(settings.highlightLastMove, isTrue);
    expect(find.byKey(StarChallengeKeys.star(star.name)), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(StarChallengeKeys.starName)).data,
      star.name,
    );
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
  });

  testWidgets('"vai", a estrela aparece, pegar conta e o fim mostra a nota', (
    tester,
  ) async {
    final cubit = await pump(tester);
    expect(find.text('Rook challenge'), findsOneWidget);
    expect(find.text('Easy · Star hunt'), findsOneWidget);
    expect(tester.widget<AppBar>(find.byType(AppBar)).bottom, isNull);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byKey(StarChallengeKeys.levelChip),
      ),
      findsOneWidget,
    );
    expect(find.text('1:00'), findsOneWidget);
    final boardWidget = tester.widget<Chessboard>(
      find.byKey(StarChallengeKeys.board),
    );
    expect(boardWidget.settings.enableCoordinates, isTrue);
    expect(boardWidget.settings.showLastMove, isTrue);
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();

    final star = cubit.state.star!;
    expect(find.byKey(StarChallengeKeys.star(star.name)), findsOneWidget);
    final board = LessonRules.starsBoard(cubit.state.fen!);
    final from = StarChallengeRules.pieceSquare(board)!;
    final rect = tester.getRect(find.byKey(StarChallengeKeys.board));
    await tester.tapAt(squareCenter(rect, from.name));
    await tester.pump();
    await tester.tapAt(squareCenter(rect, star.name));
    await tester.pumpAndSettle();
    expect(cubit.state.points, greaterThan(0));
    // O painel embaixo do tabuleiro: a cor da estrela pega e o total.
    final kind = StarKind.values.firstWhere((k) => cubit.state.countOf(k) > 0);
    expect(
      tester
          .widget<Text>(find.byKey(StarChallengeKeys.kindCount(kind.name)))
          .data,
      '1',
    );
    expect(
      tester.widget<Text>(find.byKey(StarChallengeKeys.collected)).data,
      '${cubit.state.points}',
    );

    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
    expect(find.byKey(StarChallengeKeys.result), findsOneWidget);
    expect(find.text("Time's up!"), findsOneWidget);
    expect(find.text('New best!'), findsOneWidget);
    expect(
      tester.widget(find.byKey(StarChallengeKeys.retryButton)),
      isA<FilledButton>(),
    );
    expect(find.byKey(StarChallengeKeys.backButton), findsOneWidget);
  });

  testWidgets('o painel: estrelas de cada cor e o total de pontos', (
    tester,
  ) async {
    final scores = ValueNotifier<(Map<StarKind, int>, int)>((const {}, 0));
    addTearDown(scores.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: Scaffold(
          body: Center(
            child: ValueListenableBuilder(
              valueListenable: scores,
              builder: (context, value, _) =>
                  StarScoreboard(counts: value.$1, points: value.$2),
            ),
          ),
        ),
      ),
    );
    String text(Key key) => tester.widget<Text>(find.byKey(key)).data!;

    await tester.pumpAndSettle();
    for (final kind in StarKind.values) {
      expect(text(StarChallengeKeys.kindCount(kind.name)), '0');
    }
    expect(text(StarChallengeKeys.collected), '0');
    // Cada estrela diz quanto vale.
    expect(find.text('worth 3'), findsOneWidget);
    expect(find.text('worth 2'), findsOneWidget);
    expect(find.text('worth 1'), findsOneWidget);

    // Duas de bronze, uma de prata, três de ouro: 2 + 2 + 9 = 13.
    scores.value = (
      const {StarKind.bronze: 2, StarKind.silver: 1, StarKind.gold: 3},
      13,
    );
    await tester.pump();
    // No meio da animação o total ainda está subindo.
    await tester.pump(const Duration(milliseconds: 50));
    expect(text(StarChallengeKeys.collected), isNot('13'));
    await tester.pumpAndSettle();
    expect(text(StarChallengeKeys.kindCount('bronze')), '2');
    expect(text(StarChallengeKeys.kindCount('silver')), '1');
    expect(text(StarChallengeKeys.kindCount('gold')), '3');
    expect(text(StarChallengeKeys.collected), '13');
  });

  for (final size in [
    const Size(360, 740),
    const Size(360, 800),
    const Size(384, 832),
    const Size(393, 873),
    const Size(412, 915),
    const Size(414, 896),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'B6b $size fonte $scale: o bloco no meio em todos os estados',
        (tester) async {
          final cubit = await pump(
            tester,
            size: size,
            systemBars: true,
            textScale: scale,
          );
          final before = tester.getRect(find.byKey(StarChallengeKeys.board));
          expectBalanced(tester, size, bottomInset: 32);
          expect(before.width, greaterThanOrEqualTo(100));
          if (scale == 1) {
            final rule = find
                .descendant(
                  of: find.byKey(StarChallengeKeys.intro),
                  matching: find.byType(Text),
                )
                .last;
            expect(
              tester.getTopLeft(rule).dy + 20,
              lessThanOrEqualTo(before.top - 8),
            );
          }
          final action = tester.getRect(find.byKey(StarChallengeKeys.goButton));
          final score = tester.getRect(
            find.byKey(StarChallengeKeys.scoreboard),
          );
          expect(action.left, 16);
          expect(action.width, size.width - 32);
          expect(action.height, greaterThanOrEqualTo(52));
          expect(action.bottom, closeTo(size.height - 32 - 8, 1));
          expect(action.overlaps(before), isFalse);
          expect(action.overlaps(score), isFalse);
          expect(
            tester.widget<AppBar>(find.byType(AppBar)).centerTitle,
            isTrue,
          );
          expect(find.byKey(StarChallengeKeys.levelChip), findsOneWidget);
          await tester.tap(find.byKey(StarChallengeKeys.goButton));
          await tester.pumpAndSettle();
          final running = tester.getRect(find.byKey(StarChallengeKeys.board));
          expectBalanced(tester, size, bottomInset: 32);
          expect(running.width, greaterThanOrEqualTo(before.width));
          now.advance(const Duration(seconds: 61));
          cubit.tick();
          await tester.pumpAndSettle();
          final finished = tester.getRect(find.byKey(StarChallengeKeys.board));
          expectBalanced(tester, size, bottomInset: 32);
          final retry = tester.getRect(
            find.byKey(StarChallengeKeys.retryButton),
          );
          expect(retry, action);
          expect(retry.overlaps(finished), isFalse);
          expect(
            retry.overlaps(
              tester.getRect(find.byKey(StarChallengeKeys.scoreboard)),
            ),
            isFalse,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'contagem mantém arredondamento, pouco tempo, pausa e progresso',
    (tester) async {
      final cubit = await pump(tester);
      TimeDisplay timer() => tester.widget<TimeDisplay>(
        find.ancestor(
          of: find.byKey(StarChallengeKeys.timer),
          matching: find.byType(TimeDisplay),
        ),
      );
      expect(timer().type, TimeDisplayType.countdown);
      expect(timer().size, TimeDisplaySize.inline);
      expect(timer().value, '1:00');
      expect(timer().semanticsLabel, 'Time left: 1:00');
      expect(timer().state, TimeDisplayState.normal);
      await tester.tap(find.byKey(StarChallengeKeys.goButton));
      await tester.pumpAndSettle();
      expect(timer().state, TimeDisplayState.active);
      now.advance(const Duration(milliseconds: 50400));
      cubit.tick();
      await tester.pumpAndSettle();
      expect(timer().value, '0:10');
      expect(timer().state, TimeDisplayState.low);
      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, closeTo(1 - cubit.state.elapsedFraction, .0001));
      cubit.pause();
      await tester.pumpAndSettle();
      expect(timer().state, TimeDisplayState.paused);
      expect(timer().semanticsLabel, contains('Paused'));
      expect(timer().value, '0:10');
      cubit.resume();
      now.advance(const Duration(seconds: 10));
      cubit.tick();
      await tester.pumpAndSettle();
      expect(timer().value, '0:00');
      expect(find.byKey(StarChallengeKeys.retryButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'B6b: instrução pequena em fonte $scale não encolhe e rola inteira',
      (tester) async {
        await pump(
          tester,
          size: const Size(360, 640),
          systemBars: true,
          textScale: scale,
        );
        final board = tester.getRect(find.byKey(StarChallengeKeys.board));
        final score = tester.getRect(find.byKey(StarChallengeKeys.scoreboard));
        final intro = find.byKey(StarChallengeKeys.intro);
        final text = find
            .descendant(of: intro, matching: find.byType(Text))
            .last;
        final paragraph = tester.renderObject(text);
        // A transformação pintada preserva a fonte; não basta o TextStyle
        // original continuar normal sob um ShrinkToFit.
        final screen = tester.renderObject(
          find.byKey(StarChallengeKeys.screen),
        );
        expect(
          paragraph.getTransformTo(screen).getMaxScaleOnAxis(),
          closeTo(1, .01),
        );
        // O cartão não rola por dentro: quem rola é o espaço sobre o
        // tabuleiro, com o cartão inteiro.
        expect(
          find.descendant(
            of: intro,
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
        );
        final scroll = find
            .ancestor(of: intro, matching: find.byType(SingleChildScrollView))
            .first;
        final scrollable = find
            .descendant(of: scroll, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0));
        await tester.drag(scroll, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(position.pixels, closeTo(position.maxScrollExtent, 1));
        expect(
          tester.getBottomLeft(text).dy,
          lessThanOrEqualTo(tester.getBottomLeft(scroll).dy + 1),
        );
        // Rolado até o fim, a borda de baixo do cartão aparece.
        expect(
          tester.getRect(intro).bottom,
          lessThanOrEqualTo(tester.getBottomLeft(scroll).dy + 1),
        );
        expect(tester.getRect(find.byKey(StarChallengeKeys.board)), board);
        expect(tester.getRect(find.byKey(StarChallengeKeys.scoreboard)), score);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('o bloco fica no meio, entre a barra do app e o rodapé, no '
      'convite, jogando e no fim; ao tocar em Vai! ele recentra', (
    tester,
  ) async {
    final cubit = await pump(tester);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final ready = tester.getRect(find.byKey(StarChallengeKeys.board));
    expectBalanced(tester, screen);
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byKey(StarChallengeKeys.board));
    expectBalanced(tester, screen);
    expect(rect.width, greaterThanOrEqualTo(ready.width));
    expect(rect.top, isNot(closeTo(ready.top, 1)));
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
    expectBalanced(tester, screen);
  });

  testWidgets(
    'o placar acompanha o tabuleiro e fica estável jogando e no fim',
    (tester) async {
      final cubit = await pump(tester);
      Rect card() => tester.getRect(find.byKey(StarChallengeKeys.scoreboard));
      final ready = card();
      expect(find.byKey(StarChallengeKeys.intro), findsOneWidget);
      expect(find.text('Star hunt'), findsOneWidget);
      // Fica logo abaixo do tabuleiro.
      final board = tester.getRect(find.byKey(StarChallengeKeys.board));
      expect(ready.top, greaterThan(board.bottom));
      expect(ready.top - board.bottom, lessThan(16));
      await tester.tap(find.byKey(StarChallengeKeys.goButton));
      await tester.pumpAndSettle();
      expect(find.byKey(StarChallengeKeys.intro), findsNothing);
      final running = card();
      expect(running.width, ready.width);
      expect(running.height, closeTo(ready.height, .01));
      expect(
        running.top,
        greaterThan(tester.getRect(find.byKey(StarChallengeKeys.board)).bottom),
      );
      now.advance(const Duration(seconds: 61));
      cubit.tick();
      await tester.pumpAndSettle();
      expect(find.byKey(StarChallengeKeys.result), findsOneWidget);
      expect(card().size, running.size);
      expect(
        card().top - tester.getRect(find.byKey(StarChallengeKeys.board)).bottom,
        closeTo(8, .01),
      );
    },
  );

  testWidgets('o "Vai!" amplo no rodapé começa o jogo e some', (tester) async {
    final cubit = await pump(tester);
    final fab = find.byKey(StarChallengeKeys.goButton);
    expect(
      find.descendant(of: fab, matching: find.byType(FloatingActionButton)),
      findsNothing,
    );
    expect(tester.widget(fab), isA<FilledButton>());
    expect(find.text('Go!'), findsOneWidget);
    // Rodapé amplo e fixo.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final rect = tester.getRect(fab);
    expect(rect.width, screen.width - 32);
    expect(rect.height, 52);
    expect(rect.right, greaterThan(screen.width * 0.8));
    expect(rect.bottom, greaterThan(screen.height * 0.9));
    expect(cubit.state.phase, ChallengePhase.ready);

    await tester.tap(fab);
    await tester.pump();
    expect(cubit.state.phase, ChallengePhase.running);
    await tester.pumpAndSettle();
    expect(fab, findsNothing);
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
  });

  testWidgets('tela pequena com fonte 1,6: nada estoura e o "Vai!" não cobre '
      'o tabuleiro nem o placar', (tester) async {
    final cubit = await pump(
      tester,
      level: ChallengeLevel.hard,
      size: const Size(360, 640),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
    final fab = tester.getRect(find.byKey(StarChallengeKeys.goButton));
    final board = tester.getRect(find.byKey(StarChallengeKeys.board));
    final card = tester.getRect(find.byKey(StarChallengeKeys.scoreboard));
    expect(fab.overlaps(board), isFalse);
    expect(fab.overlaps(card), isFalse);
    final ready = card;
    await tester.tap(find.byKey(StarChallengeKeys.goButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final running = tester.getRect(find.byKey(StarChallengeKeys.scoreboard));
    expect(running.width, ready.width);
    expect(running.height, closeTo(ready.height, .01));
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final finishedScore = tester.getRect(
      find.byKey(StarChallengeKeys.scoreboard),
    );
    expect(finishedScore.size, running.size);
    // No fim, o "Jogar de novo" fica no mesmo rodapé, também sem cobrir.
    final retry = tester.getRect(find.byKey(StarChallengeKeys.retryButton));
    expect(
      retry.overlaps(tester.getRect(find.byKey(StarChallengeKeys.board))),
      isFalse,
    );
    expect(retry.overlaps(finishedScore), isFalse);
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final direction in TextDirection.values) {
      testWidgets('V2 cartões/resultado legíveis $mode $direction fonte2,4', (
        tester,
      ) async {
        final cubit = await pump(
          tester,
          size: const Size(360, 740),
          textScale: 2.4,
          themeMode: mode,
          direction: direction,
        );
        final introFinder = find.byKey(StarChallengeKeys.intro);
        final context = tester.element(introFinder);
        final colors = Theme.of(context).colorScheme;
        final intro = tester.widget<Card>(introFinder);
        final score = tester.widget<Card>(
          find.byKey(StarChallengeKeys.scoreboard),
        );
        // D2: um papel só para os dois cartões, também no escuro.
        expect(
          intro.color,
          mode == ThemeMode.light
              ? colors.surfaceContainerLowest
              : colors.surfaceContainerHigh,
        );
        expect(
          score.color,
          mode == ThemeMode.light
              ? colors.surfaceContainerLowest
              : colors.surfaceContainerHigh,
        );
        // 16 de respiro mais 1 da borda dourada, que o cartão não soma.
        expect(
          find.descendant(
            of: introFinder,
            matching: find.byWidgetPredicate(
              (w) => w is Padding && w.padding == const EdgeInsets.all(17),
            ),
          ),
          findsWidgets,
        );
        await tester.tap(find.byKey(StarChallengeKeys.goButton));
        await tester.pumpAndSettle();
        now.advance(const Duration(seconds: 61));
        cubit.tick();
        await tester.pumpAndSettle();
        final result = find.byKey(StarChallengeKeys.result);
        final text = find
            .descendant(of: result, matching: find.byType(Text))
            .first;
        final screen = tester.renderObject(
          find.byKey(StarChallengeKeys.screen),
        );
        expect(
          tester.renderObject(text).getTransformTo(screen).getMaxScaleOnAxis(),
          closeTo(1, .01),
        );
        final scroll = find
            .ancestor(of: result, matching: find.byType(SingleChildScrollView))
            .first;
        await tester.drag(scroll, const Offset(0, -1000));
        await tester.pumpAndSettle();
        expect(
          tester.getBottomLeft(result).dy,
          lessThanOrEqualTo(tester.getBottomLeft(scroll).dy + 1),
        );
        final retry = tester.getRect(find.byKey(StarChallengeKeys.retryButton));
        expect(
          retry.overlaps(
            tester.getRect(find.byKey(StarChallengeKeys.scoreboard)),
          ),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a lista: seis peças, três níveis, a melhor marca', (
    tester,
  ) async {
    progress = FakeStarChallengeRepository(
      const StarChallengeProgress().withBest(
        ChallengePiece.knight,
        ChallengeLevel.hard,
        7,
      ),
    );
    final cubit = StarChallengesCubit(progress: progress);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: await settings(),
        child: BlocProvider.value(
          value: cubit,
          child: const StarChallengesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(StarChallengeKeys.listScreen), findsOneWidget);
    // A lista monta por partes: rola até cada peça.
    for (final piece in ChallengePiece.values) {
      await tester.scrollUntilVisible(
        find.byKey(StarChallengeKeys.challenge(piece.name, 'easy')),
        200,
      );
      expect(
        find.byKey(StarChallengeKeys.challenge(piece.name, 'hard')),
        findsOneWidget,
      );
    }
    await tester.scrollUntilVisible(
      find.byKey(StarChallengeKeys.challenge('knight', 'hard')),
      -200,
    );
    expect(find.text('Best: 7'), findsOneWidget);
  });
}
