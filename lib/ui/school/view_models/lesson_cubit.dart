import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/opponent/opponent_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/lesson_source.dart';
import '../../../data/repositories/settings/settings_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/lesson_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/think_timer.dart';
import '../../core/sound/game_sounds.dart';
import '../../../domain/models/game_sound.dart';
import '../../../domain/models/haptic_event.dart';
import '../../core/sound/game_haptics.dart';

/// Em que pé está o passo aberto.
enum StepPhase {
  /// O aluno lê (fala) ou joga (estrelas, lance, jogar).
  active,

  /// A máquina está respondendo.
  waiting,

  /// Cumprido: o botão leva ao próximo passo.
  done,

  /// Num passo de jogar, a posição acabou sem o objetivo (afogamento, empate
  /// ou mate no aluno): o botão tenta de novo.
  failed,
}

class LessonState {
  const LessonState({
    this.ready = false,
    this.missing = false,
    this.lesson,
    this.texts = LessonTexts.empty,
    this.viktor,
    this.step = 0,
    this.reached = 0,
    this.fen,
    this.lastMove,
    this.collected = const [],
    this.turn = 0,
    this.moves = const [],
    this.phase = StepPhase.active,
    this.speech,
    this.emotion = Emotion.calm,
    this.hint,
    this.result,
    this.finished = false,
    this.courseFinished = false,
    this.graduationPath = const [],
    this.finishedAt,
    this.lessonNumber = 0,
    this.lessonCount = 0,
    this.mistakes = 0,
    this.nextLesson,
    this.endgame = false,
    this.part,
    this.partNumber = 0,
    this.partCount = 0,
    this.nextPart,
    this.thinkStartedAt,
    this.thinkLeft,
    this.hintsShown = 0,
    this.demoMove = 0,
    this.demoPlaying = true,
    this.thinkMinutes = 0,
  });

  /// O tempo de pensar escolhido nas preferências, em minutos; 0: o
  /// recomendado por cada posição.
  final int thinkMinutes;

  /// O tempo de pensar no passo aberto.
  Duration get thinkTime => switch (current) {
    ThinkStep step when thinkMinutes == 0 => step.time,
    _ => Duration(minutes: thinkMinutes == 0 ? 3 : thinkMinutes),
  };

  final bool ready;

  /// A aula pedida não existe no curso.
  final bool missing;
  final Lesson? lesson;
  final LessonTexts texts;

  /// O professor. Nulo só se a ficha dele faltar.
  final Character? viktor;

  /// O índice do passo aberto.
  final int step;

  /// O passo mais adiante a que o aluno já chegou. Voltando para rever, os
  /// passos até ele podem ser pulados com "continuar", sem refazer o lance.
  final int reached;

  /// Está revendo um passo já passado.
  bool get reviewing => step < reached;

  /// "Continuar" vale: a fala, o passo cumprido ou um passo revisto.
  bool get canContinue =>
      current != null &&
      phase != StepPhase.waiting &&
      (phase == StepPhase.done ||
          reviewing ||
          (current is TalkStep && phase == StepPhase.active) ||
          // "Ver explicação": só depois do tempo de pensar.
          (current is ThinkStep && !thinking));

  /// Há passo antes deste para rever.
  bool get canGoBack => step > 0 && phase != StepPhase.waiting && !finished;

  /// O tabuleiro agora. Nulo num passo sem tabuleiro.
  final String? fen;
  final Move? lastMove;

  /// As estrelas já pegas no passo.
  final List<String> collected;

  /// A vez do aluno num passo de lance.
  final int turn;

  /// Os lances do passo de jogar, em UCI.
  final List<String> moves;
  final StepPhase phase;

  /// O que o Viktor está dizendo.
  final String? speech;
  final Emotion emotion;

  /// O lance que o mestre sugere (seta no tabuleiro).
  final Move? hint;

  /// Como acabou o passo de jogar.
  final PlayResult? result;

  /// A aula terminou: aparece o cartão de fim.
  final bool finished;

  /// Era a última aula do curso: a formatura.
  final bool courseFinished;

  /// Na formatura: os módulos da escola, em ordem (o caminho no diploma e na
  /// imagem de compartilhar).
  final List<CourseModule> graduationPath;

  /// Quando a aula foi concluída (a data do diploma, na formatura).
  final DateTime? finishedAt;

  /// A posição da aula no curso (1 é a primeira) e quantas há.
  final int lessonNumber;
  final int lessonCount;

  /// Lances errados no passo aberto (a tela sacode o tabuleiro a cada um).
  final int mistakes;

  /// Com a aula terminada, a próxima da trilha. Nula na última.
  final String? nextLesson;

