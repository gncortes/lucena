import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/endgame_position.dart';
import '../../../domain/use_cases/position_validation.dart';
import '../../../routing/routes.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/custom_position_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/custom_position_cubit.dart';

/// Montar uma posição: no editor (tocar na peça da paleta e depois nas casas)
/// ou colando um FEN. A posição só segue quando é jogável.
class CustomPositionScreen extends StatefulWidget {
  const CustomPositionScreen({super.key});

  @override
  State<CustomPositionScreen> createState() => _CustomPositionScreenState();
}

class _CustomPositionScreenState extends State<CustomPositionScreen> {
  // Começa com o FEN do estado: o rascunho pode ter sido lido antes de a tela
  // se inscrever no view model.
  late final _fen = TextEditingController(
    text: context.read<CustomPositionCubit>().state.fen,
  );

  // A ferramenta do editor: uma peça para pôr, a borracha (nulo com
  // [_erasing]) ou mover (nenhuma das duas).
  Piece? _tool;
  bool _erasing = false;

  @override
  void initState() {
    super.initState();
    // O campo é ouvido direto (e não só pela digitação): colar pelo menu,
    // ditar ou trocar o texto por código também chega ao view model.
    _fen.addListener(_onFenEdited);
  }

  void _onFenEdited() {
    final cubit = context.read<CustomPositionCubit>();
    if (_fen.text.trim() != cubit.state.fen) cubit.setFen(_fen.text);
  }

  @override
  void dispose() {
    _fen.dispose();
    super.dispose();
  }

  Pieces _pieces(CustomPositionState state) => readFen(state.board);

  void _edit(Pieces Function(Pieces) change) {
    final cubit = context.read<CustomPositionCubit>();
    cubit.setBoard(writeFen(change(Map.of(_pieces(cubit.state)))));
  }

