import 'dart:async';
import 'dart:convert';

import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/pilares_access.dart';
import '../../../domain/use_cases/now.dart';
import '../../services/preferences_service.dart';
import '../../services/purchase_service.dart';
import '../analytics/analytics_repository.dart';

/// Como terminou a última compra aberta pela [PurchaseRepository.buy]
/// (H-VEN-05/06). A tela mostra e chama [PurchaseRepository.clearOutcome].
enum PurchaseOutcome { done, canceled, error, offline, pending }

/// "Restaurar compra" (H-VEN-08).
enum RestoreResult { found, notFound, offline, error }

/// O Pilares para o app todo (H-VEN-16): o acesso, os preços da loja e a
/// compra em andamento.
class PurchaseState {
  const PurchaseState({
    this.access = const PilaresAccess(),
    this.prices = const {},
    this.pricesReady = false,
    this.processing = false,
    this.pending = false,
    this.outcome,
    this.plan,
  });

  final PilaresAccess access;

  /// O preço da Play no país da conta, por plano (vazio sem loja).
  final Map<PilaresPlan, String> prices;

  /// A loja já respondeu (com ou sem preço).
  final bool pricesReady;

  /// A janela de pagamento está aberta.
  final bool processing;

  /// Compra feita, pagamento ainda não confirmado (boleto, Pix).
  final bool pending;
  final PurchaseOutcome? outcome;

  /// O plano da última compra.
  final PilaresPlan? plan;

  /// Comprador não vê anúncio.
  bool get adFree => access.owns;

  PurchaseState copyWith({
    PilaresAccess? access,
    Map<PilaresPlan, String>? prices,
    bool? pricesReady,
    bool? processing,
    bool? pending,
    PurchaseOutcome? outcome,
    bool clearOutcome = false,
    PilaresPlan? plan,
  }) => PurchaseState(
    access: access ?? this.access,
    prices: prices ?? this.prices,
    pricesReady: pricesReady ?? this.pricesReady,
    processing: processing ?? this.processing,
    pending: pending ?? this.pending,
    outcome: clearOutcome ? null : outcome ?? this.outcome,
    plan: plan ?? this.plan,
  );

  @override
  bool operator ==(Object other) =>
      other is PurchaseState &&
      other.access == access &&
      _samePrices(other.prices, prices) &&
      other.pricesReady == pricesReady &&
      other.processing == processing &&
      other.pending == pending &&
      other.outcome == outcome &&
      other.plan == plan;

  static bool _samePrices(
    Map<PilaresPlan, String> a,
    Map<PilaresPlan, String> b,
  ) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    access,
    Object.hashAll(prices.entries.map((e) => Object.hash(e.key, e.value))),
    pricesReady,
    processing,
    pending,
    outcome,
    plan,
  );
}

abstract class PurchaseRepository {
  PurchaseState get state;

  Stream<PurchaseState> get changes;

  /// Lê a cópia guardada, escuta a loja e, sem esperar, confere as compras
  /// da conta e busca os preços. Chamar uma vez, na abertura.
  Future<void> start();

  /// Confere de novo com a loja e com o site (ao voltar ao app, ao entrar
  /// na conta).
  Future<void> refresh();

  /// Abre a janela de pagamento do [plan]. O resultado chega por [changes].
  Future<void> buy(PilaresPlan plan);

  /// Procura a compra na loja e na conta (H-VEN-08).
  Future<RestoreResult> restore();

  /// A tela já mostrou o [PurchaseState.outcome].
  void clearOutcome();

  /// "Sua assinatura terminou" já apareceu (H-VEN-10).
  Future<void> markEndedSeen();
}

/// Play Billing e a compra do site, com a cópia do acesso no aparelho: sem
/// rede, vale a cópia ([PilaresAccess.offline]).
class PlayPurchaseRepository implements PurchaseRepository {
  PlayPurchaseRepository(
    this._service,
    this._preferences, {
    this._site = const NoSitePurchaseService(),
    this._now = const SystemNow(),
    this._analytics,
    this._accountChanges,
  });

  final PurchaseService _service;
  final PreferencesService _preferences;
  final SitePurchaseService _site;
  final Now _now;
  final AnalyticsRepository? _analytics;
  final Stream<Object?>? _accountChanges;

  static const accessKey = 'purchase.pilares.access';
  static const pendingKey = 'purchase.pilares.pending';

  /// O plano da janela de pagamento aberta: sobrevive a fechar à força no
  /// meio da compra, para "Concluída" aparecer na volta.
  static const buyingKey = 'purchase.pilares.buying';

  final _changes = StreamController<PurchaseState>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  final _products = <PilaresPlan, StoreProduct>{};
  Future<void>? _started;

  @override
  PurchaseState get state => _state;
  PurchaseState _state = const PurchaseState();

  @override
  Stream<PurchaseState> get changes => _changes.stream;

