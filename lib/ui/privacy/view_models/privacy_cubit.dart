import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/ads/ads_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';

class PrivacyState {
  const PrivacyState({
    this.ready = false,
    this.adFree = false,
    this.optionsRequired = false,
    this.hasAccount = false,
  });

  final bool ready;

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
      other.adFree == adFree &&
      other.optionsRequired == optionsRequired &&
      other.hasAccount == hasAccount;

  @override
  int get hashCode => Object.hash(ready, adFree, optionsRequired, hasAccount);
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
    _subscription ??= _purchases.changes.listen((_) => _refresh());
    await _refresh();
  }

  Future<void> _refresh() async {
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
