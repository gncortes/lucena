import 'dart:math';
import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:lucena/data/repositories/characters/talk_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
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
  late FakeNow now;

  TalkCubit cubit() {
    final cubit = TalkCubit(
      characters: FakeCharacterRepository(),
      evaluation: evaluation,
      talk: talk,
      settings: settings,
      now: now,
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
    now = FakeNow(startedAt);
    evaluation = FakeEvaluationRepository();
    talk = FakeTalkRepository();
    settings = FakeSettingsRepository();
  });

  Future<void> dismissThree(
    TalkCubit talking, {
    DateTime? at,
    int? level,
  }) async {
    FreeBoardState current() => game(
      [],
      at: at,
    ).copyWith(mode: level == null ? mode : mode.copyWith(level: level));
    talking.update(current());
    await talking.settled();
    for (var index = 0; index < 3; index++) {
      expect(talking.state.line, isNotNull);
      talking.dismissLine(lineId: talking.state.line!.id);
      await talking.settled();
      if (index < 2) {
        talking.update(
          current().copyWith(
            drawOffer: DrawOffer.declined,
            drawDeclinedAt: index,
          ),
        );
        await talking.settled();
      }
    }
  }

  group('D12 fechamentos e dica', () {
    test(
      'fechar Cubit durante leitura não consome intervalo da dica',
      () async {
        final deferred = _DeferredHintRepository();
        talk = deferred;
        final talking = cubit();
        final pending = dismissThree(talking);
        await deferred.started.future;
        await talking.close();
        deferred.release.complete();
        await pending;
        expect(deferred.speechHintShownAt, isNull);
        expect(talking.state.speechHintVersion, 0);
        expect(deferred.saved!.lineId, isNull);
        expect(deferred.saved!.dismissedLineIds, hasLength(3));
      },
    );
    test(
      'fechar só fala atual; próximo evento volta, 3 IDs dão uma dica',
      () async {
        final talking = cubit()..update(game([]));
        await talking.settled();
        final firstId = talking.state.line!.id;
        talking.dismissLine(lineId: firstId);
        talking.dismissLine(lineId: firstId);
        await talking.settled();
        expect(talking.state.line, isNull);
        expect(talk.saved!.dismissedLineIds, [firstId]);
        expect(talking.state.enabled, isTrue);
        talking.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 0),
        );
        await talking.settled();
        expect(talking.state.line, isNotNull);
        talking.dismissLine(lineId: firstId); // toque atrasado.
        await talking.settled();
        expect(talking.state.line, isNotNull);
        talking.dismissLine();
        await talking.settled();
        expect(talking.state.speechHintVersion, 0);
        talking.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 1),
        );
        await talking.settled();
        talking.dismissLine();
        await talking.settled();
        expect(talk.saved!.dismissedLineIds, hasLength(3));
        expect(talk.saved!.speechHintShown, isTrue);
        expect(talking.state.speechHintVersion, 1);
        expect(talk.speechHintShownAt, now.value);
      },
    );

    test(
      'duas falas fechadas persistem; terceira após reload emite dica',
      () async {
        final first = cubit()..update(game([]));
        await first.settled();
        first.dismissLine();
        await first.settled();
        first.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 0),
        );
        await first.settled();
        first.dismissLine();
        await first.settled();
        final second = cubit()..update(game([]));
        await second.settled();
        expect(second.state.line, isNull);
        expect(talk.saved!.dismissedLineIds, hasLength(2));
        second.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 1),
        );
        await second.settled();
        second.dismissLine();
        await second.settled();
        expect(second.state.speechHintVersion, 1);
      },
    );

    test('mesmo ID reexibido depois de reload não conta de novo', () async {
      final first = cubit()..update(game([]));
      await first.settled();
      final line = first.state.line!;
      first.dismissLine();
      await first.settled();
      final saved = talk.saved!;
      talk.saved = TalkSnapshot(
        gameStartedAt: saved.gameStartedAt,
        plies: saved.plies,
        memory: saved.memory,
        lineId: line.id,
        dismissedLineIds: saved.dismissedLineIds,
      );
      final second = cubit()..update(game([]));
      await second.settled();
      second.dismissLine();
      await second.settled();
      expect(second.state.line, isNull);
      expect(talk.saved!.dismissedLineIds, [line.id]);
      expect(second.state.speechHintVersion, 0);
    });

    test(
      'reload não reemite dica mesmo passados 7 dias na mesma partida',
      () async {
        final first = cubit();
        await dismissThree(first);
        now.advance(const Duration(days: 8));
        final second = cubit()..update(game([]));
        await second.settled();
        expect(second.state.speechHintVersion, 0);
        second.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 2),
        );
        await second.settled();
        second.dismissLine();
        await second.settled();
        expect(second.state.speechHintVersion, 0);
        expect(talk.speechHintShownAt, startedAt);
      },
    );

    test('nova partida zera contagem e preserva intervalo global entre personagens', () async {
      final talking = cubit();
      await dismissThree(talking);
      final next = startedAt.add(const Duration(hours: 1));
      talking.update(
        game([], at: next).copyWith(mode: mode.copyWith(level: 1000)),
      );
      await talking.settled();
      expect(talk.saved!.dismissedLineIds, isEmpty);
      expect(talk.saved!.speechHintShown, isFalse);
      expect(talking.state.speechHintVersion, 1); // sem evento ao trocar.
      await dismissThree(talking, at: next, level: 1000);
      expect(talking.state.speechHintVersion, 1);
      expect(talk.speechHintShownAt, startedAt);
    });

    test('intervalo é de 7 dias exatos e persiste entre instâncias', () async {
      await dismissThree(cubit());
      now.advance(const Duration(days: 7) - Duration(microseconds: 1));
      final early = cubit();
      await dismissThree(early, at: now.value);
      expect(early.state.speechHintVersion, 0);
      now.advance(const Duration(microseconds: 1));
      final eligible = cubit();
      await dismissThree(eligible, at: now.value);
      expect(eligible.state.speechHintVersion, 1);
      expect(talk.speechHintShownAt, now.value);
    });

    test(
      'gravações lentas permanecem ordenadas e não reabrem balão fechado',
      () async {
        final deferred = _DeferredTalkRepository();
        talk = deferred;
        final talking = cubit()..update(game([]));
        await talking.settled();
        deferred.deferNext = true;
        talking.update(
          game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 0),
        );
        await deferred.started.future;
        talking.dismissLine();
        deferred.release.complete();
        await talking.settled();
        expect(deferred.maxConcurrentWrites, 1);
        expect(talking.state.line, isNull);
        expect(deferred.saved!.lineId, isNull);
        expect(deferred.saved!.dismissedLineIds, hasLength(1));
      },
    );

    test('falas desligadas não contam fechamento nem disparam dica', () async {
      final talking = cubit()..update(game([]));
      await talking.settled();
      talking.setEnabled(enabled: false);
      talking.dismissLine();
      await talking.settled();
      expect(talk.saved!.dismissedLineIds, isEmpty);
      expect(talking.state.speechHintVersion, 0);
    });
  });

  test('o personagem é o do nível do Maia e abre a partida falando', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();

    expect(talking.state.character?.name, 'Valdini');
    expect(talking.state.line?.category, LineCategory.gameStart);
  });

  test(
    'o Stockfish aparece com o logo e fala em binário quando joga',
    () async {
      final stockfish = mode.copyWith(opponent: OpponentKind.stockfish);
      final talking = cubit()..update(game([]).copyWith(mode: stockfish));
      await talking.settled();

      expect(talking.state.character, TalkCubit.stockfish);
      expect(talking.state.isEngine, isTrue);
      final first = talking.state.line!;
      expect(first.text, matches(RegExp(r'^[01]{8}( [01]{8})+$')));

      // O lance do jogador não muda a fala; o da máquina, sim.
      talking.update(game(shuffle.sublist(0, 1)).copyWith(mode: stockfish));
      await talking.settled();
      expect(talking.state.line, first);
      talking.update(game(shuffle.sublist(0, 2)).copyWith(mode: stockfish));
      await talking.settled();
      expect(talking.state.line!.id, isNot(first.id));
      expect(evaluation.requests, isEmpty);
    },
  );

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

  test('empate recusado e aceito: falas da categoria certa', () async {
    final talking = cubit()..update(game([]));
    await talking.settled();
    talking.update(
      game([]).copyWith(drawOffer: DrawOffer.declined, drawDeclinedAt: 0),
    );
    await talking.settled();
    expect(talking.state.line?.category, LineCategory.drawDeclined);

    talking.update(
      game([]).copyWith(
        drawOffer: DrawOffer.accepted,
        forcedEnd: const GameEnd(GameEndReason.drawAgreed),
      ),
    );
    await talking.settled();
    expect(talking.state.line?.category, LineCategory.drawAccepted);
  });
}

class _DeferredTalkRepository extends FakeTalkRepository {
  bool deferNext = false;
  final started = Completer<void>();
  final release = Completer<void>();
  int _activeWrites = 0;
  int maxConcurrentWrites = 0;

  @override
  Future<void> save(TalkSnapshot snapshot) async {
    _activeWrites++;
    maxConcurrentWrites = max(maxConcurrentWrites, _activeWrites);
    if (deferNext) {
      deferNext = false;
      started.complete();
      await release.future;
    }
    await super.save(snapshot);
    _activeWrites--;
  }
}

class _DeferredHintRepository extends FakeTalkRepository {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<DateTime?> loadSpeechHintShownAt() async {
    started.complete();
    await release.future;
    return super.loadSpeechHintShownAt();
  }
}
