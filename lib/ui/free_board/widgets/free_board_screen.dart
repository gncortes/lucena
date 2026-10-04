import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/clock_settings.dart';
import '../../../domain/models/game_end.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/free_board_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/free_board_cubit.dart';
import 'clock_row.dart';
import 'clock_sheet.dart';
import 'move_list.dart';

class FreeBoardScreen extends StatefulWidget {
  const FreeBoardScreen({super.key});

  @override
  State<FreeBoardScreen> createState() => _FreeBoardScreenState();
}

class _FreeBoardScreenState extends State<FreeBoardScreen> {
  // Altura reservada para o painel de cima e para a lista de lances.
  static const _statusHeight = 72.0;
  static const _minMovesHeight = 120.0;

  late final ChessboardController _board;

  // O relógio não conta tiques: a tela só pede, várias vezes por segundo, que
  // os tempos sejam refeitos pelo instante atual.
  late final Timer _clockRefresh;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<FreeBoardCubit>();
    _board = ChessboardController(game: _gameData(cubit.state));
    _clockRefresh = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => cubit.tick(),
    );
  }

  @override
  void dispose() {
    _clockRefresh.cancel();
    _board.dispose();
    super.dispose();
  }

  Future<void> _pickClock() async {
    final cubit = context.read<FreeBoardCubit>();
    final choice = await showClockSheet(
      context,
      current: cubit.state.clock?.config,
    );
    if (choice != null) cubit.newGameWithClock(choice.config);
  }

  GameData _gameData(FreeBoardState state) {
    final position = state.position;
    return GameData(
      fen: position.fen,
      playerSide: _playerSide(state),
      sideToMove: position.turn,
      validMoves: GameRules.legalMoves(position),
      lastMove: state.lastMove,
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  PlayerSide _playerSide(FreeBoardState state) {
    // Com a partida terminada, o tabuleiro trava.
    if (state.end != null) return PlayerSide.none;
    return switch (state.playerSide) {
      null => PlayerSide.both,
      Side.white => PlayerSide.white,
      Side.black => PlayerSide.black,
    };
  }

  void _onStateChanged(FreeBoardState state) {
    final isPlayerTurn = state.playerSide == state.position.turn;
    final premove = _board.premove;
    // O pré-lance só sobrevive enquanto espera a resposta do adversário.
    final keepPremove = state.end == null && state.moves.isNotEmpty;
    _board.updatePosition(_gameData(state), resetPremove: !keepPremove);
    if (!keepPremove || premove == null || !isPlayerTurn) return;
    // O adversário respondeu: o lance marcado antes é jogado em seguida. Se
    // ele deixou de ser legal, é só descartado.
    _board.premove = null;
    context.read<FreeBoardCubit>().play(premove);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FreeBoardCubit>();
    final boardSettings = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    final clockPosition = context.select(
      (SettingsCubit cubit) =>
          (cubit.state?.clock ?? const ClockSettings()).position,
    );
    return BlocConsumer<FreeBoardCubit, FreeBoardState>(
      listener: (context, state) => _onStateChanged(state),
      builder: (context, state) {
        // Sair da tela pela seta ou pelo botão de voltar para o relógio e
        // guarda a partida.
        return PopScope(
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) unawaited(cubit.leave());
          },
          child: _scaffold(context, cubit, state, boardSettings, clockPosition),
        );
      },
    );
  }

  Widget _scaffold(
    BuildContext context,
    FreeBoardCubit cubit,
    FreeBoardState state,
    BoardSettings boardSettings,
    ClockPosition clockPosition,
  ) {
    // Enquanto a partida em andamento é lida do aparelho, só a barra de cima:
    // o tabuleiro não pisca na posição errada.
    if (!state.ready) {
      return Scaffold(
        key: FreeBoardKeys.screen,
        appBar: AppBar(title: Text(context.l10n.freeBoardTitle)),
      );
    }
    return Scaffold(
      key: FreeBoardKeys.screen,
      appBar: AppBar(
        title: Text(context.l10n.freeBoardTitle),
        actions: [
          IconButton(
            key: FreeBoardKeys.flipButton,
            icon: const Icon(Icons.swap_vert),
            tooltip: context.l10n.freeBoardFlip,
            onPressed: cubit.flip,
          ),
          IconButton(
            key: FreeBoardKeys.clockButton,
            icon: const Icon(Icons.timer_outlined),
            tooltip: context.l10n.freeBoardClock,
            onPressed: _pickClock,
          ),
          IconButton(
            key: FreeBoardKeys.newGameButton,
            icon: const Icon(Icons.restart_alt),
            tooltip: context.l10n.freeBoardNewGame,
            onPressed: cubit.newGame,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Sem relógio na partida, nenhuma fileira de relógio aparece.
            final clocks = state.clock == null ? null : clockPosition;
            final clockRows = switch (clocks) {
              null => 0,
              ClockPosition.sides => 2,
              ClockPosition.top || ClockPosition.bottom => 1,
            };
            final boardSize = math.min(
              constraints.maxWidth,
              constraints.maxHeight -
                  _statusHeight -
                  clockRows * ClockRow.height -
                  _minMovesHeight,
            );
            const both = [Side.white, Side.black];
            return Column(
              children: [
                _Status(
                  minHeight: _statusHeight,
                  state: state,
                  onNewGame: cubit.newGame,
                ),
                if (clocks == ClockPosition.top)
                  ClockRow(sides: both, state: state),
                if (clocks == ClockPosition.sides)
                  ClockRow(sides: [state.orientation.opposite], state: state),
                // O tabuleiro não espelha em idiomas da direita para a esquerda.
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Chessboard(
                    key: FreeBoardKeys.board,
                    size: boardSize,
                    controller: _board,
                    settings: boardSettings.chessground,
                    orientation: state.orientation,
                    onMove: (move, {viaDragAndDrop}) => cubit.play(move),
                  ),
                ),
                if (clocks == ClockPosition.sides)
                  ClockRow(sides: [state.orientation], state: state),
                if (clocks == ClockPosition.bottom)
                  ClockRow(sides: both, state: state),
                Expanded(
                  child: MoveList(
                    moves: state.moves,
                    firstMoveNumber: state.start.fullmoves,
                    firstSide: state.start.turn,
                    pieceLetters: boardSettings.notation.pieceLetters(
                      context.l10n,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Painel acima do tabuleiro: de quem é a vez ou, no fim, o resultado.
class _Status extends StatelessWidget {
  const _Status({
    required this.minHeight,
    required this.state,
    required this.onNewGame,
  });

  /// Texto longo (outros idiomas) pode passar disso; a lista de lances cede.
  final double minHeight;
  final FreeBoardState state;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final end = state.end;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.25),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: ConstrainedBox(
          key: ValueKey<Object>(end ?? state.position.turn),
          constraints: BoxConstraints(minHeight: minHeight),
          child: end == null
              ? _Turn(side: state.position.turn)
              : _End(end: end, onNewGame: onNewGame),
        ),
      ),
    );
  }
}

class _Turn extends StatelessWidget {
  const _Turn({required this.side});

  final Side side;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Disco da cor de quem joga.
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: side == Side.white ? Colors.white : Colors.black,
              border: Border.all(color: theme.colorScheme.outline, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              side == Side.white
                  ? context.l10n.freeBoardWhiteToMove
                  : context.l10n.freeBoardBlackToMove,
              key: FreeBoardKeys.turn,
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _End extends StatelessWidget {
  const _End({required this.end, required this.onNewGame});

  final GameEnd end;
  final VoidCallback onNewGame;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final reason = switch (end.reason) {
      GameEndReason.checkmate => l10n.freeBoardCheckmate,
      GameEndReason.stalemate => l10n.freeBoardStalemate,
      GameEndReason.insufficientMaterial => l10n.freeBoardInsufficientMaterial,
      GameEndReason.timeout => l10n.freeBoardTimeout,
      GameEndReason.timeoutVsInsufficientMaterial =>
        l10n.freeBoardTimeoutVsInsufficientMaterial,
    };
    final result = switch (end.winner) {
      Side.white => l10n.freeBoardWhiteWins,
      Side.black => l10n.freeBoardBlackWins,
      null => l10n.freeBoardDraw,
    };
    return ColoredBox(
      key: FreeBoardKeys.endPanel,
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
        child: Row(
          children: [
            Icon(
              end.winner == null ? Icons.handshake_outlined : Icons.flag,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    key: FreeBoardKeys.endReason,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  Text(
                    result,
                    key: FreeBoardKeys.endResult,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: FreeBoardKeys.endNewGameButton,
              onPressed: onNewGame,
              child: Text(l10n.freeBoardNewGame),
            ),
          ],
        ),
      ),
    );
  }
}
