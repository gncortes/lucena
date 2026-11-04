import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'valor_que_anima.dart';

/// O número que conta até o valor (H-ANI-18): 650 ms `emphasized`, junto com a
/// barra ao lado. Numa mudança real, conta do valor anterior. Formato do
/// idioma do app (pt-BR: 1.267) e algarismos de largura fixa; a largura é a do
/// valor final desde o primeiro quadro, para nada em volta pular. O leitor de
/// tela lê só o valor final.
class NumeroQueConta extends StatelessWidget {
  const NumeroQueConta({
    required this.valor,
    this.estilo,
    this.sufixo = '',
    this.alinhamento = AlignmentDirectional.center,
    super.key,
  });

  final int valor;
  final TextStyle? estilo;

  /// Texto colado depois do número ("%", " pts"), já traduzido pela tela.
  final String sufixo;
  final AlignmentGeometry alinhamento;

  @override
  Widget build(BuildContext context) {
    final local = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final formato = NumberFormat.decimalPattern(local ?? 'pt_BR');
    final estilo = (DefaultTextStyle.of(context).style.merge(this.estilo))
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final fim = '${formato.format(valor)}$sufixo';
    return Semantics(
      key: MotionKeys.numeroQueConta,
      label: fim,
      child: ExcludeSemantics(
        child: Stack(
          alignment: alinhamento,
          children: [
            // Invisível e fora do find.text: só guarda a largura do fim.
            RichText(
              text: TextSpan(
                text: fim,
                style: estilo.copyWith(color: Colors.transparent),
              ),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            ),
            ValorQueAnima(
              valor: valor.toDouble(),
              duracao: LucenaMotion.numeroConta,
              builder: (context, agora) => Text(
                '${formato.format(agora.round())}$sufixo',
                style: estilo,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
