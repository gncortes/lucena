import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/core/widgets/course/course_continue_card.dart';
import 'package:lucena/ui/core/widgets/course/course_part_header.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/phone_size.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    EndgameProgress progress = const EndgameProgress(),
    Locale locale = const Locale('en'),
    EndgameTrail? trail,
  }) async {
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(trail: trail),
      progress: FakeEndgameProgressRepository(progress),
      characters: FakeCharacterRepository(),
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sem conteúdo: mensagem centrada e sem filtros sem opções', (
    tester,
  ) async {
    await pump(tester, locale: const Locale('pt'), trail: EndgameTrail.empty);
    final message = find.text('As aulas ainda não estão disponíveis.');
    expect(message, findsOneWidget);
    expect(find.byKey(EndgamesKeys.filtersButton), findsNothing);
    expect(
      tester.getCenter(message).dx,
      closeTo(
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
        .5,
      ),
    );
  });

  const passed = EndgameProgress(
    lessons: {
      'rook.lucena': EndgameLessonProgress(
        lessonDone: true,
        stars: {'e01': 1, 'e02': 2, 'e03': 1},
      ),
    },
  );

  testWidgets('sem nada feito: o Continuar no primeiro capítulo e a parte '
      'com a contagem', (tester) async {
    await pump(tester);
    expect(find.text('Rook endgames · chapter 1'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.byKey(EndgamesKeys.continueButton), findsOneWidget);
    expect(find.byKey(EndgamesKeys.module('rook')), findsOneWidget);
    expect(find.text('0 of 2'), findsOneWidget);
    expect(find.byKey(EndgamesKeys.lesson('rook.lucena')), findsOneWidget);
    expect(find.byKey(EndgamesKeys.lesson('rook.philidor')), findsOneWidget);
    // Sem nota alcançada, sem medalha.
    expect(find.byKey(EndgamesKeys.medal('rook.lucena')), findsNothing);
    expect(find.byKey(EndgamesKeys.filtersButton), findsOneWidget);
  });

  testWidgets('com um aprovado: a medalha nele e o Continuar no seguinte', (
    tester,
  ) async {
    await pump(tester, progress: passed);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('Rook endgames · chapter 2'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byKey(EndgamesKeys.medal('rook.lucena')), findsOneWidget);
    expect(find.byKey(EndgamesKeys.medal('rook.philidor')), findsNothing);
  });

  for (final size in phoneSizes) {
    testWidgets('geometria do canvas (PropV2FinaisCurso) em '
        '${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      setPhoneSize(tester, size);
      await pump(tester, progress: passed, locale: const Locale('pt'));
      expect(tester.takeException(), isNull);
      final width = size.width;
      final bar = tester.getRect(find.byType(AppBar));
      // O cartão Continuar: 8 abaixo da barra, 16 das laterais.
      final card = tester.getRect(find.byType(CourseContinueCard));
      expect(card.top, closeToDp(bar.bottom + 8));
      expect(card.left, closeToDp(16));
      expect(card.right, closeToDp(width - 16));
      expect(rectOf(tester, EndgamesKeys.continueButton).height, closeToDp(48));
      // A parte: 12 abaixo do cartão; o primeiro capítulo, 12 abaixo dela; 8
      // entre os capítulos.
      final header = tester.getRect(find.byType(CoursePartHeader));
      expect(header.top, closeToDp(card.bottom + 12));
      final first = rectOf(tester, EndgamesKeys.lesson('rook.lucena'));
      final second = rectOf(tester, EndgamesKeys.lesson('rook.philidor'));
      expect(first.top, closeToDp(header.bottom + 12));
      expect(second.top, closeToDp(first.bottom + 8));
      for (final tile in [first, second]) {
        expect(tile.left, closeToDp(16));
        expect(tile.right, closeToDp(width - 16));
        expect(tile.height, greaterThanOrEqualTo(48));
      }
      // A medalha: 20 de altura, 16 da borda do cartão do capítulo.
      final medal = rectOf(tester, EndgamesKeys.medal('rook.lucena'));
      expect(medal.height, closeToDp(20));
      expect(medal.right, closeToDp(first.right - 16));
      expect(medal.top, closeToDp(first.top + 16));
      expect(find.text('1 de 2'), findsOneWidget);
    });
  }

  testWidgets('filtros: modal, chip com X, estado vazio e limpar', (
    tester,
  ) async {
    final settings = FakeSettingsRepository();
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(),
      progress: FakeEndgameProgressRepository(),
      characters: FakeCharacterRepository(),
      settings: settings,
    );
    addTearDown(cubit.close);
    await cubit.load('en');
    await tester.pumpWidget(
      TestApp(
        child: BlocProvider.value(value: cubit, child: const EndgamesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EndgamesKeys.filtersButton));
    await tester.pumpAndSettle();
    expect(find.byKey(EndgamesKeys.filtersSheet), findsOneWidget);
    // Só os tipos que têm aula; sem o mapa de habilidades, sem dificuldade.
    expect(find.byKey(EndgamesKeys.filterOption('kind.rook')), findsOneWidget);
    expect(find.byKey(EndgamesKeys.filterOption('kind.pawn')), findsNothing);
    expect(find.byKey(EndgamesKeys.filterOption('sort.easiest')), findsNothing);

    await tester.tap(find.byKey(EndgamesKeys.filterOption('status.passed')));
    await tester.pumpAndSettle();
    expect(find.text('No chapters'), findsOneWidget);
    await tester.tap(find.byKey(EndgamesKeys.filtersApply));
    await tester.pumpAndSettle();

    expect(
      find.byKey(EndgamesKeys.filterChip('status.passed')),
      findsOneWidget,
    );
    expect(find.byKey(EndgamesKeys.filtersEmpty), findsOneWidget);
    expect(find.byKey(EndgamesKeys.module('rook')), findsNothing);
    expect((await settings.load()).endgamesFilter.statuses, {
      EndgameLessonStatus.passed,
    });

    // O X do chip tira o filtro.
    await tester.tap(
      find.descendant(
        of: find.byKey(EndgamesKeys.filterChip('status.passed')),
        matching: find.byIcon(Icons.clear),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(EndgamesKeys.filtersEmpty), findsNothing);
    expect(find.byKey(EndgamesKeys.module('rook')), findsOneWidget);

    // Dois filtros e o "Limpar".
    await cubit.toggleKind(EndgameKind.rook);
    await cubit.toggleStatus(EndgameLessonStatus.open);
    await tester.pumpAndSettle();
    expect(find.byKey(EndgamesKeys.filterChip('kind.rook')), findsOneWidget);
    expect(find.byKey(EndgamesKeys.lesson('rook.lucena')), findsOneWidget);
    await tester.tap(find.byKey(EndgamesKeys.filtersClear));
    await tester.pumpAndSettle();
    expect(find.byKey(EndgamesKeys.filterChip('kind.rook')), findsNothing);
    expect(cubit.state.filter, const EndgameFilter());
    expect(const AppSettings().endgamesFilter, const EndgameFilter());
  });
}
