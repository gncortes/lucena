import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/routing/training_goal_return.dart';

import '../../testing/fakes/fake_course_training_repository.dart';
import '../../testing/test_app.dart';

void main() {
  for (final fails in [false, true]) {
    testWidgets(
      'next serializes duplicate route taps and permits retry after disk error $fails',
      (tester) async {
        final repository = FakeTrainingRepository();
        addTearDown(repository.dispose);
        final gate = Completer<void>();
        repository.beforeSave = gate.future;
        if (fails) repository.writeError = StateError('disk');
        BuildContext? target;
        final router = GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const Scaffold()),
            GoRoute(
              path: '/guide',
              builder: (_, _) => const Scaffold(key: Key('guide')),
            ),
            GoRoute(
              path: '/challenge',
              builder: (context, _) {
                target = context;
                return const Scaffold(key: Key('challenge'));
              },
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          RepositoryProvider<TrainingRepository>.value(
            value: repository,
            child: TestApp(router: router, child: const SizedBox()),
          ),
        );
        unawaited(router.push('/guide'));
        await tester.pumpAndSettle();
        unawaited(router.push('/challenge'));
        await tester.pumpAndSettle();
        final first = TrainingGoalReturn(TrainingCourseConfig.escola, 'goal');
        final rebuilt = TrainingGoalReturn(TrainingCourseConfig.escola, 'goal');
        final a = first.next(target!);
        final b = rebuilt.next(target!);
        if (fails) {
          await Future.wait([
            expectLater(a, throwsStateError),
            expectLater(b, throwsStateError),
          ]);
          expect(find.byKey(const Key('challenge')), findsOneWidget);
          repository.writeError = null;
          final retry = first.next(target!);
          gate.complete();
          await retry;
        } else {
          await tester.pump();
          expect(find.byKey(const Key('challenge')), findsOneWidget);
          expect(repository.writes, 0);
          gate.complete();
          await Future.wait([a, b]);
        }
        await tester.pumpAndSettle();
        expect(repository.writes, 1);
        expect(find.byKey(const Key('guide')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
