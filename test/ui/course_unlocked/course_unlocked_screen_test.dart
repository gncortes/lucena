import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/characters/character_repository.dart';
import 'package:lucena/data/repositories/profile/profile_repository.dart';
import 'package:lucena/data/repositories/training/course_training_repository.dart';
import 'package:lucena/domain/models/training/goal/study_plan.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/user_profile.dart';
import 'package:lucena/routing/frentes/d2_routes.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/course_unlocked_keys.dart';
import 'package:lucena/ui/core/theme/app_colors.dart';
import 'package:lucena/ui/core/theme/canvas_symbols.dart';
import 'package:lucena/ui/course_unlocked/view_models/course_unlocked_cubit.dart';
import 'package:lucena/ui/course_unlocked/widgets/course_unlocked_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_course_training_repository.dart';
import '../../../testing/fakes/fake_profile_repository.dart';
import '../../../testing/test_app.dart';

import '../../../testing/goldens/golden_harness.dart';

/// Curso liberado (H-R5-62): presente e compra, com e sem nome, com e sem
/// plano; o X volta para onde estava.
void main() {
  // Fonte real (Roboto): o "cabe em" mede como no aparelho.
  setUpAll(Goldens.loadFonts);

  Future<GoRouter> pump(
    WidgetTester tester, {
    required CourseUnlockedOrigin origin,
    String nickname = 'Ana',
    bool hasPlan = false,
    Size size = const Size(412, 917),
    bool fromHome = true,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    const path = '/unlocked';
    final training = FakeTrainingRepository(
      states: {
        if (hasPlan)
          TrainingCourse.pilares: TrainingState(
            course: TrainingCourse.pilares,
            installSeed: 'fake-installation',
            studyPlan: StudyPlan(createdOn: '2026-11-01'),
          ),
      },
    );
    final router = GoRouter(
      initialLocation: fromHome ? Routes.home : path,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('inicio')),
        ),
        GoRoute(
          path: D2Paths.pilaresGoal,
          builder: (_, _) => const Scaffold(body: Text('objetivo')),
        ),
        GoRoute(
          path: Routes.training(TrainingCourse.pilares.name),
          builder: (_, _) => const Scaffold(body: Text('curso')),
        ),
        GoRoute(
          path: path,
          builder: (context, _) => BlocProvider(
            create: (context) => CourseUnlockedCubit(
              characters: context.read<CharacterRepository>(),
              profile: context.read<ProfileRepository>(),
              training: context.read<TrainingRepository>(),
            )..load(),
            child: CourseUnlockedScreen(origin: origin),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CharacterRepository>.value(
            value: FakeCharacterRepository(),
          ),
          RepositoryProvider<ProfileRepository>.value(
            value: FakeProfileRepository(UserProfile(nickname: nickname)),
          ),
          RepositoryProvider<TrainingRepository>.value(value: training),
        ],
        child: TestApp(
          locale: const Locale('pt'),
          router: router,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (fromHome) {
      unawaited(router.push(path));
      await tester.pumpAndSettle();
    }
    return router;
  }

  String speech(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(CourseUnlockedKeys.speech),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .join(' ');

  testWidgets('presente: título, fala com o nome e "Montar o meu plano"', (
    tester,
  ) async {
    await pump(tester, origin: CourseUnlockedOrigin.gift);
    expect(find.text('Você ganhou o Pilares do Xadrez'), findsOneWidget);
    final fala = speech(tester);
    expect(fala, contains('Parabéns pelo presente, Ana!'));
    expect(fala, contains('Agora treinamos juntos o que decide partidas'));
    expect(fala, contains('Vamos começar pelo seu plano.'));
    expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
    expect(find.text('Montar o meu plano'), findsOneWidget);
  });

  testWidgets('lista o que o curso traz, abaixo da fala', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.purchase);
    for (final linha in const [
      'Tática e cálculo, do primeiro golpe às combinações',
      'Planos no meio-jogo e técnica nos finais',
      'As aberturas mais jogadas no seu nível',
      'Cada lance das lições explicado pelo Viktor',
    ]) {
      expect(find.text(linha), findsOneWidget);
    }
    final fala = tester.getRect(find.byKey(CourseUnlockedKeys.speech));
    expect(
      tester.getRect(find.byKey(CourseUnlockedKeys.include(0))).top,
      greaterThan(fala.bottom),
    );
  });

  testWidgets('compra sem nome: fala sem nome e ✓ verde', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.purchase, nickname: '  ');
    expect(find.text('O curso completo é seu'), findsOneWidget);
    final fala = speech(tester);
    expect(fala, contains('Boas-vindas ao Pilares do Xadrez.'));
    expect(fala, isNot(contains(',  ')));
    expect(find.byIcon(CanvasSymbols.check), findsOneWidget);
    final icone = tester.widget<Icon>(find.byIcon(CanvasSymbols.check));
    expect(icone.color, AppColors.successOnSurface);
  });

  testWidgets('presente sem nome', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.gift, nickname: '');
    expect(speech(tester), contains('Mestre Viktor Parabéns pelo presente!'));
  });

  testWidgets('com plano: "Ir para o curso" abre o curso', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.purchase, hasPlan: true);
    expect(speech(tester), isNot(contains('Vamos começar pelo seu plano.')));
    expect(find.text('Ir para o curso'), findsOneWidget);
    await tester.tap(find.byKey(CourseUnlockedKeys.action));
    await tester.pumpAndSettle();
    expect(find.text('curso'), findsOneWidget);
  });

  testWidgets('sem plano: "Montar o meu plano" abre o objetivo', (
    tester,
  ) async {
    await pump(tester, origin: CourseUnlockedOrigin.gift);
    await tester.tap(find.byKey(CourseUnlockedKeys.action));
    await tester.pumpAndSettle();
    expect(find.text('objetivo'), findsOneWidget);
  });

  testWidgets('o X volta para onde estava', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.gift);
    await tester.tap(find.byKey(CourseUnlockedKeys.close));
    await tester.pumpAndSettle();
    expect(find.byKey(CourseUnlockedKeys.screen), findsNothing);
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('sem para onde voltar, o X vai ao Início', (tester) async {
    await pump(tester, origin: CourseUnlockedOrigin.gift, fromHome: false);
    await tester.tap(find.byKey(CourseUnlockedKeys.close));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });

  for (final size in const [Size(360, 740), Size(412, 917)]) {
    testWidgets('cabe em ${size.width.toInt()}×${size.height.toInt()}', (
      tester,
    ) async {
      await pump(tester, origin: CourseUnlockedOrigin.gift, size: size);
      expect(tester.takeException(), isNull);
      final botao = tester.getRect(find.byKey(CourseUnlockedKeys.action));
      final lista = tester.getRect(find.byKey(CourseUnlockedKeys.include(3)));
      expect(botao.bottom, lessThanOrEqualTo(size.height));
      expect(botao.top, greaterThan(lista.bottom));
    });
  }
}
