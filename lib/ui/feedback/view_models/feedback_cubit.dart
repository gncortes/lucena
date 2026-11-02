import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/feedback/feedback_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/feedback_entry.dart';

class FeedbackState {
  final LoadFailure? failure;
  const FeedbackState({
    this.failure,
    this.ready = false,
    this.type,
    this.text = '',
    this.viktor,
    this.sending = false,
    this.sent = false,
  });

  final FeedbackType? type;
  final String text;
  final Character? viktor;
  final bool sending;
  final bool sent;
  final bool ready;

  /// Com o assunto escolhido e algum texto.
  bool get canSend =>
      type != null && FeedbackEntry.clip(text).isNotEmpty && !sending;

  FeedbackState copyWith({
    bool? ready,
    FeedbackType? type,
    String? text,
    Character? viktor,
    bool? sending,
    bool? sent,
  }) => FeedbackState(
    ready: ready ?? this.ready,
    failure: failure,
    type: type ?? this.type,
    text: text ?? this.text,
    viktor: viktor ?? this.viktor,
    sending: sending ?? this.sending,
    sent: sent ?? this.sent,
  );
}

/// O "Enviar feedback" do Perfil (E1.26): assunto, texto até 500 e o
/// agradecimento do Viktor.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit({
    required this._feedback,
    required this._characters,
    this.language,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const FeedbackState());

  final FeedbackRepository _feedback;
  final CharacterRepository _characters;
  final AnalyticsRepository _analytics;

  /// O idioma do app, que vai junto.
  final String? language;

  Future<void> load() async {
    _retryLoad = () => load();
    try {
      await _load();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) emit(FeedbackState(failure: LoadFailure.of(error)));
    }
  }

  Future<void> Function()? _retryLoad;
  Future<void> retryLoad() async => _retryLoad?.call();

  Future<void> _load() async {
    Character? viktor;
    for (final character in await _characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (!isClosed) {
      emit(
        FeedbackState(
          ready: true,
          type: state.type,
          text: state.text,
          viktor: viktor,
        ),
      );
    }
  }

  void pickType(FeedbackType type) => emit(state.copyWith(type: type));

  void setText(String text) => emit(
    state.copyWith(
      text: text.length > FeedbackEntry.maxText
          ? text.substring(0, FeedbackEntry.maxText)
          : text,
    ),
  );

  Future<void> send() async {
    final type = state.type;
    if (type == null || !state.canSend || state.sent) return;
    emit(state.copyWith(sending: true));
    final ok = await _feedback.send(
      FeedbackEntry.free(type: type, text: state.text, language: language),
    );
    if (ok) {
      unawaited(
        _analytics.log(
          AnalyticsEvents.feedbackEnviado(
            tipo: type.code,
            tamanho: FeedbackEntry.clip(state.text).length,
          ),
        ),
      );
    }
    if (isClosed) return;
    emit(state.copyWith(sending: false, sent: ok));
  }
}
