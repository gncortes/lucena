import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/speedrun/widgets/speedrun_history_screen.dart';

void main() {
  // T67d P2: em 360 a hora do recorde quebrava sozinha ("às / 20:06").
  test('a hora do recorde fica presa à palavra de antes', () async {
    final pt = await AppLocalizations.delegate.load(const Locale('pt', 'BR'));
    expect(
      recordAtLabel(pt, '12 de outubro', '20:06'),
      'Em 12 de outubro, às 20:06',
    );
  });

  test('em todos os idiomas a hora não fica sozinha numa linha', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final label = recordAtLabel(l10n, 'D', '20:06');
      expect(label, contains('20:06'), reason: '$locale');
      expect(label, isNot(contains(' 20:06')), reason: '$locale');
    }
  });
}
