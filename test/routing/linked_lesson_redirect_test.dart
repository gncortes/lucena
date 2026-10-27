import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/campaign/campaign_repository.dart';
import 'package:lucena/data/repositories/campaign/linked_lesson_catalog.dart';
import 'package:lucena/domain/models/linked_lesson.dart';
import 'package:lucena/routing/linked_lesson_redirect.dart';
import 'package:lucena/routing/routes.dart';

import '../../testing/fakes/fake_analytics_repository.dart';

class _Catalog implements LinkedLessonCatalog {
  @override
  Future<LinkedLessonInfo?> info(LinkedLesson lesson, String language) async =>
      null;

  _Catalog(this.value);

  final bool value;

  @override
  Future<bool> available(LinkedLesson lesson) async => value;
}

void main() {
  const lesson = LinkedLesson(LinkedLessonKind.endgame, 'rook.lucena');

  Future<(String?, FakeAnalyticsRepository)> run({
    required bool available,
    required bool hasAccount,
  }) async {
    final analytics = FakeAnalyticsRepository();
    final target = await linkedLessonRedirect(
      lesson,
      hasAccount: hasAccount,
      catalog: _Catalog(available),
      campaigns: MemoryCampaignRepository(),
      analytics: analytics,
    );
    await Future<void>.delayed(Duration.zero);
    return (target, analytics);
  }

  test(
    'sem conta, a aula que abre fica na rota (convite), sem aula_aberta',
    () async {
      final (target, analytics) = await run(available: true, hasAccount: false);
      expect(target, isNull);
      expect(analytics.eventsNamed('campanha_aula_aberta'), isEmpty);
    },
  );

  test('com conta, vai à aula e registra aula_aberta', () async {
    final (target, analytics) = await run(available: true, hasAccount: true);
    expect(target, Routes.linkedLesson(lesson));
    expect(analytics.eventsNamed('campanha_aula_aberta'), hasLength(1));
  });

  test('aula que não abre: a regra de sempre, com aula_indisponivel', () async {
    final (target, analytics) = await run(available: false, hasAccount: false);
    expect(target, Routes.linkedLesson(lesson, available: false));
    expect(analytics.eventsNamed('aula_indisponivel'), hasLength(1));
    expect(analytics.eventsNamed('campanha_aula_aberta'), isEmpty);
  });
}
