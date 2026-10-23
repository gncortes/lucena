import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/race/race_repository_local.dart';
import 'package:lucena/data/services/asset_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/race.dart';
import 'package:lucena/domain/use_cases/race_rules.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_now.dart';

/// Lê os arquivos do próprio projeto, como o app lê os dele.
class _ProjectBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  final start = DateTime.utc(2026, 1, 1, 12);
  late FakeNow now;

  // Cada chamada cria repositório e serviço novos, como ao reabrir o app.
  LocalRaceRepository reopen() => LocalRaceRepository(
    AssetService(_ProjectBundle()),
    PreferencesService(),
    now,
  );

  RaceAnswer answer({required bool correct, int level = 1000}) => RaceAnswer(
    problemId: 'race.001',
    level: level,
    move: 'a1g7',
    correct: correct,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = FakeNow(start);
  });

  test(
    'sem nada gravado: sem recorde, histórico nem Corrida em andamento',
    () async {
      final repository = reopen();
      expect((await repository.record()).isEmpty, isTrue);
      expect(await repository.history(), isEmpty);
      expect(await repository.ongoing(), isNull);
    },
  );

  test('a Corrida em andamento volta com o instante em que começou', () async {
    final run = RaceRun(
      startedAt: start,
      filter: const RaceFilter(goal: RaceGoal.both, excluded: {'queen'}),
    ).withAnswer(answer(correct: true));
    await reopen().saveOngoing(run);

    final back = (await reopen().ongoing())!;
    expect(back.startedAt, start);
    expect(
      back.filter,
      const RaceFilter(goal: RaceGoal.both, excluded: {'queen'}),
    );
    expect(back.corrects, 1);
    // O app ficou fechado 2 minutos: o tempo correu.
    final later = start.add(const Duration(minutes: 2));
    expect(RaceRules.remaining(back, later), const Duration(minutes: 1));
  });

  test('terminar guarda recorde e histórico e encerra a Corrida', () async {
    final run = RaceRun(startedAt: start)
        .withAnswer(answer(correct: true, level: 1300))
        .withAnswer(answer(correct: false));
    await reopen().saveOngoing(run);
    now.advance(const Duration(minutes: 3));

    final outcome = await reopen().finish(run, RaceEnd.time);

    expect(outcome.isRecord, isTrue);
    expect(outcome.previous.isEmpty, isTrue);
    final repository = reopen();
    expect((await repository.record()).corrects, 1);
    expect((await repository.record()).hardest, 1300);
    expect(await repository.ongoing(), isNull);
    final history = await repository.history();
    expect(history, hasLength(1));
    expect(history.single.end, RaceEnd.time);
    expect(history.single.finishedAt, now());
  });

  group('duração', () {
    test('sem escolha vale 3 minutos, e a escolha persiste', () async {
      expect(await reopen().duration(), RaceDuration.threeMinutes);
      await reopen().setDuration(RaceDuration.fiveMinutes);
      expect(await reopen().duration(), RaceDuration.fiveMinutes);
    });

    test('o recorde de antes (chave antiga) é o de 3 minutos', () async {
      await PreferencesService().setString(
        'race.record',
        '{"corrects":7,"hardest":1200}',
      );
      final repository = reopen();
      expect((await repository.record()).corrects, 7);
      expect(
        (await repository.record(duration: RaceDuration.fiveMinutes)).isEmpty,
        isTrue,
      );
    });

    test('cada duração tem o seu recorde e a Corrida guarda a dela', () async {
      final three = RaceRun(startedAt: start)
          .withAnswer(answer(correct: true, level: 800));
      final five = RaceRun(startedAt: start, duration: RaceDuration.fiveMinutes)
          .withAnswer(answer(correct: true, level: 900))
          .withAnswer(answer(correct: true, level: 950));
      await reopen().finish(three, RaceEnd.time);
      await reopen().finish(five, RaceEnd.time);
      final repository = reopen();
      expect((await repository.record()).corrects, 1);
      expect(
        (await repository.record(duration: RaceDuration.fiveMinutes)).corrects,
        2,
      );
      final history = await repository.history();
      expect(history.first.run.duration, RaceDuration.fiveMinutes);
      expect(history.last.run.duration, RaceDuration.threeMinutes);
    });
  });

  test(
    'o histórico guarda por problema o tipo, o nível e o resultado',
    () async {
      const right = RaceAnswer(
        problemId: 'race.300.01',
        level: 300,
        subcategory: 'queen',
        move: 'a1a8',
        correct: true,
      );
      const slow = RaceAnswer(
        problemId: 'race.350.01',
        level: 350,
        subcategory: 'rook',
        move: 'a1a2',
        correct: false,
        slower: true,
      );
      const wrong = RaceAnswer(
        problemId: 'race.400.01',
        level: 400,
        subcategory: 'pawnVsKing',
        defend: true,
        move: 'a7a8r',
        correct: false,
      );
      final run = RaceRun(startedAt: start)
          .withAnswer(right)
          .withAnswer(slow)
          .withAnswer(wrong);
      await reopen().finish(run, RaceEnd.errors);
      final saved = (await reopen().history()).single.run.answers;
      expect(
        [for (final a in saved) a.subcategory],
        ['queen', 'rook', 'pawnVsKing'],
      );
      expect([for (final a in saved) a.defend], [false, false, true]);
      expect([for (final a in saved) a.level], [300, 350, 400]);
      expect(
        [for (final a in saved) a.kind],
        [
          RaceOutcomeKind.correct,
          RaceOutcomeKind.slowWin,
          RaceOutcomeKind.wrong,
        ],
      );
    },
  );

  test('o recorde só sobe', () async {
    final good = RaceRun(startedAt: start)
        .withAnswer(answer(correct: true))
        .withAnswer(answer(correct: true));
    final weak = RaceRun(startedAt: start).withAnswer(answer(correct: true));
    await reopen().finish(good, RaceEnd.time);

    final outcome = await reopen().finish(weak, RaceEnd.time);

    expect(outcome.isRecord, isFalse);
    expect((await reopen().record()).corrects, 2);
    expect(await reopen().history(), hasLength(2));
  });

  test(
    'o histórico guarda só as últimas e a mais recente vem primeiro',
    () async {
      for (var i = 0; i < LocalRaceRepository.historyLimit + 3; i++) {
        now.advance(const Duration(minutes: 1));
        await reopen().finish(RaceRun(startedAt: start), RaceEnd.time);
      }
      final history = await reopen().history();
      expect(history, hasLength(LocalRaceRepository.historyLimit));
      expect(history.first.finishedAt.isAfter(history.last.finishedAt), isTrue);
    },
  );

  test('sair descarta a Corrida em andamento sem recorde', () async {
    final repository = reopen();
    await repository.saveOngoing(RaceRun(startedAt: start));
    await repository.discardOngoing();
    expect(await reopen().ongoing(), isNull);
    expect(await reopen().history(), isEmpty);
  });

  test('gravação ilegível vira "sem nada"', () async {
    final preferences = PreferencesService();
    await preferences.setString('race.ongoing', '{não é json');
    await preferences.setString('race.record', '[1,2]');
    final repository = reopen();
    expect(await repository.ongoing(), isNull);
    expect((await repository.record()).isEmpty, isTrue);
  });

  test(
    'o aquecimento é oferecido até o jogador pedir para não perguntar',
    () async {
      expect(await reopen().offersWarmUp(), isTrue);
      await reopen().setOffersWarmUp(value: false);
      expect(await reopen().offersWarmUp(), isFalse);
    },
  );

  test('o filtro de finais persiste entre aberturas', () async {
    expect(await reopen().filter(), const RaceFilter());
    const chosen = RaceFilter(goal: RaceGoal.defend, excluded: {'rook'});
    await reopen().setFilter(chosen);
    expect(await reopen().filter(), chosen);
    await reopen().setFilter(const RaceFilter());
    expect(await reopen().filter(), const RaceFilter());
  });

  test(
    'o padrão da oferta pode vir desligado (cenários de ponta a ponta)',
    () async {
      final repository = LocalRaceRepository(
        AssetService(_ProjectBundle()),
        PreferencesService(),
        now,
        offersWarmUpByDefault: false,
      );
      expect(await repository.offersWarmUp(), isFalse);
    },
  );

  test('o banco do app tem as 8 categorias e os dois objetivos', () async {
    final problems = await reopen().problems();
    expect(problems.length, greaterThanOrEqualTo(10));
    expect(
      problems.map((p) => p.category).toSet(),
      containsAll(RaceRules.categories),
    );
    expect(problems.map((p) => p.defend).toSet(), {false, true});
  });
}
