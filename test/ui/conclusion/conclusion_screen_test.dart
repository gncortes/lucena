import 'dart:async';
import 'dart:typed_data';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/account/account_repository.dart';
import 'package:lucena/data/repositories/sync/sync_scheduler.dart';
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
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/keys/account_keys.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/free_board/view_models/game_reporter.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';
import 'package:lucena/ui/voice/view_models/speech_cubit.dart';

import '../../../testing/fakes/fake_account_invite_repository.dart';
import '../../../testing/fakes/fake_account_repository.dart';
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
import '../../../testing/fakes/fake_sync_repository.dart';
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
    FakeAccountInviteRepository? invite,
    FakeAccountRepository? accounts,
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
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(scale),
            disableAnimations: disableAnimations,
          ),
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AccountRepository>.value(
                value: accounts ?? FakeAccountRepository(),
              ),
              RepositoryProvider<SyncScheduler>(
                create: (_) => SyncScheduler(
                  accounts ?? FakeAccountRepository(),
                  FakeSyncRepository(),
                ),
                dispose: (scheduler) => scheduler.dispose(),
              ),
            ],
            child: BlocProvider.value(
              value: cubit,
              child: ConclusionScreen(fresh: fresh, invite: invite),
            ),
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

  group('avatares (T73, D9)', () {
    Size avatarIn(WidgetTester tester, Key key) => tester.getSize(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(CharacterAvatar),
      ),
    );

    testWidgets('no confronto o adversário (avatar com moldura) tem 72', (
      tester,
    ) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));
      final frame = find
          .ancestor(
            of: find.descendant(
              of: find.byKey(ConclusionKeys.opponent),
              matching: find.byType(CharacterAvatar),
            ),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(frame), const Size(72, 72));
    });

    testWidgets('na fala em cartão do adversário o avatar tem 56', (
      tester,
    ) async {
      await open(tester, moves: _longMoves, played: const Duration(minutes: 5));
      await tester.ensureVisible(find.byKey(ConclusionKeys.quickReview));
      await tester.tap(find.byKey(ConclusionKeys.quickReview));
      await settle(tester);
      expect(avatarIn(tester, ConclusionKeys.comment), const Size(56, 56));
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

  group('aviso de conquista', () {
    for (final size in const [Size(360, 740), Size(412, 917)]) {
      testWidgets('fica no alto, acima do título (${size.width.toInt()})', (
        tester,
      ) async {
        await open(tester, size: size, fresh: true, settled: false);
        await tester.pump(AchievementToasts.duration * 0.3);
        final toast = tester.getRect(find.byKey(AchievementsKeys.toast));
        final title = tester.getRect(find.byKey(ConclusionKeys.title));
        expect(toast.top, closeTo(8, 1));
        expect(toast.bottom, lessThanOrEqualTo(title.top));
        // Some sozinho e o título fica livre.
        await tester.pump(AchievementToasts.duration);
        await tester.pumpAndSettle();
        expect(find.byKey(AchievementsKeys.toast).hitTestable(), findsNothing);
        expect(find.byKey(ConclusionKeys.title).hitTestable(), findsOneWidget);
      });
    }
  });

  group('convite da conta', () {
    testWidgets('resultado livre; convite abre apenas ao tocar no cartão', (
      tester,
    ) async {
      final invite = FakeAccountInviteRepository();
      await open(tester, fresh: true, invite: invite);

      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(find.byKey(ConclusionKeys.accountInvite), findsOneWidget);
      expect(invite.shown, isFalse);
      expect(find.byKey(ConclusionKeys.close).hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byKey(ConclusionKeys.accountInvite));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ConclusionKeys.accountInvite));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.inviteSheet), findsOneWidget);
      expect(invite.shown, isTrue);

      // "Agora não" só fecha: a conclusão fica.
      await tester.tap(find.byKey(AccountKeys.notNow));
      await tester.pumpAndSettle();
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
      expect(find.byKey(ConclusionKeys.accountInvite), findsNothing);
    });

    testWidgets('já mostrado, não volta', (tester) async {
      await open(
        tester,
        fresh: true,
        invite: FakeAccountInviteRepository(shown: true),
      );
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(find.byKey(ConclusionKeys.accountInvite), findsNothing);
    });

    testWidgets('não abrir o cartão mantém o convite pendente', (tester) async {
      final invite = FakeAccountInviteRepository();
      await open(tester, fresh: true, invite: invite);
      expect(find.byKey(ConclusionKeys.accountInvite), findsOneWidget);
      expect(await invite.pending(), isTrue);
      // Outra conclusão ainda pode oferecer a proteção do progresso.
      await tester.pumpWidget(const SizedBox.shrink());
      await open(tester, fresh: true, invite: invite);
      expect(find.byKey(ConclusionKeys.accountInvite), findsOneWidget);
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(await invite.pending(), isTrue);
    });

    testWidgets('entre etapas não oferece convite nem consome pending', (
      tester,
    ) async {
      final invite = FakeAccountInviteRepository();
      final template = sampleSpeedruns[1];
      final base = SpeedrunPaces.withTime(template, sampleSpeedrunTime);
      await open(
        tester,
        fresh: true,
        invite: invite,
        journey: FakeJourneyRepository(speedruns: [template]),
        marathon: (speedruns) async {
          final attempt = await speedruns.start(base.id, now());
          return (attempt.id, 0);
        },
      );
      expect(cubit.state.conclusion!.run!.nextChallenge, isNotNull);
      expect(find.byKey(ConclusionKeys.accountInvite), findsNothing);
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(await invite.pending(), isTrue);
    });

    testWidgets('reaberta (não acabou agora), não convida', (tester) async {
      final invite = FakeAccountInviteRepository();
      await open(tester, invite: invite);
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(find.byKey(ConclusionKeys.accountInvite), findsNothing);
      expect(invite.shown, isFalse);
    });

    testWidgets('com conta, não convida', (tester) async {
      final invite = FakeAccountInviteRepository();
      await open(
        tester,
        fresh: true,
        invite: invite,
        accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      );
      expect(find.byKey(AccountKeys.inviteSheet), findsNothing);
      expect(find.byKey(ConclusionKeys.accountInvite), findsNothing);
      expect(invite.shown, isFalse);
    });
  });
}
