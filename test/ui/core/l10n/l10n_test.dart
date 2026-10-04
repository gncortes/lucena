import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';

void main() {
  test('converte o código salvo em Locale', () {
    expect(localeFromCode(null), isNull);
    expect(localeFromCode('es'), const Locale('es'));
    expect(localeFromCode('pt_PT'), const Locale('pt', 'PT'));
  });

  test('todo idioma oferecido tem tradução no app', () {
    for (final language in AppLanguage.values) {
      expect(
        AppLocalizations.supportedLocales,
        contains(localeFromCode(language.code)),
        reason: 'falta o arquivo app_${language.code}.arb',
      );
    }
  });

  test('toda tradução do app aparece na lista de idiomas', () {
    final codes = AppLanguage.values.map((language) => language.code);
    for (final locale in AppLocalizations.supportedLocales) {
      final code = locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}';
      expect(codes, contains(code), reason: 'falta $code em AppLanguage');
    }
  });

  test('os códigos dos idiomas não se repetem', () {
    final codes = AppLanguage.values.map((language) => language.code);
    expect(codes.toSet(), hasLength(AppLanguage.values.length));
  });
}
