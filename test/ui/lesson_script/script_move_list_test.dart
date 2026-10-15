import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/keys/lesson_script_keys.dart';
import 'package:lucena/ui/lesson_script/view_models/lesson_script_state.dart';
import 'package:lucena/ui/lesson_script/widgets/script_move_list.dart';

import '../../../testing/test_app.dart';

void main() {
  ScriptMoveEntry move(String id, String san, int number, Side side) =>
      ScriptMoveEntry(
        id: id,
        san: san,
        number: number,
        side: side,
        variant: false,
      );

  testWidgets('em PT, a lista e o leitor de tela usam as letras do idioma '
      '(Dh4#, não Qh4#)', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: ScriptMoveList(
            moves: [
              move('a', 'f3', 1, Side.white),
              move('b', 'e5', 1, Side.black),
              move('c', 'g4', 2, Side.white),
              move('d', 'Qh4#', 2, Side.black),
            ],
            currentId: 'd',
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dh4#'), findsOneWidget);
    expect(find.text('Qh4#'), findsNothing);
    expect(
      tester.getSemantics(find.byKey(LessonScriptKeys.move('d'))).label,
      'Dh4#',
    );
    semantics.dispose();
  });
}
