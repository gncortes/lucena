import '../../core/motion/folha_lucena.dart';
import '../../core/theme/app_bar_height.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_colors.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';

import '../../course_guide/widgets/training_load_error.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/models/learning_analysis.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/keys/learning_analysis_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/learning_analysis_cubit.dart';

const _background = AppColors.trainingCanvasSurface;
const _primary = AppColors.trainingAnalysisPrimary;

class LearningAnalysisScreen extends StatelessWidget {
  const LearningAnalysisScreen({
    this.engineName = 'Stockfish',
    this.title,
    this.annotations = const {},
    super.key,
  });
  final String engineName;

  /// O título no lugar de "Análise" (Treinador: "Análise da partida").
  final String? title;

  /// As marcas por nó da linha principal (sufixo de erro e comentário).
  final Map<int, AnalysisAnnotation> annotations;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<LearningAnalysisCubit, LearningAnalysisState>(
        listenWhen: (before, after) => !before.saveFailed && after.saveFailed,
        listener: (context, state) => ScaffoldMessenger.of(context)
            .showSnackBar(
              SnackBar(content: Text(context.l10n.learningAnalysisSaveError)),
            ),
        builder: (context, state) {
          final cubit = context.read<LearningAnalysisCubit>();
          final l10n = context.l10n;
          if (state.failure case final failure?) {
            return trainingLoadError(context, failure, cubit.load);
          }
          return Scaffold(
            key: LearningAnalysisKeys.screen,
            backgroundColor: _background,
            appBar: AppBar(
              toolbarHeight: AppBarHeight.standard,
              backgroundColor: _background,
              titleSpacing: 0,
              leading: IconButton(
                key: LearningAnalysisKeys.back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(CanvasSymbols.arrowBack),
              ),
              title: Text(
                title ?? l10n.learningAnalysisTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              actions: [
                IconButton(
                  key: LearningAnalysisKeys.settings,
                  tooltip: l10n.learningAnalysisSettings,
                  onPressed: state.ready ? () => _settings(context) : null,
                  icon: const Icon(CanvasSymbols.settings),
                ),
              ],
              shape: const Border(
                bottom: BorderSide(color: AppColors.trainingAnalysisDivider),
              ),
            ),
            body: _AnalysisBody(state: state, annotations: annotations),
          );
        },
      );

  static String _score(EngineScore score) {
    if (score.mate != null) return '#${score.mate}';
    final cp = score.centipawns;
    if (cp == null) return '—';
    return '${cp > 0 ? '+' : ''}${(cp / 100).toStringAsFixed(1).replaceAll('.', ',')}'
        .replaceAll('-', '−');
  }

  static TextSpan _lineText(
    BuildContext context,
    Position position,
    List<String> moves,
  ) {
    final line = _line(context, position, moves);
    final separator = line.indexOf(' ');
    if (separator < 0) return TextSpan(text: line);
    return TextSpan(
      children: [
        TextSpan(
          text: line.substring(0, separator),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.trainingCanvasInk,
          ),
        ),
        TextSpan(text: line.substring(separator)),
      ],
    );
  }

