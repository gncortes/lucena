import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:lucena/data/repositories/training/course_training_repository_local.dart';
import 'package:lucena/data/services/lesson_content_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/main.dart' show LucenaApp;

import '../e2e_dependencies.dart';

/// Host-only process-loss proof, built explicitly with E2E=true. Never seeds,
/// clears preferences or changes a goal: it reports only the existing fixture.
Future<void> main() async {
  if (!const bool.fromEnvironment('E2E')) {
    throw StateError('The process-resume entrypoint requires E2E=true');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final course = TrainingCourse.values.byName(
    const String.fromEnvironment(
      'TRAINING_PROOF_COURSE',
      defaultValue: 'pilares',
    ),
  );
  // ScenarioBuilder sets its injected date during preparation. A fresh Android
  // process must restore that same civil date before any observer builds a day;
  // e2eDependencies alone starts with the generic test clock instead.
  final frozenReader = TrainingRepositoryLocal(
    PreferencesService(),
    const LessonContentAssets(),
    installSeed: 'process-proof',
  );
  final frozen = await frozenReader.load(course);
  await frozenReader.dispose();
  if (frozen.day == null) {
    throw StateError('Prepare a dated training fixture first');
  }
  e2eNow.value = DateTime.parse('${frozen.day!.date}T12:00:00');
  final dependencies = await e2eDependencies();
  final state = await dependencies.courseTrainingRepository.load(course);
  final goal = state.day?.goals
      .where(
        (g) =>
            !g.done &&
            const {
              GoalKind.exercise,
              GoalKind.reinforce,
              GoalKind.stars,
            }.contains(g.kind),
      )
      .firstOrNull;
  if (goal == null) {
    throw StateError('Prepare an unfinished training fixture first');
  }
  final openStar = await dependencies.starChallengeRepository.open();
  final durable = state.toJson()
    ..remove('analytics')
    ..remove('analyticsReminderAt')
    ..remove('analyticsReminderShownAt');
  final file = File('${Directory.systemTemp.path}/t85-resume-proof.json');
  await file.writeAsString(
    jsonEncode({
      'pid': pid,
      'course': course.name,
      'date': state.day!.date,
      'goal': goal.key,
      'itemId': goal.itemId,
      'hintUsed': goal.hintUsed,
      'done': goal.done,
      'openStar': openStar?.key,
      'stateDigest': sha256
          .convert(utf8.encode(jsonEncode(durable)))
          .toString(),
    }),
    flush: true,
  );
  debugPrint('T85_RESUME_PROOF_FILE=${file.path}');
  runApp(LucenaApp(dependencies: dependencies));
}
