import 'package:animations/animations.dart';
import 'package:flutter/widgets.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O eixo X compartilhado dos passos em sequência (H-ANI-03): o passo novo
/// entra pela direita e o velho sai pela esquerda; com [voltar], ao
/// contrário. 300 ms: a saída some nos primeiros 90 ms
/// (`standardAccelerate`) e a entrada aparece nos 210 ms seguintes
/// (`emphasizedDecelerate`), deslizando 30 px.
///
/// Cada passo precisa de uma key própria no [child]. Com movimento reduzido,
/// fade de 100 ms sem deslocamento.
class TransicaoEixoX extends StatelessWidget {
  const TransicaoEixoX({required this.child, this.voltar = false, super.key});

  final Widget child;

  /// O passo anterior: o novo vem da esquerda.
  final bool voltar;

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    return PageTransitionSwitcher(
      duration: reduzido ? LucenaMotion.fadeReduzido : LucenaMotion.eixoX,
      reverse: voltar,
      layoutBuilder: _pilha,
      transitionBuilder: reduzido
          ? _fade
          : (filho, primaria, secundaria) => _Lado(
              animacao: primaria,
              lado: 1,
              child: _Lado(animacao: secundaria, lado: -1, child: filho),
            ),
      child: child,
    );
  }
}

Widget _pilha(List<Widget> filhos) =>
    Stack(alignment: Alignment.center, children: filhos);

Widget _fade(
  Widget filho,
  Animation<double> primaria,
  Animation<double> secundaria,
) => FadeTransition(
  opacity: primaria,
  child: FadeTransition(opacity: ReverseAnimation(secundaria), child: filho),
);

/// Um dos dois movimentos de um passo, pelo sentido da [animacao]:
/// - [lado] 1 (a primária): indo, entra da direita; voltando, sai por ela;
/// - [lado] -1 (a secundária): indo, sai pela esquerda; voltando, entra
///   por ela.
class _Lado extends StatelessWidget {
  const _Lado({
    required this.animacao,
    required this.lado,
    required this.child,
  });

  final Animation<double> animacao;
  final double lado;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animacao,
    builder: (context, filho) {
      final v = animacao.value;
      // A primária entra quando avança; a secundária, quando volta.
      final entrando = lado > 0
          ? animacao.status != AnimationStatus.reverse
          : animacao.status == AnimationStatus.reverse;
      // Fora do lugar: 0 no lugar, 1 a 30 px e invisível.
      final fora = lado > 0 ? 1 - v : v;
      final double opacidade;
      final double dx;
      if (entrando) {
        final t = 1 - fora;
        opacidade = _entra.transform(t);
        dx = LucenaMotion.deslocamentoDoEixo * (1 - _desliza.transform(t));
      } else {
        opacidade = 1 - _sai.transform(fora);
        dx = LucenaMotion.deslocamentoDoEixo * _desliza.transform(fora);
      }
      return Opacity(
        opacity: opacidade,
        child: Transform.translate(offset: Offset(lado * dx, 0), child: filho),
      );
    },
    child: child,
  );
}

const _entra = Interval(
  LucenaMotion.fracaoDaSaida,
  1,
  curve: LucenaMotion.emphasizedDecelerate,
);
const _sai = Interval(
  0,
  LucenaMotion.fracaoDaSaida,
  curve: LucenaMotion.standardAccelerate,
);
const _desliza = LucenaMotion.emphasized;
