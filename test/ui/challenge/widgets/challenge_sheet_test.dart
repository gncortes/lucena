import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/analytics/analytics_repository.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_links.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/clock.dart';
import 'package:lucena/domain/models/game_setup.dart';
import 'package:lucena/ui/challenge/widgets/challenge_sheet.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_analytics_repository.dart';
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

// O link que sai da folha: marcado como criado no app, 1ª geração.
final _sent = _link.sharedFrom('criar_desafio', generation: 1);

void main() {
  late FakeShareRepository share;
  late List<String> clipboard;
  late FakeAnalyticsRepository analytics;

  setUp(() {
    share = FakeShareRepository();
    clipboard = [];
    analytics = FakeAnalyticsRepository();
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
        analytics: analytics,
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
    expect(share.texts.single, contains(_sent.uri.toString()));
    expect(share.texts.single, contains('utm_source=app'));
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
    expect(clipboard.single, _sent.uri.toString());
    expect(find.text('Link copied'), findsOne);
    // O aviso sai sozinho.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.text('Link copied'), findsNothing);
  });

  group('estatísticas', () {
    testWidgets('Compartilhar conta link_criado e share uma vez', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.byKey(ChallengeKeys.share));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ChallengeKeys.share));
      await tester.pumpAndSettle();
      final created = analytics.eventsNamed('link_criado');
      expect(created, hasLength(1));
      expect(created.single.params['codigo'], _link.code);
      expect(created.single.params['tela'], 'criar_desafio');
      expect(created.single.params['geracao'], 1);
      expect(created.single.params['codigo_pai'], 'nenhum');
      final shares = analytics.eventsNamed('share');
      expect(shares, hasLength(2));
      expect(shares.first.params['content_type'], 'desafio');
      expect(shares.first.params['resultado'], 'concluido');
    });

    testWidgets('quem chegou por link manda a geração seguinte', (
      tester,
    ) async {
      analytics.trail = const LinkTrail(code: 'abcde', generation: 2);
      await open(tester);
      await tester.tap(find.byKey(ChallengeKeys.copy));
      await tester.pumpAndSettle();
      expect(clipboard.single, contains('g=3'));
      final created = analytics.eventsNamed('link_criado').single;
      expect(created.params['geracao'], 3);
      expect(created.params['codigo_pai'], 'abcde');
      final copied = analytics.eventsNamed('link_copiado').single;
      expect(copied.params['geracao'], 3);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    });

    testWidgets('a trava é outro código: outro link_criado', (tester) async {
      await open(tester);
      await tester.tap(find.byKey(ChallengeKeys.copy));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ChallengeKeys.lockSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ChallengeKeys.copy));
      await tester.pumpAndSettle();
      expect(analytics.eventsNamed('link_criado'), hasLength(2));
      expect(analytics.eventsNamed('link_copiado'), hasLength(2));
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
    });
  });
}
