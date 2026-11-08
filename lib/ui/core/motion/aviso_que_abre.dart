import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'relogio_de_entrada.dart';

/// O aviso de falha, cancelamento ou sem internet (H-ANI-27, clipe 10): a
/// altura vai de 0 à cheia em 320 ms (DEC), empurrando o conteúdo abaixo, e
/// depois o [icone] pulsa uma vez a 1,3 em 400 ms.
///
/// Anima sempre que aparece. Com movimento reduzido, aberto e sem pulso. A
/// [decoracao] (fundo, contorno) é da tela.
class AvisoQueAbre extends StatelessWidget {
  const AvisoQueAbre({
    required this.icone,
    required this.child,
    this.decoracao,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final Widget icone;
  final Widget child;
  final Decoration? decoracao;
  final EdgeInsetsGeometry padding;

  static final _pulso = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: LucenaMotion.escalaDoPulso,
      ).chain(CurveTween(curve: LucenaMotion.emphasizedDecelerate)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: LucenaMotion.escalaDoPulso,
        end: 1.0,
      ).chain(CurveTween(curve: LucenaMotion.emphasized)),
      weight: 50,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final conteudo = Container(
      decoration: decoracao,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoTempo(
            inicio: LucenaMotion.avisoAbre,
            duracao: LucenaMotion.pulsoDoAviso,
            curva: LucenaMotion.linear,
            builder: (context, v, filho) => Transform.scale(
              key: MotionKeys.iconeDoAviso,
              scale: _pulso.transform(v),
              child: filho,
            ),
            child: icone,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
    return RelogioDeEntrada(
      total: LucenaMotion.avisoAbre + LucenaMotion.pulsoDoAviso,
      animar: true,
      child: NoTempo(
        inicio: Duration.zero,
        duracao: LucenaMotion.avisoAbre,
        child: conteudo,
        builder: (context, v, filho) => ClipRect(
          key: MotionKeys.avisoQueAbre,
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: v,
            child: filho,
          ),
        ),
      ),
    );
  }
}
