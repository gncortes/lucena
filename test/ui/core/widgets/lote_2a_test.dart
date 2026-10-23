import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/achievements/widgets/achievement_medal.dart';
import 'package:lucena/ui/core/widgets/choice_sheet.dart';
import 'package:lucena/ui/core/widgets/skeleton.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../../testing/test_app.dart';

/// E1.08, lote 2a: rodapé, folha, medalha e avatar no padrão.
void main() {
  testWidgets('folha de escolha: cabeçalho padrão e botão de 52 a 24', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showChoiceSheet<int>(
                context,
                title: 'Escolha',
                options: const [
                  ChoiceSheetOption(value: 1, label: 'Um', key: Key('o1')),
                ],
                selected: 1,
                confirmLabel: 'Confirmar',
                confirmKey: const Key('ok'),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(SheetKeys.header), findsOneWidget);
    expect(find.byKey(SheetKeys.title), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('ok'))).height, 52);
    final sheet = tester.getRect(find.byKey(SheetKeys.surface));
    final button = tester.getRect(find.byKey(const Key('ok')));
    expect(button.left - sheet.left, 24);
    expect(sheet.right - button.right, 24);
    expect(find.byKey(CoreKeys.actionsFooter), findsOneWidget);
  });

  testWidgets('medalha obtida: disco de ouro liso, sem degradê', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(
        child: Scaffold(
          body: AchievementMedal(icon: Icons.star, unlocked: true, size: 80),
        ),
      ),
    );
    final decorated = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>();
    expect(decorated.any((d) => d.color == AppColors.goldColor), isTrue);
    expect(decorated.any((d) => d.gradient is LinearGradient), isFalse);
  });

  testWidgets('o verde do recorde é um token', (tester) async {
    expect(AppColors.record, const Color(0xff2e6b3a));
  });

  testWidgets('carregando: o esqueleto no lugar do círculo', (tester) async {
    await tester.pumpWidget(
      const TestApp(child: Scaffold(body: SkeletonList())),
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
