import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/onboarding/onboarding_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../data/repositories/speedrun/speedrun_repository.dart';
import '../../../data/repositories/school/lesson_repository.dart';
import '../../../data/repositories/school/school_progress_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/character.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../domain/use_cases/mastery.dart';
import '../../../domain/use_cases/speedrun_score.dart';

part 'journey_cubit.freezed.dart';

@freezed
abstract class JourneyState with _$JourneyState {
  const factory JourneyState({
    /// Nulo enquanto a Jornada é lida.
    JourneyProgress? progress,

    /// O desafio aberto e as partidas dele, da mais recente para a mais
    /// antiga. Nulo fora da tela do desafio.
    Challenge? challenge,
    @Default(<Attempt>[]) List<Attempt> attempts,

    /// Os personagens, um por nível do Maia.
    @Default(<Character>[]) List<Character> characters,

    /// O que o Viktor diz ao ex-aluno no degrau dele. Nulo para quem não fez
    /// aulas com ele.
    String? reunion,
  }) = _JourneyState;
}

/// A Jornada: os degraus com o que o jogador já concluiu e, na tela de um
/// desafio, as partidas dele.
class JourneyCubit extends Cubit<JourneyState> {
  JourneyCubit(
    this._journey,
    this._progress, {
    this._onboarding,
    this._characters,
    this._school,
    this._lessons,
    this._speedruns,
    this._language = 'en',
    JourneyState? initial,
  }) : super(initial ?? const JourneyState());

  // Os speedruns e as Maratonas curtos da Jornada: concluir um conta como
  // cumprir o desafio especial.
  final SpeedrunRepository? _speedruns;

  final JourneyRepository _journey;
  final ProgressRepository _progress;

  // O degrau de início escolhido no tour. Nulo: a Jornada começa do primeiro.
  final OnboardingRepository? _onboarding;
  final CharacterRepository? _characters;
  final SchoolProgressRepository? _school;
  final LessonRepository? _lessons;
  final String _language;

  // Os especiais de speedrun (ou de Maratona) com alguma tentativa
  // concluída.
  Future<Set<String>> _speedrunSpecialsDone(List<Rung> ladder) async {
    final speedruns = _speedruns;
    if (speedruns == null) return const {};
    final bases = await _journey.speedruns();
    final done = <String>{};
    for (final rung in ladder) {
      for (final special in rung.specials) {
        final id = special.speedrunId;
        if (id == null) continue;
        final speedrun = SpeedrunPaces.resolve(bases, id);
        if (speedrun == null) continue;
        for (final attempt in await speedruns.attempts(speedrun.id)) {
          if (SpeedrunScore.run(speedrun, attempt).completed) {
            done.add(special.id);
            break;
          }
        }
      }
    }
    return done;
  }

  /// Lê a Jornada. Com [rungId] e [positionId], lê também o desafio e o
  /// histórico dele.
  Future<void> load({String? rungId, String? positionId}) async {
    final ladder = await _journey.ladder();
    final fulfilled = {
      ...await _progress.fulfilledChallenges(),
      ...await _speedrunSpecialsDone(ladder),
    };
    final onboarding = await _onboarding?.load();
    final progress = Mastery.of(
      ladder,
      fulfilled,
      startRung: onboarding?.startRung,
    );
    Challenge? challenge;
    for (final rung in ladder) {
      if (rung.id != rungId) continue;
      for (final candidate in rung.challenges) {
        if (candidate.position.id == positionId) challenge = candidate;
      }
    }
    final attempts = challenge == null
        ? const <Attempt>[]
        : await _progress.attemptsForChallenge(challenge.id);
    final characters = await _characters?.characters() ?? const <Character>[];
    final student = (await _school?.load())?.isStudent ?? false;
    final reunion = student
        ? (await _lessons?.texts(_language))?.say('journey.reunion')
        : null;
    if (isClosed) return;
    emit(
      JourneyState(
        progress: progress,
        challenge: challenge,
        attempts: attempts,
        characters: characters,
        reunion: reunion,
      ),
    );
  }
}
