import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/ambiente.dart';

void main() {
  test('flavor dev vira Ambiente.dev', () {
    expect(Ambiente.deFlavor('dev'), Ambiente.dev);
    expect(Ambiente.dev.ehDev, isTrue);
  });

  test('flavor prod, ausente ou desconhecido vira Ambiente.prod', () {
    expect(Ambiente.deFlavor('prod'), Ambiente.prod);
    expect(Ambiente.deFlavor(null), Ambiente.prod);
    expect(Ambiente.deFlavor('hml'), Ambiente.prod);
    expect(Ambiente.prod.ehDev, isFalse);
  });

  test('sem flavor no teste, o ambiente atual é prod', () {
    expect(Ambiente.atual, Ambiente.prod);
  });
}
