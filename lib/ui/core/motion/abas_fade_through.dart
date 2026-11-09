import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A troca de aba (H-ANI-05): o corpo velho some em 30% do tempo
/// (`standardAccelerate`) e o novo aparece crescendo de 0,92 a 1
/// (`emphasizedDecelerate`). 300 ms nas abas de baixo e no "já tem"; 450 ms
/// nas abas internas da venda ([venda]), junto com o
/// [IndicadorQueDesliza].
///
/// Vai só no corpo: a `NavigationBar` e o botão fixo ficam fora e não se
/// mexem. Cada aba precisa de uma key própria no [child]. Com movimento
/// reduzido, fade de 100 ms sem escala.
class AbasFadeThrough extends StatelessWidget {
  const AbasFadeThrough({required this.child, this.venda = false, super.key});

  final Widget child;

  /// As abas internas da venda: 450 ms.
  final bool venda;

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    return KeyedSubtree(
      key: MotionKeys.corpoDasAbas,
      child: PageTransitionSwitcher(
        duration: reduzido
            ? LucenaMotion.fadeReduzido
            : venda
            ? LucenaMotion.abasDaVenda
            : LucenaMotion.abas,
        layoutBuilder: (filhos) =>
            Stack(alignment: Alignment.topCenter, children: filhos),
        transitionBuilder: (filho, primaria, secundaria) => reduzido
            ? FadeTransition(
                opacity: primaria,
                child: FadeTransition(
                  opacity: ReverseAnimation(secundaria),
                  child: filho,
                ),
              )
            : _Cruzamento(entrada: primaria, saida: secundaria, child: filho),
        child: child,
      ),
    );
  }
}

class _Cruzamento extends StatelessWidget {
  const _Cruzamento({
    required this.entrada,
    required this.saida,
    required this.child,
  });

  final Animation<double> entrada;
  final Animation<double> saida;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([entrada, saida]),
    builder: (context, filho) {
      final t = _aparece.transform(entrada.value);
      final some = _some.transform(saida.value);
      return Opacity(
        opacity: t * (1 - some),
        child: Transform.scale(
          scale: LucenaMotion.escalaDaAba + (1 - LucenaMotion.escalaDaAba) * t,
          child: filho,
        ),
      );
    },
    child: child,
  );
}

const _aparece = Interval(
  LucenaMotion.fracaoDaSaida,
  1,
  curve: LucenaMotion.emphasizedDecelerate,
);
const _some = Interval(
  0,
  LucenaMotion.fracaoDaSaida,
  curve: LucenaMotion.standardAccelerate,
);

/// A barra sob a aba escolhida das abas internas da venda (H-ANI-05): desliza
/// de uma aba à outra em 450 ms (`emphasized`), junto com o
/// [AbasFadeThrough]. Ocupa a largura toda, dividida em [abas] partes. Com
/// movimento reduzido, pula direto.
class IndicadorQueDesliza extends StatelessWidget {
  const IndicadorQueDesliza({
    required this.abas,
    required this.atual,
    this.espessura = 3,
    this.cor,
    super.key,
  });

  final int abas;
  final int atual;
  final double espessura;

  /// Nulo: a cor primária do tema.
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    final cor = this.cor ?? Theme.of(context).colorScheme.primary;
    return LayoutBuilder(
      builder: (context, limites) {
        final largura = limites.maxWidth / abas;
        return Stack(
          children: [
            AnimatedPositioned(
              key: MotionKeys.indicadorDaAba,
              duration: reduzido ? Duration.zero : LucenaMotion.abasDaVenda,
              curve: LucenaMotion.emphasized,
              left: largura * atual,
              width: largura,
              bottom: 0,
              height: espessura,
              child: ColoredBox(color: cor),
            ),
          ],
        );
      },
    );
  }
}
