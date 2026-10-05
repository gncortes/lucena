import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/achievement.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/use_cases/achievement_rules.dart';
import 'package:lucena/domain/use_cases/speedrun_score.dart';

import '../../../testing/fakes/fake_journey_repository.dart';

void main() {
  final day = DateTime.utc(2026, 10, 4, 12);
  final ladder = sampleLadder;
  final rungSpeedrun = sampleSpeedruns[0];
  final endingSpeedrun = sampleSpeedruns[1];
  final speedruns = {for (final s in sampleSpeedruns) s.id: s};

  Attempt game({
    String positionId = 'p',
    bool fulfilled = true,
    OpponentKind opponent = OpponentKind.maia,
    int? level = 1000,
    String? challengeId,
    int? seconds,
    int minutes = 0,
  }) => Attempt(
    positionId: positionId,
    playedAt: day.add(Duration(minutes: minutes)),
    outcome: fulfilled ? AttemptOutcome.win : AttemptOutcome.loss,
    fulfilled: fulfilled,
    opponent: opponent,
    opponentLevel: opponent == OpponentKind.maia ? level : null,
    challengeId: challengeId,
    userClock: seconds == null ? null : Duration(seconds: seconds),
  );

  /// Uma tentativa concluída de [speedrun], [seconds] por etapa, com
  /// [losses] derrotas na primeira etapa.
  SpeedrunRun run(
    Speedrun speedrun,
    int id, {
    int seconds = 60,
    int losses = 0,
    int minutes = 0,
    bool complete = true,
  }) {
    final games = <Attempt>[
      for (var i = 0; i < losses; i++)
        Attempt(
          positionId: speedrun.stages[0].position.id,
          playedAt: day.add(Duration(minutes: minutes)),
          outcome: AttemptOutcome.loss,
          fulfilled: false,
          opponent: OpponentKind.maia,
          userClock: Duration(seconds: seconds),
          speedrunAttemptId: id,
          speedrunStage: 0,
        ),
      for (var stage = 0; stage < speedrun.stages.length; stage++)
        if (complete || stage == 0)
          Attempt(
            positionId: speedrun.stages[stage].position.id,
            playedAt: day.add(Duration(minutes: minutes + stage)),
            outcome: AttemptOutcome.win,
            fulfilled: true,
            opponent: OpponentKind.maia,
            userClock: Duration(seconds: seconds),
            speedrunAttemptId: id,
            speedrunStage: stage,
          ),
    ];
    return SpeedrunScore.run(
      speedrun,
      SpeedrunAttempt(
        id: id,
        speedrunId: speedrun.id,
        startedAt: day,
        games: games,
      ),
    );
  }

  AchievementFacts facts({
    List<Attempt> games = const [],
    List<SpeedrunRun> runs = const [],
    Map<String, String> subcategoryOf = const {},
  }) => AchievementFacts(
    games: games,
    ladder: ladder,
    subcategoryOf: subcategoryOf,
    runs: runs,
    speedruns: speedruns,
  );

  const first = Achievement(id: 'first', type: AchievementType.firstFulfilled);

  test('a primeira partida cumprida desbloqueia first-fulfilled', () {
    expect(AchievementRules.earned(first, facts()), isFalse);
    expect(
      AchievementRules.earned(first, facts(games: [game(fulfilled: false)])),
      isFalse,
    );
    expect(AchievementRules.newlyEarned([first], facts(games: [game()]), {}), [
      first,
    ]);
  });

  test('newlyEarned não devolve o já desbloqueado e mantém a ordem', () {
    const stockfish = Achievement(
      id: 'sf',
      type: AchievementType.beatStockfish,
    );
    final f = facts(
      games: [
        game(),
        game(opponent: OpponentKind.stockfish),
      ],
    );

    expect(AchievementRules.newlyEarned([stockfish, first], f, {}), [
      stockfish,
      first,
    ]);
    expect(AchievementRules.newlyEarned([stockfish, first], f, {'first'}), [
      stockfish,
    ]);
  });

  test('degrau concluído: só com todos os desafios cumpridos', () {
    const rung = Achievement(
      id: 'r',
      type: AchievementType.rungCompleted,
      rungId: '1000',
    );
    const any = Achievement(id: 'any', type: AchievementType.rungCompleted);
    final queen = ladder[0].challenges[0].id;
    final rook = ladder[0].challenges[1].id;

    final half = facts(games: [game(challengeId: queen)]);
    expect(AchievementRules.earned(rung, half), isFalse);
    expect(AchievementRules.earned(any, half), isFalse);

    final full = facts(
      games: [
        game(challengeId: queen),
        game(challengeId: rook, fulfilled: false),
        game(challengeId: rook),
      ],
    );
    expect(AchievementRules.earned(rung, full), isTrue);
    expect(AchievementRules.earned(any, full), isTrue);
  });

  test('todos os níveis numa subcategoria', () {
    const queen = Achievement(
      id: 'q',
      type: AchievementType.allLevels,
      subcategory: 'queen',
    );
    final subcategoryOf = {'q1': 'queen', 'r1': 'rook'};
    final almost = [
      for (final level in AchievementRules.maiaLevels.skip(1))
        game(positionId: 'q1', level: level),
      game(positionId: 'r1', level: 1000),
    ];
    expect(
      AchievementRules.earned(
        queen,
        facts(games: almost, subcategoryOf: subcategoryOf),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        queen,
        facts(
          games: [
            ...almost,
            game(positionId: 'q1', level: 1000),
          ],
          subcategoryOf: subcategoryOf,
        ),
      ),
      isTrue,
    );
  });

  test('vencer um nível (só ele) e vencer o Stockfish', () {
    const beat2000 = Achievement(
      id: 'b',
      type: AchievementType.beatLevel,
      level: 2000,
    );
    const stockfish = Achievement(
      id: 'sf',
      type: AchievementType.beatStockfish,
    );
    expect(
      AchievementRules.earned(beat2000, facts(games: [game(level: 1800)])),
      isFalse,
    );
    // Vencer alguém mais forte não libera a conquista de outro personagem.
    expect(
      AchievementRules.earned(beat2000, facts(games: [game(level: 2200)])),
      isFalse,
    );
    expect(
      AchievementRules.earned(beat2000, facts(games: [game(level: 2000)])),
      isTrue,
    );
    expect(
      AchievementRules.earned(
        stockfish,
        facts(
          games: [game(opponent: OpponentKind.stockfish, fulfilled: false)],
        ),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        stockfish,
        facts(games: [game(opponent: OpponentKind.stockfish)]),
      ),
      isTrue,
    );
  });

  test('speedrun concluído: qualquer um, ou um final num grupo de ritmo', () {
    const any = Achievement(id: 'a', type: AchievementType.speedrunCompleted);
    Achievement of(PaceCategory pace, {String? speedrun}) => Achievement(
      id: 'p',
      type: AchievementType.speedrunCompleted,
      speedrunId: speedrun ?? endingSpeedrun.id,
      pace: pace,
    );
    const bullet = TimeControl(initial: Duration(minutes: 1));
    final endingBullet = SpeedrunPaces.withTime(endingSpeedrun, bullet);
    final paced = {...speedruns, endingBullet.id: endingBullet};
    AchievementFacts of2(List<SpeedrunRun> runs) =>
        AchievementFacts(runs: runs, speedruns: paced);

    expect(AchievementRules.earned(any, of2([])), isFalse);
    expect(
      AchievementRules.earned(
        any,
        of2([run(endingSpeedrun, 1, complete: false)]),
      ),
      isFalse,
    );
    expect(AchievementRules.earned(any, of2([run(rungSpeedrun, 2)])), isTrue);

    // O ritmo padrão (5+3) é blitz.
    final blitzRun = run(endingSpeedrun, 3);
    expect(
      AchievementRules.earned(of(PaceCategory.blitz), of2([blitzRun])),
      isTrue,
    );
    expect(
      AchievementRules.earned(of(PaceCategory.bullet), of2([blitzRun])),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        of(PaceCategory.bullet),
        of2([run(endingBullet, 4)]),
      ),
      isTrue,
    );
    // Outro speedrun no mesmo ritmo não conta.
    expect(
      AchievementRules.earned(
        of(PaceCategory.blitz, speedrun: 'ending.other'),
        of2([blitzRun]),
      ),
      isFalse,
    );
  });

  test('speedrun sem derrota, com e sem modalidade', () {
    const flawless = Achievement(
      id: 'f',
      type: AchievementType.flawlessSpeedrun,
    );
    const ending = Achievement(
      id: 'fe',
      type: AchievementType.flawlessSpeedrun,
      speedrunKind: 'ending',
    );
    final rungClean = run(rungSpeedrun, 1);
    expect(AchievementRules.earned(flawless, facts(runs: [rungClean])), isTrue);
    expect(AchievementRules.earned(ending, facts(runs: [rungClean])), isFalse);
    expect(
      AchievementRules.earned(
        ending,
        facts(runs: [run(endingSpeedrun, 2, losses: 1)]),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        flawless,
        facts(runs: [run(rungSpeedrun, 3, complete: false)]),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(ending, facts(runs: [run(endingSpeedrun, 4)])),
      isTrue,
    );
  });

  test('recorde melhorado: precisa de uma tentativa anterior pior', () {
    const improved = Achievement(
      id: 'ri',
      type: AchievementType.recordImproved,
    );
    final slow = run(rungSpeedrun, 1, seconds: 90);
    final fast = run(rungSpeedrun, 2, seconds: 60, minutes: 30);
    expect(AchievementRules.earned(improved, facts(runs: [slow])), isFalse);
    // A mais rápida veio antes: não melhorou.
    final slowLater = run(rungSpeedrun, 3, seconds: 90, minutes: 60);
    final fastFirst = run(rungSpeedrun, 4, seconds: 60);
    expect(
      AchievementRules.earned(improved, facts(runs: [slowLater, fastFirst])),
      isFalse,
    );
    expect(
      AchievementRules.earned(improved, facts(runs: [fast, slow])),
      isTrue,
    );
    // Speedruns diferentes não se comparam.
    expect(
      AchievementRules.earned(
        improved,
        facts(runs: [slow, run(endingSpeedrun, 5, seconds: 10, minutes: 30)]),
      ),
      isFalse,
    );
  });

  test('abaixo do tempo: desafio sem modalidade, speedrun com', () {
    const challenge = Achievement(
      id: 'c',
      type: AchievementType.underTime,
      under: Duration(seconds: 30),
    );
    const rung = Achievement(
      id: 'rs',
      type: AchievementType.underTime,
      under: Duration(seconds: 300),
      speedrunKind: 'rung',
    );
    expect(
      AchievementRules.earned(challenge, facts(games: [game(seconds: 20)])),
      isFalse,
      reason: 'partida solta não é desafio',
    );
    expect(
      AchievementRules.earned(
        challenge,
        facts(games: [game(seconds: 40, challengeId: 'x')]),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        challenge,
        facts(games: [game(seconds: 20, challengeId: 'x')]),
      ),
      isTrue,
    );
    // Duas etapas de 160 s: 320 s.
    expect(
      AchievementRules.earned(
        rung,
        facts(runs: [run(rungSpeedrun, 1, seconds: 160)]),
      ),
      isFalse,
    );
    expect(
      AchievementRules.earned(
        rung,
        facts(runs: [run(rungSpeedrun, 1, seconds: 100)]),
      ),
      isTrue,
    );
  });

  test('assets/achievements.json: todas as entradas válidas e ids únicos', () {
    final json = jsonDecode(
      File('assets/achievements.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = (json['achievements'] as List).cast<Map<String, dynamic>>();
    final parsed = entries.map(Achievement.fromJson).toList();

    expect(parsed, everyElement(isNotNull));
    final ids = parsed.map((a) => a!.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(parsed.map((a) => a!.type).toSet(), AchievementType.values.toSet());
    for (final entry in entries) {
      expect(Achievement.icons, contains(entry['icon']));
    }
    expect(
      parsed.firstWhere((a) => a!.id == 'challenge-under-30')!.under,
      const Duration(seconds: 30),
    );
  });
}
