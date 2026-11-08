import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/school_training_resources.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/routing/routes.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/core/motion/celebracao.dart';
import 'package:lucena/ui/school_graduation/view_models/school_graduation_cubit.dart';
import 'package:lucena/ui/school_graduation/widgets/school_graduation_screen.dart';

import '../../../testing/fakes/fake_opening_offer_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// T85-D3 H-ESC-22: o diploma da Escola, o resumo por módulo e os destinos.
void main() {
  if (!(File('assets/lessons/course.json').existsSync() &&
      File('assets/lessons/pt/lessons.json').existsSync())) {
    test(
      'private content required for full Escola scenarios',
      () {},
      skip: true,
    );
    return;
  }
  late List<String> visited;
  late FakeOpeningOfferRepository offer;

  Future<void> mount(WidgetTester tester) async {
    setPhoneSize(tester, const Size(412, 917));
    final course = AssetLessonRepository.parseCourse(
      jsonDecode(File('assets/lessons/course.json').readAsStringSync()),
    );
    final texts = LessonTexts.fromJson(
      jsonDecode(File('assets/lessons/pt/lessons.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    final scenario = TrainingScenarioBuilder(
      TrainingCourse.escola,
      date: DateTime(2026, 11, 3, 12),
      resources: schoolTrainingResources(course, texts),
    );
    final repository = scenario.repository(
      scenario.schoolAllDone().copyWith(lastLessonDate: '2026-11-03'),
    );
    addTearDown(repository.dispose);
    visited = [];
    offer = FakeOpeningOfferRepository(now: scenario.now);
    final router = GoRouter(
      initialLocation: '/graduation',
      routes: [
        GoRoute(
          path: '/graduation',
          builder: (context, state) => BlocProvider(
            create: (_) => SchoolGraduationCubit(
              repository: repository,
              now: scenario.now,
              openingOffer: offer,
            )..load(),
            child: const SchoolGraduationScreen(),
          ),
        ),
        GoRoute(
          path: '/:any(.*)',
          builder: (context, state) {
            visited.add(state.uri.toString());
            return const Scaffold(body: SizedBox());
          },
        ),
      ],
    );
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        router: router,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('diploma, resumo por módulo e cartão de opinião', (tester) async {
    await mount(tester);
    expect(find.byKey(TrainingKeys.diploma), findsOneWidget);
    expect(find.text('Diploma'), findsOneWidget);
    expect(find.text('Jogador'), findsOneWidget);
    expect(
      find.text('por concluir as 37 lições da Escola do Viktor'),
      findsOneWidget,
    );
    expect(find.text('3 de novembro de 2026'), findsOneWidget);
    expect(find.text('Professor'), findsOneWidget);
    expect(find.text('Viktor'), findsOneWidget);
    // H-15: Celebração grande; o diploma escala no lugar.
    final festa = tester.widget<Celebracao>(find.byType(Celebracao));
    expect(festa.tamanho, TamanhoDaCelebracao.grande);
    expect(festa.escalar, isFalse);
    expect(
      find.descendant(
        of: find.byKey(MotionKeys.diplomaDaCelebracao),
        matching: find.byKey(TrainingKeys.diploma),
      ),
      findsOneWidget,
    );
    expect(find.byKey(TrainingKeys.diplomaShare), findsOneWidget);
    expect(find.byKey(TrainingKeys.diplomaSummary), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(TrainingKeys.surveyCard), 200);
    expect(find.text('O que você achou da Escola?'), findsOneWidget);
    expect(
      find.text('Leva 1 minuto e ajuda a melhorar as lições.'),
      findsOneWidget,
    );
    expect(find.text('1 lição'), findsWidgets);
    expect(find.text('12 lições'), findsOneWidget);
    expect(find.text('Conhecer o Pilares'), findsOneWidget);
    expect(find.text('Ver o catálogo'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Conhecer o Pilares abre a venda do Pilares', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(TrainingKeys.diplomaPilares));
    await tester.pumpAndSettle();
    expect(visited.last, Routes.pilaresSale);
  });

  testWidgets('H-VEN-15: Conhecer o Pilares conta como a 1ª vez da oferta '
      'ao abrir o app', (tester) async {
    await mount(tester);
    expect(offer.state.count, 0);
    await tester.tap(find.byKey(TrainingKeys.diplomaPilares));
    await tester.pumpAndSettle();
    expect(offer.state.count, 1);
  });

  testWidgets('Ver o catálogo abre o catálogo da Escola', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(TrainingKeys.diplomaCatalog));
    await tester.pumpAndSettle();
    expect(visited.last, Routes.trainingCatalog('escola'));
  });

  testWidgets('cartão de opinião abre a pesquisa da Escola', (tester) async {
    await mount(tester);
    await tester.scrollUntilVisible(find.byKey(TrainingKeys.surveyCard), 200);
    await tester.ensureVisible(find.byKey(TrainingKeys.surveyCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(TrainingKeys.surveyCard));
    await tester.pumpAndSettle();
    expect(visited.last, '/survey/school');
  });

  testWidgets('o X fecha para o Início', (tester) async {
    await mount(tester);
    await tester.tap(find.byKey(TrainingKeys.diplomaClose));
    await tester.pumpAndSettle();
    expect(visited.last, Routes.home);
  });
}
