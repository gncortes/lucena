import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/board/board_settings_ui.dart';

void main() {
  test('localizedSan troca as letras das peças pelas do idioma', () {
    final pt = lookupAppLocalizations(const Locale('pt'));
    expect(localizedSan(pt, '1.Ke3?'), '1.Re3?');
    expect(localizedSan(pt, 'Kf7'), 'Rf7');
    expect(localizedSan(pt, '1.g4?'), '1.g4?');
  });
}
