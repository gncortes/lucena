import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/streak_keys.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';
import 'package:lucena/ui/streak/widgets/streak_screen.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

void main() {
  final now = FakeNow(DateTime(2026, 10, 22, 9));

  Future<StreakCubit> pump(WidgetTester tester, Set<int> octoberDays) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = StreakCubit(
      activity: FakeActivityRepository(
        days: {for (final d in octoberDays) DateTime(2026, 10, d, 18)},
      ),
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const StreakScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('dias seguidos, recorde, semana e o mês', (tester) async {
    await pump(tester, {1, 2, 3, 4, 5, 20, 21, 22});

    expect(
      find.descendant(
        of: find.byKey(StreakKeys.current),
        matching: find.text('3 dias'),
      ),
      findsOneWidget,
    );
    expect(find.text('seguidos'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(StreakKeys.record),
        matching: find.text('5'),
      ),
      findsOneWidget,
    );
    expect(find.text('Outubro de 2026'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(StreakKeys.weekStrip),
        matching: find.byIcon(Icons.check),
      ),
      findsNWidgets(3),
    );
    expect(find.byKey(StreakKeys.day(31)), findsOneWidget);
    expect(find.textContaining('o recorde fica'), findsOneWidget);
  });

  testWidgets('um dia só: singular', (tester) async {
    await pump(tester, {22});
    expect(find.text('1 dia'), findsOneWidget);
    expect(find.text('seguido'), findsOneWidget);
  });

  test('o cubit marca só a sequência atual', () async {
    final cubit = StreakCubit(
      activity: FakeActivityRepository(
        days: {DateTime(2026, 10, 10), DateTime(2026, 10, 21)},
      ),
      now: now,
    );
    addTearDown(cubit.close);
    await cubit.load();

    expect(cubit.state.run, {DateTime(2026, 10, 21)});
    expect(cubit.state.active, hasLength(2));
    expect(cubit.state.streak.current, 1);
  });
}