  /// É a lição de uma aula de final: o fim volta para a aula, com os
  /// exercícios, em vez de seguir a trilha da escola.
  final bool endgame;

  /// A parte aberta (aula em partes, T51). Nula: a aula inteira.
  final LessonPart? part;

  /// A posição da parte na aula (1 é a primeira) e quantas há.
  final int partNumber;
  final int partCount;

  /// Com a parte terminada, a próxima recomendada. Nula com todas feitas.
  final String? nextPart;

  /// No passo de pensar: quando o aluno começou e quanto falta. [thinkLeft]
  /// nulo: o tempo acabou (ou o passo não é de pensar).
  final DateTime? thinkStartedAt;
  final Duration? thinkLeft;

  /// Quantas dicas do passo de pensar já apareceram.
  final int hintsShown;

  /// Na demonstração: quantos lances já foram jogados e se ela anda sozinha.
  final int demoMove;
  final bool demoPlaying;

  /// Ainda pensando no passo de pensar: sem dica e sem "Ver explicação".
  bool get thinking => current is ThinkStep && thinkLeft != null;

  /// No passo de pensar, há mais uma dica para mostrar.
  bool get canHint => switch (current) {
    ThinkStep(:final hints) => !thinking && hintsShown < hints,
    _ => false,
  };

  /// As setas do momento: as do passo de pensar depois do tempo, as do
  /// lance da demonstração, ou as de uma fala.
  List<(String, String)> get arrows => switch (current) {
    TalkStep(:final arrows) => arrows,
    ThinkStep(:final arrows) when hintsShown > 0 => arrows,
    DemoStep(:final line) when demoMove > 0 => line[demoMove - 1].arrows,
    _ => const [],
  };

  List<String> get marks => switch (current) {
    TalkStep(:final marks) => marks,
    ThinkStep(:final marks) when hintsShown > 0 => marks,
    DemoStep(:final line) when demoMove > 0 => line[demoMove - 1].marks,
    _ => const [],
  };

  LessonStep? get current {
    final steps = lesson?.steps;
    if (steps == null || step >= steps.length) return null;
    return steps[step];
  }

  int get stepCount => lesson?.steps.length ?? 0;

  /// Quanto da aula já foi feito, de 0 a 1 (o passo cumprido conta inteiro).
  double get progress {
    if (stepCount == 0) return 0;
    if (finished) return 1;
    if (phase == StepPhase.done) return (step + 1) / stepCount;
    // Dentro do passo, cada estrela pega e cada lance certo já enchem a barra.
    final within = switch (current) {
      StarsStep(:final stars) => collected.length / stars.length,
      TapStep(:final targets) => collected.length / targets.length,
      MoveStep(:final line) => turn / line.length,
      DemoStep(:final line) => demoMove / line.length,
      _ => 0.0,
    };
    return (step + within) / stepCount;
  }

  /// O aluno pode mexer no tabuleiro (no passo de tocar, só tocar).
  bool get interactive =>
      phase == StepPhase.active &&
      current is! TalkStep &&
      current is! TapStep &&
      current is! DemoStep &&
      current != null;

  /// No passo de tocar, a casa que o Viktor pediu agora. Nula fora dele.
  String? get tapTarget => switch (current) {
    TapStep(:final targets)
        when phase == StepPhase.active && collected.length < targets.length =>
      targets[collected.length],
    _ => null,
  };

  /// As estrelas que faltam.
  List<String> get stars => switch (current) {
    StarsStep(:final stars) => [
      for (final star in stars)
        if (!collected.contains(star)) star,
    ],
    _ => const [],
  };

