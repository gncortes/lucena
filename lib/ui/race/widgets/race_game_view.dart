import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/race.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/game_clock.dart';
import '../../free_board/widgets/game_actions_bar.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../view_models/race_cubit.dart';
import 'race_scoreboard.dart';

/// A corrida em si: o placar em cima (contador ou ícone), o tabuleiro com o
/// problema da vez e, embaixo, o relógio do jogador e as chances. Sem som e
/// sem texto de instrução: o lance certo é o único jeito de seguir.
class RaceGameView extends StatelessWidget {
  const RaceGameView({required this.state, super.key});

  /// O espaço embaixo do tabuleiro: a linha do jogador e as chances. O
  /// aquecimento reserva o mesmo, para o tabuleiro ficar na mesma altura.
  static double bottomRoom(BuildContext context) =>
      PlayersRow.detailedHeight +
      MediaQuery.textScalerOf(context)
          .scale(RaceChances.height)
          .ceilToDouble() +
      AppSpacing.sm;

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final problem = state.problem;
    final run = state.run;
    if (problem == null || run == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final bottomRoom = RaceGameView.bottomRoom(context);
    return Stack(
      key: RaceKeys.gameView,
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: CenteredBoardLayout(
            balanced: true,
            reserveTop: RaceScoreboard.height,
            reserveBottom: bottomRoom,
            footer: const SizedBox(height: GameActionsBar.height),
            top: RaceScoreboard(
              count: run.corrects,
              feedback: state.feedback,
              feedbackCount: state.feedbackCount,
            ),
            board: LayoutBuilder(
              builder: (context, box) => RaceFadingBoard(
                size: box.maxWidth,
                problem: problem,
                fen: state.boardFen ?? problem.fen,
                locked: state.replying,
                // Um tabuleiro novo a cada problema, mesmo repetindo o id.
                turn: run.answers.length,
                settings: settings,
                onMove: (move) => cubit.answer(move.uci),
              ),
            ),
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PlayersRow(
                  detailed: true,
                  board: settings,
                  players: [
                    PlayerEntry(
                      side: problem.side,
                      name: l10n.reviewYou,
                      // Defender: o objetivo embaixo do nome.
                      detail: problem.defend ? l10n.raceDefendDetail : null,
                      detailKey: RaceKeys.defendDetail,
                      time: state.remaining,
                      running: true,
                      clockKey: RaceKeys.clock,
                      timeKey: RaceKeys.clockTime,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: RaceChances(
                    errors: run.errors,
                    total: RaceRules.maxErrors,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: ActionsBar(
              children: [
                GameActionButton(
                  buttonKey: RaceKeys.exit,
                  icon: Icons.logout,
                  label: l10n.raceExit,
                  onPressed: cubit.quit,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// O tabuleiro do problema; ao trocar de problema, o antigo some e o novo
/// aparece (cruzam), sem deixar o antigo receber toques.
class RaceFadingBoard extends StatelessWidget {
  const RaceFadingBoard({
    required this.size,
    required this.problem,
    required this.fen,
    required this.turn,
    required this.settings,
    required this.onMove,
    this.locked = false,
    super.key,
  });

  final double size;
  final RaceProblem problem;

  /// A posição a mostrar: muda dentro do problema a cada lance e resposta.
  final String fen;

  /// A defesa está respondendo: o tabuleiro não aceita lance.
  final bool locked;
  final int turn;
  final BoardSettings settings;
  final void Function(Move move) onMove;

  @override
  Widget build(BuildContext context) {
    final current = ValueKey('${problem.id}#$turn');
    return KeyedSubtree(
      key: RaceKeys.board,
      child: AnimatedSwitcher(
        duration: AppMotion.of(context).component,
        switchInCurve: AppMotion.enter,
        switchOutCurve: AppMotion.exit,
        transitionBuilder: (child, animation) => IgnorePointer(
          ignoring: child.key != current,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _ProblemBoard(
          key: current,
          size: size,
          problem: problem,
          fen: fen,
          locked: locked,
          settings: settings,
          onMove: onMove,
        ),
      ),
    );
  }
}

class _ProblemBoard extends StatefulWidget {
  const _ProblemBoard({
    required this.size,
    required this.problem,
    required this.fen,
    required this.locked,
    required this.settings,
    required this.onMove,
    super.key,
  });

  final double size;
  final RaceProblem problem;
  final String fen;
  final bool locked;
  final BoardSettings settings;
  final void Function(Move move) onMove;

  @override
  State<_ProblemBoard> createState() => _ProblemBoardState();
}

class _ProblemBoardState extends State<_ProblemBoard> {
  late final ChessboardController _controller;

  GameData _data({String? last}) {
    final fen = widget.fen;
    final position = Chess.fromSetup(Setup.parseFen(fen));
    final side = widget.problem.side;
    final mine = position.turn == side && !widget.locked;
    return GameData(
      fen: fen,
      playerSide: mine
          ? (side == Side.white ? PlayerSide.white : PlayerSide.black)
          : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: mine ? GameRules.legalMoves(position) : const {},
      lastMove: last == null ? null : Move.parse(last),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController(game: _data());
  }

  @override
  void didUpdateWidget(_ProblemBoard old) {
    super.didUpdateWidget(old);
    if (old.fen != widget.fen || old.locked != widget.locked) {
      _controller.updatePosition(_data());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Chessboard(
      size: widget.size,
      controller: _controller,
      settings: widget.settings.chessground,
      orientation: widget.problem.side,
      onMove: (move, {viaDragAndDrop}) => widget.onMove(move),
    ),
  );
}
