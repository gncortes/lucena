import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/load_failure.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/survey/survey_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/survey.dart';
import '../../../domain/use_cases/survey_rules.dart';

class SurveyState {
  final LoadFailure? failure;
  const SurveyState({
    this.failure,
    required this.kind,
    this.ready = false,
    this.step = 0,
    this.answers = const SurveyAnswers(),
    this.sending = false,
    this.sent = false,
    this.sendErrors = 0,
    this.viktor,
  });

  final SurveyKind kind;

  /// O rascunho já foi lido.
  final bool ready;

  /// O passo atual, a partir de 0.
  final int step;
  final SurveyAnswers answers;
  final bool sending;

  /// A resposta foi gravada: abre o agradecimento.
  final bool sent;

  /// Quantas vezes o envio falhou: cada falha nova mostra o aviso de erro,
  /// e as respostas ficam.
  final int sendErrors;
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
    int? sendErrors,
    Character? viktor,
  }) => SurveyState(
    kind: kind,
    ready: ready ?? this.ready,
    step: step ?? this.step,
    answers: answers ?? this.answers,
    sending: sending ?? this.sending,
    sent: sent ?? this.sent,
    sendErrors: sendErrors ?? this.sendErrors,
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
    this.origin,
    this.analytics = const NoAnalyticsRepository(),
  }) : super(SurveyState(kind: kind));

  final SurveyRepository surveys;
  final CharacterRepository characters;

  /// De onde abriu (`licao_pilares`, `licao_escola`, `diploma_pilares`,
  /// `diploma_escola`), só para o registro.
  final String? origin;
  final AnalyticsRepository analytics;

  /// O tipo no registro: `pilares` ou `escola`.
  String get _type => kind == SurveyKind.school ? 'escola' : 'pilares';

  SurveyKind get kind => state.kind;

  Future<void> load() async {
    _retryLoad = () => load();
    try {
      await _load();
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(SurveyState(kind: state.kind, failure: LoadFailure.of(error)));
      }
    }
  }

  Future<void> Function()? _retryLoad;
  Future<void> retryLoad() async => _retryLoad?.call();

  Future<void> _load() async {
    final draft = await surveys.loadDraft(kind);
    Character? viktor;
    for (final character in await characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (isClosed) return;
    if (!state.ready) {
      analytics.log(
        AnalyticsEvents.questionarioAberto(
          tipo: _type,
          origem: origin ?? 'outra',
        ),
      );
    }
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
    if (state.sent) return;
    emit(state.copyWith(step: step, answers: answers));
    try {
      await surveys.saveDraft(
        SurveyDraft(kind: kind, step: state.step, answers: state.answers),
      );
    } on Object catch (error, stack) {
      // Sem espaço, por exemplo: o passo segue na memória e a tela não cai.
      reportHandledError(error, stack);
    }
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
    analytics.log(
      AnalyticsEvents.questionarioPasso(
        tipo: _type,
        passo: state.step + 1,
        passosTotal: state.total,
      ),
    );
  }

  /// Saiu sem enviar (X do passo 1 ou voltar do sistema). O rascunho fica.
  void dismissed() {
    if (state.sent || !state.ready) return;
    analytics.log(
      AnalyticsEvents.questionarioDispensado(
        tipo: _type,
        passo: state.step + 1,
        como: 'fechou',
      ),
    );
  }

  /// Volta um passo. No primeiro não faz nada: a tela sai e o rascunho fica.
  Future<void> back() async {
    if (state.step == 0) return;
    await _change(step: state.step - 1);
  }

  /// Grava a resposta (uma vez só) e abre o agradecimento. Se a gravação
  /// falha, sai do carregando, conta o erro e mantém as respostas.
  Future<void> send() async {
    if (state.sending || state.sent || !state.isLast || !state.canAdvance) {
      return;
    }
    emit(state.copyWith(sending: true));
    // "Quer rever?" vem com "Sim": sem toque, vale "Sim".
    final answers = state.answers.copyWith(
      reReview: SurveyRules.reReviewOf(state.answers),
    );
    try {
      await surveys.saveResponse(kind, answers);
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(state.copyWith(sending: false, sendErrors: state.sendErrors + 1));
      }
      return;
    }
    final clean = answers.cleaned;
    analytics.log(
      AnalyticsEvents.questionarioEnviado(
        tipo: _type,
        nota: clean.rating,
        interesse: clean.interest?.name,
        melhorar: clean.improve,
        topicos: clean.topics,
        dificuldades: clean.difficulties,
        temTexto:
            clean.improveText != null ||
            clean.wishText != null ||
            clean.difficultyText != null,
        reverAula: clean.reReview,
      ),
    );
    if (isClosed) return;
    emit(state.copyWith(sending: false, sent: true, answers: answers));
  }
}
