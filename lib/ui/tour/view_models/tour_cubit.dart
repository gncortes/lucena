import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/home/home_layout_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/home_suggestion.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Os passos do tour, na ordem (layout B, "Conversa"): o tabuleiro, a voz do
/// Viktor e o nome, como são as aulas, como pedir ajuda, as partidas e o
/// nível. Nenhum passo some.
enum TourStep {
  board,
  voice,
  school,
  help,
  play,
  level;

  bool get isLast => this == TourStep.level;
}

/// Os três cartões do último passo.
enum TourLevelChoice { beginner, test, band }

class TourState {
  const TourState({
    this.ready = false,
    this.step = TourStep.board,
    this.level = RatingLevel.casual,
    this.nickname = '',
    this.finished = false,
    this.forward = true,
    this.viktor,
    this.texts = LessonTexts.empty,
    this.characters = const [],
    this.placed,
    this.levelChosen = false,
    this.hasVoices = false,
  });

  final bool levelChosen;

  /// Há voz no idioma: só escolhe a fala do passo da voz.
  final bool hasVoices;

  /// "Começar" só vale com o nível escolhido.
  /// O rating que o teste de nível deu, se o jogador o fez e usou.
  final int? placed;

  /// Os personagens, para o passo das partidas.
  final List<Character> characters;

  final bool ready;
  final TourStep step;

  /// Há passo antes deste.
  bool get hasPrevious => step != TourStep.board;

  /// O último passo foi para a frente (a transição desliza nesse sentido).
  final bool forward;

  /// O Viktor conduz o tour. Nulo só se a ficha dele faltar.
  final Character? viktor;
  final LessonTexts texts;

  /// A faixa marcada no passo do nível.
  final RatingLevel level;

  /// O nome dado no passo da voz (o apelido do perfil). Vazio: o padrão.
  final String nickname;

  /// O tour terminou (ou foi pulado): a tela sai.
  final bool finished;

  /// O degrau em que a Jornada começa com a faixa marcada.
  String get startRung => '${MaiaLevels.nearest(rating)}';

  /// O rating que vai para o perfil: o do teste ou o da faixa marcada.
  int get rating => placed ?? level.rating;

  /// O cartão marcado no último passo; nenhum, sem escolha gravada.
  TourLevelChoice? get choice {
    if (placed != null) return TourLevelChoice.test;
    // Sem escolha, o passo abre com "Estou começando" marcado.
    if (!levelChosen) return TourLevelChoice.beginner;
    return level == RatingLevel.beginner
        ? TourLevelChoice.beginner
        : TourLevelChoice.band;
  }

  /// Marcou a faixa iniciante: o tour termina nas aulas do Viktor.
  bool get toSchool => levelChosen && level == RatingLevel.beginner;

  /// O que o Viktor diz no passo aberto.
  String? get speech => step == TourStep.voice && !hasVoices
      ? texts.say('tour.voice.none')
      : texts.say('tour.${step.name}');

  TourState copyWith({
    bool? ready,
    TourStep? step,
    RatingLevel? level,
    String? nickname,
    bool? finished,
    bool? forward,
    bool? levelChosen,
    int? Function()? placed,
  }) => TourState(
    levelChosen: levelChosen ?? this.levelChosen,
    placed: placed == null ? this.placed : placed(),
    ready: ready ?? this.ready,
    step: step ?? this.step,
    level: level ?? this.level,
    nickname: nickname ?? this.nickname,
    finished: finished ?? this.finished,
    forward: forward ?? this.forward,
    viktor: viktor,
    texts: texts,
    characters: characters,
    hasVoices: hasVoices,
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
  Onboarding _saved = const Onboarding();
  Future<void> _nicknameSaved = Future.value();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
  int _selectionRevision = 0;
  int _navigationRevision = 0;

  /// As falas do Viktor vêm em [language] (as que faltam, em inglês).
  Future<void> load(String language) async {
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
    final step = _saved.step.clamp(0, TourStep.values.length - 1);
    final voice = _voice;
    final hasVoices =
        voice != null &&
        TtsVoice.forLanguage(await voice.voices(), language).isNotEmpty;
    if (isClosed) return;
    emit(
      TourState(
        ready: true,
        step: TourStep.values[step],
        level: level,
        levelChosen: selected != null,
        placed: _saved.byHand ? null : selected,
        nickname: profile.nickname,
        viktor: viktor,
        texts: texts,
        characters: characters,
        hasVoices: hasVoices,
      ),
    );
    await _save(_saved.copyWith(step: step, inProgress: true));
  }

  Future<void> next() async {
    if (!state.ready || state.finished || _finishing) {
      return;
    }
    await _goTo(state.step.index + 1);
  }

  Future<void> back() => _goTo(state.step.index - 1);

  /// Marca a faixa.
  Future<void> setLevel(RatingLevel level) async {
    if (!state.ready || state.finished || _finishing) return;
    _selectionRevision++;
    emit(state.copyWith(level: level, placed: () => null, levelChosen: true));
    await _save(
      _saved.copyWith(selectedRating: () => level.rating, byHand: true),
    );
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
        placed: () => profile.rating,
        levelChosen: true,
      ),
    );
    await _save(
      _saved.copyWith(selectedRating: () => profile.rating, byHand: false),
    );
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
      if (state.step != TourStep.level) {
        await _goTo(TourStep.level.index);
        return;
      }
      // "Começar" com "Estou começando" marcado por padrão: grava a faixa.
      await setLevel(RatingLevel.beginner);
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

  Future<void> _goTo(int requested) async {
    if (!state.ready || state.finished || _finishing) return;
    final revision = ++_navigationRevision;
    final index = requested.clamp(0, TourStep.values.length - 1);
    if (isClosed || revision != _navigationRevision) return;
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
