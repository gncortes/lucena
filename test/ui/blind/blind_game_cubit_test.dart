import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/blind/speech_input_repository.dart';
import 'package:lucena/data/repositories/voice/voice_repository.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';

import '../../../testing/fakes/fake_blind_log_repository.dart';
import '../../../testing/fakes/fake_draw_offer_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_speech_input_repository.dart';
import '../../../testing/fakes/fake_voice_repository.dart';

void main() {
  late FakeVoiceRepository voice;
  late FakeSpeechInputRepository input;
  late FakeBlindLogRepository log;
  late FakeOpponentRepository opponent;

  final phrases = BlindPhrases(
    yourTurn: 'Sua vez.',
    notUnderstood: 'Não entendi, repita.',
    which: (options) => 'Qual: ${options.join(' ou ')}?',
    position: (white, black) => 'Brancas: $white. Pretas: $black.',
    pawn: 'peão',
    won: 'Você venceu!',
    lost: 'Você perdeu.',
    draw: 'Empate.',
    resigned: 'Você desistiu.',
    confirm: (move) => '$move. Confirma?',
    start: 'Posição inicial.',
    moveLine: (number, side, move) =>
        'Lance $number, ${side == Side.white ? 'brancas' : 'pretas'}: $move.',
    noMoves: 'Nenhum lance ainda.',
    illegal: (move) => '$move não é possível nesta posição.',
    drawAgreed: 'Empate combinado.',
    drawDeclined: 'Empate recusado.',
  );

  setUp(() {
    voice = FakeVoiceRepository()..autoFinish = true;
    input = FakeSpeechInputRepository();
    log = FakeBlindLogRepository();
    opponent = FakeOpponentRepository();
  });

  Future<BlindGameCubit> open(
    String fen, {
    Side user = Side.white,
    Duration releaseWait = Duration.zero,
  }) async {
    final cubit = BlindGameCubit(
      releaseWait: releaseWait,
      opponent: opponent,
      voice: voice,
      input: input,
      log: log,
      now: FakeNow(DateTime.utc(2026, 10, 7)),
      thinkTime: Duration.zero,
      restartDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load(
      fen: fen,
      userSide: user,
      kind: OpponentKind.maia,
      level: 1000,
      language: 'pt-BR',
      phrases: phrases,
    );
    await cubit.start();
    return cubit;
  }

  // Segura, fala e solta: espera o app reagir.
  Future<void> say(BlindGameCubit cubit, List<String> heard) async {
    await cubit.listen();
    input.hear(heard);
    await pumpEventQueue();
    await cubit.stopListening();
    await pumpEventQueue();
  }

  // Fala o lance e confirma ("sim, jogar"): a máquina responde.
  Future<void> play(BlindGameCubit cubit, List<String> heard) async {
    await say(cubit, heard);
    await cubit.confirm();
    await pumpEventQueue();
  }

  List<String> spoken() => [for (final (text, _) in voice.spoken) text];

  test(
    'abre na vez do jogador: diz "sua vez" e começa com o tabuleiro vazio',
    () async {
      final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      expect(spoken(), ['Sua vez.']);
      expect(cubit.state.phase, BlindPhase.playerTurn);
      expect(cubit.state.view, BlindView.empty);
    },
  );

  test('a entrada: nada acontece antes de "começar"; dá para ouvir a '
      'posição', () async {
    final cubit = BlindGameCubit(
      opponent: opponent,
      voice: voice,
      input: input,
      log: log,
      now: FakeNow(DateTime.utc(2026, 10, 7)),
      thinkTime: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load(
      fen: '4k3/8/8/8/8/8/8/R3K3 b - - 0 1',
      userSide: Side.white,
      kind: OpponentKind.maia,
      level: 1000,
      language: 'pt-BR',
      phrases: phrases,
    );
    expect(cubit.state.phase, BlindPhase.intro);
    expect(opponent.requests, isEmpty);
    await cubit.listen();
    expect(input.listens, isEmpty);
    await cubit.narratePosition();
    expect(spoken().last, 'Brancas: rei e1, torre a1. Pretas: rei e8.');

    // A máquina joga primeiro: só depois de começar.
    await cubit.start();
    expect(opponent.requests, hasLength(1));
  });

  test('o lance dito vira uma proposta: "não" descarta, "sim" joga', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await say(cubit, ['torre a7']);
    expect(cubit.state.phase, BlindPhase.proposing);
    expect(cubit.state.proposal?.san, 'Ra7');
    // O lance aparece escrito; o alto-falante lê quando o jogador quer.
    expect(spoken().last, isNot(contains('Confirma')));
    await cubit.sayProposal();
    expect(spoken().last, 'torre a7. Confirma?');
    await cubit.reject();
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.lastUser, isNull);

    // Também por voz: o lance e depois "sim".
    await say(cubit, ['torre a7']);
    await say(cubit, ['sim']);
    expect(cubit.state.lastUser, 'Ra7');
    expect(log.attempts.map((a) => a.result), [
      'move',
      'rejected',
      'move',
      'command',
      'confirmed',
    ]);
  });

  test('o jogador fala e confirma, o lance é jogado, a máquina responde em '
      'voz alta e volta a vez dele', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await play(cubit, ['torre a7']);
    expect(cubit.state.lastUser, 'Ra7');
    expect(opponent.requests, hasLength(1));
    expect(cubit.state.lastOpponent, isNotNull);
    // O lance da máquina sai em português ("rei d8"), não em notação.
    expect(spoken().last, startsWith('rei '));
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(log.attempts.map((a) => a.result), ['move', 'confirmed']);
    expect(log.attempts.first.san, 'Ra7');
  });

  test('narrar a partida: a posição inicial e cada lance', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.narrateGame();
    expect(spoken().last, endsWith('Nenhum lance ainda.'));
    await play(cubit, ['torre a7']);
    await cubit.narrateGame();
    expect(
      spoken().last,
      startsWith(
        'Posição inicial. Brancas: rei e1, torre a1. Pretas: rei e8. '
        'Lance 1, brancas: torre a7. Lance 1, pretas: rei',
      ),
    );
  });

  test('repetir o lance do adversário', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.repeatOpponent();
    expect(spoken().last, 'Nenhum lance ainda.');
    await play(cubit, ['torre a7']);
    final last = spoken().last;
    await cubit.repeatOpponent();
    expect(spoken().last, last);
  });

  test(
    'mate: a partida acaba, o resultado é dito e o tabuleiro volta',
    () async {
      final cubit = await open('7k/8/6K1/8/8/8/8/1Q6 w - - 0 1');
      await play(cubit, ['dama b8']);
      expect(cubit.state.phase, BlindPhase.finished);
      expect(cubit.state.end?.reason, GameEndReason.checkmate);
      expect(cubit.state.userWon, isTrue);
      expect(cubit.state.view, BlindView.board);
      expect(spoken().last, 'Você venceu!');
    },
  );

  test('duas torres para f3: o app pergunta qual, e a resposta joga', () async {
    final cubit = await open('4k3/8/8/8/8/R6R/8/4K3 w - - 0 1');
    await say(cubit, ['torre efe três']);
    expect(cubit.state.phase, BlindPhase.confirming);
    expect(spoken().last, 'Qual: torre de a3 para f3 ou torre de h3 para f3?');
    await say(cubit, ['a de aga']);
    expect(cubit.state.lastUser, 'Rhf3');
    expect(log.attempts.map((a) => a.result), ['ambiguous', 'move']);
  });

  test('não entendeu: o recado aparece e continua na vez do jogador', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await say(cubit, ['bom dia']);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.notUnderstood, isTrue);
    expect(log.attempts.single.result, 'unknown');
  });

  test('"repetir" diz de novo o último lance da máquina; "posição" lê as '
      'peças', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await play(cubit, ['torre a7']);
    final last = spoken().last;
    await say(cubit, ['repetir']);
    expect(spoken().last, last);
    await say(cubit, ['posição']);
    expect(spoken().last, startsWith('Brancas: rei e1, torre a7. Pretas: rei'));
  });

  test('"desistir" encerra com a vitória da máquina', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await say(cubit, ['desisto']);
    expect(cubit.state.phase, BlindPhase.finished);
    expect(cubit.state.userWon, isFalse);
    expect(spoken().last, 'Você desistiu.');
  });

  test('o microfone fica fechado enquanto a máquina fala', () async {
    voice.autoFinish = false;
    final cubit = BlindGameCubit(
      opponent: opponent,
      voice: voice,
      input: input,
      log: log,
      now: FakeNow(DateTime.utc(2026, 10, 7)),
      thinkTime: Duration.zero,
      speechTimeout: const Duration(seconds: 30),
    );
    addTearDown(cubit.close);
    // As pretas jogam primeiro: a máquina abre e anuncia.
    final loading = cubit
        .load(
          fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
          userSide: Side.black,
          kind: OpponentKind.maia,
          level: 1000,
          language: 'pt-BR',
          phrases: phrases,
        )
        .then((_) => cubit.start());
    await pumpEventQueue();
    expect(cubit.state.phase, BlindPhase.opponentSpeaking);
    await cubit.listen();
    expect(input.listens, isEmpty);

    voice.emit(const TtsFinished());
    await loading;
    expect(cubit.state.phase, BlindPhase.playerTurn);
    await cubit.listen();
    expect(input.listens, hasLength(1));
  });

  test('o microfone: sem permissão, a tela explica antes; negado, fica o '
      'toque com o tabuleiro à vista', () async {
    input = FakeSpeechInputRepository(permitted: false, grants: false);
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.listen();
    expect(cubit.state.mic, MicPermission.asking);
    expect(input.listens, isEmpty);
    await cubit.requestMic();
    expect(cubit.state.mic, MicPermission.denied);
    expect(cubit.state.view, BlindView.board);
    expect(cubit.state.canListen, isFalse);

    await cubit.playTouch(NormalMove(from: Square.a1, to: Square.a7));
    expect(cubit.state.lastUser, 'Ra7');
  });

  test('microfone liberado no pedido: já começa a escutar', () async {
    input = FakeSpeechInputRepository(permitted: false);
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.listen();
    await cubit.requestMic();
    expect(cubit.state.mic, MicPermission.granted);
    expect(cubit.state.phase, BlindPhase.listening);
    expect(input.listens.first, ('pt-BR', true));
  });

  test('sem reconhecimento no aparelho: avisa e tenta o do sistema', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.listen();
    input.emit(
      const SpeechFailed('error_language_unavailable', offlineMissing: true),
    );
    await pumpEventQueue();
    expect(cubit.state.offlineMissing, isTrue);
    expect(input.listens.take(2), [('pt-BR', true), ('pt-BR', false)]);
    expect(cubit.state.phase, BlindPhase.listening);
  });

  test('segurando, o reconhecedor que para sozinho (silêncio) volta a '
      'escutar; só soltar envia', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.listen();
    input.emit(const SpeechStopped());
    input.emit(const SpeechFailed('error_no_match'));
    await pumpEventQueue();
    expect(cubit.state.phase, BlindPhase.listening);
    expect(cubit.state.notUnderstood, isFalse);
    expect(input.listens.length, greaterThanOrEqualTo(3));

    input.hear(['torre a7']);
    await pumpEventQueue();
    expect(cubit.state.phase, BlindPhase.listening);
    await cubit.stopListening();
    await pumpEventQueue();
    expect(cubit.state.phase, BlindPhase.proposing);
  });

  test('toque rápido: não grava nada e mostra que é para segurar; não '
      'entender não fala nada em voz alta', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    final before = voice.spoken.length;
    await cubit.listen();
    await cubit.cancelListening(tooShort: true);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.tooShort, isTrue);
    expect(log.attempts, isEmpty);

    await say(cubit, ['bom dia']);
    expect(cubit.state.notUnderstood, isTrue);
    expect(cubit.state.tooShort, isFalse);
    expect(voice.spoken.length, before);
  });

  test('o resultado que chega depois de soltar e depois do aviso de fim '
      '(como no reconhecedor do aparelho) vale', () async {
    final cubit = await open(
      '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
      releaseWait: const Duration(seconds: 5),
    );
    await cubit.listen();
    final released = cubit.stopListening();
    await pumpEventQueue();
    // O aviso de fim chega primeiro ("doneNoResult"): o app continua
    // entendendo.
    expect(cubit.state.processing, isTrue);
    expect(cubit.state.phase, BlindPhase.listening);
    // Depois, os parciais e o resultado final.
    input.emit(const SpeechHeard(['rei'], isFinal: false));
    input.hear(['rei de dois', 'torre a7']);
    await released;
    await pumpEventQueue();
    expect(cubit.state.processing, isFalse);
    expect(cubit.state.phase, BlindPhase.proposing);
    expect(cubit.state.proposal?.san, 'Kd2');
  });

  test('lance bem dito mas impossível: o app mostra o que entendeu; '
      'confirmado, avisa que é ilegal e nada é jogado', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await say(cubit, ['rei de três']);
    expect(cubit.state.phase, BlindPhase.proposing);
    expect(cubit.state.illegal, 'Kd3');
    await cubit.sayProposal();
    expect(spoken().last, 'rei d3. Confirma?');

    await cubit.confirm();
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.illegalShown, 'Kd3');
    expect(cubit.state.lastUser, isNull);
    expect(spoken().last, 'rei d3 não é possível nesta posição.');
    expect(log.attempts.map((a) => a.result), ['illegal', 'illegalConfirmed']);

    // Falar de novo limpa o aviso.
    await say(cubit, ['torre a7']);
    expect(cubit.state.illegalShown, isNull);
    expect(cubit.state.proposal?.san, 'Ra7');
  });

  test('lance impossível recusado: volta à vez do jogador sem aviso', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await say(cubit, ['rei de três']);
    await cubit.reject();
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.illegal, isNull);
    expect(cubit.state.illegalShown, isNull);
  });

  group('sem a voz', () {
    test('digitar: a notação em português joga direto', () async {
      final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      await cubit.playTyped('Ta7');
      await pumpEventQueue();
      expect(cubit.state.lastUser, 'Ra7');
      expect(cubit.state.phase, BlindPhase.playerTurn);
    });

    test('digitar um lance impossível: avisa e não joga', () async {
      final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      await cubit.playTyped('Rd3');
      expect(cubit.state.illegalShown, 'Kd3');
      expect(cubit.state.lastUser, isNull);
      expect(spoken().last, 'rei d3 não é possível nesta posição.');
    });

    test('tocar as casas: a origem fica marcada e o destino joga', () async {
      final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      await cubit.tapSquare(Square.a1);
      expect(cubit.state.selected, Square.a1);
      await cubit.tapSquare(Square.a7);
      await pumpEventQueue();
      expect(cubit.state.lastUser, 'Ra7');
      expect(cubit.state.selected, isNull);
    });

    test('tocar a origem de novo desmarca; destino impossível avisa', () async {
      final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      await cubit.tapSquare(Square.e1);
      await cubit.tapSquare(Square.e1);
      expect(cubit.state.selected, isNull);
      await cubit.tapSquare(Square.e1);
      await cubit.tapSquare(Square.e5);
      expect(cubit.state.illegalShown, 'Ke1e5');
      expect(cubit.state.lastUser, isNull);
    });
  });

  group('empate', () {
    Future<BlindGameCubit> withDraws(FakeDrawOfferRepository draws) async {
      final cubit = BlindGameCubit(
        opponent: opponent,
        voice: voice,
        input: input,
        log: log,
        now: FakeNow(DateTime.utc(2026, 10, 7)),
        draws: draws,
        thinkTime: Duration.zero,
      );
      addTearDown(cubit.close);
      await cubit.load(
        fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
        userSide: Side.white,
        kind: OpponentKind.maia,
        level: 1000,
        language: 'pt-BR',
        phrases: phrases,
      );
      await cubit.start();
      return cubit;
    }

    test('a máquina aceita: a partida acaba empatada', () async {
      final cubit = await withDraws(FakeDrawOfferRepository()..accept = true);
      await cubit.offerDraw();
      expect(cubit.state.phase, BlindPhase.finished);
      expect(cubit.state.end?.reason, GameEndReason.drawAgreed);
      expect(spoken().last, 'Empate combinado.');
    });

    test('a máquina recusa: segue a partida e a tela avisa', () async {
      final cubit = await withDraws(FakeDrawOfferRepository());
      await cubit.offerDraw();
      expect(cubit.state.phase, BlindPhase.playerTurn);
      expect(cubit.state.drawDeclines, 1);
      expect(spoken().last, 'Empate recusado.');
    });
  });

  test('a fala quebrada em pedaços (o reconhecedor para no silêncio e volta) '
      'é entendida inteira', () async {
    final cubit = await open('4k3/8/8/8/8/8/8/R3K3 w - - 0 1');
    await cubit.listen();
    // "torre" … silêncio … "na casa de" … silêncio … "a7".
    input.hear(['torre']);
    await pumpEventQueue();
    input.emit(const SpeechHeard(['na casa de'], isFinal: false));
    input.emit(const SpeechStopped());
    await pumpEventQueue();
    input.emit(const SpeechHeard([' a7'], isFinal: false));
    await pumpEventQueue();
    await cubit.stopListening();
    await pumpEventQueue();
    expect(cubit.state.proposal?.san, 'Ra7');
    expect(log.attempts.last.alternatives.first, 'torre na casa de a7');
  });

  group('relógio', () {
    test('corre para quem joga, passa ao outro no lance e o tempo que acaba '
        'encerra a partida', () async {
      final now = FakeNow(DateTime.utc(2026, 10, 7));
      final cubit = BlindGameCubit(
        opponent: opponent,
        voice: voice,
        input: input,
        log: log,
        now: now,
        thinkTime: Duration.zero,
        tick: const Duration(milliseconds: 5),
      );
      addTearDown(cubit.close);
      await cubit.load(
        fen: '4k3/8/8/8/8/8/8/R3K3 w - - 0 1',
        userSide: Side.white,
        kind: OpponentKind.maia,
        level: 1000,
        language: 'pt-BR',
        phrases: phrases,
        clock: ClockConfig.same(
          const TimeControl(
            initial: Duration(seconds: 30),
            increment: Duration(seconds: 2),
          ),
        ),
      );
      expect(cubit.state.white, const Duration(seconds: 30));
      await cubit.start();
      expect(cubit.state.running, Side.white);

      now.advance(const Duration(seconds: 10));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(cubit.state.white, const Duration(seconds: 20));

      // Jogou: ganhou o acréscimo, e o relógio passou (e voltou, depois da
      // resposta da máquina).
      await cubit.playTyped('Ta7');
      await pumpEventQueue();
      expect(cubit.state.white, const Duration(seconds: 22));
      expect(cubit.state.running, Side.white);

      // O tempo acaba. As pretas só têm o rei e não dão mate: empate.
      now.advance(const Duration(seconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await pumpEventQueue();
      expect(cubit.state.phase, BlindPhase.finished);
      expect(
        cubit.state.end?.reason,
        GameEndReason.timeoutVsInsufficientMaterial,
      );
      expect(cubit.state.running, isNull);
    });
  });

  test(
    'desafio da Jornada às cegas: o mate fica no histórico como cumprido',
    () async {
      final progress = FakeProgressRepository();
      final cubit = BlindGameCubit(
        opponent: opponent,
        voice: voice,
        input: input,
        log: log,
        now: FakeNow(DateTime.utc(2026, 10, 7)),
        progress: progress,
        thinkTime: Duration.zero,
        restartDelay: Duration.zero,
      );
      addTearDown(cubit.close);
      await cubit.load(
        fen: '7k/8/6K1/8/8/8/8/1Q6 w - - 0 1',
        userSide: Side.white,
        kind: OpponentKind.maia,
        level: 1000,
        language: 'pt-BR',
        phrases: phrases,
        view: BlindView.hidden,
        challengeId: '1000/blind.basic.queen.0001',
        positionId: 'basic.queen.0001',
      );
      expect(cubit.state.view, BlindView.hidden);
      await cubit.start();
      await play(cubit, ['dama b8']);

      expect(
        await progress.fulfilledChallenges(),
        contains('1000/blind.basic.queen.0001'),
      );
    },
  );
}
