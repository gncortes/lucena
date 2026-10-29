import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/ui/board_controls/view_models/board_controls_cubit.dart';
import 'package:lucena/ui/board_controls/widgets/board_controls_screen.dart';
import 'package:lucena/ui/core/keys/board_controls_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  test(
    'posição e abertura da familiarização sobrevivem ao fechamento',
    () async {
      final saved = FakeOnboardingRepository();
      final first = BoardControlsCubit(saved);
      await first.load();
      first.play(Move.parse('e2e4')!);
      await Future<void>.delayed(Duration.zero);
      await first.close();
      expect((await saved.load()).boardControlsOpen, isTrue);
      final reopened = BoardControlsCubit(saved);
      await reopened.load();
      expect(reopened.state.position.board.pieceAt(Square.e4), isNotNull);
      expect(reopened.state.moved, isTrue);
      await reopened.finish(completed: false);
      expect((await saved.load()).boardControlsOpen, isFalse);
      expect((await saved.load()).boardControlsDone, isFalse);
      await reopened.close();
    },
  );
  test(
    'um lance ilegal não conclui; continuar salva a familiarização',
    () async {
      final saved = FakeOnboardingRepository();
      final cubit = BoardControlsCubit(saved);
      addTearDown(cubit.close);
      cubit.play(Move.parse('e2e5')!);
      expect(cubit.state.moved, isFalse);
      cubit.play(Move.parse('e2e4')!);
      expect(cubit.state.moved, isTrue);
      expect(cubit.state.position.board.pieceAt(Square.e4), isNotNull);
      await cubit.finish();
      expect((await saved.load()).boardControlsDone, isTrue);
      expect(cubit.state.leaving, isTrue);
    },
  );

  test('pular também preserva a decisão ao reabrir', () async {
    final saved = FakeOnboardingRepository();
    final cubit = BoardControlsCubit(saved);
    await cubit.finish();
    await cubit.close();
    expect((await saved.load()).boardControlsDone, isTrue);
  });

  for (final size in const [
    Size(360, 740),
    Size(360, 800),
    Size(384, 832),
    Size(393, 873),
    Size(412, 915),
    Size(414, 896),
  ]) {
    testWidgets('controles sem overflow e centro útil em $size', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 52, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 52, bottom: 24);
      addTearDown(tester.view.reset);
      final settings = SettingsCubit(
        FakeSettingsRepository(),
        languages: AppLanguage.selectable,
      );
      final cubit = BoardControlsCubit(FakeOnboardingRepository());
      addTearDown(settings.close);
      addTearDown(cubit.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: const BoardControlsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final board = tester.getRect(find.byKey(BoardControlsKeys.board));
      expect(
        (board.center.dy - (size.height + 52 - 24) / 2).abs(),
        lessThanOrEqualTo(.5),
      );
      expect(
        tester.getSize(find.byKey(BoardControlsKeys.continueButton)).height,
        greaterThanOrEqualTo(48),
      );
      expect(find.byKey(BoardControlsKeys.instruction), findsOneWidget);
      cubit.play(Move.parse('e2e4')!);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
