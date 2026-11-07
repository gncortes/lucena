import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'entradas_vistas.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// Uma faixa da [EntradaEmFaixas]: o [nome] vira a key
/// `MotionKeys.parteDoResultado(nome)`.
class FaixaDeEntrada {
  const FaixaDeEntrada(this.nome, this.child, {this.conta = false});

  final String nome;
  final Widget child;

  /// Há números dentro que contam enquanto a faixa entra (o rating).
  final bool conta;
}

Widget _coluna(List<Widget> faixas) =>
    Column(mainAxisSize: MainAxisSize.min, children: faixas);

/// O resultado em faixas escalonadas (T85, S3b): cada faixa entra com fade e
/// sobe 14 px em 280 ms, 100 ms depois da anterior, na ordem da lista. Os
/// números dentro de uma faixa com [FaixaDeEntrada.conta] contam do valor
/// anterior ao novo. Tudo fica liberado ao toque desde o começo; o conjunto
/// dura cerca de 1 s.
///
/// Anima só na primeira entrada do resultado ([id] novo na sessão); com
/// movimento reduzido, ou reaberto, tudo aparece pronto no primeiro quadro.
class EntradaEmFaixas extends StatelessWidget {
  const EntradaEmFaixas({
    required this.id,
    required this.faixas,
    this.montar = _coluna,
    super.key,
  });

  final String id;
  final List<FaixaDeEntrada> faixas;

  /// Arruma as faixas já animadas (padrão: coluna).
  final Widget Function(List<Widget> faixas) montar;

  /// O fim da última faixa (ou da contagem, se ela terminar depois).
  static Duration total(List<FaixaDeEntrada> faixas) {
    var fim = Duration.zero;
    for (final (i, faixa) in faixas.indexed) {
      final inicio = LucenaMotion.intervaloDasFaixas * i;
      final entra = inicio + LucenaMotion.faixaEntra;
      final conta = inicio + LucenaMotion.contagemDaFaixa;
      for (final d in [entra, if (faixa.conta) conta]) {
        if (d > fim) fim = d;
      }
    }
    return fim;
  }

  @override
  Widget build(BuildContext context) => EntradaDaTela(
    id: 'resultado-$id',
    child: RelogioDeEntrada(
      total: total(faixas),
      child: montar([
        for (final (i, faixa) in faixas.indexed)
          EntradaNoTempo(
            key: MotionKeys.parteDoResultado(faixa.nome),
            inicio: LucenaMotion.intervaloDasFaixas * i,
            duracao: LucenaMotion.faixaEntra,
            subida: LucenaMotion.subidaDaFaixa,
            duracaoDaContagem: faixa.conta
                ? LucenaMotion.contagemDaFaixa
                : null,
            child: faixa.child,
          ),
      ]),
    ),
  );
}
