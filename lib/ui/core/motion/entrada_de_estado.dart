import 'package:flutter/widgets.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// O estado vazio e o de erro aparecem com calma (H-ANI-24): o ícone escala
/// de 0,8 a 1 com fade em 400 ms; 120 ms depois, o texto sobe 8 px; a ação
/// (o `BotaoCarregando` do "Tentar novamente") vem logo atrás. Curva
/// `emphasizedDecelerate`.
///
/// Só na primeira entrada da tela; o botão carregando anima sempre. Com
/// movimento reduzido, tudo pronto.
class EntradaDeEstado extends StatelessWidget {
  const EntradaDeEstado({
    required this.icone,
    required this.texto,
    this.acao,
    this.espaco = 16,
    this.animar,
    super.key,
  });

  final Widget icone;

  /// O texto (ou a coluna de título e texto) do estado.
  final Widget texto;
  final Widget? acao;

  /// O espaço entre as partes.
  final double espaco;

  /// Nulo: só na primeira entrada da tela.
  final bool? animar;

  static final _inicioDaAcao =
      LucenaMotion.atrasoDoTextoDoEstado + LucenaMotion.intervaloDaCascata;

  @override
  Widget build(BuildContext context) {
    final acao = this.acao;
    return RelogioDeEntrada(
      total: acao == null
          ? LucenaMotion.atrasoDoTextoDoEstado + LucenaMotion.textoEntra
          : _inicioDaAcao + LucenaMotion.textoEntra,
      animar: animar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EntradaNoTempo(
            key: MotionKeys.iconeDoEstado,
            inicio: Duration.zero,
            duracao: LucenaMotion.iconeDoEstado,
            escalaDe: LucenaMotion.escalaDoIcone,
            child: icone,
          ),
          SizedBox(height: espaco),
          EntradaNoTempo(
            key: MotionKeys.textoDoEstado,
            inicio: LucenaMotion.atrasoDoTextoDoEstado,
            duracao: LucenaMotion.textoEntra,
            subida: LucenaMotion.subidaDoEstado,
            child: texto,
          ),
          if (acao != null) ...[
            SizedBox(height: espaco),
            EntradaNoTempo(
              key: MotionKeys.acaoDoEstado,
              inicio: _inicioDaAcao,
              duracao: LucenaMotion.textoEntra,
              subida: LucenaMotion.subidaDoEstado,
              child: acao,
            ),
          ],
        ],
      ),
    );
  }
}
