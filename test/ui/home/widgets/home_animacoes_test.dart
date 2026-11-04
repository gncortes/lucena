import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/ui/core/keys/core_keys.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/motion/entradas_vistas.dart';
import 'package:lucena/ui/home/view_models/home_cubit.dart';
import 'package:lucena/ui/home/widgets/hero_card.dart';
import 'package:lucena/ui/home/widgets/home_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../../testing/fakes/fake_home_layout_repository.dart';
import '../../../../testing/fakes/fake_journey_repository.dart';
import '../../../../testing/fakes/fake_now.dart';
import '../../../../testing/fakes/fake_onboarding_repository.dart';
import '../../../../testing/fakes/fake_positions_repository.dart';
import '../../../../testing/fakes/fake_profile_repository.dart';
import '../../../../testing/fakes/fake_progress_repository.dart';
import '../../../../testing/fakes/fake_rating_repository.dart';
import '../../../../testing/fakes/fake_school_repositories.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';
import '../../core/motion/entrada_helpers.dart';

/// Movimento do Início (H-ANI-07, 13, 17 e 18): o esqueleto se dissolve no
/// conteúdo, as partes entram em ordem, a barra enche e o rating conta.
class _FailingProgress extends FakeProgressRepository {
  bool fails = true;
  Completer<void>? gate;

  @override
  Future<Set<String>> fulfilledChallenges() async {
    if (fails) throw StateError('banco indisponível');
    await gate?.future;
    return super.fulfilledChallenges();
  }
}

class _Home extends StatelessWidget {
  const _Home({
    this.profile = const UserProfile(),
    this.progress,
    this.vistas,
    this.reduzir = false,
  });

  final UserProfile profile;
  final FakeProgressRepository? progress;
  final EntradasVistas? vistas;
  final bool reduzir;

  @override
  Widget build(BuildContext context) {
    final home = MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            FakeSettingsRepository(const AppSettings()),
            languages: AppLanguage.selectable,
          )..load(),
        ),
        BlocProvider(
          create: (_) => HomeCubit(
            journey: FakeJourneyRepository(),
            progress: progress ?? FakeProgressRepository(),
            onboarding: FakeOnboardingRepository(),
            characters: FakeCharacterRepository(),
            rating: FakeRatingRepository(),
            lessons: FakeLessonRepository(),
            school: FakeSchoolProgressRepository(),
            profile: FakeProfileRepository(profile),
            endgameLessons: FakeEndgameLessonRepository(),
            endgameProgress: FakeEndgameProgressRepository(),
            homeLayout: FakeHomeLayoutRepository(),
            now: FakeNow(DateTime(2026, 1, 1, 12)),
            positions: FakePositionsRepository(),
          )..load(),
        ),
      ],
      child: const HomeScreen(),
    );
    final scoped = vistas == null
        ? home
        : EntradasVistasEscopo(vistas: vistas!, child: home);
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 1600),
        disableAnimations: reduzir,
      ),
      child: scoped,
    );
  }
}

