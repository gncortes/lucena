import 'package:dartchess/dartchess.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/use_cases/race_turn.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/race_keys.dart';
import 'package:lucena/ui/race/view_models/race_cubit.dart';
import 'package:patrol/patrol.dart';

import '../testing/training/e2e_training.dart';
import 'robots/app_robot.dart';
import 'robots/race_robot.dart';
import 'robots/training_capture_robot.dart';

/// Vídeos curtos (≤ 10 s) do sinal de acerto e de erro (H-ANI-11) em lances
/// que terminam na borda do tabuleiro: na coluna a/h (que encosta na borda
/// da tela) e na 1ª/8ª fileira. A Corrida usa o mesmo `RetornoDoLance` de
/// todo exercício. Coletor: `tools/capture/t85_capture_server.py`.
void main() {
  bool naColuna(Square s) => s.file == File.a || s.file == File.h;
  bool naFileira(Square s) => s.rank == Rank.first || s.rank == Rank.eighth;

  patrolTest('D4 vídeos: acerto e erro nas bordas (Corrida)', ($) async {
    await AppRobot($)
        .open(systemLocale: const Locale('pt', 'BR'), lightDevice: true);
    final capture = TrainingCaptureRobot($);
    final race = RaceRobot($);
    await race.openFromAllModes();
    await race.start();

    RaceTurn turno() => $.tester
        .element(find.byKey(RaceKeys.gameView))
        .read<RaceCubit>()
        .state
        .turn!;

    Square destinoDoMelhor() {
      final best = turno().node.best.firstWhere((uci) => uci.length == 4);
      return Square.parse(best.substring(2))!;
    }

    /// Um lance legal errado que termina numa casa que [naBorda] aceita.
    (Square, Square)? erradoNaBorda(bool Function(Square) naBorda) {
      final turn = turno();
      final position = Chess.fromSetup(Setup.parseFen(turn.fen));
      for (final MapEntry(key: from, value: targets)
          in position.legalMoves.entries) {
        final role = position.board.roleAt(from);
        for (final to in targets.squares) {
          if (!naBorda(to)) continue;
          if (role == Role.king && (from.file - to.file).abs() > 1) continue;
          if (role == Role.pawn && naFileira(to)) continue;
          if (turn.judge('${from.name}${to.name}') == RaceMoveKind.optimal) {
            continue;
          }
          return (from, to);
        }
      }
      return null;
    }

    final faltam = <String, bool Function(Square)>{
      'D4BordaAcertoColuna': naColuna,
      'D4BordaAcertoFileira': naFileira,
    };
    final erros = <String, bool Function(Square)>{
      'D4BordaErroColuna': naColuna,
      'D4BordaErroFileira': naFileira,
    };
    for (var i = 0; i < 25 && (faltam.isNotEmpty || erros.isNotEmpty); i++) {
      if (find.byKey(RaceKeys.gameView).evaluate().isEmpty) break;
      // Primeiro o erro (a peça volta e o problema segue), depois o acerto.
      for (final MapEntry(key: nome, value: naBorda) in [...erros.entries]) {
        final lance = erradoNaBorda(naBorda);
        if (lance == null) continue;
        await capture.record(nome, () async {
          await race.move(lance.$1.name, lance.$2.name);
          await $.pump(const Duration(milliseconds: 1600));
        }, ready: RaceKeys.gameView);
        erros.remove(nome);
        break;
      }
      if (find.byKey(RaceKeys.gameView).evaluate().isEmpty) break;
      final destino = destinoDoMelhor();
      final nome = faltam.entries
          .where((e) => e.value(destino))
          .map((e) => e.key)
          .firstOrNull;
      if (nome == null) {
        await race.solve();
        continue;
      }
      await capture.record(nome, () async {
        await race.solve();
        await $.pump(const Duration(milliseconds: 900));
      }, ready: RaceKeys.gameView);
      faltam.remove(nome);
    }
    expect(faltam, isEmpty, reason: 'acertos na borda que não apareceram');
    expect(erros, isEmpty, reason: 'erros na borda que não apareceram');
    // O 3º erro fecha a Corrida: o resultado entra em ordem (H-ANI-25).
    await capture.record('D4CorridaResultado', () async {
      await race.miss();
      await race.waitForResult();
      await $.pump(const Duration(seconds: 3));
    }, ready: RaceKeys.resultView);
  });

  patrolTest('D4 vídeos: Treino, Guia em cascata e barras das metas', (
    $,
  ) async {
    await AppRobot($).open(
      systemLocale: const Locale('pt', 'BR'),
      lightDevice: true,
      trainingScenario: E2ETrainingScenario.goalsLarge,
    );
    final capture = TrainingCaptureRobot($);
    // H-ANI-16: o corpo do Guia entra em cascata na primeira abertura.
    await capture.record('D4GuiaCascata', () async {
      await capture.openGuide();
      await $.pump(const Duration(seconds: 2));
    }, ready: CourseGuideKeys.screen);
    // H-ANI-13 e 17: as barras das metas enchem e as linhas entram em ordem.
    await capture.record('D4MetasBarras', () async {
      await capture.tab('goals');
      await $.pump(const Duration(seconds: 2));
    }, ready: CourseGuideKeys.screen);
    await capture.record('D4ProgressoBarras', () async {
      await capture.tab('stats');
      await $.pump(const Duration(seconds: 2));
    }, ready: CourseGuideKeys.screen);
  });
}