  LessonState copyWith({
    bool? ready,
    bool? missing,
    Lesson? lesson,
    LessonTexts? texts,
    Character? viktor,
    int? step,
    int? reached,
    String? fen,
    bool clearFen = false,
    Move? lastMove,
    bool clearLastMove = false,
    List<String>? collected,
    int? turn,
    List<String>? moves,
    StepPhase? phase,
    String? speech,
    Emotion? emotion,
    Move? hint,
    bool clearHint = false,
    PlayResult? result,
    bool clearResult = false,
    bool? finished,
    bool? courseFinished,
    List<CourseModule>? graduationPath,
    DateTime? finishedAt,
    int? lessonNumber,
    int? lessonCount,
    int? mistakes,
    String? nextLesson,
    bool? endgame,
    LessonPart? part,
    int? partNumber,
    int? partCount,
    String? nextPart,
    DateTime? thinkStartedAt,
    Duration? thinkLeft,
    bool clearThinkLeft = false,
    int? hintsShown,
    int? demoMove,
    bool? demoPlaying,
    int? thinkMinutes,
  }) => LessonState(
    ready: ready ?? this.ready,
    missing: missing ?? this.missing,
    lesson: lesson ?? this.lesson,
    texts: texts ?? this.texts,
    viktor: viktor ?? this.viktor,
    step: step ?? this.step,
    reached: reached ?? this.reached,
    fen: clearFen ? null : fen ?? this.fen,
    lastMove: clearLastMove ? null : lastMove ?? this.lastMove,
    collected: collected ?? this.collected,
    turn: turn ?? this.turn,
    moves: moves ?? this.moves,
    phase: phase ?? this.phase,
    speech: speech ?? this.speech,
    emotion: emotion ?? this.emotion,
    hint: clearHint ? null : hint ?? this.hint,
    result: clearResult ? null : result ?? this.result,
    finished: finished ?? this.finished,
    courseFinished: courseFinished ?? this.courseFinished,
    graduationPath: graduationPath ?? this.graduationPath,
    finishedAt: finishedAt ?? this.finishedAt,
    lessonNumber: lessonNumber ?? this.lessonNumber,
    lessonCount: lessonCount ?? this.lessonCount,
    mistakes: mistakes ?? this.mistakes,
    nextLesson: nextLesson ?? this.nextLesson,
    endgame: endgame ?? this.endgame,
    part: part ?? this.part,
    partNumber: partNumber ?? this.partNumber,
    partCount: partCount ?? this.partCount,
    nextPart: nextPart ?? this.nextPart,
    thinkStartedAt: thinkStartedAt ?? this.thinkStartedAt,
    thinkLeft: clearThinkLeft ? null : thinkLeft ?? this.thinkLeft,
    hintsShown: hintsShown ?? this.hintsShown,
    demoMove: demoMove ?? this.demoMove,
    demoPlaying: demoPlaying ?? this.demoPlaying,
    thinkMinutes: thinkMinutes ?? this.thinkMinutes,
  );
}

/// Uma aula com o Viktor: ele fala a cada passo, o aluno joga no tabuleiro e
/// cada mudança é gravada (o app fechado à força volta no mesmo passo, com o
/// mesmo tabuleiro).
class LessonCubit extends Cubit<LessonState> {
  /// Com [source], a aula vem de lá (a trilha de finais); sem ela, da escola
  /// ([lessons] e [progress]).
  LessonCubit({
    LessonRepository? lessons,
    SchoolProgressRepository? progress,
    LessonSource? source,
    required this._characters,
    required this._opponent,
    this._sounds,
    this._haptics,
    this._now = const SystemNow(),
    this._settings,
    this.replyDelay = const Duration(milliseconds: 450),
  }) : _source = source ?? SchoolLessonSource(lessons!, progress!),
       super(const LessonState());

  final LessonSource _source;
  final Now _now;

  // As preferências, para o tempo de pensar; nulas: 3 minutos.
  final SettingsRepository? _settings;
  final CharacterRepository _characters;
  final OpponentRepository _opponent;

  // Os sons do jogo; nulo: a lição fica muda.
  final GameSounds? _sounds;

  // A vibração; nula: sem retorno tátil.
  final GameHaptics? _haptics;

  /// A pausa antes da resposta combinada do outro lado, para o aluno ver o
  /// próprio lance antes.
  final Duration replyDelay;

  /// Quanto a máquina pensa em cada lance (e na dica).
  static const thinkTime = Duration(milliseconds: 400);

  // Contadores das falas de incentivo: cada vez sai a próxima da lista.
  final _said = <String, int>{};

  /// Abre a aula [lessonId]. Numa aula em partes, abre a parte [part] (ou a
  /// do passo guardado, ou a primeira): a lição toca só os passos dela.
  Future<void> load(String lessonId, String language, {String? part}) async {
    final full = await _source.lesson(lessonId);
    final texts = await _source.texts(language);
    final characters = await _characters.characters();
    var saved = await _source.checkpoint();
    final (number, count) = await _source.placeOf(lessonId);
    final thinkMinutes = (await _settings?.load())?.thinkMinutes ?? 0;
    if (isClosed) return;
    if (full == null || full.steps.isEmpty) {
      emit(const LessonState(ready: true, missing: true));
      return;
    }
    if (saved != null && saved.lessonId != lessonId) saved = null;
    LessonPart? opened;
    var lesson = full;
    if (full.parts.isNotEmpty) {
      // Checkpoint de antes das partes: o passo contava na aula inteira.
      if (saved != null && saved.part == null) {
        final located = full.locate(saved.step);
        saved = located == null
            ? null
            : LessonCheckpoint(
                lessonId: saved.lessonId,
                step: located.$2,
                fen: saved.fen,
                collected: saved.collected,
                turn: saved.turn,
                moves: saved.moves,
                open: saved.open,
                part: located.$1.id,
              );
      }
      opened =
          full.part(part ?? '') ??
          full.part(saved?.part ?? '') ??
          full.parts.first;
      if (saved?.part != opened.id) saved = null;
      lesson = full.only(opened);
    }
    Character? viktor;
    for (final character in characters) {
      if (character.id == viktorId) viktor = character;
    }
    final base = LessonState(
      ready: true,
      lesson: lesson,
      texts: texts,
      viktor: viktor,
      lessonNumber: number,
      lessonCount: count,
      endgame: _source.endgame,
      part: opened,
      partNumber: opened == null ? 0 : full.parts.indexOf(opened) + 1,
      partCount: full.parts.length,
      thinkMinutes: thinkMinutes,
    );
    if (saved != null && saved.step < lesson.steps.length) {
      emit(_restore(base, saved));
    } else {
      emit(_open(base, 0));
    }
    await _save();
  }

