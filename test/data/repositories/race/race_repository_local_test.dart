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
      theme: RaceTheme.rook,
    ).withAnswer(answer(correct: true));
    await reopen().saveOngoing(run);

    final back = (await reopen().ongoing())!;
    expect(back.startedAt, start);
    expect(back.theme, RaceTheme.rook);
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
    expect(await reopen().theme(), isNull);
    await reopen().setTheme(RaceTheme.rook);
    expect(await reopen().theme(), RaceTheme.rook);
    await reopen().setTheme(null);
    expect(await reopen().theme(), isNull);
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

  test('o banco do app tem problemas de vários temas', () async {
    final problems = await reopen().problems();
    expect(problems.length, greaterThanOrEqualTo(10));
    expect(
      problems.map((p) => p.theme).toSet(),
      containsAll(RaceTheme.values.take(3)),
    );
  });
}
