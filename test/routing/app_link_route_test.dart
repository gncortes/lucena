import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/routing/routes.dart';

void main() {
  test('desafio mantém caminho original, query e atribuição', () {
    const query =
        'fen=8%2F8%2F8%2F4k3%2F8%2F8%2F4K3%2F4Q3+w+-+-+0+1'
        '&lock=1&utm_source=teste&x=a%2Bb&x=c';
    for (final path in ['/p/original', '/p/original/']) {
      expect(
        Routes.appLink(Uri.parse('https://playlucena.com$path?$query')),
        '$path?$query',
      );
    }
  });

  test('link próprio inválido tem recuperação, terceiro é ignorado', () {
    for (final path in [
      '/p/x',
      '/p/x?fen=invalida',
      '/inexistente',
      '/dia/extra',
    ]) {
      expect(
        Routes.appLink(Uri.parse('https://playlucena.com$path')),
        Routes.invalidLink,
      );
    }
    expect(Routes.appLink(Uri.parse('https://example.com/dia')), isNull);
    expect(
      Routes.appLink(Uri.parse('javascript://playlucena.com/dia')),
      isNull,
    );
  });
}
