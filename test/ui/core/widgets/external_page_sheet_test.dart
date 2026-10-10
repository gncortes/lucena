import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/external_page_keys.dart';
import 'package:lucena/ui/core/widgets/external_page_sheet.dart';
import 'package:lucena/ui/core/widgets/reference_link.dart';
import 'package:lucena/ui/core/widgets/sheet_close_button.dart';

import '../../../../testing/fakes/fake_wiki.dart';
import '../../../../testing/test_app.dart';

void main() {
  const game = Reference(
    id: 'g1',
    kind: 'game',
    fields: {
      'white': 'Andersson',
      'black': 'Karpov',
      'url': 'https://lichess.org/analysis/pgn/e4_e5#12',
    },
  );
  const study = Reference(
    id: 's1',
    kind: 'study',
    fields: {'title': 'Lucena', 'url': 'https://lichess.org/study/abc123'},
  );

  Future<void> pump(
    WidgetTester tester,
    FakeWebPages pages, [
    Reference reference = game,
  ]) async {
    await tester.pumpWidget(
      TestApp(
        webPages: pages,
        child: Scaffold(body: ReferenceLink(reference: reference)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('"Ver a partida no Lichess" abre dentro do app, com o título '
      'e o domínio no topo, e o X fecha', (tester) async {
    final pages = FakeWebPages(title: 'Andersson vs Karpov • lichess.org');
    await pump(tester, pages);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsOneWidget);
    expect(pages.opened, [Uri.parse(game.url!)]);
    final top = find.byKey(ExternalPageKeys.title);
    expect(
      find.descendant(
        of: top,
        matching: find.text('Andersson vs Karpov • lichess.org'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: top, matching: find.text('lichess.org')),
      findsOneWidget,
    );

    // O ✕ é o da fala do Viktor e flutua fora da folha, acima do título.
    expect(
      find.descendant(
        of: find.byKey(ExternalPageKeys.close),
        matching: find.byType(IconButton),
      ),
      findsOneWidget,
    );
    expect(find.byType(SheetCloseButton), findsOneWidget);
    expect(
      tester.getRect(find.byKey(ExternalPageKeys.close)).bottom,
      lessThan(tester.getRect(top).top),
    );

    await tester.tap(find.byKey(ExternalPageKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsNothing);
    expect(find.byType(ReferenceLink), findsOneWidget);
  });

  testWidgets('o estudo do Lichess também; sem título, só o domínio', (
    tester,
  ) async {
    final pages = FakeWebPages();
    await pump(tester, pages, study);
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(pages.opened, [Uri.parse(study.url!)]);
    expect(
      find.descendant(
        of: find.byKey(ExternalPageKeys.title),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
    expect(find.text('lichess.org'), findsOneWidget);
  });

  testWidgets('sem internet: o aviso, e o X volta para a aula', (tester) async {
    await pump(tester, FakeWebPages(online: false));
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.offline), findsOneWidget);
    expect(find.byKey(ExternalPageKeys.page), findsNothing);
    // Antes de abrir (e sem abrir), o topo mostra o domínio.
    expect(find.text('lichess.org'), findsOneWidget);
    await tester.tap(find.byKey(ExternalPageKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(ExternalPageKeys.sheet), findsNothing);
  });

  test('o domínio sem www. nem m.', () {
    expect(
      ExternalPageSheet.domainOf(Uri.parse('https://www.lichess.org/x')),
      'lichess.org',
    );
    expect(
      ExternalPageSheet.domainOf(
        Uri.parse('https://pt.m.wikipedia.org/wiki/A'),
      ),
      'pt.m.wikipedia.org',
    );
    expect(
      ExternalPageSheet.domainOf(Uri.parse('https://m.wikipedia.org/wiki/A')),
      'wikipedia.org',
    );
  });
}
