import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/endgame_position.dart';
import 'package:lucena/ui/core/keys/custom_position_keys.dart';
import 'package:lucena/ui/core/keys/sheet_keys.dart';
import 'package:lucena/ui/custom_position/view_models/custom_position_cubit.dart';
import 'package:lucena/ui/custom_position/widgets/custom_position_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/board_gestures.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late CustomPositionCubit cubit;
  late FakeTrainingRepository training;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    training = FakeTrainingRepository();
    cubit = CustomPositionCubit(training);
    addTearDown(cubit.close);
    await cubit.load();
    final settings = SettingsCubit(
      FakeSettingsRepository(),
      languages: AppLanguage.selectable,
    );
    addTearDown(settings.close);
    await settings.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: settings,
        child: BlocProvider.value(
          value: cubit,
          child: const CustomPositionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> typeFen(WidgetTester tester, String fen) async {
    await tester.enterText(find.byKey(CustomPositionKeys.fenField), fen);
    await tester.pumpAndSettle();
  }

  String? errorText(WidgetTester tester) {
    final finder = find.byKey(CustomPositionKeys.error);
    if (finder.evaluate().isEmpty) return null;
    return tester.widget<Text>(finder).data;
  }

  bool canContinue(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(CustomPositionKeys.continueButton))
          .onPressed !=
      null;

  for (final dismiss in [CustomPositionKeys.clearCancel, SheetKeys.close]) {
    testWidgets('Limpar: $dismiss preserva composição e rascunho', (
      tester,
    ) async {
      await pump(tester);
      const fen = '4k3/8/8/8/8/8/4P3/4K3 b - - 0 1';
      await typeFen(tester, fen);
      cubit.setGoal(PositionGoal.draw);
      await tester.pumpAndSettle();
      final before = cubit.state;
      final controller = tester
          .widget<TextField>(find.byKey(CustomPositionKeys.fenField))
          .controller!;
      const selection = TextSelection(baseOffset: 4, extentOffset: 12);
      controller.selection = selection;

      await tester.tap(find.byKey(CustomPositionKeys.clearButton));
      await tester.pumpAndSettle();
      expect(find.byKey(CustomPositionKeys.clearSheet), findsOneWidget);
      expect(cubit.state, before);
      expect(training.draft?.fen, fen);
      await tester.tap(find.byKey(dismiss));
      await tester.pumpAndSettle();

      expect(find.byKey(CustomPositionKeys.clearSheet), findsNothing);
      expect(cubit.state, before);
      expect(controller.text, fen);
      expect(controller.selection, selection);
      final restored = CustomPositionCubit(training);
      addTearDown(restored.close);
      await restored.load();
      expect(restored.state, before);
    });
  }

  testWidgets('confirmar Limpar persiste só os reis, vez e objetivo', (
    tester,
  ) async {
    await pump(tester);
    await typeFen(tester, '4k3/8/8/8/8/8/4P3/4K3 b - - 0 1');
    cubit.setGoal(PositionGoal.draw);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CustomPositionKeys.clearButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CustomPositionKeys.clearConfirm));
    await tester.pumpAndSettle();

    const cleared = '${CustomPositionCubit.startBoard} b - - 0 1';
    expect(cubit.state.fen, cleared);
    expect(
      tester
          .widget<TextField>(find.byKey(CustomPositionKeys.fenField))
          .controller!
          .text,
      cleared,
    );
    final restored = CustomPositionCubit(training);
    addTearDown(restored.close);
    await restored.load();
    expect(restored.state.fen, cleared);
    expect(restored.state.goal, PositionGoal.draw);
    expect(restored.state.turn, Side.black);
  });

  testWidgets('FEN inválido: erro traduzido e não segue', (tester) async {
    await pump(tester, locale: const Locale('pt'));

    await typeFen(tester, 'abc');

    expect(errorText(tester), 'Isso não é um FEN válido.');
    expect(canContinue(tester), isFalse);
  });

  testWidgets('FEN sem rei: diz qual rei falta', (tester) async {
    await pump(tester, locale: const Locale('pt'));

    await typeFen(tester, '8/8/8/8/8/8/4P3/4K3 w - - 0 1');

    expect(errorText(tester), 'Falta o rei das pretas.');
  });

  testWidgets('o lado que não joga em xeque: erro', (tester) async {
    await pump(tester);

    await typeFen(tester, 'R3k3/8/8/8/8/8/8/4K3 w - - 0 1');

    expect(errorText(tester), 'The side that is not to move is in check.');
  });

  testWidgets('FEN válido: sem erro, o editor mostra a posição e segue', (
    tester,
  ) async {
    await pump(tester);

    await typeFen(tester, '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');

    expect(errorText(tester), isNull);
    expect(canContinue(tester), isTrue);
    final editor = tester.widget<ChessboardEditor>(
      find.byKey(CustomPositionKeys.editor),
    );
    expect(editor.pieces[Square.a3], Piece.blackRook);
  });

  testWidgets('montar no editor: escolher a peça e tocar na casa', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(CustomPositionKeys.palette(Piece.whiteQueen)));
    await tester.pumpAndSettle();
    final board = tester.getRect(find.byKey(CustomPositionKeys.editor));
    await tester.tapAt(squareCenter(board, 'd1'));
    await tester.pumpAndSettle();

    expect(cubit.state.board, '4k3/8/8/8/8/8/8/3QK3');
    expect(errorText(tester), isNull);
    expect(canContinue(tester), isTrue);

    // A borracha tira a peça de volta.
    await tester.tap(find.byKey(CustomPositionKeys.eraseTool));
    await tester.pumpAndSettle();
    await tester.tapAt(squareCenter(board, 'd1'));
    await tester.pumpAndSettle();
    expect(cubit.state.board, CustomPositionCubit.startBoard);
  });

  testWidgets('o tabuleiro fica em cima (sem centralizar) e não voa para a '
      'tela seguinte', (tester) async {
    await pump(tester);
    // Na edição o tabuleiro fica no alto, logo abaixo da barra do app.
    final appBar = tester.getRect(find.byType(AppBar));
    final editorRect = tester.getRect(find.byKey(CustomPositionKeys.editor));
    expect(editorRect.top, closeTo(appBar.bottom, 1));

    await typeFen(tester, '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1');
    expect(cubit.state.position, isNotNull);
    // "Continuar" é uma navegação comum: nada de Hero em volta do editor.
    expect(
      find.ancestor(
        of: find.byKey(CustomPositionKeys.editor),
        matching: find.byType(Hero),
      ),
      findsNothing,
    );
  });
}
