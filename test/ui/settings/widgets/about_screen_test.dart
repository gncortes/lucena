import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/legal_keys.dart';
import 'package:lucena/ui/core/keys/settings_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/settings/widgets/about_screen.dart';

import '../../../../testing/fakes/fake_link_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeLinkRepository links;

  Future<void> pumpAbout(
    WidgetTester tester, {
    String version = '1.2.3',
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt', 'BR'),
        linkRepository: links,
        child: AboutScreen(version: version),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => links = FakeLinkRepository());

  group('H-AJU-13 · Sobre o Lucena', () {
    testWidgets('as 6 linhas na ordem, com os subtítulos e a versão', (
      tester,
    ) async {
      await pumpAbout(tester);

      final rows = [
        SettingsKeys.aboutWebsite,
        SettingsKeys.aboutSource,
        SettingsKeys.aboutLicenses,
        SettingsKeys.aboutPrivacy,
        SettingsKeys.aboutTerms,
        SettingsKeys.tourTile,
      ];
      final tops = [
        for (final key in rows) tester.getTopLeft(find.byKey(key)).dy,
      ];
      expect(tops, [...tops]..sort());
      expect(find.text('Site do Lucena'), findsOneWidget);
      expect(find.text('Software livre, AGPL-3.0'), findsOneWidget);
      expect(find.text('Rever o tour'), findsOneWidget);
      expect(find.text('Versão 1.2.3'), findsOneWidget);
    });

    testWidgets('versão vazia: o texto da versão some', (tester) async {
      await pumpAbout(tester, version: '');
      expect(find.byKey(SettingsKeys.aboutVersion), findsNothing);
    });

    testWidgets('Site abre o endereço do idioma', (tester) async {
      await pumpAbout(tester);
      await tester.tap(find.byKey(SettingsKeys.aboutWebsite));
      await tester.pumpAndSettle();
      expect(links.opened, [AboutScreen.websiteFor('pt')]);
      expect(find.byKey(CoreKeys.linkFailure), findsNothing);
    });

    testWidgets('Gap 6: o Site não abre, então aparece o aviso', (
      tester,
    ) async {
      links.fails = true;
      await pumpAbout(tester);

      await tester.tap(find.byKey(SettingsKeys.aboutWebsite));
      await tester.pumpAndSettle();

      expect(find.byKey(CoreKeys.linkFailure), findsOneWidget);
      expect(find.text('Não foi possível abrir o link'), findsOneWidget);
    });

    testWidgets('Gap 6: o Código-fonte não abre, então aparece o aviso', (
      tester,
    ) async {
      links.fails = true;
      await pumpAbout(tester);

      await tester.tap(find.byKey(SettingsKeys.aboutSource));
      await tester.pumpAndSettle();

      expect(links.opened, [AboutScreen.source]);
      expect(find.byKey(CoreKeys.linkFailure), findsOneWidget);
    });
  });

  testWidgets('H-ANI-42 · o mascote é o ícone B2', (tester) async {
    await pumpAbout(tester);
    final imagens = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<AssetImage>()
        .map((a) => a.assetName);
    expect(imagens, contains('assets/branding/mascote.png'));
  });

  group('H-AJU-14 · folhas dos Termos e da Política', () {
    Future<void> scrollToEnd(WidgetTester tester) async {
      for (var i = 0; i < 60; i++) {
        await tester.drag(find.byKey(LegalKeys.body), const Offset(0, -600));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('Termos: folha com título, endereço, versão e 16 seções; '
        'o cabeçalho fica fixo e o ✕ volta ao Sobre', (tester) async {
      await pumpAbout(tester);
      await tester.tap(find.byKey(SettingsKeys.aboutTerms));
      await tester.pumpAndSettle();

      expect(links.opened, isEmpty, reason: 'texto embarcado, sem site');
      expect(find.byKey(LegalKeys.sheet), findsOneWidget);
      expect(find.byKey(LegalKeys.terms), findsOneWidget);
      final header = find.byKey(SheetKeys.title);
      expect(tester.widget<Text>(header).data, 'Termos de uso');
      expect(
        tester.widget<Text>(find.byKey(SheetKeys.hint)).data,
        'gncortes.github.io/lucena/termos',
      );
      expect(find.text('Versão 1, em vigor desde [DATA].'), findsOneWidget);
      expect(find.text('1. Quem somos'), findsOneWidget);
      final headerTop = tester.getTopLeft(header).dy;

      await scrollToEnd(tester);
      expect(find.byKey(LegalKeys.section(15)), findsOneWidget);
      expect(find.text('16. Lei e foro'), findsOneWidget);
      expect(find.byKey(LegalKeys.section(16)), findsNothing);
      expect(tester.getTopLeft(header).dy, headerTop);

      await tester.tap(find.byKey(LegalKeys.close));
      await tester.pumpAndSettle();
      expect(find.byKey(LegalKeys.sheet), findsNothing);
      expect(find.byKey(SettingsKeys.aboutScreen), findsOneWidget);
    });

    testWidgets('Política: 13 seções, da primeira à última', (tester) async {
      await pumpAbout(tester);
      await tester.tap(find.byKey(SettingsKeys.aboutPrivacy));
      await tester.pumpAndSettle();

      expect(find.byKey(LegalKeys.privacy), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(SheetKeys.title)).data,
        'Política de privacidade',
      );
      expect(find.text('1. Quem decide sobre seus dados'), findsOneWidget);
      await scrollToEnd(tester);
      expect(find.text('13. Mudanças nesta Política'), findsOneWidget);
      expect(find.byKey(LegalKeys.section(13)), findsNothing);
    });

    testWidgets('voltar do sistema fecha a folha', (tester) async {
      await pumpAbout(tester);
      await tester.tap(find.byKey(SettingsKeys.aboutTerms));
      await tester.pumpAndSettle();
      expect(find.byKey(LegalKeys.sheet), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byKey(LegalKeys.sheet), findsNothing);
      expect(find.byKey(SettingsKeys.aboutScreen), findsOneWidget);
    });
  });
}
