import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'entradas_vistas.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

Widget _coluna(List<Widget> itens) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: itens,
);

/// O conteúdo do painel de filtro da app bar (H-ANI-23), dentro da folha
/// aberta com `showLucenaSheet(filtro: true)`: as opções entram em ordem
/// 120 ms depois de a folha começar a subir, com 40 ms entre elas (fade e
/// 10 px em 300 ms, `emphasizedDecelerate`).
///
/// Só na primeira abertura do filtro [id] na sessão; depois, as opções já
/// vêm prontas. Com movimento reduzido, tudo no lugar.
class OpcoesDoFiltro extends StatelessWidget {
  const OpcoesDoFiltro({
    required this.id,
    required this.itens,
    this.montar = _coluna,
    super.key,
  });

  /// O filtro (uma tela pode ter mais de um).
  final String id;

  /// As opções, de cima para baixo (grupos de chips, títulos, botões).
  final List<Widget> itens;

  /// Arruma as opções já animadas (coluna, `Wrap`...).
  final Widget Function(List<Widget> itens) montar;

  static Duration inicio(int i) =>
      LucenaMotion.atrasoDoFiltro + LucenaMotion.intervaloDoFiltro * i;

  @override
  Widget build(BuildContext context) {
    final ultimo = itens.isEmpty ? 0 : itens.length - 1;
    return EntradaDaTela(
      id: 'filtro.$id',
      child: RelogioDeEntrada(
        total: inicio(ultimo) + LucenaMotion.itemDaLista,
        esperarATransicao: false,
        child: montar([
          for (var i = 0; i < itens.length; i++)
            EntradaNoTempo(
              key: MotionKeys.itemDoFiltro(i),
              inicio: inicio(i),
              duracao: LucenaMotion.itemDaLista,
              subida: LucenaMotion.subidaDoTexto,
              child: itens[i],
            ),
        ]),
      ),
    );
  }
}
