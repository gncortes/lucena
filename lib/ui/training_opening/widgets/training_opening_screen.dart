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
import '../../core/keys/training_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_motion.dart';
import '../../core/widgets/exercise_actions.dart';
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
    super.key,
  });
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final Now now;
  final String lessonId;
  final Character teacher;
  final VoidCallback onNextGoal;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        TrainingOpeningCubit(repository: repository, config: config, now: now)
          ..load(lessonId: lessonId),
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
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _advance(TrainingOpeningState state) {
    if (state.phase != TrainingOpeningPhase.complete ||
        state.pending.isEmpty ||
        _fading) {
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
    listener: (_, state) => _advance(state),
    builder: (context, state) {
      final loading = state.phase == TrainingOpeningPhase.loading;
      final l = context.l10n;
      final cubit = context.read<TrainingOpeningCubit>();
      final ready =
          state.line != null && state.phase != TrainingOpeningPhase.expired;
      final bank = state.resources?.openings[state.lessonId] ?? [];
      final boardCenter =
          BoardViewport.usefulHeightOf(context) / 2 - kToolbarHeight;
      final screen = MediaQuery.sizeOf(context);
      // Preserve the natural speech/header when a full-width board cannot fit.
      final fullWidthFits =
          boardCenter - screen.width / 2 >= (screen.height < 780 ? 80 : 112);
      final number = bank.indexWhere((t) => t.id == state.trecho?.id) + 1;
      final lesson = state.resources?.lessons
          .where((l) => l.id == state.lessonId)
          .firstOrNull;
      return Scaffold(
        key: TrainingKeys.openingScreen,
        appBar: LucenaAppBar(
          leading: ModalRoute.of(context)?.canPop == true
              ? const BackButton(key: TrainingKeys.openingBack)
              : null,
          title: Text(
            key: TrainingKeys.openingTitle(state.lessonId ?? ''),
            ready
                ? l.trainingOpeningTitle(
                    lesson?.title ?? state.trecho!.title,
                    number,
                    bank.length,
                  )
                : l.trainingOpeningsTitle,
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
                  ignoring: loading,
                  child: CenteredBoardLayout(
                    centerY: boardCenter,
                    minFraction: fullWidthFits ? 1 : 0,
                    reserveTop: 120,
                    reserveBottom: 72,
                    gap: 0,
                    shrinkSides: false,
                    top: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          text: state.phase == TrainingOpeningPhase.complete
                              ? l.trainingOpeningComplete
                              : state.wrong
                              ? l.trainingOpeningWrong
                              : l.trainingOpeningPrompt,
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
                                for (var i = 0; i < state.cursor; i++)
                                  ScriptMoveEntry(
                                    id: '${i + 1}',
                                    san: state.line!.san[i],
                                    number: i ~/ 2 + 1,
                                    side: i.isEven ? Side.white : Side.black,
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
                    hint: ExerciseHintButton(
                      key: TrainingKeys.exerciseHint,
                      label: l.exerciseHintFree,
                      onPressed:
                          state.phase == TrainingOpeningPhase.playing &&
                              !state.reviewing
                          ? cubit.hint
                          : null,
                    ),
                    navigation: state.shown == 0
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
                      if (state.phase == TrainingOpeningPhase.complete &&
                          state.pending.isEmpty)
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
    final position = GameRules.fromFen(state.fen!)!;
    final playing =
        state.phase == TrainingOpeningPhase.playing &&
        !state.reviewing &&
        !_fading;
    final data = GameData(
      fen: state.fen!,
      playerSide: playing
          ? (state.trecho!.black ? PlayerSide.black : PlayerSide.white)
          : PlayerSide.none,
      sideToMove: position.turn,
      validMoves: playing ? GameRules.legalMoves(position) : const {},
      lastMove: state.shown == 0
          ? null
          : Move.parse(state.trecho!.moves[state.shown - 1]),
      kingSquareInCheck: GameRules.checkedKing(position),
    );
    final lineId = '${state.lessonId}:${state.trecho!.id}';
    final changedLine = _boardLine != lineId;
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
        ? Move.parse(state.trecho!.moves[state.cursor])
        : null;
    return Directionality(
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
  }
}
