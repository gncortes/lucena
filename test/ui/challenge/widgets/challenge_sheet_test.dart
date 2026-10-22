import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/challenge/widgets/challenge_sheet.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_share_repository.dart';
import '../../../../testing/test_app.dart';

final _link = ChallengeLink(
  fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
  userSide: Side.white,
  opponent: OpponentKind.maia,
  level: 1400,
  clock: TimeControl.tryParse('300+0'),
);

void main() {
  late FakeShareRepository share;
  late List<String> clipboard;

  setUp(() {
    share = FakeShareRepository();
    clipboard = [];
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> open(WidgetTester tester) async {
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
            body: TextButton(
              onPressed: () => showChallengeSheet(context, link: _link),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o resumo, a trava e o endereço curto', (tester) async {
    await open(tester);
    expect(find.text('Send as a challenge'), findsOne);
    expect(find.byKey(ChallengeKeys.summary), findsOne);
    expect(find.text('Maia 1400 · 5+0'), findsOne);
    expect(find.text('You play white · Normal'), findsOne);
    expect(find.text('${AppLinks.host}/p/${_link.code}'), findsOne);
  });

  testWidgets('Compartilhar manda o link do desafio', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(ChallengeKeys.share));
    await tester.pumpAndSettle();
    expect(share.texts.single, contains(_link.uri.toString()));
    expect(share.texts.single, isNot(contains('lock=1')));
  });

  testWidgets('travar a configuração muda o link', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(ChallengeKeys.lockSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ChallengeKeys.share));
    await tester.pumpAndSettle();
    expect(share.texts.single, contains('lock=1'));
    // O código acompanha a trava: é outro desafio.
    expect(share.texts.single, contains(_link.withLock(locked: true).code));
  });

  testWidgets('Copiar link guarda o endereço inteiro e avisa', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(ChallengeKeys.copy));
    await tester.pumpAndSettle();
    expect(clipboard.single, _link.uri.toString());
    expect(find.text('Link copied'), findsOne);
    // O aviso sai sozinho.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Link copied'), findsNothing);
  });
}