  void _onEditedSquare(Square square) {
    final tool = _tool;
    _edit((pieces) {
      if (_erasing) {
        pieces.remove(square);
      } else if (tool != null) {
        // Tocar de novo na mesma peça tira a peça da casa.
        if (pieces[square] == tool) {
          pieces.remove(square);
        } else {
          pieces[square] = tool;
        }
      }
      return pieces;
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    context.read<CustomPositionCubit>().setFen(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CustomPositionCubit>();
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    return BlocConsumer<CustomPositionCubit, CustomPositionState>(
      // O campo acompanha o editor; o que o jogador digita não é reescrito.
      listener: (context, state) {
        if (_fen.text.trim() != state.fen) {
          _fen.value = TextEditingValue(
            text: state.fen,
            selection: TextSelection.collapsed(offset: state.fen.length),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          key: CustomPositionKeys.screen,
          appBar: AppBar(
            title: Text(l10n.customPositionTitle),
            actions: [
              IconButton(
                key: CustomPositionKeys.clearButton,
                icon: const Icon(Icons.layers_clear_outlined),
                tooltip: l10n.customClear,
                onPressed: cubit.clear,
              ),
            ],
          ),
          body: !state.ready
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    // O tabuleiro fica parado no alto: arrastar nele move as
                    // peças, nunca rola a tela.
                    _editor(state, board),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 16),
                        children: [
                          _palette(board),
                          const SizedBox(height: 12),
                          _turnAndGoal(state),
                          _fenField(state),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: FilledButton(
                          key: CustomPositionKeys.continueButton,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          onPressed: state.position == null
                              ? null
                              : () => context.push(
                                  Routes.setup(
                                    state.position!.fen,
                                    goal: state.goal.code,
                                  ),
                                ),
                          child: Text(l10n.customContinue),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _editor(CustomPositionState state, BoardSettings board) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = MediaQuery.sizeOf(context);
        final size = math.min(
          math.min(constraints.maxWidth, 420.0),
          screen.height * 0.42,
        );
        return Center(
          // O tabuleiro não espelha em idiomas da direita para a esquerda.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ChessboardEditor(
              key: CustomPositionKeys.editor,
              size: size,
              orientation: Side.white,
              pieces: _pieces(state),
              settings: board.chessground,
              pointerMode: _tool != null || _erasing
                  ? EditorPointerMode.edit
                  : EditorPointerMode.drag,
              onEditedSquare: _onEditedSquare,
              onDroppedPiece: (origin, destination, piece) => _edit((pieces) {
                if (origin != null) pieces.remove(origin);
                pieces[destination] = piece;
                return pieces;
              }),
              onDiscardedPiece: (square) =>
                  _edit((pieces) => pieces..remove(square)),
            ),
          ),
        );
      },
    );
  }

  Widget _palette(BoardSettings board) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    const roles = [
      Role.king,
      Role.queen,
      Role.rook,
      Role.bishop,
      Role.knight,
      Role.pawn,
    ];
    Widget tool({
      required Key key,
      required bool selected,
      required String tooltip,
      required Widget child,
      required VoidCallback onTap,
    }) {
      return Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: selected,
          label: tooltip,
          excludeSemantics: true,
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  width: 2,
                  color: selected ? colors.primary : Colors.transparent,
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
    }

    Widget row(Side side) => Wrap(
      spacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final role in roles)
          () {
            final piece = Piece(color: side, role: role);
            return tool(
              key: CustomPositionKeys.palette(piece),
              selected: _tool == piece,
              tooltip: l10n.pieceOfSide(
                _roleName(l10n, role),
                side == Side.white ? l10n.sideWhite : l10n.sideBlack,
              ),
              child: Image(image: board.pieces.assets[piece.kind]!),
              onTap: () => setState(() {
                _tool = piece;
                _erasing = false;
              }),
            );
          }(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        spacing: 6,
        children: [
          // A paleta é sempre da esquerda para a direita, como o tabuleiro.
          Directionality(
            textDirection: TextDirection.ltr,
            child: row(Side.white),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: row(Side.black),
          ),
          Wrap(
            spacing: 6,
            children: [
              tool(
                key: CustomPositionKeys.moveTool,
                selected: _tool == null && !_erasing,
                tooltip: l10n.customToolMove,
                child: const Icon(Icons.pan_tool_alt_outlined),
                onTap: () => setState(() {
                  _tool = null;
                  _erasing = false;
                }),
              ),
              tool(
                key: CustomPositionKeys.eraseTool,
                selected: _erasing,
                tooltip: l10n.customToolErase,
                child: const Icon(Icons.backspace_outlined),
                onTap: () => setState(() {
                  _tool = null;
                  _erasing = true;
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _turnAndGoal(CustomPositionState state) {
    final l10n = context.l10n;
    final cubit = context.read<CustomPositionCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        spacing: 10,
        children: [
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Side>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: Side.white,
                  label: Text(
                    l10n.freeBoardWhiteToMove,
                    key: CustomPositionKeys.turn(Side.white),
                  ),
                ),
                ButtonSegment(
                  value: Side.black,
                  label: Text(
                    l10n.freeBoardBlackToMove,
                    key: CustomPositionKeys.turn(Side.black),
                  ),
                ),
              ],
              selected: {state.turn},
              onSelectionChanged: (selected) => cubit.setTurn(selected.single),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<PositionGoal>(
              showSelectedIcon: false,
              segments: [
                for (final goal in PositionGoal.values)
                  ButtonSegment(
                    value: goal,
                    icon: Icon(
                      goal == PositionGoal.win
                          ? Icons.emoji_events_outlined
                          : Icons.shield_outlined,
                    ),
                    label: Text(
                      goalLabel(l10n, goal),
                      key: CustomPositionKeys.goal(goal),
                    ),
                  ),
              ],
              selected: {state.goal},
              onSelectionChanged: (selected) => cubit.setGoal(selected.single),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fenField(CustomPositionState state) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final problem = state.problem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O FEN é sempre da esquerda para a direita.
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              key: CustomPositionKeys.fenField,
              controller: _fen,
              autocorrect: false,
              enableSuggestions: false,
              maxLines: 2,
              minLines: 1,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                labelText: l10n.customFen,
                helperText: l10n.customFenHint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  key: CustomPositionKeys.pasteButton,
                  icon: const Icon(Icons.content_paste),
                  tooltip: l10n.customPaste,
                  onPressed: _paste,
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: problem == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            problemMessage(l10n, problem),
                            key: CustomPositionKeys.error,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

String _roleName(AppLocalizations l10n, Role role) => switch (role) {
  Role.king => l10n.pieceKing,
  Role.queen => l10n.pieceQueen,
  Role.rook => l10n.pieceRook,
  Role.bishop => l10n.pieceBishop,
  Role.knight => l10n.pieceKnight,
  Role.pawn => l10n.piecePawn,
};

/// O problema da posição, em palavras.
String problemMessage(AppLocalizations l10n, PositionProblem problem) =>
    switch (problem) {
      PositionProblem.invalidFen => l10n.positionErrorInvalidFen,
      PositionProblem.empty => l10n.positionErrorEmpty,
      PositionProblem.missingWhiteKing => l10n.positionErrorMissingWhiteKing,
      PositionProblem.missingBlackKing => l10n.positionErrorMissingBlackKing,
      PositionProblem.tooManyKings => l10n.positionErrorTooManyKings,
      PositionProblem.oppositeCheck => l10n.positionErrorOppositeCheck,
      PositionProblem.impossibleCheck => l10n.positionErrorImpossibleCheck,
      PositionProblem.pawnsOnBackrank => l10n.positionErrorPawnsOnBackrank,
      PositionProblem.alreadyOver => l10n.positionErrorAlreadyOver,
    };
