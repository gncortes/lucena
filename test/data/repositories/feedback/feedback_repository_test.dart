import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/feedback/feedback_repository.dart';
import 'package:lucena/data/services/device_service.dart';
import 'package:lucena/data/services/firebase/cloud_store_service.dart';
import 'package:lucena/domain/models/app_version.dart';
import 'package:lucena/domain/models/feedback_entry.dart';

import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_feedback_repositories.dart';

void main() {
  late FakeCloudStoreService store;

  setUp(() => store = FakeCloudStoreService());

  CloudFeedbackRepository repository() => CloudFeedbackRepository(
    store,
    const FakeDeviceService(
      value: DeviceModel(model: 'Pixel 8', manufacturer: 'Google'),
    ),
    const AppVersion('1.4.0'),
    wait: Duration.zero,
  );

  test('o texto livre vai com assunto, versão e modelo, sem uid', () async {
    final ok = await repository().send(
      const FeedbackEntry.free(
        type: FeedbackType.idea,
        text: '  Mais finais de torre  ',
        language: 'pt',
      ),
    );
    expect(ok, isTrue);
    expect(store.feedback.single, {
      'kind': 'livre',
      'type': 'ideia',
      'text': 'Mais finais de torre',
      'appVersion': '1.4.0',
      'model': 'Pixel 8',
      'manufacturer': 'Google',
      'language': 'pt',
    });
  });

  test('a origem da 1ª abertura vai junto (E1.03)', () async {
    final ok = await CloudFeedbackRepository(
      store,
      const FakeDeviceService(
        value: DeviceModel(model: 'Pixel 8', manufacturer: 'Google'),
      ),
      const AppVersion('1.4.0'),
      origin: () async => 'link',
    ).send(const FeedbackEntry.free(type: FeedbackType.idea, text: 'Oi'));
    expect(ok, isTrue);
    expect(store.feedback.single['origin'], 'link');
  });

  test('o texto é cortado em 500 letras', () async {
    await repository().send(
      FeedbackEntry.free(type: FeedbackType.problem, text: 'a' * 600),
    );
    expect(store.feedback.single['text'], 'a' * 500);
  });

  test('texto vazio não é mandado', () async {
    final ok = await repository().send(
      const FeedbackEntry.free(type: FeedbackType.praise, text: '   '),
    );
    expect(ok, isFalse);
    expect(store.feedback, isEmpty);
  });

  test('sem rede, o envio não trava a tela (fica na fila local)', () async {
    store.offline = true;
    final ok = await repository().send(
      const FeedbackEntry.free(type: FeedbackType.problem, text: 'Travou'),
    );
    expect(ok, isTrue);
  });

  test('gap 5: o servidor recusou, o envio falha (a tela avisa)', () async {
    store.refuseFeedback = true;
    await expectLater(
      repository().send(
        const FeedbackEntry.free(type: FeedbackType.problem, text: 'Travou'),
      ),
      throwsA(isA<CloudStoreException>()),
    );
  });
}
