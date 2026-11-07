import 'package:lucena/data/repositories/activity/activity_repository.dart';

import '../../../testing/fakes/fake_activity_repository.dart';

import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/featured/featured_progress_repository.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/ui/featured/view_models/featured_endgame_cubit.dart';
import 'package:lucena/ui/featured/view_models/find_move_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_featured_repositories.dart';

class _Preferences extends PreferencesService {
  final values = <String, String>{};
  Completer<void>? gate;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;

  @override
  Future<String?> getString(String key) async {
    if (failRead && key.endsWith('.findMove')) {
      throw StateError('read failed');
    }
    return values[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    writes++;
    await gate?.future;
    if (failWrite) throw StateError('write failed');
    values[key] = value;
  }
}

class _PendingActivity extends FakeActivityRepository {
  final entered = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> markToday() async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    await super.markToday();
  }
}

void main() {
  late _Preferences preferences;
  final endgame = sampleFeaturedCatalog().endgame('b')!;
  LocalFeaturedProgressRepository repository() =>
      LocalFeaturedProgressRepository(preferences);

  FeaturedEndgameCubit parent() {
    final cubit = FeaturedEndgameCubit(
      id: 'b',
      featured: FakeFeaturedRepository(sampleFeaturedCatalog()),
      progress: repository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<FindMoveCubit> reopen() async {
    final loader = parent();
    await loader.load();
    expect(loader.state.failure, isNull);
    final cubit = FindMoveCubit(
      endgame: loader.state.endgame!,
      progress: repository(),
      initial: loader.state.findMove,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = _Preferences();
  });

  test('reabertura aguarda gravação anterior inclusive Activity', () async {
    final activity = _PendingActivity();
    final writer = ActiveFeaturedProgressRepository(repository(), activity);
    final first = FindMoveCubit(endgame: endgame, progress: writer);
    final pending = first.reveal();
    await activity.entered.future;
    await first.close();
    var readCompleted = false;
    final nextRead = repository().findMove(endgame).then((value) {
      readCompleted = true;
      return value;
    });
    try {
      await Future<void>.delayed(Duration.zero);
      expect(
        readCompleted,
        isFalse,
        reason: 'reabrir deve esperar a operação persistente inteira',
      );
    } finally {
      activity.release.complete();
      await pending;
    }
    final restored = await nextRead;
    expect(restored!.phase, FindMovePhase.revealed);
    final second = FindMoveCubit(
      endgame: endgame,
      progress: repository(),
      initial: restored,
    );
    addTearDown(second.close);
    await second.retry();
    await second.play(Move.parse('c8c7')!);
    expect((await repository().findMove(endgame))!.phase, FindMovePhase.wrong);
    expect((await repository().findMove(endgame))!.attempts, 2);
  });

  test('novo parent e repositório retomam wrong, dica e asking', () async {
    var cubit = await reopen();
    await cubit.play(Move.parse('c8c7')!);
    await cubit.showHint();
    cubit = await reopen();
    expect(cubit.state.phase, FindMovePhase.wrong);
    expect(cubit.state.attempts, 1);
    expect(cubit.state.hint, isTrue);
    await cubit.retry();
    cubit = await reopen();
    expect(cubit.state.phase, FindMovePhase.asking);
    expect(cubit.state.attempts, 1);
    expect(cubit.state.hint, isTrue);
  });

  for (final solved in [true, false]) {
    test('retoma ${solved ? 'solved' : 'revealed'} sem refazer', () async {
      var cubit = await reopen();
      if (solved) {
        await cubit.play(Move.parse('c8b8')!);
      } else {
        await cubit.reveal();
      }
      cubit = await reopen();
      expect(
        cubit.state.phase,
        solved ? FindMovePhase.solved : FindMovePhase.revealed,
      );
      expect(await repository().played(), {'b'});
      if (!solved) {
        await cubit.retry();
        cubit = await reopen();
        expect(cubit.state.phase, FindMovePhase.asking);
        expect(cubit.state.attempts, 1);
        expect(cubit.state.hint, isFalse);
      }
    });
  }

  test('isola IDs e invalida FEN ou soluções alterados', () async {
    final cubit = await reopen();
    await cubit.showHint();
    expect(
      await repository().findMove(sampleFeaturedCatalog().endgame('a')!),
      isNull,
    );
    for (final change in ['id', 'fen', 'solutions']) {
      final changed = FeaturedEndgame(
        id: change == 'id' ? 'another' : endgame.id,
        kind: endgame.kind,
        origin: endgame.origin,
        fen: change == 'fen' ? '${endgame.fen} changed' : endgame.fen,
        goal: endgame.goal,
        white: endgame.white,
        black: endgame.black,
        suggested: endgame.suggested,
        solutions: change == 'solutions'
            ? const ['changed']
            : endgame.solutions,
      );
      expect(await repository().findMove(changed), isNull);
    }
  });

  test('pending bloqueia duplicação e conserva fase até persistir', () async {
    final cubit = await reopen();
    preferences.gate = Completer<void>();
    final pending = cubit.play(Move.parse('c8c7')!);
    expect(cubit.state.phase, FindMovePhase.asking);
    expect(cubit.state.attempts, 0);
    expect(cubit.state.saving, 'play');
    await cubit.showHint();
    await cubit.reveal();
    await cubit.retry();
    await cubit.play(Move.parse('c8b8')!);
    expect(preferences.writes, 1);
    preferences.gate!.complete();
    await pending;
    expect(cubit.state.phase, FindMovePhase.wrong);
    expect(cubit.state.attempts, 1);
    expect(cubit.state.hint, isFalse);
    expect((await reopen()).state.attempts, 1);
  });

  test('reveal só publica fase depois de ambas as gravações', () async {
    final cubit = await reopen();
    preferences.gate = Completer<void>();
    final pending = cubit.reveal();
    expect(cubit.state.finished, isFalse);
    expect(cubit.state.saving, 'answer');
    preferences.gate!.complete();
    await pending;
    expect((await reopen()).state.phase, FindMovePhase.revealed);
  });

  test('hint e retry mantêm estado anterior enquanto salvam', () async {
    var cubit = await reopen();
    preferences.gate = Completer<void>();
    final hint = cubit.showHint();
    expect(cubit.state.hint, isFalse);
    expect(cubit.state.saving, 'hint');
    preferences.gate!.complete();
    await hint;
    preferences.gate = null;
    await cubit.reveal();
    preferences.gate = Completer<void>();
    final retry = cubit.retry();
    expect(cubit.state.phase, FindMovePhase.revealed);
    expect(cubit.state.hint, isTrue);
    expect(cubit.state.saving, 'retry');
    preferences.gate!.complete();
    await retry;
    cubit = await reopen();
    expect(cubit.state.phase, FindMovePhase.asking);
    expect(cubit.state.hint, isFalse);
    expect(cubit.state.attempts, 1);
  });

  test('falha markPlayed não publica conclusão e retry conclui', () async {
    final cubit = await reopen();
    preferences.failWrite = true;
    await cubit.reveal();
    expect(cubit.state.finished, isFalse);
    expect(cubit.state.failure, isNotNull);
    preferences.failWrite = false;
    await cubit.retrySave();
    expect((await reopen()).state.phase, FindMovePhase.revealed);
    expect(await repository().played(), {'b'});
  });

  test(
    'falha escrita preserva estado e retry grava o candidato exato',
    () async {
      final cubit = await reopen();
      preferences.failWrite = true;
      await cubit.play(Move.parse('c8c7')!);
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.phase, FindMovePhase.asking);
      expect(cubit.state.attempts, 0);
      await cubit.reveal();
      expect(preferences.writes, 1);
      preferences.failWrite = false;
      await cubit.retrySave();
      expect(cubit.state.failure, isNull);
      final restored = await reopen();
      expect(restored.state.phase, FindMovePhase.wrong);
      expect(restored.state.attempts, 1);
    },
  );

  test('leitura falha não recomeça; parent permite retry', () async {
    await (await reopen()).showHint();
    preferences.failRead = true;
    final loader = parent();
    await loader.load();
    expect(loader.state.failure, isNotNull);
    expect(loader.state.ready, isFalse);
    preferences.failRead = false;
    await loader.retryLoad();
    expect(loader.state.failure, isNull);
    expect(loader.state.findMove!.hint, isTrue);
    expect(loader.state.copyWith(played: true).findMove!.hint, isTrue);
  });

  test('checkpoint corrompido vira falha de leitura explícita', () async {
    preferences.values['featured.b.findMove'] = '{broken';
    final loader = parent();
    await loader.load();
    expect(loader.state.failure, isNotNull);
    expect(loader.state.ready, isFalse);
  });
}
