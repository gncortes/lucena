import 'package:flutter/widgets.dart';

import '../theme/app_motion.dart';

/// Que parte da partida entra: cada uma com o seu tempo e o seu movimento.
enum GameEntrancePart {
  /// A barra do adversário (acima do tabuleiro): desce do alto.
  top,

  /// A barra do jogador (abaixo do tabuleiro): sobe de baixo.
  bottom,

  /// O relógio de cada barra: um pequeno pop, logo depois da barra.
  clock,

  /// O balão de fala do personagem: aparece com um deslize curto.
  speech,
}

/// A entrada das peças em volta do tabuleiro no começo da partida, enquanto
/// o tabuleiro termina o voo ([GameBoardHero]): as barras dos jogadores
/// deslizam para o lugar, escalonadas, e os relógios dão um pop.
///
/// Tudo segue a animação da própria rota (sem controller): com a rota já de
/// pé (de volta do segundo plano, numa reconstrução ou aberta sem
/// transição), na saída ou com "remover animações", fica tudo parado no
/// lugar. A árvore é a mesma em todos os quadros, para não perder o estado
/// de quem está dentro.
class GameEntrance extends StatelessWidget {
  const GameEntrance({required this.part, required this.child, super.key});

  final GameEntrancePart part;
  final Widget child;

  /// O trecho da entrada da rota ([AppMotion.screen]) de cada parte: as
  /// barras começam enquanto o tabuleiro ainda voa; o relógio e o balão,
  /// logo depois da sua barra.
  static const topInterval = Interval(0.2, 0.75, curve: AppMotion.enter);
  static const bottomInterval = Interval(0.3, 0.85, curve: AppMotion.enter);
  static const clockFade = Interval(0.55, 0.8, curve: AppMotion.enter);
  static const clockPop = Interval(0.55, 1, curve: AppMotion.pop);
  static const speechInterval = Interval(0.6, 1, curve: AppMotion.enter);

  /// De onde cada parte parte, em frações do próprio tamanho.
  static const topFrom = Offset(0, -0.5);
  static const bottomFrom = Offset(0, 0.5);
  static const speechFrom = Offset(0, 0.15);

  /// A escala de onde o relógio cresce até o tamanho dele.
  static const clockFrom = 0.85;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.animation;
    if (route == null || AppMotion.of(context).disabled) {
      return _Still(part: part, child: child);
    }
    return AnimatedBuilder(
      animation: route,
      child: child,
      builder: (context, child) {
        // Na saída da tela (a rota volta), as partes não refazem o caminho.
        final t = route.status == AnimationStatus.reverse ? 1.0 : route.value;
        return switch (part) {
          GameEntrancePart.top => _Slide(
            t: t,
            interval: topInterval,
            from: topFrom,
            child: child!,
          ),
          GameEntrancePart.bottom => _Slide(
            t: t,
            interval: bottomInterval,
            from: bottomFrom,
            child: child!,
          ),
          GameEntrancePart.speech => _Slide(
            t: t,
            interval: speechInterval,
            from: speechFrom,
            child: child!,
          ),
          GameEntrancePart.clock => _Pop(t: t, child: child!),
        };
      },
    );
  }
}

/// Uma barra (ou o balão) no ponto [t] da entrada: aparece e desliza de
/// [from] até o lugar.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.t,
    required this.interval,
    required this.from,
    required this.child,
  });

  final double t;
  final Curve interval;
  final Offset from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final v = interval.transform(t);
    return Opacity(
      opacity: v,
      child: FractionalTranslation(
        translation: Offset.lerp(from, Offset.zero, v)!,
        child: child,
      ),
    );
  }
}

/// O relógio no ponto [t] da entrada: aparece e cresce até o tamanho dele.
class _Pop extends StatelessWidget {
  const _Pop({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: GameEntrance.clockFade.transform(t),
    child: Transform.scale(
      scale:
          GameEntrance.clockFrom +
          (1 - GameEntrance.clockFrom) * GameEntrance.clockPop.transform(t),
      child: child,
    ),
  );
}

/// Parado no lugar, com a mesma árvore dos quadros da entrada.
class _Still extends StatelessWidget {
  const _Still({required this.part, required this.child});

  final GameEntrancePart part;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return part == GameEntrancePart.clock
        ? _Pop(t: 1, child: child)
        : _Slide(
            t: 1,
            interval: GameEntrance.topInterval,
            from: Offset.zero,
            child: child,
          );
  }
}
