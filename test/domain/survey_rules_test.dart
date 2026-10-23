import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/domain/use_cases/survey_rules.dart';

void main() {
  test('finais tem 2 passos e a Escola 3', () {
    expect(SurveyRules.totalSteps(SurveyKind.endgames), 2);
    expect(SurveyRules.totalSteps(SurveyKind.school), 3);
  });

  test('o passo 1 exige a nota e o 2 exige o interesse; o resto é livre', () {
    const empty = SurveyAnswers();
    expect(SurveyRules.canAdvance(SurveyKind.endgames, 0, empty), isFalse);
    expect(
      SurveyRules.canAdvance(
        SurveyKind.endgames,
        0,
        const SurveyAnswers(rating: 4),
      ),
      isTrue,
    );
    expect(SurveyRules.canAdvance(SurveyKind.endgames, 1, empty), isFalse);
    expect(
      SurveyRules.canAdvance(
        SurveyKind.school,
        1,
        const SurveyAnswers(interest: SurveyInterest.maybe),
      ),
      isTrue,
    );
    // Passo 3 da Escola: "Enviar" sempre habilitado.
    expect(SurveyRules.canAdvance(SurveyKind.school, 2, empty), isTrue);
  });

  test('o convite some com a resposta enviada', () {
    expect(SurveyRules.shouldInvite(hasResponse: false), isTrue);
    expect(SurveyRules.shouldInvite(hasResponse: true), isFalse);
  });

  test('as respostas vão e voltam em JSON', () {
    const answers = SurveyAnswers(
      rating: 5,
      improve: {'voice', 'examples'},
      improveText: 'mais exemplos',
      interest: SurveyInterest.yes,
      reReview: false,
      wishText: 'um final',
      topics: {'tactics'},
      difficulties: {'clock'},
      difficultyText: 'travo no relógio',
    );
    expect(SurveyAnswers.fromJson(answers.toJson()), answers);
    final draft = SurveyDraft(
      kind: SurveyKind.school,
      step: 2,
      answers: answers,
    );
    final back = SurveyDraft.fromJson(draft.toJson());
    expect(back.kind, SurveyKind.school);
    expect(back.step, 2);
    expect(back.answers, answers);
    expect(
      SurveyResponse.fromJson(
        SurveyResponse(
          kind: SurveyKind.endgames,
          answers: answers,
          answeredAt: DateTime.utc(2026, 1, 2),
        ).toJson(),
      ).answeredAt,
      DateTime.utc(2026, 1, 2),
    );
  });

  test('texto livre: corta em 500, tira os espaços e vazio vira nulo', () {
    final long = SurveyAnswers(improveText: 'a' * 600).cleaned;
    expect(long.improveText, hasLength(SurveyAnswers.maxText));
    expect(
      const SurveyAnswers(improveText: '  oi  ').cleaned.improveText,
      'oi',
    );
    final blank = const SurveyAnswers(wishText: '   ').cleaned;
    expect(blank.wishText, isNull);
    expect(blank.toJson().containsKey('wishText'), isFalse);
  });
}
