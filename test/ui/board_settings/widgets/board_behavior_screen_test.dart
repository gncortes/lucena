import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_language.dart';
import 'package:lucena/domain/models/app_settings.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/board_settings/widgets/board_behavior_screen.dart';
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
        child: const BoardBehaviorScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();
  }

  String textOf(WidgetTester tester, Key key) =>
      tester.widget<Text>(find.byKey(key)).data!;

  bool switchValue(WidgetTester tester, Key key) =>
      tester.widget<SwitchListTile>(find.byKey(key)).value;

  testWidgets('abre com o comportamento gravado', (tester) async {
    await pumpScreen(
      tester,
      board: const BoardSettings(
        moveMethod: MoveMethod.drag,
        showLegalMoves: false,
        notation: MoveNotation.letters,
      ),
    );

    expect(textOf(tester, BoardSettingsKeys.moveMethodValue), 'Drag only');
    expect(switchValue(tester, BoardSettingsKeys.legalMovesSwitch), isFalse);
    expect(switchValue(tester, BoardSettingsKeys.lastMoveSwitch), isTrue);
    expect(textOf(tester, BoardSettingsKeys.notationValue), 'Letters');
  });

  testWidgets('cada chave liga e desliga a sua preferência e grava', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tap(tester, BoardSettingsKeys.legalMovesSwitch);
    expect(repository.saved.last.board.showLegalMoves, isFalse);

    await tap(tester, BoardSettingsKeys.lastMoveSwitch);
    expect(repository.saved.last.board.highlightLastMove, isFalse);

    await tap(tester, BoardSettingsKeys.animationSwitch);
    expect(repository.saved.last.board.animation, isFalse);

    await tap(tester, BoardSettingsKeys.premovesSwitch);
    expect(repository.saved.last.board.premoves, isFalse);

    await tap(tester, BoardSettingsKeys.legalMovesSwitch);
    expect(
      repository.saved.last.board,
      const BoardSettings(
        highlightLastMove: false,
        animation: false,
        premoves: false,
      ),
    );
  });

  testWidgets('o jeito de mover só muda depois de confirmar no painel', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tap(tester, BoardSettingsKeys.moveMethodTile);
    expect(find.byKey(BoardSettingsKeys.choiceSheet), findsOneWidget);
    await tap(tester, BoardSettingsKeys.moveMethodOption(MoveMethod.tap));
    expect(repository.saved, isEmpty);

    await tap(tester, BoardSettingsKeys.choiceConfirmButton);

    expect(find.byKey(BoardSettingsKeys.choiceSheet), findsNothing);
    expect(textOf(tester, BoardSettingsKeys.moveMethodValue), 'Tap only');
    expect(repository.saved.last.board.moveMethod, MoveMethod.tap);
  });

  testWidgets('fechar o painel sem confirmar não muda nada', (tester) async {
    await pumpScreen(tester);

    await tap(tester, BoardSettingsKeys.moveMethodTile);
    await tap(tester, BoardSettingsKeys.moveMethodOption(MoveMethod.drag));
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.byKey(BoardSettingsKeys.choiceSheet), findsNothing);
    expect(textOf(tester, BoardSettingsKeys.moveMethodValue), 'Drag or tap');
    expect(repository.saved, isEmpty);
  });

  testWidgets('notação por letras: o exemplo usa as letras do idioma', (
    tester,
  ) async {
    await pumpScreen(tester, locale: const Locale('pt'));

    await tap(tester, BoardSettingsKeys.notationTile);
    expect(find.textContaining('Cf3  Bc4  Dxf7'), findsOneWidget);
    expect(find.textContaining('♘f3  ♗c4  ♕xf7'), findsOneWidget);

    await tap(tester, BoardSettingsKeys.notationOption(MoveNotation.letters));
    await tap(tester, BoardSettingsKeys.choiceConfirmButton);

    expect(textOf(tester, BoardSettingsKeys.notationValue), 'Letras');
    expect(repository.saved.last.board.notation, MoveNotation.letters);
  });
}
