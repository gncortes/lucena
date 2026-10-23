import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/survey/survey_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  final now = FakeNow(DateTime.utc(2026, 3, 4, 10));
  LocalSurveyRepository reopen() =>
      LocalSurveyRepository(PreferencesService(), now);

  test('o rascunho é gravado e relido ao reabrir', () async {
    const draft = SurveyDraft(
      kind: SurveyKind.endgames,
      step: 1,
      answers: SurveyAnswers(rating: 4, improve: {'voice'}),
    );
    expect(await reopen().loadDraft(SurveyKind.endgames), isNull);
    await reopen().saveDraft(draft);
    final back = await reopen().loadDraft(SurveyKind.endgames);
    expect(back?.step, 1);
    expect(back?.answers, draft.answers);
  });

  test('a resposta usa o Now e apaga o rascunho', () async {
    final repository = reopen();
    await repository.saveDraft(
      const SurveyDraft(
        kind: SurveyKind.endgames,
        step: 1,
        answers: SurveyAnswers(rating: 3),
      ),
    );
    final saved = await repository.saveResponse(
      SurveyKind.endgames,
      const SurveyAnswers(rating: 3, wishText: '  oi  '),
    );
    expect(saved.answeredAt, DateTime.utc(2026, 3, 4, 10));
    expect(saved.answers.wishText, 'oi');
    expect(await reopen().loadDraft(SurveyKind.endgames), isNull);
    final back = await reopen().loadResponse(SurveyKind.endgames);
    expect(back?.answeredAt, saved.answeredAt);
    expect(back?.answers.rating, 3);
  });

  test('finais e Escola são independentes', () async {
    await reopen().saveResponse(
      SurveyKind.school,
      const SurveyAnswers(rating: 5),
    );
    expect(await reopen().loadResponse(SurveyKind.endgames), isNull);
    expect(await reopen().loadResponse(SurveyKind.school), isNotNull);
  });

  test('JSON estragado vale como se não existisse', () async {
    final preferences = PreferencesService();
    await preferences.setString(
      LocalSurveyRepository.draftKey(SurveyKind.endgames),
      '{não é json',
    );
    await preferences.setString(
      LocalSurveyRepository.responseKey(SurveyKind.endgames),
      '[1, 2]',
    );
    expect(await reopen().loadDraft(SurveyKind.endgames), isNull);
    expect(await reopen().loadResponse(SurveyKind.endgames), isNull);
  });

  test('o JSON da resposta leva v, kind, answers e answeredAt', () async {
    await reopen().saveResponse(
      SurveyKind.endgames,
      const SurveyAnswers(rating: 2),
    );
    final raw = await PreferencesService().getString(
      LocalSurveyRepository.responseKey(SurveyKind.endgames),
    );
    expect(raw, allOf(contains('"v":1'), contains('"kind":"endgames"')));
    expect(raw, allOf(contains('"answers"'), contains('"answeredAt"')));
  });
}
