import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/treinador/treinador.dart';
import 'package:lucena/ui/treinador/widgets/linha_partida.dart';

import '../../../testing/test_app.dart';
import 'treinador_harness.dart';

PartidaTreinador _longa({StatusPartida status = StatusPartida.nova}) =>
    PartidaTreinador(
      id: 'lichess_Longa001',
      jogadaEm: DateTime.utc(2026, 11, 9, 9),
      ritmo: Ritmo.rapida,
      cadencia: '15+10',
      cor: CorPartida.pretas,
      adversario: const Adversario(nome: 'JogadorDeNomeLongo_25', rating: 1612),
      resultado: Resultado.derrota,
      abertura: const AberturaPartida(
        eco: 'B99',
        nome: 'Defesa Siciliana: Variante Najdorf, Ataque Inglês',
      ),
      status: status,
    );

/// Todo texto da linha, com o que o layout fez dele.
Iterable<RenderParagraph> _paragrafos(WidgetTester tester) => tester
    .renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(LinhaPartida),
        matching: find.byType(RichText),
      ),
    )
    .where((p) => p.text.toPlainText().trim().isNotEmpty);

void main() {
  Future<void> montar(WidgetTester tester, PartidaTreinador p) async {
    aparelho411x914(tester);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: LinhaPartida(partida: p, agora: agoraDeTeste(), acesso: true),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('abertura curta fica na mesma linha, como no canvas', (
    tester,
  ) async {
    final curta = PartidaTreinador(
      id: 'lichess_Curta001',
      jogadaEm: DateTime.utc(2026, 11, 9, 9),
      ritmo: Ritmo.blitz,
      cadencia: '5+0',
      cor: CorPartida.pretas,
      adversario: const Adversario(nome: 'Tiago_Rook', rating: 1612),
      resultado: Resultado.derrota,
      abertura: const AberturaPartida(eco: 'B12', nome: 'Caro-Kann'),
    );
    // A fonte dos testes é mais larga que a Roboto: tela larga para a linha
    // caber inteira.
    await montar(tester, curta);
    tester.view.physicalSize = const Size(900, 914);
    await tester.pump();
    final textos = [for (final p in _paragrafos(tester)) p.text.toPlainText()];
    expect(textos, contains('5+0 Blitz · Pretas · Caro-Kann · Hoje'));
  });

  // Cobertura 5 do QA: nada de reticências com dado real longo a 411x914.
  for (final status in [StatusPartida.nova, StatusPartida.pronta]) {
    testWidgets('nome de 25 caracteres e abertura longa não cortam '
        '($status)', (tester) async {
      await montar(tester, _longa(status: status));

      expect(find.text('JogadorDeNomeLongo_25 (1612)'), findsOneWidget);
      // Com a abertura longa, ela abre a linha de baixo (ordem estável:
      // ritmo, cor, abertura, quando).
      final textos = [
        for (final p in _paragrafos(tester)) p.text.toPlainText(),
      ];
      expect(textos, contains('15+10 Rápido · Pretas'));
      expect(
        textos,
        contains('Defesa Siciliana: Variante Najdorf, Ataque Inglês · Hoje'),
      );
      for (final p in _paragrafos(tester)) {
        // Nenhum texto passa do máximo de linhas (nada é cortado).
        expect(
          p.didExceedMaxLines,
          isFalse,
          reason: 'cortou: ${p.text.toPlainText()}',
        );
        expect(
          p.maxLines,
          anyOf(
            isNull,
            LinhaPartida.detalheMaxLinhas,
            LinhaPartida.detalheMaxLinhas + 1,
          ),
        );
        expect(p.text.toPlainText(), isNot(contains('…')));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sem seta e sem estado: só nome e detalhe', (tester) async {
    aparelho411x914(tester);
    await tester.pumpWidget(
      TestApp(
        locale: const Locale('pt'),
        child: Scaffold(
          body: LinhaPartida(
            partida: _longa(status: StatusPartida.nova),
            agora: agoraDeTeste(),
            acesso: true,
            mostrarSeta: false,
            mostrarEstado: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.chevron_right), findsNothing);
    final textos = [for (final p in _paragrafos(tester)) p.text.toPlainText()];
    // A letra do resultado, o nome e as duas linhas do detalhe.
    expect(textos, hasLength(4));
  });
}
