import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/pilares_access.dart';

/// Onde está a procura da compra (H-VEN-08).
enum RestoreStep { idle, searching, found, notFound, offline, error }

class PilaresRestoreState {
  const PilaresRestoreState({
    this.step = RestoreStep.idle,
    this.email,
    this.site = false,
  });

  final RestoreStep step;

  /// O e-mail da conta em que a compra é procurada.
  final String? email;

  /// A compra achada veio do site (pela conta).
  final bool site;

  bool get searching => step == RestoreStep.searching;

  PilaresRestoreState copyWith({
    RestoreStep? step,
    String? email,
    bool? site,
  }) => PilaresRestoreState(
    step: step ?? this.step,
    email: email ?? this.email,
    site: site ?? this.site,
  );
}

/// Restaurar compra (H-VEN-08): procura na loja e na conta. Fechar à força
/// no meio volta à tela Restaurar (nada persiste além do acesso achado).
class PilaresRestoreCubit extends Cubit<PilaresRestoreState> {
  PilaresRestoreCubit({
    required this._purchases,
    required AccountRepository accounts,
    required this._analytics,
  }) : _accounts = accounts,
       super(PilaresRestoreState(email: accounts.current?.email));

  final PurchaseRepository _purchases;
  final AccountRepository _accounts;
  final AnalyticsRepository _analytics;

  /// Sem conta, a conta vem antes (a compra é dela).
  bool get needsAccount => _accounts.current == null;

  Future<void> search() async {
    if (state.searching) return;
    emit(
      state.copyWith(
        step: RestoreStep.searching,
        email: _accounts.current?.email,
      ),
    );
    final result = await _purchases.restore();
    if (isClosed) return;
    final access = _purchases.state.access;
    // Assinatura vencida não restaura: é "Não achou" (H-VEN-10 cuida dela).
    final found = result == RestoreResult.found && access.owns;
    final step = switch (result) {
      RestoreResult.found => found ? RestoreStep.found : RestoreStep.notFound,
      RestoreResult.notFound => RestoreStep.notFound,
      RestoreResult.offline => RestoreStep.offline,
      RestoreResult.error => RestoreStep.error,
    };
    unawaited(
      _analytics.log(AnalyticsEvents.pilaresRestaurar(resultado: step.name)),
    );
    emit(state.copyWith(step: step, site: access.source == PilaresSource.site));
  }

  /// "Entrar com Google" de "Comprou pelo site?": troca a conta e procura.
  Future<void> signInWithGoogle() async {
    if (state.searching) return;
    emit(state.copyWith(step: RestoreStep.searching));
    try {
      await _accounts.signOut();
      final account = await _accounts.signInWithGoogle();
      if (account == null) {
        if (!isClosed) emit(state.copyWith(step: RestoreStep.notFound));
        return;
      }
    } on Exception {
      if (!isClosed) emit(state.copyWith(step: RestoreStep.error));
      return;
    }
    emit(state.copyWith(step: RestoreStep.idle));
    await search();
  }

  /// "Entrar com e-mail" sai da conta atual antes da tela de e-mail.
  Future<void> signOut() => _accounts.signOut();

  /// O voltar da tela de erro: de novo a tela Restaurar.
  void reset() => emit(state.copyWith(step: RestoreStep.idle));
}
