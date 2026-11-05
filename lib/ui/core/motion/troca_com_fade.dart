import 'package:flutter/widgets.dart';

import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A troca de exercício (H-ANI-03, regra de 04/11): quando a [chave] muda (o
/// id do exercício), o exercício velho e o novo se cruzam em fade de 300 ms,
/// empilhados no mesmo lugar. O tabuleiro não se move e as peças não deslizam:
/// a posição nova entra pronta, no lugar do `updatePosition` animado. A fala
/// e o enunciado vão dentro do [child] e trocam juntos.
///
/// Com a mesma chave, o filho novo só substitui o velho, sem fade. Com
/// movimento reduzido, fade de 100 ms. É também a troca das perguntas do teste
/// de nível (B7).
class TrocaComFade extends StatelessWidget {
  const TrocaComFade({required this.chave, required this.child, super.key});

  /// O que identifica o exercício; trocar a chave dispara o fade.
  final Object chave;

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MovimentoReduzido.of(context)
        ? LucenaMotion.fadeReduzido
        : LucenaMotion.trocaComFade,
    switchInCurve: LucenaMotion.emphasizedDecelerate,
    switchOutCurve: LucenaMotion.emphasizedAccelerate,
    transitionBuilder: (filho, animacao) =>
        FadeTransition(opacity: animacao, child: filho),
    // Sem recorte: o selo da fileira de cima sai por cima do tabuleiro.
    layoutBuilder: (atual, anteriores) => Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [...anteriores, ?atual],
    ),
    child: KeyedSubtree(key: ValueKey(chave), child: child),
  );
}
