import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A primeira carga da tela (H-ANI-07): o [esqueleto] (feito de
/// `SkeletonBlock`, que brilha em laço de 1100 ms) fica até [carregando]
/// virar falso; aí se dissolve em 250 ms, e o [child] sobe 8 px em 300 ms
/// (`emphasizedDecelerate`).
///
/// Se o conteúdo já está pronto no primeiro quadro, o esqueleto nem aparece.
/// Com movimento reduzido, o brilho fica parado e a troca é um fade de 100 ms,
/// sem subir.
class ShimmerConteudo extends StatefulWidget {
  const ShimmerConteudo({
    required this.carregando,
    required this.esqueleto,
    required this.child,
    this.trocaAnimada = true,
    super.key,
  });

  /// Falso: a troca é seca, sem dissolver nem subir. Para quem envolve a tela
  /// toda: a app bar e a barra de baixo não podem se mexer nem piscar, e o
  /// corpo faz a própria troca por dentro.
  final bool trocaAnimada;

  final bool carregando;
  final Widget esqueleto;
  final Widget child;

  @override
  State<ShimmerConteudo> createState() => _ShimmerConteudoState();
}

class _ShimmerConteudoState extends State<ShimmerConteudo>
    with SingleTickerProviderStateMixin {
  // Começa no fim: sem carregar, nada a trocar.
  late final AnimationController _troca = AnimationController(
    vsync: this,
    duration: LucenaMotion.sobeConteudo,
    value: 1,
  );

  @override
  void didUpdateWidget(ShimmerConteudo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carregando && !widget.carregando) {
      _troca.duration = MovimentoReduzido.of(context)
          ? LucenaMotion.fadeReduzido
          : LucenaMotion.sobeConteudo;
      _troca.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _troca.dispose();
    super.dispose();
  }

  Widget get _esqueleto => KeyedSubtree(
    key: MotionKeys.shimmerEsqueleto,
    child: ExcludeSemantics(child: widget.esqueleto),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.carregando) return _esqueleto;
    if (!widget.trocaAnimada) {
      return KeyedSubtree(key: MotionKeys.shimmerConteudo, child: widget.child);
    }
    final reduzido = MovimentoReduzido.of(context);
    // O dissolve dura 250 dos 300 ms da subida.
    final dissolve = reduzido
        ? LucenaMotion.linear
        : Interval(
            0,
            LucenaMotion.dissolveEsqueleto.inMicroseconds /
                LucenaMotion.sobeConteudo.inMicroseconds,
          );
    return AnimatedBuilder(
      animation: _troca,
      builder: (context, conteudo) {
        final t = _troca.value;
        final opacidade = dissolve.transform(t);
        final dy = reduzido
            ? 0.0
            : LucenaMotion.distanciaConteudo *
                  (1 - LucenaMotion.emphasizedDecelerate.transform(t));
        return Stack(
          children: [
            Opacity(
              opacity: opacidade,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: conteudo,
              ),
            ),
            if (t < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(opacity: 1 - opacidade, child: _esqueleto),
                ),
              ),
          ],
        );
      },
      child: KeyedSubtree(key: MotionKeys.shimmerConteudo, child: widget.child),
    );
  }
}

/// O brilho que atravessa um bloco do esqueleto, da esquerda para a direita.
/// [fase] vai de 0 a 1 a cada volta (`LucenaMotion.brilho`).
class BrilhoEsqueleto extends StatelessWidget {
  const BrilhoEsqueleto({
    required this.fase,
    required this.base,
    required this.brilho,
    required this.child,
    super.key,
  });

  final double fase;
  final Color base;
  final Color brilho;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = fase * 3 - 1;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) => LinearGradient(
        colors: [base, brilho, base],
        stops: [(t - 0.3).clamp(0, 1), t.clamp(0, 1), (t + 0.3).clamp(0, 1)],
      ).createShader(bounds),
      child: child,
    );
  }
}
