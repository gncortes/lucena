import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/core/motion/anel_da_meta.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';
import 'package:lucena/ui/streak/widgets/streak_screen.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

/// Movimento da Sequência (H-ANI-07, 08 e 18): o esqueleto se dissolve, os
/// dias contam e Tentar novamente carrega no botão.
class _Atividade extends FakeActivityRepository {
  _Atividade({super.days});

  bool falha = false;
  Completer<void>? porta;

  @override
  Future<Set<DateTime>> days() async {
    if (falha) throw StateError('banco');
    await porta?.future;
    return super.days();
  }
}

void main() {
  final now = FakeNow(DateTime(2026, 10, 22, 9));
  final dias = {
    for (final d in [1, 2, 3, 4, 5, 20, 21, 22]) DateTime(2026, 10, d, 18),
  };

  Future<void> pump(WidgetTester tester, StreakCubit cubit) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const StreakScreen()),
      ),
    );
  }

  testWidgets('o esqueleto e o conteúdo coexistem e só o conteúdo fica', (
    tester,
  ) async {
    final repo = _Atividade(days: dias)..porta = Completer<void>();
    final cubit = StreakCubit(activity: repo, now: now);
    addTearDown(cubit.close);
    await pump(tester, cubit);
    unawaited(cubit.load());
    await tester.pump();
    expect(find.byKey(StreakKeys.loading), findsOneWidget);

    repo.porta!.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
    expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.byKey(StreakKeys.loading), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('os dias seguidos e o recorde contam até o valor', (
    tester,
  ) async {
    final cubit = StreakCubit(
      activity: _Atividade(days: dias),
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await pump(tester, cubit);
    await tester.pump(const Duration(milliseconds: 200));
    // No meio da contagem a sequência de 3 dias ainda não chegou.
    expect(find.text('3 dias'), findsNothing);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(StreakKeys.current),
        matching: find.text('3 dias'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Tentar novamente gira o círculo no botão até a resposta', (
    tester,
  ) async {
    final repo = _Atividade()..falha = true;
    final cubit = StreakCubit(activity: repo, now: now);
    addTearDown(cubit.close);
    await cubit.load();
    await pump(tester, cubit);
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.error), findsOneWidget);

    repo
      ..falha = false
      ..porta = Completer<void>();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
    repo.porta!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.error), findsNothing);
  });

  group('H-28: hoje cumprido na faixa da semana', () {
    // 22/10/2026 é quinta: a semana vai de 19 a 25; a sequência é 20, 21, 22
    // (índices 1, 2 e 3, hoje).
    final seguidos = {
      for (final d in [20, 21, 22]) DateTime(2026, 10, d, 18),
    };

    double tempoDoAnel(WidgetTester tester) =>
        (tester.widget<CustomPaint>(find.byKey(MotionKeys.anelDaMeta)).painter!
                as PintorDoAnel)
            .tempo;
    double check(WidgetTester tester, int i) => tester
        .widget<Transform>(find.byKey(MotionKeys.checkDaSemana(i)))
        .transform
        .storage[0];
    Finder contador(String texto) => find.descendant(
      of: find.byKey(StreakKeys.current),
      matching: find.text(texto),
    );

    Future<void> abrir(WidgetTester tester, Set<DateTime> dias) async {
      final cubit = StreakCubit(
        activity: _Atividade(days: dias),
        now: now,
      );
      addTearDown(cubit.close);
      await cubit.load();
      await pump(tester, cubit);
    }

    testWidgets('✓ anteriores em onda, o anel fecha, o ✓ de hoje salta e o '
        'contador sobe de 2 para 3', (tester) async {
      await abrir(tester, seguidos);
      await tester.pump();
      expect(tempoDoAnel(tester), lessThan(.2));
      await tester.pump(const Duration(milliseconds: 60));
      // O primeiro ✓ já saiu; o segundo espera o intervalo.
      expect(check(tester, 1), greaterThan(0));
      expect(check(tester, 2), 0);
      expect(contador('2 dias'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tempoDoAnel(tester), 1);
      expect(check(tester, 2), greaterThan(0));
      // O ✓ de hoje só salta depois que o anel fecha.
      expect(check(tester, 3), lessThan(.3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(check(tester, 3), greaterThan(.8));
      await tester.pumpAndSettle();
      expect(contador('3 dias'), findsOneWidget);
      for (final i in [1, 2, 3]) {
        expect(check(tester, i), 1);
      }
      expect(tempoDoAnel(tester), 1);
    });

    testWidgets('movimento reduzido: tudo no estado final no primeiro quadro', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await abrir(tester, seguidos);
      await tester.pump();
      expect(tempoDoAnel(tester), 1);
      for (final i in [1, 2, 3]) {
        expect(check(tester, i), 1);
      }
      expect(contador('3 dias'), findsOneWidget);
    });

    testWidgets('hoje sem atividade: o anel de hoje fica parado, sem festa', (
      tester,
    ) async {
      await abrir(tester, {
        for (final d in [20, 21]) DateTime(2026, 10, d, 18),
      });
      await tester.pump();
      expect(find.byKey(MotionKeys.anelDaMeta), findsNothing);
      expect(find.byKey(MotionKeys.checkDaSemana(1)), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });
}
