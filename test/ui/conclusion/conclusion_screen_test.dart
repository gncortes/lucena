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
import 'package:lucena/ui/conclusion/view_models/conclusion_cubit.dart';
import 'package:lucena/ui/conclusion/widgets/conclusion_screen.dart';
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
import '../../../testing/fakes/fake_voice_repository.dart';
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
  }) async {
    final rating = FakeRatingRepository();
    final achievements = FakeAchievementsRepository();
    final speedruns = FakeSpeedrunRepository(progress);
    await tester.runAsync(() async {
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
      );
      final id = await progress.addAttempt(game);
      await GameReporter(
        rating: rating,
        achievements: achievements,
        journey: FakeJourneyRepository(),
        progress: progress,
        speedruns: speedruns,
        positions: FakePositionsRepository(),
        now: now,
      ).report(game, gameId: id, userSide: Side.white, drawGoal: false);
      cubit = ConclusionCubit(
        progress: progress,
        rating: rating,
        achievements: achievements,
        journey: FakeJourneyRepository(),
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
    const size = Size(412, 2400);
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
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            disableAnimations: disableAnimations,
          ),
          child: BlocProvider.value(
            value: cubit,
            child: const ConclusionScreen(),
          ),
        ),
      ),
    );
    await settle(tester);
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
      // "Ver a análise detalhada" logo abaixo da precisão, antes dos
      // quadradinhos: o único caminho para ela na tela.
      final deeper = tester.getTopLeft(find.byKey(ConclusionKeys.reviewDeeper));
      expect(
        deeper.dy,
        greaterThan(tester.getTopLeft(find.byKey(ConclusionKeys.accuracy)).dy),
      );
      expect(
        deeper.dy,
        lessThan(
          tester.getTopLeft(find.byKey(ConclusionKeys.quality('best'))).dy,
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

  group('fala do adversário', () {
    testWidgets('fica no alto; o ✕ a esconde e cala a voz', (tester) async {
      final voice = FakeVoiceRepository();
      final speech = SpeechCubit(voice);
      addTearDown(speech.close);
      await tester.runAsync(speech.load);
      await open(
        tester,
        moves: _longMoves,
        played: const Duration(minutes: 5),
        speech: speech,
      );
      final comment = cubit.state.comment!;
      expect(find.byKey(ConclusionKeys.comment), findsOneWidget);
      // Fora da rolagem: rolar até o fim não a tira da vista.
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -3000),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(ConclusionKeys.comment)).dy,
        lessThan(200),
      );

      await tester.runAsync(
        () => speech.say(
          comment,
          speakerId: cubit.state.opponent!.id,
          language: 'en',
        ),
      );
      await tester.pump();
      expect(speech.state.isSpeaking(comment), isTrue);

      await tester.tap(find.byKey(ConclusionKeys.commentClose));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.byKey(ConclusionKeys.comment), findsNothing);
      expect(speech.state.speaking, isNull);
      expect(voice.stops, greaterThan(0));
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
}
