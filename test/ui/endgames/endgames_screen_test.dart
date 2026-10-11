import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    EndgameProgress progress = const EndgameProgress(),
    Locale locale = const Locale('en'),
  }) async {
    final cubit = EndgamesCubit(
      lessons: FakeEndgameLessonRepository(),
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

  testWidgets('o Viktor recebe, o módulo e as aulas com a nota', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('These are the endgame lessons.'), findsOneWidget);
    expect(find.text('0 of 2 completed'), findsOneWidget);
    expect(find.text('Start the first lesson'), findsOneWidget);
    expect(find.byKey(EndgamesKeys.module('rook')), findsOneWidget);
    expect(find.text('Rook endgames'), findsOneWidget);
    expect(find.byKey(EndgamesKeys.lesson('rook.lucena')), findsOneWidget);
    expect(find.byKey(EndgamesKeys.lesson('rook.philidor')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(EndgamesKeys.lessonScore('rook.lucena')))
          .data,
      '0/6',
    );
  });

  testWidgets('com uma aprovada, continua na seguinte', (tester) async {
    await pump(
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
    expect(find.text('Good to see you again.'), findsOneWidget);
    expect(find.text('1 of 2 completed'), findsOneWidget);
    expect(find.text('Continue: The Philidor defence'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(EndgamesKeys.lessonScore('rook.lucena')))
          .data,
      '4/6',
    );
  });

  testWidgets('em árabe a tela espelha', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(find.byKey(EndgamesKeys.screen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(EndgamesKeys.overview))),
      TextDirection.rtl,
    );
  });

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
    expect(find.text('No lessons'), findsOneWidget);
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
