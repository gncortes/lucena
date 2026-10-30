import 'dart:async';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/board/centered_board_layout.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/game_board_hero.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/teacher_speech.dart';
import '../../lesson_script/view_models/lesson_script_state.dart';
import '../../lesson_script/widgets/script_move_list.dart';
import '../../settings/view_models/settings_cubit.dart';
import '../view_models/training_opening_cubit.dart';

class TrainingOpeningScreen extends StatelessWidget {
  const TrainingOpeningScreen({
    required this.repository,
    required this.config,
    required this.now,
    required this.lessonId,
    required this.teacher,
    required this.onNextGoal,
    this.heroTag,
    this.preview,
    this.homeHero = false,
    this.partId,
    this.onProgress,
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String lessonId;
  final Character teacher;
  final VoidCallback onNextGoal;
  final Object? heroTag;
  final TrainingOpeningState? preview;
  final bool homeHero;
  final String? partId;
  final VoidCallback? onProgress;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => TrainingOpeningCubit(
      repository: repository,
      config: config,
      now: now,
      analytics: context.analytics,
      trainingAnalytics: context.trainingAnalytics,
    )..load(lessonId: lessonId, partId: partId),
    child: _OpeningView(screen: this),
  );
}

class _OpeningView extends StatefulWidget {
  const _OpeningView({required this.screen});
  final TrainingOpeningScreen screen;
  @override
  State<_OpeningView> createState() => _OpeningViewState();
}

class _OpeningViewState extends State<_OpeningView> {
  ChessboardController? _controller;
  String? _boardLine;
  bool _fading = false;
  Timer? _replay;
  String? _replayFen;
  int? _lastCursor;
  @override
  void dispose() {
    _replay?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _advance(TrainingOpeningState state) {
    if (state.phase != TrainingOpeningPhase.complete ||
        state.pending.isEmpty ||
        _fading ||
        state.trecho?.lines.isNotEmpty == true) {
      return;
    }
    setState(() => _fading = true);
  }

  Future<void> _onFadeEnd() async {
    if (!_fading) return;
    await context.read<TrainingOpeningCubit>().nextOpening();
    if (mounted) setState(() => _fading = false);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<TrainingOpeningCubit, TrainingOpeningState>(
    listener: (context, state) {
      _advance(state);
      if (state.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.trainingExerciseSaveError)),
        );
      }
    },
    builder: (context, state) {
      final loading = state.phase == TrainingOpeningPhase.loading;
      if (loading && widget.screen.preview != null) {
        state = widget.screen.preview!;
      }
      final l = context.l10n;
      final cubit = context.read<TrainingOpeningCubit>();
      final ready =
          state.line != null && state.phase != TrainingOpeningPhase.expired;
      final bank = state.resources?.openings[state.lessonId] ?? [];
      final screen = MediaQuery.sizeOf(context);
      final multipart = state.trecho?.lines.isNotEmpty == true;
      final boardCenter =
          BoardViewport.usefulHeightOf(context) / 2 -
          (multipart ? 64 : kToolbarHeight);
      // Preserve the natural speech/header when a full-width board cannot fit.
      final fullWidthFits =
          boardCenter - screen.width / 2 >= (screen.height < 780 ? 80 : 112);
      final number = bank.indexWhere((t) => t.id == state.trecho?.id) + 1;
      final notation = multipart
          ? state.line!.notationIndices(
              state.reviewing ? state.shown : state.cursor,
            )
          : [for (var i = 0; i < state.cursor; i++) i];
      final speechText = state.phase == TrainingOpeningPhase.complete
          ? state.allPartsDone
                ? l.trainingOpeningFinished(state.trecho!.title, bank.length)
                : l.trainingOpeningPartComplete(number)
          : state.wrong
          ? l.trainingOpeningWrong
          : state.firstTry.isNotEmpty
          ? l.trainingFixedCorrect
          : l.trainingOpeningPrompt;
      final lesson = state.resources?.lessons
          .where((l) => l.id == state.lessonId)
          .firstOrNull;
      return Scaffold(
        key: TrainingKeys.openingScreen,
        appBar: LucenaAppBar(
          toolbarHeight: multipart ? 64 : null,
          leading: ModalRoute.of(context)?.canPop == true
              ? const BackButton(key: TrainingKeys.openingBack)
              : null,
          title: Text(
            key: TrainingKeys.openingTitle(state.lessonId ?? ''),
            ready
                ? l.trainingOpeningTitle(
                    state.trecho!.lines.isNotEmpty
                        ? state.trecho!.title
                        : lesson?.title ?? state.trecho!.title,
                    number,
                    bank.length,
                  )
                : l.trainingOpeningsTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: SafeArea(
          child: !ready
              ? Center(
                  child: state.phase == TrainingOpeningPhase.loading
                      ? const CircularProgressIndicator()
                      : Text(
                          state.phase == TrainingOpeningPhase.expired
                              ? l.trainingExerciseExpired
                              : l.exerciseMissing,
                        ),
                )
              : IgnorePointer(
                  ignoring: loading || _replayFen != null,
                  child: CenteredBoardLayout(
                    centerY: boardCenter,
                    minFraction: fullWidthFits ? 1 : 0,
                    reserveTop: 120,
                    reserveBottom: multipart ? 56 : 72,
                    gap: 0,
                    shrinkSides: false,
                    top: Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        screen.height < 780 ? 0 : 8,
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          textTheme: Theme.of(context).textTheme.copyWith(
                            bodyLarge: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        child: TeacherSpeech(
                          teacher: widget.screen.teacher,
                          avatarSize: 40,
                          bubbleAboveHeader: true,
                          trainingLayout: true,
                          text: speechText,
                          speechContext: SpeechContext.teaching,
                        ),
                      ),
                    ),
                    board: LayoutBuilder(
                      builder: (context, box) => AnimatedOpacity(
                        opacity: _fading ? 0 : 1,
                        duration: AppMotion.of(context).component,
                        onEnd: _onFadeEnd,
                        child: _board(context, state, box.maxWidth),
                      ),
                    ),
                    bottom: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: ScriptMoveList(
                              moves: [
                                for (final i in notation)
                                  if (state.line!.moveAt(i) != null)
                                    ScriptMoveEntry(
                                      id: '${i + 1}',
                                      san: state.line!.san[i],
                                      number: state.line!.moveNumberAt(i),
                                      side: state.line!.sideAt(i),
                                      variant: false,
                                    ),
                              ],
                              currentId: state.shown == 0
                                  ? null
                                  : '${state.shown}',
                              onTap: (id) {
                                cubit.notationTap(int.parse(id));
                              },
                            ),
                          ),
                        ),
                        if (state.error)
                          Text(
                            l.trainingExerciseSaveError,
                            key: TrainingKeys.openingSaveError,
                          ),
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar: !ready
            ? null
            : SafeArea(
                child: IgnorePointer(
                  ignoring: loading,
                  child: ExerciseActions(
                    hug: state.phase == TrainingOpeningPhase.complete,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    hint: state.phase == TrainingOpeningPhase.complete
                        ? null
                        : ExerciseHintButton(
                            backgroundColor: AppColors.trainingHintSurface,
                            key: TrainingKeys.exerciseHint,
                            label: l.exerciseHintFree,
                            onPressed:
                                state.phase == TrainingOpeningPhase.playing &&
                                    !state.reviewing
                                ? cubit.hint
                                : null,
                          ),
                    navigation: state.phase == TrainingOpeningPhase.complete
                        ? null
                        : state.shown == 0
                        ? ExerciseNavigation.start
                        : state.shown == state.cursor
                        ? ExerciseNavigation.end
                        : ExerciseNavigation.middle,
                    onPreviousMove: () => cubit.review(state.shown - 1),
                    onNextMove: state.reviewing
                        ? () => cubit.review(state.shown + 1)
                        : null,
                    actions: [
                      if (state.error)
                        ExerciseAction(
                          key: TrainingKeys.openingSaveRetry,
                          label: l.lessonRetry,
                          primary: true,
                          onPressed: cubit.retry,
                        ),
                      if (state.phase == TrainingOpeningPhase.complete)
                        ExerciseAction(
                          key: state.allPartsDone
                              ? TrainingKeys.openingProgress
                              : TrainingKeys.openingNextPart,
                          label: state.allPartsDone
                              ? l.trainingViewProgress
                              : l.trainingNextPart,
                          onPressed: state.allPartsDone
                              ? widget.screen.onProgress
                              : cubit.nextPart,
                        ),
                      if (state.phase == TrainingOpeningPhase.complete)
                        ExerciseAction(
                          key: TrainingKeys.nextGoal,
                          label: l.trainingNextGoal,
                          primary: true,
                          onPressed: widget.screen.onNextGoal,
                        ),
                    ],
                  ),
                ),
              ),
      );
    },
  );

  Widget _board(BuildContext context, TrainingOpeningState state, double size) {
    final cubit = context.read<TrainingOpeningCubit>();
    final lineId = '${state.lessonId}:${state.trecho!.id}';
    final changedLine = _boardLine != lineId;
    final animation = AppMotion.of(context).component;
    if (changedLine) {
      _replay?.cancel();
      _replayFen = null;
    } else if (_lastCursor != state.cursor &&
        !state.reviewing &&
        state.transitionFens.length > 1 &&
        animation > Duration.zero) {
      _replay?.cancel();
      final frames = state.transitionFens;
      var frame = 0;
      _replayFen = frames.first;
      _replay = Timer.periodic(animation, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          frame++;
          if (frame >= frames.length) {
            timer.cancel();
            _replayFen = null;
          } else {
            _replayFen = frames[frame];
          }
        });
      });
    }
    _lastCursor = state.cursor;
    final fen = _replayFen ?? state.fen!;
    final position = GameRules.fromFen(fen)!;
    final playing =
        state.phase == TrainingOpeningPhase.playing &&
        !state.reviewing &&
        !_fading &&
        _replayFen == null;
    final data = GameData(
      fen: fen,
      playerSide: playing
          ? (position.turn == Side.black ? PlayerSide.black : PlayerSide.white)
          : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: playing ? GameRules.legalMoves(position) : const {},
      lastMove: state.shown == 0
          ? null
          : state.line!.moveAt(state.shown - 1) == null
          ? null
          : Move.parse(state.line!.moveAt(state.shown - 1)!),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
    if (_controller == null) {
      _controller = ChessboardController(game: data);
    } else {
      _controller!.updatePosition(
        data,
        animate: !state.wrong && !changedLine,
        resetPremove: true,
      );
    }
    _boardLine = lineId;
    final settings = context.select(
      (SettingsCubit c) => c.state?.board ?? const BoardSettings(),
    );
    final hint = playing && state.hint
        ? Move.parse(state.line!.acceptedAt(state.cursor).first)
        : null;
    Widget board = Directionality(
      textDirection: TextDirection.ltr,
      child: Chessboard(
        key: TrainingKeys.openingBoard,
        size: size,
        controller: _controller!,
        orientation: state.trecho!.black ? Side.black : Side.white,
        settings: settings.chessground,
        shapes: {
          if (hint is NormalMove)
            Arrow(
              color: Theme.of(context).colorScheme.primary,
              orig: hint.from,
              dest: hint.to,
            ),
        },
        onMove: (move, {viaDragAndDrop}) => cubit.play(move.uci),
      ),
    );
    if (widget.screen.homeHero) {
      board = GameBoardHero(
        orientation: state.trecho!.black ? Side.black : Side.white,
        child: board,
      );
    } else if (widget.screen.heroTag case final tag?) {
      board = Hero(tag: tag, child: board);
    }
    return board;
  }
}
