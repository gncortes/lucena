import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:lucena/ui/survey/view_models/survey_cubit.dart';
import 'package:lucena/ui/survey/widgets/survey_face.dart';
import 'package:lucena/ui/survey/widgets/survey_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSurveyRepository surveys;

  Future<void> pump(WidgetTester tester, SurveyKind kind) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = SurveyCubit(
      kind: kind,
      surveys: surveys,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        child: BlocProvider.value(
          value: cubit,
          child: const SurveyScreen(fromLesson: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  setUp(() => surveys = FakeSurveyRepository());

  testWidgets('os rostos desenham em 36 x 36 dentro do círculo de 52', (
    tester,
  ) async {
    await pump(tester, SurveyKind.endgames);
    for (var n = 1; n <= 5; n++) {
      final face = find.descendant(
        of: find.byKey(SurveyKeys.face(n)),
        matching: find.byType(SurveyFace),
      );
      expect(tester.getSize(face), const Size.square(36));
    }
    expect(tester.getSize(find.byKey(SurveyKeys.face(1))).width, 52);
  });

  testWidgets('finais: 1 de 2, Continuar só com um rosto, depois 2 de 2', (
    tester,
  ) async {
    await pump(tester, SurveyKind.endgames);
    expect(find.text('Sua opinião'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('O que você achou das aulas?'), findsOneWidget);
    expect(find.text('O que poderia melhorar?'), findsOneWidget);
    expect(find.text('Marque quantos quiser.'), findsOneWidget);
    expect(find.text('Conte com suas palavras (opcional)'), findsOneWidget);
    expect(find.text('Setas e marcas no tabuleiro'), findsOneWidget);
    expect(find.text('Coordenadas e notação'), findsNothing);
    expect(enabled(tester, SurveyKeys.next), isFalse);
    await tap(tester, SurveyKeys.face(4));
    expect(find.text('Gostei'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.next), isTrue);
    await tap(tester, SurveyKeys.next);
    expect(find.text('2 de 2'), findsOneWidget);
    expect(
      find.text(
        'Se lançarmos um curso completo de finais, você teria interesse?',
      ),
      findsOneWidget,
    );
    expect(find.text('Sim, tenho interesse'), findsOneWidget);
    expect(find.text('Talvez'), findsOneWidget);
    expect(find.text('Não por enquanto'), findsOneWidget);
    expect(
      find.text('O que você gostaria que tivesse a mais?'),
      findsOneWidget,
    );
  });

  testWidgets('sem interesse o Enviar fica desabilitado e nada vem marcado', (
    tester,
  ) async {
    await pump(tester, SurveyKind.endgames);
    await tap(tester, SurveyKeys.face(3));
    await tap(tester, SurveyKeys.next);
    expect(enabled(tester, SurveyKeys.send), isFalse);
    await tap(tester, SurveyKeys.interest(SurveyInterest.maybe));
    expect(enabled(tester, SurveyKeys.send), isTrue);
  });

  testWidgets('o rascunho volta: passo, nota, chips, interesse e texto', (
    tester,
  ) async {
    surveys.drafts[SurveyKind.endgames] = const SurveyDraft(
      kind: SurveyKind.endgames,
      step: 1,
      answers: SurveyAnswers(
        rating: 4,
        interest: SurveyInterest.maybe,
        wishText: 'um final de peões',
      ),
    );
    await pump(tester, SurveyKind.endgames);
    expect(find.text('2 de 2'), findsOneWidget);
    expect(find.text('um final de peões'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.send), isTrue);
    await tap(tester, SurveyKeys.back);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('Gostei'), findsOneWidget);
  });

  testWidgets('o texto livre para em 500 caracteres', (tester) async {
    await pump(tester, SurveyKind.endgames);
    await tester.enterText(find.byKey(SurveyKeys.improveText), 'a' * 520);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(SurveyKeys.improveText))
          .controller!
          .text,
      hasLength(500),
    );
    expect(
      surveys.drafts[SurveyKind.endgames]?.answers.improveText,
      hasLength(500),
    );
  });

  testWidgets('enviar grava a resposta e mostra o agradecimento', (
    tester,
  ) async {
    await pump(tester, SurveyKind.endgames);
    await tap(tester, SurveyKeys.face(5));
    await tap(tester, SurveyKeys.improveChip('examples'));
    await tap(tester, SurveyKeys.next);
    await tap(tester, SurveyKeys.interest(SurveyInterest.yes));
    await tap(tester, SurveyKeys.send);
    expect(find.byKey(SurveyKeys.thanks), findsOneWidget);
    expect(
      find.textContaining('Muito obrigado por tirar um tempo'),
      findsOneWidget,
    );
    expect(find.text('Voltar às aulas'), findsOneWidget);
    final saved = surveys.responses[SurveyKind.endgames]!;
    expect(saved.answers.rating, 5);
    expect(saved.answers.improve, {'examples'});
    expect(surveys.saves, 1);
    expect(surveys.drafts, isEmpty);
  });

  testWidgets('Escola: 3 passos, temas e dificuldades, Enviar sempre ativo', (
    tester,
  ) async {
    await pump(tester, SurveyKind.school);
    expect(find.text('1 de 3'), findsOneWidget);
    expect(find.text('O que você achou das aulas da Escola?'), findsOneWidget);
    expect(find.text('Coordenadas e notação'), findsOneWidget);
    expect(find.text('Setas e marcas no tabuleiro'), findsNothing);
    await tap(tester, SurveyKeys.face(2));
    await tap(tester, SurveyKeys.next);
    expect(find.text('2 de 3'), findsOneWidget);
    expect(find.text('O que você gostaria de aprender nele?'), findsOneWidget);
    expect(find.text('Preparação para torneio'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.next), isFalse);
    await tap(tester, SurveyKeys.interest(SurveyInterest.yes));
    await tap(tester, SurveyKeys.topicChip('tactics'));
    await tap(tester, SurveyKeys.next);
    expect(find.text('3 de 3'), findsOneWidget);
    expect(
      find.text('Onde você sente mais dificuldade nas suas partidas?'),
      findsOneWidget,
    );
    expect(find.text('Relógio e nervosismo'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.send), isTrue);
    await tap(tester, SurveyKeys.send);
    expect(find.text('Voltar à escola'), findsOneWidget);
    expect(surveys.responses[SurveyKind.school]?.answers.topics, {'tactics'});
  });
}
