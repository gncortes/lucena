import 'dart:async';

import '../../models/analytics_event.dart';
import '../../models/training/day_goals.dart';
import '../../models/training/training_analytics_state.dart';
import '../../models/training/training_course.dart';
import '../../models/training/training_state.dart';
import '../now.dart';
import 'training_date.dart';

export '../../models/training/training_analytics_state.dart';

typedef TrainingAnalyticsRead = Future<TrainingState> Function(
  TrainingCourse course,
);
typedef TrainingAnalyticsWrite = Future<TrainingState> Function(
  TrainingCourse course,
  TrainingState Function(TrainingState) change,
);

/// One coordinator per app. Storage callbacks use the raw durable repository;
/// no log transport is awaited by training commands. [attach] is pure and may
/// be called inside a training transaction without recursively writing storage.
final class TrainingAnalytics {
  TrainingAnalytics({
    required this.now,
    required this.log,
    this.read,
    this.write,
  });
  final Now now;
  final Future<void> Function(AnalyticsEvent) log;
  final TrainingAnalyticsRead? read;
  final TrainingAnalyticsWrite? write;
  final _contexts = <TrainingCourse, TrainingAnalyticsState>{};

  Future<void> send(AnalyticsEvent event) async {
    try {
      await log(event);
    } catch (_) {
      /* Best effort telemetry. */
    }
  }

  Future<void> restore(TrainingCourse course, {TrainingState? state}) async {
    final saved = state ?? await read?.call(course);
    if (saved == null) return;
    final date = saved.day?.date;
    final durable = saved.analytics.date == date
        ? saved.analytics
        : TrainingAnalyticsState(date: date);
    final memory = _contexts[course];
    _contexts[course] = memory?.date == date ? durable.merge(memory!) : durable;
  }

  TrainingAnalyticsAttempt? attempt(TrainingCourse course, String goalKey) =>
      _contexts[course]?.attempts[goalKey];
  TrainingAnalyticsSegment? segment(
    TrainingCourse course,
    String lessonId,
    String segmentId,
  ) => _contexts[course]?.segments['$lessonId:$segmentId'];

  /// Merge only today's metadata and return identity if nothing changed.
  TrainingState attach(TrainingState state) {
    final memory = _contexts[state.course];
    if (memory == null || memory.date != state.day?.date) return state;
    final base = state.analytics.date == memory.date
        ? state.analytics
        : TrainingAnalyticsState(date: memory.date);
    final merged = base.merge(memory);
    return state.analytics.same(merged)
        ? state
        : state.copyWith(analytics: merged);
  }

  Future<void> flush(TrainingCourse course) async {
    await _persist(course);
  }

  Future<bool> _persist(TrainingCourse course) async {
    final save = write;
    if (save == null) return true;
    try {
      final saved = await save(course, attach);
      await restore(course, state: saved);
      return true;
    } catch (_) {
      // Keep the pending metadata in memory; the next command attaches it.
      return false;
    }
  }

  Future<void> startGoal(
    TrainingState state,
    TrainingGoal goal, {
    String origin = 'metas',
    String? lessonId,
  }) async {
    if (goal.done) return;
    final began = now();
    await restore(state.course, state: state);
    var context = _contexts[state.course]!;
    if (context.attempts.containsKey(goal.key)) return;
    final cycle = state.cycles[goal.ref];
    final cycleDay = cycle == null || goal.kind != GoalKind.exercise
        ? 0
        : (cycle.cycleDays.length + 1).clamp(1, 7);
    final candidate = TrainingAnalyticsAttempt(
      started: began,
      origin: origin == 'home' ? 'home' : 'metas',
      lessonId: lessonId ?? goal.items['lessonId'],
      cycleDay: cycleDay,
    );
    context = TrainingAnalyticsState(
      date: state.day?.date,
      attempts: {...context.attempts, goal.key: candidate},
      segments: context.segments,
    );
    _contexts[state.course] = context;
    var created = true;
    final save = write;
    if (save != null) {
      try {
        final saved = await save(state.course, (current) {
          final pending = current.day?.goals
              .where((g) => g.key == goal.key && !g.done)
              .firstOrNull;
          if (current.day?.date != state.day?.date || pending == null) {
            created = false;
            return current;
          }
          final previous = current.analytics.date == current.day?.date
              ? current.analytics.attempts[goal.key]
              : null;
          if (previous != null) created = false;
          return attach(current);
        });
        await restore(state.course, state: saved);
      } catch (_) {
        return;
      }
    }
    final attempt = _contexts[state.course]!.attempts[goal.key]!;
    if (created) {
      unawaited(
        send(
          AnalyticsEvents.treinoMetaInicio(
            curso: state.course.name,
            tipo: goalType(goal.kind),
            aulaId: attempt.lessonId ?? lessonCode(goal),
            estrela: goal.stars,
            diaCiclo: attempt.cycleDay,
            origem: attempt.origin,
            mock: goal.mock,
          ),
        ),
      );
    }
  }

