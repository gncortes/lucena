import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/lesson.dart';
import '../../../domain/models/maia_level.dart';
import '../../../domain/models/onboarding.dart';
import '../../../domain/models/rating_level.dart';

/// Os passos do tour, na ordem. O último pergunta o nível.
enum TourStep {
  goal,
  rating,
  journey,
  endgames,
  opponents,
  speedrun,
  records,
  level;

  bool get isLast => this == TourStep.level;
}

class TourState {
  const TourState({
    this.ready = false,
    this.step = TourStep.goal,
    this.level = RatingLevel.casual,
    this.finished = false,
    this.forward = true,
    this.viktor,
    this.texts = LessonTexts.empty,
  });

  final bool ready;
  final TourStep step;

  /// O último passo foi para a frente (a transição desliza nesse sentido).
  final bool forward;

  /// O Viktor conduz o tour. Nulo só se a ficha dele faltar.
  final Character? viktor;
  final LessonTexts texts;

  /// A faixa marcada no último passo.
  final RatingLevel level;

  /// O tour terminou (ou foi pulado): a tela sai.
  final bool finished;

  /// O degrau em que a Jornada começa com a faixa marcada.
  String get startRung => '${MaiaLevels.nearest(level.rating)}';

  /// Marcou "iniciante": o tour termina nas aulas do Viktor.
  bool get toSchool => level == RatingLevel.beginner;

  /// O que o Viktor diz no passo aberto.
  String? get speech {
    if (step.isLast) {
      return texts.say(toSchool ? 'tour.level.beginner' : 'tour.level');
    }
    return texts.say('tour.${step.name}');
  }

  TourState copyWith({
    bool? ready,
    TourStep? step,
    RatingLevel? level,
    bool? finished,
    bool? forward,
  }) => TourState(
    ready: ready ?? this.ready,
    step: step ?? this.step,
    level: level ?? this.level,
    finished: finished ?? this.finished,
    forward: forward ?? this.forward,
    viktor: viktor,
    texts: texts,
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
  }) : super(const TourState());

  final OnboardingRepository _onboarding;
  final ProfileRepository _profile;
  final CharacterRepository _characters;
  final LessonRepository _lessons;
  Onboarding _saved = const Onboarding();

  /// As falas do Viktor vêm em [language] (as que faltam, em inglês).
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
    // Revendo o tour (já visto), ele começa do primeiro passo.
    final step = _saved.done
        ? 0
        : _saved.step.clamp(0, TourStep.values.length - 1);
    emit(
      TourState(
        ready: true,
        step: TourStep.values[step],
        level: profile.level,
        viktor: viktor,
        texts: texts,
      ),
    );
  }

  Future<void> next() => _goTo(state.step.index + 1);

  Future<void> back() => _goTo(state.step.index - 1);

  void setLevel(RatingLevel level) => emit(state.copyWith(level: level));

  /// Pula o resto: o tour não aparece de novo.
  Future<void> skip() async {
    await _save(_saved.copyWith(done: true, step: 0));
    emit(state.copyWith(finished: true));
  }

  /// Confirma a faixa: o perfil fica com ela e a Jornada começa no degrau
  /// dela.
  Future<void> finish() async {
    final profile = await _profile.load();
    await _profile.save(profile.copyWith(rating: state.level.rating));
    await _save(
      _saved.copyWith(done: true, step: 0, startRung: state.startRung),
    );
    emit(state.copyWith(finished: true));
  }

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= TourStep.values.length) return;
    emit(
      state.copyWith(
        step: TourStep.values[index],
        forward: index > state.step.index,
      ),
    );
    // Revendo o tour, o passo não precisa ser lembrado.
    if (!_saved.done) await _save(_saved.copyWith(step: index));
  }

  Future<void> _save(Onboarding onboarding) async {
    _saved = onboarding;
    await _onboarding.save(onboarding);
  }
}
