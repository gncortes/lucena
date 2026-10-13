import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/game_snapshot.dart';
import 'package:lucena/domain/models/clock_settings.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/models/speedrun_pace.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/speedrun/view_models/speedrun_cubit.dart';

import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_ongoing_game_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_rating_repository.dart';
import '../../../testing/fakes/fake_progress_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_speedrun_repository.dart';

void main() {
  late FakeNow now;
  late FakeProgressRepository progress;
  late FakeSpeedrunRepository speedruns;
  late FakeOngoingGameRepository games;

  setUp(() {
    now = FakeNow(DateTime.utc(2026, 10, 4, 12));
    progress = FakeProgressRepository();
    speedruns = FakeSpeedrunRepository(progress);
    games = FakeOngoingGameRepository();
  });

  late FakeSettingsRepository settings;

  SpeedrunCubit build({
    UserProfile? profile,
    AppSettings saved = const AppSettings(),
  }) {
    settings = FakeSettingsRepository(saved);
    final cubit = SpeedrunCubit(
      journey: FakeJourneyRepository(),
      speedruns: speedruns,
      games: games,
      now: now,
      settings: settings,
      profile: profile == null ? null : FakeProfileRepository(profile),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> win(int attempt, int stage, int seconds) => progress.addAttempt(
    Attempt(
      positionId: 'basic.queen.0001',
      playedAt: now(),
      outcome: AttemptOutcome.win,
      fulfilled: true,
      opponent: OpponentKind.maia,
      userClock: Duration(seconds: seconds),
      speedrunAttemptId: attempt,
      speedrunStage: stage,
    ),
  );

  test('lista os speedruns sem recorde nem tentativa', () async {
    final cubit = build();
    await cubit.load();

    expect(cubit.state.all!.map((s) => s.speedrun.id), [
      'rung.1000',
      'ending.queen',
    ]);
    expect(cubit.state.all!.first.records.best, isNull);
    expect(cubit.state.all!.first.ongoing, isNull);
  });

  // A etapa da tentativa [attempt] no tabuleiro (o app fechou no meio dela).
  void onBoard(int attempt) => games.snapshot = GameSnapshot(
    startFen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
    mode: GameMode(speedrunId: 'rung.1000', speedrunAttemptId: attempt),
  );

  test('começar cria a tentativa no ritmo escolhido e grava o ritmo', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');

    final (speedrun, id) = (await cubit.startWith(SpeedrunPaces.standard))!;
    expect(speedrun.id, 'rung.1000');
    expect(speedrun.stages, isNotEmpty);
    onBoard(id);
    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    expect(cubit.state.selected!.ongoing!.attempt.id, id);
    expect(cubit.state.run!.currentStage, 0);
    expect((await settings.load()).clock.speedrunTime, SpeedrunPaces.standard);
  });

  test('a etapa no tabuleiro mantém a tentativa em andamento', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final (_, id) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(id, 0, 20);
    onBoard(id);

    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    expect(cubit.state.selected!.ongoing!.attempt.id, id);
    expect(cubit.state.run!.currentStage, 1);
    expect(cubit.state.selected!.abandoned, isEmpty);
  });

  test('entre etapas: a tentativa sem tabuleiro mantém progresso', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final (_, id) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(id, 0, 20);
    now.advance(const Duration(minutes: 5));

    await cubit.load(speedrunId: 'rung.1000', attemptId: id);

    expect(cubit.state.run!.abandoned, isFalse);
    expect(cubit.state.run!.currentStage, 1);
    expect(cubit.state.selected!.ongoing!.attempt.id, id);
    expect(cubit.state.selected!.abandoned, isEmpty);
    final route = Uri.parse((await cubit.resume())!);
    expect(route.queryParameters['stage'], '1');
    expect(route.queryParameters['attempt'], id.toString());
    expect(cubit.state.selected!.records.completed, isEmpty);
  });

  for (final marathon in [false, true]) {
    test('${marathon ? "Maratona" : "Clássico"}: reconstrução entre etapas '
        'retoma terceira etapa e preserva tempo', () async {
      final template = marathon ? sampleMarathon : sampleSpeedruns[1];
      // O ritmo escolhido pertence ao ID persistido; ID sem sufixo é 5+3.
      final base = SpeedrunPaces.withTime(template, sampleSpeedrunTime);
      final attempt = await speedruns.start(base.id, now());
      await win(attempt.id, 0, 20);
      await win(attempt.id, 1, 30);
      // Cubit novo, mesmos repositórios persistidos, sem GameSnapshot.
      final restored = SpeedrunCubit(
        journey: FakeJourneyRepository(speedruns: [template]),
        speedruns: speedruns,
        games: games,
        now: now,
      );
      addTearDown(restored.close);
      await restored.load(speedrunId: base.id);
      expect(restored.state.selected!.ongoing!.currentStage, 2);
      final route = Uri.parse((await restored.resume())!);
      expect(route.queryParameters['stage'], '2');
      expect(route.queryParameters['attempt'], attempt.id.toString());
      expect((await speedruns.attempt(attempt.id))!.abandonedAt, isNull);
      if (marathon) {
        final remaining = base.time.initial - const Duration(seconds: 50);
        expect(
          route.queryParameters['white'],
          base.time.copyWith(initial: remaining).code,
        );
      }
    });
  }

  test('concluída: vira recorde e mostra o recorde de antes', () async {
    final cubit = build();
    await cubit.load(speedrunId: 'rung.1000');
    final (_, first) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(first, 0, 30);
    await win(first, 1, 40);
    now.advance(const Duration(hours: 1));
    final (_, second) = (await cubit.startWith(SpeedrunPaces.standard))!;
    await win(second, 0, 20);
    await win(second, 1, 30);

    await cubit.load(speedrunId: 'rung.1000', attemptId: second);

    expect(cubit.state.run!.completed, isTrue);
    expect(cubit.state.selected!.records.best, const Duration(seconds: 50));
    expect(cubit.state.previousBest, const Duration(seconds: 70));
    expect(cubit.state.selected!.ongoing, isNull);
    // A concluída não é abandonada ao abrir de novo.
    expect(cubit.state.selected!.abandoned, isEmpty);
  });

  group('ritmos', () {
    const threeTwo = TimeControl(
      initial: Duration(minutes: 3),
      increment: Duration(seconds: 2),
    );

    test('a lista abre no ritmo padrão (5+3)', () async {
      final cubit = build();
      await cubit.load();

      expect(cubit.state.pace, SpeedrunPaces.standard);
      expect(cubit.state.all!.first.speedrun.time, SpeedrunPaces.standard);
    });

    test('trocar o ritmo troca os speedruns da lista e fica gravado', () async {
      final cubit = build();
      await cubit.load();

      await cubit.choosePace(threeTwo);

      expect(cubit.state.pace, threeTwo);
      expect(cubit.state.all!.first.speedrun.id, 'rung.1000@180+2');
      expect(cubit.state.all!.first.speedrun.stages.first.time, threeTwo);
      expect((await settings.load()).clock.speedrunTime, threeTwo);
    });

    test('cada ritmo tem os seus recordes', () async {
      final cubit = build();
      await cubit.load(speedrunId: 'rung.1000');
      final (speedrun, attempt) = (await cubit.startWith(threeTwo))!;
      expect(speedrun.id, 'rung.1000@180+2');
      await win(attempt, 0, 20);
      await win(attempt, 1, 30);

      await cubit.load();
      // No 3+2, o recorde; no 5+3, nada.
      expect(cubit.state.all!.first.records.best, const Duration(seconds: 50));
      await cubit.choosePace(SpeedrunPaces.standard);
      expect(cubit.state.all!.first.records.best, isNull);
    });

    test('trocar ritmo preserva a tentativa pela metade', () async {
      final cubit = build();
      await cubit.load(speedrunId: 'rung.1000');
      final (speedrun, attempt) = (await cubit.startWith(threeTwo))!;
      await cubit.choosePace(SpeedrunPaces.standard);

      await cubit.load();

      final attempts = await speedruns.attempts(speedrun.id);
      expect(attempts.single.id, attempt);
      expect(attempts.single.abandonedAt, isNull);
    });
  });

  group('ritmo inicial pelo nível', () {
    test(
      'sem ritmo escolhido, a lista e a Maratona abrem no do nível',
      () async {
        final expected = {
          RatingLevel.beginner: '900+10',
          RatingLevel.intermediate: '300+3',
          RatingLevel.master: '60+0',
        };
        for (final MapEntry(key: level, value: code) in expected.entries) {
          final cubit = build(profile: UserProfile(rating: level.rating));
          await cubit.load();
          expect(cubit.state.pace.code, code, reason: level.name);
          expect(cubit.state.marathonPace.code, code, reason: level.name);
        }
      },
    );

    test(
      'o ritmo escolhido vence o nível, e trocar o nível não muda nada',
      () async {
        const threeZero = TimeControl(initial: Duration(minutes: 3));
        final cubit = build(
          profile: UserProfile(rating: RatingLevel.beginner.rating),
          saved: const AppSettings(
            clock: ClockSettings(speedrunTime: threeZero),
          ),
        );
        await cubit.load();
        expect(cubit.state.pace, threeZero);
        // A Maratona tem o seu: sem escolha, ainda o do nível.
        expect(cubit.state.marathonPace.code, '900+10');
      },
    );
  });

  test('a dificuldade abre na do nível; sem perfil, todas', () async {
    final none = build();
    await none.load();
    expect(none.state.category, isNull);

    final master = build(
      profile: UserProfile(rating: RatingLevel.master.rating),
    );
    await master.load();
    expect(master.state.category, SpeedrunCategory.advanced);
    master.chooseCategory(SpeedrunCategory.beginner);
    // Reler a lista (voltando de um speedrun) não desfaz a escolha.
    await master.load();
    expect(master.state.category, SpeedrunCategory.beginner);

    final casual = build(profile: const UserProfile());
    await casual.load();
    expect(casual.state.category, SpeedrunCategory.beginner);
  });

  group('oferta e bônus de rating', () {
    late FakeRatingRepository rating;
    late FakeJourneyRepository journey;
    final marathonId = SpeedrunPaces.idFor(
      sampleMarathon.id,
      sampleSpeedrunTime,
    );
    final endingId = SpeedrunPaces.idFor(
      sampleSpeedruns[1].id,
      sampleSpeedrunTime,
    );
    final started = <int, String>{};

    SpeedrunCubit withRating({List<Speedrun>? speedrunsList}) {
      journey = FakeJourneyRepository(
        speedruns: speedrunsList ?? [...sampleSpeedruns, sampleMarathon],
      );
      rating = FakeRatingRepository(now: now)
        ..speedrunOf = (id) => started[id]!;
      settings = FakeSettingsRepository(const AppSettings());
      final cubit = SpeedrunCubit(
        journey: journey,
        speedruns: speedruns,
        games: games,
        now: now,
        settings: settings,
        rating: rating,
      );
      addTearDown(cubit.close);
      return cubit;
    }

    Future<int> complete(String speedrunId, int stages) async {
      final attempt = await speedruns.start(speedrunId, now());
      started[attempt.id] = speedrunId;
      for (var index = 0; index < stages; index++) {
        await win(attempt.id, index, 10);
      }
      return attempt.id;
    }

    test('a oferta da Maratona é a do clássico ×1,5', () async {
      final cubit = withRating();

      await cubit.load(speedrunId: endingId);
      final classic = cubit.state.offer;
      await cubit.load(speedrunId: marathonId);

      // 1150 no Blitz iniciante: 70 no clássico; ×1,5 = 107,8 → 110.
      expect(classic, 70);
      expect(cubit.state.offer, 110);
      expect(cubit.state.bonus, isNull);
    });

    test('já pago no grupo: a oferta some', () async {
      final cubit = withRating();
      await complete(marathonId, sampleMarathon.stages.length);

      await cubit.load(speedrunId: marathonId);

      expect(cubit.state.offer, 0);
    });

    test('o clássico concluído deixa a Maratona do final em 75%', () async {
      final cubit = withRating();
      final id = await complete(endingId, sampleSpeedruns[1].stages.length);
      // Abrir o resumo paga o que a partida não gravou.
      await cubit.load(speedrunId: endingId, attemptId: id);

      await cubit.load(speedrunId: marathonId);

      // O rating subiu 70: cheio = 1220 × 10% × 0,45 × 1,5 = 82 → 80; 75% = 60.
      expect(cubit.state.offer, 60);
    });

    test('trocar o ritmo da Maratona recalcula a oferta', () async {
      final cubit = withRating();
      await cubit.load(speedrunId: marathonId);
      final blitz = cubit.state.offer;

      const rapid = TimeControl(
        initial: Duration(minutes: 15),
        increment: Duration(seconds: 10),
      );
      await cubit.chooseMarathonPace(rapid);
      await cubit.load(
        speedrunId: SpeedrunPaces.idFor(sampleMarathon.id, rapid),
      );

      expect(cubit.state.selected!.speedrun.time, rapid);
      expect(cubit.state.offer, isNot(blitz));
      expect(cubit.state.offer, greaterThan(0));
    });

    test('Maratona só da Jornada não dá bônus', () async {
      final cubit = withRating(
        speedrunsList: [
          ...sampleSpeedruns,
          sampleMarathon.copyWith(journeyOnly: true),
        ],
      );

      await cubit.load(speedrunId: marathonId);

      expect(cubit.state.offer, 0);
    });

    test('o resumo concluído traz o bônus, pago em silêncio', () async {
      final cubit = withRating();
      final id = await complete(marathonId, sampleMarathon.stages.length);

      await cubit.load(speedrunId: marathonId, attemptId: id);

      expect(cubit.state.bonus!.points, 110);
      expect(cubit.state.bonus!.attemptId, id);
      expect(rating.entries, hasLength(1));
    });

    test('tentativa que não concluiu não tem bônus', () async {
      final cubit = withRating();
      final attempt = await speedruns.start(marathonId, now());
      started[attempt.id] = marathonId;
      await win(attempt.id, 0, 10);

      await cubit.load(speedrunId: marathonId, attemptId: attempt.id);

      expect(cubit.state.bonus, isNull);
      expect(cubit.state.offer, 110);
    });
  });
}
