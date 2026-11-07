import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/lesson_content.dart';
import 'package:lucena/domain/models/placement.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/ui/core/widgets/load_error.dart';
import 'package:lucena/ui/placement/view_models/placement_cubit.dart';
import 'package:lucena/ui/placement/widgets/placement_screen.dart';

import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_placement_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

class _Placement extends FakePlacementRepository {
  Object? failure;
  @override
  Future<SkillMap> skills() async {
    final error = failure;
    if (error != null) throw error;
    return super.skills();
  }
}

void main() {
  for (final (error, kind) in <(Object, LoadErrorKind)>[
    (StateError('database'), LoadErrorKind.generic),
    (const LessonContentUnavailable(), LoadErrorKind.unavailable),
    (const LessonContentNotFound(), LoadErrorKind.unavailable),
    (const LessonContentNetworkUnavailable(), LoadErrorKind.offline),
    (const LessonContentStorageUnavailable(1), LoadErrorKind.noSpace),
  ]) {
    testWidgets('placement $kind recovers', (tester) async {
      final repo = _Placement()..failure = error;
      final cubit = PlacementCubit(
        placement: repo,
        profile: FakeProfileRepository(),
        now: FakeNow(DateTime(2026, 10, 22)),
      );
      addTearDown(cubit.close);
      await cubit.load();
      await tester.pumpWidget(
        TestApp(
          locale: const Locale('pt'),
          child: BlocProvider.value(
            value: cubit,
            child: const PlacementScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.widget<LoadErrorScreen>(find.byType(LoadErrorScreen)).kind,
        kind,
      );
      expect(find.byKey(LoadErrorKeys.back), findsOneWidget);
      expect(
        find.byKey(LoadErrorKeys.freeSpace),
        kind == LoadErrorKind.noSpace ? findsOneWidget : findsNothing,
      );
      repo.failure = null;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pump();
      expect(find.byType(LoadErrorScreen), findsNothing);
      expect(cubit.state.view, PlacementView.intro);
    });
  }
}
