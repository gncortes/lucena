import 'dart:async';
import 'dart:math';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/characters/talk_repository.dart';
import '../../../data/repositories/evaluation/evaluation_repository.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/use_cases/clock_engine.dart';
import '../../../domain/use_cases/emotion_state.dart';
import '../../../domain/use_cases/game_events.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/line_picker.dart';
import '../../../domain/use_cases/now.dart';
import 'free_board_state.dart';

/// O personagem da partida e o que ele está dizendo.
class TalkState {
  const TalkState({
    this.character,
    this.line,
    this.emotion = Emotion.calm,
    this.enabled = true,
  });

  /// O adversário como personagem. Nulo contra o Stockfish e sem máquina.
  final Character? character;

  /// A fala no balão. Nula: balão fechado.
  final CharacterLine? line;
  final Emotion emotion;

  /// As falas estão ligadas em Configurações.
  final bool enabled;

  TalkState copyWith({
    Character? character,
    CharacterLine? line,
    bool clearLine = false,
    Emotion? emotion,
    bool? enabled,
  }) => TalkState(
    character: character ?? this.character,
    line: clearLine ? null : line ?? this.line,
    emotion: emotion ?? this.emotion,
    enabled: enabled ?? this.enabled,
  );
}

/// O adversário que comenta a partida: a cada lance, avalia a posição em
/// segundo plano, acha os eventos, atualiza a emoção e, quando é hora, escolhe
/// uma fala. A memória dele (emoção, falas ditas, a fala no balão) é gravada e
/// volta com a partida.
class TalkCubit extends Cubit<TalkState> {
  TalkCubit({
    required this._characters,
    required this._evaluation,
    required this._talk,
    required this._settings,
    required this._now,
    required this._language,
    Random? random,
  }) : _random = random ?? Random(),
       super(const TalkState());

  final CharacterRepository _characters;
  final EvaluationRepository _evaluation;
  final TalkRepository _talk;
  final SettingsRepository _settings;
  final Now _now;
  final String _language;
  final Random _random;

  // O trabalho em fila: um lance é visto depois do outro.
  Future<void> _work = Future.value();

  List<CharacterLine> _lines = const [];
  TalkMemory _memory = TalkMemory.empty;
  DateTime? _game;
  int _plies = 0;
  bool _ended = false;

  // O lance do jogador em que o personagem já reclamou da demora.
  int? _thinkingSaidAt;

  /// A partida mudou (lance, fim, partida nova). A tela chama a cada mudança.
  void update(FreeBoardState game) {
    _work = _work.then((_) => _update(game)).onError((_, _) {});
  }

  /// Espera o que está em andamento (para os testes).
  Future<void> settled() => _work;

  /// O relógio andou: falas de tempo (pouco tempo, demora para jogar).
  void tick(FreeBoardState game) {
    final clock = game.clock;
    final machine = game.mode.machineSide;
    if (state.character == null || clock == null || machine == null) return;
    if (game.end != null || _game != game.startedAt) return;
    final now = _now();
    final user = machine.opposite;
    final userToMove = clock.running == user;
    final turnStarted = clock.turnStartedAt;
    var events = GameEvents.clock(
      memory: _memory,
      characterTime: ClockEngine.remaining(clock, machine, now),
      playerTime: ClockEngine.remaining(clock, user, now),
      playerToMove: userToMove,
      playerThinking: userToMove && turnStarted != null
          ? now.difference(turnStarted)
          : Duration.zero,
    );
    // A demora do jogador vale uma fala por lance dele.
    if (_thinkingSaidAt == game.ucis.length) {
      events = [
        for (final event in events)
          if (event.category != LineCategory.opponentThinking) event,
      ];
    }
    if (events.isEmpty) return;
    _work = _work
        .then((_) {
          if (_game != game.startedAt) return;
          final said = _say(events);
          if (said?.category == LineCategory.opponentThinking) {
            _thinkingSaidAt = game.ucis.length;
          }
        })
        .onError((_, _) {});
  }

  Future<void> _update(FreeBoardState game) async {
    if (isClosed || !game.ready) return;
    final mode = game.mode;
    if (_game != game.startedAt) {
      await _open(game);
      return;
    }
    if (state.character == null) return;
    final machine = mode.machineSide!;
    while (_plies < game.ucis.length) {
      // O lance do jogador e a resposta da máquina costumam chegar juntos: os
      // dois são avaliados. Uma leva maior (lances jogados com o app fechado)
      // só tem os dois últimos avaliados.
      final recent = game.ucis.length - _plies <= 2;
      await _moved(game, _plies, machine, evaluate: recent);
      _plies++;
    }
    final end = game.end;
    if (end != null && !_ended) {
      _ended = true;
      final winner = end.winner;
      _say([
        GameEvent(
          winner == null
              ? LineCategory.draw
              : winner == machine
              ? LineCategory.win
              : LineCategory.loss,
          2,
        ),
      ]);
    }
    await _save();
  }