  void _emit(PurchaseState next) {
    if (next == _state || _changes.isClosed) return;
    _state = next;
    _changes.add(next);
  }

  static PilaresPlan? _planOf(String productId) => switch (productId) {
    pilaresLifetimeProductId => PilaresPlan.lifetime,
    pilaresMonthlyProductId => PilaresPlan.monthly,
    _ => null,
  };

  static String _productOf(PilaresPlan plan) => switch (plan) {
    PilaresPlan.lifetime => pilaresLifetimeProductId,
    PilaresPlan.monthly => pilaresMonthlyProductId,
  };

  @override
  Future<void> start() => _started ??= _start();

  Future<void> _start() async {
    final stored = await _preferences.getString(accessKey);
    var access = const PilaresAccess();
    if (stored != null) {
      try {
        access = PilaresAccess.fromJson(
          (jsonDecode(stored) as Map).cast<String, Object?>(),
        );
      } on FormatException {
        // Cópia ilegível: demo até a loja responder.
      } on TypeError {
        // Idem.
      }
    }
    final pending = await _preferences.getBool(pendingKey) ?? false;
    final buying = _planFromName(await _preferences.getString(buyingKey));
    _emit(
      _state.copyWith(
        access: access.offline(_now()),
        pending: pending && !access.owns,
        plan: buying,
      ),
    );
    _subscriptions.add(_service.purchases.listen(_onPurchase));
    final account = _accountChanges;
    if (account != null) {
      _subscriptions.add(account.listen((_) => unawaited(refresh())));
    }
    unawaited(_query());
  }

  static PilaresPlan? _planFromName(String? name) =>
      name == null ? null : PilaresPlan.values.asNameMap()[name];

  Future<void> _query() async {
    try {
      if (await _service.available()) {
        for (final plan in PilaresPlan.values) {
          final product = await _service.product(_productOf(plan));
          if (product != null) _products[plan] = product;
        }
      }
    } on Exception {
      // Sem rede: sem preço; a Oferta mostra o de referência.
    }
    _emit(
      _state.copyWith(
        prices: {for (final e in _products.entries) e.key: e.value.price},
        pricesReady: true,
      ),
    );
    await _sync();
  }

  @override
  Future<void> refresh() async {
    await start();
    await _sync();
  }

  /// Confere a loja e o site. Devolve se achou compra; nulo sem rede.
  Future<bool?> _sync() async {
    List<StorePurchase> owned;
    DateTime? site;
    try {
      // Sem Play não há como confirmar: vale a cópia.
      if (!await _service.available()) return null;
      owned = await _service.owned();
    } on StoreOfflineException {
      return null;
    } on Exception {
      return null;
    }
    try {
      site = await _site.pilaresPurchasedAt();
    } on Exception {
      site = null;
    }
    final next = _fromStore(owned, site);
    for (final purchase in owned) {
      if (purchase.needsCompletion) await _service.complete(purchase);
    }
    await _setAccess(next);
    return next.owns;
  }

  /// O acesso que a loja e o site confirmam, a partir da cópia atual.
  PilaresAccess _fromStore(List<StorePurchase> owned, DateTime? site) {
    final current = _state.access;
    StorePurchase? find(String id) => owned
        .where(
          (p) =>
              p.productId == id &&
              (p.status == StorePurchaseStatus.purchased ||
                  p.status == StorePurchaseStatus.restored),
        )
        .firstOrNull;
    final lifetime = find(pilaresLifetimeProductId);
    if (lifetime != null) {
      return PilaresAccess(
        kind: PilaresAccessKind.lifetime,
        since: lifetime.purchasedAt ?? current.since,
      );
    }
    if (site != null) {
      return PilaresAccess(
        kind: PilaresAccessKind.lifetime,
        since: site,
        source: PilaresSource.site,
      );
    }
    final monthly = find(pilaresMonthlyProductId);
    if (monthly != null) {
      final grace = monthly.graceUntil;
      return PilaresAccess(
        kind: grace != null && _now().isBefore(grace)
            ? PilaresAccessKind.monthlyGrace
            : PilaresAccessKind.monthlyActive,
        since: monthly.purchasedAt ?? current.since,
        renewsAt: monthly.renewsAt,
        graceUntil: grace,
      );
    }
    // A loja respondeu sem compra: a assinatura acabou; o resto é demo.
    if (current.monthly || current.kind == PilaresAccessKind.monthlyEnded) {
      return current.ended();
    }
    return const PilaresAccess();
  }

  Future<void> _setAccess(PilaresAccess access) async {
    await _preferences.setString(accessKey, jsonEncode(access.toJson()));
    final wasBuying =
        _state.plan != null && await _preferences.getString(buyingKey) != null;
    if (access.owns) {
      await _preferences.remove(pendingKey);
      await _preferences.remove(buyingKey);
    }
    // Comprou com o app fechado (ou o pendente confirmou): "Concluída" uma vez.
    final confirmed =
        access.owns && !_state.access.owns && (wasBuying || _state.pending);
    _emit(
      _state.copyWith(
        access: access,
        pending: access.owns ? false : null,
        processing: access.owns ? false : null,
        outcome: confirmed ? PurchaseOutcome.done : null,
      ),
    );
  }

