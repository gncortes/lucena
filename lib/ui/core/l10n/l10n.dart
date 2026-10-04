import 'package:flutter/widgets.dart';

import '../../../l10n/app_localizations.dart';

export '../../../l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Converte o código salvo (`es`, `pt_PT`) em [Locale]. Nulo segue o sistema.
Locale? localeFromCode(String? code) {
  if (code == null) return null;
  final parts = code.split('_');
  return Locale(parts.first, parts.length > 1 ? parts[1] : null);
}

/// Idiomas do app com o inglês em primeiro: o Flutter usa o primeiro da lista
/// quando o idioma do aparelho não tem tradução.
final List<Locale> appSupportedLocales = [
  const Locale('en'),
  ...AppLocalizations.supportedLocales.where(
    (locale) => locale != const Locale('en'),
  ),
];
