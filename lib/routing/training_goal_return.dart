import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/training/course_training_repository.dart';
import '../domain/models/training/training_course.dart';
import '../domain/models/training/training_course_config.dart';
import 'routes.dart';

// Shared by callbacks rebuilt while their route is animating out. A completed
// return remains attached to that route until it is collected.
final _returns = Expando<Future<void>>('training goal return');

/// Only routes explicitly opened by a training goal receive the extra action.
final class TrainingGoalReturn {
  TrainingGoalReturn(this.config, this.key);
  final TrainingCourseConfig config;
  final String key;
  Future<void>? _pending;

  static TrainingGoalReturn? from(GoRouterState state) {
    final config = TrainingCourseConfig.fromName(
      state.uri.queryParameters['treino'] ?? '',
    );
    final key = state.uri.queryParameters['meta'];
    return config == null || key == null
        ? null
        : TrainingGoalReturn(config, key);
  }

  Future<bool> done(BuildContext context) async {
    final state = await context.read<TrainingRepository>().load(config.course);
    return state.day?.goals.any((g) => g.key == key && g.done) ?? false;
  }

  Future<void> next(BuildContext context) {
    final route = ModalRoute.of(context);
    final previous = route == null ? _pending : _returns[route];
    if (previous != null) return previous;
    final operation = _next(context);
    if (route == null) {
      _pending = operation;
    } else {
      _returns[route] = operation;
    }
    return operation.onError((Object error, StackTrace stack) {
      if (route == null) {
        _pending = null;
      } else {
        _returns[route] = null;
      }
      Error.throwWithStackTrace(error, stack);
    });
  }

  Future<void> _next(BuildContext context) async {
    final router = GoRouter.of(context);
    await context.read<TrainingRepository>().update(
      config.course,
      (s) => s.copyWith(tab: CourseGuideTab.goals),
    );
    if (!context.mounted) return;
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(Routes.training(config.course.name));
    }
  }
}
