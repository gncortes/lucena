import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/services/purchase_service.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_purchase_service.dart';

void main() {
  late FakePurchaseService play;
  late FakeSitePurchaseService site;
  late FakeAnalyticsRepository analytics;
  late StreamController<Object?> account;
  final now = FakeNow(DateTime(2026, 11, 4, 10));

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    play = FakePurchaseService();
    site = FakeSitePurchaseService();
    analytics = FakeAnalyticsRepository();
    account = StreamController<Object?>.broadcast();
  });

  Future<PlayPurchaseRepository> open() async {
    final repository = PlayPurchaseRepository(
      play,
      PreferencesService(),
      site: site,
      now: now,
      analytics: analytics,
      accountChanges: account.stream,
    );
    await repository.start();
    await pumpEventQueue();
    return repository;
  }

  StorePurchase lifetime(
    StorePurchaseStatus status, {
    bool needsCompletion = false,
  }) => StorePurchase(
    productId: pilaresLifetimeProductId,
    status: status,
    needsCompletion: needsCompletion,
    purchasedAt: DateTime(2026, 11, 4),
  );

  StorePurchase monthly({DateTime? graceUntil}) => StorePurchase(
    productId: pilaresMonthlyProductId,
    status: StorePurchaseStatus.purchased,
    purchasedAt: DateTime(2026, 11, 4),
    renewsAt: DateTime(2026, 12, 4),
    graceUntil: graceUntil,
  );

  group('H-VEN-16/17: preço da loja', () {
    test('lê os dois preços da Play e confere a conta', () async {
      final repository = await open();
      expect(repository.state.prices, {
        PilaresPlan.lifetime: 'R\$ 89,90',
        PilaresPlan.monthly: 'R\$ 17,90',
      });
      expect(repository.state.pricesReady, isTrue);
      expect(repository.state.access.owns, isFalse);
      expect(play.ownedCalls, 1);
    });

    test('loja sem resposta: sem preço (a tela usa o de referência)', () async {
      play.isAvailable = false;
      final repository = await open();
      expect(repository.state.prices, isEmpty);
      expect(repository.state.pricesReady, isTrue);
    });
  });

  group('H-VEN-05/16: compra', () {
    test(
      'vitalício confirmado: acesso, acknowledge, Concluída e purchase',
      () async {
        final repository = await open();
        await repository.buy(PilaresPlan.lifetime);
        expect(play.bought.single.id, pilaresLifetimeProductId);
        expect(repository.state.processing, isTrue);
        final done = lifetime(
          StorePurchaseStatus.purchased,
          needsCompletion: true,
        );
        play.send(done);
        await pumpEventQueue();
        expect(repository.state.access.kind, PilaresAccessKind.lifetime);
        expect(repository.state.adFree, isTrue);
        expect(repository.state.outcome, PurchaseOutcome.done);
        expect(play.completed, [done]);
        final event = analytics.eventsNamed('purchase').single;
        expect(event.params['item_id'], 'pilares_vitalicio');
        expect(event.params['currency'], 'BRL');
        // Sem rede na próxima abertura, vale a cópia.
        play.isAvailable = false;
        expect((await open()).state.access.owns, isTrue);
      },
    );

    test('toque duplo abre a janela uma vez só', () async {
      final repository = await open();
      await Future.wait([
        repository.buy(PilaresPlan.monthly),
        repository.buy(PilaresPlan.monthly),
      ]);
      expect(play.bought, hasLength(1));
    });

    test('pendente: espera; confirmou depois: Concluída', () async {
      final repository = await open();
      await repository.buy(PilaresPlan.lifetime);
      play.send(lifetime(StorePurchaseStatus.pending));
      await pumpEventQueue();
      expect(repository.state.pending, isTrue);
      expect(repository.state.outcome, PurchaseOutcome.pending);
      expect(repository.state.access.owns, isFalse);
      repository.clearOutcome();
      expect(repository.state.outcome, isNull);
      play.send(lifetime(StorePurchaseStatus.purchased, needsCompletion: true));
      await pumpEventQueue();
      expect(repository.state.pending, isFalse);
      expect(repository.state.outcome, PurchaseOutcome.done);
    });

    test(
      'pendente sobrevive a fechar; confirmado ao abrir: Concluída',
      () async {
        final first = await open();
        await first.buy(PilaresPlan.lifetime);
        play.send(lifetime(StorePurchaseStatus.pending));
        await pumpEventQueue();
        await first.dispose();
        play.ownedPurchases = [lifetime(StorePurchaseStatus.purchased)];
        final repository = await open();
        expect(repository.state.access.owns, isTrue);
        expect(repository.state.outcome, PurchaseOutcome.done);
      },
    );

    test('cancelada: nada muda, avisa', () async {
      final repository = await open();
      await repository.buy(PilaresPlan.lifetime);
      play.send(lifetime(StorePurchaseStatus.canceled));
      await pumpEventQueue();
      expect(repository.state.outcome, PurchaseOutcome.canceled);
      expect(repository.state.processing, isFalse);
      expect(repository.state.access.owns, isFalse);
      expect(analytics.eventsNamed('purchase'), isEmpty);
    });

    test('erro da Play: avisa, sem acesso', () async {
      final repository = await open();
      play.send(lifetime(StorePurchaseStatus.error));
      await pumpEventQueue();
      expect(repository.state.outcome, PurchaseOutcome.error);
      expect(repository.state.access.owns, isFalse);
    });

    test('sem internet: avisa Sem internet e não abre a Play', () async {
      play.isAvailable = false;
      final repository = await open();
      await repository.buy(PilaresPlan.lifetime);
      expect(repository.state.outcome, PurchaseOutcome.offline);
      expect(play.bought, isEmpty);
    });
  });

  group('H-VEN-08: restaurar', () {
    test('achou na loja', () async {
      final repository = await open();
      play.ownedPurchases = [lifetime(StorePurchaseStatus.restored)];
      expect(await repository.restore(), RestoreResult.found);
      expect(repository.state.access.kind, PilaresAccessKind.lifetime);
      // Restaurar não é compra: sem Concluída e sem purchase.
      expect(repository.state.outcome, isNull);
      expect(analytics.eventsNamed('purchase'), isEmpty);
    });

    test('não achou', () async {
      final repository = await open();
      expect(await repository.restore(), RestoreResult.notFound);
    });

    test('sem internet', () async {
      final repository = await open();
      play.offline = true;
      expect(await repository.restore(), RestoreResult.offline);
    });

    test('comprou no site: chega pela conta ao entrar', () async {
      final repository = await open();
      site.purchasedAt = DateTime(2026, 10, 1);
      account.add(null);
      await pumpEventQueue();
      expect(repository.state.access.kind, PilaresAccessKind.lifetime);
      expect(repository.state.access.source, PilaresSource.site);
    });
  });

  group('H-VEN-10: assinatura', () {
    test('ativa, em carência e encerrada (avisa uma vez)', () async {
      play.ownedPurchases = [monthly()];
      var repository = await open();
      expect(repository.state.access.kind, PilaresAccessKind.monthlyActive);
      expect(repository.state.access.renewsAt, DateTime(2026, 12, 4));

      play.ownedPurchases = [monthly(graceUntil: DateTime(2026, 11, 10))];
      await repository.refresh();
      expect(repository.state.access.kind, PilaresAccessKind.monthlyGrace);

      play.ownedPurchases = [];
      await repository.refresh();
      expect(repository.state.access.kind, PilaresAccessKind.monthlyEnded);
      expect(repository.state.access.showEnded, isTrue);
      await repository.markEndedSeen();
      expect(repository.state.access.showEnded, isFalse);

      await repository.dispose();
      repository = await open();
      expect(repository.state.access.kind, PilaresAccessKind.monthlyEnded);
      expect(repository.state.access.showEnded, isFalse);
    });

    test('sem rede: a cópia da assinatura vale até a renovação', () async {
      play.ownedPurchases = [monthly()];
      await (await open()).dispose();
      play.offline = true;
      final repository = await open();
      expect(repository.state.access.kind, PilaresAccessKind.monthlyActive);
    });
  });
}
