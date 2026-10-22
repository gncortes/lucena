import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/analytics/view_models/analytics_opt_in_cubit.dart';
import 'package:lucena/ui/analytics/view_models/team_mode_cubit.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';

void main() {
  late FakeAnalyticsRepository analytics;

  setUp(() => analytics = FakeAnalyticsRepository());

  group('AnalyticsOptInCubit', () {
    test('começa sem valor e lê a chave salva', () async {
      analytics.optIn = false;
      final cubit = AnalyticsOptInCubit(analytics);
      addTearDown(cubit.close);
      expect(cubit.state, isNull);

      await cubit.load();
      expect(cubit.state, isFalse);
    });

    test('desligar grava e conta uma vez', () async {
      final cubit = AnalyticsOptInCubit(analytics);
      addTearDown(cubit.close);
      await cubit.load();

      await cubit.setEnabled(false);
      await cubit.setEnabled(false);

      expect(cubit.state, isFalse);
      expect(analytics.optIn, isFalse);
      expect(analytics.eventsNamed('privacidade_analytics'), hasLength(1));
    });
  });

  group('TeamModeCubit', () {
    test('lê o Modo equipe salvo', () async {
      analytics.team = true;
      final cubit = TeamModeCubit(analytics);
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.team, isTrue);
    });

    test('o 7º toque abre, e a conta recomeça', () {
      final cubit = TeamModeCubit(analytics);
      addTearDown(cubit.close);
      final taps = [for (var i = 0; i < 14; i++) cubit.tapVersion()];
      expect(taps.where((open) => open), hasLength(2));
      expect(taps[6], isTrue);
      expect(taps[13], isTrue);
      expect(taps.take(6), everyElement(isFalse));
    });

    test('ligar e desligar vão para o repositório', () async {
      final cubit = TeamModeCubit(analytics);
      addTearDown(cubit.close);
      await cubit.setTeamMode(true);
      expect(cubit.state.team, isTrue);
      expect(analytics.team, isTrue);
      expect(analytics.resets, 1);

      await cubit.setTeamMode(false);
      expect(analytics.team, isFalse);
    });
  });
}
