import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/viktor_sheet_keys.dart';
import 'package:lucena/ui/core/widgets/character_avatar.dart';
import 'package:lucena/ui/core/widgets/viktor_sheet.dart';
import 'package:lucena/ui/core/widgets/teacher_speech.dart';
import 'package:lucena_ui/lucena_ui.dart';

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
    expect(tester.getRect(scroll).top, closeTo(76, 1)); // §5: X inteiro
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
      'toque expande fala curta até 76 dp do topo, X recolhe e informa ações; reduzido=$reducedMotion',
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
        expect(tester.getRect(scroll).top, closeTo(76, 1));
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
      expect(tester.getRect(scroll).top, closeTo(76, 1));
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

  for (final size in [const Size(360, 640), const Size(412, 917)]) {
    testWidgets(
      'aberta: folha a 76 dp do topo, X inteiro e alça 32x4 em ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pump(tester, teacher: true);
        await tester.tapAt(
          tester.getTopLeft(find.byKey(const Key('typed'))) +
              const Offset(12, 8),
        );
        await tester.pumpAndSettle();
        final sheet = tester.getRect(find.byKey(ViktorSheetKeys.scroll));
        expect(sheet.top, greaterThanOrEqualTo(76 - 1));
        final close = tester.getRect(find.byKey(ViktorSheetKeys.close));
        expect(close.top, greaterThanOrEqualTo(8 - 1));
        expect(close.size, const Size(48, 48));
        expect(sheet.top - close.bottom, closeTo(20, 1));
        final handle = tester.getRect(find.byKey(ViktorSheetKeys.handle));
        expect(handle.size, const Size(32, 4));
        expect(handle.top - sheet.top, closeTo(8, 1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a barra de rolagem é fina e não ocupa largura do texto', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, long: true);
    final bar = tester.widget<RawScrollbar>(
      find.byKey(ViktorSheetKeys.scrollbar),
    );
    final colors = Theme.of(tester.element(find.byKey(ViktorSheetKeys.sheet)))
        .colorScheme;
    expect(bar.thickness, 4);
    expect(bar.radius, const Radius.circular(AppShape.hairline));
    expect(bar.thumbColor, colors.outlineVariant);
    expect(bar.crossAxisMargin, 6);
    // O texto ocupa a largura toda da folha.
    expect(
      tester.getSize(find.byKey(const Key('text'))).width,
      tester.getSize(find.byKey(ViktorSheetKeys.scroll)).width,
    );
  });

  testWidgets('collapse baixa a folha aberta até a borda do tabuleiro', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, teacher: true);
    final scroll = find.byKey(ViktorSheetKeys.scroll);
    final collapsed = tester.getRect(scroll);
    await tester.tapAt(
      tester.getTopLeft(find.byKey(const Key('typed'))) + const Offset(12, 8),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(scroll).top, lessThan(collapsed.top));
    ViktorSheet.collapse(tester.element(find.byKey(const Key('typed'))));
    await tester.pumpAndSettle();
    expect(tester.getRect(scroll), collapsed);
  });

  testWidgets('cabeçalho do Viktor: linha de 48 dp com retrato de 28 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: LayoutBuilder(
            builder: (context, box) => ViktorSheet(
              top: box.maxHeight * .6,
              children: const [
                TeacherSpeech(
                  teacher: FakeCharacterRepository.viktor,
                  text: 'Fala.',
                  speechContext: SpeechContext.teaching,
                  lessonV2: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final header = tester.getRect(find.byKey(ViktorSheetKeys.header));
    expect(header.height, 48);
    expect(tester.getSize(find.byType(CharacterAvatar)), const Size(28, 28));
  });

  testWidgets('recolhida: abaixo do corte entre linhas nada da linha seguinte '
      'aparece (nem o topo das letras)', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      TestApp(
        child: RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: LayoutBuilder(
              builder: (context, box) => ViktorSheet(
                // 4 linhas de 24 dp e meia: a 4ª cruza o fim recolhido.
                top: box.maxHeight - 100,
                children: [
                  Text(
                    List.filled(80, 'Éllh').join(' '),
                    key: const Key('text'),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(const Key('text')),
    );
    final origin = paragraph.localToGlobal(Offset.zero).dy;
    final lines = paragraph.getBoxesForSelection(
      TextSelection(
        baseOffset: 0,
        extentOffset: paragraph.text.toPlainText().length,
      ),
    );
    // A 1ª linha que não cabe inteira acima do fim (640 - 4).
    final crossing = lines.firstWhere((b) => origin + b.bottom > 640 - 4);
    final cut = (origin + crossing.top).floor();
    final image = (await tester.runAsync(() async {
      final object =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return object.toImage();
    }))!;
    final bytes = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    int pixel(int x, int y) {
      final o = (y * image.width + x) * 4;
      return bytes.getUint32(o);
    }

    final background = pixel(8, 639);
    var stray = 0;
    for (var y = cut; y < 640; y++) {
      for (var x = 16; x < 340; x++) {
        if (pixel(x, y) != background) {
          stray++;
        }
      }
    }
    expect(stray, 0, reason: 'pixels de texto abaixo do corte em y=$cut');
  });
}
