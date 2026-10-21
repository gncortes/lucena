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

/// O fim "torre ganha" (T78, sessão 0): a prática `jogo` de dama contra torre
/// com o objetivo `ganhar` roda até a captura da torre, com a máquina
/// defendendo pela tabela do roteiro (`tools/script_tables.py`: a defesa que
/// mais demora a perder a torre, pelo DTZ). A prática da fixture é a posição
/// de Philidor com as brancas a jogar (`test/fixtures/kqkr`, gerada pelo
/// script com `--root`).

const _lesson = 'queen.vsRook.philidor';
const _key = '$_lesson/kqkr';
const _fixtures = 'test/fixtures/kqkr';

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

  String _file(String key) =>
      key == AssetLessonScriptRepository.scriptPath(_key)
      ? '$_fixtures/roteiro.json'
      : key;
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
  ScriptTable? table,
  FakePositionJudge? engine,
}) async {
  final repository = AssetLessonScriptRepository(
    AssetService(_FixtureBundle()),
  );
  final path = AssetLessonScriptRepository.scriptPath(_key);
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
  test('a prática roda até a torre cair, a máquina pela tabela', () async {
    final (cubit, engine, opponent) = await _open();
    expect(cubit.state.phase, ScriptPhase.praticaVez);
    expect(cubit.state.movable, Side.white);
    var plies = 0;
    for (
      var i = 0;
      i < 30 && cubit.state.phase == ScriptPhase.praticaVez;
      i++
    ) {
      final fen = cubit.state.fen;
      final best = _table.best(fen);
      expect(best, isNotNull, reason: 'o aluno sem lance na tabela em $fen');
      await cubit.onMove(best!);
      plies++;
      if (cubit.state.phase != ScriptPhase.praticaVez) break;
      // A máquina respondeu com o lance da tabela, não com o motor.
      expect(cubit.state.lastMove, _table.best(_after(fen, best)));
      plies++;
    }
    final board = GameRules.fromFen(cubit.state.fen)!.board;
    expect(cubit.state.phase, ScriptPhase.praticaFim);
    expect(cubit.state.tone, ScriptTone.good);
    expect(board.rooks.isEmpty, isTrue);
    expect(board.queens.isNotEmpty, isTrue);
    expect(cubit.state.moves.last.result, '1–0');
    // A defesa resiste o máximo: 15 meios-lances (o DTZ da posição).
    expect(plies, 15);
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

  test(
    'lance fora da tabela não passa como certo: vale o juiz de reserva',
    () async {
      final start = (await _open()).$1.state.fen;
      final winning = _legal(start).firstWhere(
        (uci) =>
            uci != _table.best(start) &&
            _table.wdl(_after(start, uci)) == Wdl.loss,
      );
      final missing = ScriptTable.keyOf(_after(start, winning));
      final (cubit, engine, _) = await _open(
        table: ScriptTable({..._positions}..remove(missing)),
        engine: FakePositionJudge(results: {missing: Wdl.draw}),
      );
      await cubit.onMove(winning);
      expect(engine.asked, [missing]);
      expect(cubit.state.tone, ScriptTone.bad);
      expect(cubit.state.primary, ScriptAction.tentarDeNovo);
    },
  );
}
