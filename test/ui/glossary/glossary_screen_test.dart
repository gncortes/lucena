import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/glossary_term.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/glossary_keys.dart';
import 'package:lucena/ui/core/widgets/lucena_card.dart';
import 'package:lucena/ui/glossary/view_models/glossary_cubit.dart';
import 'package:lucena/ui/glossary/widgets/glossary_screen.dart';
import 'package:lucena/ui/glossary/widgets/glossary_text.dart';

import '../../../testing/fakes/fake_glossary.dart';
import '../../../testing/fakes/fake_wiki.dart';
import '../../../testing/test_app.dart';

Finder termCard(String id) => find.byWidgetPredicate(
  (w) => w is LucenaCard && w.key == GlossaryKeys.term(id),
);

void main() {
  late FakeConnectivityRepository connectivity;
  late FakeWebPages pages;

  setUp(() {
    connectivity = FakeConnectivityRepository();
    pages = FakeWebPages(title: 'Zugzwang');
  });

  Widget screen({String query = '', String? openTermId}) => BlocProvider(
    create: (_) =>
        GlossaryCubit(FakeGlossaryRepository(), connectivity)
          ..load(query: query),
    child: GlossaryScreen(openTermId: openTermId),
  );

  Future<void> pump(
    WidgetTester tester, {
    String query = '',
    String? openTermId,
  }) async {
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        webPages: pages,
        child: screen(query: query, openTermId: openTermId),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a busca filtra a lista e atualiza a contagem', (tester) async {
    await pump(tester);
    expect(termCard('ponte'), findsOneWidget);
    expect(termCard('zugzwang'), findsOneWidget);

    await tester.enterText(find.byKey(GlossaryKeys.search), 'zug');
    await tester.pump();
    expect(termCard('ponte'), findsNothing);
    expect(termCard('zugzwang'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(GlossaryKeys.count)).data, '1 termo');

    await tester.tap(find.byKey(GlossaryKeys.searchClear));
    await tester.pump();
    expect(termCard('ponte'), findsOneWidget);
  });

  testWidgets('busca sem resultado mostra o vazio com o texto buscado', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byKey(GlossaryKeys.search), 'roque');
    await tester.pump();
    expect(find.byKey(GlossaryKeys.empty), findsOneWidget);
    expect(find.textContaining('roque'), findsWidgets);
    expect(termCard('ponte'), findsNothing);
  });

  testWidgets('tocar no termo abre a folha; o link abre a Wikipédia', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(termCard('zugzwang'));
    await tester.pumpAndSettle();
    expect(find.byKey(GlossaryKeys.sheet), findsOneWidget);
    expect(find.text(fakeGlossaryTerms.last.definition), findsWidgets);
    expect(find.byKey(GlossaryKeys.offline), findsNothing);

    await tester.tap(find.byKey(GlossaryKeys.wiki));
    await tester.pumpAndSettle();
    expect(find.byKey(GlossaryKeys.sheet), findsNothing);
    expect(
      pages.opened.single.toString(),
      contains('wikipedia.org/wiki/Zugzwang'),
    );
  });

  testWidgets('sem internet, a folha avisa e não oferece a Wikipédia', (
    tester,
  ) async {
    connectivity.online = false;
    await pump(tester);
    await tester.tap(termCard('zugzwang'));
    await tester.pumpAndSettle();
    expect(find.byKey(GlossaryKeys.offline), findsOneWidget);
    expect(find.byKey(GlossaryKeys.wiki), findsNothing);
  });

  testWidgets('termo sem verbete não mostra link nem aviso', (tester) async {
    await pump(tester);
    await tester.tap(termCard('ponte'));
    await tester.pumpAndSettle();
    expect(find.byKey(GlossaryKeys.sheet), findsOneWidget);
    expect(find.byKey(GlossaryKeys.wiki), findsNothing);
    expect(find.byKey(GlossaryKeys.offline), findsNothing);
  });

  testWidgets('aberta por um termo, com internet, vai direto à Wikipédia', (
    tester,
  ) async {
    await pump(tester, query: 'Zugzwang', openTermId: 'zugzwang');
    expect(pages.opened, hasLength(1));
    expect(find.byKey(GlossaryKeys.sheet), findsNothing);
  });

  testWidgets('aberta por um termo, sem internet, mostra a folha offline', (
    tester,
  ) async {
    connectivity.online = false;
    await pump(tester, query: 'Zugzwang', openTermId: 'zugzwang');
    expect(pages.opened, isEmpty);
    expect(find.byKey(GlossaryKeys.sheet), findsOneWidget);
    expect(find.byKey(GlossaryKeys.offline), findsOneWidget);
    expect(termCard('ponte'), findsNothing);
  });

  group('texto com termos', () {
    testWidgets('tocar no termo sublinhado chama onOpen com o termo', (
      tester,
    ) async {
      GlossaryTerm? opened;
      await tester.pumpWidget(
        TestApp(
          child: Scaffold(
            body: GlossaryText(
              'Agora construa a ponte.',
              terms: fakeGlossaryTerms,
              onOpen: (term) => opened = term,
            ),
          ),
        ),
      );
      await tester.tapOnText(find.textRange.ofSubstring('ponte'));
      expect(opened?.id, 'ponte');
    });

    testWidgets('sem onOpen, abre o Glossário filtrado com a folha do termo', (
      tester,
    ) async {
      connectivity.online = false;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: GlossaryText(
                'Agora construa a ponte.',
                terms: fakeGlossaryTerms,
              ),
            ),
          ),
          GoRoute(
            path: Routes.glossary,
            builder: (_, state) => screen(
              query: state.uri.queryParameters['q'] ?? '',
              openTermId: state.uri.queryParameters['term'],
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          router: router,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tapOnText(find.textRange.ofSubstring('ponte'));
      await tester.pumpAndSettle();
      expect(find.byKey(GlossaryKeys.screen), findsOneWidget);
      expect(find.byKey(GlossaryKeys.sheet), findsOneWidget);
      expect(termCard('zugzwang'), findsNothing);
    });
  });

  test('a rota leva busca e termo só quando há', () {
    expect(Routes.glossaryAt(), '/glossary');
    expect(
      Routes.glossaryAt(query: 'Ponte', term: 'ponte'),
      '/glossary?q=Ponte&term=ponte',
    );
  });
}
