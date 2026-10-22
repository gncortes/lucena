import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/home_suggestion.dart';

/// Os cartões da tela "Seu nível".
enum LevelChoice { beginner, test, band }

class LevelState {
  const LevelState({
    this.ready = false,
    this.level = RatingLevel.casual,
    this.levelChosen = false,
    this.placed,
    this.finished = false,
    this.viktor,
    this.texts = LessonTexts.empty,
    this.characters = const [],
  });

  final bool ready;

  /// A faixa marcada.
  final RatingLevel level;

  /// A pessoa escolheu uma faixa (ou "Não sei jogar"); sem isso, "Fazer o
  /// teste" fica marcado.
  final bool levelChosen;

  /// O rating que o teste de nível deu, se o jogador o fez e usou.
  final int? placed;

  /// A escolha foi gravada: a tela sai.
  final bool finished;
  final Character? viktor;
  final LessonTexts texts;

  /// Os personagens, para dizer o nome do adversário do degrau.
  final List<Character> characters;

  /// O personagem do degrau em que a Jornada começa. Nulo sem ele.
  Character? get startCharacter =>
      characters.forLevel(MaiaLevels.nearest(rating));

  /// "Fazer o teste" está marcado e o teste ainda não foi feito: "Continuar"
  /// abre o teste.
  bool get testPending => placed == null && choice == LevelChoice.test;

  /// O rating que vai para o perfil: o do teste ou o da faixa marcada.
  int get rating => placed ?? level.rating;

  /// O degrau em que a Jornada começa com a faixa marcada.
  String get startRung => '${MaiaLevels.nearest(rating)}';

  /// O cartão marcado. Antes de a pessoa escolher, "Fazer o teste" já vem
  /// marcado (decisão 7 do Gabriel).
  LevelChoice get choice {
    if (placed != null || !levelChosen) return LevelChoice.test;
    return level == RatingLevel.beginner
        ? LevelChoice.beginner
        : LevelChoice.band;
  }

  /// Marcou a faixa iniciante: a primeira abertura termina nas aulas.
  bool get toSchool => levelChosen && level == RatingLevel.beginner;

  LevelState copyWith({
    RatingLevel? level,
    bool? levelChosen,
    int? Function()? placed,
    bool? finished,
  }) => LevelState(
    ready: ready,
    level: level ?? this.level,
    levelChosen: levelChosen ?? this.levelChosen,
    placed: placed == null ? this.placed : placed(),
    finished: finished ?? this.finished,
    viktor: viktor,
    texts: texts,
    characters: characters,
  );
}

/// "Seu nível": o último passo da primeira abertura. A faixa vai para o
/// perfil, decide o degrau de início da Jornada e a sugestão da tela inicial;
/// só aqui o tour conta como visto.
class LevelCubit extends Cubit<LevelState> {
  LevelCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    required this._lessons,
    this._home,
  }) : super(const LevelState());

  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final LessonRepository _lessons;
  final HomeLayoutRepository? _home;
  Onboarding _saved = const Onboarding();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
  int _selectionRevision = 0;

  Future<void> load(String language) async {
    _saved = await _onboarding.load();
    final profile = await _profile.load();
    final characters = await _characters.characters();
    final texts = await _lessons.texts(language);
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == 'master') viktor = character;
    }
    final selected = _saved.selectedRating;
    emit(
      LevelState(
        ready: true,
        level: selected == null ? profile.level : RatingLevel.of(selected),
        levelChosen: selected != null,
        placed: _saved.byHand ? null : selected,
        viktor: viktor,
        texts: texts,
        characters: characters,
      ),
    );
  }

  /// Marca a faixa.
  Future<void> setLevel(RatingLevel level) async {
    if (!state.ready || state.finished || _finishing) return;
    _selectionRevision++;
    emit(state.copyWith(level: level, placed: () => null, levelChosen: true));
    await _save(
      _saved.copyWith(selectedRating: () => level.rating, byHand: true),
    );
  }

  /// Chamado só quando o teste volta com um resultado que a pessoa usou.
  Future<void> usePlacement() async {
    if (!state.ready || state.finished || _finishing) return;
    final revision = ++_selectionRevision;
    final profile = await _profile.load();
    if (isClosed ||
        state.finished ||
        _finishing ||
        revision != _selectionRevision) {
      return;
    }
    emit(
      state.copyWith(
        level: profile.level,
        placed: () => profile.rating,
        levelChosen: true,
      ),
    );
    await _save(
      _saved.copyWith(selectedRating: () => profile.rating, byHand: false),
    );
  }

  /// "Continuar" com o teste feito, uma faixa ou "Não sei jogar".
  Future<void> finish() async {
    if (!state.ready || state.finished || _finishing) return;
    _finishing = true;
    try {
      await _onboardingSaved;
      final profile = await _profile.load();
      await _profile.save(profile.copyWith(rating: state.rating));
      await _home?.save(HomeSuggestion.of(state.level));
      await _home?.markNoticeSeen();
      await _save(
        _saved.copyWith(
          done: true,
          step: 0,
          startRung: state.startRung,
          inProgress: false,
        ),
      );
      if (!isClosed) emit(state.copyWith(finished: true));
    } finally {
      _finishing = false;
    }
  }

  Future<void> _save(Onboarding onboarding) {
    _saved = onboarding;
    return _onboardingSaved = _onboardingSaved.then(
      (_) => _onboarding.save(onboarding),
    );
  }
}
