import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/ui/core/keys/survey_keys.dart';
import 'package:lucena/ui/core/widgets/app_bar_progress.dart';
import 'package:lucena/ui/survey/view_models/survey_cubit.dart';
import 'package:lucena/ui/survey/view_models/viktor_thanks_cubit.dart';
import 'package:lucena/ui/survey/widgets/survey_face.dart';
import 'package:lucena/ui/survey/widgets/survey_screen.dart';
import 'package:lucena/ui/survey/widgets/survey_thanks_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_survey_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeSurveyRepository surveys;
  late GoRouter router;

  /// A tela de origem (`/`, a lição concluída), a pesquisa por cima e o
  /// agradecimento com os nomes de rota do app.
  Future<void> pump(WidgetTester tester, SurveyKind kind) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Lição concluída')),
        ),
        GoRoute(
          name: RouteNames.survey,
          path: '/survey/:kind',
          builder: (_, state) => BlocProvider(
            create: (_) => SurveyCubit(
              kind: SurveyKind.byCode(state.pathParameters['kind']!)!,
              surveys: surveys,
              characters: FakeCharacterRepository(),
            )..load(),
            child: const SurveyScreen(),
          ),
        ),
        GoRoute(
          name: RouteNames.surveyThanks,
          path: '/survey/:kind/thanks',
          builder: (_, state) => BlocProvider(
            create: (_) =>
                ViktorThanksCubit(characters: FakeCharacterRepository())
                  ..load(),
            child: SurveyThanksScreen(
              kind: SurveyKind.byCode(state.pathParameters['kind']!)!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/survey/${kind.code}');
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

  testWidgets('regra da app bar: no carregando, o mesmo título e o X '
      '(desabilitado) do passo 1, sem subtítulo', (tester) async {
    final cubit = SurveyCubit(
      kind: SurveyKind.pilares,
      surveys: surveys,
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        surveyRepository: surveys,
        child: BlocProvider.value(value: cubit, child: const SurveyScreen()),
      ),
    );
    await tester.pump();
    final appBar = find.byType(AppBar);
    expect(appBar, findsOneWidget);
    expect(
      find.descendant(of: appBar, matching: find.text('Sua opinião')),
      findsOneWidget,
    );
    final close = tester.widget<IconButton>(find.byKey(SurveyKeys.close));
    expect(close.onPressed, isNull);
    expect(tester.getSize(appBar).height, 64);
  });

  testWidgets('os rostos desenham em 36 x 36 dentro do círculo de 52', (
    tester,
  ) async {
    await pump(tester, SurveyKind.pilares);
    // Regra da app bar: 64 com a barra de progresso dentro.
    expect(tester.getSize(find.byType(AppBar)).height, 64);
    for (var n = 1; n <= 5; n++) {
      final face = find.descendant(
        of: find.byKey(SurveyKeys.face(n)),
        matching: find.byType(SurveyFace),
      );
      expect(tester.getSize(face), const Size.square(36));
    }
    expect(tester.getSize(find.byKey(SurveyKeys.face(1))).width, 52);
  });

  testWidgets('Pilares passo 1 (H-OPI-03): textos, sem "1 de 2", Continuar '
      'só com um rosto', (tester) async {
    await pump(tester, SurveyKind.pilares);
    expect(find.text('Sua opinião'), findsOneWidget);
    expect(find.text('1 de 2'), findsNothing);
    expect(_step(tester), 1 / 2);
    expect(
      find.text('O que você achou das lições do Pilares?'),
      findsOneWidget,
    );
    expect(find.text('O que poderia melhorar?'), findsOneWidget);
    expect(find.text('Marque quantos quiser.'), findsOneWidget);
    expect(find.text('Conte com suas palavras (opcional)'), findsOneWidget);
    expect(find.text('Setas e marcas no tabuleiro'), findsOneWidget);
    expect(find.text('Coordenadas e notação'), findsNothing);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(enabled(tester, SurveyKeys.next), isFalse);
    await tap(tester, SurveyKeys.face(4));
    expect(find.text('Gostei'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.next), isTrue);
  });

  testWidgets('Pilares passo 2 (H-OPI-04): sem a pergunta de interesse, '
      'revisão com "Sim" marcado e Enviar ligado', (tester) async {
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(3));
    await tap(tester, SurveyKeys.next);
    expect(_step(tester), 2 / 2);
    expect(find.byKey(SurveyKeys.interest(SurveyInterest.yes)), findsNothing);
    expect(
      find.text(
        'Quando revisarmos uma lição com as sugestões, quer rever e dar sua '
        'opinião novamente?',
      ),
      findsOneWidget,
    );
    expect(find.text('O que mais você gostaria de ver?'), findsOneWidget);
    final segmented = tester.widget<SegmentedButton<bool>>(
      find.byType(SegmentedButton<bool>),
    );
    expect(segmented.selected, {true});
    expect(enabled(tester, SurveyKeys.send), isTrue);
  });

  testWidgets('X no passo 2 volta ao passo 1; X no passo 1 sai e o rascunho '
      'fica (gap D)', (tester) async {
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(4));
    await tap(tester, SurveyKeys.next);
    expect(_step(tester), 2 / 2);
    await tap(tester, SurveyKeys.close);
    expect(_step(tester), 1 / 2);
    expect(find.text('Gostei'), findsOneWidget);
    await tap(tester, SurveyKeys.close);
    expect(find.text('Lição concluída'), findsOneWidget);
    expect(surveys.drafts[SurveyKind.pilares]?.answers.rating, 4);
  });

  testWidgets('voltar do sistema no passo 2 volta um passo', (tester) async {
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(4));
    await tap(tester, SurveyKeys.next);
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.screen), findsOneWidget);
    expect(_step(tester), 1 / 2);
  });

  testWidgets('o rascunho volta: passo, nota e texto', (tester) async {
    surveys.drafts[SurveyKind.pilares] = const SurveyDraft(
      kind: SurveyKind.pilares,
      step: 1,
      answers: SurveyAnswers(rating: 4, wishText: 'um final de peões'),
    );
    await pump(tester, SurveyKind.pilares);
    expect(_step(tester), 2 / 2);
    expect(find.text('um final de peões'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.send), isTrue);
    await tap(tester, SurveyKeys.close);
    expect(_step(tester), 1 / 2);
    expect(find.text('Gostei'), findsOneWidget);
  });

  testWidgets('o texto livre para em 500 caracteres', (tester) async {
    await pump(tester, SurveyKind.pilares);
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
      surveys.drafts[SurveyKind.pilares]?.answers.improveText,
      hasLength(500),
    );
  });

  testWidgets('enviar grava e abre o agradecimento (H-OPI-05); voltar chega '
      'à origem (gap 8)', (tester) async {
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(5));
    await tap(tester, SurveyKeys.improveChip('examples'));
    await tap(tester, SurveyKeys.next);
    await tap(tester, SurveyKeys.send);
    expect(find.byKey(SurveyKeys.thanks), findsOneWidget);
    expect(
      find.text('Obrigado pela sua opinião. Ela ajuda a melhorar o Lucena.'),
      findsOneWidget,
    );
    expect(find.text('Voltar ao Pilares'), findsOneWidget);
    final saved = surveys.responses[SurveyKind.pilares]!;
    expect(saved.answers.rating, 5);
    expect(saved.answers.improve, {'examples'});
    expect(surveys.saves, 1);
    expect(surveys.drafts, isEmpty);

    // Voltar do sistema: a pesquisa saiu da pilha, chega à lição concluída.
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Lição concluída'), findsOneWidget);
  });

  testWidgets('o botão do agradecimento também volta à origem', (tester) async {
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(5));
    await tap(tester, SurveyKeys.next);
    await tap(tester, SurveyKeys.send);
    await tap(tester, SurveyKeys.thanksBack);
    expect(find.text('Lição concluída'), findsOneWidget);
  });

  testWidgets('gap 2: falha ao gravar avisa, mantém as respostas e deixa '
      'tentar de novo', (tester) async {
    surveys.failSave = true;
    await pump(tester, SurveyKind.pilares);
    await tap(tester, SurveyKeys.face(2));
    await tap(tester, SurveyKeys.next);
    await tester.enterText(find.byKey(SurveyKeys.wishText), 'mais finais');
    await tester.pumpAndSettle();
    await tap(tester, SurveyKeys.send);
    expect(find.byKey(SurveyKeys.sendError), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.byKey(SurveyKeys.thanks), findsNothing);
    expect(find.text('mais finais'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.send), isTrue);

    surveys.failSave = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.byKey(SurveyKeys.thanks), findsOneWidget);
    expect(surveys.saves, 1);
  });

  testWidgets('Escola: 3 passos, interesse obrigatório, Enviar sempre ativo '
      '(H-OPI-06 a 09)', (tester) async {
    await pump(tester, SurveyKind.school);
    expect(_step(tester), 1 / 3);
    expect(find.text('O que você achou das lições da Escola?'), findsOneWidget);
    expect(find.text('Coordenadas e notação'), findsOneWidget);
    expect(find.text('Setas e marcas no tabuleiro'), findsNothing);
    await tap(tester, SurveyKeys.face(2));
    await tap(tester, SurveyKeys.next);
    expect(_step(tester), 2 / 3);
    expect(
      find.text(
        'Se lançarmos um curso para você continuar evoluindo, você teria '
        'interesse?',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Com os finais no centro, além de aberturas, tática e como pensar a '
        'partida.',
      ),
      findsOneWidget,
    );
    expect(find.text('O que você gostaria de aprender nele?'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.next), isFalse);
    await tap(tester, SurveyKeys.interest(SurveyInterest.maybe));
    await tap(tester, SurveyKeys.topicChip('tactics'));
    await tap(tester, SurveyKeys.next);
    expect(_step(tester), 3 / 3);
    expect(
      find.text('Onde você sente mais dificuldade nas suas partidas?'),
      findsOneWidget,
    );
    expect(find.text('Relógio e nervosismo'), findsOneWidget);
    expect(enabled(tester, SurveyKeys.send), isTrue);
    await tap(tester, SurveyKeys.send);
    expect(find.text('Voltar à Escola'), findsOneWidget);
    expect(surveys.responses[SurveyKind.school]?.answers.topics, {'tactics'});
  });
}

/// O passo da pesquisa na barra de progresso (a app bar leva só o título).
double _step(WidgetTester tester) =>
    tester.widget<AppBarProgress>(find.byType(AppBarProgress)).value;
