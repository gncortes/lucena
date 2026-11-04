import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/motion/lucena_motion.dart';
import 'package:lucena/ui/voice/widgets/voice_pickers.dart';

import '../../../testing/test_app.dart';

/// H-ANI-21 no tema do tour (PropV2TourBTema): o cartão escolhido se enche
/// de cor em 200 ms; com movimento reduzido, troca na hora.
void main() {
  const chave = Key('cartao');

  Future<void> montar(
    WidgetTester tester, {
    required bool selected,
    bool reduzir = false,
  }) => tester.pumpWidget(
    TestApp(
      locale: const Locale('pt'),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduzir),
          child: Center(
            child: SizedBox(
              width: 120,
              child: VoiceCard(
                key: chave,
                label: 'Claro',
                icon: Icons.light_mode,
                selected: selected,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Color fundo(WidgetTester tester) => tester
      .widget<Material>(
        find
            .descendant(of: find.byKey(chave), matching: find.byType(Material))
            .first,
      )
      .color!;

  testWidgets('escolher enche o fundo em 200 ms', (tester) async {
    await montar(tester, selected: false);
    final antes = fundo(tester);
    await montar(tester, selected: true);
    await tester.pump(const Duration(milliseconds: 100));
    final meio = fundo(tester);
    await tester.pump(LucenaMotion.selecao);
    final depois = fundo(tester);
    expect(depois, isNot(antes));
    expect(meio, isNot(antes));
    expect(meio, isNot(depois));
  });

  testWidgets('movimento reduzido: troca na hora', (tester) async {
    await montar(tester, selected: false, reduzir: true);
    await montar(tester, selected: true, reduzir: true);
    await tester.pump();
    final agora = fundo(tester);
    await tester.pumpAndSettle();
    expect(fundo(tester), agora);
  });
}
