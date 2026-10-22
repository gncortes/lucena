import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/star_challenge.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/star_challenge_cubit.dart';
import 'package:lucena/ui/school/widgets/star_challenge_screen.dart';
import 'package:lucena/ui/school/widgets/star_challenge_ui.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_star_challenge_repository.dart';
import '../../../testing/goldens/golden_harness.dart';
import '../../../testing/test_app.dart';

/// T65: o Desafio das Estrelas contra o canvas V2
/// (`PropV2DesafioEstrelas{Pronto,Jogo}{,P360}`), com a fonte do app (Roboto)
/// para as medidas baterem com as do aparelho.
void main() {
  late FakeNow now;

  setUpAll(Goldens.loadFonts);
  setUp(() => now = FakeNow(DateTime(2026, 10, 12, 10)));

  Future<StarChallengeCubit> pump(
    WidgetTester tester, {
    required Size size,
    ChallengeLevel level = ChallengeLevel.easy,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('pt'),
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = StarChallengeCubit(
      progress: FakeStarChallengeRepository(),
      now: now,
      random: Random(5),
      tickEvery: const Duration(hours: 1),
    );
    addTearDown(cubit.close);
    await cubit.load(ChallengePiece.rook, level);
    // A tela entra por cima de outra, como no app: assim a barra tem o
    // "voltar".
    await tester.pumpWidget(
      TestApp(
        themeMode: themeMode,
        locale: locale,
        settingsCubit: settings,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BlocProvider.value(
                      value: cubit,
                      child: const StarChallengeScreen(),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    return cubit;
  }

  Rect rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

  Future<void> finish(WidgetTester tester, StarChallengeCubit cubit) async {
    now.advance(const Duration(seconds: 61));
    cubit.tick();
    await tester.pumpAndSettle();
  }

  /// "Centralizar igual": o bloco (relógio, convite ou resultado, tabuleiro e
  /// placar) com a sobra meio a meio entre a barra do app e o rodapé (o topo
  /// da ação fixa, com a borda e a margem de 8; sem ação, o fim da tela).
  void expectBalanced(WidgetTester tester, Size size) {
    final appBar = tester.getRect(find.byType(AppBar)).bottom;
    final top = rectOf(tester, StarChallengeKeys.blockTop).top;
    final score = rectOf(tester, StarChallengeKeys.scoreboard).bottom;
    final action = [
      StarChallengeKeys.goButton,
      StarChallengeKeys.retryButton,
    ].where((key) => find.byKey(key).evaluate().isNotEmpty);
    final footer = action.isEmpty
        ? size.height
        : rectOf(tester, action.single).top - 8 - 1;
    final above = top - appBar;
    final below = footer - score;
    expect(above, greaterThanOrEqualTo(-1));
    expect(above, closeTo(below, 1), reason: 'vão de cima × vão de baixo');
  }

  // As medidas do contrato, sem insets, fonte 1,0, pt, Fácil. O cartão do
  // convite tem a altura do conteúdo: 112 dp com o texto em duas linhas (o
  // artboard reserva 108, ver "Ajuste no canvas" no contrato). O tabuleiro
  // ocupa a largura e o bloco fica no meio do que sobra (T65, "Centralizar
  // igual"): ao tocar em Vai!, o convite e o botão somem e o bloco recentra.
  for (final size in [
    const Size(360, 740),
    const Size(412, 917),
    const Size(448, 997),
  ]) {
    testWidgets('V2 $size: medidas do Pronto, Jogando, Pausa e Fim', (
      tester,
    ) async {
      final cubit = await pump(tester, size: size);
      expect(tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight, 72);
      expect(find.text('Desafio da torre'), findsOneWidget);
      expect(find.text('Fácil · Caça às estrelas'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byKey(StarChallengeKeys.levelChip),
        ),
        findsOneWidget,
      );
      // A contagem no topo do bloco: 40 dp.
      final timer = rectOf(tester, StarChallengeKeys.timer);
      final block = rectOf(tester, StarChallengeKeys.blockTop);
      expect(timer.top, closeTo(block.top + 8, 1));
      expect(timer.height, closeTo(24, 1));

      final board = rectOf(tester, StarChallengeKeys.board);
      final intro = rectOf(tester, StarChallengeKeys.intro);
      final score = rectOf(tester, StarChallengeKeys.scoreboard);
      final go = rectOf(tester, StarChallengeKeys.goButton);
      expectBalanced(tester, size);
      expect(board.width, size.width);
      expect(board.center.dx, closeTo(size.width / 2, .01));
      // O convite: margem 16, 8 dp acima do tabuleiro (a altura do cartão cabe: o ícone é de 24), altura do conteúdo.
      expect(intro.left, 16);
      expect(intro.width, size.width - 32);
      expect(intro.height, closeTo(114, 1));
      expect(intro.top, greaterThanOrEqualTo(timer.bottom + 6 - 1));
      expect(intro.bottom, closeTo(board.top - 8, 1));
      expect(
        find.descendant(
          of: find.byKey(StarChallengeKeys.intro),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      // O placar: 8 dp sob o tabuleiro, margem 16, 68 dp.
      expect(score.top - board.bottom, closeTo(8, 1));
      expect(score.height, closeTo(68, 1));
      expect(score.left, 16);
      expect(score.width, size.width - 32);
      // O "Vai!": 52 dp, largura total menos 16 de cada lado, rodapé 8/16.
      expect(go.height, 52);
      expect(go.left, 16);
      expect(go.width, size.width - 32);
      expect(go.bottom, size.height - 8);
      expect(go.overlaps(score), isFalse);
      expect(go.overlaps(board), isFalse);
      // O "voltar" da barra: alvo de 48 dp.
      final back = tester.getSize(find.byType(BackButton));
      expect(back.width, greaterThanOrEqualTo(48));
      expect(back.height, greaterThanOrEqualTo(48));

      await tester.tap(find.byKey(StarChallengeKeys.goButton));
      await tester.pumpAndSettle();
      final running = rectOf(tester, StarChallengeKeys.board);
      expect(running.width, size.width);
      expectBalanced(tester, size);
      // Sem o convite e sem o botão, o bloco desce para o meio.
      expect(running.top, lessThan(board.top));
      expect(find.byKey(StarChallengeKeys.goButton), findsNothing);
      expect(find.byKey(StarChallengeKeys.intro), findsNothing);
      expect(find.text('Sua vez'), findsNothing);
      final runningScore = rectOf(tester, StarChallengeKeys.scoreboard);
      expect(runningScore.size, score.size);
      expect(runningScore.top - running.bottom, closeTo(8, 1));

      cubit.pause();
      await tester.pumpAndSettle();
      expect(find.text('Em pausa'), findsOneWidget);
      expect(rectOf(tester, StarChallengeKeys.board), running);
      expect(rectOf(tester, StarChallengeKeys.scoreboard), runningScore);
      expectBalanced(tester, size);
      cubit.resume();
      await tester.pumpAndSettle();

      await finish(tester, cubit);
      final finished = rectOf(tester, StarChallengeKeys.board);
      expectBalanced(tester, size);
      final finishedScore = rectOf(tester, StarChallengeKeys.scoreboard);
      expect(finishedScore.size, score.size);
      expect(finishedScore.top - finished.bottom, closeTo(8, 1));
      expect(rectOf(tester, StarChallengeKeys.retryButton), go);
      expect(tester.takeException(), isNull);
    });
  }

  // A matriz: tamanhos, fonte, tema e direção, em todos os estados.
  for (final size in [
    const Size(360, 740),
    const Size(412, 917),
    const Size(448, 997),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        for (final locale in [const Locale('pt'), const Locale('ar')]) {
          testWidgets('V2 matriz $size fonte $scale ${mode.name} '
              '${locale.languageCode}', (tester) async {
            final cubit = await pump(
              tester,
              size: size,
              textScale: scale,
              themeMode: mode,
              locale: locale,
            );
            final rtl = locale.languageCode == 'ar';
            final context = tester.element(find.byKey(StarChallengeKeys.intro));
            final theme = Theme.of(context);
            expect(
              Directionality.of(context),
              rtl ? TextDirection.rtl : TextDirection.ltr,
            );
            final ready = rectOf(tester, StarChallengeKeys.board);
            expectBalanced(tester, size);
            // Tabuleiro e número do tempo sempre da esquerda para a direita.
            expect(
              tester
                  .widget<Directionality>(
                    find
                        .ancestor(
                          of: find.byType(Chessboard),
                          matching: find.byType(Directionality),
                        )
                        .first,
                  )
                  .textDirection,
              TextDirection.ltr,
            );
            expect(
              tester
                  .widget<Text>(find.byKey(StarChallengeKeys.timer))
                  .textDirection,
              TextDirection.ltr,
            );
            // D2: o mesmo papel nos dois cartões.
            Color? colorOf(Key key) =>
                tester.widget<Card>(find.byKey(key)).color;
            expect(colorOf(StarChallengeKeys.intro), starCardColor(theme));
            expect(colorOf(StarChallengeKeys.scoreboard), starCardColor(theme));
            expect(
              starCardColor(theme),
              mode == ThemeMode.light
                  ? theme.colorScheme.surfaceContainerLowest
                  : theme.colorScheme.surfaceContainerHigh,
            );
            // A barra do app cresce com a fonte (piso 72).
            expect(
              tester.widget<AppBar>(find.byType(AppBar)).toolbarHeight,
              max(72.0, 44 * scale + 16),
            );
            // O placar espelha: em árabe o ouro fica à direita.
            final gold = tester.getCenter(
              find.byKey(StarChallengeKeys.kindCount('gold')),
            );
            final bronze = tester.getCenter(
              find.byKey(StarChallengeKeys.kindCount('bronze')),
            );
            expect(gold.dx < bronze.dx, !rtl);
            // O cartão do convite inteiro: sem rolagem interna, o texto no
            // tamanho da fonte e, rolando o espaço de cima, a borda de baixo.
            final intro = find.byKey(StarChallengeKeys.intro);
            expect(
              find.descendant(
                of: intro,
                matching: find.byType(SingleChildScrollView),
              ),
              findsNothing,
            );
            final screen = tester.renderObject(
              find.byKey(StarChallengeKeys.screen),
            );
            final body = find
                .descendant(of: intro, matching: find.byType(Text))
                .last;
            expect(
              tester
                  .renderObject(body)
                  .getTransformTo(screen)
                  .getMaxScaleOnAxis(),
              closeTo(1, .01),
            );
            final above = find
                .ancestor(
                  of: intro,
                  matching: find.byType(SingleChildScrollView),
                )
                .first;
            await tester.drag(above, const Offset(0, -2000));
            await tester.pumpAndSettle();
            expect(
              tester.getRect(intro).bottom,
              lessThanOrEqualTo(tester.getRect(above).bottom + 1),
            );
            expect(rectOf(tester, StarChallengeKeys.board), ready);
            final score = rectOf(tester, StarChallengeKeys.scoreboard);
            final go = rectOf(tester, StarChallengeKeys.goButton);
            expect(score.top - ready.bottom, closeTo(8, 1));
            expect(go.height, greaterThanOrEqualTo(52));
            expect(go.overlaps(score), isFalse);
            expect(go.overlaps(ready), isFalse);
            expect(tester.takeException(), isNull);

            await tester.tap(find.byKey(StarChallengeKeys.goButton));
            await tester.pumpAndSettle();
            final running = rectOf(tester, StarChallengeKeys.board);
            expectBalanced(tester, size);
            expect(running.width, greaterThanOrEqualTo(ready.width));
            final runningScore = rectOf(tester, StarChallengeKeys.scoreboard);
            expect(runningScore.size, score.size);
            expect(runningScore.top - running.bottom, closeTo(8, 1));

            // Pouco tempo: ícone, número e barra em error.
            now.advance(const Duration(milliseconds: 50400));
            cubit.tick();
            await tester.pumpAndSettle();
            final error = theme.colorScheme.error;
            expect(
              tester.widget<Icon>(find.byIcon(Icons.timer_outlined)).color,
              error,
            );
            expect(
              tester
                  .widget<Text>(find.byKey(StarChallengeKeys.timer))
                  .style
                  ?.color,
              error,
            );
            expect(
              tester
                  .widget<LinearProgressIndicator>(
                    find.byType(LinearProgressIndicator),
                  )
                  .color,
              error,
            );

            cubit.pause();
            await tester.pumpAndSettle();
            expect(rectOf(tester, StarChallengeKeys.board), running);
            expect(rectOf(tester, StarChallengeKeys.scoreboard), runningScore);
            expect(tester.takeException(), isNull);
            cubit.resume();
            await tester.pumpAndSettle();

            await finish(tester, cubit);
            final finished = rectOf(tester, StarChallengeKeys.board);
            expectBalanced(tester, size);
            final finishedScore = rectOf(tester, StarChallengeKeys.scoreboard);
            expect(finishedScore.size, score.size);
            final retry = rectOf(tester, StarChallengeKeys.retryButton);
            expect(retry, go);
            expect(retry.overlaps(finished), isFalse);
            expect(retry.overlaps(finishedScore), isFalse);
            final result = find.byKey(StarChallengeKeys.result);
            expect(
              tester
                  .renderObject(
                    find
                        .descendant(of: result, matching: find.byType(Text))
                        .first,
                  )
                  .getTransformTo(screen)
                  .getMaxScaleOnAxis(),
              closeTo(1, .01),
            );
            expect(
              tester.getSize(find.byKey(StarChallengeKeys.backButton)).height,
              greaterThanOrEqualTo(48),
            );
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }

  for (final level in [ChallengeLevel.medium, ChallengeLevel.hard]) {
    testWidgets('V2 ${level.name} em 360×740: a nota dos obstáculos aparece '
        'e o bloco continua no meio', (tester) async {
      await pump(tester, size: const Size(360, 740), level: level);
      final note = rectOf(tester, StarChallengeKeys.obstacles);
      final intro = rectOf(tester, StarChallengeKeys.intro);
      final board = rectOf(tester, StarChallengeKeys.board);
      expect(note.bottom, lessThanOrEqualTo(intro.bottom - 16 + 1));
      expect(intro.bottom, closeTo(board.top - 8, 1));
      expect(board.width, lessThanOrEqualTo(360));
      expectBalanced(tester, const Size(360, 740));
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in [const Locale('pt'), const Locale('ar')]) {
    testWidgets('V2 às cegas ${locale.languageCode}: a casa por extenso acima '
        'do tabuleiro, sempre LTR', (tester) async {
      final cubit = await pump(
        tester,
        size: const Size(360, 740),
        level: ChallengeLevel.named,
        locale: locale,
      );
      expectBalanced(tester, const Size(360, 740));
      await tester.tap(find.byKey(StarChallengeKeys.goButton));
      await tester.pumpAndSettle();
      final name = find.byKey(StarChallengeKeys.starName);
      expect(tester.widget<Text>(name).data, cubit.state.star!.name);
      final board = rectOf(tester, StarChallengeKeys.board);
      expectBalanced(tester, const Size(360, 740));
      expect(tester.getRect(name).bottom, lessThanOrEqualTo(board.top));
      // A casa ("e4") é notação: nunca vira "4e" em árabe.
      expect(tester.widget<Text>(name).textDirection, TextDirection.ltr);
      await finish(tester, cubit);
      expect(tester.takeException(), isNull);
    });
  }
}
