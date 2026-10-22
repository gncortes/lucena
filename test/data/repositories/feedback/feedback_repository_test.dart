import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/feedback/feedback_repository.dart';
import 'package:lucena/data/services/device_service.dart';
import 'package:lucena/domain/models/app_version.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/domain/models/would_pay.dart';

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

  test('o "Você pagaria?" manda só as respostas e o nível', () async {
    await repository().send(
      const FeedbackEntry.wouldPay(
        answers: WouldPayAnswers(
          course: WouldPayAnswer.yes,
          coursePrice: CoursePrice.from30To59,
          coach: WouldPayAnswer.no,
          coachPrice: MonthPrice.none,
          learn: LearnAnswer.some,
          why: {'tournament', 'learn'},
        ),
      ),
      level: '1500',
    );
    final data = store.feedback.single;
    expect(data['kind'], 'pagaria');
    expect(data.containsKey('type'), isFalse);
    expect(data.containsKey('text'), isFalse);
    expect(data['level'], '1500');
    expect(data['answers'], {
      'course': 'yes',
      'coursePrice': '30to59',
      'coach': 'no',
      'coachPrice': 'none',
      'learn': 'some',
      'why': ['learn', 'tournament'],
    });
  });
}
