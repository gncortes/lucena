import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/purchase/purchase_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/offer_discount.dart';
import '../../../domain/models/pilares_access.dart';

/// O aviso no topo da oferta quando a compra não terminou (H-VEN-06).
enum OfferBanner { error, offline }

/// O que a tela faz uma vez, a partir do fim da compra (H-VEN-06).
enum OfferSignal { canceled, pending }

class PilaresOfferState {
  const PilaresOfferState({
    this.plan = PilaresPlan.lifetime,
    this.purchase = const PurchaseState(),
    this.banner,
    this.signal,
    this.signalId = 0,
  });

  /// O plano marcado. Não persiste: abrir de novo volta ao vitalício.
  final PilaresPlan plan;
  final PurchaseState purchase;
  final OfferBanner? banner;

  /// Snackbar de cancelada ou ida à Pendente; [signalId] muda a cada vez.
  final OfferSignal? signal;
  final int signalId;

  /// O preço da loja do [plan], se ela já respondeu com ele.
  String? priceOf(PilaresPlan plan) => purchase.prices[plan];

  /// Os preços ainda não vieram: os cartões piscam e o botão espera.
  bool get loadingPrices => !purchase.pricesReady;

  /// Confirmando a compra: tudo desligado, voltar não age (H-VEN-05).
  bool get processing => purchase.processing;

  /// Pagamento pendente: "Comprar" desligado até a loja confirmar.
  bool get pending => purchase.pending;

  /// O desconto do vitalício (regra 10), só com o preço da loja.
  OfferDiscount? get discount => purchase.discount;

  /// O link de desconto não vale mais: o aviso no topo, uma vez.
  bool get linkGone => purchase.linkGone;

  PilaresOfferState copyWith({
    PilaresPlan? plan,
    PurchaseState? purchase,
    OfferBanner? banner,
    bool clearBanner = false,
    OfferSignal? signal,
  }) => PilaresOfferState(
    plan: plan ?? this.plan,
    purchase: purchase ?? this.purchase,
    banner: clearBanner ? null : banner ?? this.banner,
    signal: signal ?? this.signal,
    signalId: signal == null ? signalId : signalId + 1,
  );
}

/// O que acontece ao tocar no botão principal.
enum OfferBuyStep { needsAccount, started, ignored }

/// A oferta do Pilares (H-VEN-03/05/06): o plano escolhido e a compra.
class PilaresOfferCubit extends Cubit<PilaresOfferState> {
  PilaresOfferCubit({
    required PurchaseRepository purchases,
    required this._accounts,
    required this._analytics,
    PilaresPlan plan = PilaresPlan.lifetime,
    this._origin = 'perfil',
    String? offerCode,
  }) : _purchases = purchases,
       super(PilaresOfferState(plan: plan, purchase: purchases.state)) {
    _subscription = purchases.changes.listen(_onPurchase);
    unawaited(_purchases.start());
    // Veio do link com desconto: o código fica guardado (H-R5-66).
    if (offerCode != null) unawaited(_purchases.useOfferCode(offerCode));
    unawaited(
      _analytics.log(
        AnalyticsEvents.pilaresOfertaVista(origem: _origin, destaque: 'oferta'),
      ),
    );
    _onPurchase(purchases.state);
  }

  final PurchaseRepository _purchases;
  final AccountRepository _accounts;
  final AnalyticsRepository _analytics;
  final String _origin;
  late final StreamSubscription<PurchaseState> _subscription;

  /// Sem conta, "Restaurar compra" pede a conta antes (a compra é dela).
  bool get needsAccount => _accounts.current == null;

  void select(PilaresPlan plan) {
    if (state.processing || plan == state.plan) return;
    emit(state.copyWith(plan: plan));
    unawaited(
      _analytics.log(AnalyticsEvents.pilaresPlanoEscolhido(plan: plan)),
    );
  }

  /// "Comprar"/"Assinar" e "Tentar novamente": sem conta, a conta vem antes
  /// (H-CON-05); com ela, abre a folha da loja do plano marcado.
  Future<OfferBuyStep> buy() async {
    if (state.processing || state.pending) return OfferBuyStep.ignored;
    if (_accounts.current == null) return OfferBuyStep.needsAccount;
    emit(state.copyWith(clearBanner: true));
    // O resultado (`pilares_compra_resultado`, `purchase`) sai do repositório.
    await _purchases.buy(state.plan);
    return OfferBuyStep.started;
  }

  /// Saiu da oferta sem comprar.
  void leave() => unawaited(
    _analytics.log(
      AnalyticsEvents.pilaresOfertaFechada(origem: _origin, destaque: 'oferta'),
    ),
  );

  void _onPurchase(PurchaseState purchase) {
    if (isClosed) return;
    final next = state.copyWith(purchase: purchase);
    switch (purchase.outcome) {
      case PurchaseOutcome.canceled:
        emit(next.copyWith(clearBanner: true, signal: OfferSignal.canceled));
        _purchases.clearOutcome();
      case PurchaseOutcome.pending:
        emit(next.copyWith(clearBanner: true, signal: OfferSignal.pending));
        _purchases.clearOutcome();
      case PurchaseOutcome.error:
        emit(next.copyWith(banner: OfferBanner.error));
        _purchases.clearOutcome();
      case PurchaseOutcome.offline:
        emit(next.copyWith(banner: OfferBanner.offline));
        _purchases.clearOutcome();
      // Concluída: a ponte da compra leva à tela, de onde quer que esteja.
      case PurchaseOutcome.done:
      case null:
        emit(next);
    }
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    // O aviso do link aparece uma vez só.
    if (state.linkGone) unawaited(_purchases.dismissLinkNotice());
    return super.close();
  }
}
