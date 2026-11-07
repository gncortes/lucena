import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/training/course_training_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/training/training_course.dart';

/// Por onde o curso chegou: o presente (do painel ou de outra pessoa) ou a
/// compra (na loja, pelo site ou paga por fora).
enum CourseUnlockedOrigin { gift, purchase }

class CourseUnlockedState {
  const CourseUnlockedState({
    this.loaded = false,
    this.teacher,
    this.name = '',
    this.hasPlan = false,
  });

  final bool loaded;

  /// O Viktor; nulo se a leitura falhou (a fala some, o resto fica).
  final Character? teacher;

  /// O apelido do Perfil; vazio, a fala vai sem nome.
  final String name;

  /// Já tem plano de estudo: "Ir para o curso" no lugar de "Montar o meu
  /// plano".
  final bool hasPlan;
}

/// Os dados do Curso liberado (H-R5-62): o Viktor, o nome e se já há plano.
class CourseUnlockedCubit extends Cubit<CourseUnlockedState> {
  CourseUnlockedCubit({
    required this._characters,
    required this._profile,
    required this._training,
  }) : super(const CourseUnlockedState());

  final CharacterRepository _characters;
  final ProfileRepository _profile;
  final TrainingRepository _training;

  Future<void> load() async {
    Character? teacher;
    var name = '';
    var hasPlan = false;
    try {
      teacher = (await _characters.characters())
          .where((c) => c.id == Character.masterId)
          .firstOrNull;
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
    try {
      name = (await _profile.load()).nickname.trim();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
    try {
      hasPlan =
          (await _training.load(TrainingCourse.pilares)).studyPlan != null;
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
    }
    if (isClosed) return;
    emit(
      CourseUnlockedState(
        loaded: true,
        teacher: teacher,
        name: name,
        hasPlan: hasPlan,
      ),
    );
  }
}
