import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/use_cases/training/training_analytics.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/day_goals.dart';
import '../../../domain/models/training/training_content.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../domain/models/training/training_resources.dart';
import '../../../domain/models/training/training_state.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/build_day_goals.dart';
import '../../../domain/use_cases/training/complete_training_goal.dart';
import '../../../domain/use_cases/training/play_training_opening.dart';
import '../../../domain/use_cases/training/training_date.dart';
import '../../../domain/use_cases/training/opening_trecho_rules.dart';

enum TrainingOpeningPhase {
  loading,
  playing,
  mistakeSaving,
  saving,
  complete,
  unavailable,
  expired,
}

final class TrainingOpeningState {
  const TrainingOpeningState({
    this.phase = TrainingOpeningPhase.loading,
    this.saved,
    this.resources,
    this.lessonId,
    this.line,
    this.cursor = 0,
    this.shown = 0,
    this.firstTry = const [],
    this.failed = false,
    this.wrong = false,
    this.hint = false,
    this.error = false,
    this.transitionFens = const [],
  });
  final TrainingOpeningPhase phase;
  final TrainingState? saved;
  final TrainingResources? resources;
  final String? lessonId;
  final PlayTrainingOpening? line;
  final int cursor, shown;
  final List<bool> firstTry;
  final bool failed, wrong, hint, error;
  final List<String> transitionFens;
  bool get reviewing => shown < cursor;
  bool get allPartsDone {
    final bank = resources?.openings[lessonId] ?? const <OpeningTrecho>[];
    return bank.isNotEmpty &&
        bank.every(
          (p) =>
              saved?.openings[lessonId]?.doneTrechos.containsKey(p.id) ?? false,
        );
  }

  String? get fen => line?.fens[shown];
  OpeningTrecho? get trecho => line?.trecho;
  TrainingGoal? get goal =>
      saved?.day?.goals.where((g) => g.kind == GoalKind.openings).firstOrNull;
  List<String> get pending => [
    for (final e in goal?.items.entries ?? const <MapEntry<String, String>>[])
      if (saved?.openings[e.key]?.doneTrechos[e.value] != saved?.day?.date)
        e.key,
  ];

  TrainingOpeningState copyWith({
    TrainingOpeningPhase? phase,
    TrainingState? saved,
    int? cursor,
    int? shown,
    List<bool>? firstTry,
    bool? failed,
    bool? wrong,
    bool? hint,
    bool? error,
    List<String>? transitionFens,
  }) => TrainingOpeningState(
    phase: phase ?? this.phase,
    saved: saved ?? this.saved,
    resources: resources,
    lessonId: lessonId,
    line: line,
    cursor: cursor ?? this.cursor,
    shown: shown ?? this.shown,
    firstTry: firstTry ?? this.firstTry,
    failed: failed ?? this.failed,
    wrong: wrong ?? this.wrong,
    hint: hint ?? this.hint,
    error: error ?? this.error,
    transitionFens: transitionFens ?? this.transitionFens,
  );
}

final class _ExpiredOpening implements Exception {
  const _ExpiredOpening();
}

/// Course-neutral: the frozen daily goal owns which opening segment is playable.
final class TrainingOpeningCubit extends Cubit<TrainingOpeningState> {
  TrainingOpeningCubit({
    required this.repository,
    required this.config,
    required this.now,
    this.analytics = const NoAnalyticsRepository(),
    this.trainingAnalytics,
    this.origin = 'metas',
  }) : super(const TrainingOpeningState()) {
    _changes = repository.changes.listen((saved) {
      if (!isClosed &&
          saved.course == config.course &&
          state.saved != null &&
          state.line == null) {
        emit(state.copyWith(saved: saved));
      }
    });
  }
  final TrainingRepository repository;
  final TrainingCourseConfig config;
  final String origin;
  DateTime? _started;
  int _errors = 0, _back = 0, _forward = 0, _notation = 0, _hints = 0;
  bool _segmentSent = false;
  final Now now;
  final AnalyticsRepository analytics;
  final TrainingAnalytics? trainingAnalytics;
  Future<void> _log(AnalyticsEvent event) {
    unawaited(
      Future<void>.sync(() => analytics.log(event)).catchError((Object _) {}),
    );
    return Future<void>.value();
  }

