import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_lesson.dart';
import 'package:lucena/ui/core/keys/endgames_keys.dart';
import 'package:lucena/ui/endgames/view_models/endgames_cubit.dart';
import 'package:lucena/ui/endgames/widgets/endgames_screen.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
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
    expect(find.text('0 of 2 passed'), findsOneWidget);
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
    expect(find.text('1 of 2 passed'), findsOneWidget);
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
}
