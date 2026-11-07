import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// H-CON-14, critério 7: o endereço para pedir a exclusão sem o app é um só
/// (playlucena.com/excluir-conta), em todos os idiomas.
void main() {
  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .toList();
  // O pseudo-idioma troca as letras de propósito (gen_pseudo_l10n.py).
  final real = arbs.where((file) => !file.path.endsWith('_XA.arb'));

  test('nenhum idioma cita apagar-conta', () {
    expect(arbs, isNotEmpty);
    final stale = [
      for (final file in arbs)
        if (file.readAsStringSync().contains('apagar-conta')) file.path,
    ];
    expect(stale, isEmpty);
  });

  test('todo idioma cita playlucena.com/excluir-conta', () {
    final missing = [
      for (final file in real)
        if (!file.readAsStringSync().contains('playlucena.com/excluir-conta'))
          file.path,
    ];
    expect(missing, isEmpty);
  });
}
