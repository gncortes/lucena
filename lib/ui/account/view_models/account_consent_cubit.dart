import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../data/repositories/legal/legal_consent_repository.dart';
import '../../../domain/models/analytics_event.dart';

class AccountConsentState {
  const AccountConsentState({
    this.checked = false,
    this.busy = false,
    this.done = false,
    this.failed = 0,
  });

  /// "Li e aceito": só com ela "Continuar" liga.
  final bool checked;
  final bool busy;

  /// Aceito: a tela segue.
  final bool done;

  /// Muda a cada falha ao gravar, para o aviso aparecer de novo.
  final int failed;

  AccountConsentState copyWith({
    bool? checked,
    bool? busy,
    bool? done,
    int? failed,
  }) => AccountConsentState(
    checked: checked ?? this.checked,
    busy: busy ?? this.busy,
    done: done ?? this.done,
    failed: failed ?? this.failed,
  );
}

/// "Termos e privacidade" (H-CON-08): a caixa e o aceite da conta [uid].
class AccountConsentCubit extends Cubit<AccountConsentState> {
  AccountConsentCubit({
    required this.uid,
    required this._consent,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const AccountConsentState());

  /// Nula: a conta saiu enquanto a tela estava aberta (segue sem gravar).
  final String? uid;
  final LegalConsentRepository _consent;
  final AnalyticsRepository _analytics;

  void toggle() {
    if (state.busy) return;
    emit(state.copyWith(checked: !state.checked));
  }

  /// Grava o aceite; falhando, a caixa continua marcada e vem o erro padrão.
  Future<void> accept() async {
    if (!state.checked || state.busy || state.done) return;
    final uid = this.uid;
    if (uid == null) {
      emit(state.copyWith(done: true));
      return;
    }
    emit(state.copyWith(busy: true));
    try {
      await _consent.accept(uid);
      unawaited(
        _analytics.log(
          AnalyticsEvents.aceiteTermos(versao: LegalConsentRepository.version),
        ),
      );
      if (!isClosed) emit(state.copyWith(busy: false, done: true));
    } on Object catch (error, stack) {
      debugPrint('legal consent failed: $error');
      reportHandledError(error, stack);
      if (!isClosed) {
        emit(state.copyWith(busy: false, failed: state.failed + 1));
      }
    }
  }
}