void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    UserProfile profile = const UserProfile(),
    FakeProgressRepository? progress,
    EntradasVistas? vistas,
    bool reduzir = false,
  }) async {
    tester.view
      ..physicalSize = const Size(360, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: _Home(
          profile: profile,
          progress: progress,
          vistas: vistas,
          reduzir: reduzir,
        ),
      ),
    );
  }

  /// Passa quadros até o conteúdo aparecer (a carga termina nos microtasks).
  Future<void> ateOConteudo(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      if (find.byKey(MotionKeys.shimmerConteudo).evaluate().isNotEmpty) return;
      await tester.pump();
    }
  }

  group('H-ANI-07 · shimmer na primeira carga', () {
    testWidgets('o esqueleto e o conteúdo coexistem e só o conteúdo fica', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
      expect(find.byKey(HomeKeys.loading), findsOneWidget);

      await ateOConteudo(tester);
      await tester.pump(const Duration(milliseconds: 125));
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
      expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
      expect(find.byKey(HomeKeys.loading), findsNothing);
      expect(find.byKey(HomeKeys.shortcutsTitle), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('H-ANI-17 · partes em ordem', () {
    testWidgets('a lista entra de cima para baixo, um de cada vez', (
      tester,
    ) async {
      await pumpHome(tester);
      await ateOConteudo(tester);
      // O esqueleto sai em 300 ms; a lista começa junto com o conteúdo.
      await tester.pump(const Duration(milliseconds: 60));
      final primeiro = find.byKey(MotionKeys.itemDaLista(0));
      final ultimo = find.byKey(MotionKeys.itemDaLista(2));
      expect(primeiro, findsOneWidget);
      expect(ultimo, findsOneWidget);
      expect(
        opacidade(tester, primeiro),
        greaterThan(opacidade(tester, ultimo)),
      );
      await tester.pumpAndSettle();
      expect(opacidade(tester, ultimo), 1);
    });

    testWidgets('voltar ao Início na mesma sessão: tudo pronto', (
      tester,
    ) async {
      final vistas = EntradasVistas()..primeiraVez('PropV2Home');
      await pumpHome(tester, vistas: vistas);
      await ateOConteudo(tester);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaLista(0))), 1);
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaLista(2))), 1);
      await tester.pumpAndSettle();
    });

    testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
      tester,
    ) async {
      await pumpHome(tester, reduzir: true);
      await ateOConteudo(tester);
      await tester.pump();
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaLista(2))), 1);
      await tester.pumpAndSettle();
    });
  });

  group('H-ANI-18 · o rating conta', () {
    testWidgets('sobe de 0 até o valor e termina em 1150', (tester) async {
      await pumpHome(
        tester,
        profile: const UserProfile(nickname: 'Ana', rating: 1450),
      );
      await ateOConteudo(tester);
      Finder valor() => find.byKey(HomeKeys.ratingValue);
      await tester.pump(const Duration(milliseconds: 200));
      final meio = int.parse(tester.widget<Text>(valor()).data!);
      expect(meio, inInclusiveRange(1, 1149));
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.widget<Text>(valor()).data, '1150');
      await tester.pumpAndSettle();
    });
  });

  group('H-ANI-08 · Tentar novamente carrega no botão', () {
    testWidgets('o círculo gira no botão até a resposta', (tester) async {
      final progress = _FailingProgress();
      await pumpHome(tester, progress: progress);
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.error), findsOneWidget);
      progress.fails = false;
      progress.gate = Completer<void>();
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(CoreKeys.busySpinner), findsOneWidget);
      progress.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(HomeKeys.screen), findsOneWidget);
    });
  });

  group('H-ANI-13 · a barra do cartão enche', () {
    testWidgets('de 0 até o ponto da escola (2 de 6)', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final settings = SettingsCubit(
        FakeSettingsRepository(const AppSettings()),
        languages: AppLanguage.selectable,
      );
      addTearDown(settings.close);
      await settings.load();
      await tester.pumpWidget(
        TestApp(
          settingsCubit: settings,
          locale: const Locale('pt'),
          child: const Scaffold(
            body: EntradaDaTela(
              id: 'PropV2UxHomeTreino',
              child: HeroCard(
                state: HomeState(
                  ready: true,
                  school: SchoolSummary(done: 2, total: 6, teacher: null),
                ),
              ),
            ),
          ),
        ),
      );
      double lido() => tester
          .widget<LinearProgressIndicator>(
            find.descendant(
              of: find.byKey(HomeKeys.heroProgress),
              matching: find.byType(LinearProgressIndicator),
            ),
          )
          .value!;
      expect(lido(), 0);
      await tester.pump(const Duration(milliseconds: 350));
      expect(lido(), allOf(greaterThan(0), lessThan(2 / 6)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(lido(), closeTo(2 / 6, 1e-9));
    });
  });
}
