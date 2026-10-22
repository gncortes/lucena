import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/keys/week_keys.dart';
import 'package:lucena/ui/week/view_models/week_cubit.dart';
import 'package:lucena/ui/week/widgets/week_screen.dart';

import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  WeekSummary week({int from = 1152, int to = 1192, List<int>? perDay}) {
    final days = perDay ?? const [2, 1, 3, 1, 2, 2, 1];
    return WeekSummary(
      monday: DateTime(2026, 10, 12),
      finals: days.fold(0, (a, b) => a + b),
      perDay: days,
      ratingFrom: from,
      ratingTo: to,
      streakDays: 12,
      firstTry: 9,
    );
  }

  Future<void> pump(WidgetTester tester, WeekSummary summary) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    final cubit = WeekCubit(FakeWeekRepository(summary));
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(value: cubit, child: const WeekScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder statText(String code, String text) => find.descendant(
    of: find.byKey(WeekKeys.stat(code)),
    matching: find.text(text),
  );

  testWidgets('título, datas, números, barras e rating', (tester) async {
    await pump(tester, week());

    expect(find.text('Sua semana'), findsOneWidget);
    expect(
      find.text('Esta semana você jogou 12 finais e subiu 40 pontos'),
      findsOneWidget,
    );
    expect(
      find.text('De segunda, 12 de outubro, a domingo, 18.'),
      findsOneWidget,
    );
    expect(statText('finals', '12'), findsOneWidget);
    expect(statText('points', '+40'), findsOneWidget);
    expect(statText('days', '12'), findsOneWidget);
    expect(statText('firstTry', '9'), findsOneWidget);
    expect(find.text('Finais por dia'), findsOneWidget);
    expect(find.text('Rating: 1152 para 1192'), findsOneWidget);
    expect(find.text('Seu melhor dia foi a quarta-feira.'), findsOneWidget);
    expect(find.byKey(WeekKeys.play), findsOneWidget);
    expect(find.byKey(WeekKeys.seeStreak), findsOneWidget);
  });

  testWidgets('rating caiu e melhor dia no sábado', (tester) async {
    await pump(
      tester,
      week(from: 1200, to: 1188, perDay: const [0, 0, 0, 0, 0, 3, 1]),
    );

    expect(
      find.text('Esta semana você jogou 4 finais e caiu 12 pontos'),
      findsOneWidget,
    );
    expect(statText('points', '-12'), findsOneWidget);
    expect(find.text('Seu melhor dia foi o sábado.'), findsOneWidget);
  });

  testWidgets('semana sem finais', (tester) async {
    await pump(tester, week(to: 1152, perDay: const [0, 0, 0, 0, 0, 0, 0]));

    expect(find.text('Sua semana ainda não tem finais'), findsOneWidget);
    expect(find.textContaining('melhor dia'), findsNothing);
  });
}
