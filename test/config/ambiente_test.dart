import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';

void main() {
  test('--flavor prod vira Ambiente.prod (isProd)', () {
    expect(Ambiente.atual(flavor: 'prod'), Ambiente.prod);
    expect(Ambiente.atual(flavor: 'prod').isProd, isTrue);
  });

  test('flavor dev, ausente ou desconhecido vira Ambiente.dev', () {
    expect(Ambiente.atual(flavor: 'dev'), Ambiente.dev);
    expect(Ambiente.atual(flavor: null), Ambiente.dev);
    expect(Ambiente.atual(flavor: 'hml'), Ambiente.dev);
    expect(Ambiente.dev.isProd, isFalse);
  });

  test('sem flavor no teste, o ambiente atual é dev', () {
    expect(Ambiente.atual(), Ambiente.dev);
  });
}
