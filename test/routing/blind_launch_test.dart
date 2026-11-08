import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';
import 'package:lucena/domain/models/blind_checkpoint.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/blind/view_models/blind_game_cubit.dart';
import 'package:lucena/ui/blind/widgets/blind_game_screen.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';

import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_dependencies.dart';

void main() {
  testWidgets('abrir o app retoma a partida às cegas salva no disco', (
    tester,
  ) async {
    final dependencies = testDependencies(
      settingsRepository: FakeSettingsRepository(
        const AppSettings(languageCode: 'pt', themeMode: AppThemeMode.light),
      ),
    );
    const checkpoint = BlindCheckpoint(
      setup: {
        'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
        'user': 'white',
        'kind': 'maia',
        'level': 1000,
        'goal': 'win',
      },
      moves: ['e2e4', 'e7e5'],
      state: {'phase': 'playerTurn', 'view': 'empty', 'drawDeclines': 0},
    );
    await dependencies.blindCheckpointRepository.save(checkpoint);

    await tester.pumpWidget(LucenaApp(dependencies: dependencies));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(BlindGameScreen), findsOneWidget);
    expect(find.byKey(HomeKeys.screen), findsNothing);
    final cubit = tester
        .element(find.byType(BlindGameScreen))
        .read<BlindGameCubit>();
    expect(cubit.state.sans, ['e4', 'e5']);
    expect(cubit.state.phase, BlindPhase.playerTurn);
    expect(cubit.state.view, BlindView.empty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
