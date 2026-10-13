import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/failed_alternative.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/core/widgets/text_link.dart';
import 'package:lucena/ui/core/widgets/typing_dots.dart';
import 'package:lucena/ui/school/widgets/failed_moves_list.dart';

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
  testWidgets('TextLink tem alvo de 48 dp e responde ao toque', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(TextLink(label: 'Ver', onTap: () => taps++)));
    final size = t.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(size.width, greaterThanOrEqualTo(48));
    await t.tap(find.text('Ver'));
    expect(taps, 1);
  });

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

  testWidgets('FailedMovesList marca o já visto e abre o lance', (t) async {
    String? opened;
    await t.pumpWidget(
      _host(
        FailedMovesList(
          alternatives: const [
            FailedAlternative(uci: 'e2e3', label: '1.Re3?', seen: true),
            FailedAlternative(uci: 'g2g4', label: '1.g4?', seen: false),
          ],
          onOpen: (uci) => opened = uci,
        ),
      ),
    );
    expect(find.byKey(LessonKeys.alreadySeen('e2e3')), findsOneWidget);
    expect(find.byKey(LessonKeys.alreadySeen('g2g4')), findsNothing);
    expect(
      t.getSize(find.byKey(LessonKeys.failedAlternative('g2g4'))).height,
      greaterThanOrEqualTo(48),
    );
    await t.tap(find.byKey(LessonKeys.failedAlternative('g2g4')));
    expect(opened, 'g2g4');
  });
}
