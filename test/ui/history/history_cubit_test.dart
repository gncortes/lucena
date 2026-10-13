import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/history_filter.dart';
import 'package:lucena/domain/models/pace.dart';
import 'package:lucena/domain/models/speedrun.dart';
import 'package:lucena/domain/use_cases/rating_period.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import 'history_harness.dart';

void main() {
  late HistoryWorld world;
  const win = AttemptOutcome.win;
  const loss = AttemptOutcome.loss;
  const blitz = TimeControl(
    initial: Duration(minutes: 3),
    increment: Duration(seconds: 2),
  );

  setUp(() => world = HistoryWorld());

  test('lê as partidas, sem bônus nem etapas de speedrun', () async {
    await world.play([win, loss, win]);
    await world.speedrun(time: blitz);
    final cubit = world.cubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.loaded, isTrue);
    expect(cubit.state.games, hasLength(3));
    expect(cubit.state.classic, hasLength(1));
    expect(cubit.state.marathons, isEmpty);
  });

  test('paga o bônus pendente antes de ler', () async {
    await world.play([win, win, win]);
    await world.speedrun(time: blitz);
    final cubit = world.cubit();
    addTearDown(cubit.close);
    expect(await world.rating.speedrunBonuses(), isEmpty);

    await cubit.load();

    expect(await world.rating.speedrunBonuses(), hasLength(1));
    expect(cubit.state.history.any((entry) => entry.isBonus), isTrue);
    // O bônus não vira linha de partida e o placar não o conta.
    expect(cubit.state.games, hasLength(3));
  });

  test('aba e filtros gravam e voltam num cubit novo', () async {
    await world.play([win, loss]);
    final first = world.cubit();
    addTearDown(first.close);
    await first.load();

    await first.selectTab(HistoryTab.marathon);
    await first.applyGamesFilter(
      const GamesHistoryFilter(period: RatingPeriod.week, result: loss),
    );
    await first.applyClassicFilter(
      const SpeedrunHistoryFilter(pace: PaceCategory.blitz),
    );
    await first.applyMarathonFilter(
      const SpeedrunHistoryFilter(level: SpeedrunCategory.advanced),
    );

    final second = world.cubit();
    addTearDown(second.close);
    await second.load();

    expect(second.state.tab, HistoryTab.marathon);
    expect(
      second.state.gamesFilter,
      const GamesHistoryFilter(period: RatingPeriod.week, result: loss),
    );
    expect(
      second.state.classicFilter,
      const SpeedrunHistoryFilter(pace: PaceCategory.blitz),
    );
    expect(
      second.state.marathonFilter,
      const SpeedrunHistoryFilter(level: SpeedrunCategory.advanced),
    );
  });

  test('recarregar mantém a aba e os filtros do momento', () async {
    await world.play([win, loss]);
    final cubit = world.cubit();
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.selectTab(HistoryTab.classic);

    await cubit.load();

    expect(cubit.state.tab, HistoryTab.classic);
  });

  test('?game= abre em Partidas com filtros zerados e não grava', () async {
    final ids = await world.play([win, loss]);
    world.settings = FakeSettingsRepository(
      const AppSettings(
        historyTab: HistoryTab.marathon,
        historyGamesFilter: GamesHistoryFilter(result: win),
      ),
    );
    final cubit = world.cubit(highlightedGame: ids.first);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.tab, HistoryTab.games);
    expect(cubit.state.gamesFilter.isEmpty, isTrue);
    expect(cubit.state.highlighted, ids.first);
    expect(world.settings.saved, isEmpty);
    expect(world.settings.settings.historyTab, HistoryTab.marathon);
  });

  test('id de partida que não existe é ignorado', () async {
    await world.play([win]);
    final cubit = world.cubit(highlightedGame: 999);
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.highlighted, isNull);
  });

  test('gravar a aba não apaga as outras preferências', () async {
    world.settings = FakeSettingsRepository(
      const AppSettings(
        historyClassicFilter: SpeedrunHistoryFilter(pace: PaceCategory.rapid),
      ),
    );
    final cubit = world.cubit();
    addTearDown(cubit.close);
    await cubit.load();

    await cubit.selectTab(HistoryTab.classic);

    expect(
      world.settings.settings.historyClassicFilter,
      const SpeedrunHistoryFilter(pace: PaceCategory.rapid),
    );
    expect(world.settings.settings.historyTab, HistoryTab.classic);
  });
}
