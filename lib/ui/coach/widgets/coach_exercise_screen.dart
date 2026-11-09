import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/endgame_lesson_rules.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/coach_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/retorno_do_lance.dart';
import '../../core/motion/tabuleiro_animado.dart';
import '../../core/motion/troca_com_fade.dart';
import '../../core/motion/entrada_de_resultado.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/move_highlight.dart';
import '../../core/widgets/load_skeleton.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../core/widgets/training_canvas_layout.dart';
import '../../endgames/widgets/grade_widgets.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../survey/view_models/viktor_thanks_cubit.dart';
import '../view_models/coach_exercise_cubit.dart';
import 'coach_screen.dart';

/// Os exercícios de uma partida analisada, com o Viktor, e a pontuação no
/// fim. O progresso fica salvo a cada exercício (sair no meio retoma dali).
class CoachExerciseScreen extends StatefulWidget {
  const CoachExerciseScreen({super.key});

  @override
  State<CoachExerciseScreen> createState() => _CoachExerciseScreenState();
}

class _CoachExerciseScreenState extends State<CoachExerciseScreen> {
  /// Uma posição por exercício: na troca, a nova entra pronta num fade
  /// enquanto a anterior some (H-ANI-03), como no Treino.
  final _boards = <int, ChessboardController>{};

  @override
  void dispose() {
    for (final board in _boards.values) {
      board.dispose();
    }
    super.dispose();
  }

  void _back() => context.canPop() ? context.pop() : context.go(Routes.coach());

  static Side _side(CoachExercise ex) =>
      GameRules.fromFen(ex.fen)?.turn ?? Side.white;

  GameData _data(CoachExerciseState s) {
    final fen = s.fen!;
    final position = GameRules.fromFen(fen);
    final side = _side(s.exercise!);
    final chessMove = s.lastMoveOfGame == null
        ? null
        : Move.parse(s.lastMoveOfGame!);
    return GameData(
      fen: fen,
      playerSide: position == null || s.phase != ExerciseStep.playing
          ? PlayerSide.none
          : (side == Side.white ? PlayerSide.white : PlayerSide.black),
      sideToMove: position?.turn ?? side,
      validMoves: position == null ? const {} : GameRules.legalMoves(position),
      lastMove: chessMove,
      kingSquareInCheck: position == null
          ? null
          : GameRules.checkedKing(position),
    );
  }

  CoachExerciseState? _previous;

