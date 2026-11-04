import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/domain/models/pilares_access.dart';
import 'package:lucena/ui/pilares_sale/view_models/pilares_offer_cubit.dart';
import 'package:lucena/ui/pilares_sale/view_models/pilares_purchase_watch_cubit.dart';
import 'package:lucena/ui/pilares_sale/view_models/pilares_restore_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_purchase_service.dart';

void main() {
  late FakePurchaseRepository purchases;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    purchases = FakePurchaseRepository(
      const PurchaseState(
        pricesReady: true,
        prices: {
          PilaresPlan.lifetime: r'R$ 99,90',
          PilaresPlan.monthly: r'R$ 19,90',
        },
      ),
    );
    analytics = FakeAnalyticsRepository();
  });

  group('PilaresOfferCubit (H-VEN-03/06)', () {
    PilaresOfferCubit offer({FakeAccountRepository? accounts}) =>
        PilaresOfferCubit(
          purchases: purchases,
          accounts:
              accounts ??
              FakeAccountRepository(account: FakeAccountRepository.google),
          analytics: analytics,
          origin: 'demo',
        );

    test('abre com o vitalício e registra a oferta vista', () async {
      final cubit = offer();
      addTearDown(cubit.close);
      expect(cubit.state.plan, PilaresPlan.lifetime);
      expect(cubit.state.priceOf(PilaresPlan.lifetime), r'R$ 99,90');
      expect(analytics.eventsNamed('pilares_oferta_vista'), hasLength(1));
    });

    test('sem conta, comprar pede a conta e não abre a loja', () async {
      final cubit = offer(accounts: FakeAccountRepository());
      addTearDown(cubit.close);
      expect(await cubit.buy(), OfferBuyStep.needsAccount);
      expect(purchases.buys, isEmpty);
    });

    test('com conta, compra o plano escolhido', () async {
      final cubit = offer();
      addTearDown(cubit.close);
      cubit.select(PilaresPlan.monthly);
      expect(await cubit.buy(), OfferBuyStep.started);
      expect(purchases.buys, [PilaresPlan.monthly]);
      expect(analytics.eventsNamed('pilares_plano_escolhido'), hasLength(1));
    });

    test('cancelada vira aviso; erro e sem internet viram faixa', () async {
      final cubit = offer();
      addTearDown(cubit.close);
      purchases.state = purchases.state.copyWith(
        outcome: PurchaseOutcome.canceled,
      );
      await pumpEventQueue();
      expect(cubit.state.signal, OfferSignal.canceled);
      expect(purchases.state.outcome, isNull);

      purchases.state = purchases.state.copyWith(
        outcome: PurchaseOutcome.offline,
      );
      await pumpEventQueue();
      expect(cubit.state.banner, OfferBanner.offline);

      purchases.state = purchases.state.copyWith(
        outcome: PurchaseOutcome.error,
      );
      await pumpEventQueue();
      expect(cubit.state.banner, OfferBanner.error);
    });

    test('pagamento pendente sinaliza e não deixa comprar de novo', () async {
      final cubit = offer();
      addTearDown(cubit.close);
      purchases.state = purchases.state.copyWith(
        pending: true,
        outcome: PurchaseOutcome.pending,
      );
      await pumpEventQueue();
      expect(cubit.state.signal, OfferSignal.pending);
      expect(await cubit.buy(), OfferBuyStep.ignored);
      expect(purchases.buys, isEmpty);
    });

    test('processando: não troca de plano', () async {
      final cubit = offer();
      addTearDown(cubit.close);
      purchases.state = purchases.state.copyWith(processing: true);
      await pumpEventQueue();
      cubit.select(PilaresPlan.monthly);
      expect(cubit.state.plan, PilaresPlan.lifetime);
    });
  });

  group('PilaresRestoreCubit (H-VEN-08)', () {
    PilaresRestoreCubit restore() => PilaresRestoreCubit(
      purchases: purchases,
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      analytics: analytics,
    );

    test('achou: compra restaurada', () async {
      purchases
        ..restoreResult = RestoreResult.found
        ..state = purchases.state.copyWith(
          access: const PilaresAccess(kind: PilaresAccessKind.lifetime),
        );
      final cubit = restore();
      addTearDown(cubit.close);
      expect(cubit.state.email, 'teste@example.com');
      await cubit.search();
      expect(cubit.state.step, RestoreStep.found);
      expect(analytics.eventsNamed('pilares_restaurar'), hasLength(1));
    });

    test('assinatura vencida não restaura: não achou', () async {
      purchases
        ..restoreResult = RestoreResult.found
        ..state = purchases.state.copyWith(
          access: const PilaresAccess(kind: PilaresAccessKind.monthlyEnded),
        );
      final cubit = restore();
      addTearDown(cubit.close);
      await cubit.search();
      expect(cubit.state.step, RestoreStep.notFound);
    });

    test('sem internet e voltar da tela de erro', () async {
      purchases.restoreResult = RestoreResult.offline;
      final cubit = restore();
      addTearDown(cubit.close);
      await cubit.search();
      expect(cubit.state.step, RestoreStep.offline);
      cubit.reset();
      expect(cubit.state.step, RestoreStep.idle);
    });

    test('compra do site vem marcada', () async {
      purchases
        ..restoreResult = RestoreResult.found
        ..state = purchases.state.copyWith(
          access: const PilaresAccess(
            kind: PilaresAccessKind.lifetime,
            source: PilaresSource.site,
          ),
        );
      final cubit = restore();
      addTearDown(cubit.close);
      await cubit.search();
      expect(cubit.state.site, isTrue);
    });
  });

  group('PilaresPurchaseWatchCubit (H-VEN-05/10)', () {
    test('compra confirmada abre a Concluída uma vez', () async {
      final cubit = PilaresPurchaseWatchCubit(
        purchases: purchases,
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.screen, isNull);
      purchases.state = purchases.state.copyWith(outcome: PurchaseOutcome.done);
      await pumpEventQueue();
      expect(cubit.state.screen, PurchaseScreen.done);
      expect(cubit.state.id, 1);
      expect(purchases.state.outcome, isNull);
    });

    test('assinatura encerrada abre uma vez e marca vista', () async {
      purchases.state = purchases.state.copyWith(
        access: const PilaresAccess(kind: PilaresAccessKind.monthlyEnded),
      );
      final cubit = PilaresPurchaseWatchCubit(
        purchases: purchases,
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await pumpEventQueue();
      expect(cubit.state.screen, PurchaseScreen.ended);
      expect(cubit.state.id, 1);
      expect(purchases.state.access.endedSeen, isTrue);
      expect(
        analytics.eventsNamed('pilares_assinatura_encerrada'),
        hasLength(1),
      );
    });

    test('voltar do segundo plano consulta a loja', () async {
      final cubit = PilaresPurchaseWatchCubit(
        purchases: purchases,
        analytics: analytics,
      );
      addTearDown(cubit.close);
      await cubit.resumed();
      expect(purchases.refreshes, 1);
    });
  });
}