  late final StreamSubscription<TrainingState> _changes;
  bool _saving = false;
  bool _pendingHint = false;
  Timer? _saveRetry;

  @override
  Future<void> close() async {
    _saveRetry?.cancel();
    await _changes.cancel();
    await super.close();
  }

  Future<void> load({String? lessonId, String? partId}) async {
    try {
      final resources = await repository.resources(config.course);
      final saved = await repository.transact(
        config.course,
        (current) => BuildDayGoals(now, config)(current, resources),
      );
      if (isClosed) return;
      if (lessonId == null) {
        emit(
          TrainingOpeningState(
            phase: TrainingOpeningPhase.complete,
            saved: saved,
            resources: resources,
          ),
        );
        return;
      }
      final goal = saved.day?.goals
          .where((g) => g.kind == GoalKind.openings)
          .firstOrNull;
      final id = partId ?? goal?.items[lessonId];
      final trecho = resources.openings[lessonId]
          ?.where((t) => t.id == id)
          .firstOrNull;
      if (trecho == null ||
          (partId == null &&
              saved.openings[lessonId]?.doneTrechos[id] == saved.day?.date)) {
        throw StateError('Opening unavailable');
      }
      final line = PlayTrainingOpening(trecho);
      await trainingAnalytics?.restore(config.course, state: saved);
      if (goal != null) {
        await trainingAnalytics?.startGoal(saved, goal, origin: origin);
      }
      final metadata = await trainingAnalytics?.startSegment(
        saved,
        lessonId: lessonId,
        segmentId: trecho.id,
        total: resources.openings[lessonId]!.length,
        review:
            saved.openings[lessonId]?.doneTrechos.containsKey(trecho.id) ??
            false,
        mock: trecho.mock,
        origin: origin,
      );
      _started = metadata?.started ?? now();
      _errors = metadata?.errors ?? 0;
      _back = metadata?.back ?? 0;
      _forward = metadata?.forward ?? 0;
      _notation = metadata?.notation ?? 0;
      _hints = metadata?.hints ?? 0;
      _segmentSent = false;
      if (trainingAnalytics == null) {
        await _log(
          AnalyticsEvents.treinoTrechoInicio(
            curso: config.course.name,
            aulaId: lessonId,
            trecho: trecho.id,
            trechosTotal: resources.openings[lessonId]!.length,
            revisao:
                saved.openings[lessonId]?.doneTrechos.containsKey(trecho.id) ??
                false,
            origem: origin,
            mock: trecho.mock,
          ),
        );
      }
      emit(
        TrainingOpeningState(
          phase: TrainingOpeningPhase.playing,
          saved: saved,
          resources: resources,
          lessonId: lessonId,
          line: line,
          cursor: line.initialCursor,
          shown: line.initialCursor,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          const TrainingOpeningState(phase: TrainingOpeningPhase.unavailable),
        );
      }
    }
  }

  /// The notation view reports its own taps; arrows use [review].
  void _counter({
    int errors = 0,
    int back = 0,
    int forward = 0,
    int notation = 0,
    int hints = 0,
    bool flush = true,
  }) {
    final id = state.lessonId, trecho = state.trecho;
    if (id == null || trecho == null) return;
    trainingAnalytics?.updateSegment(
      config.course,
      id,
      trecho.id,
      errors: errors,
      back: back,
      forward: forward,
      notation: notation,
      hints: hints,
    );
    if (flush && trainingAnalytics != null) {
      unawaited(trainingAnalytics!.flush(config.course));
    }
  }

  void notationTap([int? index]) {
    _notation++;
    _counter(notation: 1);
    if (index != null) review(index, countArrow: false);
  }

  void review(int index, {bool countArrow = true}) {
    if (state.line == null || index < 0 || index > state.cursor) return;
    if (countArrow && index < state.shown) {
      _back++;
      _counter(back: 1);
    }
    if (countArrow && index > state.shown) {
      _forward++;
      _counter(forward: 1);
    }
    emit(state.copyWith(shown: index));
  }

  Future<void> hint() async {
    if (state.phase != TrainingOpeningPhase.playing || state.reviewing) {
      return;
    }
    if (state.trecho?.lines.isNotEmpty == true) {
      emit(state.copyWith(failed: true, hint: true));
      return;
    }
    _pendingHint = true;
    _hints++;
    _counter(hints: 1, flush: false);
    emit(
      state.copyWith(
        phase: TrainingOpeningPhase.mistakeSaving,
        failed: true,
        error: false,
      ),
    );
    await _saveMistake();
  }

