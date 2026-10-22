import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Os passos do tour, na ordem (layout B, "Conversa"): o tabuleiro, a voz do
/// Viktor e o nome, como são as aulas, como pedir ajuda e as partidas. A conta
/// e o nível vêm depois, em telas à parte.
enum TourStep {
  board,
  voice,
  school,
  help,
  play;

  bool get isLast => this == TourStep.play;
}

class TourState {
  const TourState({
    this.ready = false,
    this.step = TourStep.board,
    this.nickname = '',
    this.finished = false,
    this.forward = true,
    this.viktor,
    this.texts = LessonTexts.empty,
    this.characters = const [],
    this.hasVoices = false,
    this.linkSetupDone = false,
  });

  /// Há voz no idioma: só escolhe a fala do passo da voz.
  final bool hasVoices;

  /// Quem veio de um link já escolheu cores e peças: o tour pula o tabuleiro.
  final bool linkSetupDone;

  /// Os personagens, para o passo das partidas.
  final List<Character> characters;

  final bool ready;
  final TourStep step;

  /// Os passos que aparecem, na ordem.
  List<TourStep> get steps => [
    for (final step in TourStep.values)
      if (!(linkSetupDone && step == TourStep.board)) step,
  ];

  /// A posição do passo aberto entre os que aparecem (de 0).
  int get position => steps.indexOf(step);

  /// Há passo antes deste.
  bool get hasPrevious => position > 0;

  /// O último passo foi para a frente (a transição desliza nesse sentido).
  final bool forward;

  /// O Viktor conduz o tour. Nulo só se a ficha dele faltar.
  final Character? viktor;
  final LessonTexts texts;

  /// O nome dado no passo da voz (o apelido do perfil). Vazio: o padrão.
  final String nickname;

  /// O tour terminou (ou foi pulado): a tela sai para a pergunta do objetivo
  /// (vindo de um link, para a conta).
  final bool finished;

  /// O que o Viktor diz no passo aberto. Vindo de um link, ele abre a
  /// conversa de outro jeito (a pessoa já jogou).
  String? get speech {
    if (step == TourStep.voice) {
      if (linkSetupDone) {
        return texts.say(
          hasVoices ? 'tour.voice.link' : 'tour.voice.link.none',
        );
      }
      if (!hasVoices) return texts.say('tour.voice.none');
    }
    return texts.say('tour.${step.name}');
  }

  TourState copyWith({
    bool? ready,
    TourStep? step,
    String? nickname,
    bool? finished,
    bool? forward,
  }) => TourState(
    ready: ready ?? this.ready,
    step: step ?? this.step,
    nickname: nickname ?? this.nickname,
    finished: finished ?? this.finished,
    forward: forward ?? this.forward,
    viktor: viktor,
    texts: texts,
    characters: characters,
    hasVoices: hasVoices,
    linkSetupDone: linkSetupDone,
  );
}

/// O tour da primeira abertura, conduzido pelo Viktor: cada passo é gravado,
/// e o app fechado no meio volta no mesmo passo. No fim (ou ao pular), a tela
/// sai para a pergunta do objetivo (vindo de um link, antes para a conta).
class TourCubit extends Cubit<TourState> {
  TourCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    required this._lessons,
    this._voice,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const TourState());

  final AnalyticsRepository _analytics;
  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final LessonRepository _lessons;
  final VoiceRepository? _voice;
  Onboarding _saved = const Onboarding();
  Future<void> _nicknameSaved = Future.value();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
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
    var step = _saved.step.clamp(0, TourStep.values.length - 1);
    // Quem veio de um link não vê o tabuleiro de novo.
    if (_saved.linkSetupDone && step == TourStep.board.index) step++;
    final voice = _voice;
    final hasVoices =
        voice != null &&
        TtsVoice.forLanguage(await voice.voices(), language).isNotEmpty;
    if (isClosed) return;
    // O tour que volta no meio já contou o começo.
    if (!_saved.inProgress) {
      unawaited(
        _analytics.log(
          AnalyticsEvents.tutorialBegin(
            entrada: _saved.linkSetupDone ? 'link' : 'loja',
          ),
        ),
      );
    }
    emit(
      TourState(
        ready: true,
        step: TourStep.values[step],
        nickname: profile.nickname,
        viktor: viktor,
        texts: texts,
        characters: characters,
        hasVoices: hasVoices,
        linkSetupDone: _saved.linkSetupDone,
      ),
    );
    await _save(
      _saved.copyWith(
        step: step,
        inProgress: true,
        stage: OnboardingStage.tour,
      ),
    );
  }

  Future<void> next() async {
    if (!state.ready || state.finished || _finishing) return;
    final steps = state.steps;
    final position = state.position;
    if (position + 1 >= steps.length) return;
    await _goTo(steps[position + 1]);
  }

  Future<void> back() async {
    final position = state.position;
    if (position <= 0) return;
    await _goTo(state.steps[position - 1]);
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

  /// Pular vai direto para a pergunta; o nível ainda é perguntado depois.
  Future<void> skip() => finish(skipped: true);

  /// O fim do tour: a tela sai. O tour só conta como visto quando o nível é
  /// escolhido; fechado o app antes, ele volta no último passo.
  Future<void> finish({bool skipped = false}) async {
    if (!state.ready || state.finished || _finishing) return;
    _finishing = true;
    unawaited(
      _analytics.log(
        AnalyticsEvents.tutorialComplete(
          pulado: skipped,
          passosVistos: state.position + 1,
        ),
      ),
    );
    try {
      await _nicknameSaved;
      await _onboardingSaved;
      await _save(_saved.copyWith(step: TourStep.values.last.index));
      if (!isClosed) emit(state.copyWith(finished: true));
    } finally {
      _finishing = false;
    }
  }

  Future<void> _goTo(TourStep requested) async {
    if (!state.ready || state.finished || _finishing) return;
    final revision = ++_navigationRevision;
    if (isClosed || revision != _navigationRevision) return;
    emit(
      state.copyWith(
        step: requested,
        forward: requested.index > state.step.index,
      ),
    );
    await _save(_saved.copyWith(step: requested.index));
  }

  Future<void> _save(Onboarding onboarding) {
    _saved = onboarding;
    return _onboardingSaved = _onboardingSaved.then(
      (_) => _onboarding.save(onboarding),
    );
  }
}
