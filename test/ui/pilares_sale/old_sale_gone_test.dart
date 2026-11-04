import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H-VEN-18: a prévia de desenvolvimento saiu; o preço antigo não volta ao
/// código nem aos assets, e nenhuma rota de Ajustes leva a outra venda.
void main() {
  Iterable<File> files(String dir) =>
      Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => !file.path.endsWith('old_sale_gone_test.dart'))
          .where((file) => RegExp(r'\.(dart|json|arb)$').hasMatch(file.path));

  test('o preço antigo (R\$ 59,90) não está em lib, assets nem test', () {
    final hits = [
      for (final dir in ['lib', 'assets', 'test'])
        for (final file in files(dir))
          if (file.readAsStringSync().contains('59,90')) file.path,
    ];
    expect(hits, isEmpty);
  });

  test('a prévia antiga não tem rota nem tile', () {
    final hits = [
      for (final file in files('lib'))
        if (RegExp(
          r"/settings/pilares|pilaresPreviewTile|pilares_preview\.json",
        ).hasMatch(file.readAsStringSync()))
          file.path,
    ];
    expect(hits, isEmpty);
  });
}
