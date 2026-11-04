import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_repository_asset.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/domain/models/training/school_training_progress.dart';
import 'package:lucena/domain/models/training/school_training_resources.dart';
import 'package:lucena/domain/models/training/training_content.dart';
import 'package:lucena/domain/models/training/training_course.dart';
import 'package:lucena/domain/models/training/training_course_config.dart';
import 'package:lucena/domain/models/training/training_resources.dart';
import 'package:lucena/domain/models/training/training_state.dart';
import 'package:lucena/ui/core/keys/course_guide_keys.dart';
import 'package:lucena/ui/course_entry/widgets/course_content_states.dart';
import 'package:lucena/ui/core/keys/training_keys.dart';
import 'package:lucena/ui/course_guide/view_models/course_guide_cubit.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_copy.dart';
import 'package:lucena/ui/course_guide/widgets/course_guide_screen.dart';
import 'package:lucena/ui/course_guide/widgets/training_progress_tab.dart';

import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';
import '../../../testing/training/training_scenario_builder.dart';

/// T85-D3 (Escola): textos e estrutura das abas do guia, H-ESC-04, 07, 08,
/// 19 e 20. Usa o índice real `assets/lessons/course.json`.
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
    void Function(TrainingLesson)? onLesson,
    VoidCallback? onDiploma,
    TrainingResources? resources,
  }) async {
    setPhoneSize(tester, const Size(412, 917));
    final scenario = TrainingScenarioBuilder(
      TrainingCourseConfig.escola.course,
      date: DateTime(2026, 10, 26, 12),
      resources: resources ?? escola,
    );
    final repository = scenario.repository(build(scenario).copyWith(tab: tab));
    final cubit = CourseGuideCubit(
      repository: repository,
      config: TrainingCourseConfig.escola,
      now: scenario.now,
    );
    addTearDown(repository.dispose);
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: const [],
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: CourseGuideScreen(
            onBack: () {},
            onPlan: () {},
            onHelp: () {},
            onWelcomeContinue: () {},
            onLesson: (l) => onLesson?.call(l),
            onDiploma: onDiploma,
            onChapter: (_) {},
            goalsBuilder: (_) => const SizedBox(),
            progressBuilder: (_) => TrainingProgressTab(
              onTheme: (_) {},
              onOpenings: () {},
              onTest: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('boas-vindas: texto do canvas e sem ajuda', (tester) async {
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(onboardingDone: false),
    );
    expect(find.text('Boas-vindas à Escola do Viktor'), findsOneWidget);
    expect(find.textContaining('em lições curtas'), findsOneWidget);
    expect(find.text('As abas aqui embaixo'), findsOneWidget);
    for (final phrase in const [
      'Lição: a próxima lição, sempre aqui.',
      'Metas: o que fazer hoje.',
      'Estatísticas: as lições feitas e as estrelas por peça.',
      'Catálogo: todas as lições do curso.',
    ]) {
      expect(find.text(phrase), findsOneWidget, reason: phrase);
    }
    expect(find.byKey(CourseGuideKeys.helpAction), findsNothing);
    expect(find.byKey(CourseGuideKeys.planAction), findsOneWidget);
  });

  testWidgets('abas: Lição, Metas, Estatísticas, Catálogo', (tester) async {
    await mount(tester, (s) => s.schoolDayOne());
    expect(find.text('Estatísticas'), findsOneWidget);
    expect(find.text('Progresso'), findsNothing);
  });

  testWidgets('primeira lição: Módulo 1 · Lição 1, A torre, Começar', (
    tester,
  ) async {
    await mount(tester, (s) => s.schoolDayOne());
    expect(find.text('Módulo 1 · Lição 1'), findsOneWidget);
    expect(find.text('A torre'), findsOneWidget);
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Dicas de estudo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ver o catálogo'), 200);
    expect(find.text('Ver o catálogo'), findsOneWidget);
  });

  testWidgets('quinta lição: Módulo 1 · Lição 5, Continuar', (tester) async {
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(
        completedLessons: {
          for (final l in escola.lessons.take(4)) l.id: '2026-10-25',
        },
      ),
    );
    expect(find.text('Módulo 1 · Lição 5'), findsOneWidget);
    expect(find.text('O cavalo'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('catálogo: só o módulo 1 aberto, título puro, expande', (
    tester,
  ) async {
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(
        completedLessons: {
          for (final l in escola.lessons.take(5)) l.id: '2026-10-25',
        },
      ),
      tab: CourseGuideTab.catalog,
    );
    expect(find.textContaining('Lição 1 ·'), findsNothing);
    expect(find.textContaining('Aula'), findsNothing);
    expect(
      find.byKey(CourseGuideKeys.chapterLesson(escola.lessons.first.id)),
      findsOneWidget,
    );
    expect(find.text('A torre'), findsOneWidget);
    expect(find.textContaining('MÓDULO 1'), findsOneWidget);
    final module2 = find.textContaining('Módulo 2 ·');
    await tester.scrollUntilVisible(module2, 300);
    expect(module2, findsOneWidget);
    // As abas no rodapé cobrem a última linha: centraliza antes do toque.
    await Scrollable.ensureVisible(tester.element(module2), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(module2);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('MÓDULO 2'), 200);
    expect(find.textContaining('MÓDULO 2'), findsOneWidget);
  });

  testWidgets('estatísticas: título, 4 de 37, Formatura 0 de 1', (
    tester,
  ) async {
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(
        completedLessons: {
          for (final l in escola.lessons.take(4)) l.id: '2026-10-25',
        },
        school: SchoolTrainingProgress(pieceLevels: {'rook': 2}),
      ),
      tab: CourseGuideTab.stats,
    );
    expect(find.text('Estatísticas'), findsNWidgets(2));
    expect(find.text('4 de 37'), findsOneWidget);
    expect(find.text('4 de 12'), findsOneWidget);
    expect(find.text('Formatura'), findsOneWidget);
    expect(find.text('0 de 1'), findsWidgets);
    expect(find.byKey(TrainingKeys.pieceStars('rook')), findsOneWidget);
  });

  testWidgets('Escola concluída: 4 abas e "Ver o diploma" abre o diploma', (
    tester,
  ) async {
    var opened = 0;
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(
        completedLessons: {
          for (final l in escola.lessons.where((l) => l.visible))
            l.id: '2026-10-25',
        },
      ),
      onDiploma: () => opened++,
    );
    expect(find.byKey(TrainingKeys.completedCourse), findsOneWidget);
    expect(find.text('Começar o Pilares'), findsNothing);
    // Abas só com ícone (H-TRE-18): conferidas pela key.
    for (final tab in [
      CourseGuideTab.lesson,
      CourseGuideTab.goals,
      CourseGuideTab.stats,
      CourseGuideTab.catalog,
    ]) {
      expect(
        find.byKey(CourseGuideKeys.tab(tab.name)),
        findsOneWidget,
        reason: tab.name,
      );
    }
    await tester.tap(find.text('Ver o diploma'));
    expect(opened, 1);
  });

  testWidgets('H-ESC-24: sem lição visível, Conteúdo indisponível e retry', (
    tester,
  ) async {
    await mount(
      tester,
      (s) => s.schoolDayOne(),
      resources: TrainingResources(),
    );
    expect(find.text('Conteúdo indisponível'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byKey(CourseGuideKeys.screen), findsNothing);
  });

  testWidgets('H-ESC-24: próxima lição não publicada mostra aviso e Metas', (
    tester,
  ) async {
    final lessons = escola.lessons.toList();
    final next = lessons[4];
    lessons[4] = TrainingLesson(
      id: next.id,
      kind: next.kind,
      title: next.title,
      group: next.group,
      groupId: next.groupId,
      partId: next.partId,
      partTitle: next.partTitle,
      published: false,
    );
    await mount(
      tester,
      (s) => s.schoolDayOne().copyWith(
        completedLessons: {
          for (final l in escola.lessons.take(4)) l.id: '2026-10-25',
        },
      ),
      resources: TrainingResources(lessons: lessons),
    );
    expect(find.byType(TrainingUnpublishedNotice), findsOneWidget);
    expect(find.text('Ver as metas'), findsOneWidget);
    expect(find.text('Começar'), findsNothing);
  });

  testWidgets('oferta de dobrar escreve o número por extenso', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    String body(int n) =>
        courseGuideCopy(context, 'trainingEscolaDoubleBody', count: n);
    expect(body(2), 'Entram hoje mais duas lições e os desafios delas.');
    expect(body(4), 'Entram hoje mais quatro lições e os desafios delas.');
    expect(body(8), 'Entram hoje mais oito lições e os desafios delas.');
    expect(body(12), 'Entram hoje mais doze lições e os desafios delas.');
  });
}
