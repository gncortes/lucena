import 'dart:async';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/clock_format.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievement_toast.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/domain/use_cases/marathon.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/fakes/fake_analysis_repository.dart';
import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_game_review_repository.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_share_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/test_app.dart';

// Uma partida longa: 16 lances (a dama e o rei indo e voltando).
const _longMoves = [
  'c1b1', 'd7e7', 'b1c1', 'e7d7', //
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
  'c1b1', 'd7e7', 'b1c1', 'e7d7',
];

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeAnalysisRepository analysis;
  late FakeShareRepository share;
  late ConclusionCubit cubit;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 9, 12));
    progress = FakeProgressRepository();
    analysis = FakeAnalysisRepository();
    share = FakeShareRepository();
  });

  // Deixa a engine falsa e as animações terminarem.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  /// Grava a partida, monta a tela e espera ela abrir.
  Future<void> open(
    WidgetTester tester, {
    AttemptOutcome outcome = AttemptOutcome.win,
    List<String> moves = const ['c1g5'],
    Duration played = const Duration(seconds: 20),
    bool disableAnimations = false,
    SpeechCubit? speech,
    FakeOpponentRepository? opponent,
    FakeJourneyRepository? journey,
    Future<(int, int)> Function(FakeSpeedrunRepository)? marathon,
    Size size = const Size(412, 2400),
    double scale = 1,
    Locale locale = const Locale('en'),
    bool fresh = false,
    bool settled = true,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final rating = FakeRatingRepository();
    final achievements = FakeAchievementsRepository();
    final speedruns = FakeSpeedrunRepository(progress);
    await tester.runAsync(() async {
      final run = await marathon?.call(speedruns);
      final game = Attempt(
        positionId: samplePositions[0].id,
        playedAt: now(),
        startedAt: now().subtract(played),
        outcome: outcome,
        fulfilled: outcome == AttemptOutcome.win,
        opponent: OpponentKind.maia,
        opponentLevel: 1000,
        startFen: samplePositions[0].fen,
        userSide: Side.white,
        endReason: switch (outcome) {
          AttemptOutcome.win => GameEndReason.checkmate,
          AttemptOutcome.loss => GameEndReason.resign,
          AttemptOutcome.draw => GameEndReason.stalemate,
        },
        moves: moves,
        userClock: run == null ? null : const Duration(seconds: 10),
        speedrunAttemptId: run?.$1,
        speedrunStage: run?.$2,
      );
      final id = await progress.addAttempt(game);
      await GameReporter(
        rating: rating,
        achievements: achievements,
        journey: journey ?? FakeJourneyRepository(),
        progress: progress,
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        now: now,
      ).report(game, gameId: id, userSide: Side.white, drawGoal: false);
      cubit = ConclusionCubit(
        progress: progress,
        rating: rating,
        achievements: achievements,
        journey: journey ?? FakeJourneyRepository(),
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        characters: FakeCharacterRepository(),
        now: now,
        analysis: analysis,
        reviews: FakeGameReviewRepository(),
        opponent: opponent,
      );
      await cubit.load(id, 'en');
    });
    addTearDown(cubit.close);
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await tester.runAsync(settings.load);
    await tester.pumpWidget(
      TestApp(
        shareRepository: share,
        settingsCubit: settings,
        speechCubit: speech,
        locale: locale,
        themeMode: themeMode,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            disableAnimations: disableAnimations,
          ),
          child: BlocProvider.value(
            value: cubit,
            child: ConclusionScreen(fresh: fresh),
          ),
        ),
      ),
    );
    if (settled) {
      await settle(tester);
    } else {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump();
    }
  }

  /// Compartilha e devolve a altura da imagem (no cabeçalho do PNG).
  Future<int> sharedHeight(WidgetTester tester) async {
    share.shared.clear();
    await tester.runAsync(() async {
      await tester.tap(find.byKey(ConclusionKeys.share));
      for (var i = 0; i < 40 && share.shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    final png = share.shared.single.png;
    return ByteData.sublistView(png, 20, 24).getUint32(0);
  }

  group('Maratona concluída', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets('o painel mostra "Tempo que sobrou", como o resumo '
          '(${locale.languageCode})', (tester) async {
        final marathon = sampleMarathon;
        final stages = marathon.stages.length;
        final pace = SpeedrunPaces.idFor(marathon.id, sampleSpeedrunTime);
        await open(
          tester,
          locale: locale,
          journey: FakeJourneyRepository(speedruns: [marathon]),
          marathon: (speedruns) async {
            final attempt = await speedruns.start(pace, now());
            for (var stage = 0; stage < stages - 1; stage++) {
              await progress.addAttempt(
                Attempt(
                  positionId: samplePositions[0].id,
                  playedAt: now(),
                  outcome: AttemptOutcome.win,
                  fulfilled: true,
                  opponent: OpponentKind.maia,
                  userClock: const Duration(seconds: 10),
                  speedrunAttemptId: attempt.id,
                  speedrunStage: stage,
                ),
              );
            }
            return (attempt.id, stages - 1);
          },
        );

        final label = AppLocalizations.of(
          tester.element(find.byKey(ConclusionKeys.run)),
        );
        expect(find.text(label.marathonLeft), findsOneWidget);
        expect(find.text(label.conclusionTotalTime), findsNothing);
        final left = Duration(seconds: 180 - stages * 10);
        expect(
          tester.widget<Text>(find.byKey(ConclusionKeys.total)).data,
          RunTimeFormat.clock(left),
        );
      });
    }
  });

  group('fonte 2,0', () {
    // Largo de propósito: a fonte dos testes (Ahem, um quadrado por letra)
    // não cabe em 360 a 2,0, e a largura não muda o círculo de 28 fixo.
    testWidgets('o número "10" da etapa cabe inteiro (pílula)', (tester) async {
      final base = sampleSpeedruns[1];
      final marathon = Marathon.of(
        base.copyWith(
          stages: [
            for (var i = 0; i < 10; i++)
              base.stages.first.copyWith(id: '${base.id}/$i'),
          ],
        ),
      );
      final pace = SpeedrunPaces.idFor(marathon.id, sampleSpeedrunTime);
      await open(
        tester,
        size: const Size(900, 2400),
        scale: 2,
        journey: FakeJourneyRepository(speedruns: [marathon]),
        marathon: (speedruns) async {
          final attempt = await speedruns.start(pace, now());
          for (var stage = 0; stage < 9; stage++) {
            await progress.addAttempt(
              Attempt(
                positionId: samplePositions[0].id,
                playedAt: now(),
                outcome: AttemptOutcome.win,
                fulfilled: true,
                opponent: OpponentKind.maia,
                userClock: const Duration(seconds: 10),
                speedrunAttemptId: attempt.id,
                speedrunStage: stage,
              ),
            );
          }
          return (attempt.id, 9);
        },
      );
      await tester.tap(find.byKey(ConclusionKeys.runDetails));
      await tester.pumpAndSettle();
      final number = find.descendant(
        of: find.byKey(ConclusionKeys.stage(9)),
        matching: find.text('10'),
      );
      final badge = find.ancestor(of: number, matching: find.byType(Container));
      final box = tester.getRect(badge.first);
      final text = tester.getRect(number);
      // Numa linha só e dentro da pílula (antes o "0" descia e era cortado).
      expect(box.width, greaterThanOrEqualTo(text.width));
      expect(box.height, greaterThanOrEqualTo(text.height));
      expect(text.height, lessThan(text.width * 2));
    });

    testWidgets('o rating cabe em 360 sem encolher a fonte', (tester) async {
      await open(tester, size: const Size(360, 2400), scale: 2);
      expect(find.byKey(ConclusionKeys.ratingValue), findsOneWidget);
      // Sem FittedBox: o valor desce de linha em vez de diminuir.
      expect(
        find.ancestor(
          of: find.byKey(ConclusionKeys.ratingValue),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      final card = tester.getRect(find.byKey(ConclusionKeys.rating));
      final value = tester.getRect(find.byKey(ConclusionKeys.ratingValue));
      expect(value.right, lessThanOrEqualTo(card.right));
    });
  });

  group('análise rápida', () {
    testWidgets('partida curta: começa sozinha, no fim da tela, andando', (
      tester,
    ) async {
      analysis.hold = Completer<void>();
      await open(tester);

      expect(cubit.state.reviewing, isTrue);
      expect(find.byKey(ConclusionKeys.reviewBoard), findsOneWidget);
      // No fim: depois dos atalhos de histórico.
      final links = tester.getTopLeft(
        find.byKey(ConclusionKeys.action(ConclusionAction.ratingHistory)),
      );
      final quick = tester.getTopLeft(find.byKey(ConclusionKeys.quickReview));
      expect(quick.dy, greaterThan(links.dy));

      analysis.hold!.complete();
      analysis.hold = null;
      await settle(tester);
      expect(find.byKey(ConclusionKeys.review), findsOneWidget);
    });

    testWidgets('partida longa: só no toque, e anda ali mesmo, no fim da '
        'tela', (tester) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));

      expect(cubit.state.reviewing, isFalse);
      expect(analysis.requests, isEmpty);
      expect(find.byKey(ConclusionKeys.reviewBoard), findsNothing);
      expect(find.byKey(ConclusionKeys.review), findsNothing);
      final links = tester.getTopLeft(
        find.byKey(ConclusionKeys.action(ConclusionAction.ratingHistory)),
      );
      final quick = tester.getTopLeft(find.byKey(ConclusionKeys.quickReview));
      expect(quick.dy, greaterThan(links.dy));

      analysis.hold = Completer<void>();
      await tester.ensureVisible(find.byKey(ConclusionKeys.quickReview));
      await tester.tap(find.byKey(ConclusionKeys.quickReview));
      await settle(tester);
      // Na própria conclusão, andando, com a fala do adversário à vista.
      expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
      expect(find.byKey(ConclusionKeys.reviewBoard), findsOneWidget);
      expect(find.byKey(ConclusionKeys.comment), findsOneWidget);

      analysis.hold!.complete();
      analysis.hold = null;
      await settle(tester);
      expect(find.byKey(ConclusionKeys.review), findsOneWidget);
      // "Ver a análise detalhada" abaixo do cartão da precisão, fora dele:
      // o único caminho para ela na tela.
      final deeper = tester.getTopLeft(find.byKey(ConclusionKeys.reviewDeeper));
      expect(
        deeper.dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.byKey(ConclusionKeys.analysisShared)).dy,
        ),
      );
      expect(find.text('See the detailed analysis'), findsOneWidget);
      expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
      expect(find.byKey(ConclusionKeys.comment), findsOneWidget);
    });

    testWidgets('compartilhar com a análise rodando: a imagem sai sem ela; '
        'pronta, ela entra', (tester) async {
      analysis.hold = Completer<void>();
      await open(tester);
      expect(cubit.state.reviewing, isTrue);
      final running = await sharedHeight(tester);
      // A imagem é só o cartão: a análise (com o tabuleiro) ficou de fora.
      final card = tester.getSize(find.byKey(ConclusionKeys.quickReview));
      expect(card.height, greaterThan(100));

      analysis.hold!.complete();
      analysis.hold = null;
      await settle(tester);
      expect(cubit.state.review, isNotNull);
      final done = await sharedHeight(tester);
      expect(done, greaterThan(running));
      // Pronta, a imagem leva o resumo, mas nunca o botão: ele fica fora
      // do que é capturado, desenhado sob a precisão.
      expect(
        find.descendant(
          of: find.byKey(ConclusionKeys.analysisShared),
          matching: find.byKey(ConclusionKeys.accuracy),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(ConclusionKeys.analysisShared),
          matching: find.byKey(ConclusionKeys.reviewDeeper),
        ),
        findsNothing,
      );
      await tester.ensureVisible(find.byKey(ConclusionKeys.accuracy));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ConclusionKeys.reviewDeeper).hitTestable(),
        findsOneWidget,
      );
    });
  });

  group('melhor linha', () {
    testWidgets('ao abrir, os lances andam sozinhos conforme chegam; embaixo, '
        'o aviso e a análise detalhada', (tester) async {
      final opponent = FakeOpponentRepository()..hold();
      await open(
        tester,
        moves: _longMoves,
        played: const Duration(minutes: 5),
        opponent: opponent,
      );
      // Fechada, nada é jogado.
      expect(opponent.requests, isEmpty);
      await tester.ensureVisible(find.byKey(ConclusionKeys.bestLineToggle));
      await tester.tap(find.byKey(ConclusionKeys.bestLineToggle));
      await tester.pump();
      expect(find.byKey(ConclusionKeys.bestLineRunning), findsOneWidget);
      expect(find.byKey(ConclusionKeys.bestLineDisclaimer), findsOneWidget);
      expect(find.byKey(ConclusionKeys.bestLineDeeper), findsOneWidget);

      String label() =>
          tester.widget<Text>(find.byKey(ConclusionKeys.bestLineMove)).data!;
      // Cada lance que chega aparece no tabuleiro, sem tocar em nada.
      Future<void> next() async {
        opponent
          ..release()
          ..hold();
        await tester.runAsync(pumpEventQueue);
        await tester.pump();
      }

      await next();
      expect(label(), startsWith('Move 1 of 1 · '));
      await next();
      expect(label(), startsWith('Move 2 of 2 · '));
      // Rodando, não dá para andar na mão.
      expect(
        tester
            .widget<IconButton>(find.byKey(ConclusionKeys.bestLineBack))
            .onPressed,
        isNull,
      );

      // Até o fim: a barra some e dá para voltar.
      opponent.release();
      await tester.runAsync(() async {
        for (var i = 0; i < 50 && !cubit.state.bestLineDone; i++) {
          await pumpEventQueue();
        }
      });
      await tester.pumpAndSettle();
      expect(cubit.state.bestLineDone, isTrue);
      expect(find.byKey(ConclusionKeys.bestLineRunning), findsNothing);
      final total = cubit.state.bestLine.length;
      expect(label(), startsWith('Move $total of $total · '));
      await tester.tap(find.byKey(ConclusionKeys.bestLineBack));
      await tester.pump();
      expect(label(), startsWith('Move ${total - 1} of $total · '));
      expect(
        find.text(
          'Stockfish played fast (1 s per move), so in some positions it may '
          'miss the best defence or the win. For a deeper look, open the '
          'detailed analysis.',
        ),
        findsOneWidget,
      );
    });
  });

  group('brilho de quem venceu', () {
    Finder glowIn(Key player) => find.descendant(
      of: find.byKey(player),
      matching: find.byKey(ConclusionKeys.winnerGlow),
    );

    testWidgets('vitória: só no jogador', (tester) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));
      expect(glowIn(ConclusionKeys.player), findsOneWidget);
      expect(glowIn(ConclusionKeys.opponent), findsNothing);
    });

    testWidgets('derrota: só no adversário', (tester) async {
      await open(
        tester,
        outcome: AttemptOutcome.loss,
        moves: _longMoves,
        played: const Duration(minutes: 5),
      );
      expect(glowIn(ConclusionKeys.player), findsNothing);
      expect(glowIn(ConclusionKeys.opponent), findsOneWidget);
    });

    testWidgets('empate: em nenhum', (tester) async {
      await open(
        tester,
        outcome: AttemptOutcome.draw,
        moves: _longMoves,
        played: const Duration(minutes: 5),
      );
      expect(find.byKey(ConclusionKeys.winnerGlow), findsNothing);
    });

    testWidgets('sem animações: nenhum', (tester) async {
      await open(
        tester,
        moves: _longMoves,
        played: const Duration(minutes: 5),
        disableAnimations: true,
      );
      expect(find.byKey(ConclusionKeys.winnerGlow), findsNothing);
    });
  });

  // T65 (dívidas): tempo no árabe, aviso por cima da AppBar, botão no tema.
  group('speedrun clássico', () {
    final speedrunId = SpeedrunPaces.idFor(
      sampleSpeedruns[0].id,
      SpeedrunPaces.all.first,
    );

    // Joga as etapas anteriores e devolve a que `open` grava por último.
    Future<(int, int)> Function(FakeSpeedrunRepository) run(int last) {
      return (speedruns) async {
        final attempt = await speedruns.start(speedrunId, now());
        for (var stage = 0; stage < last; stage++) {
          await progress.addAttempt(
            Attempt(
              positionId: samplePositions[0].id,
              playedAt: now(),
              outcome: AttemptOutcome.win,
              fulfilled: true,
              opponent: OpponentKind.maia,
              userClock: const Duration(seconds: 10),
              speedrunAttemptId: attempt.id,
              speedrunStage: stage,
            ),
          );
        }
        return (attempt.id, last);
      };
    }

    Text textOf(WidgetTester tester, Key key) =>
        tester.widget<Text>(find.byKey(key));

    testWidgets('em andamento: tempo da etapa isolado em LTR (ar)', (
      tester,
    ) async {
      await open(tester, locale: const Locale('ar'), marathon: run(0));
      final stageText = textOf(tester, ConclusionKeys.stageTime);
      final formatted = RunTimeFormat.format(const Duration(seconds: 10));
      expect(stageText.data, contains('\u2066$formatted\u2069'));
      expect(
        textOf(tester, ConclusionKeys.total).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('em andamento, en: o texto visível não muda', (tester) async {
      await open(tester, marathon: run(0));
      final formatted = RunTimeFormat.format(const Duration(seconds: 10));
      final label = AppLocalizations.of(
        tester.element(find.byKey(ConclusionKeys.run)),
      ).conclusionStageTime;
      expect(
        textOf(
          tester,
          ConclusionKeys.stageTime,
        ).data!.replaceAll(RegExp('[\u2066\u2069]'), ''),
        '$label: $formatted',
      );
    });

    testWidgets('concluído: total e etapas em LTR (ar)', (tester) async {
      await open(tester, locale: const Locale('ar'), marathon: run(1));
      expect(
        textOf(tester, ConclusionKeys.total).textDirection,
        TextDirection.ltr,
      );
      final rows = find.descendant(
        of: find.byKey(ConclusionKeys.stage(0)),
        matching: find.byType(Text),
      );
      await tester.tap(find.byKey(ConclusionKeys.runDetails));
      await tester.pumpAndSettle();
      final texts = tester.widgetList<Text>(rows);
      final formatted = RunTimeFormat.format(const Duration(seconds: 10));
      expect(
        texts.where(
          (t) => t.data == formatted && t.textDirection == TextDirection.ltr,
        ),
        isNotEmpty,
      );
    });
  });

  group('aviso de conquista', () {
    for (final size in const [Size(360, 740), Size(412, 917)]) {
      for (final scale in const [1.0, 2.0]) {
        // A 2,0 o aviso (componente aprovado, cresce com a fonte) tem
        // 188-220 dp e cobre o título enquanto aparece: aceito, porque some
        // sozinho. Ali só a posição e o título livre depois.
        testWidgets('fica no alto, acima do título a 1,0 '
            '(${size.width.toInt()}, x$scale)', (tester) async {
          await open(
            tester,
            size: size,
            scale: scale,
            fresh: true,
            settled: false,
          );
          await tester.pump(AchievementToasts.duration * 0.3);
          final toast = tester.getRect(find.byKey(AchievementsKeys.toast));
          final title = tester.getRect(find.byKey(ConclusionKeys.title));
          expect(toast.top, closeTo(8, 1));
          if (scale == 1) expect(toast.bottom, lessThanOrEqualTo(title.top));
          await tester.pump(AchievementToasts.duration);
          await tester.pumpAndSettle();
          expect(
            find.byKey(AchievementsKeys.toast).hitTestable(),
            findsNothing,
          );
          expect(
            find.byKey(ConclusionKeys.title).hitTestable(),
            findsOneWidget,
          );
        });
      }
    }
  });

  group('botão principal no escuro', () {
    testWidgets('usa o tema, sem cor fixa, com contraste', (tester) async {
      await open(tester, themeMode: ThemeMode.dark);
      final colors = Theme.of(tester.element(find.byKey(ConclusionKeys.screen)))
          .colorScheme;
      final buttons = find.descendant(
        of: find.byKey(ConclusionKeys.screen),
        matching: find.byType(FilledButton),
      );
      expect(buttons, findsWidgets);
      for (final button in tester.widgetList<FilledButton>(buttons)) {
        expect(button.style?.backgroundColor, isNull);
        expect(button.style?.foregroundColor, isNull);
      }
      final a = colors.primary.computeLuminance();
      final b = colors.onPrimary.computeLuminance();
      final ratio =
          (a > b ? a + 0.05 : b + 0.05) / (a > b ? b + 0.05 : a + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });
}
