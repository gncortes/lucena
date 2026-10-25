import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/widgets/course/chapter_lesson_list.dart';
import 'package:lucena/ui/endgames/view_models/endgame_lesson_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgame_lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_journey_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  final sample = FakeEndgameLessonRepository.sample.lessons.first;
  const steps = [TalkStep(id: 'a', fen: FakeEndgameLessonRepository.lucenaFen)];

  /// A Lucena do fake com duas lições (p1 e p2), com roteiro.
  EndgameTrail parted() => EndgameTrail(
    modules: [
      EndgameModule(
        id: sample.module,
        lessons: [
          EndgameLesson(
            id: sample.id,
            module: sample.module,
            lesson: Lesson.parted(
              id: sample.id,
              parts: const [
                LessonPart(id: 'p1', steps: steps, script: 'p1.json'),
                LessonPart(id: 'p2', steps: steps, script: 'p2.json'),
              ],
            ),
            exercises: sample.exercises,
            passScore: sample.passScore,
            keyPositions: sample.keyPositions,
            practice: sample.practice,
            references: sample.references,
          ),
        ],
      ),
    ],
  );

  final partedTexts = LessonTexts.fromJson({
    ...FakeEndgameLessonRepository.sampleTexts.toJson(),
    '${sample.id}.part.p1.title': 'First',
    '${sample.id}.part.p1.summary': 'Summary of the first.',
    '${sample.id}.part.p2.title': 'Second',
    '${sample.id}.part.p2.summary': 'Summary of the second.',
  });

  /// Monta a tela com um roteador que anota o endereço aberto.
  Future<List<Uri>> pump(
    WidgetTester tester, {
    String id = 'rook.lucena',
    EndgameProgress progress = const EndgameProgress(),
    EndgameTrail? trail,
    LessonTexts? texts,
    Locale locale = const Locale('en'),
  }) async {
    final cubit = EndgameLessonCubit(
      lessons: FakeEndgameLessonRepository(trail: trail, texts: texts),
      progress: FakeEndgameProgressRepository(progress),
      journey: FakeJourneyRepository(),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load(id, locale.languageCode);
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    final opened = <Uri>[];
    Widget record(BuildContext context, GoRouterState state) {
      opened.add(state.uri);
      return const SizedBox();
    }

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: const EndgameLessonScreen(),
          ),
          routes: [
            GoRoute(path: 'endgames/:lesson/:page', builder: record),
            GoRoute(path: 'setup', builder: record),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        router: router,
        locale: locale,
        child: const SizedBox(),
      ),
    );
    await tester.pumpAndSettle();
    return opened;
  }

  testWidgets('nada feito: a lição recomendada, os exercícios e o botão de '
      'começar', (tester) async {
    final opened = await pump(tester, trail: parted(), texts: partedTexts);
    expect(find.text('The Lucena position'), findsOneWidget);
    expect(find.text('Rook endgames · chapter 1 of 1'), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.part('p1')), findsOneWidget);
    expect(find.byKey(EndgameLessonKeys.part('p2')), findsOneWidget);
    // Só a lição recomendada mostra o resumo.
    expect(find.text('Summary of the first.'), findsOneWidget);
    expect(find.text('Summary of the second.'), findsNothing);
    expect(find.text('3 practice exercises'), findsOneWidget);
    expect(find.text('Start lesson 1'), findsOneWidget);

    await tester.tap(find.byKey(EndgameLessonKeys.continueButton));
    await tester.pumpAndSettle();
    expect(opened.single.path, '/endgames/rook.lucena/roteiro');
    expect(opened.single.queryParameters['part'], 'p1');
  });

  testWidgets('a linha dos exercícios abre a introdução até resolver todos', (
    tester,
  ) async {
    final opened = await pump(tester);
    await tester.tap(find.byKey(EndgameLessonKeys.exercises));
    await tester.pumpAndSettle();
    expect(opened.single.path, '/endgames/rook.lucena/intro');
  });

  testWidgets('tudo resolvido: os exercícios abrem o resultado e o botão '
      'treina a posição', (tester) async {
    final opened = await pump(
      tester,
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1, 'e02': 2, 'e03': 1},
          ),
        },
      ),
    );
    expect(find.text('Train this position'), findsOneWidget);
    await tester.tap(find.byKey(EndgameLessonKeys.exercises));
    await tester.pumpAndSettle();
    expect(opened.single.path, '/endgames/rook.lucena/done');
  });

  testWidgets('lições feitas e exercícios pela metade: continuar os '
      'exercícios', (tester) async {
    final opened = await pump(
      tester,
      progress: const EndgameProgress(
        lessons: {
          'rook.lucena': EndgameLessonProgress(
            lessonDone: true,
            stars: {'e01': 1},
          ),
        },
      ),
    );
    expect(find.text('Continue the exercises'), findsOneWidget);
    await tester.tap(find.byKey(EndgameLessonKeys.continueButton));
    await tester.pumpAndSettle();
    expect(opened.single.path, '/endgames/rook.lucena/intro');
  });

  testWidgets('lições feitas e nenhum exercício: fazer os exercícios', (
    tester,
  ) async {
    await pump(
      tester,
      progress: const EndgameProgress(
        lessons: {'rook.lucena': EndgameLessonProgress(lessonDone: true)},
      ),
    );
    expect(find.text('Do the practice exercises'), findsOneWidget);
  });

  testWidgets('aula que não existe', (tester) async {
    await pump(tester, id: 'nothing');
    expect(find.byKey(EndgameLessonKeys.missing), findsOneWidget);
  });

  testWidgets('aula em revisão: o aviso aparece só nela', (tester) async {
    await pump(tester);
    expect(find.byKey(EndgameLessonKeys.inReview), findsNothing);

    final review = EndgameLesson(
      id: sample.id,
      module: sample.module,
      lesson: sample.lesson,
      exercises: sample.exercises,
      passScore: sample.passScore,
      keyPositions: sample.keyPositions,
      practice: sample.practice,
      references: sample.references,
      inReview: true,
    );
    await pump(
      tester,
      trail: EndgameTrail(
        modules: [
          EndgameModule(id: review.module, lessons: [review]),
        ],
      ),
    );
    expect(find.byKey(EndgameLessonKeys.inReview), findsOneWidget);
    expect(find.textContaining('under review'), findsOneWidget);
  });

  testWidgets('capítulo começado: "Continuar" volta na etapa em que o aluno '
      'saiu', (tester) async {
    final opened = await pump(
      tester,
      trail: parted(),
      progress: EndgameProgress(
        lessons: {
          sample.id: const EndgameLessonProgress(parts: {'p1'}),
        },
        ongoing: LessonCheckpoint(lessonId: sample.id, part: 'p2', step: 2),
      ),
    );
    expect(find.text('Continue lesson 2'), findsOneWidget);
    await tester.tap(find.byKey(EndgameLessonKeys.continueButton));
    await tester.pumpAndSettle();
    expect(opened.single.queryParameters['part'], 'p2');
    expect(opened.single.queryParameters['etapa'], '2');
  });

  testWidgets('tocar numa lição abre o roteiro dela', (tester) async {
    final opened = await pump(tester, trail: parted(), texts: partedTexts);
    await tester.tap(find.byKey(EndgameLessonKeys.part('p2')));
    await tester.pumpAndSettle();
    expect(opened.single.queryParameters['part'], 'p2');
    expect(opened.single.queryParameters['etapa'], '0');
  });

  for (final size in phoneSizes) {
    testWidgets('geometria do canvas (PropV2FinaisLicao) em '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      setPhoneSize(tester, size);
      await pump(
        tester,
        trail: parted(),
        texts: partedTexts,
        locale: const Locale('pt'),
        progress: EndgameProgress(
          lessons: {
            sample.id: const EndgameLessonProgress(parts: {'p1'}),
          },
        ),
      );
      expect(tester.takeException(), isNull);
      final width = size.width;
      // O cartão da lista: 16 de margem nas laterais.
      final card = tester.getRect(find.byType(ChapterLessonList));
      expect(card.left, closeToDp(16));
      expect(card.right, closeToDp(width - 16));
      // As linhas: 6 dentro do cartão, alvo de 48 no mínimo.
      for (final key in [
        EndgameLessonKeys.part('p1'),
        EndgameLessonKeys.part('p2'),
        EndgameLessonKeys.exercises,
      ]) {
        final row = rectOf(tester, key);
        expect(row.left, closeToDp(22));
        expect(row.right, closeToDp(width - 22));
        expect(row.height, greaterThanOrEqualTo(48));
      }
      // A feita tem 48; a recomendada, com o resumo, cresce.
      expect(
        rectOf(tester, EndgameLessonKeys.part('p1')).height,
        closeToDp(48),
      );
      expect(
        rectOf(tester, EndgameLessonKeys.part('p2')).height,
        greaterThan(48),
      );
      // O primeiro item do cartão: 8 abaixo do topo dele.
      expect(
        rectOf(tester, EndgameLessonKeys.part('p1')).top,
        closeToDp(card.top + 8),
      );
      // O botão do rodapé: 52 de altura, 16 das laterais, colado embaixo.
      final button = rectOf(tester, EndgameLessonKeys.continueButton);
      expect(button.height, closeToDp(52));
      expect(button.left, closeToDp(16));
      expect(button.right, closeToDp(width - 16));
      expect(button.bottom, closeToDp(size.height - 8));
      expect(find.text('Começar a lição 2'), findsOneWidget);
    });
  }
}
