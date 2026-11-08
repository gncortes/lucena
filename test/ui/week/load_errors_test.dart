import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/week/view_models/week_cubit.dart';
import 'package:lucena/ui/week/widgets/week_screen.dart';
import 'package:lucena/ui/streak/view_models/streak_cubit.dart';
import 'package:lucena/ui/streak/widgets/streak_screen.dart';
import 'package:lucena/ui/home_layout/view_models/home_layout_cubit.dart';
import 'package:lucena/ui/home_layout/widgets/home_layout_screen.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/test_app.dart';

class _Week extends FakeWeekRepository {
  _Week()
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
  bool failing = true;
  @override
  Future<WeekSummary> summary() async {
    if (failing) throw StateError('database');
    return super.summary();
  }
}

class _Activity extends FakeActivityRepository {
  bool failing = true;
  @override
  Future<Set<DateTime>> days() async {
    if (failing) throw StateError('database');
    return super.days();
  }
}

class _Profile extends FakeProfileRepository {
  bool failing = true;
  @override
  Future<UserProfile> load() async {
    if (failing) throw StateError('database');
    return super.load();
  }
}

void main() {
  for (final area in ['week', 'streak', 'home_layout']) {
    testWidgets('$area failure replaces scaffold and retry recovers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final Widget provider;
      final Future<void> Function() load;
      final VoidCallback recover;
      switch (area) {
        case 'week':
          final repo = _Week();
          final cubit = WeekCubit(repo);
          addTearDown(cubit.close);
          load = cubit.load;
          recover = () => repo.failing = false;
          provider = BlocProvider.value(
            value: cubit,
            child: const WeekScreen(),
          );
        case 'streak':
          final repo = _Activity();
          final cubit = StreakCubit(
            activity: repo,
            now: FakeNow(DateTime(2026, 10, 22)),
          );
          addTearDown(cubit.close);
          load = cubit.load;
          recover = () => repo.failing = false;
          provider = BlocProvider.value(
            value: cubit,
            child: const StreakScreen(),
          );
        default:
          final repo = _Profile();
          final cubit = HomeLayoutCubit(
            layouts: FakeHomeLayoutRepository(),
            profile: repo,
          );
          addTearDown(cubit.close);
          load = cubit.load;
          recover = () => repo.failing = false;
          provider = BlocProvider.value(
            value: cubit,
            child: const HomeLayoutScreen(),
          );
      }
      await load();
      await tester.pumpWidget(
        TestApp(locale: const Locale('pt'), child: provider),
      );
      await tester.pump();
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        LoadErrorKind.generic,
      );
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsOneWidget);
      recover();
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
