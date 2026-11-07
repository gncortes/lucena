import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/feedback/feedback_draft_repository.dart';
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
    this.sendErrors = 0,
    this.needsAccount = 0,
  });

  final FeedbackType? type;
  final String text;
  final Character? viktor;
  final bool sending;
  final bool sent;
  final bool ready;

  /// Quantas vezes o envio falhou: cada falha nova mostra o aviso, e o
  /// assunto e o texto ficam.
  final int sendErrors;

  /// Quantas vezes o envio parou por falta de conta: cada uma mostra o aviso
  /// com "Entrar", e o assunto e o texto ficam no rascunho.
  final int needsAccount;

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
    int? sendErrors,
    int? needsAccount,
  }) => FeedbackState(
    ready: ready ?? this.ready,
    failure: failure,
    type: type ?? this.type,
    text: text ?? this.text,
    viktor: viktor ?? this.viktor,
    sending: sending ?? this.sending,
    sent: sent ?? this.sent,
    sendErrors: sendErrors ?? this.sendErrors,
    needsAccount: needsAccount ?? this.needsAccount,
  );
}

/// O "Enviar feedback" do Perfil (E1.26, H-OPI-11): assunto e texto até
/// 500. Cada mudança grava o rascunho, que volta depois de fechar o app e
/// some ao enviar.
class FeedbackCubit extends Cubit<FeedbackState> {
  FeedbackCubit({
    required this._feedback,
    required this._characters,
    this._drafts = const NoFeedbackDraftRepository(),
    this.language,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const FeedbackState());

  final FeedbackRepository _feedback;
  final CharacterRepository _characters;
  final FeedbackDraftRepository _drafts;
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
    FeedbackDraft? draft;
    try {
      draft = await _drafts.load();
    } on Object catch (error, stack) {
      // Sem o rascunho, o formulário abre vazio; não é erro de tela.
      reportHandledError(error, stack);
    }
    Character? viktor;
    for (final character in await _characters.characters()) {
      if (character.id == 'master') viktor = character;
    }
    if (!isClosed) {
      emit(
        FeedbackState(
          ready: true,
          type: state.type ?? draft?.type,
          text: state.text.isNotEmpty ? state.text : draft?.text ?? '',
          viktor: viktor,
        ),
      );
    }
  }

  Future<void> _saveDraft() async {
    try {
      await _drafts.save(FeedbackDraft(type: state.type, text: state.text));
    } on Object catch (error, stack) {
      // Sem espaço, por exemplo: o texto segue na memória e a tela não cai.
      reportHandledError(error, stack);
    }
  }

  Future<void> pickType(FeedbackType type) async {
    if (state.sent) return;
    emit(state.copyWith(type: type));
    await _saveDraft();
  }

  Future<void> setText(String text) async {
    if (state.sent) return;
    emit(
      state.copyWith(
        text: text.length > FeedbackEntry.maxText
            ? text.substring(0, FeedbackEntry.maxText)
            : text,
      ),
    );
    await _saveDraft();
  }

  /// Manda o feedback (uma vez só). Se falha, sai do carregando, conta o
  /// erro e mantém o assunto e o texto para tentar de novo.
  Future<void> send() async {
    final type = state.type;
    if (type == null || !state.canSend || state.sent) return;
    emit(state.copyWith(sending: true));
    bool ok;
    try {
      ok = await _feedback.send(
        FeedbackEntry.free(type: type, text: state.text, language: language),
      );
    } on FeedbackNeedsAccount {
      // Não é falha: o feedback só vai com conta (proteção contra abuso).
      if (!isClosed) {
        emit(
          state.copyWith(sending: false, needsAccount: state.needsAccount + 1),
        );
      }
      return;
    } on Object catch (error, stack) {
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(state.copyWith(sending: false, sendErrors: state.sendErrors + 1));
      }
      return;
    }
    if (ok) {
      try {
        await _drafts.clear();
      } on Object catch (error, stack) {
        reportHandledError(error, stack);
      }
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
