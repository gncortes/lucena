import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/course_preview/course_preview_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/course_preview.dart';

/// O que as telas da prévia mostram: carregando, os textos ou a falta deles,
/// e o Viktor da fala da venda.
class CoursePreviewState {
  const CoursePreviewState({this.ready = false, this.preview, this.viktor});

  final bool ready;
  final CoursePreview? preview;
  final Character? viktor;
}

/// Carrega a prévia do Pilares do Xadrez (T82). Não guarda nada: é só layout.
class CoursePreviewCubit extends Cubit<CoursePreviewState> {
  CoursePreviewCubit(this._repository, this._characters)
    : super(const CoursePreviewState());

  final CoursePreviewRepository _repository;
  final CharacterRepository _characters;

  Future<void> load() async {
    final preview = await _repository.load();
    final characters = await _characters.characters();
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == Character.masterId) viktor = character;
    }
    emit(CoursePreviewState(ready: true, preview: preview, viktor: viktor));
  }
}
