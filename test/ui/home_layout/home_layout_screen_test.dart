import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/home_layout.dart';
import 'package:lucena/domain/models/rating_level.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/use_cases/home_suggestion.dart';
import 'package:lucena/ui/core/keys/home_layout_keys.dart';
import 'package:lucena/ui/home_layout/view_models/home_layout_cubit.dart';
import 'package:lucena/ui/home_layout/widgets/home_layout_screen.dart';

import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  late FakeHomeLayoutRepository layouts;
  late HomeLayoutCubit cubit;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    layouts = FakeHomeLayoutRepository();
    cubit = HomeLayoutCubit(
      layouts: layouts,
      profile: FakeProfileRepository(
        UserProfile(rating: RatingLevel.beginner.rating),
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: BlocProvider.value(
          value: cubit,
          child: const HomeLayoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool checked(WidgetTester tester, HomePath path) => tester
      .widget<CheckboxListTile>(find.byKey(HomeLayoutKeys.check(path)))
      .value!;

  testWidgets('marcar, reordenar e voltar à sugestão; tudo gravado', (
    tester,
  ) async {
    await pump(tester);
    // A sugestão do iniciante: já é ela, nada a restaurar.
    expect(checked(tester, HomePath.learn), isTrue);
    expect(checked(tester, HomePath.speedrun), isFalse);
    expect(
      tester.widget<OutlinedButton>(find.byKey(HomeLayoutKeys.restore)).enabled,
      isFalse,
    );

    await tester.tap(find.byKey(HomeLayoutKeys.check(HomePath.speedrun)));
    await tester.pumpAndSettle();
    expect(checked(tester, HomePath.speedrun), isTrue);
    expect(layouts.layout!.visible, contains(HomePath.speedrun));
    expect(layouts.layout!.custom, isTrue);

    // Arrastar o Speedrun (o último) para o topo.
    final handle = find.byKey(HomeLayoutKeys.handle(HomePath.speedrun));
    final first = tester.getCenter(
      find.byKey(HomeLayoutKeys.item(HomePath.learn)),
    );
    final start = tester.getCenter(handle);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 100));
    final target = Offset(start.dx, first.dy - 40);
    for (var i = 1; i <= 10; i++) {
      await gesture.moveTo(Offset.lerp(start, target, i / 10)!);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(layouts.layout!.order.first, HomePath.speedrun);

    await tester.tap(find.byKey(HomeLayoutKeys.restore));
    await tester.pumpAndSettle();
    expect(layouts.layout, HomeSuggestion.of(RatingLevel.beginner));
    expect(checked(tester, HomePath.speedrun), isFalse);
  });

  testWidgets('o último marcado não pode ser desmarcado', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(HomeLayoutKeys.check(HomePath.learn)));
    await tester.pumpAndSettle();
    final journey = tester.widget<CheckboxListTile>(
      find.byKey(HomeLayoutKeys.check(HomePath.journey)),
    );
    expect(journey.enabled, isFalse);
  });
}
