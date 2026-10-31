import '../../core/theme/app_shape.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_colors.dart';

import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/board_settings.dart';
import '../../../domain/models/game_review.dart';
import '../../../domain/models/learning_analysis.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/learning_analysis_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/learning_analysis_cubit.dart';

const _background = AppColors.trainingCanvasSurface;
const _primary = AppColors.trainingAnalysisPrimary;

class LearningAnalysisScreen extends StatelessWidget {
  const LearningAnalysisScreen({this.engineName = 'Stockfish', super.key});
  final String engineName;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<LearningAnalysisCubit, LearningAnalysisState>(
    listenWhen: (before, after) => !before.saveFailed && after.saveFailed,
    listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.learningAnalysisSaveError)),
    ),
    builder: (context, state) {
      final cubit = context.read<LearningAnalysisCubit>();
      final l10n = context.l10n;
      final session = state.session;
      return Scaffold(
        key: LearningAnalysisKeys.screen,
        backgroundColor: _background,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: _background,
          titleSpacing: 0,
          leading: IconButton(
            key: LearningAnalysisKeys.back,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(CanvasSymbols.arrowBack),
          ),
          title: Text(
            l10n.learningAnalysisTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w400),
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
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final engineHeight = state.settings.showEngine
                  ? 8 + 41.0 * state.settings.lines
                  : 0.0;
              final content = Column(
                children: [
                  if (state.settings.showEngine) ...[
                    _evaluation(state, cubit.launch.orientation),
                    _engine(context, state),
                  ],
                  _AnalysisBoard(size: constraints.maxWidth),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: _notation(context, session),
                  ),
                ],
              );
              final needed = engineHeight + constraints.maxWidth + 80;
              return Column(
                children: [
                  Expanded(
                    child: needed > constraints.maxHeight - 54
                        ? SingleChildScrollView(child: content)
                        : Align(alignment: Alignment.topCenter, child: content),
                  ),
                  SizedBox(
                    height: 54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _navigation(
                          LearningAnalysisKeys.first,
                          l10n.learningAnalysisFirst,
                          CanvasSymbols.firstPage,
                          state.ready && session.selected != 0
                              ? cubit.first
                              : null,
                        ),
                        _navigation(
                          LearningAnalysisKeys.previous,
                          l10n.learningAnalysisPrevious,
                          CanvasSymbols.chevronLeft,
                          state.ready && session.current.parent != null
                              ? cubit.previous
                              : null,
                          filled: true,
                        ),
                        _navigation(
                          LearningAnalysisKeys.next,
                          l10n.learningAnalysisNext,
                          CanvasSymbols.chevronRight,
                          state.ready &&
                                  session.children(session.selected).isNotEmpty
                              ? cubit.next
                              : null,
                          filled: true,
                        ),
                        _navigation(
                          LearningAnalysisKeys.last,
                          l10n.learningAnalysisLast,
                          CanvasSymbols.lastPage,
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
    },
  );

  Widget _navigation(
    Key key,
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool filled = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: IconButton(
      key: key,
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

  Widget _evaluation(LearningAnalysisState state, Side orientation) {
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

  Widget _engine(BuildContext context, LearningAnalysisState state) {
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
                          _score(state.lines[i].score),
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
                          _lineText(context, position, state.lines[i].moves),
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

  String _score(EngineScore score) {
    if (score.mate != null) return '#${score.mate}';
    final cp = score.centipawns;
    if (cp == null) return '—';
    return '${cp > 0 ? '+' : ''}${(cp / 100).toStringAsFixed(1).replaceAll('.', ',')}'
        .replaceAll('-', '−');
  }

  TextSpan _lineText(
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

  String _line(BuildContext context, Position position, List<String> moves) {
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

  Widget _notation(BuildContext context, LearningAnalysisSession session) {
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
    void chip(int index, {bool alternate = false}) {
      final node = session.nodes[index];
      final parent = GameRules.fromFen(session.nodes[node.parent!].fen)!;
      final number = parent.turn == Side.white
          ? '${parent.fullmoves}. '
          : node.parent == 0 || alternate
          ? '${parent.fullmoves}... '
          : '';
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
                foregroundColor: session.selected == index
                    ? AppColors.chessWhiteColor
                    : AppColors.trainingCanvasInk,
                backgroundColor: session.selected == index
                    ? _primary
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppShape.small),
                ),
              ),
              child: Text(
                localizedSan(context.l10n, node.san!),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
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

  Future<void> _settings(BuildContext context) async {
    final cubit = context.read<LearningAnalysisCubit>();
    var showEngine = cubit.state.settings.showEngine;
    var lines = cubit.state.settings.lines;
    final result = await showModalBottomSheet<LearningAnalysisSettings>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
