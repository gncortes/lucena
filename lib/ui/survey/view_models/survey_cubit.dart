import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/survey/survey_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/use_cases/survey_rules.dart';

class SurveyState {
  const SurveyState({
    required this.kind,
    this.ready = false,
    this.step = 0,
    this.answers = const SurveyAnswers(),
    this.sending = false,
    this.sent = false,
    this.viktor,
  });

  final SurveyKind kind;

  /// O rascunho já foi lido.
  final bool ready;

  /// O passo atual, a partir de 0.
  final int step;
  final SurveyAnswers answers;
  final bool sending;

  /// A resposta foi gravada: mostra o agradecimento.
  final bool sent;
  final Character? viktor;

  int get total => SurveyRules.totalSteps(kind);
  bool get isLast => step >= total - 1;
  bool get canAdvance => SurveyRules.canAdvance(kind, step, answers);

  SurveyState copyWith({
    bool? ready,
    int? step,
    SurveyAnswers? answers,
    bool? sending,
    bool? sent,
    Character? viktor,
  }) => SurveyState(
    kind: kind,
    ready: ready ?? this.ready,
    step: step ?? this.step,
    answers: answers ?? this.answers,
    sending: sending ?? this.sending,
    sent: sent ?? this.sent,
    viktor: viktor ?? this.viktor,
  );
}

/// O questionário "Sua opinião". Cada mudança grava o rascunho (passo e
/// respostas), para retomar depois de sair ou fechar o app.
class SurveyCubit extends Cubit<SurveyState> {
  SurveyCubit({
    required SurveyKind kind,
    required this.surveys,
    required this.characters,
  }) : super(SurveyState(kind: kind));

  final SurveyRepository surveys;
  final CharacterRepository characters;

  SurveyKind get kind => state.kind;

  Future<void> load() async {
    final draft = await surveys.loadDraft(kind);
    Character? viktor;
    for (final character in await characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (isClosed) return;
    emit(
      state.copyWith(
        ready: true,
        step: draft == null ? 0 : draft.step.clamp(0, state.total - 1),
        answers: draft?.answers,
        viktor: viktor,
      ),
    );
  }

  static String? _clip(String? text) => text == null
      ? null
      : text.length > SurveyAnswers.maxText
      ? text.substring(0, SurveyAnswers.maxText)
      : text;

  Future<void> _change({int? step, SurveyAnswers? answers}) async {
    emit(state.copyWith(step: step, answers: answers));
    await surveys.saveDraft(
      SurveyDraft(kind: kind, step: state.step, answers: state.answers),
    );
  }

  Future<void> pickRating(int rating) =>
      _change(answers: state.answers.copyWith(rating: rating));

  Set<String> _toggled(Set<String> set, String id) =>
      set.contains(id) ? ({...set}..remove(id)) : {...set, id};

  Future<void> toggleImprove(String id) => _change(
    answers: state.answers.copyWith(
      improve: _toggled(state.answers.improve, id),
    ),
  );

  Future<void> toggleTopic(String id) => _change(
    answers: state.answers.copyWith(topics: _toggled(state.answers.topics, id)),
  );

  Future<void> toggleDifficulty(String id) => _change(
    answers: state.answers.copyWith(
      difficulties: _toggled(state.answers.difficulties, id),
    ),
  );

  Future<void> setImproveText(String text) =>
      _change(answers: state.answers.copyWith(improveText: _clip(text)));

  Future<void> setWishText(String text) =>
      _change(answers: state.answers.copyWith(wishText: _clip(text)));

  Future<void> setDifficultyText(String text) =>
      _change(answers: state.answers.copyWith(difficultyText: _clip(text)));

  Future<void> pickInterest(SurveyInterest interest) =>
      _change(answers: state.answers.copyWith(interest: interest));

  Future<void> pickReReview({required bool yes}) =>
      _change(answers: state.answers.copyWith(reReview: yes));

  /// Vai ao próximo passo, se o atual está completo.
  Future<void> next() async {
    if (state.isLast || !state.canAdvance) return;
    await _change(step: state.step + 1);
  }

  /// Volta um passo. No primeiro não faz nada: a tela sai e o rascunho fica.
  Future<void> back() async {
    if (state.step == 0) return;
    await _change(step: state.step - 1);
  }

  /// Grava a resposta (uma vez só) e mostra o agradecimento.
  Future<void> send() async {
    if (state.sending || state.sent || !state.isLast || !state.canAdvance) {
      return;
    }
    emit(state.copyWith(sending: true));
    await surveys.saveResponse(kind, state.answers);
    if (isClosed) return;
    emit(state.copyWith(sending: false, sent: true));
  }
}
