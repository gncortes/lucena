import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/review/review_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../../testing/fakes/fake_now.dart';

void main() {
  late FakeNow now;
  late FakeReviewService service;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = FakeNow(DateTime.utc(2026, 3, 1, 9));
    service = FakeReviewService();
  });

  LocalReviewRepository open() =>
      LocalReviewRepository(PreferencesService(), service, now);

  Future<bool> ask(LocalReviewRepository repository) =>
      repository.maybeAsk(lessonsCompleted: 3, endgamesWon: 0);

  test('a primeira abertura fica e não muda nas próximas', () async {
    await open().markFirstOpen();
    now.value = DateTime.utc(2026, 3, 3);
    await open().markFirstOpen();
    now.value = DateTime.utc(2026, 3, 4, 8);
    // Contou do dia 1: 3 dias.
    expect(await ask(open()), isTrue);
    expect(service.requests, 1);
  });

  test('cada pedido conta: 60 dias depois o 2º, e só 3 na vida', () async {
    await open().markFirstOpen();
    now.value = DateTime.utc(2026, 3, 5);
    expect(await ask(open()), isTrue);
    now.value = DateTime.utc(2026, 4, 5);
    expect(await ask(open()), isFalse);
    now.value = DateTime.utc(2026, 5, 4);
    expect(await ask(open()), isTrue);
    now.value = DateTime.utc(2026, 7, 4);
    expect(await ask(open()), isTrue);
    now.value = DateTime.utc(2027, 1, 1);
    expect(await ask(open()), isFalse);
    expect(service.requests, 3);
  });

  test('questionário visto ou revés recente seguram o pedido', () async {
    await open().markFirstOpen();
    now.value = DateTime.utc(2026, 3, 5);
    final seen = open()..noteSurveySeen();
    expect(await ask(seen), isFalse);
    final lost = open()..noteSetback();
    expect(await ask(lost), isFalse);
    now.value = now.value.add(const Duration(minutes: 5));
    expect(await ask(lost), isTrue);
    expect(service.requests, 1);
  });

  test('sem Play não pede; a página da loja abre direto', () async {
    service.available = false;
    await open().markFirstOpen();
    now.value = DateTime.utc(2026, 4, 1);
    expect(await ask(open()), isFalse);
    await open().openStoreListing();
    expect(service.storeOpens, 1);
    expect(service.requests, 0);
  });
}