  static String _line(
    BuildContext context,
    Position position,
    List<String> moves,
  ) {
    final output = <String>[];
    var current = position;
    for (final uci in moves) {
      final move = Move.parse(uci);
      final played = move == null ? null : GameRules.play(current, move);
      if (played == null) break;
      final number = current.fullmoves;
      output.add(
        '${current.turn == Side.white
            ? '$number. '
            : output.isEmpty
            ? '$number... '
            : ''}${localizedSan(context.l10n, played.san)}',
      );
      current = played.position;
    }
    return output.join(' ');
  }

  Future<void> _settings(BuildContext context) async {
    final cubit = context.read<LearningAnalysisCubit>();
    var showEngine = cubit.state.settings.showEngine;
    var lines = cubit.state.settings.lines;
    final result = await FolhaLucena.mostrar<LearningAnalysisSettings>(
      context,
      useSafeArea: false,
      elevation: null,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 56),
              child: Container(
                key: LearningAnalysisKeys.sheet,
                decoration: const BoxDecoration(
                  color: AppColors.chessWhiteColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppShape.extraLarge),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 32,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.trainingAnalysisInactive,
                              borderRadius: BorderRadius.circular(
                                AppShape.hairline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          context.l10n.learningAnalysisEngine,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.l10n.learningAnalysisShowEngine,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    context.l10n.learningAnalysisEngineDetail(
                                      engineName,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.trainingCanvasSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              key: LearningAnalysisKeys.showEngine,
                              value: showEngine,
                              onChanged: (value) =>
                                  setState(() => showEngine = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.learningAnalysisLines,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.trainingCanvasSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: SegmentedButton<int>(
                            key: LearningAnalysisKeys.lines,
                            expandedInsets: EdgeInsets.zero,
                            showSelectedIcon: false,
                            style: const ButtonStyle(
                              visualDensity: VisualDensity.standard,
                              minimumSize: WidgetStatePropertyAll(Size(0, 40)),
                              padding: WidgetStatePropertyAll(EdgeInsets.zero),
                            ),
                            segments: [
                              for (var i = 1; i <= 3; i++)
                                ButtonSegment(
                                  value: i,
                                  label: Text(i.toString()),
                                ),
                            ],
                            selected: {lines},
                            onSelectionChanged: (selection) =>
                                setState(() => lines = selection.single),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            key: LearningAnalysisKeys.confirm,
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              LearningAnalysisSettings(
                                showEngine: showEngine,
                                lines: lines,
                              ),
                            ),
                            child: Text(context.l10n.learningAnalysisConfirm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              child: Material(
                color: AppColors.chessWhiteColor,
                elevation: 3,
                shape: const CircleBorder(),
                child: IconButton(
                  key: LearningAnalysisKeys.close,
                  tooltip: context.l10n.learningAnalysisClose,
                  onPressed: () => Navigator.pop(sheetContext),
                  icon: const Icon(CanvasSymbols.close),
                  style: IconButton.styleFrom(fixedSize: const Size.square(44)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && !cubit.isClosed) await cubit.confirmSettings(result);
  }
}

class _AnalysisBoard extends StatefulWidget {
  const _AnalysisBoard({required this.size});
  final double size;
  @override
  State<_AnalysisBoard> createState() => _AnalysisBoardState();
}

class _AnalysisBoardState extends State<_AnalysisBoard> {
  late final ChessboardController controller;
  @override
  void initState() {
    super.initState();
    controller = ChessboardController(
      game: _game(context.read<LearningAnalysisCubit>().state),
    );
  }

  GameData _game(LearningAnalysisState state) {
    final position = GameRules.fromFen(state.session.current.fen)!;
    final live = state.ready && GameRules.endOf(position) == null;
    return GameData(
      fen: position.fen,
      playerSide: !live
          ? PlayerSide.none
          : position.turn == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position.turn,
      validMoves: live ? GameRules.legalMoves(position) : const {},
      lastMove: state.session.current.uci == null
          ? null
          : Move.parse(state.session.current.uci!),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LearningAnalysisCubit>();
    final state = context.watch<LearningAnalysisCubit>().state;
    final board = context.select(
      (SettingsCubit cubit) => cubit.state?.board ?? const BoardSettings(),
    );
    controller.updatePosition(_game(state), animate: false, resetPremove: true);
    return Chessboard(
      key: LearningAnalysisKeys.board,
      size: widget.size,
      controller: controller,
      orientation: cubit.launch.orientation,
      settings: board.chessground.copyWith(
        borderRadius: BorderRadius.zero,
        enablePremoves: false,
      ),
      onMove: (move, {viaDragAndDrop}) => cubit.play(move.uci),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: IconButton(
      key: buttonKey,
      tooltip: label,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: filled
            ? AppColors.trainingAnalysisSelected
            : Colors.transparent,
        foregroundColor: _primary,
        disabledBackgroundColor: filled
            ? AppColors.trainingAnalysisHistory
            : Colors.transparent,
        fixedSize: const Size.square(40),
      ),
      icon: Icon(icon, size: AppIconSize.standard),
    ),
  );
}

class _EvaluationBar extends StatelessWidget {
  const _EvaluationBar({required this.state, required this.orientation});

  final LearningAnalysisState state;
  final Side orientation;

  @override
  Widget build(BuildContext context) {
    final percent = state.lines.firstOrNull?.score.whiteWinPercent;
    final fraction = percent == null
        ? null
        : (orientation == Side.white ? percent : 100 - percent) / 100;
    return SizedBox(
      key: LearningAnalysisKeys.evaluation,
      height: 8,
      child: fraction == null
          ? const ColoredBox(
              color: AppColors.trainingAnalysisDivider,
              child: SizedBox.expand(),
            )
          : LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  SizedBox(
                    width: constraints.maxWidth * fraction,
                    child: ColoredBox(
                      color: orientation == Side.white
                          ? AppColors.chessWhiteColor
                          : AppColors.trainingAnalysisDark,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: orientation == Side.white
                          ? AppColors.trainingAnalysisDark
                          : AppColors.chessWhiteColor,
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _EngineLines extends StatelessWidget {
  const _EngineLines({required this.state});

  final LearningAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final position = GameRules.fromFen(state.session.current.fen)!;
    return Column(
      key: LearningAnalysisKeys.engine,
      children: [
        for (var i = 0; i < state.settings.lines; i++)
          Container(
            height: 41,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.trainingAnalysisDivider),
              ),
            ),
            child: i >= state.lines.length
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: state.loading
                        ? SizedBox(
                            width: 160 + i * 35,
                            height: 12,
                            child: const ColoredBox(
                              color: AppColors.trainingAnalysisSkeleton,
                            ),
                          )
                        : const SizedBox.shrink(),
                  )
                : Row(
                    children: [
                      Container(
                        width: 48,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: state.lines[i].score.cappedCentipawns < 0
                              ? AppColors.trainingAnalysisDark
                              : AppColors.chessWhiteColor,
                          borderRadius: BorderRadius.circular(AppShape.small),
                          border: Border.all(
                            color: AppColors.trainingAnalysisDivider,
                          ),
                        ),
                        child: Text(
                          LearningAnalysisScreen._score(state.lines[i].score),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: state.lines[i].score.cappedCentipawns < 0
                                ? AppColors.chessWhiteColor
                                : AppColors.trainingCanvasInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          LearningAnalysisScreen._lineText(
                            context,
                            position,
                            state.lines[i].moves,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.trainingCanvasSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }
}

class _NotationStrip extends StatelessWidget {
  const _NotationStrip({required this.session, required this.annotations});

  final LearningAnalysisSession session;

  /// Ver [LearningAnalysisScreen.annotations].
  final Map<int, AnalysisAnnotation> annotations;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    if (session.selected == 0) {
      widgets.add(
        TextButton(
          key: LearningAnalysisKeys.move(0),
          onPressed: () => context.read<LearningAnalysisCubit>().first(),
          style: TextButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: AppColors.chessWhiteColor,
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShape.small),
            ),
          ),
          child: Text(context.l10n.learningAnalysisFirst),
        ),
      );
    }
    var afterComment = false;
    void chip(int index, {bool alternate = false}) {
      final node = session.nodes[index];
      final parent = GameRules.fromFen(session.nodes[node.parent!].fen)!;
      final number = parent.turn == Side.white
          ? '${parent.fullmoves}. '
          : node.parent == 0 || alternate || afterComment
          ? '${parent.fullmoves}... '
          : '';
      afterComment = false;
      final note = alternate ? null : annotations[index];
      final selected = session.selected == index;
      widgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (number.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.trainingCanvasSecondary,
                  ),
                ),
              ),
            TextButton(
              key: LearningAnalysisKeys.move(index),
              onPressed: () =>
                  context.read<LearningAnalysisCubit>().select(index),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: selected
                    ? AppColors.chessWhiteColor
                    : AppColors.trainingCanvasInk,
                backgroundColor: selected ? _primary : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
              ),
              child: Text.rich(
                TextSpan(
                  text: localizedSan(context.l10n, node.san!),
                  children: [
                    if (note?.suffix case final suffix?)
                      TextSpan(
                        text: suffix,
                        style: TextStyle(
                          color: selected
                              ? AppColors.chessWhiteColor
                              : AppColors.trainingDayWrong,
                        ),
                      ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      if (note?.comment case final comment? when comment.isNotEmpty) {
        widgets.add(
          SizedBox(
            key: LearningAnalysisKeys.comment(index),
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.trainingCanvasInk,
                ),
              ),
            ),
          ),
        );
        afterComment = true;
      }
    }

    void branch(int parent) {
      final children = session.children(parent);
      if (children.isNotEmpty) {
        chip(children.first);
        for (final alternative in children.skip(1)) {
          widgets.add(
            const Text(
              '(',
              style: TextStyle(
                color: AppColors.trainingCanvasMuted,
                fontSize: 16,
              ),
            ),
          );
          chip(alternative, alternate: true);
          branch(alternative);
          widgets.add(
            const Text(
              ')',
              style: TextStyle(
                color: AppColors.trainingCanvasMuted,
                fontSize: 16,
              ),
            ),
          );
        }
        branch(children.first);
      }
    }

    branch(0);
    return SingleChildScrollView(
      key: LearningAnalysisKeys.notation,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: widgets,
      ),
    );
  }
}

/// O corpo da tela: o tabuleiro no centro útil, o motor em cima, a notação
/// embaixo e a navegação pelos lances.
class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.state, required this.annotations});

  final LearningAnalysisState state;
  final Map<int, AnalysisAnnotation> annotations;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LearningAnalysisCubit>();
    final l10n = context.l10n;
    final session = state.session;
    return BoardViewport(
      usefulHeight: BoardViewport.usefulHeightOf(context),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final engineHeight = state.settings.showEngine
                ? 8 + 41.0 * state.settings.lines
                : 0.0;
            // A8: o centro do tabuleiro fica no centro útil da tela; o
            // motor fica colado em cima, a notação embaixo. Se não couber,
            // rola com o tabuleiro inteiro.
            return Column(
              children: [
                Expanded(
                  child: CenteredBoardLayout(
                    centerY: BoardViewport.centerYOf(context),
                    gap: 0,
                    reserveTop: engineHeight,
                    reserveBottom: 80,
                    minBoardSide: constraints.maxWidth,
                    top: state.settings.showEngine
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _EvaluationBar(
                                state: state,
                                orientation: cubit.launch.orientation,
                              ),
                              _EngineLines(state: state),
                            ],
                          )
                        : null,
                    board: LayoutBuilder(
                      builder: (context, box) =>
                          _AnalysisBoard(size: box.maxWidth),
                    ),
                    bottom: SizedBox(
                      width: double.infinity,
                      height: 80,
                      child: _NotationStrip(
                        session: session,
                        annotations: annotations,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _NavButton(
                        buttonKey: LearningAnalysisKeys.first,
                        label: l10n.learningAnalysisFirst,
                        icon: CanvasSymbols.firstPage,
                        onPressed: state.ready && session.selected != 0
                            ? cubit.first
                            : null,
                      ),
                      _NavButton(
                        buttonKey: LearningAnalysisKeys.previous,
                        label: l10n.learningAnalysisPrevious,
                        icon: CanvasSymbols.chevronLeft,
                        onPressed: state.ready && session.current.parent != null
                            ? cubit.previous
                            : null,
                        filled: true,
                      ),
                      _NavButton(
                        buttonKey: LearningAnalysisKeys.next,
                        label: l10n.learningAnalysisNext,
                        icon: CanvasSymbols.chevronRight,
                        onPressed:
                            state.ready &&
                                session.children(session.selected).isNotEmpty
                            ? cubit.next
                            : null,
                        filled: true,
                      ),
                      _NavButton(
                        buttonKey: LearningAnalysisKeys.last,
                        label: l10n.learningAnalysisLast,
                        icon: CanvasSymbols.lastPage,
                        onPressed:
                            state.ready &&
                                session.children(session.selected).isNotEmpty
                            ? cubit.last
                            : null,
                      ),
                    ],
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
