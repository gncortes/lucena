import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/config/remote_defaults.dart';
import 'package:lucena/data/repositories/update/app_update_repository.dart';
import 'package:lucena/domain/use_cases/update_policy.dart';
import 'package:lucena/ui/update/view_models/update_cubit.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_app_update_repository.dart';
import '../../../testing/fakes/fake_remote_flags_repository.dart';

void main() {
  late FakeRemoteFlagsRepository flags;
  late FakeAppUpdateRepository updates;
  late UpdateCubit cubit;

  setUp(() {
    flags = FakeRemoteFlagsRepository();
    updates = FakeAppUpdateRepository(
      info: const PlayUpdateInfo(available: true, flexibleAllowed: true),
    );
    cubit = UpdateCubit(flags: flags, updates: updates);
  });

  tearDown(() => cubit.close());

  test('em dia, nem pergunta à Play e busca sem esperar', () async {
    await cubit.start();

    expect(cubit.state.decision, UpdateDecision.none);
    expect(updates.checks, 0);
    expect(flags.refreshes, 1);
  });

  test('abaixo da mínima, obrigatória e tenta a imediata da Play', () async {
    flags.updateMinBuild = 101;
    updates.info = const PlayUpdateInfo(
      available: true,
      immediateAllowed: true,
    );

    await cubit.start();
    await cubit.check();

    expect(cubit.state.required, isTrue);
    expect(updates.immediates, 1);
  });

  test('uma chave update_ nova confere de novo', () async {
    await cubit.start();
    flags.updateRecommendedBuild = 110;

    flags.change({RemoteKeys.adsEnabled});
    await pumpEventQueue();
    expect(cubit.state.decision, UpdateDecision.none);

    flags.change({RemoteKeys.updateRecommendedBuild});
    await pumpEventQueue();
    expect(cubit.state.decision, UpdateDecision.recommended);
    expect(cubit.state.target, 110);
  });

  test('a recomendada mostrada fica vista para o mesmo valor', () async {
    flags.updateRecommendedBuild = 110;
    await cubit.start();

    await cubit.recommendedShown();
    await cubit.check();

    expect(updates.seen, 110);
    expect(cubit.state.shown, isTrue);
    // Volta numa abertura nova só com um valor maior.
    final next = UpdateCubit(flags: flags, updates: updates);
    addTearDown(next.close);
    await next.start();
    expect(next.state.decision, UpdateDecision.none);
    flags.updateRecommendedBuild = 120;
    await next.check();
    expect(next.state.decision, UpdateDecision.recommended);
  });

  test('Atualizar baixa em segundo plano e fica pronto', () async {
    flags.updateRecommendedBuild = 110;
    await cubit.start();
    updates.holdFlexible = Completer<void>();

    final download = cubit.updateRecommended();
    expect(cubit.state.downloading, isTrue);
    updates.holdFlexible!.complete();
    await download;

    expect(cubit.state.downloading, isFalse);
    expect(cubit.state.ready, isTrue);
    await cubit.restart();
    expect(updates.completes, 1);
  });

  test('fora da Play, Atualizar abre a loja', () async {
    flags.updateRecommendedBuild = 110;
    updates.info = const PlayUpdateInfo();
    await cubit.start();

    await cubit.updateRecommended();

    expect(updates.flexibles, 0);
    expect(updates.storeOpens, 1);
  });

  group('estatísticas', () {
    late FakeAnalyticsRepository analytics;

    setUp(() async {
      analytics = FakeAnalyticsRepository();
      await cubit.close();
      cubit = UpdateCubit(flags: flags, updates: updates, analytics: analytics);
    });

    test(
      'a obrigatória conta atualizacao_vista uma vez por abertura',
      () async {
        flags.updateMinBuild = 101;
        await cubit.start();
        await cubit.check();
        await cubit.openStore();

        final seen = analytics.eventsNamed('atualizacao_vista').single;
        expect(seen.params['tipo'], 'obrigatoria');
        expect(seen.params['build_pedido'], 101);
        final action = analytics.eventsNamed('atualizacao_acao').single;
        expect(action.params['acao'], 'atualizar');
        expect(action.params['via'], 'loja');
      },
    );

    test('a recomendada conta a vista, o agora não e o atualizar', () async {
      flags.updateRecommendedBuild = 110;
      await cubit.start();
      await cubit.recommendedShown();
      await cubit.recommendedLater();
      await cubit.updateRecommended();

      final seen = analytics.eventsNamed('atualizacao_vista').single;
      expect(seen.params['tipo'], 'recomendada');
      expect(seen.params['build_pedido'], 110);
      expect(
        analytics.eventsNamed('atualizacao_acao').map((e) => e.params['acao']),
        ['agora_nao', 'atualizar'],
      );
      expect(
        analytics.eventsNamed('atualizacao_acao').first.params['via'],
        'play_no_app',
      );
    });
  });
}
