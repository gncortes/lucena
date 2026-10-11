import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Os passos do tour, na ordem. Primeiro a voz do Viktor e a dos
/// adversários; depois as boas-vindas, a aparência do app e do tabuleiro e a
/// pergunta do som; no fim, o nível e o que o jogador quer fazer no app.
enum TourStep {
  /// A voz do Viktor (ou "sem voz"). Some sem voz no idioma.
  voice,

  /// As vozes dos adversários. Some sem voz no idioma ou com a voz
  /// desligada.
  characterVoices,
  goal,
  theme,
  board,
  sound,
  rating,
  journey,
  endgames,
  opponents,
  speedrun,
  records,
  level,

  /// O que o jogador quer fazer no Lucena: os caminhos da tela inicial.
  goals;

  bool get isLast => this == TourStep.goals;
}

class TourState {
  const TourState({
    this.ready = false,
    this.step = TourStep.voice,
    this.first = TourStep.voice,
    this.level = RatingLevel.casual,
    this.nickname = '',
    this.finished = false,
    this.forward = true,
    this.viktor,
    this.texts = LessonTexts.empty,
    this.goals = const {},
    this.characters = const [],
    this.byHand = false,
    this.placed,
    this.levelChosen = false,
  });

  /// No passo do nível: o jogador preferiu escolher a faixa na mão (a lista
  /// das seis aparece no lugar do cartão do teste).
  final bool byHand;
  final bool levelChosen;

  bool get canAdvance => step.index < TourStep.level.index || levelChosen;

  /// O rating que o teste de nível deu, se o jogador o fez e usou.
  final int? placed;

  /// Os personagens, para as demonstrações dos passos.
  final List<Character> characters;

  final bool ready;
  final TourStep step;

  /// O primeiro passo que aparece (sem voz no idioma, os da voz somem).
  final TourStep first;

  /// Há passo antes deste.
  bool get hasPrevious => step.index > first.index;

  /// O último passo foi para a frente (a transição desliza nesse sentido).
  final bool forward;

  /// O Viktor conduz o tour. Nulo só se a ficha dele faltar.
  final Character? viktor;
  final LessonTexts texts;

  /// A faixa marcada no passo do nível.
  final RatingLevel level;

  /// Os caminhos marcados no último passo. Começam pela sugestão do nível.
  final Set<HomePath> goals;

  /// Os cinco caminhos, na ordem da sugestão do nível.
  List<HomePath> get paths => HomeSuggestion.of(level).order;

  /// O nome dado no primeiro passo (o apelido do perfil). Vazio: o padrão.
  final String nickname;

  /// O tour terminou (ou foi pulado): a tela sai.
  final bool finished;

  /// O degrau em que a Jornada começa com a faixa marcada.
  String get startRung => '${MaiaLevels.nearest(rating)}';

  /// O rating que vai para o perfil: o do teste ou o da faixa marcada.
  int get rating => placed ?? level.rating;

  /// Marcou "iniciante" e quer aprender: o tour termina nas aulas do
  /// Viktor.
  bool get toSchool =>
      level == RatingLevel.beginner && goals.contains(HomePath.learn);

  /// O que o Viktor diz no passo aberto.
  String? get speech {
    if (step == TourStep.level && !byHand && placed == null) {
      return texts.say('tour.level.test') ?? texts.say('tour.level');
    }
    if (step == TourStep.goals && placed != null) {
      return texts.say('tour.goals.placed') ?? texts.say('tour.goals');
    }
    if (step == TourStep.level) {
      return texts.say(
        level == RatingLevel.beginner ? 'tour.level.beginner' : 'tour.level',
      );
    }
    return texts.say('tour.${step.name}');
  }

