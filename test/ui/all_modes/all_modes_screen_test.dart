import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/profile/view_models/profile_cubit.dart';
import 'package:lucena/ui/all_modes/widgets/all_modes_screen.dart';
import 'package:lucena/ui/core/keys/all_modes_keys.dart';

import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets('todos os modos num lugar só', (tester) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const TestApp(locale: Locale('pt'), child: AllModesScreen()),
    );
    await tester.pumpAndSettle();
    for (final mode in [
      'learn',
      'stars',
      'endgames',
      'journey',
      'train',
      'blind',
      'lichess',
      'speedrun',
      'freeBoard',
      'custom',
      'rating',
      'achievements',
    ]) {
      expect(find.byKey(AllModesKeys.item(mode)), findsOneWidget, reason: mode);
    }
    expect(find.text('Às cegas'), findsOneWidget);
  });

  testWidgets('quem já joga vê Jogar primeiro; o iniciante, Aprender', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 6000);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    Future<double> top(UserProfile profile, String mode) async {
      final cubit = ProfileCubit(FakeProfileRepository(profile));
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: const AllModesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getTopLeft(find.byKey(AllModesKeys.item(mode))).dy;
    }

    const master = UserProfile(rating: 2400);
    expect(await top(master, 'journey'), lessThan(await top(master, 'learn')));
    const beginner = UserProfile(rating: 800);
    expect(
      await top(beginner, 'learn'),
      lessThan(await top(beginner, 'journey')),
    );
  });
}
