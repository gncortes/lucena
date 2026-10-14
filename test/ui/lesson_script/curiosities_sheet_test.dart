import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson_script.dart';
import 'package:lucena/ui/core/keys/curiosities_keys.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/lesson_script/widgets/curiosities_sheet.dart';

import '../../../testing/fakes/fake_wiki.dart';
import '../../../testing/test_app.dart';

void main() {
  const texts = ScriptTexts({
    'cur.t': 'Texto sobre a posição.',
    'cur.cit': 'Uma citação inesquecível.',
  });
  const lessonRefs = [
    Reference(
      id: 'opposition',
      kind: 'web',
      fields: {
        'title': 'Oposição (xadrez)',
        'url': 'https://en.wikipedia.org/wiki/Opposition_(chess)',
      },
    ),
  ];
  const full = Curiosities(
    t: 'cur.t',
    quote: 'cur.cit',
    quoteAuthor: 'Fulano',
    references: [
      CuriosityRef(id: 'opposition'),
      CuriosityRef(
        inline: Reference(
          id: 'g',
          kind: 'game',
          fields: {
            'white': 'Branco',
            'black': 'Preto',
            'event': 'Torneio',
            'year': '1900',
            'url': 'https://lichess.org/AAAAAAAA',
          },
        ),
      ),
      CuriosityRef(
        inline: Reference(
          id: 'st',
          kind: 'study',
          fields: {
            'author': 'lichess',
            'title': 'Estudo',
            'url': 'https://lichess.org/study/AAAAAAAA',
          },
        ),
      ),
      CuriosityRef(
        inline: Reference(
          id: 'bk',
          kind: 'book',
          fields: {
            'author': 'Autor',
            'title': 'Livro',
            'publisher': 'Editora',
            'year': '1900',
          },
        ),
      ),
      CuriosityRef(
        inline: Reference(
          id: 'pl',
          kind: 'player',
          fields: {
            'name': 'José Capablanca',
            'initials': 'JC',
            'dates': '1888–1942',
            'url':
                'https://en.wikipedia.org/wiki/Jos%C3%A9_Ra%C3%BAl_Capablanca',
          },
        ),
      ),
    ],
  );

  Future<FakeWebPages> open(
    WidgetTester tester,
    Curiosities curiosities, {
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final pages = FakeWebPages(title: 'Página');
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        webPages: pages,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showCuriositiesSheet(
                  context,
                  curiosities,
                  texts: texts,
                  lessonRefs: lessonRefs,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return pages;
  }

  testWidgets('mostra título, texto, citação e referências', (tester) async {
    await open(tester, full);
    expect(find.byKey(CuriositiesKeys.sheet), findsOneWidget);
    expect(find.text('Curiosidades'), findsOneWidget);
    expect(find.text('Sobre a posição'), findsOneWidget);
    expect(find.text('Texto sobre a posição.'), findsOneWidget);
    expect(find.text('Uma citação inesquecível.'), findsOneWidget);
    expect(find.text('— Fulano'), findsOneWidget);
    expect(find.text('Referências'), findsOneWidget);
    // Rola até o fim: o jogador mostra as iniciais, o nome e as datas.
    await tester.scrollUntilVisible(
      find.byKey(CuriositiesKeys.playerAvatar('pl')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('JC'), findsOneWidget);
    expect(find.text('José Capablanca'), findsOneWidget);
    expect(find.text('1888–1942'), findsOneWidget);
    expect(find.text('Autor. Livro. Editora, 1900.'), findsOneWidget);
  });

  testWidgets('toque na referência abre a página dentro do app', (
    tester,
  ) async {
    final pages = await open(tester, full);
    await tester.scrollUntilVisible(
      find.byKey(CuriositiesKeys.reference('pl')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(CuriositiesKeys.reference('pl')));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsOneWidget);
    expect(pages.opened, [
      Uri.parse('https://en.wikipedia.org/wiki/Jos%C3%A9_Ra%C3%BAl_Capablanca'),
    ]);
  });

  testWidgets('referência sem link não abre nada', (tester) async {
    final pages = await open(tester, full);
    await tester.scrollUntilVisible(
      find.byKey(CuriositiesKeys.reference('bk')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(CuriositiesKeys.reference('bk')));
    await tester.pumpAndSettle();
    expect(pages.opened, isEmpty);
    expect(find.byKey(CuriositiesKeys.source('bk')), findsNothing);
  });

  testWidgets('sem citação nem referências só mostra o texto', (tester) async {
    await open(tester, const Curiosities(t: 'cur.t'));
    expect(find.byKey(CuriositiesKeys.about), findsOneWidget);
    expect(find.byKey(CuriositiesKeys.quote), findsNothing);
    expect(find.byKey(CuriositiesKeys.references), findsNothing);
    expect(find.text('Referências'), findsNothing);
  });

  testWidgets('o X fecha a folha', (tester) async {
    await open(tester, full);
    await tester.tap(find.byKey(CuriositiesKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(CuriositiesKeys.sheet), findsNothing);
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets('sem overflow, rola e alvos de 48 dp em $size', (tester) async {
      await open(tester, full, size: size);
      expect(tester.takeException(), isNull);
      final sheet = tester.getRect(find.byKey(CuriositiesKeys.sheet));
      expect(sheet.bottom, lessThanOrEqualTo(size.height));
      expect(sheet.width, size.width);
      final close = tester.getSize(find.byKey(CuriositiesKeys.close));
      expect(close.width, greaterThanOrEqualTo(48));
      expect(close.height, greaterThanOrEqualTo(48));
      await tester.scrollUntilVisible(
        find.byKey(CuriositiesKeys.reference('pl')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      final tile = tester.getSize(find.byKey(CuriositiesKeys.reference('pl')));
      expect(tile.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}
