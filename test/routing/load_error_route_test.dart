import 'package:flutter_test/flutter_test.dart';
import 'package:dartchess/dartchess.dart';
import 'package:lucena/domain/models/challenge_link.dart';
import 'package:lucena/domain/models/onboarding.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';
import 'package:lucena/routing/routes.dart';

import '../../testing/fakes/fake_settings_repository.dart';
import '../../testing/test_dependencies.dart';
import '../../testing/fakes/fake_onboarding_repository.dart';

class _Onboarding extends FakeOnboardingRepository {
  bool fails = false;
  @override
  Future<Onboarding> load() async {
    if (fails) throw StateError('redirect unavailable');
    return super.load();
  }
}

void main() {
  testWidgets(
    'falha no redirect de desafio informa erro e retry preserva link',
    (tester) async {
      final onboarding = _Onboarding();
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
            onboardingRepository: onboarding,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      const link = ChallengeLink(
        fen: '8/3k4/8/8/8/8/2K5/2Q5 w - - 0 1',
        userSide: Side.white,
        level: 1400,
      );
      onboarding.fails = true;
      router.go('${link.uri.path}?${link.uri.query}');
      await tester.pumpAndSettle();
      expect(find.text('Ocorreu um erro inesperado'), findsOneWidget);
      onboarding.fails = false;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, link.uri.path);
    },
  );
  for (final route in [
    Routes.conclusionNow,
    '/rota-inexistente',
    '/race/warm-up',
  ]) {
    testWidgets('$route mostra não encontrado sem retry nem voltar', (
      tester,
    ) async {
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      expect(find.text('Conteúdo não encontrado'), findsOneWidget);
      expect(find.text('Ir para o início'), findsOneWidget);
      expect(find.byKey(LoadErrorKeys.back), findsNothing);
      expect(find.text('Tentar novamente'), findsNothing);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });
  }
}
