import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/domain/models/conclusion.dart';
import 'package:lucena/ui/core/keys/conclusion_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/free_board_keys.dart';
import 'package:lucena/ui/core/keys/speedrun_keys.dart';
import 'package:lucena/ui/free_board/view_models/free_board_cubit.dart';
import 'package:lucena/ui/core/widgets/versus_intro.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/test_dependencies.dart';

/// O caminho de uma tentativa pelo app: as telas de cima mostram o resultado
/// novo ao voltar, mesmo com a tentativa reaberta pelo fim de cada etapa.
void main() {
  // O jogador sem nível escolhido é casual: o speedrun abre em 10+0.
  const id = 'rung.1000@600+0';

  // O texto na key, simples ou com partes (o RunClock escreve os décimos
  // menores).
  String runClock(WidgetTester tester, Key key) {
    final text = tester.widget<Text>(find.byKey(key));
    return text.data ?? text.textSpan!.toPlainText();
  }

  // O speedrun fica em "Outros modos" para o jogador casual.
  Future<void> openList(WidgetTester tester) async {
    if (find.byKey(HomeKeys.speedrunButton).evaluate().isEmpty) {
      await tester.ensureVisible(find.byKey(HomeKeys.otherModes));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(HomeKeys.otherModes));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(HomeKeys.speedrunButton));
    await tester.pumpAndSettle();
  }

  Future<void> openSpeedrun(WidgetTester tester) async {
    await openList(tester);
    await tester.tap(find.byKey(SpeedrunKeys.item(id)));
    await tester.pumpAndSettle();
  }

  for (final marathon in [false, true]) {
    for (final systemBack in [false, true]) {
      testWidgets(
        '${marathon ? "Maratona" : "Clássico"}: '
        '${systemBack ? "voltar" : "X"} do resultado mantém duas etapas vencidas',
        (tester) async {
          final now = FakeNow(DateTime.utc(2026, 10, 11, 12));
          final progress = FakeProgressRepository();
          final speedruns = FakeSpeedrunRepository(progress);
          final games = FakeOngoingGameRepository();
          final template = marathon ? sampleMarathon : sampleSpeedruns[1];
          final base = SpeedrunPaces.withTime(template, sampleSpeedrunTime);
          final attempt = await speedruns.start(base.id, now());
          for (final stage in [0, 1]) {
            now.advance(const Duration(seconds: 20));
            await progress.addAttempt(
              Attempt(
                positionId: samplePositions[0].id,
                playedAt: now(),
                outcome: AttemptOutcome.win,
                fulfilled: true,
                opponent: OpponentKind.maia,
                opponentLevel: 1000,
                userClock: const Duration(seconds: 20),
                userTime: base.time,
                startFen: samplePositions[0].fen,
                endReason: GameEndReason.checkmate,
                speedrunAttemptId: attempt.id,
                speedrunStage: stage,
              ),
            );
          }
          await tester.pumpWidget(
            LucenaApp(
              dependencies: testDependencies(
                now: now,
                progressRepository: progress,
                speedrunRepository: speedruns,
                ongoingGameRepository: games,
                journeyRepository: FakeJourneyRepository(speedruns: [template]),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byKey(HomeKeys.screen));
          GoRouter.of(context).go(Routes.conclusion(2));
          await tester.pumpAndSettle();
          expect(find.byKey(ConclusionKeys.screen), findsOneWidget);
          expect(games.snapshot, isNull);
          if (systemBack) {
            await tester.binding.handlePopRoute();
          } else {
            await tester.tap(find.byKey(ConclusionKeys.close));
          }
          await tester.pumpAndSettle();
          final game = tester
              .element(find.byKey(FreeBoardKeys.screen))
              .read<FreeBoardCubit>();
          expect(game.state.mode.speedrunAttemptId, attempt.id);
          expect(game.state.mode.speedrunStage, 2);
          expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
          if (marathon) {
            expect(
              game.state.clock!.config.of(game.state.mode.userSide!).initial,
              base.time.initial - const Duration(seconds: 40),
            );
          }
          // Tanto o X quanto o voltar levam à mesma confirmação explícita.
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.text('You lose the 2 stages you won in this attempt.'),
            findsOneWidget,
          );
          expect(find.byKey(FreeBoardKeys.speedrunQuitSheet), findsOneWidget);
          await tester.tap(find.byKey(FreeBoardKeys.speedrunQuitCancel));
          await tester.pumpAndSettle();
          expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
          expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
        },
      );
    }
  }

  testWidgets('ao voltar da tentativa concluída, o recorde aparece', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    final progress = FakeProgressRepository();
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(now: now, progressRepository: progress),
      ),
    );
    await tester.pumpAndSettle();
    await openSpeedrun(tester);
    // "Começar" abre a primeira etapa direto, no ritmo da lista.
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);

    // Cada etapa termina no tabuleiro; depois da última, a partida abre o
    // resumo da tentativa com `go`.
    for (final stage in [0, 1]) {
      now.advance(const Duration(minutes: 1));
      await progress.addAttempt(
        Attempt(
          positionId: 'basic.queen.0001',
          playedAt: now(),
          outcome: AttemptOutcome.win,
          fulfilled: true,
          opponent: OpponentKind.maia,
          userClock: const Duration(seconds: 6),
          speedrunAttemptId: 1,
          speedrunStage: stage,
        ),
      );
    }
    final context = tester.element(find.byKey(FreeBoardKeys.screen));
    GoRouter.of(context)
        .go(Routes.speedrunAttempt(id, 1, game: now().millisecondsSinceEpoch));
    await tester.pumpAndSettle();
    expect(find.byKey(SpeedrunKeys.total), findsOneWidget);
    expect(find.text('Your record'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(runClock(tester, SpeedrunKeys.best), '0:12.0');
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(runClock(tester, SpeedrunKeys.itemBest(id)), '0:12.0');
  });

  testWidgets('sair da etapa no meio pede confirmação e encerra a tentativa', (
    tester,
  ) async {
    final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    final games = FakeOngoingGameRepository();
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(now: now, ongoingGameRepository: games),
      ),
    );
    await tester.pumpAndSettle();
    await openSpeedrun(tester);
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);

    // Voltar pergunta antes; desistir de sair continua a partida.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.speedrunQuitConfirm), findsOneWidget);
    await tester.tap(find.byKey(FreeBoardKeys.speedrunQuitConfirm));
    await tester.pumpAndSettle();

    // De volta ao speedrun: a tentativa está no histórico, como abandonada,
    // e nenhuma etapa ficou guardada para depois.
    expect(find.byKey(SpeedrunKeys.screen), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.start), findsOneWidget);
    expect(find.byKey(SpeedrunKeys.bestAttempt), findsOneWidget);
    expect(find.text('Best attempt: stage 1 of 2'), findsOneWidget);
    expect(games.snapshot, isNull);
  });

  testWidgets('Maratona: perder encerra a tentativa; a conclusão oferece '
      'tentar de novo, do começo e com o tempo cheio', (tester) async {
    final now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    await tester.pumpWidget(
      LucenaApp(
        dependencies: testDependencies(
          now: now,
          journeyRepository: FakeJourneyRepository(
            speedruns: [...sampleSpeedruns, sampleMarathon],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openList(tester);
    // O jogador casual: a Maratona também abre em 10+0.
    const marathon = 'marathon.queen@600+0';
    await tester.tap(find.byKey(SpeedrunKeys.modeOption('marathon')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(SpeedrunKeys.item(marathon)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.item(marathon)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SpeedrunKeys.start));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    FreeBoardCubit game() =>
        tester.element(find.byKey(FreeBoardKeys.screen)).read<FreeBoardCubit>();
    // Você contra ele; os cartões saem e vem a contagem, com o relógio
    // parado; depois ele corre.
    expect(find.byKey(FreeBoardKeys.marathonBanner), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('3'), findsOneWidget);
    expect(game().state.clock!.running, isNull);
    await tester.pump(VersusIntro.duration);
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.marathonBanner), findsNothing);
    expect(game().state.clock!.running, isNotNull);

    // 20 s depois, a etapa é perdida: a partida para no tabuleiro (canvas
    // PropV2PartidaFim) e "Ver o resultado" abre a conclusão no lugar dela.
    now.advance(const Duration(seconds: 20));
    game().resign();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsOneWidget);
    await tester.tap(find.byKey(FreeBoardKeys.seeResultButton));
    await tester.pumpAndSettle();
    expect(find.byKey(FreeBoardKeys.screen), findsNothing);
    expect(find.byKey(ConclusionKeys.title), findsOneWidget);
    expect(find.textContaining('Stopped at stage 1 of'), findsOneWidget);

    // Tentar de novo: uma tentativa nova, da primeira etapa, tempo cheio.
    await tester.tap(find.byKey(ConclusionKeys.action(ConclusionAction.retry)));
    await tester.pumpAndSettle();
    final state = game().state;
    expect(state.mode.speedrunStage, 0);
    expect(
      state.clock!.config.of(state.mode.userSide!).initial,
      const Duration(minutes: 10),
    );
    await tester.pump(VersusIntro.duration);
    await tester.pumpAndSettle();
  });
}
