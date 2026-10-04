import 'dart:ui' show Tristate;

import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/board_settings/widgets/board_appearance_screen.dart';
import 'package:lucena/ui/core/keys/board_settings_keys.dart';
import 'package:lucena/ui/settings/view_models/settings_cubit.dart';

import '../../../../testing/fakes/fake_settings_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  late FakeSettingsRepository repository;

  Future<void> pumpScreen(
    WidgetTester tester, {
    BoardSettings board = const BoardSettings(),
    Locale locale = const Locale('en'),
  }) async {
    // Tela de celular em retrato: a lista de opções cabe quase inteira.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    repository = FakeSettingsRepository(AppSettings(board: board));
    final cubit = SettingsCubit(repository, languages: AppLanguage.selectable);
    addTearDown(cubit.close);
    await cubit.load();
    await tester.pumpWidget(
      TestApp(
        locale: locale,
        settingsCubit: cubit,
        child: const BoardAppearanceScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  StaticChessboardSettings preview(WidgetTester tester) => tester
      .widget<StaticChessboard>(find.byKey(BoardSettingsKeys.preview))
      .settings;

  Future<void> tapOption(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, Key key) =>
      tester.getSemantics(find.byKey(key)).flagsCollection.isSelected ==
      Tristate.isTrue;

  testWidgets('abre com a amostra na aparência gravada', (tester) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(
        colors: BoardColors.brown,
        pieces: PieceStyle.chessnut,
        coordinates: false,
      ),
    );

    expect(preview(tester).colorScheme, ChessboardColorScheme.brown);
    expect(preview(tester).pieceAssets, PieceSet.chessnutAssets);
    expect(preview(tester).enableCoordinates, isFalse);
    expect(
      isSelected(tester, BoardSettingsKeys.colorsOption(BoardColors.brown)),
      isTrue,
    );
    expect(
      isSelected(tester, BoardSettingsKeys.colorsOption(BoardColors.blue)),
      isFalse,
    );
  });

  testWidgets('trocar as peças muda a amostra na hora e grava', (tester) async {
    await pumpScreen(tester);

    await tapOption(tester, BoardSettingsKeys.piecesOption(PieceStyle.merida));

    expect(preview(tester).pieceAssets, PieceSet.meridaAssets);
    expect(repository.saved.last.board.pieces, PieceStyle.merida);
    expect(
      isSelected(tester, BoardSettingsKeys.piecesOption(PieceStyle.merida)),
      isTrue,
    );
  });

  testWidgets('trocar as cores muda a amostra na hora e grava', (tester) async {
    await pumpScreen(tester);

    await tapOption(tester, BoardSettingsKeys.colorsOption(BoardColors.green));

    expect(preview(tester).colorScheme, ChessboardColorScheme.green);
    expect(repository.saved.last.board.colors, BoardColors.green);
  });

  testWidgets('desligar as coordenadas tira as coordenadas da amostra', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(preview(tester).enableCoordinates, isTrue);

    await tapOption(tester, BoardSettingsKeys.coordinatesSwitch);

    expect(preview(tester).enableCoordinates, isFalse);
    expect(repository.saved.last.board.coordinates, isFalse);
  });

  testWidgets('restaurar padrão volta cores, peças e coordenadas', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(
        colors: BoardColors.purple,
        pieces: PieceStyle.pixel,
        coordinates: false,
      ),
    );

    await tapOption(tester, BoardSettingsKeys.resetButton);

    expect(preview(tester).colorScheme, ChessboardColorScheme.blue);
    expect(preview(tester).pieceAssets, PieceSet.cburnettAssets);
    expect(preview(tester).enableCoordinates, isTrue);
    expect(repository.saved.last.board, const BoardSettings());
  });

  testWidgets('os nomes das cores vêm traduzidos', (tester) async {
    await pumpScreen(tester, locale: const Locale('pt'));

    expect(find.text('Azul'), findsOneWidget);
    expect(find.text('Marrom'), findsOneWidget);
    expect(find.text('Restaurar padrão'), findsOneWidget);
  });

  testWidgets('em árabe a amostra não espelha', (tester) async {
    await pumpScreen(tester, locale: const Locale('ar'));

    final board = tester.element(find.byKey(BoardSettingsKeys.preview));
    expect(Directionality.of(board), TextDirection.ltr);
  });
}
