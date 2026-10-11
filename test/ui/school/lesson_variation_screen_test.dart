import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/school/lesson_source.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/lesson.dart';
import 'package:lucena/ui/core/keys/school_keys.dart';
import 'package:lucena/ui/school/view_models/lesson_cubit.dart';
import 'package:lucena/ui/school/widgets/lesson_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../testing/fakes/fake_character_repository.dart';
import '../../../testing/fakes/fake_endgame_repositories.dart';
import '../../../testing/fakes/fake_opponent_repository.dart';
import '../../../testing/fakes/fake_settings_repository.dart';
import '../../../testing/test_app.dart';

/// A variante citada na fala: o lance tocado mostra a posição e o botão do
/// rodapé anda por ela lance a lance.
void main() {
  const said = 'Play 1.Rd1+ Ke7 2.Rd4 and the rook shields the king.';

  Future<void> pump(WidgetTester tester, String intro) async {
    tester.view.physicalSize = const Size(400, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = LessonCubit(
      source: EndgameLessonSource(
        FakeEndgameLessonRepository(
          texts: LessonTexts.fromJson({
            ...FakeEndgameLessonRepository.sampleTexts.toJson(),
            'rook.lucena.intro': intro,
          }),
        ),
        FakeEndgameProgressRepository(),
      ),
      characters: FakeCharacterRepository(),
      opponent: FakeOpponentRepository(),
      replyDelay: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.load('rook.lucena', 'en');
    final settings = SettingsCubit(
      FakeSettingsRepository(const AppSettings()),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        settingsCubit: settings,
        child: BlocProvider.value(value: cubit, child: const LessonScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  String fen(WidgetTester tester) => tester
      .widget<Chessboard>(find.byKey(LessonKeys.board))
      .controller
      .game
      .fen;

  Future<void> tapText(WidgetTester tester, String move) async {
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byKey(LessonKeys.speech),
        matching: find.byType(RichText),
      ),
    );
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: said.indexOf(move) + 1),
      Rect.zero,
    );
    await tester.tapAt(paragraph.localToGlobal(caret + const Offset(3, 8)));
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  testWidgets('tocar num lance da linha mostra a posição com ele jogado e '
      'tocar de novo volta ao passo', (tester) async {
    await pump(tester, said);
    final start = fen(tester);
    expect(start, startsWith('1K1k4/1P6/8/8/8/8/r7/2R5'));
    await tapText(tester, 'Ke7');
    // Depois de 1.Rd1+ Ke7: a torre em d1, o rei preto em e7.
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/8/8/r7/3R4'));
    expect(find.byKey(LessonKeys.variationExit), findsOneWidget);
    await tapText(tester, 'Ke7');
    expect(fen(tester), start);
    expect(find.byKey(LessonKeys.variationExit), findsNothing);
  });

  testWidgets('o botão do rodapé abre a variante e as setas andam por ela', (
    tester,
  ) async {
    await pump(tester, said);
    final start = fen(tester);
    await press(tester, LessonKeys.variationShow);
    // O primeiro lance já jogado.
    expect(fen(tester), startsWith('1K1k4/1P6/8/8/8/8/r7/3R4'));
    // A linha deste passo não é a errada: sem o selo.
    expect(find.byKey(LessonKeys.wrongLine), findsNothing);
    await press(tester, LessonKeys.variationForward);
    await press(tester, LessonKeys.variationForward);
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/3R4/8/r7/8'));
    // No fim, a seta de próximo lance desliga.
    expect(
      tester
          .widget<FloatingActionButton>(find.byKey(LessonKeys.variationForward))
          .onPressed,
      isNull,
    );
    await press(tester, LessonKeys.variationBack);
    expect(fen(tester), startsWith('1K6/1P2k3/8/8/8/8/r7/3R4'));
    await press(tester, LessonKeys.variationExit);
    expect(fen(tester), start);
    expect(find.byKey(LessonKeys.variationShow), findsOneWidget);
  });

  testWidgets('fala sem variante: sem o botão', (tester) async {
    await pump(tester, 'This is the Lucena position.');
    expect(find.byKey(LessonKeys.variationShow), findsNothing);
  });
}