  Future<void> _onPurchase(StorePurchase purchase) async {
    final plan = _planOf(purchase.productId);
    if (plan == null) return;
    switch (purchase.status) {
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        final wasOwner = _state.access.owns;
        final access = plan == PilaresPlan.lifetime
            ? PilaresAccess(
                kind: PilaresAccessKind.lifetime,
                since: purchase.purchasedAt ?? _now(),
              )
            : PilaresAccess(
                kind: PilaresAccessKind.monthlyActive,
                since: purchase.purchasedAt ?? _now(),
                renewsAt: purchase.renewsAt,
              );
        // Guarda antes do acknowledge: se o app cair no meio, a cópia vale.
        await _preferences.setString(accessKey, jsonEncode(access.toJson()));
        await _preferences.remove(pendingKey);
        await _preferences.remove(buyingKey);
        if (purchase.needsCompletion) await _service.complete(purchase);
        final bought = purchase.status == StorePurchaseStatus.purchased;
        _emit(
          _state.copyWith(
            access: access,
            pending: false,
            processing: false,
            plan: plan,
            outcome: bought && !wasOwner ? PurchaseOutcome.done : null,
          ),
        );
        if (bought && !wasOwner) await _logPurchase(plan);
      case StorePurchaseStatus.pending:
        await _preferences.setBool(pendingKey, value: true);
        _emit(
          _state.copyWith(
            pending: true,
            processing: false,
            plan: plan,
            outcome: PurchaseOutcome.pending,
          ),
        );
      case StorePurchaseStatus.canceled:
        // Também o pendente que venceu sem pagar.
        await _preferences.remove(buyingKey);
        await _preferences.remove(pendingKey);
        _emit(
          _state.copyWith(
            processing: false,
            pending: false,
            outcome: PurchaseOutcome.canceled,
          ),
        );
      case StorePurchaseStatus.error:
        await _preferences.remove(buyingKey);
        _emit(
          _state.copyWith(processing: false, outcome: PurchaseOutcome.error),
        );
    }
  }

  Future<void> _logPurchase(PilaresPlan plan) async {
    final product = _products[plan];
    await _analytics?.log(
      AnalyticsEvents.purchase(
        plan: plan,
        value: product?.rawPrice,
        currency: product?.currency,
      ),
    );
  }

  @override
  Future<void> buy(PilaresPlan plan) async {
    await start();
    // Toque duplo, ou já comprou: nada.
    if (_state.processing || _state.access.owns) return;
    _emit(_state.copyWith(processing: true, plan: plan, clearOutcome: true));
    try {
      if (!await _service.available()) throw const StoreOfflineException();
      var product = _products[plan];
      if (product == null) {
        product = await _service.product(_productOf(plan));
        if (product == null) throw const StoreOfflineException();
        _products[plan] = product;
      }
      await _preferences.setString(buyingKey, plan.name);
      await _service.buy(product);
    } on StoreOfflineException {
      await _preferences.remove(buyingKey);
      _emit(
        _state.copyWith(processing: false, outcome: PurchaseOutcome.offline),
      );
    } on Exception {
      await _preferences.remove(buyingKey);
      _emit(_state.copyWith(processing: false, outcome: PurchaseOutcome.error));
    }
  }

  @override
  Future<RestoreResult> restore() async {
    await start();
    try {
      if (!await _service.available()) return RestoreResult.offline;
    } on Exception {
      return RestoreResult.offline;
    }
    final found = await _sync();
    return switch (found) {
      null => RestoreResult.offline,
      true => RestoreResult.found,
      false => RestoreResult.notFound,
    };
  }

  @override
  void clearOutcome() => _emit(_state.copyWith(clearOutcome: true));

  @override
  Future<void> markEndedSeen() async {
    final access = _state.access.copyWith(endedSeen: true);
    await _preferences.setString(accessKey, jsonEncode(access.toJson()));
    _emit(_state.copyWith(access: access));
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _changes.close();
  }
}

/// Sem Play (F-Droid, testes): demo, com os anúncios.
class NoPurchaseRepository implements PurchaseRepository {
  const NoPurchaseRepository();

  @override
  PurchaseState get state => const PurchaseState(pricesReady: true);

  @override
  Stream<PurchaseState> get changes => const Stream.empty();

  @override
  Future<void> start() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> buy(PilaresPlan plan) async {}

  @override
  Future<RestoreResult> restore() async => RestoreResult.notFound;

  @override
  void clearOutcome() {}

  @override
  Future<void> markEndedSeen() async {}
}
