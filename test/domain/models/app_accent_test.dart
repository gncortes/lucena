import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_accent.dart';

void main() {
  test('cada cor volta do código gravado', () {
    for (final accent in AppAccent.values) {
      expect(AppAccent.fromCode(accent.code), accent);
    }
  });

  test('código desconhecido ou ausente: nenhuma cor escolhida', () {
    expect(AppAccent.fromCode(null), isNull);
    expect(AppAccent.fromCode('magenta'), isNull);
  });

  test('de fábrica: azul no tema claro e verde no escuro', () {
    expect(AppAccent.standard(dark: false), AppAccent.blue);
    expect(AppAccent.standard(dark: true), AppAccent.green);
  });
}
