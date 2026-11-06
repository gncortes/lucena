import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/feedback_entry.dart';
import 'package:lucena/routing/route_names.dart';
import 'package:lucena/ui/core/keys/feedback_keys.dart';
import 'package:lucena/ui/feedback/view_models/feedback_cubit.dart';
import 'package:lucena/ui/feedback/widgets/feedback_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_feedback_repositories.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeFeedbackRepository feedback;
  late FakeFeedbackDraftRepository drafts;

  setUp(() {
    feedback = FakeFeedbackRepository();
    drafts = FakeFeedbackDraftRepository();
  });

  /// O Perfil (`/`), o formulário e o "Feedback enviado" num roteador
  /// mínimo, com os mesmos nomes de rota do app.
  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 917)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/feedback',
      routes: [
        GoRoute(
          path: '/conta',
          builder: (_, state) =>
              Text('Conta de ${state.uri.queryParameters['from']}'),
        ),
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Perfil')),
          routes: [
            GoRoute(
              name: RouteNames.feedback,
              path: 'feedback',
              builder: (_, _) => BlocProvider(
                create: (_) => FeedbackCubit(
                  feedback: feedback,
                  drafts: drafts,
                  characters: FakeCharacterRepository(),
                  language: 'pt',
                )..load(),
                child: const FeedbackScreen(),
              ),
            ),
            GoRoute(
              name: RouteNames.feedbackSent,
              path: 'sent',
              builder: (_, _) => const Text('Feedback enviado'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    // Abre por cima do Perfil, como no app.
    router
      ..go('/')
      ..pushNamed(RouteNames.feedback);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String text) async {
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.problem)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FeedbackKeys.text), text);
    await tester.pumpAndSettle();
  }

  bool canSend(WidgetTester tester) =>
      tester
          .widget<ButtonStyleButton>(find.byKey(FeedbackKeys.send))
          .onPressed !=
      null;

  testWidgets('Enviar só com assunto e texto; depois o agradecimento', (
    tester,
  ) async {
    await pump(tester);
    expect(canSend(tester), isFalse);
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.problem)));
    await tester.pumpAndSettle();
    expect(canSend(tester), isFalse);
    await tester.enterText(find.byKey(FeedbackKeys.text), '   ');
    await tester.pumpAndSettle();
    expect(canSend(tester), isFalse);
    await tester.enterText(find.byKey(FeedbackKeys.text), 'O som some');
    await tester.pumpAndSettle();
    expect(find.text('10/500'), findsOneWidget);
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();

    final sent = feedback.sent.single;
    expect(sent.type, FeedbackType.problem);
    expect(sent.text, 'O som some');
    expect(sent.language, 'pt');
    // H-OPI-12: o agradecimento abre no lugar do formulário.
    expect(find.text('Feedback enviado'), findsOneWidget);
    expect(find.byKey(FeedbackKeys.screen), findsNothing);
  });

  testWidgets('os textos do canvas (H-OPI-11)', (tester) async {
    await pump(tester);
    expect(find.text('Lemos tudo. Conte o que está acontecendo.'), findsOne);
    expect(find.text('Até 500 caracteres.'), findsOne);
    expect(
      find.text(
        'Vão junto, sem identificar você: a versão do app e o modelo do '
        'celular, para acharmos o problema mais rápido.',
      ),
      findsOne,
    );
  });

  testWidgets('gap 3: o rascunho volta depois de fechar o app', (tester) async {
    await pump(tester);
    await fill(tester, 'Queria ver o relógio maior');
    expect(drafts.draft?.type, FeedbackType.problem);
    expect(drafts.draft?.text, 'Queria ver o relógio maior');

    // Reabre do zero (app fechado à força): o rascunho volta.
    await tester.pumpWidget(const SizedBox());
    await pump(tester);
    expect(find.text('Queria ver o relógio maior'), findsOneWidget);
    final chip = tester.widget<FilterChip>(
      find.byKey(FeedbackKeys.kindChip(FeedbackType.problem)),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('enviar apaga o rascunho', (tester) async {
    await pump(tester);
    await fill(tester, 'O som some');
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();
    expect(drafts.draft, isNull);
  });

  testWidgets('gap 2 e 5: falha no envio avisa, mantém o texto e deixa '
      'tentar de novo', (tester) async {
    feedback.fail = true;
    await pump(tester);
    await fill(tester, 'O som some');
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();

    expect(find.byKey(FeedbackKeys.sendError), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.text('O som some'), findsOneWidget);
    expect(canSend(tester), isTrue);
    expect(drafts.draft?.text, 'O som some');

    feedback.fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(feedback.sent.single.text, 'O som some');
    expect(find.text('Feedback enviado'), findsOneWidget);
  });

  testWidgets('abuso: sem conta, o aviso oferece Entrar e mantém o texto', (
    tester,
  ) async {
    feedback.needsAccount = true;
    await pump(tester);
    await fill(tester, 'Mais finais');
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();

    expect(find.byKey(FeedbackKeys.needsAccount), findsOneWidget);
    expect(
      find.text('Entre na sua conta para enviar. O texto continua salvo.'),
      findsOneWidget,
    );
    expect(find.byKey(FeedbackKeys.sendError), findsNothing);
    expect(feedback.sent, isEmpty);
    expect(drafts.draft?.text, 'Mais finais');

    await tester.tap(find.byKey(FeedbackKeys.needsAccountSignIn));
    await tester.pumpAndSettle();
    expect(find.text('Conta de /settings/feedback'), findsOneWidget);
  });

  testWidgets('o texto para em 500 letras', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(FeedbackKeys.text), 'a' * 600);
    await tester.pumpAndSettle();
    expect(find.byKey(FeedbackKeys.counter), findsOneWidget);
    expect(find.text('500/500'), findsOneWidget);
  });

  testWidgets('um assunto por vez', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.idea)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeedbackKeys.kindChip(FeedbackType.praise)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(FeedbackKeys.text), 'Gostei');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(FeedbackKeys.send));
    await tester.pumpAndSettle();
    expect(feedback.sent.single.type, FeedbackType.praise);
  });
}