  /// O id do Viktor nas fichas dos personagens.
  static const viktorId = 'master';

  /// "Continuar": passa da fala, ou do passo cumprido, para o próximo; no
  /// último, conclui a aula.
  Future<void> next() async {
    if (!state.canContinue) return;
    final nextStep = state.step + 1;
    if (nextStep < state.stepCount) {
      emit(_open(state, nextStep));
      await _save();
      return;
    }
    await _finish();
  }

  /// Volta um passo, para rever: ele abre do começo (dá para jogar de
  /// novo ou seguir com "continuar").
  Future<void> back() async {
    if (!state.canGoBack) return;
    emit(_open(state, state.step - 1));
    await _save();
  }

  /// Tenta de novo o passo de jogar, do começo.
  Future<void> retry() async {
    if (state.current is! PlayStep) return;
    emit(
      _open(
        state,
        state.step,
      ).copyWith(speech: _pick('coach.retry'), emotion: Emotion.focused),
    );
    await _save();
  }

  /// Sai da aula pelo voltar: o passo fica guardado, mas o app não reabre
  /// nela.
  Future<void> leave() async {
    if (state.finished) return;
    await _source.leave();
  }

  /// O aluno moveu uma peça no tabuleiro.
  Future<void> play(Move move) async {
    if (!state.interactive) return;
    switch (state.current) {
      case StarsStep step:
        await _playStar(step, move);
      case MoveStep step:
        await _playLine(step, move);
      case PlayStep step:
        await _playOut(step, move);
      case ThinkStep():
        await _playThink(move);
      case TalkStep() || TapStep() || DemoStep() || null:
        return;
    }
  }

  // --- pensar (T51) --------------------------------------------------------

  /// O relógio do passo de pensar: a tela chama a cada segundo. No fim do
  /// tempo, o Viktor faz a pergunta-guia do passo; as dicas vêm a pedido.
  /// O aluno escolheu agora o tempo de pensar: o passo de pensar recomeça
  /// com ele (o relógio e a fala "pense por N minutos").
  void useThinkMinutes(int minutes) {
    if (isClosed || state.lesson == null) return;
    final base = state.copyWith(thinkMinutes: minutes);
    emit(
      state.current is ThinkStep && state.thinking
          ? _open(base, state.step)
          : base,
    );
  }

  Future<void> tick() async {
    final step = state.current;
    final startedAt = state.thinkStartedAt;
    if (step is! ThinkStep || startedAt == null || state.finished) return;
    if (!state.thinking) return;
    switch (ThinkTimer.phase(
      startedAt: startedAt,
      time: state.thinkTime,
      now: _now(),
    )) {
      case Thinking(:final remaining):
        emit(state.copyWith(thinkLeft: remaining));
      case ThinkExpired():
        emit(
          state.copyWith(
            clearThinkLeft: true,
            speech: state.texts.step(_lessonId, step.id),
            emotion: Emotion.focused,
          ),
        );
        await _save();
    }
  }

  /// Pular o tempo de pensar e ir direto à explicação.
  Future<void> skipThink() async {
    if (!state.thinking) return;
    await _explain();
  }

  Future<void> _explain() async {
    final nextStep = state.step + 1;
    if (nextStep < state.stepCount) {
      emit(_open(state, nextStep));
      await _save();
      return;
    }
    await _finish();
  }

  /// "Mais uma dica", depois do tempo de pensar.
  Future<void> moreHint() async {
    final step = state.current;
    if (step is! ThinkStep || !state.canHint) return;
    final shown = state.hintsShown + 1;
    emit(
      state.copyWith(
        hintsShown: shown,
        speech: state.texts.thinkHint(_lessonId, step.id, shown),
        emotion: Emotion.focused,
      ),
    );
    await _save();
  }

