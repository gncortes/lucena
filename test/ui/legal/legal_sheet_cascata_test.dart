import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/legal_document.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/legal/widgets/legal_sheet.dart';

import '../core/motion/entrada_helpers.dart';

/// H-ANI-16 na Legal: o topo da folha (marca, título e introdução) entra em
/// cascata; as seções de baixo ficam paradas.
void main() {
  const documento = LegalDocument(
    intro: [
      LegalParagraph([(text: 'Introdução', bold: false)]),
    ],
    sections: [
      LegalSection('Seção 1', [
        LegalParagraph([(text: 'Corpo', bold: false)]),
      ]),
    ],
  );

  Widget folha() => MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: EntradasVistasEscopo(
      vistas: EntradasVistas(),
      child: const Scaffold(
        body: LegalSheet(
          kind: LegalKind.terms,
          title: 'Termos de uso',
          hint: 'playlucenachess.com/termos',
          document: documento,
        ),
      ),
    ),
  );

  Finder item(int i) => find.byKey(MotionKeys.itemDaCascata(i));

  testWidgets('marca, título e introdução entram em ordem', (tester) async {
    await tester.pumpWidget(folha());
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      find.descendant(of: item(1), matching: find.text('Termos de uso')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: item(2), matching: find.textContaining('Introdução')),
      findsOneWidget,
    );
    expect(opacidade(tester, item(2)), lessThan(1));
    // As seções não entram na cascata.
    expect(
      find.ancestor(
        of: find.text('Seção 1'),
        matching: find.byKey(MotionKeys.itemDaCascata(3)),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(opacidade(tester, item(2)), 1);
  });
}
