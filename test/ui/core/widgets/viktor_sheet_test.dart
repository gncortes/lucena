import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
import 'package:lucena/ui/core/widgets/viktor_sheet.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';

import '../../../../testing/fakes/fake_character_repository.dart';
import '../../../../testing/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool long = false,
    bool reducedMotion = false,
    bool teacher = false,
    bool fixedPeek = false,
    ValueChanged<bool>? onExpanded,
  }) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reducedMotion),
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, box) => ViktorSheet(
                  top: fixedPeek ? box.maxHeight - 160 : box.maxHeight * .7,
                  onExpanded: onExpanded,
                  children: [
                    if (teacher)
                      const TeacherSpeech(
                        teacher: FakeCharacterRepository.viktor,
                        text: 'Texto sem link, toque para abrir.',
                        speechContext: SpeechContext.game,
                        typed: true,
                        bubbleKey: Key('typed'),
                      )
                    else
                      Text(
                        long
                            ? List.filled(
                                300,
                                'Texto legível até o fim.',
                              ).join(' ')
                            : 'Fala curta.',
                        key: const Key('text'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('toque diretamente na fala digitada abre a folha', (
    tester,
  ) async {
    await pump(tester, teacher: true);
    final scroll = find.byKey(ViktorSheetKeys.scroll);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const Key('typed'))) + const Offset(12, 8),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(scroll).top, closeTo(30, 1));
    expect(find.byKey(ViktorSheetKeys.close).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folha recolhida acompanha o topo ao mudar a viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final states = <bool>[];
    await pump(tester, fixedPeek: true, onExpanded: states.add);
    for (final height in [800.0, 915.0, 640.0, 800.0]) {
      tester.view.physicalSize = Size(360, height);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(ViktorSheetKeys.scroll)).top,
        closeTo(height - 160, 1),
      );
      expect(find.byKey(ViktorSheetKeys.close).hitTestable(), findsNothing);
    }
    expect(states, isNot(contains(true)));
    expect(tester.takeException(), isNull);
  });

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'toque expande fala curta até 95%, X recolhe e informa ações; reduzido=$reducedMotion',
      (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final states = <bool>[];
        await pump(
          tester,
          onExpanded: states.add,
          reducedMotion: reducedMotion,
        );
        final scroll = find.byKey(ViktorSheetKeys.scroll);
        final collapsed = tester.getRect(scroll);
        expect(collapsed.bottom, 640);
        expect(collapsed.top, closeTo(448, 1));
        await tester.tap(find.text('Fala curta.'));
        await tester.pumpAndSettle();
        expect(tester.getRect(scroll).top, closeTo(32, 1));
        expect(states.last, isTrue);
        expect(find.byKey(ViktorSheetKeys.close).hitTestable(), findsOneWidget);
        await tester.tap(find.byKey(ViktorSheetKeys.close));
        await tester.pumpAndSettle();
        expect(tester.getRect(scroll), collapsed);
        expect(states.last, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'texto inteiro acessível; expansão e rolagem sobrevivem rotação e segundo plano',
    (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester, long: true);
      final scroll = find.byKey(ViktorSheetKeys.scroll);
      await tester.tapAt(tester.getTopLeft(scroll) + const Offset(40, 12));
      await tester.pumpAndSettle();
      await tester.drag(scroll, const Offset(0, -400));
      await tester.pumpAndSettle();
      final state = tester.state<ScrollableState>(
        find.descendant(of: scroll, matching: find.byType(Scrollable)),
      );
      final offset = state.position.pixels;
      expect(offset, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.view.physicalSize = const Size(800, 360);
      await tester.pumpAndSettle();
      expect(find.byKey(ViktorSheetKeys.close).hitTestable(), findsOneWidget);
      expect(state.position.pixels, closeTo(offset, 1));
      expect(tester.getRect(scroll).top, closeTo(18, 1));
      await tester.drag(scroll, const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(state.position.pixels, closeTo(state.position.maxScrollExtent, 1));
      expect(
        tester.getRect(find.byKey(const Key('text'))).bottom,
        lessThanOrEqualTo(tester.getRect(scroll).bottom),
      );
      await tester.tap(find.byKey(ViktorSheetKeys.close));
      await tester.pumpAndSettle();
      expect(state.position.pixels, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
