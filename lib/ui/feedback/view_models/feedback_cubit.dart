import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/feedback/feedback_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/feedback_entry.dart';

class FeedbackState {
  const FeedbackState({
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

  /// Com o assunto escolhido e algum texto.
  bool get canSend =>
      type != null && FeedbackEntry.clip(text).isNotEmpty && !sending;

  FeedbackState copyWith({
    FeedbackType? type,
    String? text,
    Character? viktor,
    bool? sending,
    bool? sent,
  }) => FeedbackState(
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
  }) : super(const FeedbackState());

  final FeedbackRepository _feedback;
  final CharacterRepository _characters;

  /// O idioma do app, que vai junto.
  final String? language;

  Future<void> load() async {
    Character? viktor;
    for (final character in await _characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (!isClosed) emit(state.copyWith(viktor: viktor));
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
    if (isClosed) return;
    emit(state.copyWith(sending: false, sent: ok));
  }
}
