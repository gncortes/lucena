import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:lucena/ui/challenge/view_models/link_setup_cubit.dart';
import 'package:lucena/ui/challenge/widgets/link_setup_screen.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeOnboardingRepository onboarding;
  late FakeSettingsRepository settingsRepository;
  late SettingsCubit settings;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    onboarding = FakeOnboardingRepository(const Onboarding());
    settingsRepository = FakeSettingsRepository();
    settings = SettingsCubit(
      settingsRepository,
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider(
            create: (_) => LinkSetupCubit(onboarding),
            child: const LinkSetupScreen(
              next: '/desafio',
              fen: '8/8/8/8/8/8/4K3/4Q2k w - - 0 1',
            ),
          ),
        ),
        GoRoute(
          path: '/desafio',
          builder: (context, state) => const Scaffold(body: Text('desafio')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mostra a amostra, as cores, as peças e o som', (tester) async {
    await open(tester);
    expect(find.text('Before the challenge'), findsOneWidget);
    expect(find.byKey(ChallengeKeys.setupPreview), findsOneWidget);
    expect(
      find.byKey(ChallengeKeys.setupColors(BoardColors.values.first)),
      findsOneWidget,
    );
    expect(find.byKey(ChallengeKeys.setupSound), findsOneWidget);
  });

  testWidgets('a miniatura mostra a posição do desafio, sem último lance', (
    tester,
  ) async {
    await open(tester);
    final board = tester.widget<StaticChessboard>(
      find.byKey(ChallengeKeys.setupPreview),
    );
    expect(board.fen, '8/8/8/8/8/8/4K3/4Q2k w - - 0 1');
    expect(board.lastMove, isNull);
  });

  testWidgets('escolher outra cor muda o tabuleiro de verdade', (tester) async {
    await open(tester);
    final other = BoardColors.values.firstWhere(
      (colors) => colors != settings.state!.board.colors,
    );
    await tester.ensureVisible(find.byKey(ChallengeKeys.setupColors(other)));
    await tester.tap(find.byKey(ChallengeKeys.setupColors(other)));
    await tester.pumpAndSettle();
    expect(settings.state!.board.colors, other);
  });

  testWidgets('"Jogar o desafio" grava que passou e abre o desafio no lugar', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(ChallengeKeys.setupPlay));
    await tester.pumpAndSettle();

    expect(onboarding.saved.linkSetupDone, isTrue);
    // O tour continua pendente: só o desafio foi liberado.
    expect(onboarding.saved.done, isFalse);
    expect(find.text('desafio'), findsOneWidget);
    expect(find.byKey(ChallengeKeys.setupScreen), findsNothing);
  });
}
