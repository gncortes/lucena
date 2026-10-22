import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dartchess/dartchess.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_script_repository_asset.dart';
import 'package:lucena/data/repositories/tablebase/kpk_repository.dart';
import 'package:lucena/data/repositories/tablebase/script_table_repository.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/domain/models/script_table.dart';
import 'package:lucena/domain/models/wdl.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/kpk_oracle.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_cubit.dart';

import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_lesson_source.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_position_judge.dart';

/// O fim `coroa` em torre e peão contra torre (T79, sessão 0): a prática
/// `jogo` com o objetivo `ganhar` roda até a coroação, com a máquina
/// defendendo pela tabela do roteiro (`tools/script_tables.py`: a defesa que
/// mais resiste, pelo DTZ, e no mesmo DTZ o xeque de mais longe). A coroação
/// só fecha a partida se a posição depois dela segue ganha (a dama não cai de
/// graça). Fixtures em `test/fixtures/krpkr`, geradas pelo script com `--root`:
/// `roteiro.json` (Lucena com o rei preto cortado) e `pendurada.json` (a
/// coroação que a torre preta captura).

const _lesson = 'rook.lucena';
const _fixtures = 'test/fixtures/krpkr';

/// A etapa da prática (ideia, demos, prática).
const _practiceStage = 2;

/// Os assets lidos do disco; o roteiro da prática vem da fixture.
class _FixtureBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await io.File(_file(key)).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      io.File(_file(key)).readAsString();

  String _file(String key) => switch (key) {
    _ when key == AssetLessonScriptRepository.scriptPath('$_lesson/krpkr') =>
      '$_fixtures/roteiro.json',
    _
        when key ==
            AssetLessonScriptRepository.scriptPath('$_lesson/pendurada') =>
      '$_fixtures/pendurada.json',
    _ => key,
  };
}

class _FixedTables implements ScriptTableRepository {
  _FixedTables(this._table);

  final ScriptTable _table;

  @override
  Future<ScriptTable> table(String scriptPath) async => _table;
}

final _kpk = KpkTableOracle(io.File(AssetKpkRepository.path).readAsBytesSync());

final _positions =
    ((jsonDecode(io.File('$_fixtures/tabela.json').readAsStringSync())
                as Map)['posicoes']
            as Map)
        .cast<String, String>();
final _table = ScriptTable(_positions);

Future<(LessonScriptCubit, FakePositionJudge, FakeOpponentRepository)> _open({
  String part = 'krpkr',
  ScriptTable? table,
  FakePositionJudge? engine,
}) async {
  final repository = AssetLessonScriptRepository(
    AssetService(_FixtureBundle()),
  );
  final path = AssetLessonScriptRepository.scriptPath('$_lesson/$part');
  final script = await repository.script(path);
  final judge = engine ?? FakePositionJudge();
  final opponent = FakeOpponentRepository();
  final cubit = LessonScriptCubit(
    lessonId: _lesson,
    partId: script.partId,
    scriptPath: path,
    language: 'pt',
    scripts: repository,
    kpk: FakeKpkRepository(_kpk),
    source: FakeLessonSource(),
    initialStage: _practiceStage,
    opponent: opponent,
    tables: _FixedTables(table ?? _table),
    engineJudge: judge,
    delay: (_) => Future.value(),
    timer: (_, _) => Timer(const Duration(days: 1), () {}),
  );
  addTearDown(cubit.close);
  await cubit.start();
  return (cubit, judge, opponent);
}

/// Os lances legais de [fen] em UCI, em ordem.
List<String> _legal(String fen) {
  final position = GameRules.fromFen(fen)!;
  return [
    for (final MapEntry(key: from, value: targets)
        in position.legalMoves.entries)
      for (final to in targets.squares) NormalMove(from: from, to: to).uci,
  ]..sort();
}

String _after(String fen, String uci) =>
    GameRules.fromFen(fen)!.play(Move.parse(uci)!).fen;

void main() {
  test('a prática roda até a coroação, a máquina pela tabela', () async {
    final (cubit, engine, opponent) = await _open();
    expect(cubit.state.phase, ScriptPhase.praticaVez);
    expect(cubit.state.movable, Side.white);
    for (
      var i = 0;
      i < 40 && cubit.state.phase == ScriptPhase.praticaVez;
      i++
    ) {
      final fen = cubit.state.fen;
      final best = _table.best(fen);
      expect(best, isNotNull, reason: 'o aluno sem lance na tabela em $fen');
      await cubit.onMove(best!);
      if (cubit.state.phase != ScriptPhase.praticaVez) break;
      // A máquina respondeu com o lance da tabela, não com o motor.
      expect(cubit.state.lastMove, _table.best(_after(fen, best)));
    }
    final board = GameRules.fromFen(cubit.state.fen)!.board;
    expect(cubit.state.phase, ScriptPhase.praticaFim);
    expect(cubit.state.tone, ScriptTone.good);
    expect(board.pawns.isEmpty, isTrue);
    expect(board.queens.isNotEmpty, isTrue);
    expect(cubit.state.moves.last.result, '1–0');
    expect(opponent.requests, isEmpty);
    expect(engine.asked, isEmpty);
  });

  test('o lance que empata pela tabela é refutado, não segue', () async {
    final (cubit, _, _) = await _open();
    final start = cubit.state.fen;
    final drawing = _legal(start)
        .firstWhere((uci) => _table.wdl(_after(start, uci)) == Wdl.draw);
    await cubit.onMove(drawing);
    expect(cubit.state.phase, ScriptPhase.praticaFim);
    expect(cubit.state.tone, ScriptTone.bad);
    expect(cubit.state.primary, ScriptAction.tentarDeNovo);
  });

  test('a dama que nasce pendurada não conta como coroação', () async {
    final (cubit, _, _) = await _open(part: 'pendurada');
    final start = cubit.state.fen;
    expect(_table.wdl(_after(start, 'b7b8q')), Wdl.draw);
    await cubit.onMove('b7b8q');
    expect(cubit.state.phase, ScriptPhase.praticaFim);
    expect(cubit.state.tone, ScriptTone.bad);
    expect(cubit.state.primary, ScriptAction.tentarDeNovo);
  });
}
