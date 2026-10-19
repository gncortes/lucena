import 'dart:async';
import 'dart:math' as math;

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/assessment_attempt.dart';
import '../../../domain/models/board_settings.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/endgames_keys.dart';
import '../../core/theme/app_button.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../view_models/assessment_cubit.dart';
import 'assessment_response_form.dart';

/// Localized, neutral collection copy. No evaluation is rendered by this screen.
class AssessmentScreenLabels {
  const AssessmentScreenLabels({
    required this.title,
    required this.loading,
    required this.technicalFailure,
    required this.retry,
    required this.exit,
    required this.submitInitial,
    required this.finishExecution,
    required this.submitProtection,
    required this.closed,
    required this.phase,
    required this.remaining,
    required this.snapshot,
    this.newAttempt,
  });

  final String title, loading, technicalFailure, retry, exit;
  final String submitInitial, finishExecution, submitProtection, closed;
  final String? newAttempt;
  final String Function(AssessmentPhase) phase;
  final String Function(Duration) remaining;
  final String Function(String ref, String fen) snapshot;
}

/// Pure, externally owned collector. The caller supplies localized confirmation
/// dialogs and navigation, and retains ownership of [cubit] after disposal.
class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({
    required this.cubit,
    required this.labels,
    required this.responseLabels,
    required this.pickSquares,
    required this.createRelationId,
    required this.confirmFinishExecution,
    required this.confirmExit,
    required this.onExit,
    this.boardSettings = const BoardSettings(),
    this.confirmRemoveTarget,
    this.confirmRemoveRelation,
    this.confirmNewAttempt,
    super.key,
  });

  final AssessmentCubit cubit;
  final AssessmentScreenLabels labels;
  final AssessmentResponseLabels responseLabels;
  final AssessmentSquarePicker pickSquares;
  final String Function() createRelationId;
  final Future<bool> Function() confirmFinishExecution, confirmExit;
  final VoidCallback onExit;
  final BoardSettings boardSettings;
  final Future<bool> Function()? confirmRemoveTarget;
  final Future<bool> Function()? confirmNewAttempt;
  final Future<bool> Function(AssessmentRelation)? confirmRemoveRelation;

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool _background = false, _confirming = false, _observing = false;
  bool _resuming = false;
  bool _resumeAgain = false;
  int _bindingEpoch = 0;

  @override
  void didUpdateWidget(covariant AssessmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.cubit, widget.cubit)) {
      _bindingEpoch++;
      _confirming = false;
      _resuming = false;
      _resumeAgain = false;
      _observing = false;
      if (!widget.cubit.isClosed &&
          widget.cubit.state.snapshot == null &&
          !widget.cubit.state.busy) {
        unawaited(widget.cubit.load());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (widget.cubit.state.snapshot == null && !widget.cubit.state.busy) {
      unawaited(widget.cubit.load());
    }
  }

  void _tick() {
    if (!mounted || _background || widget.cubit.isClosed) return;
    setState(() {});
    final state = widget.cubit.state;
    if (_observing ||
        _resuming ||
        state.busy ||
        state.snapshot == null ||
        state.snapshot!.phase == AssessmentPhase.closed) {
      return;
    }
    if (state.technicalFailure != null &&
        widget.cubit.config.now().isBefore(state.snapshot!.deadlineUtc)) {
      return;
    }
    _observing = true;
    unawaited(
      widget.cubit.observeTime().whenComplete(() => _observing = false),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _background = true;
      return;
    }
    if (!_background || widget.cubit.isClosed) return;
    _background = false;
    if (_resuming) {
      _resumeAgain = true;
      return;
    }
    setState(() => _resuming = true);
    unawaited(_resumeForeground(widget.cubit, _bindingEpoch));
  }

  Future<void> _resumeForeground(AssessmentCubit cubit, int epoch) async {
    try {
      do {
        _resumeAgain = false;
        await cubit.resume();
        if (!mounted || epoch != _bindingEpoch || cubit.isClosed) return;
      } while (_resumeAgain && !_background);
    } finally {
      if (mounted && epoch == _bindingEpoch) {
        setState(() => _resuming = false);
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _current(AssessmentAttempt attempt) {
    final current = widget.cubit.state;
    return mounted &&
        !_background &&
        !_resuming &&
        !widget.cubit.isClosed &&
        !current.busy &&
        current.snapshot?.attemptId == attempt.attemptId &&
        current.snapshot?.phase == attempt.phase &&
        current.snapshot?.callbackEpoch == attempt.callbackEpoch;
  }

  Future<void> _finish(AssessmentAttempt attempt) async {
    if (_confirming || !_current(attempt)) return;
    final epoch = _bindingEpoch;
    setState(() => _confirming = true);
    try {
      if (await widget.confirmFinishExecution() &&
          epoch == _bindingEpoch &&
          _current(attempt) &&
          widget.cubit.state.technicalFailure == null) {
        await widget.cubit.finishExecution(voluntaryConfirmed: true);
      }
    } finally {
      if (mounted && epoch == _bindingEpoch) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _exit() async {
    final cubit = widget.cubit;
    final epoch = _bindingEpoch;
    final onExit = widget.onExit;
    final before = cubit.state;
    if (_confirming || before.busy || cubit.isClosed) return;
    final attempt = before.snapshot;
    setState(() => _confirming = true);
    try {
      if (!await widget.confirmExit() ||
          !mounted ||
          cubit.isClosed ||
          epoch != _bindingEpoch ||
          !identical(cubit, widget.cubit) ||
          !identical(onExit, widget.onExit)) {
        return;
      }
      if (attempt == null) {
        if (cubit.state.snapshot == null && !cubit.state.busy) onExit();
        return;
      }
      if (!_current(attempt)) return;
      if (attempt.phase != AssessmentPhase.closed) await cubit.cancel();
      final after = cubit.state;
      if (mounted &&
          epoch == _bindingEpoch &&
          !cubit.isClosed &&
          identical(cubit, widget.cubit) &&
          identical(onExit, widget.onExit) &&
          !after.busy &&
          after.technicalFailure != AssessmentTechnicalFailure.storage &&
          after.snapshot?.attemptId == attempt.attemptId &&
          after.snapshot?.phase == AssessmentPhase.closed) {
        onExit();
      }
    } finally {
      if (mounted && epoch == _bindingEpoch) {
        setState(() => _confirming = false);
      }
    }
  }

  Future<void> _newAttempt(
    AssessmentAttempt attempt,
    AssessmentCubit cubit,
    int epoch,
    Future<bool> Function() confirm,
  ) async {
    bool active() =>
        mounted &&
        epoch == _bindingEpoch &&
        identical(cubit, widget.cubit) &&
        identical(confirm, widget.confirmNewAttempt) &&
        widget.labels.newAttempt != null &&
        attempt.phase == AssessmentPhase.closed &&
        _current(attempt) &&
        cubit.state.technicalFailure != AssessmentTechnicalFailure.storage;
    if (_confirming || !active()) return;
    setState(() => _confirming = true);
    try {
      if (await confirm() && active()) await cubit.retry();
    } finally {
      if (mounted && epoch == _bindingEpoch) {
        setState(() => _confirming = false);
      }
    }
  }

  VoidCallback _technicalRetry(AssessmentState state) {
    final cubit = widget.cubit;
    final epoch = _bindingEpoch;
    final attempt = state.snapshot;
    return () {
      if (!mounted ||
          epoch != _bindingEpoch ||
          !identical(cubit, widget.cubit) ||
          cubit.isClosed ||
          _confirming ||
          _background ||
          _resuming ||
          cubit.state.busy) {
        return;
      }
      final current = cubit.state.snapshot;
      if (current?.attemptId != attempt?.attemptId ||
          current?.phase != attempt?.phase ||
          current?.callbackEpoch != attempt?.callbackEpoch ||
          cubit.state.technicalFailure == null) {
        return;
      }
      unawaited(cubit.resume());
    };
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AssessmentCubit, AssessmentState>(
    bloc: widget.cubit,
    builder: (context, state) {
      final attempt = state.snapshot;
      final enabled = !state.busy && !_confirming && !_resuming && !_background;
      final l = widget.labels;
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) unawaited(_exit());
        },
        child: Scaffold(
          key: AssessmentKeys.screen,
          appBar: LucenaAppBar(
            title: Text(l.title),
            automaticallyImplyLeading: false,
            leading: IconButton(
              key: AssessmentKeys.exit,
              tooltip: l.exit,
              onPressed: enabled ? _exit : null,
              icon: const Icon(Icons.close),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (state.busy)
                  const LinearProgressIndicator(key: AssessmentKeys.busy),
                if (state.technicalFailure != null)
                  Padding(
                    key: AssessmentKeys.failure,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(l.technicalFailure),
                        TextButton(
                          key: AssessmentKeys.retry,
                          onPressed: enabled ? _technicalRetry(state) : null,
                          child: Text(l.retry),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: attempt == null
                      ? Center(child: Text(l.loading))
                      : _content(
                          attempt,
                          enabled && state.technicalFailure == null,
                        ),
                ),
                if (attempt != null)
                  _footer(
                    attempt,
                    enabled &&
                        (state.technicalFailure == null ||
                            attempt.phase == AssessmentPhase.closed),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _content(AssessmentAttempt attempt, bool enabled) {
    final epoch = _bindingEpoch;
    final l = widget.labels;
    final delta = attempt.deadlineUtc.difference(widget.cubit.config.now());
    final remaining = Duration(
      seconds: delta.inMilliseconds <= 0
          ? 0
          : (delta.inMilliseconds / 1000).ceil().clamp(0, 600),
    );
    final timer = Text(l.remaining(remaining), key: AssessmentKeys.timer);
    final status = Text(l.phase(attempt.phase), key: AssessmentKeys.phase);
    if (attempt.phase == AssessmentPhase.closed) {
      return Center(child: Text(l.closed, key: AssessmentKeys.closed));
    }
    if (attempt.phase == AssessmentPhase.execution) {
      return LayoutBuilder(
        key: AssessmentKeys.page,
        builder: (context, box) {
          // The useful Android area includes the app bar and the footer.
          // Its midpoint is below this remaining body's midpoint by half
          // the difference between those two occupied heights.
          const footerHeight = kButtonHeight + 2 * 16;
          const centerOffset = (footerHeight - kToolbarHeight) / 2;
          const headerHeight = kMinInteractiveDimension;
          const gap = 8.0;
          final size = math.min(
            box.maxWidth,
            math.max(
              0.0,
              box.maxHeight - 2 * (headerHeight + gap + centerOffset.abs()),
            ),
          );
          final top = (box.maxHeight - size) / 2 + centerOffset;
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: math.max(0.0, top - gap),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [status, timer],
                  ),
                ),
              ),
              Positioned(
                top: top,
                left: (box.maxWidth - size) / 2,
                width: size,
                height: size,
                child: _board(
                  attempt.execution.gameFen,
                  size,
                  playable:
                      enabled &&
                      !attempt.execution.pending &&
                      attempt.execution.studentTurn,
                  attempt: attempt,
                ),
              ),
            ],
          );
        },
      );
    }
    final snapshots = [
      for (final entry in attempt.execution.visitedSnapshots.entries)
        AssessmentFormSnapshot(
          ref: entry.key,
          fen: entry.value,
          label: l.snapshot(entry.key, entry.value),
        ),
    ];
    final initial = snapshots.firstWhere((s) => s.ref == 'ply:0');
    final current = attempt.phase == AssessmentPhase.initial
        ? initial
        : snapshots.firstWhere(
            (s) => s.ref == attempt.viewSnapshotRef,
            orElse: () => snapshots.last,
          );
    return SingleChildScrollView(
      key: AssessmentKeys.page,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          status,
          Center(child: timer),
          LayoutBuilder(
            builder: (context, box) => _board(
              current.fen,
              box.maxWidth,
              playable: false,
              attempt: attempt,
            ),
          ),
          if (attempt.phase == AssessmentPhase.protection)
            Wrap(
              children: [
                for (final snapshot in snapshots)
                  ChoiceChip(
                    key: AssessmentKeys.snapshot(snapshot.ref),
                    label: Text(snapshot.label),
                    selected: snapshot.ref == current.ref,
                    onSelected: enabled
                        ? (selected) {
                            if (selected &&
                                epoch == _bindingEpoch &&
                                _current(attempt)) {
                              unawaited(
                                widget.cubit.selectVisitedSnapshot(
                                  snapshot.ref,
                                ),
                              );
                            }
                          }
                        : null,
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: AssessmentResponseForm(
              key: AssessmentKeys.form(attempt.attemptId, attempt.phase),
              value: attempt.draft,
              phase: attempt.phase,
              currentSnapshot: current,
              visitedSnapshots: attempt.phase == AssessmentPhase.initial
                  ? [initial]
                  : snapshots,
              labels: widget.responseLabels,
              pickSquares: widget.pickSquares,
              createRelationId: widget.createRelationId,
              enabled: enabled,
              busy: widget.cubit.state.busy,
              confirmRemoveTarget: widget.confirmRemoveTarget,
              confirmRemoveRelation: widget.confirmRemoveRelation,
              onChanged: (draft) {
                if (epoch == _bindingEpoch &&
                    _current(attempt) &&
                    widget.cubit.state.technicalFailure == null) {
                  unawaited(widget.cubit.replaceDraft(draft));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _board(
    String fen,
    double size, {
    required bool playable,
    required AssessmentAttempt attempt,
  }) {
    final epoch = _bindingEpoch;
    final identity = (widget.cubit, attempt.attemptId, attempt.callbackEpoch);
    final side = widget.cubit.config.student;
    return KeyedSubtree(
      key: AssessmentKeys.board,
      child: _AssessmentBoard(
        key: ValueKey((identity, side)),
        fen: fen,
        size: size,
        playable: playable,
        side: side,
        settings: widget.boardSettings,
        identity: identity,
        onMove: (move) {
          if (playable &&
              epoch == _bindingEpoch &&
              _current(attempt) &&
              widget.cubit.state.technicalFailure == null) {
            unawaited(widget.cubit.play(move));
          }
        },
      ),
    );
  }

  Widget _footer(AssessmentAttempt attempt, bool enabled) {
    final l = widget.labels;
    final cubit = widget.cubit;
    final epoch = _bindingEpoch;
    final onExit = widget.onExit;
    final newAttempt = l.newAttempt;
    final confirmNewAttempt = widget.confirmNewAttempt;
    final (label, action) = switch (attempt.phase) {
      AssessmentPhase.initial => (l.submitInitial, widget.cubit.submitInitial),
      AssessmentPhase.execution => (l.finishExecution, () => _finish(attempt)),
      AssessmentPhase.protection => (
        l.submitProtection,
        widget.cubit.submitProtection,
      ),
      AssessmentPhase.closed => (l.exit, _exit),
    };
    final settled =
        attempt.phase != AssessmentPhase.execution ||
        (!attempt.execution.pending && attempt.execution.studentTurn);
    return Padding(
      key: AssessmentKeys.footer,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (attempt.phase == AssessmentPhase.closed &&
              newAttempt != null &&
              confirmNewAttempt != null) ...[
            OutlinedButton(
              key: AssessmentKeys.newAttempt,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeight),
              ),
              onPressed:
                  enabled &&
                      cubit.state.technicalFailure !=
                          AssessmentTechnicalFailure.storage
                  ? () => _newAttempt(attempt, cubit, epoch, confirmNewAttempt)
                  : null,
              child: Text(newAttempt),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: AssessmentKeys.submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(kButtonHeight),
              ),
              onPressed: enabled && settled
                  ? () {
                      if (epoch != _bindingEpoch ||
                          !identical(cubit, widget.cubit) ||
                          !identical(onExit, widget.onExit) ||
                          _confirming ||
                          !_current(attempt)) {
                        return;
                      }
                      if (attempt.phase != AssessmentPhase.closed &&
                          cubit.state.technicalFailure != null) {
                        return;
                      }
                      unawaited(action());
                    }
                  : null,
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentBoard extends StatefulWidget {
  const _AssessmentBoard({
    required this.fen,
    required this.size,
    required this.playable,
    required this.side,
    required this.settings,
    required this.identity,
    required this.onMove,
    super.key,
  });
  final String fen;
  final double size;
  final bool playable;
  final Side side;
  final BoardSettings settings;
  final Object identity;
  final ValueChanged<Move> onMove;
  @override
  State<_AssessmentBoard> createState() => _AssessmentBoardState();
}

class _AssessmentBoardState extends State<_AssessmentBoard> {
  late final ChessboardController _controller;
  GameData _data() {
    final position = GameRules.fromFen(widget.fen);
    return GameData(
      fen: widget.fen,
      playerSide: !widget.playable
          ? PlayerSide.none
          : widget.side == Side.white
          ? PlayerSide.white
          : PlayerSide.black,
      sideToMove: position?.turn ?? widget.side,
      validMoves: widget.playable && position != null
          ? GameRules.legalMoves(position)
          : const {},
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = ChessboardController(game: _data());
  }

  @override
  void didUpdateWidget(covariant _AssessmentBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fen != widget.fen ||
        oldWidget.playable != widget.playable ||
        oldWidget.side != widget.side ||
        oldWidget.identity != widget.identity) {
      _controller.updatePosition(_data(), animate: false, resetPremove: true);
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
      orientation: widget.side,
      onMove: (move, {viaDragAndDrop}) => widget.onMove(move),
    ),
  );
}
