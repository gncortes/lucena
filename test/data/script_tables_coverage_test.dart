import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/script_table_repository.dart';
import 'package:lucena/domain/models/script_table.dart';

/// T76: todo roteiro que julga posição com mais de 3 peças (objetivo ganhar ou
/// empatar, juiz `kpk`, prática de jogo) tem a tabela gerada por
/// `tools/script_tables.py`, e ela cobre a posição de cada pergunta, a
/// posição depois de QUALQUER lance legal do aluno nela, e o começo da
/// prática. Roteiro novo sem tabela: rodar a ferramenta.

const _scripts = AssetScriptTableRepository.scriptsDir;

int _pieces(Position position) => position.board.occupied.squares.length;

Position _pos(String fen) => Chess.fromSetup(Setup.parseFen(fen));

/// A tabela só precisa da posição que o oráculo KPK e as regras não decidem.
bool _needsTable(Position position) =>
    _pieces(position) > 3 && !position.isGameOver;

List<Map<String, dynamic>> _steps(Map<String, dynamic> example) {
  final out = <Map<String, dynamic>>[
    ...(example['entrada'] as List? ?? const []).cast(),
    ...(example['linha'] as List? ?? const []).cast(),
  ];
  final question = example['pergunta'] as Map<String, dynamic>?;
  if (question != null) {
    for (final key in ['certo', 'revela']) {
      if (question[key] is Map) out.add(question[key] as Map<String, dynamic>);
    }
    for (final group in ['alternativos', 'erros']) {
      for (final value in (question[group] as Map? ?? const {}).values) {
        if (value is List) out.addAll(value.cast());
        if (value is Map) out.add(value as Map<String, dynamic>);
      }
    }
  }
  return out;
}

/// O mesmo critério de `judged` da ferramenta.
bool _judged(Map<String, dynamic> example) {
  final goal = example['objetivo'] as String? ?? 'ganhar';
  if (goal != 'ganhar' && goal != 'empatar') return false;
  final question = example['pergunta'] as Map<String, dynamic>?;
  final practice = example['pratica'] as Map<String, dynamic>?;
  if (question != null && (question['juiz'] ?? 'kpk') != 'kpk') return false;
  if (practice != null && (practice['tipo'] ?? 'jogo') != 'jogo') return false;
  final fens = [example['fen'] as String, ..._steps(example).map(_fenOf)];
  return fens.any((fen) => _pieces(_pos(fen)) > 3);
}

String _fenOf(Map<String, dynamic> step) => step['fen'] as String;

/// Todo lance legal, com as quatro coroações.
Iterable<Position> _children(Position position) sync* {
  for (final MapEntry(key: from, value: targets)
      in position.legalMoves.entries) {
    for (final to in targets.squares) {
      final promotes =
          position.board.roleAt(from) == Role.pawn &&
          (to.rank == Rank.first || to.rank == Rank.eighth);
      if (!promotes) {
        yield position.playUnchecked(NormalMove(from: from, to: to));
        continue;
      }
      for (final role in [Role.queen, Role.rook, Role.bishop, Role.knight]) {
        yield position.playUnchecked(
          NormalMove(from: from, to: to, promotion: role),
        );
      }
    }
  }
}

void main() {
  final files =
      io.Directory(_scripts)
          .listSync(recursive: true)
          .whereType<io.File>()
          .where((file) => file.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final examples = [
      for (final stage in (json['etapas'] as List? ?? const []).cast<Map>())
        for (final example
            in (stage['exemplos'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          if (_judged(example)) example,
    ];
    if (examples.isEmpty) continue;

    test('${file.path}: a tabela cobre as perguntas e as práticas', () {
      final tablePath = AssetScriptTableRepository.pathFor(file.path);
      final tableFile = io.File(tablePath);
      expect(
        tableFile.existsSync(),
        isTrue,
        reason: 'falta $tablePath: rode tools/script_tables.py',
      );
      final table = ScriptTable.fromJson(
        jsonDecode(tableFile.readAsStringSync()) as Map<String, dynamic>,
      );
      final missing = <String>[];
      void need(Position position, String where) {
        if (_needsTable(position) && table.wdl(position.fen) == null) {
          missing.add('$where: ${ScriptTable.keyOf(position.fen)}');
        }
      }

      for (final example in examples) {
        final id = example['id'];
        for (final step in [example, ..._steps(example)]) {
          need(_pos(_fenOf(step)), '$id (passo)');
        }
        if (example['pergunta'] != null) {
          final entry = (example['entrada'] as List? ?? const []).cast<Map>();
          final fen = entry.isEmpty
              ? example['fen'] as String
              : entry.last['fen'] as String;
          final question = _pos(fen);
          need(question, '$id (pergunta)');
          for (final child in _children(question)) {
            need(child, '$id (lance do aluno)');
          }
        }
        if (example['pratica'] != null) {
          var start = _pos(example['fen'] as String);
          need(start, '$id (prática)');
          final student = example['vira'] == true ? Side.black : Side.white;
          if (_needsTable(start) && start.turn != student) {
            final best = table.best(start.fen);
            if (best == null) {
              missing.add('$id (prática): sem o lance da máquina');
              continue;
            }
            start = start.playUnchecked(Move.parse(best)!);
          }
          for (final child in _children(start)) {
            need(child, '$id (prática, lance do aluno)');
          }
        }
      }
      expect(missing, isEmpty, reason: missing.take(20).join('\n'));
    });
  }

  test('o roteiro de cada capítulo de final está no caminho padrão', () {
    final index = io.Directory('assets/lessons/endgames')
        .listSync()
        .whereType<io.File>()
        .where((file) => file.path.endsWith('.json'));
    final wrong = <String>[];
    for (final file in index) {
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map<String, dynamic>) continue;
      final id = json['id'];
      for (final part
          in (json['parts'] as List? ?? const []).whereType<Map>()) {
        final path = part['roteiro'];
        if (path is! String || id is! String) continue;
        final expected = AssetLessonScriptRepository.chapterScriptPath(
          id,
          part['id'] as String,
        );
        if (path != expected) wrong.add('$path (esperado $expected)');
      }
    }
    expect(wrong, isEmpty);
  });
}
