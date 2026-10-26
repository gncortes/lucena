import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../routing/routes.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/board_controls_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/board_controls_cubit.dart';

class BoardControlsScreen extends StatefulWidget {
  const BoardControlsScreen({super.key});

  @override
  State<BoardControlsScreen> createState() => _BoardControlsScreenState();
}

class _BoardControlsScreenState extends State<BoardControlsScreen> {
  late final _board = ChessboardController(
    game: _data(context.read<BoardControlsCubit>().state),
  );

  GameData _data(BoardControlsState state) => GameData(
    fen: state.position.fen,
    playerSide: PlayerSide.both,
    sideToMove: state.position.turn,
    validMoves: GameRules.legalMoves(state.position),
    lastMove: state.lastMove,
    kingSquareInCheck: GameRules.checkedKing(state.position),
  );

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<BoardControlsCubit>();
    final board =
        context.select((SettingsCubit cubit) => cubit.state?.board) ??
        const BoardSettings();
    return BlocConsumer<BoardControlsCubit, BoardControlsState>(
      listener: (context, state) {
        _board.updatePosition(_data(state));
        if (state.leaving) context.go(Routes.home);
      },
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) cubit.finish(completed: false);
        },
        child: Scaffold(
          key: BoardControlsKeys.screen,
          appBar: LucenaAppBar(
            title: Text(l10n.boardMoveMethod),
            leading: BackButton(
              onPressed: () => cubit.finish(completed: false),
            ),
          ),
          body: BoardViewport(
            usefulHeight: BoardViewport.usefulHeightOf(context),
            child: SafeArea(
              child: Builder(
                builder: (context) => CenteredBoardLayout(
                  centerY: BoardViewport.centerYOf(context),
                  reserveTop: 100,
                  reserveBottom: 0,
                  top: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      state.moved
                          ? l10n.boardControlsDone
                          : l10n.boardControlsHint,
                      key: BoardControlsKeys.instruction,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  board: LayoutBuilder(
                    builder: (context, box) => Chessboard(
                      key: BoardControlsKeys.board,
                      size: box.maxWidth,
                      controller: _board,
                      orientation: Side.white,
                      settings: board
                          .copyWith(
                            moveMethod: MoveMethod.either,
                            showLegalMoves: true,
                            premoves: false,
                          )
                          .chessground,
                      onMove: (move, {viaDragAndDrop}) => cubit.play(move),
                    ),
                  ),
                  footer: ActionsFooter(
                    children: [
                      FilledButton(
                        key: BoardControlsKeys.continueButton,
                        onPressed: cubit.finish,
                        child: Text(
                          state.moved
                              ? l10n.goalContinue
                              : l10n.boardControlsSkip,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
