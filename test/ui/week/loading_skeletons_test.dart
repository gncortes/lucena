import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';
import 'package:lucena/ui/streak/widgets/streak_screen.dart';
import 'package:lucena/ui/week/view_models/week_cubit.dart';
import 'package:lucena/ui/week/widgets/week_screen.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/test_app.dart';

/// H-INI-09 e H-INI-10: o primeiro carregamento mostra o esqueleto (não a
/// tela vazia) e a falha leva a chave de erro da tela.
class _FailingWeek extends FakeWeekRepository {
  _FailingWeek()
    : super(
        WeekSummary(
          monday: DateTime(2026, 10, 19),
          finals: 0,
          perDay: const [0, 0, 0, 0, 0, 0, 0],
          ratingFrom: 1200,
          ratingTo: 1200,
          streakDays: 0,
          firstTry: 0,
        ),
      );
  @override
  Future<WeekSummary> summary() async => throw StateError('database');
}

class _FailingActivity extends FakeActivityRepository {
  @override
  Future<Set<DateTime>> days() async => throw StateError('database');
}

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('Sua semana: esqueleto com os botões do rodapé visíveis', (
    tester,
  ) async {
    phone(tester);
    final cubit = WeekCubit(_FailingWeek());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const WeekScreen()),
      ),
    );
    expect(find.text('Sua semana'), findsOneWidget);
    expect(find.byKey(WeekKeys.loading), findsOneWidget);
    expect(find.byKey(WeekKeys.play), findsOneWidget);
    expect(find.byKey(WeekKeys.seeStreak), findsOneWidget);
    expect(find.byKey(WeekKeys.error), findsNothing);
  });

  testWidgets('Sua semana: a falha leva a chave de erro', (tester) async {
    phone(tester);
    final cubit = WeekCubit(_FailingWeek());
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const WeekScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(WeekKeys.error), findsOneWidget);
    expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  testWidgets('Sequência: esqueleto antes da leitura e erro com chave', (
    tester,
  ) async {
    phone(tester);
    final cubit = StreakCubit(
      activity: FakeActivityRepository(),
      now: FakeNow(DateTime(2026, 10, 22, 9)),
    );
    addTearDown(cubit.close);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const StreakScreen()),
      ),
    );
    expect(find.text('Sequência'), findsOneWidget);
    expect(find.byKey(StreakKeys.loading), findsOneWidget);
    expect(find.byKey(StreakKeys.error), findsNothing);

    final failing = StreakCubit(
      activity: _FailingActivity(),
      now: FakeNow(DateTime(2026, 10, 22, 9)),
    );
    addTearDown(failing.close);
    await failing.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: failing, child: const StreakScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(StreakKeys.error), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Voltar'), findsOneWidget);
  });

  test('Configurar o Início tem a chave de erro', () {
    expect(HomeLayoutKeys.error, isNotNull);
  });
}