  // Partida nova ou a gravada voltando: o personagem do nível e a memória.
  Future<void> _open(FreeBoardState game) async {
    _game = game.startedAt;
    _plies = game.ucis.length;
    _ended = game.end != null;
    _thinkingSaidAt = null;
    final mode = game.mode;
    final character = mode.opponent == OpponentKind.maia
        ? (await _characters.characters()).forLevel(mode.level)
        : null;
    final settings = await _settings.load();
    if (character == null) {
      emit(TalkState(enabled: settings.characterTalk));
      return;
    }
    _lines = await _characters.lines(character.id, _language);
    final saved = await _talk.load();
    if (isClosed) return;
    if (saved != null && saved.gameStartedAt == game.startedAt) {
      _memory = saved.memory;
      _plies = saved.plies.clamp(0, game.ucis.length);
      emit(
        TalkState(
          character: character,
          line: _lineById(saved.lineId),
          emotion: _memory.emotion ?? EmotionRules.of(_memory),
          enabled: settings.characterTalk,
        ),
      );
      // Lances jogados com o app fechado (a máquina pode ter respondido).
      await _update(game);
      return;
    }
    _memory = TalkMemory.empty;
    emit(TalkState(character: character, enabled: settings.characterTalk));
    if (game.ucis.isEmpty) {
      _say(const [GameEvent(LineCategory.gameStart)]);
    }
    await _save();
  }

  Future<void> _moved(
    FreeBoardState game,
    int ply,
    Side machine, {
    required bool evaluate,
  }) async {
    final (before, after, move) = _replay(game, ply);
    if (move == null || after == null) return;
    final byCharacter = before.turn == machine;
    final captured = move is NormalMove
        ? before.board.roleAt(move.to) ??
              // En passant: o peão sai de outra casa.
              (before.board.roleAt(move.from) == Role.pawn &&
                      move.from.file != move.to.file
                  ? Role.pawn
                  : null)
        : null;
    final facts = MoveFacts(
      byCharacter: byCharacter,
      captured: captured?.name,
      promotion: move is NormalMove && move.promotion != null,
    );
    final evaluation = evaluate && GameRules.endOf(after) == null
        ? await _evaluation.evaluate(after, pov: machine)
        : null;
    final events = GameEvents.afterMove(
      memory: _memory,
      move: facts,
      evaluation: evaluation,
    );
    _memory = LinePicker.moved(GameEvents.remember(_memory, evaluation?.score));
    final emotion = EmotionRules.of(_memory);
    // Logo depois de uma fala, o retrato fica com a emoção dela; depois volta
    // a seguir o andamento da partida.
    final reacting = _memory.movesSinceLine < LinePicker.minMovesBetweenLines;
    if (!isClosed && !reacting && emotion != state.emotion) {
      emit(state.copyWith(emotion: emotion));
    }
    // No fim da partida, a fala é a do resultado.
    if (game.end == null || ply < game.ucis.length - 1) _say(events);
  }

  // A posição antes e depois do lance [ply] e o lance.
  (Position, Position?, Move?) _replay(FreeBoardState game, int ply) {
    var position = game.start;
    for (var index = 0; index <= ply; index++) {
      final move = Move.parse(game.ucis[index]);
      final played = move == null ? null : GameRules.play(position, move);
      if (played == null) return (position, null, null);
      if (index == ply) return (position, played.position, move);
      position = played.position;
    }
    return (position, null, null);
  }

  CharacterLine? _say(List<GameEvent> events) {
    if (isClosed || events.isEmpty || state.character == null) return null;
    final picked = LinePicker.pick(
      lines: _lines,
      events: events,
      memory: _memory,
      roll: _random.nextDouble(),
    );
    if (picked == null) return null;
    _memory = picked.memory;
    emit(state.copyWith(line: picked.line, emotion: picked.line.emotion));
    unawaited(_save());
    return picked.line;
  }

  CharacterLine? _lineById(String? id) {
    for (final line in _lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  Future<void> _save() async {
    final game = _game;
    if (game == null || state.character == null) return;
    await _talk.save(
      TalkSnapshot(
        gameStartedAt: game,
        plies: _plies,
        memory: _memory.copyWith(emotion: state.emotion),
        lineId: state.line?.id,
      ),
    );
  }
}
