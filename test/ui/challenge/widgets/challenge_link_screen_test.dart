import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/challenge/view_models/challenge_link_cubit.dart';
import 'package:lucena/ui/challenge/widgets/challenge_link_screen.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  testWidgets('em 412 x 917 o Modo e a nota da trava cabem sem rolar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 917);
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final cubit = ChallengeLinkCubit(
      FakeCharacterRepository(),
      FakeProfileRepository(),
      FakeRatingRepository(),
      link: ChallengeLink(
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        userSide: Side.white,
        opponent: OpponentKind.maia,
        level: 1400,
        locked: true,
      ),
    );
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const ChallengeLinkScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final key in [
      ChallengeKeys.modeRow,
      ChallengeKeys.lockedNote,
      ChallengeKeys.play,
    ]) {
      final box = tester.getRect(find.byKey(key));
      expect(box.bottom, lessThanOrEqualTo(917), reason: '$key');
    }
    expect(
      tester.getRect(find.byKey(ChallengeKeys.lockedNote)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byKey(ChallengeKeys.play)).top),
    );
  });
}