  void _sync(CoachExerciseState s) {
    final previous = _previous;
    _previous = s;
    if (s.fen == null || s.exercise == null) return;
    final board = _boards[s.index];
    if (board == null) {
      _boards[s.index] = ChessboardController(game: _data(s));
      return;
    }
    board.updatePosition(
      _data(s),
      animate: previous?.fen != s.fen && previous?.index == s.index,
      resetPremove: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // Lido no build: o boardBuilder roda no layout.
    final boardSettings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    return BlocConsumer<CoachExerciseCubit, CoachExerciseState>(
      listener: (_, s) => _sync(s),
      builder: (context, s) {
        if (s.phase == ExerciseStep.loading) {
          return const LoadSkeletonScreen();
        }
        if (s.phase == ExerciseStep.unavailable) {
          return LoadErrorScreen(
            kind: LoadErrorKind.notFound,
            onAction: () => context.go(Routes.coach()),
            onBack: _back,
          );
        }
        if (s.phase == ExerciseStep.offline) {
          return LoadErrorScreen(
            kind: LoadErrorKind.offline,
            onAction: context.read<CoachExerciseCubit>().reload,
            onBack: _back,
          );
        }
        if (!_boards.containsKey(s.index) &&
            s.fen != null &&
            s.exercise != null) {
          _boards[s.index] = ChessboardController(game: _data(s));
          _previous = s;
        }
        return BlocBuilder<ViktorThanksCubit, Character?>(
          builder: (context, viktor) {
            if (viktor == null) return const LoadSkeletonScreen();
            if (s.phase == ExerciseStep.end) {
              return _End(state: s, viktor: viktor, onClose: _back);
            }
            final ex = s.exercise!;
            return Scaffold(
              key: CoachKeys.exercise,
              appBar: LucenaAppBar(
                leading: BackButton(key: CoachKeys.back, onPressed: _back),
                title: Text(l.treinadorExercicioTitulo(s.index + 1, s.total)),
                actions: [
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.md,
                    ),
                    child: Semantics(
                      label: _counts(s)
                          ? l.exercisePoints(s.counts)
                          : l.exerciseNoMorePoints,
                      excludeSemantics: true,
                      // Como nos exercícios de finais (exercise_screen): neutra,
                      // na cor do texto, cheia enquanto ainda vale pontos; cada
                      // erro ou dica desce um degrau (3 → 2 → 1), e só esvazia
                      // quando não vale mais nada.
                      child: Icon(
                        _counts(s)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        key: CoachKeys.exerciseStars,
                        size: AppIconSize.large,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              body: BoardViewport(
                usefulHeight: BoardViewport.usefulHeightOf(context),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Expanded(
                        child: TrainingCanvasPage(
                          pageKey: CoachKeys.exercisePage,
                          teacher: viktor,
                          text: _line(l, s, ex),
                          boardBuilder: (size) =>
                              _board(context, s, size, boardSettings),
                          notation: _notation(s, ex),
                        ),
                      ),
                      _footer(context, s),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static bool _counts(CoachExerciseState s) =>
      s.counts > 0 &&
      (s.phase == ExerciseStep.playing || s.phase == ExerciseStep.solved);

  /// O lance tentado (com "?" no erro) ou a solução, em SAN, como no Treino,
  /// com o destaque do lance da análise de partida.
  /// Na posição do exercício; vazia enquanto o aluno ainda não jogou.
  static Widget _notation(CoachExerciseState s, CoachExercise ex) {
    final position = GameRules.fromFen(ex.fen);
    final uci = switch (s.phase) {
      ExerciseStep.solved || ExerciseStep.missed => s.lastMoveOfGame,
      ExerciseStep.solution => ex.solution,
      _ => null,
    };
    if (position == null || uci == null) return const SizedBox.shrink();
    final sans = GameRules.sanLine(position, [uci]);
    if (sans.isEmpty) return const SizedBox.shrink();
    return ScriptMoveList(
      moves: [
        ScriptMoveEntry(
          id: '0',
          san: sans.first,
          number: position.fullmoves,
          side: position.turn,
          variant: false,
          symbol: switch (s.phase) {
            ExerciseStep.missed => '?',
            ExerciseStep.solution => '!',
            _ => null,
          },
        ),
      ],
      currentId: '0',
      onTap: (_) {},
      // O destaque do lance como na análise da partida (T87).
      highlight: MoveHighlight.outlined,
    );
  }

  static String _line(
    AppLocalizations l,
    CoachExerciseState s,
    CoachExercise ex,
  ) {
    String or(String text, String standard) =>
        text.trim().isEmpty ? standard : text;
    return switch (s.phase) {
      ExerciseStep.solved => or(ex.lines.correct, l.treinadorAcertoPadrao),
      ExerciseStep.missed => or(ex.lines.error, l.treinadorErroPadrao),
      ExerciseStep.solution => or(ex.lines.solution, l.treinadorSolucaoPadrao),
      _ => or(ex.lines.prompt, l.treinadorEnunciadoPadrao),
    };
  }

  Widget _footer(BuildContext context, CoachExerciseState s) {
    final l = context.l10n;
    final cubit = context.read<CoachExerciseCubit>();
    final advance =
        s.phase == ExerciseStep.solved || s.phase == ExerciseStep.solution;
    return TrainingCanvasFooter(
      // A lâmpada à esquerda, como no exercício do Treino.
      leading: s.canHint
          ? TrainingCanvasFooter.hint(
              key: CoachKeys.hint,
              label: switch (s.counts) {
                0 => l.exerciseHintFree,
                1 => l.exerciseHintLast,
                _ => l.exerciseHint,
              },
              onPressed: cubit.hint,
            )
          : null,
      secondary:
          s.phase == ExerciseStep.playing || s.phase == ExerciseStep.missed
          ? TrainingCanvasFooter.button(
              key: CoachKeys.seeSolution,
              label: l.trainingSeeSolution,
              onPressed: () => unawaited(cubit.seeSolution()),
            )
          : null,
      primary: s.phase == ExerciseStep.missed
          ? TrainingCanvasFooter.button(
              key: CoachKeys.retry,
              label: l.loadErrorRetry,
              primary: true,
              onPressed: cubit.retry,
            )
          : advance
          ? TrainingCanvasFooter.button(
              key: CoachKeys.next,
              label: s.lastOne ? l.treinadorVerPontuacao : l.treinadorProximo,
              primary: true,
              onPressed: cubit.next,
            )
          : null,
    );
  }

  Widget _board(
    BuildContext context,
    CoachExerciseState s,
    double size,
    BoardSettings boardSettings,
  ) {
    final board = _boards[s.index];
    final ex = s.exercise!;
    if (board == null) return SizedBox.square(dimension: size);
    final side = _side(ex);
    final played = s.lastMoveOfGame == null
        ? null
        : Move.parse(s.lastMoveOfGame!);
    final solution = Move.parse(ex.solution);
    final child = SizedBox.square(
      dimension: size,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TabuleiroAnimado(
          controlador: board,
          orientacao: side,
          tamanho: size,
          pecas: boardSettings.chessground.pieceAssets,
          child: Chessboard(
            key: CoachKeys.exerciseBoard,
            size: size,
            controller: board,
            settings: TabuleiroAnimado.ajustes(
              context,
              boardSettings.chessground,
            ),
            orientation: side,
            shapes: {
              // A dica: a peça que joga (1) e depois o lance (2).
              if (s.phase == ExerciseStep.playing &&
                  s.hints == 1 &&
                  solution is NormalMove)
                Circle(
                  color: Theme.of(context).colorScheme.primary,
                  orig: solution.from,
                ),
              if (s.phase == ExerciseStep.playing &&
                  s.hints >= 2 &&
                  solution is NormalMove)
                Arrow(
                  color: Theme.of(context).colorScheme.primary,
                  orig: solution.from,
                  dest: solution.to,
                ),
              if (s.phase == ExerciseStep.missed && played is NormalMove)
                Arrow(
                  color: AppColors.errorColor.withValues(
                    alpha: AppColors.boardMarkAlpha,
                  ),
                  orig: played.from,
                  dest: played.to,
                ),
              if (s.phase == ExerciseStep.solution && solution is NormalMove)
                Arrow(
                  color: AppColors.successColor.withValues(
                    alpha: AppColors.boardMarkAlpha,
                  ),
                  orig: solution.from,
                  dest: solution.to,
                ),
            },
            onMove: (move, {viaDragAndDrop}) =>
                unawaited(context.read<CoachExerciseCubit>().play(move.uci)),
          ),
        ),
      ),
    );
    // H-ANI-03: o tabuleiro fica parado; na troca de exercício só a posição
    // troca em fade, como no Treino.
    if (played is! NormalMove ||
        (s.phase != ExerciseStep.solved && s.phase != ExerciseStep.missed)) {
      return TrocaComFade(chave: s.index, child: child);
    }
    return TrocaComFade(
      chave: s.index,
      child: RetornoDoLance(
        key: ValueKey('${s.index}.${s.attempts}.${s.phase.name}'),
        tipo: s.phase == ExerciseStep.solved
            ? TipoDeRetorno.acerto
            : TipoDeRetorno.erro,
        casa: played.to,
        orientacao: side,
        tamanho: size,
        vibrar: context.read<SettingsCubit>().state?.vibration ?? true,
        child: child,
      ),
    );
  }
}

/// A pontuação (canvas DFim): a medalha, "x de N certos", a partida, uma
/// bolinha por exercício, a fala do Viktor e os botões no pé.
class _End extends StatelessWidget {
  const _End({
    required this.state,
    required this.viktor,
    required this.onClose,
  });

  final CoachExerciseState state;
  final Character viktor;
  final VoidCallback onClose;

  /// O diâmetro da bolinha (DFim: 40 dp).
  static const _dot = 40.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final p = state.progress;
    final game = state.game;
    final note = CoachRules.note(p.corrects, state.total);
    final line = switch (note) {
      ExerciseGrade.perfect => l.treinadorFimVikPerfeito,
      ExerciseGrade.good ||
      ExerciseGrade.excellent ||
      ExerciseGrade.passed => l.treinadorFimVikBom,
      ExerciseGrade.below => l.treinadorFimVikAbaixo,
    };
    final id = game?.id ?? '';
    final opponent = game?.opponent.name ?? '';
    final cadence = game?.cadence;
    return Scaffold(
      key: CoachKeys.end,
      appBar: LucenaAppBar(
        leading: IconButton(
          key: CoachKeys.endClose,
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onClose,
        ),
      ),
      body: SafeArea(
        // H-ANI-25, como no fim do teste e da lista: medalha, título,
        // partida, bolinhas, Viktor e botões em ordem; reabrir o mesmo
        // resultado mostra tudo pronto.
        child: EntradaDeResultado(
          id: 'treinador-$id-${p.corrects}-${state.total}',
          estrela: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: GradeMedal(key: CoachKeys.endNote, grade: note),
            ),
          ),
          titulo: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l.treinadorFimCertos(p.corrects, state.total),
              textAlign: TextAlign.center,
              style: context.screenTitle?.copyWith(fontWeight: AppWeight.heavy),
            ),
          ),
          subtitulo: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              cadence == null || cadence.isEmpty
                  ? l.treinadorFimSubtituloSemCadencia(opponent)
                  : l.treinadorFimSubtitulo(opponent, cadence),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          bolinhas: _Dots.items(context, state, _dot),
          montarBolinhas: (dots) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Wrap(
              key: CoachKeys.endDots,
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: dots,
            ),
          ),
          viktor: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: TeacherSpeech(
              speechContext: SpeechContext.teaching,
              teacher: viktor,
              text: line,
            ),
          ),
          botoes: ActionsFooter(
            stacked: true,
            children: [
              BusyButton(
                buttonKey: CoachKeys.analysisEnd,
                icon: Icons.analytics_outlined,
                label: l.treinadorVerAnalise,
                // A10 G4: abre na 1ª posição-chave, não no lance 0.
                onPressed: () => unawaited(
                  context.push(
                    Routes.coachAnalysis(
                      id,
                      ply: switch (game?.exercises.firstOrNull) {
                        final ex? => CoachRules.halfMove(
                          ex.chessMove,
                          white: game!.color == GameColor.white,
                        ),
                        null => null,
                      },
                    ),
                  ),
                ),
              ),
              BusyButton(
                buttonKey: CoachKeys.endYourGame,
                icon: Icons.insights_outlined,
                style: BusyButtonStyle.outlined,
                label: l.treinadorOndeErra,
                onPressed: () =>
                    context.go(Routes.coach(tab: CoachTab.yourGame.wire)),
              ),
            ],
          ),
          // A rolagem com o conteúdo e os botões fixos no pé.
          montar: (parts) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.screen),
                  children: parts.sublist(0, parts.length - 1),
                ),
              ),
              parts.last,
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma bolinha por exercício: verde certo, vermelha errado (de
/// `progresso.resultados`); o que não foi feito fica só com o contorno.
abstract final class _Dots {
  static List<Widget> items(
    BuildContext context,
    CoachExerciseState state,
    double diameter,
  ) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final byN = {for (final r in state.progress.results) r.n: r};
    return [
      for (final (i, ex) in state.exercises.indexed)
        _Dot(
          key: CoachKeys.endDot(i + 1),
          number: i + 1,
          diameter: diameter,
          right: byN[ex.n]?.solved,
          semantics: switch (byN[ex.n]?.solved) {
            true => l.treinadorFimBolinhaCerta(i + 1),
            false => l.treinadorFimBolinhaErrada(i + 1),
            // Sem resultado neste celular: "Exercício n de N" e o valor.
            null => l.treinadorExercicioTitulo(i + 1, state.total),
          },
          semanticValue: byN[ex.n] == null
              ? l.treinadorResumoSemResultado
              : null,
          text: theme.textTheme.titleMedium,
        ),
    ];
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.number,
    required this.diameter,
    required this.right,
    required this.semantics,
    required this.text,
    this.semanticValue,
    super.key,
  });

  final int number;
  final double diameter;

  /// Nulo: ainda sem resultado.
  final bool? right;
  final String semantics;
  final String? semanticValue;
  final TextStyle? text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (right) {
      true => AppColors.trainingDayCorrect,
      false => AppColors.trainingDayWrong,
      null => null,
    };
    return Semantics(
      label: semantics,
      value: semanticValue,
      excludeSemantics: true,
      child: Container(
        width: diameter,
        height: diameter,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          // Sem resultado: só o contorno, com o número na cor do texto.
          border: color == null ? Border.all(color: colors.outline) : null,
          shape: BoxShape.circle,
        ),
        child: Text(
          NumberFormat.decimalPattern(
            Localizations.localeOf(context).toString(),
          ).format(number),
          style: text?.copyWith(
            color: color == null ? colors.onSurface : AppColors.chessWhiteColor,
          ),
        ),
      ),
    );
  }
}
