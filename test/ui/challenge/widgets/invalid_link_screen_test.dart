import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/challenge/widgets/invalid_link_screen.dart';
import 'package:lucena/ui/core/keys/challenge_keys.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';

void main() {
  testWidgets('erro permite voltar sem apagar a atividade anterior', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'atividade preservada');
    addTearDown(controller.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: TextField(controller: controller)),
        ),
        GoRoute(
          path: Routes.invalidLink,
          builder: (_, _) => const InvalidLinkScreen(),
        ),
        GoRoute(
          path: Routes.daily,
          builder: (_, _) => const Scaffold(body: Text('daily destination')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    router.push(Routes.invalidLink);
    await tester.pumpAndSettle();
    expect(find.byKey(ChallengeKeys.invalidMessage), findsOneWidget);
    await tester.tap(find.byKey(ChallengeKeys.invalidBack));
    await tester.pumpAndSettle();
    expect(find.text('atividade preservada'), findsOneWidget);

    router.push(Routes.invalidLink);
    await tester.pumpAndSettle();
    var clipboard = 'https://example.com/dia';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.getData') {
            return {'text': clipboard};
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byKey(ChallengeKeys.invalidPaste));
    await tester.pumpAndSettle();
    expect(find.byKey(ChallengeKeys.invalidScreen), findsOneWidget);
    expect(controller.text, 'atividade preservada');
    clipboard = 'https://playlucena.com/dia';
    await tester.tap(find.byKey(ChallengeKeys.invalidPaste));
    await tester.pumpAndSettle();
    expect(find.text('daily destination'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('atividade preservada'), findsOneWidget);
  });
}
