import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/use_cases/game_rules.dart';
import 'package:lucena/ui/catalog/widgets/catalog_ui.dart';
import 'package:lucena/ui/core/keys/custom_position_keys.dart';
import 'package:lucena/ui/core/widgets/position_board.dart';
import 'package:lucena/ui/custom_position/view_models/custom_position_cubit.dart';
import 'package:lucena/ui/custom_position/widgets/custom_position_screen.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/board_gestures.dart';
import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/fakes/fake_training_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late CustomPositionCubit cubit;

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    cubit = CustomPositionCubit(FakeTrainingRepository());
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

  testWidgets('o tabuleiro fica em cima (sem centralizar) e, com a posição '
      'jogável, voa até o da preparação da partida e volta, virando para o '
      'lado de quem joga', (tester) async {
    await pump(tester);
    // Na edição o tabuleiro fica no alto, logo abaixo da barra do app.
    final appBar = tester.getRect(find.byType(AppBar));
    final editorRect = tester.getRect(find.byKey(CustomPositionKeys.editor));
    expect(editorRect.top, closeTo(appBar.bottom, 1));

    const fen = '8/8/8/4k3/8/r7/4P3/4K2R b - - 0 1';
    await typeFen(tester, fen);
    final position = cubit.state.position!;
    final tag = setupBoardTag(fen: position.fen);
    // A rota da preparação relê o FEN: a marca precisa ser a mesma lá.
    expect(GameRules.fromFen(position.fen)!.fen, position.fen);
    expect(find.byWidgetPredicate((w) => w is Hero && w.tag == tag), findsOne);

    // A preparação da partida vê a posição pelas pretas (quem joga).
    Navigator.of(tester.element(find.byKey(CustomPositionKeys.editor))).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          body: Center(
            child: PositionBoard(
              fen: position.fen,
              size: 300,
              orientation: Side.black,
              heroTag: tag,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // No ar: um tabuleiro só, o da viagem, sem coordenadas.
    expect(find.byType(StaticChessboard), findsOne);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(CustomPositionKeys.editor), findsNothing);
    expect(find.byType(StaticChessboard), findsOne);

    Navigator.of(tester.element(find.byType(StaticChessboard))).pop();
    await tester.pumpAndSettle();
    expect(find.byKey(CustomPositionKeys.editor), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('posição incompleta: o tabuleiro não voa para lugar nenhum', (
    tester,
  ) async {
    await pump(tester);
    await typeFen(tester, '8/8/8/8/8/8/4P3/4K3 w - - 0 1');
    expect(cubit.state.position, isNull);
    final hero = tester.widget<Hero>(
      find.ancestor(
        of: find.byKey(CustomPositionKeys.editor),
        matching: find.byType(Hero),
      ),
    );
    expect(hero.tag, isNot(isA<String>()));
  });
}
