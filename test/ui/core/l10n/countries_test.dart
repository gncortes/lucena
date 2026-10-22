import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/l10n/app_localizations.dart';
import 'package:lucena/ui/core/l10n/countries.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('o nome no idioma do app; código desconhecido fica como veio', () {
    expect(Countries.name(pt, 'br'), 'Brasil');
    expect(Countries.name(en, 'BR'), 'Brazil');
    expect(Countries.name(pt, 'QQ'), 'QQ');
  });

  test('em ordem alfabética, sem os códigos que não são país', () {
    final codes = [for (final c in Countries.all(pt)) c.key];
    expect(codes.first, 'AF');
    expect(codes, isNot(contains('EU')));
    expect(codes, isNot(contains('ZZ')));
    expect(codes.indexOf('IS'), lessThan(codes.indexOf('IT')));
  });

  test('a busca ignora acento e maiúscula e aceita o código', () {
    expect([for (final c in Countries.search(pt, 'JAPAO')) c.key], ['JP']);
    expect(Countries.search(pt, 'pt').map((c) => c.key), contains('PT'));
    expect(Countries.search(pt, '  '), hasLength(Countries.all(pt).length));
  });

  test('a bandeira sai das duas letras', () {
    expect(Countries.flag('br'), '🇧🇷');
    expect(Countries.flag('BRA'), '');
  });
}
