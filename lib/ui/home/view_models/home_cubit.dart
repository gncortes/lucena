import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/profile/profile_repository.dart';
import '../../../data/repositories/rating/rating_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/game_setup.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/rating_level.dart';
import '../../../domain/use_cases/mastery.dart';

/// O que a tela inicial mostra: onde o jogador está, contra quem joga e o
/// próximo passo.
class HomeState {
  const HomeState({
    this.ready = false,
    this.tourPending = false,
    this.current,
    this.next,
    this.character,
    this.rating,
    this.school,
    this.nickname = '',
    this.level,
    this.ratingChange,
  });

  final bool ready;

  /// A primeira abertura: o tour ainda não foi visto.
  final bool tourPending;

  /// O degrau atual. Nulo com a Jornada concluída.
  final RungProgress? current;

  /// O próximo desafio do degrau atual.
  final Challenge? next;

  /// O personagem do degrau atual (nulo no do Stockfish).
  final Character? character;
  final int? rating;

  /// O iniciante com aulas por fazer: a tela inicial leva primeiro a elas.
  final SchoolSummary? school;

  /// O apelido e a faixa do jogador.
  final String nickname;
  final RatingLevel? level;

  /// Quanto a última partida mudou o rating. Nulo sem duas partidas.
  final int? ratingChange;
}

/// As aulas do Viktor na tela inicial: quantas foram feitas e o professor.
class SchoolSummary {
  const SchoolSummary({
    required this.done,
    required this.total,
    required this.teacher,
  });

  final int done;
  final int total;
  final Character? teacher;
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this._journey,
    required this._progress,
    required this._onboarding,
    required this._characters,
    required this._rating,
    required this._lessons,
    required this._school,
    required this._profile,
  }) : super(const HomeState());

  final JourneyRepository _journey;
  final ProgressRepository _progress;
  final OnboardingRepository _onboarding;
  final CharacterRepository _characters;
  final RatingRepository _rating;
  final LessonRepository _lessons;
  final SchoolProgressRepository _school;
  final ProfileRepository _profile;

  Future<void> load() async {
    final onboarding = await _onboarding.load();
    final progress = Mastery.of(
      await _journey.ladder(),
      await _progress.fulfilledChallenges(),
      startRung: onboarding.startRung,
    );
    final current = progress.current;
    Challenge? next;
    for (final challenge in current?.rung.challenges ?? const <Challenge>[]) {
      if (!current!.completed.contains(challenge.id)) {
        next = challenge;
        break;
      }
    }
    final characters = await _characters.characters();
    final rating = await _rating.current();
    final history = await _rating.history();
    final school = await _schoolSummary(characters);
    final profile = await _profile.load();
    if (isClosed) return;
    emit(
      HomeState(
        ready: true,
        tourPending: !onboarding.done,
        current: current,
        next: next,
        // O do Stockfish é o logo dele.
        character: current?.rung.opponent.kind == OpponentKind.stockfish
            ? Character.stockfish
            : characters.forLevel(current?.rung.opponent.level),
        rating: rating.rounded,
        school: school,
        nickname: profile.nickname,
        level: profile.level,
        ratingChange: history.length < 2
            ? null
            : history.last.rating.rounded -
                  history[history.length - 2].rating.rounded,
      ),
    );
  }

  /// Só para quem marcou "iniciante" e ainda não se formou.
  Future<SchoolSummary?> _schoolSummary(List<Character> characters) async {
    final profile = await _profile.load();
    if (profile.level != RatingLevel.beginner) return null;
    final lessons = (await _lessons.course()).lessons;
    final completed = (await _school.load()).completed;
    final done = lessons.where((lesson) => completed.contains(lesson.id));
    if (lessons.isEmpty || done.length == lessons.length) return null;
    Character? teacher;
    for (final character in characters) {
      if (character.id == 'master') teacher = character;
    }
    return SchoolSummary(
      done: done.length,
      total: lessons.length,
      teacher: teacher,
    );
  }
}
