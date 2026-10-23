import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/attempt.dart';
import '../../../domain/models/progress_summary.dart';
import '../../../domain/models/star_challenge.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/progress_merge.dart';
import '../../../domain/use_cases/speedrun_score.dart';
import '../../services/firebase/cloud_store_service.dart';
import '../../services/preferences_service.dart';
import '../endgames/endgame_progress_repository.dart';
import '../featured/featured_progress_repository.dart';
import '../journey/journey_repository.dart';
import '../onboarding/onboarding_repository.dart';
import '../profile/profile_repository.dart';
import '../progress/progress_repository_restored.dart';
import '../race/race_repository.dart';
import '../rating/rating_repository.dart';
import '../school/school_progress_repository.dart';
import '../school/star_challenge_repository.dart';
import '../speedrun/speedrun_repository.dart';

/// A conta não respondeu: sem rede na hora de entrar (regra 13). Nada foi
/// apagado nem mudado.
class SyncException implements Exception {
  const SyncException();
}

/// O que a junção encontrou.
class SyncResult {
  const SyncResult({required this.summary, required this.hadRemote});

  /// O progresso junto, que agora vale no aparelho e na conta.
  final ProgressSummary summary;

  /// A conta já tinha progresso de outro aparelho (a tela "Bem-vindo de
  /// volta").
  final bool hadRemote;
}

/// Leva o progresso do aparelho para a conta e traz o da conta (E1.13,
/// regras 12 e 13). O aparelho é a fonte da verdade: tudo é gravado nele
/// antes, e a conta recebe a junção depois, ao entrar e ao terminar uma
/// partida ou uma aula, nunca a cada lance.
abstract class SyncRepository {
  /// Quando a conta [uid] confirmou o último envio. Nulo: nunca.
  Future<DateTime?> lastSyncedAt(String uid);

  /// Lê a conta, junta com o aparelho (vale o maior em cada item), grava a
  /// junção aqui e a manda para a conta, com as partidas novas. Lança
  /// [SyncException] se não deu para ler a conta.
  Future<SyncResult> sync(String uid);
}

/// Sem conta na nuvem (testes, build sem Firebase): a conta nunca responde.
class NoSyncRepository implements SyncRepository {
  const NoSyncRepository();

  @override
  Future<DateTime?> lastSyncedAt(String uid) async => null;

  @override
  Future<SyncResult> sync(String uid) async => throw const SyncException();
}

class CloudSyncRepository implements SyncRepository {
  CloudSyncRepository({
    required this._store,
    required this._preferences,
    required this._now,
    required this._profile,
    required this._rating,
    required this._progress,
    required this._endgames,
    required this._school,
    required this._stars,
    required this._onboarding,
    required this._journey,
    required this._speedruns,
    required this._race,
    required this._featured,
  });

  final CloudStoreService _store;
  final PreferencesService _preferences;
  final Now _now;
  final ProfileRepository _profile;
  final RatingRepository _rating;
  final RestoredProgressRepository _progress;
  final EndgameProgressRepository _endgames;
  final SchoolProgressRepository _school;
  final StarChallengeRepository _stars;
  final OnboardingRepository _onboarding;
  final JourneyRepository _journey;
  final SpeedrunRepository _speedruns;
  final RaceRepository _race;
  final FeaturedProgressRepository _featured;

  static String _syncedKey(String uid) => 'sync.$uid.at';

  /// O id local da última partida enviada.
  static String _gamesKey(String uid) => 'sync.$uid.games';

  @override
  Future<DateTime?> lastSyncedAt(String uid) async {
    final saved = await _preferences.getString(_syncedKey(uid));
    return saved == null ? null : DateTime.tryParse(saved);
  }

  @override
  Future<SyncResult> sync(String uid) async {
    final Map<String, Object?>? saved;
    try {
      saved = await _store.readProgress(uid);
    } on CloudStoreException {
      throw const SyncException();
    }
    final local = await localSummary();
    final remote = saved == null ? null : ProgressSummary.fromJson(saved);
    final merged = remote == null ? local : ProgressMerge.merge(local, remote);
    if (remote != null) await _apply(local, merged);
    // Sem rede, a gravação fica na fila do Firestore e termina quando ela
    // volta: quem entrou não espera por ela.
    unawaited(_push(uid, merged));
    return SyncResult(
      summary: merged,
      hadRemote: remote != null && !remote.isEmpty,
    );
  }

