import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/lesson_ad/course_access_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/coach/opening_in_pilares.dart';

final class OpeningCourseState {
  const OpeningCourseState({
    this.loading = true,
    this.hasCourse = false,
    this.opening,
  });

  final bool loading;

  /// Comprou o Pilares (e ainda tem): a ligação vai às metas de hoje; sem o
  /// curso, à abertura com cadeado e a oferta.
  final bool hasCourse;

  /// `null` = o curso não tem a abertura ou o conteúdo não carregou.
  final OpeningInPilares? opening;
}

/// A abertura do ponto fraco dentro do Pilares: as partes, a que fica em
/// evidência e se a pessoa tem o curso.
class OpeningCourseCubit extends Cubit<OpeningCourseState> {
  OpeningCourseCubit({
    required this._training,
    required this._access,
    required this.slot,
    this.part,
  }) : super(const OpeningCourseState());

  final TrainingRepository _training;
  final CourseAccessRepository _access;
  final String slot;

  /// A parte que o servidor ligou à saída da teoria.
  final int? part;

  final _subs = <StreamSubscription<Object?>>[];

  /// Lê o curso e passa a ouvir a compra e o progresso: comprar ou terminar
  /// uma parte já muda a tela, sem reabrir.
  Future<void> load() async {
    if (_subs.isEmpty) {
      _subs
        ..add(_access.changes.listen((_) => _read(), onError: (Object _) {}))
        ..add(
          _training.changes
              .where((s) => s.course == TrainingCourse.pilares)
              .listen((_) => _read(), onError: (Object _) {}),
        );
    }
    await _read();
  }

  Future<void> _read() async {
    final hasCourse = _access.access.hasFullCourse;
    OpeningInPilares? opening;
    try {
      final resources =
          await _training.cachedOutline(TrainingCourse.pilares) ??
          await _training.resources(TrainingCourse.pilares);
      final state = hasCourse
          ? await _training.load(TrainingCourse.pilares)
          : null;
      opening = openingInPilares(
        slot: slot,
        resources: resources,
        state: state,
        serverPart: part,
      );
    } on Object {
      opening = null;
    }
    if (isClosed) return;
    emit(
      OpeningCourseState(
        loading: false,
        hasCourse: hasCourse,
        opening: opening,
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final s in _subs) {
      await s.cancel();
    }
    return super.close();
  }
}
