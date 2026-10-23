import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena_ui/lucena_ui.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('pt'),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('TypingDots fica estático sem animação', (t) async {
    await t.pumpWidget(_host(const TypingDots(), disableAnimations: true));
    await t.pump(const Duration(milliseconds: 400));
    final before = t
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(TypingDots),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity)
        .toList();
    await t.pump(const Duration(milliseconds: 400));
    final after = t
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(TypingDots),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity)
        .toList();
    expect(before, after);
    expect(before.toSet().length, 1);
  });
}