  /// O que o aparelho tem agora, no formato da conta.
  @visibleForTesting
  Future<ProgressSummary> localSummary() async {
    final history = await _rating.history();
    final school = await _school.load();
    final startRung = (await _onboarding.load()).startRung;
    final speedruns = <String, int>{};
    for (final speedrun in await _journey.speedruns()) {
      final best = SpeedrunScore.records(
        speedrun,
        await _speedruns.attempts(speedrun.id),
      ).best;
      if (best != null) speedruns[speedrun.id] = best.inMilliseconds;
    }
    return ProgressSummary(
      profile: await _profile.load(),
      rating: history.isEmpty ? null : await _rating.current(),
      lessons: (await _endgames.load()).lessons,
      school: school.completed,
      stars: (await _stars.load()).best,
      challenges: await _progress.fulfilledChallenges(),
      positions: await _progress.fulfilledPositions(),
      startRung: startRung == null ? null : int.tryParse(startRung),
      speedruns: speedruns,
      race: await _race.record(),
      featured: await _featured.played(),
    );
  }

  // Grava no aparelho o que veio da conta. Os recordes de speedrun ficam só
  // no resumo da conta: aqui eles saem das tentativas gravadas.
  Future<void> _apply(ProgressSummary local, ProgressSummary merged) async {
    await _profile.save(merged.profile);
    if (merged.rating case final rating?) await _rating.restore(rating);
    final endgames = await _endgames.load();
    await _endgames.save(
      endgames.copyWith(
        lessons: {
          for (final MapEntry(:key, :value) in merged.lessons.entries)
            key: value.copyWith(exercise: endgames.lessons[key]?.exercise),
        },
      ),
    );
    final school = await _school.load();
    await _school.save(school.copyWith(completed: merged.school));
    await _stars.save(StarChallengeProgress(best: merged.stars));
    await _progress.restore(
      challenges: merged.challenges.difference(local.challenges),
      positions: merged.positions.difference(local.positions),
    );
    if (merged.startRung case final rung? when rung != local.startRung) {
      final onboarding = await _onboarding.load();
      await _onboarding.save(onboarding.copyWith(startRung: '$rung'));
    }
    await _race.restoreRecord(merged.race);
    for (final id in merged.featured.difference(local.featured)) {
      await _featured.markPlayed(id);
    }
  }

  Future<void> _push(String uid, ProgressSummary summary) async {
    try {
      await _store.writeProgress(uid, {
        ...summary.toJson(),
        'updatedAt': _now(),
      });
      await _preferences.setString(_syncedKey(uid), _now().toIso8601String());
      await _pushGames(uid);
    } on Object catch (error) {
      debugPrint('Progresso não enviado: $error');
    }
  }

  Future<void> _pushGames(String uid) async {
    final sent = int.tryParse(
      await _preferences.getString(_gamesKey(uid)) ?? '',
    );
    for (final MapEntry(key: id, value: game)
        in (await _progress.allAttemptsById()).entries) {
      if (sent != null && id <= sent) continue;
      await _store.writeGame(uid, gameId(game), gameJson(game));
      await _preferences.setString(_gamesKey(uid), '$id');
    }
  }

  /// O id da partida na conta: o mesmo em qualquer aparelho e a cada envio
  /// (as regras não deixam regravar).
  @visibleForTesting
  static String gameId(Attempt game) {
    final position = game.positionId.replaceAll(RegExp('[^A-Za-z0-9_-]'), '_');
    return '${game.playedAt.toUtc().microsecondsSinceEpoch}-$position';
  }

  /// A partida na conta: sem os ids deste aparelho (tentativa de speedrun).
  @visibleForTesting
  static Map<String, Object?> gameJson(Attempt game) => {
    'positionId': game.positionId,
    'playedAt': game.playedAt,
    'outcome': game.outcome.code,
    'fulfilled': game.fulfilled,
    'opponent': game.opponent.name,
    'opponentLevel': ?game.opponentLevel,
    'startedAt': ?game.startedAt,
    'startFen': ?game.startFen,
    'moves': game.moves.join(' '),
    'userSide': ?game.userSide?.name,
    'endReason': ?game.endReason?.name,
    'challengeId': ?game.challengeId,
  };
}
