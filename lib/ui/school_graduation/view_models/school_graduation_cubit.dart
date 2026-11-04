import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/now.dart';

/// Um módulo da Escola no resumo do diploma.
final class GraduationModule {
  const GraduationModule({
    required this.id,
    required this.title,
    required this.lessons,
  });

  final String id, title;
  final int lessons;
}

final class SchoolGraduationState {
  const SchoolGraduationState({
    this.loaded = false,
    this.modules = const [],
    this.date,
  });

  final bool loaded;
  final List<GraduationModule> modules;

  /// O dia da última lição concluída (ou hoje, se a data não foi gravada).
  final DateTime? date;

  int get lessons => modules.fold(0, (sum, m) => sum + m.lessons);
}

/// O diploma da Escola (H-ESC-22): lê o curso concluído, sem alterá-lo.
class SchoolGraduationCubit extends Cubit<SchoolGraduationState> {
  SchoolGraduationCubit({required this._repository, required this._now})
    : super(const SchoolGraduationState());

  final TrainingRepository _repository;
  final Now _now;

  Future<void> load() async {
    final training = await _repository.load(TrainingCourse.escola);
    final resources = await _repository.resources(TrainingCourse.escola);
    final lessons = resources.lessons.where((l) => l.visible);
    final modules = <String, GraduationModule>{};
    for (final lesson in lessons) {
      final before = modules[lesson.groupId];
      modules[lesson.groupId] = GraduationModule(
        id: lesson.groupId,
        title: lesson.group,
        lessons: (before?.lessons ?? 0) + 1,
      );
    }
    if (isClosed) return;
    emit(
      SchoolGraduationState(
        loaded: true,
        modules: modules.values.toList(),
        date: DateTime.tryParse(training.lastLessonDate ?? '') ?? _now(),
      ),
    );
  }
}
