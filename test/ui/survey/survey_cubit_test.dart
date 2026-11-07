import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/ui/survey/view_models/survey_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_survey_repository.dart';

void main() {
  late FakeSurveyRepository surveys;

  SurveyCubit make(SurveyKind kind) {
    final cubit = SurveyCubit(
      kind: kind,
      surveys: surveys,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() => surveys = FakeSurveyRepository());

  test('só avança com a nota e volta um passo', () async {
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.next();
    expect(cubit.state.step, 0);
    await cubit.pickRating(4);
    await cubit.next();
    expect(cubit.state.step, 1);
    expect(cubit.state.isLast, isTrue);
    await cubit.back();
    expect(cubit.state.step, 0);
  });

  test('cada mudança grava o rascunho e outro cubit retoma no passo', () async {
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.pickRating(4);
    await cubit.toggleImprove('examples');
    await cubit.next();
    await cubit.setWishText('mais finais');
    final again = make(SurveyKind.pilares);
    await again.load();
    expect(again.state.step, 1);
    expect(again.state.answers.rating, 4);
    expect(again.state.answers.improve, {'examples'});
    expect(again.state.answers.wishText, 'mais finais');
  });

  test('o chip marca e desmarca', () async {
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.toggleImprove('voice');
    await cubit.toggleImprove('voice');
    expect(cubit.state.answers.improve, isEmpty);
  });

  test('o texto passa de 500 e é cortado', () async {
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.setWishText('x' * 700);
    expect(cubit.state.answers.wishText, hasLength(500));
  });

  test('Pilares: o passo 2 não pede interesse e grava uma vez só', () async {
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.pickRating(5);
    await cubit.next();
    await cubit.send();
    await cubit.send();
    expect(surveys.saves, 1);
    expect(cubit.state.sent, isTrue);
    expect(surveys.drafts, isEmpty);
    expect(surveys.responses[SurveyKind.pilares]?.answers.rating, 5);
  });

  test('gap 2: falha ao gravar conta o erro, mantém as respostas e deixa '
      'tentar de novo', () async {
    surveys.failSave = true;
    final cubit = make(SurveyKind.pilares);
    await cubit.load();
    await cubit.pickRating(2);
    await cubit.next();
    await cubit.setWishText('mais finais');
    await cubit.send();
    expect(cubit.state.sent, isFalse);
    expect(cubit.state.sending, isFalse);
    expect(cubit.state.sendErrors, 1);
    expect(cubit.state.answers.wishText, 'mais finais');
    expect(surveys.drafts[SurveyKind.pilares]?.answers.wishText, 'mais finais');

    surveys.failSave = false;
    await cubit.send();
    expect(cubit.state.sent, isTrue);
    expect(surveys.saves, 1);
  });

  test('na Escola o passo 3 envia sem exigir nada', () async {
    final cubit = make(SurveyKind.school);
    await cubit.load();
    await cubit.pickRating(2);
    await cubit.next();
    await cubit.pickInterest(SurveyInterest.no);
    await cubit.next();
    expect(cubit.state.step, 2);
    await cubit.send();
    expect(cubit.state.sent, isTrue);
    expect(surveys.responses[SurveyKind.school], isNotNull);
    expect(surveys.responses[SurveyKind.pilares], isNull);
  });
}