  Future<void> retry() => state.phase == TrainingOpeningPhase.mistakeSaving
      ? _saveMistake()
      : save();

  Future<void> _saveMistake() async {
    if (state.phase != TrainingOpeningPhase.mistakeSaving || _saving) return;
    _saving = true;
    final original = state;
    final index = original.line!.questionIndex(original.cursor);
    emit(state.copyWith(error: false));
    try {
      final saved = await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        final refreshed = BuildDayGoals(now, config)(current, resources);
        final goal = refreshed.day?.goals
            .where((g) => g.kind == GoalKind.openings)
            .firstOrNull;
        final track = refreshed.openings[original.lessonId];
        if (refreshed.day?.date != original.saved?.day?.date ||
            refreshed.day?.date != trainingDate(now()) ||
            goal?.items[original.lessonId] != original.trecho!.id ||
            track == null ||
            track.doneTrechos[original.trecho!.id] == refreshed.day?.date) {
          throw const _ExpiredOpening();
        }
        final marked = track.withMistake(original.trecho!.id, index);
        var next = identical(marked, track)
            ? refreshed
            : refreshed.copyWith(
                openings: {...refreshed.openings, original.lessonId!: marked},
              );
        if (_pendingHint && goal != null && !goal.hintUsed) {
          next = next.copyWith(
            day: next.day!.copyWith(
              goals: [
                for (final value in next.day!.goals)
                  if (value.key == goal.key) value.withHint() else value,
              ],
            ),
          );
        }
        return trainingAnalytics?.attach(next) ?? next;
      });
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: TrainingOpeningPhase.playing,
            saved: saved,
            failed: true,
            hint: _pendingHint,
            wrong: !_pendingHint,
          ),
        );
      }
    } on _ExpiredOpening {
      if (!isClosed) emit(state.copyWith(phase: TrainingOpeningPhase.expired));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: true));
    } finally {
      _saving = false;
      if (!isClosed && state.error) {
        _saveRetry?.cancel();
        _saveRetry = Timer(const Duration(seconds: 1), () {
          if (!isClosed) unawaited(retry());
        });
      }
    }
  }

  Future<void> play(String uci) async {
    if (state.phase != TrainingOpeningPhase.playing || state.reviewing) {
      return;
    }
    final step = state.line!.play(state.cursor, uci);
    if (!step.correct) {
      _errors++;
      _counter(errors: 1, flush: false);
      if (state.trecho!.lines.isNotEmpty) {
        emit(state.copyWith(failed: true, wrong: true, hint: false));
        return;
      }
      // Keep the same position: the board immediately restores an incorrect move.
      _pendingHint = false;
      emit(
        state.copyWith(
          phase: TrainingOpeningPhase.mistakeSaving,
          failed: true,
          wrong: true,
          error: false,
        ),
      );
      await _saveMistake();
      return;
    }
    final done = state.line!.isComplete(step.cursor);
    emit(
      state.copyWith(
        cursor: step.cursor,
        shown: step.cursor,
        transitionFens: state.trecho!.lines.isNotEmpty
            ? state.line!.transitionFens(state.cursor, step.cursor)
            : const [],
        firstTry: List.unmodifiable([
          ...state.firstTry,
          !state.failed &&
              !(state
                      .saved!
                      .openings[state.lessonId]
                      ?.pendingMistakes[state.trecho!.id]
                      ?.contains(state.line!.questionIndex(state.cursor)) ??
                  false),
        ]),
        failed: false,
        wrong: false,
        hint: false,
        phase: done
            ? TrainingOpeningPhase.saving
            : TrainingOpeningPhase.playing,
      ),
    );
    if (done) await save();
  }

  Future<void> save() async {
    if (state.phase != TrainingOpeningPhase.saving || _saving) return;
    _saving = true;
    final original = state;
    var completedHere = false;
    emit(state.copyWith(error: false));
    try {
      final saved = await repository.transact(config.course, (current) async {
        final resources = await repository.resources(config.course);
        if (original.trecho!.lines.isNotEmpty) {
          final track = current.openings[original.lessonId];
          if (track == null) throw StateError('Missing opening track');
          final updated = OpeningTrechoRules(now)
              .complete(track, original.trecho!, original.firstTry);
          var next = current.copyWith(
            openings: {...current.openings, original.lessonId!: updated},
            lastActivityAt: now(),
          );
          final goal = current.day?.goals
              .where((g) => g.kind == GoalKind.openings)
              .firstOrNull;
          if (goal != null &&
              goal.items.entries.every(
                (e) =>
                    next.openings[e.key]?.doneTrechos[e.value] ==
                    current.day!.date,
              )) {
            next = next.copyWith(
              day: next.day!.copyWith(
                goals: [
                  for (final g in next.day!.goals)
                    if (g.key == goal.key) g.complete() else g,
                ],
              ),
            );
          }
          completedHere = true;
          return trainingAnalytics?.finishSegment(
                next,
                original.lessonId!,
                original.trecho!.id,
              ) ??
              next;
        }
        final refreshed = BuildDayGoals(now, config)(current, resources);
        final goal = refreshed.day?.goals
            .where((g) => g.kind == GoalKind.openings)
            .firstOrNull;
        if (refreshed.day?.date != original.saved?.day?.date ||
            refreshed.day?.date != trainingDate(now()) ||
            goal?.items[original.lessonId] != original.trecho!.id) {
          throw const _ExpiredOpening();
        }
        completedHere =
            refreshed.openings[original.lessonId]?.doneTrechos[original
                .trecho!
                .id] !=
            refreshed.day?.date;
        if (goal != null && completedHere) {
          trainingAnalytics?.result(
            config.course,
            goal.key,
            correct: _errors == 0,
            hints: _hints,
            hintKey: '${original.lessonId}:${original.trecho!.id}',
          );
        }
        final completed = CompleteTrainingGoal(
          now,
        ).opening(refreshed, resources, original.lessonId!, original.firstTry);
        return completedHere
            ? trainingAnalytics?.finishSegment(
                    completed,
                    original.lessonId!,
                    original.trecho!.id,
                  ) ??
                  completed
            : completed;
      });
      if (original.trecho!.lines.isEmpty &&
          saved.openings[original.lessonId]?.doneTrechos[original.trecho!.id] !=
              saved.day?.date) {
        throw const _ExpiredOpening();
      }
      if (!_segmentSent && completedHere && trainingAnalytics == null) {
        _segmentSent = true;
        await _log(
          AnalyticsEvents.treinoTrechoFim(
            curso: config.course.name,
            aulaId: original.lessonId!,
            trecho: original.trecho!.id,
            erros: _errors,
            toquesVoltar: _back,
            toquesAvancar: _forward,
            toquesNotacao: _notation,
            tempoS: _started == null
                ? 0
                : now().difference(_started!).inSeconds.clamp(0, 2147483647),
            mock: original.trecho!.mock,
          ),
        );
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: TrainingOpeningPhase.complete,
            saved: saved,
            firstTry: saved
                .openings[original.lessonId]!
                .firstTry[original.trecho!.id],
          ),
        );
      }
    } on _ExpiredOpening {
      if (!isClosed) emit(state.copyWith(phase: TrainingOpeningPhase.expired));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(error: true));
    } finally {
      _saving = false;
      if (!isClosed && state.error) {
        _saveRetry?.cancel();
        _saveRetry = Timer(const Duration(seconds: 1), () {
          if (!isClosed) unawaited(retry());
        });
      }
    }
  }

  /// Only another opening in today's frozen aggregate can follow this segment.
  Future<bool> nextOpening() async {
    if (state.phase != TrainingOpeningPhase.complete || state.pending.isEmpty) {
      return false;
    }
    await load(lessonId: state.pending.first);
    return state.phase == TrainingOpeningPhase.playing;
  }

  Future<void> nextPart() async {
    final bank =
        state.resources?.openings[state.lessonId] ?? const <OpeningTrecho>[];
    final index = bank.indexWhere((p) => p.id == state.trecho?.id);
    if (state.phase != TrainingOpeningPhase.complete ||
        index < 0 ||
        index + 1 >= bank.length) {
      return;
    }
    await load(lessonId: state.lessonId, partId: bank[index + 1].id);
  }
}