  TourState copyWith({
    bool? ready,
    TourStep? step,
    RatingLevel? level,
    String? nickname,
    bool? finished,
    bool? forward,
    Set<HomePath>? goals,
    bool? byHand,
    bool? levelChosen,
    int? Function()? placed,
  }) => TourState(
    byHand: byHand ?? this.byHand,
    levelChosen: levelChosen ?? this.levelChosen,
    placed: placed == null ? this.placed : placed(),
    ready: ready ?? this.ready,
    step: step ?? this.step,
    first: first,
    level: level ?? this.level,
    nickname: nickname ?? this.nickname,
    finished: finished ?? this.finished,
    forward: forward ?? this.forward,
    viktor: viktor,
    texts: texts,
    goals: goals ?? this.goals,
    characters: characters,
  );
}

/// O tour da primeira abertura, conduzido pelo Viktor: cada passo é gravado,
/// e o app fechado no meio volta no mesmo passo. No fim, a faixa escolhida
/// vai para o perfil e decide o degrau de início da Jornada; o iniciante vai
/// para as aulas.
class TourCubit extends Cubit<TourState> {
  TourCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    required this._lessons,
    this._voice,
    this._home,
  }) : super(const TourState());

  // Os caminhos escolhidos vão para a tela inicial.
  final HomeLayoutRepository? _home;

  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final LessonRepository _lessons;
  final VoiceRepository? _voice;
  String _language = 'en';
  Onboarding _saved = const Onboarding();
  Future<void> _nicknameSaved = Future.value();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
  int _selectionRevision = 0;
  int _navigationRevision = 0;

  /// As falas do Viktor vêm em [language] (as que faltam, em inglês).
  Future<void> load(String language) async {
    _language = language;
    await _onboardingSaved;
    await _nicknameSaved;
    _saved = await _onboarding.load();
    final profile = await _profile.load();
    final characters = await _characters.characters();
    final texts = await _lessons.texts(language);
    if (isClosed) return;
    Character? viktor;
    for (final character in characters) {
      if (character.id == 'master') viktor = character;
    }
    // A new replay requires a fresh explicit choice; an unfinished replay
    // resumes without changing the legacy done flag used by Home/router.
    if (_saved.done && !_saved.inProgress) {
      _saved = _saved.copyWith(
        step: 0,
        selectedRating: () => null,
        byHand: false,
      );
    }
    final selected = _saved.selectedRating;
    final level = selected == null ? profile.level : RatingLevel.of(selected);
    final saved = _saved.step.clamp(0, TourStep.values.length - 1);
    final step = selected == null && saved > TourStep.level.index
        ? TourStep.level.index
        : await _shown(saved, forward: true);
    final first = await _shown(0, forward: true);
    emit(
      TourState(
        ready: true,
        step: TourStep.values[step],
        first: TourStep.values[first],
        level: level,
        levelChosen: selected != null,
        byHand: _saved.byHand,
        placed: _saved.byHand ? null : selected,
        goals: HomeSuggestion.of(level).visible,
        nickname: profile.nickname,
        viktor: viktor,
        texts: texts,
        characters: characters,
      ),
    );
    await _save(_saved.copyWith(step: step, inProgress: true));
  }

  Future<void> next() async {
    if (!state.ready || state.finished || _finishing || !state.canAdvance) {
      return;
    }
    await _goTo(state.step.index + 1);
  }

  Future<void> back() => _goTo(state.step.index - 1);

  /// Marca a faixa: os caminhos voltam à sugestão dela.
  Future<void> setLevel(RatingLevel level) async {
    if (!state.ready || state.finished || _finishing) return;
    _selectionRevision++;
    emit(
      state.copyWith(
        level: level,
        goals: HomeSuggestion.of(level).visible,
        placed: () => null,
        byHand: true,
        levelChosen: true,
      ),
    );
    await _save(
      _saved.copyWith(selectedRating: () => level.rating, byHand: true),
    );
  }

  /// Opening the manual list is not a level choice. Switching modes clears
  /// the earlier choice so an unselected/default band never becomes consent.
  Future<void> chooseByHand({bool byHand = true}) async {
    if (!state.ready ||
        state.finished ||
        _finishing ||
        state.byHand == byHand) {
      return;
    }
    _selectionRevision++;
    emit(
      state.copyWith(byHand: byHand, levelChosen: false, placed: () => null),
    );
    await _save(_saved.copyWith(byHand: byHand, selectedRating: () => null));
  }

  /// Called only when placement returns a result explicitly used by the user.
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
        goals: HomeSuggestion.of(profile.level).visible,
        placed: () => profile.rating,
        byHand: false,
        levelChosen: true,
      ),
    );
    await _save(
      _saved.copyWith(selectedRating: () => profile.rating, byHand: false),
    );
    if (!isClosed && revision == _selectionRevision) await next();
  }

  /// Marca ou desmarca um caminho. O último marcado não sai.
  void toggleGoal(HomePath path) {
    final goals = {...state.goals};
    if (!goals.remove(path)) goals.add(path);
    if (goals.isEmpty) return;
    emit(state.copyWith(goals: goals));
  }

  /// O nome digitado no primeiro passo: vai para o perfil na hora (fechar o
  /// app no meio do tour não perde o que já foi escrito).
  Future<void> setNickname(String text) {
    final nickname = ProfileRules.cleanNickname(text);
    if (nickname == state.nickname) return _nicknameSaved;
    emit(state.copyWith(nickname: nickname));
    // Uma gravação de cada vez, na ordem em que foram digitadas.
    return _nicknameSaved = _nicknameSaved.then((_) async {
      final profile = await _profile.load();
      await _profile.save(profile.copyWith(nickname: nickname));
    });
  }

  /// Skipping still requires an explicit level; before that it opens the choice.
  Future<void> skip() async {
    if (!state.ready || state.finished || _finishing) return;
    if (!state.levelChosen) {
      await _goTo(TourStep.level.index);
      return;
    }
    await _finish(skipped: true);
  }

  Future<void> finish() async {
    if (!state.ready || state.finished || _finishing) return;
    if (!state.levelChosen) {
      await _goTo(TourStep.level.index);
      return;
    }
    await _finish(skipped: false);
  }

  Future<void> _finish({required bool skipped}) async {
    _finishing = true;
    try {
      await _nicknameSaved;
      await _onboardingSaved;
      final profile = await _profile.load();
      await _profile.save(profile.copyWith(rating: state.rating));
      await _home?.save(
        skipped
            ? HomeSuggestion.of(state.level)
            : HomeSuggestion.withVisible(
                HomeSuggestion.of(state.level),
                state.goals,
                state.level,
              ),
      );
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

  /// O passo [index] ou, se ele não se aplica, o próximo que se aplica no
  /// sentido da navegação.
  Future<int> _shown(int index, {required bool forward}) async {
    var i = index;
    while (i >= 0 &&
        i < TourStep.values.length &&
        await _skips(TourStep.values[i])) {
      i += forward ? 1 : -1;
    }
    return i;
  }

  /// Os passos da voz somem sem voz no idioma; o das vozes dos adversários,
  /// também com a voz desligada ("sem voz").
  Future<bool> _skips(TourStep step) async {
    if (step != TourStep.voice && step != TourStep.characterVoices) {
      return false;
    }
    final voice = _voice;
    if (voice == null) return true;
    final voices = TtsVoice.forLanguage(await voice.voices(), _language);
    if (voices.isEmpty) return true;
    if (step == TourStep.characterVoices) return !(await voice.load()).enabled;
    return false;
  }

  Future<void> _goTo(int requested) async {
    if (!state.ready || state.finished || _finishing) return;
    final revision = ++_navigationRevision;
    final target = !state.levelChosen && requested > TourStep.level.index
        ? TourStep.level.index
        : requested;
    final index = await _shown(target, forward: requested > state.step.index);
    if (isClosed ||
        state.finished ||
        _finishing ||
        revision != _navigationRevision ||
        index < 0 ||
        index >= TourStep.values.length) {
      return;
    }
    emit(
      state.copyWith(
        step: TourStep.values[index],
        forward: index > state.step.index,
      ),
    );
    await _save(_saved.copyWith(step: index));
  }

  Future<void> _save(Onboarding onboarding) {
    _saved = onboarding;
    return _onboardingSaved = _onboardingSaved.then(
      (_) => _onboarding.save(onboarding),
    );
  }
}
