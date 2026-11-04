import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:lucena/ui/week/view_models/week_cubit.dart';
import 'package:lucena/ui/week/widgets/week_screen.dart';

import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/test_app.dart';

/// Movimento de Sua semana (H-ANI-07, 08 e 18): o esqueleto se dissolve, os
/// números contam e Tentar novamente carrega no botão.
class _Semana extends FakeWeekRepository {
  _Semana() : super(_resumo);

  bool falha = false;
  Completer<void>? porta;

  @override
  Future<WeekSummary> summary() async {
    if (falha) throw StateError('banco');
    await porta?.future;
    return week;
  }
}

final _resumo = WeekSummary(
  monday: DateTime(2026, 10, 12),
  finals: 12,
  perDay: const [2, 1, 3, 1, 2, 2, 1],
  ratingFrom: 1152,
  ratingTo: 1192,
  streakDays: 12,
  firstTry: 9,
);

void main() {
  Future<void> pump(WidgetTester tester, WeekCubit cubit) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const WeekScreen()),
      ),
    );
  }

  Finder numero(String code) => find.descendant(
    of: find.byKey(WeekKeys.stat(code)),
    matching: find.byType(Text),
  );

  testWidgets('o esqueleto e o conteúdo coexistem e só o conteúdo fica', (
    tester,
  ) async {
    final repo = _Semana()..porta = Completer<void>();
    final cubit = WeekCubit(repo);
    addTearDown(cubit.close);
    await pump(tester, cubit);
    unawaited(cubit.load());
    await tester.pump();
    expect(find.byKey(WeekKeys.loading), findsOneWidget);

    repo.porta!.complete();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
    expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    expect(find.byKey(WeekKeys.loading), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('os números contam de 0 até o valor da semana', (tester) async {
    final cubit = WeekCubit(_Semana());
    addTearDown(cubit.close);
    await cubit.load();
    await pump(tester, cubit);
    await tester.pump(const Duration(milliseconds: 100));
    // Meio da contagem: nem zero nem o fim.
    await tester.pump(const Duration(milliseconds: 300));
    final meio = tester
        .widgetList<Text>(numero('finals'))
        .map((t) => int.tryParse(t.data ?? ''))
        .whereType<int>()
        .single;
    expect(meio, inInclusiveRange(1, 11));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(WeekKeys.stat('finals')),
        matching: find.text('12'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(WeekKeys.stat('points')),
        matching: find.text('+40'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('as barras dos dias crescem de baixo até o valor (H-ANI-18)', (
    tester,
  ) async {
    final cubit = WeekCubit(_Semana());
    addTearDown(cubit.close);
    await cubit.load();
    await pump(tester, cubit);
    double altura(int i) => tester.getSize(find.byKey(WeekKeys.bar(i))).height;
    double base(int i) => tester.getRect(find.byKey(WeekKeys.bar(i))).bottom;
    await tester.pump(const Duration(milliseconds: 50));
    final inicio = altura(2);
    final chao = base(2);
    await tester.pump(const Duration(milliseconds: 250));
    final meio = altura(2);
    await tester.pumpAndSettle();
    // A quarta-feira (3 finais) é o dia mais cheio: 72 de altura no fim.
    expect(altura(2), 72);
    expect(meio, greaterThan(inicio));
    expect(meio, lessThan(72));
    // Cresce para cima: a base não sai do lugar.
    expect(base(2), chao);
    // O dia de 1 final fica num terço do mais cheio.
    expect(altura(1), 24);
  });

  testWidgets('Tentar novamente gira o círculo no botão até a resposta', (
    tester,
  ) async {
    final repo = _Semana()..falha = true;
    final cubit = WeekCubit(repo);
    addTearDown(cubit.close);
    await cubit.load();
    await pump(tester, cubit);
    await tester.pumpAndSettle();
    expect(find.byKey(WeekKeys.error), findsOneWidget);

    repo
      ..falha = false
      ..porta = Completer<void>();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
    repo.porta!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(WeekKeys.error), findsNothing);
  });
}
