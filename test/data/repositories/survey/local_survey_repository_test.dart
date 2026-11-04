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
      kind: SurveyKind.pilares,
      step: 1,
      answers: SurveyAnswers(rating: 4, improve: {'voice'}),
    );
    expect(await reopen().loadDraft(SurveyKind.pilares), isNull);
    await reopen().saveDraft(draft);
    final back = await reopen().loadDraft(SurveyKind.pilares);
    expect(back?.step, 1);
    expect(back?.answers, draft.answers);
  });

  test('a resposta usa o Now e apaga o rascunho', () async {
    final repository = reopen();
    await repository.saveDraft(
      const SurveyDraft(
        kind: SurveyKind.pilares,
        step: 1,
        answers: SurveyAnswers(rating: 3),
      ),
    );
    final saved = await repository.saveResponse(
      SurveyKind.pilares,
      const SurveyAnswers(rating: 3, wishText: '  oi  '),
    );
    expect(saved.answeredAt, DateTime.utc(2026, 3, 4, 10));
    expect(saved.answers.wishText, 'oi');
    expect(await reopen().loadDraft(SurveyKind.pilares), isNull);
    final back = await reopen().loadResponse(SurveyKind.pilares);
    expect(back?.answeredAt, saved.answeredAt);
    expect(back?.answers.rating, 3);
  });

  test('finais e Escola são independentes', () async {
    await reopen().saveResponse(
      SurveyKind.school,
      const SurveyAnswers(rating: 5),
    );
    expect(await reopen().loadResponse(SurveyKind.pilares), isNull);
    expect(await reopen().loadResponse(SurveyKind.school), isNotNull);
  });

  test('JSON estragado vale como se não existisse', () async {
    final preferences = PreferencesService();
    await preferences.setString(
      LocalSurveyRepository.draftKey(SurveyKind.pilares),
      '{não é json',
    );
    await preferences.setString(
      LocalSurveyRepository.responseKey(SurveyKind.pilares),
      '[1, 2]',
    );
    expect(await reopen().loadDraft(SurveyKind.pilares), isNull);
    expect(await reopen().loadResponse(SurveyKind.pilares), isNull);
  });

  test('o JSON da resposta leva v, kind, answers e answeredAt', () async {
    await reopen().saveResponse(
      SurveyKind.pilares,
      const SurveyAnswers(rating: 2),
    );
    final raw = await PreferencesService().getString(
      LocalSurveyRepository.responseKey(SurveyKind.pilares),
    );
    expect(raw, allOf(contains('"v":1'), contains('"kind":"pilares"')));
    expect(raw, allOf(contains('"answers"'), contains('"answeredAt"')));
  });

  test('quem respondeu antes da T85 (chave endgames) não vê o convite de '
      'novo e retoma o rascunho', () async {
    final preferences = PreferencesService();
    await preferences.setString(
      'survey.v1.endgames.response',
      '{"v":1,"kind":"endgames","answers":{"rating":4},'
          '"answeredAt":"2026-01-02T10:00:00.000Z"}',
    );
    await preferences.setString(
      'survey.v1.endgames.draft',
      '{"v":1,"kind":"endgames","step":1,"answers":{"rating":3}}',
    );
    final response = await reopen().loadResponse(SurveyKind.pilares);
    expect(response?.answers.rating, 4);
    final draft = await reopen().loadDraft(SurveyKind.pilares);
    expect(draft?.step, 1);
    expect(await reopen().loadResponse(SurveyKind.school), isNull);

    // Enviar de novo grava na chave nova e apaga o rascunho antigo.
    await reopen().saveResponse(
      SurveyKind.pilares,
      const SurveyAnswers(rating: 5),
    );
    expect(await preferences.getString('survey.v1.endgames.draft'), isNull);
    expect(
      (await reopen().loadResponse(SurveyKind.pilares))?.answers.rating,
      5,
    );
  });
}