  /// Call inside the same command as completion, followed by [attach].
  void result(
    TrainingCourse course,
    String goalKey, {
    required bool correct,
    int hints = 0,
    int? points,
    String? hintKey,
  }) {
    final context =
        _contexts[course] ?? TrainingAnalyticsState(date: trainingDate(now()));
    final previous =
        context.attempts[goalKey] ??
        TrainingAnalyticsAttempt(started: now(), origin: 'metas');
    _contexts[course] = TrainingAnalyticsState(
      date: context.date,
      segments: context.segments,
      attempts: {
        ...context.attempts,
        goalKey: previous.result(
          correct: correct,
          hints: hints,
          points: points,
          hintKey: hintKey ?? 'meta',
        ),
      },
    );
  }

  Future<TrainingAnalyticsSegment> startSegment(
    TrainingState state, {
    required String lessonId,
    required String segmentId,
    required int total,
    required bool review,
    required bool mock,
    String origin = 'metas',
  }) async {
    await restore(state.course, state: state);
    final context = _contexts[state.course]!;
    final key = '$lessonId:$segmentId';
    final old = context.segments[key];
    if (old != null) return old;
    final segment = TrainingAnalyticsSegment(
      lessonId: lessonId,
      segmentId: segmentId,
      started: now(),
      total: total,
      review: review,
      mock: mock,
      origin: origin == 'home' ? 'home' : 'metas',
    );
    _contexts[state.course] = TrainingAnalyticsState(
      date: context.date,
      attempts: context.attempts,
      segments: {...context.segments, key: segment},
    );
    final durable = await _persist(state.course);
    if (durable) {
      unawaited(
        send(
          AnalyticsEvents.treinoTrechoInicio(
            curso: state.course.name,
            aulaId: lessonId,
            trecho: segmentId,
            trechosTotal: total,
            revisao: review,
            origem: segment.origin,
            mock: mock,
          ),
        ),
      );
    }
    return _contexts[state.course]!.segments[key]!;
  }

  void updateSegment(
    TrainingCourse course,
    String lessonId,
    String segmentId, {
    int errors = 0,
    int back = 0,
    int forward = 0,
    int notation = 0,
    int hints = 0,
  }) {
    final context = _contexts[course];
    final old = context?.segments['$lessonId:$segmentId'];
    if (context == null || old == null) return;
    final next = old.copyWith(
      errors: old.errors + errors,
      back: old.back + back,
      forward: old.forward + forward,
      notation: old.notation + notation,
      hints: old.hints + hints,
    );
    _contexts[course] = TrainingAnalyticsState(
      date: context.date,
      attempts: context.attempts,
      segments: {...context.segments, old.key: next},
    );
  }

  /// Complete segment metadata atomically with the gameplay result. A failed
  /// disk write never leaves a finished marker in the in-memory retry context.
  TrainingState finishSegment(
    TrainingState state,
    String lessonId,
    String segmentId,
  ) {
    final attached = attach(state);
    final context = attached.analytics;
    final old = context.segments['$lessonId:$segmentId'];
    if (old == null || old.finished != null) return attached;
    return attached.copyWith(
      analytics: TrainingAnalyticsState(
        date: context.date,
        attempts: context.attempts,
        segments: {
          ...context.segments,
          old.key: old.copyWith(finished: now()),
        },
      ),
    );
  }

  Future<void> onSaved(TrainingState before, TrainingState after) async {
    final memory = _contexts[after.course];
    final contexts = after.analytics.date == after.day?.date
        ? after.analytics
        : before.analytics.date == after.day?.date
        ? before.analytics
        : TrainingAnalyticsState(date: after.day?.date);
    final effective = memory?.date == after.day?.date
        ? contexts.merge(memory!)
        : contexts;
    _contexts[after.course] = effective;
    final events = trainingAnalyticsDiff(
      before,
      after,
      now: now(),
      attempts: effective.attempts,
    );
    for (final event in events) {
      unawaited(send(event));
    }
  }
}

String goalType(GoalKind kind) => switch (kind) {
  GoalKind.lesson || GoalKind.extraLesson => 'aula',
  GoalKind.exercise => 'exercicio',
  GoalKind.reinforce => 'reforco',
  GoalKind.redo => 'refazer',
  GoalKind.openings => 'abertura',
  GoalKind.stars => 'estrelas',
  GoalKind.bot => 'bot',
  GoalKind.speedrun => 'speedrun',
};

