import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/domain/models/game_end.dart';
import 'package:lucena/domain/models/game_mode.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/domain/models/kpk_outcome.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/daily_keys.dart';
import 'package:lucena/ui/daily/view_models/daily_game_cubit.dart';
import 'package:lucena/ui/daily/widgets/daily_game_actions.dart';
import 'package:lucena/ui/free_board/view_models/free_board_state.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_daily_final_repository.dart';
import '../../../testing/fakes/fake_kpk_repository.dart';
import '../../../testing/fakes/fake_positions_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/fakes/fake_share_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  final rook = samplePositions.firstWhere((p) => p.id == 'basic.rook.0001');
  final start = GameRules.fromFen(rook.fen)!;
  const mode = GameMode(
    opponent: OpponentKind.maia,
    level: 1400,
    userSide: Side.white,
    goal: PositionGoal.win,
    dailyDate: '2026-10-22',
  );
  const won = GameEnd(GameEndReason.checkmate, winner: Side.white);
  const lost = GameEnd(GameEndReason.resign, winner: Side.black);
  const sharePt =
      'Final do dia do Lucena: brancas jogam e ganham. '
      'Você consegue? playlucena.com/dia';
  const winPt =
      'Ganhei o final do dia do Lucena (brancas jogam e ganham). '
      'Tente você também: playlucena.com/dia';

  FreeBoardState ended(GameEnd end) => FreeBoardState(
    start: start,
    position: start,
    ucis: const ['h1h2'],
    mode: mode,
    forcedEnd: end,
  );

  late DailyGameCubit cubit;
  late FakeShareRepository share;
  late GoRouter router;

  Future<void> pump(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);
    share = FakeShareRepository();
    cubit = DailyGameCubit(
      date: '2026-10-22',
      daily: FakeDailyFinalRepository(position: rook),
      activity: FakeActivityRepository(),
      kpk: FakeKpkRepository(FakeKpkOracle(fallback: KpkOutcome.outside)),
    );
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: Scaffold(
              appBar: AppBar(actions: const [DailyGameActions()]),
            ),
          ),
        ),
        GoRoute(
          path: Routes.home,
          builder: (context, state) => const Text('INICIO'),
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        shareRepository: share,
        router: router,
        child: const SizedBox.shrink(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settleShare(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('compartilhar na app bar: folha com a posição e o texto', (
    tester,
  ) async {
    await pump(tester);
    expect(find.byKey(DailyKeys.shareSheet), findsNothing);

    await tester.tap(find.byKey(DailyKeys.appBarShare));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.shareSheet), findsOneWidget);
    expect(find.text('Compartilhar final do dia'), findsOneWidget);
    expect(find.byKey(DailyKeys.shareImage), findsOneWidget);

    await tester.tap(find.byKey(DailyKeys.shareButton));
    await tester.pump();
    await settleShare(tester);

    final sent = share.shared.single;
    expect(sent.png.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
    expect(sent.text, sharePt);
    // Depois do menu do sistema, a folha fecha e a partida segue.
    expect(find.byKey(DailyKeys.shareSheet), findsNothing);
  });

  testWidgets('o X da folha volta à partida sem compartilhar', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(DailyKeys.appBarShare));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DailyKeys.shareSheetClose));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.shareSheet), findsNothing);
    expect(share.shared, isEmpty);
  });

  testWidgets('ganhou: "Parabéns!" e o convite com o texto de quem ganhou', (
    tester,
  ) async {
    await pump(tester);
    cubit.update(ended(won));
    await tester.runAsync(cubit.settle);
    await tester.pumpAndSettle();

    expect(find.byKey(DailyKeys.winSheet), findsOneWidget);
    expect(find.text('Parabéns!'), findsOneWidget);
    expect(find.text('Você ganhou o final do dia.'), findsOneWidget);
    expect(find.text('Agora não'), findsOneWidget);

    await tester.tap(find.byKey(DailyKeys.winShare));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.shareSheet), findsOneWidget);
    await tester.tap(find.byKey(DailyKeys.shareButton));
    await tester.pump();
    await settleShare(tester);
    expect(share.shared.single.text, winPt);
  });

  testWidgets('o X da folha depois de ganhar volta ao "Parabéns!"', (
    tester,
  ) async {
    await pump(tester);
    cubit.update(ended(won));
    await tester.runAsync(cubit.settle);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DailyKeys.winShare));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DailyKeys.shareSheetClose));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.shareSheet), findsNothing);
    expect(find.byKey(DailyKeys.winSheet), findsOneWidget);
  });

  testWidgets('"Agora não" leva ao Início', (tester) async {
    await pump(tester);
    cubit.update(ended(won));
    await tester.runAsync(cubit.settle);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(DailyKeys.winLater));
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.winSheet), findsNothing);
    expect(find.text('INICIO'), findsOneWidget);
  });

  testWidgets('perdeu: sem o modal de vitória', (tester) async {
    await pump(tester);
    cubit.update(ended(lost));
    await tester.runAsync(cubit.settle);
    await tester.pumpAndSettle();
    expect(find.byKey(DailyKeys.winSheet), findsNothing);
    expect(find.byKey(DailyKeys.appBarShare), findsOneWidget);
  });
}
