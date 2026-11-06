import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_plan.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/use_cases/training/build_day_goals.dart';
import 'package:lucena/domain/use_cases/training/complete_training_lesson.dart';
import 'package:lucena/domain/use_cases/training/double_training_goals.dart';
import 'package:lucena/domain/use_cases/training/goal_minutes.dart';
import 'package:lucena/domain/use_cases/training/training_goal_counts.dart';

import '../../../../testing/fakes/fake_now.dart';

/// T85 B2: a meta do dia segue o tempo do plano. O conteúdo é o índice real
/// do Pilares (assets/courses/pilares/index.json), não lições inventadas.
TrainingResources _realPilares() {
  final index = jsonDecode(
    File('assets/courses/pilares/index.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final lessons = <TrainingLesson>[];
  for (final part in index['partes'] as List) {
    for (final chapter in (part as Map)['capitulos'] as List) {
      for (final item in (chapter as Map)['aulas'] as List) {
        final tipo = (item as Map)['tipo'] as String;
        lessons.add(
          TrainingLesson(
            id: item['id'] as String,
            kind: switch (tipo) {
              'tema' => TrainingLessonKind.theme,
              'abertura' => TrainingLessonKind.opening,
              _ => TrainingLessonKind.test,
            },
            title: item['titulo'] as String,
            group: chapter['titulo'] as String,
            groupId: chapter['id'] as String,
            partId: part['id'] as String,
            partTitle: part['titulo'] as String,
          ),
        );
      }
    }
  }
  return TrainingResources(lessons: lessons);
}

void main() {
  final config = TrainingCourseConfig.pilares;
  late FakeNow now;
  late TrainingResources resources;
  setUp(() {
    now = FakeNow(DateTime(2026, 10, 26, 12)); // segunda-feira
    resources = _realPilares();
  });

  TrainingState firstDay(int minutes) => BuildDayGoals(now, config)(
    TrainingState(
      course: TrainingCourse.pilares,
      installSeed: 'b2',
      onboardingDone: true,
      plan: TrainingPlan(minutes: minutes),
    ),
    resources,
  );

  TrainingState finishAll(TrainingState state) {
    for (final goal in [...state.day!.goals]) {
      final lesson = resources.lessons.firstWhere((l) => l.id == goal.ref);
      state = CompleteTrainingLesson(now, config)(state, resources, lesson);
    }
    return state;
  }

  test('B2a: plano de 30 min, uma lição de 15 min não fecha o dia', () {
    var state = firstDay(30);
    final minutes = GoalMinutes(config);
    expect(
      minutes.ofGoals(state.day!.goals),
      greaterThanOrEqualTo(30),
      reason: 'a meta do dia soma o tempo do plano',
    );
    // Faz só a primeira lição da meta.
    final first = state.day!.goals.first;
    state = CompleteTrainingLesson(now, config)(
      state,
      resources,
      resources.lessons.firstWhere((l) => l.id == first.ref),
    );
    expect(state.day!.allDone, isFalse);
    expect(trainingGoalCounts(state).remaining, greaterThan(0));
    // Fazendo todas, o dia fecha.
    expect(finishAll(state).day!.allDone, isTrue);
  });

  test('B2a: plano de 15 min continua com uma lição', () {
    final state = firstDay(15);
    expect(state.day!.goals.where((g) => g.kind == GoalKind.lesson).length, 1);
  });

  test('B2b: depois de dobrar, faltam N de M batem com a lista', () {
    var state = finishAll(firstDay(30));
    expect(state.day!.allDone, isTrue);
    // A lição extra feita no fim da lição abre a oferta de dobrar.
    final extra = resources.lessons.firstWhere(
      (l) => !state.completedLessons.containsKey(l.id),
    );
    state = CompleteTrainingLesson(now, config)(state, resources, extra);
    final doubled = DoubleTrainingGoals(now, config)(state, resources);
    final goals = doubled.day!.goals;
    final counts = trainingGoalCounts(doubled);
    expect(counts.total, goals.length);
    expect(counts.remaining, goals.where((g) => !g.done).length);
  });

  test('Dobrar: o tempo somado sai das metas que entram', () {
    var state = finishAll(firstDay(30));
    final extra = resources.lessons.firstWhere(
      (l) => !state.completedLessons.containsKey(l.id),
    );
    state = CompleteTrainingLesson(now, config)(state, resources, extra);
    final doubled = DoubleTrainingGoals(now, config)(state, resources);
    final added = GoalMinutes(config).addedByDoubling(state, doubled);
    expect(added, config.lessonMinutes);
  });
}