  /// "Voltar à posição": o tabuleiro do passo de pensar de novo.
  void resetThink() {
    final step = state.current;
    if (step is! ThinkStep) return;
    emit(state.copyWith(fen: step.fen, clearLastMove: true));
  }

  // No passo de pensar, o aluno joga a ideia dele: o lance já responde à
  // pergunta, então o relógio some e a explicação vem logo, sem esperar o
  // tempo. Depois do tempo (ou com o relógio já parado) ele ainda testa
  // ideias à vontade, sem certo nem errado.
  Future<void> _playThink(Move move) async {
    final position = _position();
    if (position == null) return;
    final played = GameRules.play(position, move);
    if (played == null) return;
    final explainNow = state.thinking;
    final stepIndex = state.step;
    unawaited(_sounds?.move(played.san));
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        clearThinkLeft: explainNow,
      ),
    );
    if (!explainNow) return;
    // Uma pausa para o aluno ver o próprio lance antes da explicação.
    await Future<void>.delayed(replyDelay);
    if (isClosed || state.step != stepIndex) return;
    await _explain();
  }

  // --- demonstração (T51) -------------------------------------------------

  /// O próximo lance da demonstração (a tela chama no ritmo da fala, ou o
  /// aluno avança na mão): ela volta a andar sozinha.
  Future<void> demoForward() async {
    final step = state.current;
    if (step is! DemoStep || state.demoMove >= step.line.length) return;
    emit(_demoAt(state.copyWith(demoPlaying: true), step, state.demoMove + 1));
    await _save();
  }

  /// Volta um lance: desfaz no tabuleiro e mostra a fala daquele ponto.
  Future<void> demoBack() async {
    final step = state.current;
    if (step is! DemoStep || state.demoMove == 0) return;
    emit(_demoAt(state, step, state.demoMove - 1).copyWith(demoPlaying: false));
    await _save();
  }

  /// Repete a demonstração do começo.
  Future<void> demoReplay() async {
    final step = state.current;
    if (step is! DemoStep) return;
    emit(_demoAt(state, step, 0).copyWith(demoPlaying: true));
    await _save();
  }

  /// A demonstração depois de [count] lances: o tabuleiro, o último lance e
  /// a fala dele (zero: a fala de abertura).
  LessonState _demoAt(LessonState base, DemoStep step, int count) {
    var position = GameRules.fromFen(step.fen);
    Move? last;
    for (final move in step.line.take(count)) {
      final parsed = Move.parse(move.uci);
      final played = position == null || parsed == null
          ? null
          : GameRules.play(position, parsed);
      if (played == null) break;
      position = played.position;
      last = parsed;
      if (count == base.demoMove + 1 && move == step.line[count - 1]) {
        unawaited(_sounds?.move(played.san));
      }
    }
    final done = count >= step.line.length;
    return LessonState(
      ready: true,
      lesson: base.lesson,
      texts: base.texts,
      viktor: base.viktor,
      lessonNumber: base.lessonNumber,
      lessonCount: base.lessonCount,
      endgame: base.endgame,
      part: base.part,
      partNumber: base.partNumber,
      partCount: base.partCount,
      thinkMinutes: base.thinkMinutes,
      step: base.step,
      reached: base.reached,
      fen: position?.fen ?? step.fen,
      lastMove: last,
      demoMove: count,
      demoPlaying: base.demoPlaying && !done,
      phase: done ? StepPhase.done : StepPhase.active,
      speech: count == 0
          ? base.texts.step(_lessonId, step.id)
          : base.texts.demoMove(_lessonId, step.id, count),
      emotion: done ? Emotion.happy : Emotion.calm,
    );
  }

  /// O aluno tocou numa casa (no passo de tocar): certa, vai para a
  /// próxima; errada, o Viktor dá a dica.
  Future<void> tap(String square) async {
    final step = state.current;
    final target = state.tapTarget;
    if (step is! TapStep || target == null) return;
    if (square != target) {
      emit(
        state.copyWith(
          speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.hint'),
          emotion: Emotion.focused,
        ),
      );
      return;
    }
    unawaited(_sounds?.play(GameSound.move));
    unawaited(_haptics?.play(HapticEvent.selection));
    final collected = [...state.collected, square];
    final allDone = collected.length >= step.targets.length;
    emit(
      state.copyWith(
        collected: collected,
        phase: allDone ? StepPhase.done : StepPhase.active,
        speech: allDone
            ? state.texts.done(_lessonId, step.id) ?? _pick('coach.praise')
            : _pick('coach.star'),
        emotion: allDone ? Emotion.happy : Emotion.calm,
      ),
    );
    await _save();
  }

  /// Pede ao mestre o melhor lance (vira uma seta no tabuleiro).
  Future<void> askHint() async {
    final current = state.current;
    if (!state.interactive) return;
    switch (current) {
      case MoveStep step:
        final accepted = step.line[state.turn].accept.first;
        emit(
          state.copyWith(
            hint: Move.parse(accepted),
            speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
      case PlayStep():
        final position = _position();
        if (position == null) return;
        final fen = state.fen;
        final move = await _opponent.pickMove(position, thinkTime: thinkTime);
        if (isClosed || state.fen != fen || move == null) return;
        emit(
          state.copyWith(
            hint: move,
            speech: _pick('coach.hint'),
            emotion: Emotion.focused,
          ),
        );
      case StarsStep() || TalkStep() || TapStep() || ThinkStep() || null:
        return;
      case DemoStep():
        return;
    }
  }

  Future<void> _playStar(StarsStep step, Move move) async {
    if (move is! NormalMove) return;
    final board = LessonRules.starsBoard(state.fen!);
    final moved = LessonRules.moveStar(board, step.side, move.from, move.to);
    if (moved == null) return;
    unawaited(_sounds?.play(GameSound.move));
    final star = move.to.name;
    final collected = [
      ...state.collected,
      if (step.stars.contains(star) && !state.collected.contains(star)) star,
    ];
    final fen = LessonRules.starsFen(moved, step.side);
    final allDone = step.stars.every(collected.contains);
    emit(
      state.copyWith(
        fen: fen,
        lastMove: move,
        collected: collected,
        clearHint: true,
        phase: allDone ? StepPhase.done : StepPhase.active,
        speech: allDone
            ? state.texts.done(_lessonId, step.id) ?? _pick('coach.praise')
            : collected.length > state.collected.length
            ? _pick('coach.star')
            : state.speech,
        emotion: allDone ? Emotion.happy : state.emotion,
      ),
    );
    await _save();
  }

  Future<void> _playLine(MoveStep step, Move move) async {
    final position = _position();
    if (position == null) return;
    if (!LessonRules.accepts(step, state.turn, move.uci)) {
      // A peça volta: a tela redesenha o tabuleiro a cada estado novo. No
      // segundo erro, o mestre já mostra a seta.
      final mistakes = state.mistakes + 1;
      emit(
        state.copyWith(
          speech: state.texts.hint(_lessonId, step.id) ?? _pick('coach.wrong'),
          emotion: Emotion.focused,
          hint: mistakes >= 2
              ? Move.parse(step.line[state.turn].accept.first)
              : null,
          clearHint: mistakes < 2,
          mistakes: mistakes,
        ),
      );
      return;
    }
    final played = GameRules.play(position, move);
    if (played == null) return;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    final turn = step.line[state.turn];
    final ends = LessonRules.endsLine(step, state.turn, move.uci);
    if (ends) {
      emit(
        state.copyWith(
          fen: played.position.fen,
          lastMove: move,
          turn: state.turn + 1,
          clearHint: true,
          phase: StepPhase.done,
          speech: state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
          emotion: Emotion.happy,
        ),
      );
      await _save();
      return;
    }
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        clearHint: true,
        phase: turn.reply == null ? StepPhase.active : StepPhase.waiting,
        speech: _pick('coach.good'),
        emotion: Emotion.happy,
      ),
    );
    final reply = Move.parse(turn.reply ?? '');
    var after = played.position;
    if (reply != null) {
      await Future<void>.delayed(replyDelay);
      if (isClosed) return;
      final answered = GameRules.play(after, reply);
      if (answered == null) {
        // A resposta combinada não cabe no tabuleiro (aula com dado
        // inconsistente): o passo acaba aqui, cumprido.
        emit(
          state.copyWith(
            turn: step.line.length,
            phase: StepPhase.done,
            speech:
                state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
            emotion: Emotion.happy,
          ),
        );
        await _save();
        return;
      }
      unawaited(_sounds?.move(answered.san));
      after = answered.position;
    }
    emit(
      state.copyWith(
        fen: after.fen,
        lastMove: reply ?? move,
        turn: state.turn + 1,
        phase: StepPhase.active,
      ),
    );
    await _save();
  }

  Future<void> _playOut(PlayStep step, Move move) async {
    final position = _position();
    if (position == null) return;
    final played = GameRules.play(position, move);
    if (played == null) return;
    unawaited(_sounds?.move(played.san));
    unawaited(_haptics?.move(played.san));
    var moves = [...state.moves, move.uci];
    final start = GameRules.fromFen(step.fen)!;
    var result = LessonRules.resultOf(
      played.position,
      goal: step.goal,
      student: step.side,
      lastMove: move,
      repetitions: GameRules.repetitionsOf(start, moves),
      studentMoves: (moves.length + 1) ~/ 2,
    );
    final userMoves = (moves.length + 1) ~/ 2;
    emit(
      state.copyWith(
        fen: played.position.fen,
        lastMove: move,
        moves: moves,
        clearHint: true,
        phase: result == PlayResult.ongoing ? StepPhase.waiting : null,
        speech: result == PlayResult.ongoing && userMoves % 3 == 0
            ? _tip(step)
            : null,
        emotion: result == PlayResult.ongoing ? Emotion.focused : null,
      ),
    );
    if (result != PlayResult.ongoing) {
      await _endPlay(step, result);
      return;
    }
    await _save();
    final reply = await _opponent.pickMove(
      played.position,
      thinkTime: thinkTime,
      kind: step.opponent.kind,
      level: step.opponent.level,
      history: [start],
    );
    if (isClosed || state.fen != played.position.fen) return;
    final answered = reply == null
        ? null
        : GameRules.play(played.position, reply);
    if (answered == null) {
      emit(state.copyWith(phase: StepPhase.active));
      return;
    }
    unawaited(_sounds?.move(answered.san));
    moves = [...moves, reply!.uci];
    result = LessonRules.resultOf(
      answered.position,
      goal: step.goal,
      student: step.side,
      lastMove: reply,
      repetitions: GameRules.repetitionsOf(start, moves),
      studentMoves: (moves.length + 1) ~/ 2,
    );
    emit(
      state.copyWith(
        fen: answered.position.fen,
        lastMove: reply,
        moves: moves,
        phase: StepPhase.active,
      ),
    );
    if (result != PlayResult.ongoing) {
      await _endPlay(step, result);
      return;
    }
    await _save();
  }

  Future<void> _endPlay(PlayStep step, PlayResult result) async {
    final success = result == PlayResult.success;
    emit(
      state.copyWith(
        phase: success ? StepPhase.done : StepPhase.failed,
        result: result,
        speech: switch (result) {
          PlayResult.success =>
            state.texts.done(_lessonId, step.id) ?? _pick('coach.praise'),
          PlayResult.stalemate => _pick('coach.stalemate'),
          PlayResult.lost => _pick('coach.lost'),
          PlayResult.draw || PlayResult.ongoing => _pick('coach.draw'),
        },
        emotion: switch (result) {
          PlayResult.success => Emotion.happy,
          PlayResult.stalemate => Emotion.surprised,
          _ => Emotion.calm,
        },
      ),
    );
    await _save();
  }

  Future<void> _finish() async {
    final lesson = state.lesson!;
    final part = state.part;
    if (part != null) {
      // Parte concluída: o cartão "Parte N concluída" com a próxima.
      final outcome = await _source.completePart(lesson.id, part.id);
      if (isClosed) return;
      unawaited(_haptics?.play(HapticEvent.success));
      emit(
        state.copyWith(
          finished: true,
          nextPart: outcome.nextPart,
          speech: _pick('coach.partDone') ?? _pick('coach.lessonDone'),
          emotion: Emotion.confident,
        ),
      );
      return;
    }
    final outcome = await _source.complete(lesson.id);
    if (isClosed) return;
    // A formatura é só da escola: na trilha de finais, a última lição
    // termina como as outras.
    final courseFinished = outcome.last && !state.endgame;
    unawaited(
      _haptics?.play(
        courseFinished ? HapticEvent.celebrate : HapticEvent.success,
      ),
    );
    emit(
      state.copyWith(
        finished: true,
        courseFinished: courseFinished,
        graduationPath: courseFinished ? outcome.path : const [],
        finishedAt: _now(),
        nextLesson: outcome.next,
        speech: courseFinished
            ? _pick('coach.graduation')
            : _pick('coach.lessonDone'),
        emotion: Emotion.confident,
      ),
    );
  }

  /// O passo [index] do começo, com a fala de abertura dele.
  LessonState _open(LessonState base, int index) {
    final step = base.lesson!.steps[index];
    final lessonId = base.lesson!.id;
    return LessonState(
      ready: true,
      lesson: base.lesson,
      texts: base.texts,
      viktor: base.viktor,
      lessonNumber: base.lessonNumber,
      lessonCount: base.lessonCount,
      endgame: base.endgame,
      part: base.part,
      partNumber: base.partNumber,
      partCount: base.partCount,
      step: index,
      reached: index > base.reached ? index : base.reached,
      fen: step.fen,
      speech: base.texts.step(lessonId, step.id),
      emotion: index == 0 ? Emotion.happy : Emotion.calm,
      // O tempo de pensar começa ao abrir o passo.
      thinkStartedAt: step is ThinkStep ? _now() : null,
      thinkLeft: step is ThinkStep
          ? (base.thinkMinutes == 0
                ? step.time
                : Duration(minutes: base.thinkMinutes))
          : null,
      thinkMinutes: base.thinkMinutes,
    );
  }

  /// O passo guardado, com o tabuleiro de quando o app fechou.
  LessonState _restore(LessonState base, LessonCheckpoint saved) {
    final opened = _open(base, saved.step);
    final step = opened.current!;
    var restored = opened.copyWith(
      collected: saved.collected,
      turn: saved.turn,
      moves: saved.moves,
    );
    switch (step) {
      case PlayStep():
        var position = GameRules.fromFen(step.fen);
        Move? last;
        for (final uci in saved.moves) {
          final move = Move.parse(uci);
          final played = position == null || move == null
              ? null
              : GameRules.play(position, move);
          if (played == null) break;
          position = played.position;
          last = move;
        }
        if (position != null) {
          restored = restored.copyWith(fen: position.fen, lastMove: last);
          final result = LessonRules.resultOf(
            position,
            goal: step.goal,
            student: step.side,
            lastMove: last,
            repetitions: GameRules.repetitionsOf(
              GameRules.fromFen(step.fen)!,
              saved.moves,
            ),
          );
          if (result != PlayResult.ongoing) {
            restored = restored.copyWith(
              result: result,
              phase: result == PlayResult.success
                  ? StepPhase.done
                  : StepPhase.failed,
            );
          }
        }
      case StarsStep(:final stars):
        restored = restored.copyWith(
          fen: saved.fen,
          phase: stars.every(saved.collected.contains)
              ? StepPhase.done
              : StepPhase.active,
        );
      case MoveStep(:final line):
        restored = restored.copyWith(
          fen: saved.fen,
          phase: saved.turn >= line.length ? StepPhase.done : StepPhase.active,
        );
      case TapStep(:final targets):
        restored = restored.copyWith(
          phase: saved.collected.length >= targets.length
              ? StepPhase.done
              : StepPhase.active,
        );
      case ThinkStep():
        // O tempo conta desde o começo, mesmo com o app fechado no meio.
        final startedAt = saved.thinkStartedAt ?? _now();
        final phase = ThinkTimer.phase(
          startedAt: startedAt,
          time: opened.thinkTime,
          now: _now(),
        );
        final left = phase is Thinking ? phase.remaining : null;
        final hints = saved.hintsShown;
        restored = restored.copyWith(
          fen: saved.fen,
          thinkStartedAt: startedAt,
          thinkLeft: left,
          clearThinkLeft: left == null,
          hintsShown: hints,
          speech: hints == 0
              ? base.texts.step(base.lesson!.id, step.id)
              : base.texts.thinkHint(base.lesson!.id, step.id, hints),
        );
      case DemoStep():
        // Volta parada no lance em que estava: o aluno decide quando seguir.
        restored = _demoAt(
          restored.copyWith(demoPlaying: false),
          step,
          saved.demoMove,
        );
      case TalkStep():
        break;
    }
    // Passo já cumprido: o Viktor volta dizendo o que disse ao cumprir.
    if (restored.phase == StepPhase.done) {
      final done = base.texts.done(base.lesson!.id, step.id);
      if (done != null) restored = restored.copyWith(speech: done);
    }
    return restored;
  }

  Future<void> _save() async {
    final lesson = state.lesson;
    if (lesson == null || state.finished) return;
    await _source.saveCheckpoint(
      LessonCheckpoint(
        lessonId: lesson.id,
        step: state.step,
        fen: state.fen,
        collected: state.collected,
        turn: state.turn,
        moves: state.moves,
        part: state.part?.id,
        thinkStartedAt: state.thinkStartedAt,
        hintsShown: state.hintsShown,
        demoMove: state.demoMove,
      ),
    );
  }

  Position? _position() {
    final fen = state.fen;
    return fen == null ? null : GameRules.fromFen(fen);
  }

  String get _lessonId => state.lesson!.id;

  /// Uma dica da aula para o meio da partida, ou um incentivo.
  String? _tip(PlayStep step) {
    final key = '$_lessonId.${step.id}.tips';
    if (state.texts.all(key).isNotEmpty) return _pick(key);
    return _pick('coach.keepGoing');
  }

  /// A próxima fala da lista [key], dando a volta.
  String? _pick(String key) {
    final index = _said[key] ?? 0;
    _said[key] = index + 1;
    return state.texts.say(key, index);
  }
}
