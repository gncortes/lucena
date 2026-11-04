import 'package:chessground/chessground.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/board_settings.dart';
import 'package:lucena/ui/core/keys/motion_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/lesson_script/widgets/script_board.dart';

/// T85-D3 L3 (Escola) e T85-D1 L2 (lição): H-ANI-10, 11 e 33 no tabuleiro da
/// lição roteirizada, ligados em toda aula (Escola, finais e Pilares).
void main() {
  const fen = '4k3/8/8/8/8/8/4R3/4K3 w - - 0 1';

  Future<void> monte(
    WidgetTester tester, {
    required ScriptTone tone,
    bool reduzir = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduzir),
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ScriptBoard(
              state: LessonScriptState(
                ready: true,
                fen: fen,
                lastMove: 'e1e2',
                tone: tone,
              ),
              size: 320,
              settings: const BoardSettings(),
              vibrar: false,
              onMove: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('acerto: a casa pisca em verde e o selo aparece', (tester) async {
    await monte(tester, tone: ScriptTone.good);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(MotionKeys.corDaCasa), findsOneWidget);
    expect(find.byKey(MotionKeys.seloNaPeca), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('erro: o tabuleiro treme e o selo é o X', (tester) async {
    await monte(tester, tone: ScriptTone.bad);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(MotionKeys.tabuleiroDoRetorno), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('neutro: sem retorno', (tester) async {
    await monte(tester, tone: ScriptTone.neutral);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(MotionKeys.corDaCasa), findsNothing);
  });

  testWidgets('o deslize da peça usa os 300 ms do kit', (tester) async {
    await monte(tester, tone: ScriptTone.neutral);
    final tabuleiro = tester.widget<Chessboard>(find.byType(Chessboard));
    expect(tabuleiro.settings.animationDuration.inMilliseconds, 300);
  });

  testWidgets('movimento reduzido: o deslize some', (tester) async {
    await monte(tester, tone: ScriptTone.neutral, reduzir: true);
    final tabuleiro = tester.widget<Chessboard>(find.byType(Chessboard));
    expect(tabuleiro.settings.animationDuration, Duration.zero);
  });
}
