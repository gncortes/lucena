import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/training/course_training_repository.dart';
import '../../domain/models/training/training_course.dart';

/// Grava a aba [tab] em que o curso [course] abre, pelo repositório do
/// [context].
Future<void> saveCourseTab(
  BuildContext context,
  TrainingCourse course,
  CourseGuideTab tab,
) => context.read<TrainingRepository>().update(
  course,
  (s) => s.copyWith(tab: tab),
);
