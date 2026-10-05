import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/domain/use_cases/position_assessment.dart';
import 'package:lucena/ui/free_board/view_models/free_board_state.dart';
import 'package:lucena/ui/free_board/view_models/talk_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_evaluation_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_talk_repository.dart';

void main() {
  // Rei e torre das brancas (o jogador) contra o rei das pretas (o Valdini).
  final start = GameRules.fromFen('4k3/8/8/8/8/8/8/R3K3 w - - 0 1')!;
  final startedAt = DateTime.utc(2026, 1, 1, 12);
  const mode = GameMode(
    opponent: OpponentKind.maia,
    level: 1600,
    userSide: Side.white,
    goal: PositionGoal.win,
  );

  late FakeEvaluationRepository evaluation;
  late FakeTalkRepository talk;
  late FakeSettingsRepository settings;

  TalkCubit cubit() {
    final cubit = TalkCubit(
      characters: FakeCharacterRepository(),
      evaluation: evaluation,
      talk: talk,
      settings: settings,
      now: FakeNow(startedAt),
      language: 'pt',
      random: Random(3),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  // A partida depois dos lances [ucis] (sem conferir quem joga).
  FreeBoardState game(List<String> ucis, {DateTime? at}) {
    var position = start;
    for (final uci in ucis) {
      position = GameRules.play(position, Move.parse(uci)!)!.position;
    }
    return FreeBoardState(
      start: start,
      position: position,
      ucis: ucis,
      mode: mode,
      startedAt: at ?? startedAt,
    );
  }

  // Lances que vão e voltam, para a posição não acabar.
  const shuffle = ['a1a2', 'e8d8', 'a2a1', 'd8e8'];

  setUp(() {
    evaluation = FakeEvaluationRepository();
    talk = FakeTalkRepository();
    settings = FakeSettingsRepository();
  });

  test('o personagem é o do nível do Maia e abre a partida falando', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();

    expect(talking.state.character?.name, 'Valdini');
    expect(talking.state.line?.category, LineCategory.gameStart);
  });

  test('contra o Stockfish não há personagem', () async {
    final talking = cubit()
      ..update(
        game([])
            .copyWith(mode: mode.copyWith(opponent: OpponentKind.stockfish)),
      );
    await talking.settled();

    expect(talking.state.character, isNull);
    expect(talking.state.line, isNull);
  });

  test('erro grave do jogador: fala de erro grave do adversário', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();
    evaluation.next.addAll([
      const Evaluation(centipawns: -500),
      const Evaluation(centipawns: -500),
      const Evaluation(centipawns: 100),
    ]);
    // O jogador mexe, o personagem responde e o jogador entrega a vantagem.
    talking.update(game(shuffle.sublist(0, 1)));
    talking.update(game(shuffle.sublist(0, 2)));
    talking.update(game(shuffle.sublist(0, 3)));
    await talking.settled();

    expect(talking.state.line?.category, LineCategory.opponentBlunder);
  });

  test('virada: fala de "virou" e não de "está ganhando"', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();
    final scores = [-300, -300, -280, 50, 200];
    for (final (index, score) in scores.indexed) {
      evaluation.next.add(Evaluation(centipawns: score));
      talking.update(game([for (var i = 0; i <= index; i++) shuffle[i % 4]]));
    }
    await talking.settled();

    expect(talking.state.line?.category, LineCategory.comeback);
  });

  test('a mesma situação várias vezes: falas diferentes', () async {
    final said = <String>{};
    for (var round = 0; round < 3; round++) {
      final talking = cubit()
        ..update(game([], at: startedAt.add(Duration(minutes: round))));
      await talking.settled();
      said.add(talking.state.line!.id);
    }
    // Cada partida nova sorteia de novo; com o mesmo sorteio, a memória
    // gravada da partida anterior não vale para a nova.
    expect(said, isNotEmpty);

    final talking = cubit()..update(game([]));
    await talking.settled();
    final lines = <String>[talking.state.line!.id];
    var ucis = <String>[];
    for (var move = 0; move < 12; move++) {
      ucis = [...ucis, shuffle[move % 4]];
      // O jogador entrega a vantagem a cada lance dele.
      evaluation.next.add(Evaluation(centipawns: move.isEven ? 0 : 400));
      talking.update(game(ucis));
      await talking.settled();
      final line = talking.state.line!;
      if (line.category == LineCategory.opponentBlunder) lines.add(line.id);
    }
    expect(lines.toSet().length, lines.length);
  });

  test('a memória volta com a partida restaurada', () async {
    final first = cubit()..update(game([]));
    await first.settled();
    evaluation.next.addAll([
      const Evaluation(centipawns: 600),
      const Evaluation(centipawns: 600),
    ]);
    first.update(game(shuffle.sublist(0, 2)));
    await first.settled();
    final line = first.state.line;
    final emotion = first.state.emotion;
    await first.close();

    final second = cubit()..update(game(shuffle.sublist(0, 2)));
    await second.settled();

    expect(second.state.line, line);
    expect(second.state.emotion, emotion);
    // Os lances já vistos não são avaliados de novo: só as avaliações da
    // primeira vez.
    expect(evaluation.requests, hasLength(2));
  });

  test('falas desligadas: o balão não aparece', () async {
    settings = FakeSettingsRepository(const AppSettings(characterTalk: false));
    final talking = cubit()..update(game([]));
    await talking.settled();

    expect(talking.state.enabled, isFalse);
  });

  test('o fim da partida tem a fala do resultado', () async {
    // Mate do jogador: o personagem perdeu.
    final mate = GameRules.fromFen('7k/8/6K1/8/8/8/8/R7 w - - 0 1')!;
    final talking = cubit()
      ..update(
        FreeBoardState(
          start: mate,
          position: mate,
          mode: mode,
          startedAt: startedAt,
        ),
      );
    await talking.settled();
    final played = GameRules.play(mate, Move.parse('a1a8')!)!.position;
    talking.update(
      FreeBoardState(
        start: mate,
        position: played,
        ucis: const ['a1a8'],
        mode: mode,
        startedAt: startedAt,
      ),
    );
    await talking.settled();

    expect(talking.state.line?.category, LineCategory.loss);
  });

  test('lances com o app fechado: o personagem vê só o que faltava', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();
    talking.update(game(shuffle));
    await talking.settled();
    // Só os dois últimos lances da leva são avaliados.
    expect(evaluation.requests, hasLength(2));
    expect(Emotion.values, contains(talking.state.emotion));
  });
}
