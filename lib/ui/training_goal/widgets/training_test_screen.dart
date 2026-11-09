import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/training/goal/training_diagnostic.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/training/goal/diagnostic_test_size.dart';
import '../../../domain/use_cases/training/goal/goal_view.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/motion/lucena_motion.dart';
import '../../core/motion/valor_que_anima.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/lucena_card.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/training_goal_cubit.dart';
import 'goal_page.dart';

/// Teste de nível (H-TRE-08): uma posição por capítulo, "Não sei" conta como
/// erro. Cada resposta é gravada antes da posição seguinte; ao voltar, a tela
/// oferece continuar de onde parou.
class TrainingTestScreen extends StatefulWidget {
  const TrainingTestScreen({
    required this.onBack,
    required this.onSeePlan,
    super.key,
  });
  final VoidCallback onBack, onSeePlan;

  @override
  State<TrainingTestScreen> createState() => _TrainingTestScreenState();
}

class _TrainingTestScreenState extends State<TrainingTestScreen> {
  /// Entrou com respostas já salvas e ainda não decidiu continuar.
  bool? _resumePending;
  ChessboardController? _controller;
  String? _fen;

  /// A barra mostra "Posição n de total" só enquanto há posição a responder.
  bool _showsPosition(TrainingDiagnostic d) =>
      d.method == DiagnosticMethod.test &&
      !d.testComplete &&
      !(_resumePending ?? d.testAnswered > 0);

  Future<void> _answer(TrainingGoalCubit cubit, bool correct) async {
    await cubit.answerTest(correct);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cubit = context.read<TrainingGoalCubit>();
    return GoalPage(
      screenKey: TrainingGoalKeys.testScreen,
      title: t.treinoDiagTest,
      titleKey: TrainingGoalKeys.testProgress,
      titleOf: (view) {
        final d = view.state.diagnostic;
        return d != null && _showsPosition(d)
            ? t.treinoTestProgress(d.testAnswered + 1, d.testSize)
            : t.treinoDiagTest;
      },
      progressOf: (view) {
        final d = view.state.diagnostic;
        return d != null && _showsPosition(d)
            ? d.testAnswered / d.testSize
            : null;
      },
      onBack: widget.onBack,
      // A posição: o tabuleiro no centro da área útil, de ponta a ponta, e o
      // "Não sei" embaixo dele (A8).
      fill: (context, view) {
        final d = view.state.diagnostic;
        if (d == null || d.method != DiagnosticMethod.test) return null;
        if (d.testComplete || (_resumePending ?? d.testAnswered > 0)) {
          return null;
        }
        final exercise = cubit.exerciseFor(d.testChapterIds[d.testAnswered]);
        if (exercise == null) return null;
        return Builder(
          builder: (context) => CenteredBoardLayout(
            centerY: BoardViewport.centerYOf(context),
            gap: AppSpacing.md,
            board: LayoutBuilder(
              builder: (context, box) => _TestBoard(
                controller: _controllerFor(exercise),
                orientation: GameRules.fromFen(exercise.fen)!.turn,
                size: box.maxWidth,
                onMove: (uci) => _answer(
                  cubit,
                  uci == exercise.solution.first ||
                      exercise.alternatives.contains(uci),
                ),
              ),
            ),
            bottom: _DontKnowButton(cubit: cubit),
          ),
        );
      },
      builder: (context, view) {
        final d = view.state.diagnostic;
        if (d == null || d.method != DiagnosticMethod.test) return const [];
        _resumePending ??= d.testAnswered > 0 && !d.testComplete;
        if (d.testComplete) return [_TestResult(view: view, diagnostic: d)];
        if (_resumePending!) {
          return [
            _ResumeCard(
              diagnostic: d,
              onContinue: () => setState(() => _resumePending = false),
              onRestart: () async {
                await cubit.restart();
                if (!mounted) return;
                if (await cubit.chooseTest()) {
                  setState(() => _resumePending = false);
                }
              },
            ),
          ];
        }
        // Com a posição, o corpo é o do [GoalPage.fill]. Sem ela no aparelho,
        // conta como não respondida: "Não sei".
        final exercise = cubit.exerciseFor(d.testChapterIds[d.testAnswered]);
        return [if (exercise == null) _DontKnowButton(cubit: cubit)];
      },
      footer: (context, view) {
        final d = view.state.diagnostic;
        if (d == null || !d.testComplete) return const SizedBox.shrink();
        // H-ANI-25: "Ver o plano" desliza por último, no mesmo relógio do
        // resultado (as duas entradas nascem no mesmo quadro).
        return EntradaDeResultado(
          id: '${_resultId(d)}-botoes',
          botoes: BlocBuilder<TrainingGoalCubit, TrainingGoalState>(
            builder: (context, state) => BusyButton(
              buttonKey: TrainingGoalKeys.testSeePlan,
              label: t.treinoTestSeePlan,
              busy: state.saving,
              onPressed: () async {
                if (await cubit.finish()) widget.onSeePlan();
              },
            ),
          ),
        );
      },
    );
  }

