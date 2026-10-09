import 'package:dartchess/dartchess.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/endgames/endgame_lesson_repository.dart';
import '../../../data/repositories/endgames/endgame_progress_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/placement/placement_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/placement.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/use_cases/game_rules.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/placement_engine.dart';
import '../../../domain/use_cases/placement_roadmap.dart';
import 'roadmap_loader.dart';

/// Em que tela o teste está.
enum PlacementView { loading, intro, question, result }

/// O teste de nível na tela.
class PlacementViewState {
  const PlacementViewState({
    this.view = PlacementView.loading,
    this.test,
    this.item,
    this.result,
    this.skills,
    this.resuming = false,
    this.applied = false,
    this.fen,
    this.lastMove,
    this.turn = 0,
    this.selected = const {},
    this.viktor,
    this.roadmap,
    this.titles = const {},
  });

  /// O roteiro, no resultado (recalculado do progresso real).
  final PlacementRoadmap? roadmap;

  /// Os títulos das aulas do roteiro, pelo id.
  final Map<String, String> titles;

  /// O Viktor, que abre o teste e comenta o resultado.
  final Character? viktor;

  final PlacementView view;

  /// O teste em andamento (as respostas até aqui).
  final PlacementState? test;

  /// A pergunta na tela.
  final PlacementItem? item;

  /// O resultado, no fim.
  final PlacementResult? result;

  /// O mapa (os grupos e os nós do resultado).
  final SkillMap? skills;

  /// Havia um teste começado: a abertura oferece continuar.
  final bool resuming;

  /// O resultado já foi para o perfil (rating e degrau da Jornada).
  final bool applied;

  /// A posição na tela: a da pergunta e, numa sequência, depois dos lances.
  final String? fen;
  final Move? lastMove;

  /// Numa pergunta de lance: qual lance do jogador é o da vez (0 é o
  /// primeiro).
  final int turn;

  /// Numa pergunta de casas: as marcadas.
  final Set<String> selected;

  /// A pergunta na tela, de 1 a 20.
  int get number => test?.questionNumber ?? 1;

  PlacementViewState copyWith({
    PlacementView? view,
    PlacementState? test,
    PlacementItem? item,
    PlacementResult? result,
    SkillMap? skills,
    bool? resuming,
    bool? applied,
    String? fen,
    Move? lastMove,
    int? turn,
    Set<String>? selected,
    PlacementRoadmap? roadmap,
    Map<String, String>? titles,
  }) => PlacementViewState(
    viktor: viktor,
    roadmap: roadmap ?? this.roadmap,
    titles: titles ?? this.titles,
    fen: fen ?? this.fen,
    lastMove: lastMove ?? this.lastMove,
    turn: turn ?? this.turn,
    selected: selected ?? this.selected,
    view: view ?? this.view,
    test: test ?? this.test,
    item: item ?? this.item,
    result: result ?? this.result,
    skills: skills ?? this.skills,
    resuming: resuming ?? this.resuming,
    applied: applied ?? this.applied,
  );
}

/// O teste de nível (T52): 20 perguntas escolhidas pelo motor adaptativo,
/// gravadas a cada resposta (fechar o app volta na mesma pergunta), e o
/// resultado no fim: a faixa, o mapa do que o jogador domina e o roteiro.
class PlacementCubit extends Cubit<PlacementViewState> {
  PlacementCubit({
    required this._placement,
    required this._profile,
    required this._now,
    this._onboarding,
    this._characters,
    this.seed,
    this._school,
    this._schoolProgress,
    this._endgames,
    this._endgameProgress,
    this.language = 'en',
  }) : super(const PlacementViewState());

  final LessonRepository? _school;
  final SchoolProgressRepository? _schoolProgress;
  final EndgameLessonRepository? _endgames;
  final EndgameProgressRepository? _endgameProgress;

  /// O idioma dos títulos das aulas no roteiro.
  final String language;

  final PlacementRepository _placement;
  final ProfileRepository _profile;
  final Now _now;
  final OnboardingRepository? _onboarding;
  final CharacterRepository? _characters;

  /// A semente do sorteio das perguntas. Nula: a hora de começar (cada teste
  /// diferente); os testes de ponta a ponta fixam uma.
  final int? seed;

  PlacementEngine? _engine;

  // Quando a pergunta apareceu (o tempo de resposta).
  DateTime? _shownAt;

  /// Abre a abertura do teste, oferecendo continuar o que ficou pela metade.
  Future<void> load() async {
    final skills = await _placement.skills();
    final bank = await _placement.bank();
    _engine = PlacementEngine(skills: skills, bank: bank);
    final ongoing = await _placement.ongoing();
    Character? viktor;
    for (final character in await _characters?.characters() ?? const []) {
      if (character.id == 'master') viktor = character;
    }
    if (isClosed) return;
    emit(
      PlacementViewState(
        viktor: viktor,
        view: PlacementView.intro,
        skills: skills,
        test: ongoing,
        resuming: ongoing != null && ongoing.answered.isNotEmpty,
      ),
    );
  }

  /// Começa (ou continua) o teste.
  Future<void> start() async {
    final engine = _engine;
    if (engine == null) return;
    var test = state.test;
    if (test == null) {
      // Quem já escolheu uma faixa começa do meio dela.
      final profile = await _profile.load();
      test = engine.start(
        seed: seed ?? _now().millisecondsSinceEpoch,
        prior: profile.level,
      );
      await _placement.saveOngoing(test);
    }
    _show(test);
  }

  /// Recomeça do zero (na abertura, em vez de continuar).
  Future<void> restart() async {
    await _placement.clearOngoing();
    emit(
      PlacementViewState(
        view: PlacementView.intro,
        skills: state.skills,
        viktor: state.viktor,
      ),
    );
    await start();
  }

