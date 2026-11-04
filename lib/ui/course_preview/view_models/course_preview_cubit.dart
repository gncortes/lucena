import 'dart:async';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/course_preview/course_preview_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/course_preview.dart';

/// O que as telas da prévia mostram: carregando, os textos ou a falta deles,
/// e o Viktor da fala da venda.
class CoursePreviewState {
  final LoadFailure? failure;
  const CoursePreviewState({
    this.failure,
    this.ready = false,
    this.preview,
    this.viktor,
  });

  final bool ready;
  final CoursePreview? preview;
  final Character? viktor;
}

/// Carrega a apresentação do Pilares do Xadrez (H-VEN-01) e o "Para quem é".
/// Com [origin], registra a oferta vista com o destaque `apresentacao`.
class CoursePreviewCubit extends Cubit<CoursePreviewState> {
  CoursePreviewCubit(
    this._repository,
    this._characters, {
    AnalyticsRepository? analytics,
    String? origin,
  }) : super(const CoursePreviewState()) {
    if (analytics != null && origin != null) {
      unawaited(
        analytics.log(
          AnalyticsEvents.pilaresOfertaVista(
            origem: origin,
            destaque: 'apresentacao',
          ),
        ),
      );
    }
  }

  final CoursePreviewRepository _repository;
  final CharacterRepository _characters;

  Future<void> load() async {
    _retryLoad = () => load();
    try {
      await _load();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) emit(CoursePreviewState(failure: LoadFailure.of(error)));
    }
  }

  Future<void> Function()? _retryLoad;
  Future<void> retryLoad() async => _retryLoad?.call();

  Future<void> _load() async {
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
