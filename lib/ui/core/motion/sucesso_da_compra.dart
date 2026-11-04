import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// A compra concluída (H-ANI-27, clipe 09): o círculo com ✓ escala de 0,6 a
/// 1 em 380 ms (DEC) e o ✓ salta (0 → 1,18 → 1); um anel vai a 1,7 e some em
/// 700 ms, uma vez; o [titulo] e o [texto] sobem 14 px em 300 ms e os
/// [botoes] entram por último, 100 ms entre eles.
///
/// Anima sempre que aparece. Com movimento reduzido, pronto e sem anel.
class SucessoDaCompra extends StatelessWidget {
  const SucessoDaCompra({
    required this.titulo,
    required this.texto,
    required this.botoes,
    this.tamanho = 88,
    super.key,
  });

  final Widget titulo;
  final Widget texto;
  final List<Widget> botoes;

  /// O diâmetro do círculo.
  final double tamanho;

  static Duration _inicioDoBotao(int i) =>
      LucenaMotion.botoesDaCompra + LucenaMotion.intervaloDosBotoes * i;

  static final _check = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: LucenaMotion.picoDoCheck,
      ).chain(CurveTween(curve: LucenaMotion.emphasizedDecelerate)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: LucenaMotion.picoDoCheck,
        end: 1.0,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 40,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final ultimo = botoes.isEmpty
        ? LucenaMotion.textoDaCompra + LucenaMotion.sobeDaCompra
        : _inicioDoBotao(botoes.length - 1) + LucenaMotion.sobeDaCompra;
    final total = ultimo > LucenaMotion.anelDaCompra
        ? ultimo
        : LucenaMotion.anelDaCompra;
    return RelogioDeEntrada(
      total: total,
      animar: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox.square(
            dimension: tamanho * LucenaMotion.escalaDoAnel,
            child: Stack(
              alignment: Alignment.center,
              children: [
                NoTempo(
                  inicio: Duration.zero,
                  duracao: LucenaMotion.anelDaCompra,
                  curva: LucenaMotion.linear,
                  builder: (context, v, _) => v >= 1
                      ? const SizedBox.shrink()
                      : Opacity(
                          key: MotionKeys.anelDaCompra,
                          opacity: 1 - v,
                          child: Transform.scale(
                            scale:
                                1 +
                                (LucenaMotion.escalaDoAnel - 1) *
                                    LucenaMotion.emphasizedDecelerate.transform(
                                      v,
                                    ),
                            child: Container(
                              width: tamanho,
                              height: tamanho,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: cores.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                NoTempo(
                  inicio: Duration.zero,
                  duracao: LucenaMotion.circuloDaCompra,
                  builder: (context, v, filho) => Transform.scale(
                    key: MotionKeys.circuloDaCompra,
                    scale:
                        LucenaMotion.escalaDoCirculo +
                        (1 - LucenaMotion.escalaDoCirculo) * v,
                    child: filho,
                  ),
                  child: Container(
                    width: tamanho,
                    height: tamanho,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cores.primary,
                    ),
                    alignment: Alignment.center,
                    child: NoTempo(
                      inicio: Duration.zero,
                      duracao: LucenaMotion.circuloDaCompra,
                      curva: LucenaMotion.linear,
                      builder: (context, v, filho) => Transform.scale(
                        key: MotionKeys.checkDaCompra,
                        scale: _check.transform(v),
                        child: filho,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: cores.onPrimary,
                        size: tamanho * .5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          EntradaNoTempo(
            inicio: LucenaMotion.tituloDaCompra,
            duracao: LucenaMotion.sobeDaCompra,
            subida: LucenaMotion.subidaDoTitulo,
            child: titulo,
          ),
          const SizedBox(height: AppSpacing.sm),
          EntradaNoTempo(
            inicio: LucenaMotion.textoDaCompra,
            duracao: LucenaMotion.sobeDaCompra,
            subida: LucenaMotion.subidaDoTitulo,
            child: texto,
          ),
          for (final (i, botao) in botoes.indexed) ...[
            SizedBox(height: i == 0 ? AppSpacing.xl : AppSpacing.sm),
            EntradaNoTempo(
              inicio: _inicioDoBotao(i),
              duracao: LucenaMotion.sobeDaCompra,
              subida: LucenaMotion.subidaDoTexto,
              child: botao,
            ),
          ],
        ],
      ),
    );
  }
}
