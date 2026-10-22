import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/attempt.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/challenge_result.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/challenge/widgets/challenge_result_card.dart';
import 'package:lucena/ui/challenge/widgets/challenge_result_share.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_share_repository.dart';
import '../../../../testing/test_app.dart';

ChallengeResult _result({
  AttemptOutcome outcome = AttemptOutcome.win,
  Role? piece = Role.queen,
  Duration? remaining = const Duration(seconds: 292),
}) => ChallengeResult(
  link: ChallengeLink(
    fen: '7k/8/6K1/8/8/8/8/5Q2 w - - 0 1',
    userSide: Side.white,
    opponent: OpponentKind.maia,
    level: 1400,
    clock: TimeControl.tryParse('300+0'),
  ),
  outcome: outcome,
  moves: 9,
  remaining: remaining,
  matingPiece: piece,
  finalFen: '7k/6Q1/6K1/8/8/8/8/8 b - - 0 1',
);

void main() {
  late FakeShareRepository share;

  setUp(() {
    share = FakeShareRepository();
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> open(WidgetTester tester, ChallengeResult result) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        shareRepository: share,
        child: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                ChallengeResultCard(
                  result: result,
                  opponent: 'Percival · 1400',
                ),
                TextButton(
                  onPressed: () => unawaited(
                    shareChallengeResult(
                      context,
                      result: result,
                      opponent: 'Percival · 1400',
                    ),
                  ),
                  child: const Text('compartilhar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('mostra a imagem e o texto do mate, com o relógio', (
    tester,
  ) async {
    await open(tester, _result());

    expect(find.byKey(ChallengeKeys.resultCard), findsOneWidget);
    expect(find.text('CHALLENGE COMPLETE'), findsOneWidget);
    expect(
      find.text(
        'I checkmated with the queen in 9 moves, with 4:52 on the clock',
      ),
      findsOneWidget,
    );
    expect(find.text('against Percival · 1400'), findsOneWidget);
  });

  testWidgets('vitória sem mate e sem relógio', (tester) async {
    await open(tester, _result(piece: null, remaining: null));
    expect(find.text('I won the challenge in 9 moves'), findsOneWidget);
  });

  testWidgets('empate', (tester) async {
    await open(tester, _result(outcome: AttemptOutcome.draw, piece: null));
    expect(find.text('CHALLENGE DRAWN'), findsOneWidget);
    expect(find.text('I drew the challenge'), findsOneWidget);
  });

  testWidgets('Compartilhar manda a imagem PNG junto com o link', (
    tester,
  ) async {
    await open(tester, _result());
    await tester.tap(find.text('compartilhar'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    final sent = share.shared.single;
    // Assinatura de PNG.
    expect(sent.png.sublist(0, 4), [0x89, 0x50, 0x4e, 0x47]);
    expect(sent.text, contains('Can you do it faster?'));
    expect(sent.text, contains('https://${AppLinks.host}/p/'));
    expect(share.texts, isEmpty);
  });
}