  /// A resposta à pergunta na tela: acertou, errou ou "não sei". Sem dizer
  /// se acertou (só no fim).
  Future<void> answer(PlacementOutcome outcome) async {
    final engine = _engine;
    final test = state.test;
    final item = state.item;
    if (engine == null || test == null || item == null) return;
    final shown = _shownAt;
    final elapsed = shown == null ? Duration.zero : _now().difference(shown);
    final next = engine.answer(test, item, outcome, elapsed: elapsed);
    await _placement.saveOngoing(next);
    if (isClosed) return;
    if (next.isFinished) {
      final result = engine.result(next, takenAt: _now());
      await _placement.saveResult(result);
      await _placement.clearOngoing();
      final (roadmap, titles) = await _roadmap(result);
      if (isClosed) return;
      emit(
        state.copyWith(
          view: PlacementView.result,
          test: next,
          result: result,
          roadmap: roadmap,
          titles: titles,
        ),
      );
      return;
    }
    _show(next);
  }

  /// Leva o resultado para o perfil: o rating vira o estimado (o Glicko
  /// ajusta rápido nas primeiras partidas) e a Jornada começa no degrau
  /// mais perto dele. [level], se o intervalo cruza duas faixas e o jogador
  /// escolheu uma.
  Future<void> apply({RatingLevel? level}) async {
    final result = state.result;
    if (result == null) return;
    final rating = level == null || level == result.level
        ? result.theta
        : level.rating;
    final profile = await _profile.load();
    await _profile.save(profile.copyWith(rating: rating));
    final onboarding = _onboarding;
    if (onboarding != null) {
      final saved = await onboarding.load();
      await onboarding.save(
        saved.copyWith(startRung: '${MaiaLevels.nearest(rating)}'),
      );
    }
    if (!isClosed) emit(state.copyWith(applied: true));
  }

  /// Pergunta de lance: o lance do jogador. Fora da linha, errou (sem
  /// dizer); certo, a máquina responde o lance da linha e, sem mais lances,
  /// acertou.
  Future<void> play(Move move) async {
    final item = state.item;
    final fen = state.fen;
    if (item == null || fen == null || item.type != PlacementItemType.move) {
      return;
    }
    final position = GameRules.fromFen(fen);
    final played = position == null ? null : GameRules.play(position, move);
    if (played == null) return;
    if (!item.acceptsMove(state.turn, move.uci)) {
      emit(state.copyWith(fen: played.position.fen, lastMove: move));
      await answer(PlacementOutcome.wrong);
      return;
    }
    final turn = state.turn + 1;
    if (turn >= item.playerMoves) {
      emit(state.copyWith(fen: played.position.fen, lastMove: move));
      await answer(PlacementOutcome.correct);
      return;
    }
    // A resposta da linha (o lance seguinte ao deste do jogador).
    final replyIndex = turn * 2 - 1;
    final reply = replyIndex < item.moves.length
        ? Move.parse(item.moves[replyIndex])
        : null;
    var after = played.position;
    if (reply != null) {
      final answered = GameRules.play(after, reply);
      if (answered != null) after = answered.position;
    }
    emit(state.copyWith(fen: after.fen, lastMove: reply ?? move, turn: turn));
  }

  /// Pergunta de casas: marca ou desmarca a casa.
  void toggleSquare(String square) {
    if (state.item?.type != PlacementItemType.squares) return;
    final selected = {...state.selected};
    if (!selected.remove(square)) selected.add(square);
    emit(state.copyWith(selected: selected));
  }

  /// Pergunta de casas: confirma as marcadas.
  Future<void> confirmSquares() async {
    final item = state.item;
    if (item == null) return;
    await answer(
      item.acceptsSquares(state.selected)
          ? PlacementOutcome.correct
          : PlacementOutcome.wrong,
    );
  }

  /// Pergunta de escolha: a opção escolhida.
  Future<void> choose(String option) async {
    final item = state.item;
    if (item == null) return;
    await answer(
      item.acceptsChoice(option)
          ? PlacementOutcome.correct
          : PlacementOutcome.wrong,
    );
  }

  // O roteiro do resultado, contra as aulas que existem e as já feitas.
  Future<(PlacementRoadmap?, Map<String, String>)> _roadmap(
    PlacementResult result,
  ) async {
    final school = _school;
    final endgames = _endgames;
    final schoolProgress = _schoolProgress;
    final endgameProgress = _endgameProgress;
    if (school == null ||
        endgames == null ||
        schoolProgress == null ||
        endgameProgress == null) {
      return (null, const <String, String>{});
    }
    final roadmap = await RoadmapLoader(
      placement: _placement,
      school: school,
      schoolProgress: schoolProgress,
      endgames: endgames,
      endgameProgress: endgameProgress,
    ).build(result);
    final schoolTexts = await school.texts(language);
    final endgameTexts = await endgames.texts(language);
    final titles = {
      for (final step in roadmap.steps)
        step.lessonId: _title(
          step.school ? schoolTexts : endgameTexts,
          step.lessonId,
        ),
    };
    return (roadmap, titles);
  }

  static String _title(LessonTexts texts, String id) => texts.lessonTitle(id);

  void _show(PlacementState test) {
    final item = _engine!.next(test);
    _shownAt = _now();
    // Cada pergunta começa limpa: a posição dela, nada marcado.
    emit(
      PlacementViewState(
        view: PlacementView.question,
        viktor: state.viktor,
        skills: state.skills,
        test: test,
        item: item,
        fen: item?.fen,
      ),
    );
  }
}
