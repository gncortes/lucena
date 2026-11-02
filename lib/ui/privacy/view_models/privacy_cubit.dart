import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/ads/ads_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';

class PrivacyState {
  const PrivacyState({
    this.ready = false,
    this.adFree = false,
    this.optionsRequired = false,
    this.hasAccount = false,
    this.failure,
  });

  final bool ready;
  final LoadFailure? failure;

  /// Comprou "Remover anúncios": cartão "Sem anúncios", sem "Escolhas de
  /// anúncios".
  final bool adFree;

  /// O SDK do Google exige as opções de privacidade.
  final bool optionsRequired;

  /// "Apagar minha conta e meus dados" só com conta.
  final bool hasAccount;

  bool get showsAdChoices => optionsRequired && !adFree;

  @override
  bool operator ==(Object other) =>
      other is PrivacyState &&
      other.ready == ready &&
      other.failure == failure &&
      other.adFree == adFree &&
      other.optionsRequired == optionsRequired &&
      other.hasAccount == hasAccount;

  @override
  int get hashCode =>
      Object.hash(ready, adFree, optionsRequired, hasAccount, failure);
}

/// Privacidade e anúncios (E1.25, item 2).
class PrivacyCubit extends Cubit<PrivacyState> {
  PrivacyCubit({
    required this._ads,
    required this._purchases,
    required this._accounts,
  }) : super(const PrivacyState());

  final AdsRepository _ads;
  final PurchaseRepository _purchases;
  final AccountRepository _accounts;
  StreamSubscription<PurchaseState>? _subscription;

  Future<void> load() async {
    try {
      _subscription ??= _purchases.changes.listen(
        (_) => unawaited(_refresh()),
        onError: _failed,
      );
      await _refresh();
    } on Object catch (error, stack) {
      _failed(error, stack);
    }
  }

  Future<void> _refresh() async {
    try {
      await _read();
    } on Object catch (error, stack) {
      _failed(error, stack);
    }
  }

  void _failed(Object error, StackTrace stack) {
    debugPrint('privacy load failed: $error');
    reportHandledError(error, stack);
    if (isClosed) return;
    emit(
      PrivacyState(
        ready: state.ready,
        adFree: state.adFree,
        optionsRequired: state.optionsRequired,
        hasAccount: state.hasAccount,
        failure: LoadFailure.generic,
      ),
    );
  }

  Future<void> _read() async {
    final adFree = _purchases.state.adFree;
    final required = !adFree && await _ads.privacyOptionsRequired();
    if (isClosed) return;
    emit(
      PrivacyState(
        ready: true,
        adFree: adFree,
        optionsRequired: required,
        hasAccount: _accounts.current != null,
      ),
    );
  }

  /// Reabre as opções do Google; a escolha pode mudar o que é exigido.
  Future<void> openAdChoices() async {
    await _ads.showPrivacyOptions();
    await _refresh();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