  /// O controlador do tabuleiro da posição; refeito só quando a posição muda.
  ChessboardController _controllerFor(TrainingExercise exercise) {
    final position = GameRules.fromFen(exercise.fen)!;
    final side = position.turn;
    final data = GameData(
      fen: exercise.fen,
      playerSide: side == Side.white ? PlayerSide.white : PlayerSide.black,
      sideToMove: side,
      validMoves: GameRules.legalMoves(position),
      lastMove: exercise.lastMove == null
          ? null
          : Move.parse(exercise.lastMove!),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
    if (_controller == null || _fen != exercise.fen) {
      _controller = ChessboardController(game: data);
      _fen = exercise.fen;
    }
    return _controller!;
  }

  /// O teste respondido: as mesmas respostas não animam duas vezes.
  static String _resultId(TrainingDiagnostic d) =>
      'meta-teste-${d.testChapterIds.join(',')}-${d.testAnswers.join(',')}';
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({
    required this.diagnostic,
    required this.onContinue,
    required this.onRestart,
  });

  final TrainingDiagnostic diagnostic;
  final VoidCallback onContinue, onRestart;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return LucenaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.treinoTestResumeTitle(
              diagnostic.testAnswered + 1,
              diagnostic.testSize,
            ),
            key: TrainingGoalKeys.testResume,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(t.treinoTestResumeBody),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            key: TrainingGoalKeys.testResumeContinue,
            onPressed: onContinue,
            child: Text(t.treinoTestResume),
          ),
          TextButton(
            key: TrainingGoalKeys.testRestart,
            onPressed: onRestart,
            child: Text(t.treinoRestart),
          ),
        ],
      ),
    );
  }
}

class _TestBoard extends StatelessWidget {
  const _TestBoard({
    required this.controller,
    required this.orientation,
    required this.size,
    required this.onMove,
  });

  final ChessboardController controller;
  final Side orientation;
  final double size;

  /// Recebe o lance jogado, em UCI.
  final ValueChanged<String> onMove;

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Chessboard(
        key: TrainingGoalKeys.testBoard,
        size: size,
        controller: controller,
        orientation: orientation,
        settings: settings.chessground,
        onMove: (move, {viaDragAndDrop}) => onMove(move.uci),
      ),
    );
  }
}

class _TestResult extends StatelessWidget {
  const _TestResult({required this.view, required this.diagnostic});

  final GoalView view;
  final TrainingDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final chosen = [
      for (final id in diagnostic.testChapterIds)
        if (view.chapter(id) != null) view.chapter(id)!,
    ];
    final levels = levelsFromTest(chosen, diagnostic.testAnswers);
    final titles = <String, String>{
      for (final c in chosen) c.partId: c.partTitle,
    };
    String label(TopicLevel l) => switch (l) {
      TopicLevel.mastered => t.treinoLevelStrong,
      TopicLevel.practicing => t.treinoLevelReview,
      TopicLevel.learning => t.treinoLevelLearn,
    };
    // H-ANI-25: o título sobe, a frase entra e onde o jogador está vem
    // depois; o rodapé fecha a entrada.
    return EntradaDeResultado(
      id: _TrainingTestScreenState._resultId(diagnostic),
      titulo: Text(
        t.treinoTestDone,
        key: TrainingGoalKeys.testResult,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      // H-ANI-18: as posições respondidas contam no tempo do placar.
      placar: ValorQueAnima(
        valor: diagnostic.testSize.toDouble(),
        duracao: LucenaMotion.numeroConta,
        builder: (context, agora) => Text(
          t.treinoTestAnswered(agora.round()),
          textAlign: TextAlign.center,
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ),
      viktor: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.treinoTestWhereYouAre,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final e in levels.entries)
            LucenaCard(
              child: Row(
                children: [
                  Expanded(child: Text(titles[e.key] ?? e.key)),
                  Text(label(e.value)),
                ],
              ),
            ),
        ],
      ),
      montar: (parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: parts,
      ),
    );
  }
}

class _DontKnowButton extends StatelessWidget {
  const _DontKnowButton({required this.cubit});

  final TrainingGoalCubit cubit;

  @override
  Widget build(BuildContext context) => TextButton(
    key: TrainingGoalKeys.testDontKnow,
    onPressed: () => cubit.answerTest(false),
    child: Text(context.l10n.treinoTestDontKnow),
  );
}
