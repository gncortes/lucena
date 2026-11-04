import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/school_training_resources.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_goals_tab.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';
import '../core/motion/entrada_helpers.dart';

/// T85-D6 L3 (Escola, área Iniciante): H-ANI-07, 16, 17 e 25 nas abas do
/// guia do curso da Escola.
void main() {
  late TrainingResources escola;
  setUpAll(() {
    final course = AssetLessonRepository.parseCourse(
      jsonDecode(File('assets/lessons/course.json').readAsStringSync()),
    );
    final texts = LessonTexts.fromJson(
      jsonDecode(File('assets/lessons/pt/lessons.json').readAsStringSync())
          as Map<String, dynamic>,
    );
    escola = schoolTrainingResources(course, texts);
  });

  Future<CourseGuideCubit> mount(
    WidgetTester tester,
    TrainingState Function(TrainingScenarioBuilder) build, {
    CourseGuideTab tab = CourseGuideTab.lesson,
    bool load = true,
    bool reduzir = false,
    VoidCallback? onDiploma,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final scenario = TrainingScenarioBuilder(
      TrainingCourseConfig.escola.course,
      date: DateTime(2026, 10, 26, 12),
      resources: escola,
    );
    final repository = scenario.repository(build(scenario).copyWith(tab: tab));
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.escola,
      now: scenario.now,
    );
    addTearDown(repository.dispose);
    addTearDown(cubit.close);
    if (load) await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: const [],
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 917),
          disableAnimations: reduzir,
        ),
        child: TestApp(
          locale: const Locale('pt'),
          settingsCubit: settings,
          child: BlocProvider.value(
            value: cubit,
            child: CourseGuideScreen(
              onBack: () {},
              onPlan: () {},
              onHelp: () {},
              onWelcomeContinue: () {},
              onLesson: (_) {},
              onDiploma: onDiploma,
              onChapter: (_) {},
              goalsBuilder: (_) =>
                  TrainingGoalsTab(onGoal: (_) {}, onPlan: () {}),
              progressBuilder: (_) => TrainingProgressTab(
                onTheme: (_) {},
                onOpenings: () {},
                onTest: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  group('boas-vindas (H-ANI-16)', () {
    testWidgets('entram em cascata e o botão é o último', (tester) async {
      await mount(
        tester,
        (s) => s.schoolDayOne().copyWith(onboardingDone: false),
      );
      await tester.pump();
      final titulo = find.byKey(MotionKeys.itemDaCascata(0));
      final botao = find.byKey(MotionKeys.itemDaCascata(2));
      expect(titulo, findsOneWidget);
      expect(botao, findsOneWidget);
      expect(opacidade(tester, botao), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacidade(tester, titulo), greaterThan(0));
      expect(opacidade(tester, botao), lessThan(opacidade(tester, titulo)));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(opacidade(tester, botao), 1);
      expect(find.byKey(CourseGuideKeys.continueButton), findsOneWidget);
    });

    testWidgets('movimento reduzido: tudo pronto no primeiro quadro', (
      tester,
    ) async {
      await mount(
        tester,
        (s) => s.schoolDayOne().copyWith(onboardingDone: false),
        reduzir: true,
      );
      await tester.pump();
      expect(opacidade(tester, find.byKey(MotionKeys.itemDaCascata(2))), 1);
    });
  });

  group('catálogo (H-ANI-17)', () {
    testWidgets('as linhas entram em ordem, uma de cada vez', (tester) async {
      await mount(tester, (s) => s.schoolDayOne(), tab: CourseGuideTab.catalog);
      await tester.pump();
      final primeira = find.byKey(MotionKeys.itemDaLista(0));
      final quarta = find.byKey(MotionKeys.itemDaLista(3));
      expect(primeira, findsOneWidget);
      expect(opacidade(tester, quarta), lessThan(1));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(opacidade(tester, quarta), 1);
    });
  });

  group('primeira carga (H-ANI-07)', () {
    testWidgets('o esqueleto fica até carregar e se dissolve no conteúdo', (
      tester,
    ) async {
      final cubit = await mount(
        tester,
        (s) => s.schoolDayOne(),
        tab: CourseGuideTab.catalog,
        load: false,
      );
      await tester.pump();
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
      expect(find.byKey(MotionKeys.shimmerConteudo), findsNothing);
      await cubit.load();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsOneWidget);
      expect(find.byKey(MotionKeys.shimmerConteudo), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(MotionKeys.shimmerEsqueleto), findsNothing);
    });
  });

  group('estatísticas (H-ANI-13, H-ANI-18)', () {
    testWidgets('barras enchem e o total conta, só na Escola', (tester) async {
      await mount(
        tester,
        (s) => s.schoolDayOneProgress(),
        tab: CourseGuideTab.stats,
      );
      await tester.pump();
      expect(find.byKey(MotionKeys.barraQueEnche), findsWidgets);
      expect(find.byKey(MotionKeys.numeroQueConta), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byKey(MotionKeys.numeroQueConta), findsOneWidget);
    });
  });

  group('metas (H-ANI-13, H-ANI-17)', () {
    testWidgets('a barra do dia enche; a Escola é quem anima', (tester) async {
      await mount(tester, (s) => s.schoolDayOne(), tab: CourseGuideTab.goals);
      await tester.pump();
      expect(find.byKey(MotionKeys.barraQueEnche), findsOneWidget);
    });

    testWidgets('metas feitas entram em ordem, 90 ms entre elas', (
      tester,
    ) async {
      await mount(tester, (s) => s.schoolAllDone(), tab: CourseGuideTab.goals);
      await tester.pump();
      expect(find.byKey(MotionKeys.itemDaLista(0)), findsOneWidget);
      expect(find.byKey(MotionKeys.itemDaLista(1)), findsWidgets);
    });
  });

  group('escola concluída (H-ANI-25)', () {
    testWidgets('o resultado se monta em ordem e o botão vem por último', (
      tester,
    ) async {
      await mount(
        tester,
        (s) => s.schoolDayOne().copyWith(
          completedLessons: {
            for (final l in escola.lessons.where((l) => l.visible))
              l.id: '2026-10-25',
          },
        ),
      );
      await tester.pump();
      final estrela = find.byKey(MotionKeys.parteDoResultado('titulo'));
      final botoes = find.byKey(MotionKeys.parteDoResultado('botoes'));
      expect(estrela, findsOneWidget);
      expect(botoes, findsOneWidget);
      expect(opacidade(tester, botoes), 0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(opacidade(tester, botoes), 1);
      expect(find.byKey(TrainingKeys.completedPrimary), findsOneWidget);
    });
  });
}
