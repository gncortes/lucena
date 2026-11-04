import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/character.dart';
import 'package:lucena/domain/models/featured.dart';
import 'package:lucena/domain/models/survey.dart';
import 'package:lucena/main.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/load_error_keys.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_featured_repositories.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_dependencies.dart';

class _Characters extends FakeCharacterRepository {
  bool fails = false;
  Completer<void>? pending;
  @override
  Future<List<Character>> characters() async {
    await pending?.future;
    if (fails) throw StateError('characters unavailable');
    return super.characters();
  }
}

class _Featured extends FakeFeaturedRepository {
  _Featured() : super(sampleFeaturedCatalog());
  bool fails = false;
  Completer<void>? pending;
  @override
  Future<FeaturedCatalog> catalog() async {
    await pending?.future;
    if (fails) throw StateError('catalog unavailable');
    return super.catalog();
  }
}

void main() {
  for (final route in [
    Routes.featuredEndgame('missing'),
    Routes.featuredTournament('missing'),
  ]) {
    testWidgets('$route inexistente mostra início sem retry', (tester) async {
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
            featuredRepository: _Featured(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.text('Conteúdo não encontrado'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsNothing);
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });
  }
  for (final route in [
    Routes.feedback,
    Routes.survey(SurveyKind.school),
    Routes.wouldPay,
    Routes.pilaresSale,
    D2Paths.pilaresForWhom,
    Routes.featured,
    Routes.featuredEndgame('a'),
    Routes.featuredTournament('live'),
  ]) {
    testWidgets('$route carga inicial usa shimmer', (tester) async {
      final characters = _Characters();
      final featured = _Featured();
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
            characterRepository: characters,
            featuredRepository: featured,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      final pending = Completer<void>();
      if (route.startsWith('/featured')) {
        featured.pending = pending;
      } else {
        characters.pending = pending;
      }
      router.go(route);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SkeletonBlock), findsWidgets);
      pending.complete();
      await tester.pumpAndSettle();
    });
    testWidgets('$route falha com saída e retry carrega', (tester) async {
      final characters = _Characters();
      final featured = _Featured();
      await tester.pumpWidget(
        LucenaApp(
          dependencies: testDependencies(
            settingsRepository: FakeSettingsRepository(
              const AppSettings(languageCode: 'pt'),
            ),
            characterRepository: characters,
            featuredRepository: featured,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final router = GoRouter.of(tester.element(find.byKey(HomeKeys.screen)));
      if (route.startsWith('/featured')) {
        featured.fails = true;
      } else {
        characters.fails = true;
      }
      router.go(route);
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsOneWidget);
      characters.fails = featured.fails = false;
      await tester.tap(find.byKey(LoadErrorKeys.action));
      await tester.pumpAndSettle();
      expect(find.byKey(LoadErrorKeys.screen), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
