import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/progress/progress_repository.dart';
import '../../../domain/models/attempt.dart';
import '../../../domain/models/journey.dart';
import '../../../domain/use_cases/mastery.dart';

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
  }) = _JourneyState;
}

/// A Jornada: os degraus com o que o jogador já concluiu e, na tela de um
/// desafio, as partidas dele.
class JourneyCubit extends Cubit<JourneyState> {
  JourneyCubit(this._journey, this._progress) : super(const JourneyState());

  final JourneyRepository _journey;
  final ProgressRepository _progress;

  /// Lê a Jornada. Com [rungId] e [positionId], lê também o desafio e o
  /// histórico dele.
  Future<void> load({String? rungId, String? positionId}) async {
    final ladder = await _journey.ladder();
    final fulfilled = await _progress.fulfilledChallenges();
    final progress = Mastery.of(ladder, fulfilled);
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
    if (isClosed) return;
    emit(
      JourneyState(
        progress: progress,
        challenge: challenge,
        attempts: attempts,
      ),
    );
  }
}
