import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/achievements/view_models/achievements_cubit.dart';
import 'package:lucena/ui/achievements/widgets/achievements_screen.dart';
import 'package:lucena/ui/core/keys/achievements_keys.dart';

import '../../../testing/fakes/fake_achievements_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('obtidas com data primeiro, bloqueadas com o que falta', (
    tester,
  ) async {
    final repository = FakeAchievementsRepository();
    await repository.unlock(['beat-2600'], DateTime.utc(2026, 10, 4, 12));
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider(
          create: (_) => AchievementsCubit(repository)..load(),
          child: const AchievementsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 2 unlocked'), findsOneWidget);
    expect(find.text('Beat Maia 2600'), findsOneWidget);
    expect(find.text('Unlocked on 10/4/2026'), findsOneWidget);
    expect(
      find.byKey(AchievementsKeys.locked('first-fulfilled')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(AchievementsKeys.item('beat-2600'))).dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(AchievementsKeys.item('first-fulfilled')))
            .dy,
      ),
    );
  });
}
