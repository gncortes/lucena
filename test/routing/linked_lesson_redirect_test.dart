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

  test('normal content requires account and preserves exact destination after login', () async {
    for (final path in [
      '/school/mates.queen/roteiro?etapa=2',
      '/endgames/rook.lucena/roteiro?part=ponte&etapa=1',
      '/endgames/rook.lucena/ex/e01',
    ]) {
      final target = Uri.parse(path);
      final entry = lessonAccountRedirect(
        target,
        required: true,
        hasAccount: false,
      )!;
      final gate = Uri.parse(entry);
      expect(gate.queryParameters['retorno'], path);
      expect(Routes.afterAccount(entry), entry);
      final selected = path.startsWith('/school')
          ? const LinkedLesson.school('mates.queen')
          : lesson;
      final destination = await linkedLessonRedirect(
        selected,
        hasAccount: true,
        catalog: _Catalog(true),
        campaigns: MemoryCampaignRepository(),
        analytics: FakeAnalyticsRepository(),
        returnTo: gate.queryParameters['retorno'],
      );
      expect(destination, path);
      expect(
        lessonAccountRedirect(target, required: true, hasAccount: true),
        isNull,
      );
      expect(
        lessonAccountRedirect(target, required: false, hasAccount: false),
        isNull,
      );
    }
    for (final path in [
      '/endgames',
      '/school',
      '/endgames/challenges',
      '/endgames/challenges/rook/1',
      '/home',
    ]) {
      expect(
        lessonAccountRedirect(
          Uri.parse(path),
          required: true,
          hasAccount: false,
        ),
        isNull,
      );
    }
  });

  test(
    'normal return cannot open external locations or another unit',
    () async {
      for (final path in [
        'https://example.com/endgames/rook.lucena',
        '//example.com/endgames/rook.lucena',
        '/endgames/other',
        '/school/rook.lucena/roteiro',
        'endgames/rook.lucena',
      ]) {
        expect(lessonReturnDestination(lesson, path), isNull);
      }
      final analytics = FakeAnalyticsRepository();
      final campaigns = MemoryCampaignRepository();
      await linkedLessonRedirect(
        lesson,
        hasAccount: true,
        catalog: _Catalog(true),
        campaigns: campaigns,
        analytics: analytics,
        returnTo: '/endgames/rook.lucena/intro',
      );
      expect(analytics.events, isEmpty);
      expect(await campaigns.active(), isNull);
    },
  );

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
