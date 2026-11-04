import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../../data/repositories/diagnostics/failure_report_repository.dart';
import '../../../domain/models/load_failure.dart';

import '../../../data/repositories/analytics/analytics_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/voice/voice_repository.dart';
import '../../../domain/models/analytics_event.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/goal_preference.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/voice.dart';
import '../../../domain/use_cases/profile_rules.dart';

/// Os passos do tour, na ordem (T85): o tabuleiro, o tema, a voz do Viktor e
/// o nome, o nível, a região e a conta. O nível é um passo do tour (não há
/// mais tela "Seu nível" à parte).
enum TourStep {
  board,
  theme,
  voice,
  level,
  region,
  account;

  bool get isLast => this == TourStep.account;

  /// Quanto da barra está cheio neste passo (canvas `PropV2TourB*`). Com o
  /// objetivo "Aprender a jogar" não há o passo do nível e a barra fica em
  /// quartos.
  double progress({required bool learn}) => learn
      ? switch (this) {
          board || theme => 0.25,
          voice => 0.50,
          level || region => 0.75,
          account => 1.0,
        }
      : switch (this) {
          board => 0.20,
          theme => 0.30,
          voice => 0.40,
          level => 0.60,
          region => 0.80,
          account => 1.0,
        };
}

class TourState {
  final LoadFailure? failure;
  const TourState({
    this.ready = false,
    this.failure,
    this.step = TourStep.board,
    this.nickname = '',
    this.finished = false,
    this.forward = true,
    this.viktor,
    this.hasVoices = false,
    this.linkSetupDone = false,
    this.learn = false,
  });

  /// Há voz no idioma: só escolhe a fala do passo da voz.
  final bool hasVoices;

  /// Quem veio de um link já escolheu cores e peças: o tour pula o tabuleiro.
  final bool linkSetupDone;

  /// O objetivo é "Aprender a jogar": o tour não pergunta o nível.
  final bool learn;

  final bool ready;
  final TourStep step;

  /// Os passos que aparecem, na ordem.
  List<TourStep> get steps => [
    for (final step in TourStep.values)
      if (!(linkSetupDone && step == TourStep.board) &&
          !(learn && step == TourStep.level))
        step,
  ];

  /// A posição do passo aberto entre os que aparecem (de 0).
  int get position => steps.indexOf(step);

  /// A fração da barra de progresso no passo aberto.
  double get progress => step.progress(learn: learn);

  /// Há passo antes deste. O primeiro passo não tem seta de voltar.
  bool get hasPrevious => position > 0;

  /// O último passo foi para a frente (a transição desliza nesse sentido).
  final bool forward;

  /// O Viktor conduz o tour. Nulo só se a ficha dele faltar.
  final Character? viktor;

  /// O nome dado no passo da voz (o apelido do perfil). Vazio: o padrão.
  final String nickname;

  /// O tour terminou (saiu da Conta): a tela vai para o Início.
  final bool finished;

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
    hasVoices: hasVoices,
    linkSetupDone: linkSetupDone,
    learn: learn,
  );
}

/// O tour da primeira abertura, conduzido pelo Viktor: cada passo é gravado,
/// e o app fechado no meio volta no mesmo passo. O tour só termina ao sair da
/// Conta (o último passo); "Pular" pula só o passo aberto.
class TourCubit extends Cubit<TourState> {
  TourCubit({
    required this._onboarding,
    required this._profile,
    required this._characters,
    this._voice,
    this._analytics = const NoAnalyticsRepository(),
  }) : super(const TourState());

  final AnalyticsRepository _analytics;
  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final VoiceRepository? _voice;
  Onboarding _saved = const Onboarding();
  Future<void> _nicknameSaved = Future.value();
  Future<void> _onboardingSaved = Future.value();
  bool _finishing = false;
  bool _skipped = false;
  int _navigationRevision = 0;

  /// As falas do Viktor vêm em [language] (as que faltam, em inglês).
  Future<void> load(String language) async {
    try {
      await _load(language);
    } on Object catch (error, stack) {
      // A failed persisted write must not poison the next explicit load.
      _onboardingSaved = Future<void>.value();
      _nicknameSaved = Future<void>.value();
      debugPrint('tour load failed: $error');
      reportHandledError(error, stack);
      if (!isClosed) emit(TourState(failure: LoadFailure.generic));
    }
  }

  Future<void> _load(String language) async {
    await _onboardingSaved;
    await _nicknameSaved;
    _saved = await _onboarding.load();
    final profile = await _profile.load();
    final characters = await _characters.characters();
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
    final learn = profile.goal == GoalPreference.learn;
    var step = _saved.step.clamp(0, TourStep.values.length - 1);
    // Quem veio de um link não vê o tabuleiro de novo; quem quer aprender a
    // jogar não vê o nível.
    if (_saved.linkSetupDone && step == TourStep.board.index) step++;
    if (learn && step == TourStep.level.index) step++;
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
        hasVoices: hasVoices,
        linkSetupDone: _saved.linkSetupDone,
        learn: learn,
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

  /// "Pular" pula só o passo aberto (a escolha dele fica no padrão) e vai
  /// ao próximo. Na Conta não há o que pular.
  Future<void> skip() async {
    if (!state.ready || state.finished || _finishing || state.step.isLast) {
      return;
    }
    _skipped = true;
    await next();
  }

  /// O fim do tour, ao sair da Conta (convite recusado ou conta criada): só
  /// aqui ele conta como visto.
  Future<void> finish() async {
    if (!state.ready || state.finished || _finishing) return;
    _finishing = true;
    unawaited(
      _analytics.log(
        AnalyticsEvents.tutorialComplete(
          pulado: _skipped,
          passosVistos: state.position + 1,
        ),
      ),
    );
    try {
      await _nicknameSaved;
      await _onboardingSaved;
      await _save(_saved.copyWith(done: true, step: 0, inProgress: false));
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
