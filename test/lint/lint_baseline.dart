import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Checker com baseline (lote 10, B7 e "reaproveitar primeiro"): as
/// ocorrências que já existiam ficam contadas por arquivo em
/// `test/lint/baselines/<nome>.json`; o teste só falha quando um arquivo passa
/// da conta dele (código novo). Quando uma ocorrência sai, a conta cai junto:
/// rode com `ATUALIZAR_BASELINE=1 flutter test test/lint` para gravar o novo
/// teto (nunca para subir: código novo usa o token ou o componente do core).
void checkBaseline(String name, Map<String, int> found, String hint) {
  final file = File('test/lint/baselines/$name.json');
  if (Platform.environment['ATUALIZAR_BASELINE'] == '1') {
    final sorted = Map.fromEntries(
      found.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(sorted)}\n',
    );
    return;
  }
  final baseline = (jsonDecode(file.readAsStringSync()) as Map)
      .cast<String, int>();
  final over = <String>[];
  for (final entry in found.entries) {
    final allowed = baseline[entry.key] ?? 0;
    if (entry.value > allowed) {
      over.add('${entry.key}: ${entry.value} (teto $allowed)');
    }
  }
  expect(over, isEmpty, reason: hint);
}

/// Arquivos `.dart` de [root] com o caminho em `/`, fora dos gerados.
Iterable<(String, List<String>)> dartFiles(String root) sync* {
  for (final entity in Directory(root).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) continue;
    yield (path, entity.readAsLinesSync());
  }
}

bool isComment(String line) => line.trimLeft().startsWith('//');
