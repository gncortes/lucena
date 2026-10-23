import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/purchase/purchase_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/data/services/purchase_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_purchase_service.dart';

void main() {
  late FakePurchaseService play;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    play = FakePurchaseService();
  });

  Future<PlayPurchaseRepository> open() async {
    final repository = PlayPurchaseRepository(play, PreferencesService());
    await repository.start();
    await pumpEventQueue();
    return repository;
  }

  StorePurchase purchase(
    StorePurchaseStatus status, {
    bool needsCompletion = false,
  }) => StorePurchase(
    productId: removeAdsProductId,
    status: status,
    needsCompletion: needsCompletion,
  );

  test('lê o preço da Play e confere compras antigas', () async {
    final repository = await open();
    expect(repository.state.price, 'R\$ 9,90');
    expect(repository.state.adFree, isFalse);
    expect(play.restores, 1);
  });

  test('compra confirmada: sem anúncios, reconhecida e guardada', () async {
    final repository = await open();
    await repository.buy();
    expect(play.bought.single.id, removeAdsProductId);
    final done = purchase(StorePurchaseStatus.purchased, needsCompletion: true);
    play.send(done);
    await pumpEventQueue();
    expect(repository.state.adFree, isTrue);
    expect(play.completed, [done]);
    // Sem rede na próxima abertura, vale o guardado.
    play = FakePurchaseService(isAvailable: false);
    expect((await open()).state.adFree, isTrue);
  });

  test('pagamento pendente: espera, sem tirar os anúncios', () async {
    final repository = await open();
    play.send(purchase(StorePurchaseStatus.pending));
    await pumpEventQueue();
    expect(repository.state.pending, isTrue);
    expect(repository.state.adFree, isFalse);
    play.send(purchase(StorePurchaseStatus.purchased, needsCompletion: true));
    await pumpEventQueue();
    expect(repository.state.pending, isFalse);
    expect(repository.state.adFree, isTrue);
  });

  test('cancelada: nada muda', () async {
    final repository = await open();
    play.send(purchase(StorePurchaseStatus.pending));
    await pumpEventQueue();
    play.send(purchase(StorePurchaseStatus.canceled));
    await pumpEventQueue();
    expect(repository.state.pending, isFalse);
    expect(repository.state.adFree, isFalse);
    expect(repository.state.error, isFalse);
  });

  test('erro da Play: avisa e não tira os anúncios', () async {
    final repository = await open();
    play.send(purchase(StorePurchaseStatus.error));
    await pumpEventQueue();
    expect(repository.state.error, isTrue);
    expect(repository.state.adFree, isFalse);
  });

  test('restaurada em outro celular: sem anúncios', () async {
    final repository = await open();
    play.send(purchase(StorePurchaseStatus.restored, needsCompletion: true));
    await pumpEventQueue();
    expect(repository.state.adFree, isTrue);
    expect(play.completed, hasLength(1));
  });

  test('sem produto na Play, não há preço nem compra', () async {
    play = FakePurchaseService(price: null);
    final repository = await open();
    expect(repository.state.price, isNull);
    await repository.buy();
    expect(play.bought, isEmpty);
  });
}
