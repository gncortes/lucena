import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/deep_link/install_referrer_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/campaign.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_install_referrer.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('campanha gravada', () {
    LocalCampaignRepository reopen() =>
        LocalCampaignRepository(PreferencesService());

    test('sobrevive a fechar o app e sai com clear', () async {
      const campaign = Campaign(
        utm: {'utm_source': 'instagram', 'utm_campaign': 'torre-engana'},
        code: 'k7Qe2',
        lesson: LinkedLesson.endgame('rook.lucena'),
      );
      expect(await reopen().active(), isNull);
      await reopen().remember(campaign);
      expect(await reopen().active(), campaign);
      await reopen().clear();
      expect(await reopen().active(), isNull);
    });

    test('o convite aceito vale uma vez só', () async {
      expect(await reopen().takeInvited(), isFalse);
      await reopen().markInvited();
      expect(await reopen().takeInvited(), isTrue);
      expect(await reopen().takeInvited(), isFalse);
    });
  });

  group('referrer da instalação', () {
    test('lê a Play uma vez só e devolve o link do desafio', () async {
      final service = FakeInstallReferrerService(
        '/aula/rook.lucena?utm_source=instagram',
      );
      ServiceInstallReferrerRepository reopen() =>
          ServiceInstallReferrerRepository(service, PreferencesService());

      final link = await reopen().pendingLink();
      expect(link?.path, '/aula/rook.lucena');
      expect(link?.queryParameters['utm_source'], 'instagram');
      // Abrir de novo não reabre o desafio.
      expect(await reopen().pendingLink(), isNull);
      expect(service.reads, 1);
    });

    test('instalação orgânica: nenhum link', () async {
      final service = FakeInstallReferrerService(
        'utm_source=google-play&utm_medium=organic',
      );
      final repository = ServiceInstallReferrerRepository(
        service,
        PreferencesService(),
      );
      expect(await repository.pendingLink(), isNull);
      expect(await const NoInstallReferrerRepository().pendingLink(), isNull);
    });

    test('o fake entrega o link pendente uma vez', () async {
      final fake = FakeInstallReferrerRepository(Uri.parse('https://x/p/a'));
      expect(await fake.pendingLink(), isNotNull);
      expect(await fake.pendingLink(), isNull);
    });
  });
}
