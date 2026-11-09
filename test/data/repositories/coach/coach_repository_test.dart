import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/coach/coach_repository.dart';
import 'package:lucena/data/services/firebase/coach_service.dart';
import 'package:lucena/data/services/preferences_service.dart';
import 'package:lucena/domain/models/coach/coach.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../testing/fakes/fake_coach_repository.dart';
import '../../../../testing/coach_fixtures.dart';

void main() {
  late FakeCoachService service;
  late StreamController<String?> uids;
  String? uid;

  CloudCoachRepository open() => CloudCoachRepository(
    service,
    PreferencesService(),
    uids: uids.stream,
    currentUid: () => uid,
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    service = FakeCoachService()..games['u1'] = CoachFixtures.jsonList();
    uids = StreamController<String?>.broadcast();
    uid = 'u1';
  });

  tearDown(() => uids.close());

  test('lista as partidas da mais nova', () async {
    final list = await open().games().first;
    expect(list, hasLength(5));
    expect(list.first.opponent.name, 'Tiago_Rook');
    expect(
      list.map((p) => p.moveAt).toList(),
      [for (final p in list) p.moveAt]..sort((a, b) => b.compareTo(a)),
    );
  });

  test('sem conta do Lucena: vazio e ligar dá semLogin', () async {
    uid = null;
    final repo = open();
    expect(await repo.games().first, isEmpty);
    expect(await repo.account().first, isNull);
    await expectLater(
      repo.linkAccount(Platform.lichess, 'x'),
      throwsA(
        isA<LinkAccountException>().having(
          (e) => e.failure,
          'falha',
          LinkAccountFailure.noLogin,
        ),
      ),
    );
  });

  test('ligar a conta chama a Function e traduz o erro', () async {
    final repo = open();
    await repo.linkAccount(Platform.chesscom, '  gabriel ');
    expect(service.calls.single.$1, CoachFunctions.linkAccount);
    expect(service.calls.single.$2, {
      'plataforma': 'chesscom',
      'usuario': 'gabriel',
    });
    for (final (code, failure) in [
      ('not-found', LinkAccountFailure.doesNotExist),
      ('permission-denied', LinkAccountFailure.noPlan),
      ('unavailable', LinkAccountFailure.noResponse),
    ]) {
      service.callError = code;
      await expectLater(
        repo.linkAccount(Platform.lichess, 'x'),
        throwsA(
          isA<LinkAccountException>().having(
            (e) => e.failure,
            'falha',
            failure,
          ),
        ),
      );
    }
  });

  test(
    'o progresso fica no aparelho, chega à tela e vai ao servidor',
    () async {
      final repo = open();
      final id = CoachFixtures.idTiago;
      final emitted = <GameProgress?>[];
      final sub = repo.game(id).listen((p) => emitted.add(p?.progress));
      await pumpEventQueue();
      final pr = GameProgress.empty.withValue(
        const ExerciseResult(n: 1, solved: true, points: 3),
      );
      await repo.saveProgress(id, pr);
      await pumpEventQueue();
      expect(emitted.last?.doneCount, 1);
      expect(service.savedProgresses.single.$3, {
        'feitos': 1,
        'acertos': 1,
        'pontos': 3,
        'resultados': {'1': true},
      });
      await sub.cancel();

      // Fechar e abrir o app: o progresso volta do aparelho.
      final reopened = open();
      expect((await reopened.progress(id)).next(4), 2);
    },
  );

  test('sem nada no aparelho: usa o espelho do servidor', () async {
    final id = CoachFixtures.idTiago;
    service.games['u1']![id] = {
      ...CoachFixtures.tiagoJson(),
      'progresso': {'feitos': 4, 'acertos': 2, 'pontos': 6},
    };
    final pr = await open().progress(id);
    expect(pr.isComplete(4), isTrue);
    expect(pr.corrects, 2);
  });

  test('trocar de conta troca as partidas', () async {
    final repo = open();
    final emitted = <int>[];
    final sub = repo.games().listen((l) => emitted.add(l.length));
    await pumpEventQueue();
    uid = 'u2';
    uids.add('u2');
    await pumpEventQueue();
    expect(emitted, [5, 0]);
    await sub.cancel();
  });

  test('analisar pede à Function com o aviso', () async {
    await open().analyze('lichess_DeF67890', notify: false);
    expect(service.calls.single.$1, CoachFunctions.analyze);
    expect(service.calls.single.$2, {
      'partida': 'lichess_DeF67890',
      'avisar': false,
    });
  });

  test('config e modelos ilegíveis caem no padrão', () async {
    final repo = open();
    expect((await repo.config()).exercisesPerGame, 4);
    service.configDoc = {'exerciciosPorPartida': 2};
    expect((await repo.config()).exercisesPerGame, 2);
    expect(await repo.modelGames('B12'), isEmpty);
  });

  test('o fake leva a partida até pronta', () async {
    final fake = FakeCoachRepository.withData()..analyzeCompletes = true;
    await fake.analyze('lichess_DeF67890');
    final p = await fake.game('lichess_DeF67890').first;
    expect(p!.ready, isTrue);
    expect(p.opponent.name, 'lmatos88');
    expect(p.exercises, hasLength(4));
  });
}
