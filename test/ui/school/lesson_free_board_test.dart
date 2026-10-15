import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/ui/core/keys/lesson_v2_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  testWidgets(
    'free board keeps exact position, student orientation and lesson on return',
    (tester) async {
      tester.view
        ..physicalSize = const Size(400, 1100)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = LessonCubit(
        source: EndgameLessonSource(
          FakeEndgameLessonRepository(),
          FakeEndgameProgressRepository(),
        ),
        characters: FakeCharacterRepository(),
        opponent: FakeOpponentRepository(),
        replyDelay: Duration.zero,
      );
      addTearDown(cubit.close);
      await cubit.load('rook.lucena', 'en');
      final original = cubit.state;
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      Uri? opened;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                BlocProvider.value(value: cubit, child: const LessonScreen()),
          ),
          GoRoute(
            path: '/setup',
            builder: (_, state) {
              opened = state.uri;
              return const Scaffold(body: Text('Free board destination'));
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          router: router,
          child: const SizedBox(),
        ),
      );
      await tester.pumpAndSettle();
      final button = find.byKey(LessonV2Keys.openFreeBoard);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(opened!.queryParameters['fen'], original.fen);
      expect(opened!.queryParameters['goal'], PositionGoal.win.code);
      expect(cubit.state.step, original.step);
      expect(cubit.state.reached, original.reached);
      router.pop();
      await tester.pumpAndSettle();
      expect(button, findsOneWidget);
      expect(cubit.state.fen, original.fen);
      expect(cubit.state.step, original.step);
      expect(tester.takeException(), isNull);
    },
  );
}
