import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// V6 (H-ANI-01, critério 3, e H-ANI-06, critério 4): os widgets de
/// movimento só usam os tempos e curvas de `LucenaMotion`, e nenhuma folha do
/// app sobe sem a `FolhaLucena`.
void main() {
  Iterable<(String, int, String)> linhas(String pasta) sync* {
    final arquivos = Directory(pasta)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    for (final arquivo in arquivos) {
      final caminho = arquivo.path.replaceAll(r'\', '/');
      for (final (i, linha) in arquivo.readAsLinesSync().indexed) {
        if (linha.trimLeft().startsWith('//')) continue;
        yield (caminho, i + 1, linha);
      }
    }
  }

  test('nenhum Duration ou Cubic fora de LucenaMotion', () {
    final soltos = [
      for (final (caminho, n, linha) in linhas('lib/ui/core/motion'))
        if (!caminho.endsWith('/lucena_motion.dart') &&
            RegExp(r'\bDuration\(|\bCubic\(').hasMatch(linha))
          '$caminho:$n: ${linha.trim()}',
    ];
    expect(soltos, isEmpty, reason: soltos.join('\n'));
  });

  test('nenhum showModalBottomSheet fora da FolhaLucena', () {
    final soltos = [
      for (final (caminho, n, linha) in linhas('lib'))
        if (!caminho.endsWith('/motion/folha_lucena.dart') &&
            linha.contains('showModalBottomSheet'))
          '$caminho:$n: ${linha.trim()}',
    ];
    expect(soltos, isEmpty, reason: soltos.join('\n'));
  }, skip: 'entra com a FolhaLucena, no lote L1');
}