/// The aggregate opening key is a code; never substitute a lesson title.
String lessonCode(TrainingGoal goal) =>
    goal.items['lessonId'] ??
    (goal.kind == GoalKind.speedrun ? 'nenhum' : goal.ref);

/// Pure durable-transition mapper. Replays/reloads have no new transitions.
List<AnalyticsEvent> trainingAnalyticsDiff(
  TrainingState before,
  TrainingState after, {
  required DateTime now,
  Map<String, TrainingAnalyticsAttempt> attempts = const {},
}) {
  final out = <AnalyticsEvent>[];
  for (final segment in after.analytics.segments.values) {
    final old = before.analytics.date == after.analytics.date
        ? before.analytics.segments[segment.key]
        : null;
    if (segment.finished == null || old?.finished != null) continue;
    out.add(
      AnalyticsEvents.treinoTrechoFim(
        curso: after.course.name,
        aulaId: segment.lessonId,
        trecho: segment.segmentId,
        erros: segment.errors,
        toquesVoltar: segment.back,
        toquesAvancar: segment.forward,
        toquesNotacao: segment.notation,
        tempoS: segment.finished!
            .difference(segment.started)
            .inSeconds
            .clamp(0, 2147483647),
        mock: segment.mock,
      ),
    );
  }
  final day = after.day;
  final sameDay = before.day?.date == day?.date;
  final course = after.course.name;
  if (day != null && sameDay) {
    for (final goal in day.goals) {
      final old = before.day!.goals.where((g) => g.key == goal.key).firstOrNull;
      if (!goal.done || old == null || old.done) continue;
      final attempt =
          attempts[goal.key] ??
          (after.analytics.date == day.date
              ? after.analytics.attempts[goal.key]
              : null) ??
          (before.analytics.date == day.date
              ? before.analytics.attempts[goal.key]
              : null);
      final cycle = after.cycles[goal.ref];
      final record = cycle?.days
          .where((d) => d.date == day.date && d.exerciseId == goal.itemId)
          .lastOrNull;
      final hints = (attempt?.hints ?? 0) > 0
          ? attempt!.hints
          : goal.hintUsed || (record?.hint ?? false)
          ? 1
          : 0;
      final openingCorrect =
          goal.kind != GoalKind.openings ||
          goal.items.entries.every(
            (e) =>
                after.openings[e.key]?.firstTry[e.value]?.every(
                  (correct) => correct,
                ) ??
                false,
          );
      out.add(
        AnalyticsEvents.treinoMetaFim(
          curso: course,
          tipo: goalType(goal.kind),
          aulaId: attempt?.lessonId ?? lessonCode(goal),
          estrela: goal.stars,
          diaCiclo:
              attempt?.cycleDay ??
              (goal.kind == GoalKind.exercise
                  ? (cycle?.cycleDays.length ?? 0)
                  : 0),
          origem: attempt?.origin ?? 'metas',
          mock: goal.mock,
          acertou:
              hints == 0 &&
              openingCorrect &&
              (record?.correct ?? attempt?.correct ?? true),
          dicas: hints,
          tempoS: attempt == null
              ? 0
              : now.difference(attempt.started).inSeconds.clamp(0, 2147483647),
          metasRestantes: day.remaining,
          pontos: goal.kind == GoalKind.stars ? attempt?.points : null,
          falaErro: goal.exerciseError?.feedbackShown ?? false,
        ),
      );
    }
    if (!before.day!.doubled && day.doubled) {
      out.add(
        AnalyticsEvents.treinoMetaDobrada(
          curso: course,
          metasNovas: day.goals.length - before.day!.goals.length,
        ),
      );
    }
    if (!before.day!.allDone && day.allDone && day.goals.isNotEmpty) {
      out.add(
        AnalyticsEvents.treinoDiaCompleto(
          curso: course,
          metas: day.goals.length,
          aulasExtra: day.goals
              .where((g) => g.kind == GoalKind.extraLesson && g.done)
              .length,
          dobrou: day.doubled,
        ),
      );
    }
  }
  for (final entry in after.completedLessons.entries) {
    if (before.completedLessons.containsKey(entry.key)) continue;
    final wasGoal =
        before.day?.goals.any(
          (g) =>
              g.ref == entry.key &&
              (g.kind == GoalKind.lesson || g.kind == GoalKind.redo) &&
              !g.done,
        ) ??
        false;
    if (!wasGoal) {
      out.add(
        AnalyticsEvents.treinoAulaExtra(
          curso: course,
          aulaId: entry.key,
          diaFolga: !(day?.studyDay ?? false),
        ),
      );
    }
  }
  return out;
}
