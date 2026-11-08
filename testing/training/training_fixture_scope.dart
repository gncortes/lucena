import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/use_cases/now.dart';
import 'package:lucena/domain/use_cases/training/training_analytics.dart';
import 'package:lucena/ui/core/analytics/analytics_context.dart';

/// A manually mounted real bank must use one repository for progress and
/// telemetry. The surrounding mock course has a different bank and queue.
class TrainingFixtureScope extends StatelessWidget {
  const TrainingFixtureScope({
    required this.repository,
    required this.now,
    required this.child,
    super.key,
  });
  final TrainingRepository repository;
  final Now now;
  final Widget child;

  @override
  Widget build(BuildContext context) => RepositoryProvider<TrainingAnalytics>(
    create: (_) => TrainingAnalytics(
      now: now,
      log: context.analytics.log,
      read: repository.load,
      write: repository.update,
    ),
    child: child,
  );
}
