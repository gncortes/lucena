import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../keys/motion_keys.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O tabuleiro que voa de uma tela para a outra (H-ANI-02): o cartão da
/// lista, do destaque ou do Início e o tabuleiro da tela de jogo usam o
/// mesmo [id]. A rota precisa ser a [RotaComTabuleiro] (ou a
/// [PaginaComTabuleiro], no go_router).
///
/// - Voo de 450 ms em linha reta (`RectTween`, sem arco).
/// - O tabuleiro de A se dissolve no de B entre 0,2 e 0,65 do voo.
/// - O canto vai do [raio] de A ao [raio] de B.
/// - Os dois tabuleiros reais ficam escondidos durante o voo, e o de B
///   assume do último quadro, sem salto.
///
/// Quando o tabuleiro fica no mesmo lugar nas duas telas, o retângulo não
/// muda e nada voa. Com movimento reduzido, não há hero: a tela troca num
/// fade de 100 ms.
class TabuleiroHero extends StatelessWidget {
  const TabuleiroHero({
    required this.id,
    required this.child,
    this.raio = 0,
    super.key,
  });

  /// A posição (ou a partida) que o tabuleiro mostra, igual nas duas telas.
  final String id;

  /// O raio do canto do tabuleiro nesta tela.
  final double raio;

  final Widget child;

  static String tag(String id) => 'tabuleiro-$id';

  @override
  Widget build(BuildContext context) {
    final tabuleiro = _ComRaio(raio: raio, child: child);
    if (MovimentoReduzido.of(context)) return tabuleiro;
    return Hero(
      tag: tag(id),
      createRectTween: (inicio, fim) => RectTween(begin: inicio, end: fim),
      flightShuttleBuilder: _emVoo,
      child: tabuleiro,
    );
  }

  static Widget _emVoo(
    BuildContext contextoDoVoo,
    Animation<double> voo,
    HeroFlightDirection direcao,
    BuildContext deContexto,
    BuildContext paraContexto,
  ) {
    final ida = direcao == HeroFlightDirection.push;
    // A é sempre o cartão, B a tela do tabuleiro: na volta o voo é o mesmo,
    // com o tempo correndo de 1 a 0.
    final a = ida ? deContexto : paraContexto;
    final b = ida ? paraContexto : deContexto;
    final comRaioA = (a.widget as Hero).child as _ComRaio;
    final comRaioB = (b.widget as Hero).child as _ComRaio;
    final tamanhoA = (a.findRenderObject()! as RenderBox).size;
    final tamanhoB = (b.findRenderObject()! as RenderBox).size;
    return AnimatedBuilder(
      key: MotionKeys.tabuleiroEmVoo,
      animation: voo,
      builder: (context, _) {
        final t = voo.value;
        final deB = LucenaMotion.dissolveDoVoo.transform(t.clamp(0.0, 1.0));
        return ClipRRect(
          borderRadius: BorderRadius.lerp(
            BorderRadius.circular(comRaioA.raio),
            BorderRadius.circular(comRaioB.raio),
            t,
          )!,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - deB,
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: tamanhoA,
                    child: comRaioA.child,
                  ),
                ),
              ),
              Opacity(
                opacity: deB,
                child: FittedBox(
                  child: SizedBox.fromSize(
                    size: tamanhoB,
                    child: comRaioB.child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ComRaio extends StatelessWidget {
  const _ComRaio({required this.raio, required this.child});

  final double raio;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ClipRRect(borderRadius: BorderRadius.circular(raio), child: child);
}

/// A entrada e a saída da tela que tem o [TabuleiroHero] (H-ANI-02).
///
/// - **Ida:** a tela B entra com fade e sobe 3% da altura, durante o voo.
/// - **Volta:** a tela que sai faz fade e desce 20 px nos primeiros 270 ms,
///   enquanto o tabuleiro volta ao cartão.
/// - **Movimento reduzido:** só um fade de 100 ms.
abstract final class TransicaoComTabuleiro {
  static Duration duracao({required bool reduzir}) =>
      reduzir ? LucenaMotion.fadeReduzido : LucenaMotion.vooDoTabuleiro;

  /// A fração do voo que a saída ocupa, na volta.
  static final double _fracaoDaSaida =
      LucenaMotion.saidaDaTela.inMicroseconds /
      LucenaMotion.vooDoTabuleiro.inMicroseconds;

  static Widget construir(
    Animation<double> animacao,
    Widget tela, {
    required bool reduzir,
  }) {
    if (reduzir) return FadeTransition(opacity: animacao, child: tela);
    return AnimatedBuilder(
      animation: animacao,
      builder: (context, tela) {
        final t = animacao.value;
        if (animacao.status == AnimationStatus.reverse) {
          final saida = LucenaMotion.emphasizedAccelerate.transform(
            ((1 - t) / _fracaoDaSaida).clamp(0.0, 1.0),
          );
          return Opacity(
            opacity: 1 - saida,
            child: Transform.translate(
              offset: Offset(0, LucenaMotion.descidaDaTela * saida),
              child: tela,
            ),
          );
        }
        final entrada = LucenaMotion.entradaDaTelaB.transform(t);
        return Opacity(
          opacity: entrada,
          child: FractionalTranslation(
            translation: Offset(0, LucenaMotion.subidaDaTelaB * (1 - entrada)),
            child: tela,
          ),
        );
      },
      child: tela,
    );
  }
}

/// A rota (Navigator) para a tela com [TabuleiroHero].
class RotaComTabuleiro<T> extends PageRouteBuilder<T> {
  RotaComTabuleiro({
    required WidgetBuilder builder,
    required bool reduzir,
    super.settings,
  }) : super(
         pageBuilder: (context, _, _) => builder(context),
         transitionDuration: TransicaoComTabuleiro.duracao(reduzir: reduzir),
         reverseTransitionDuration: TransicaoComTabuleiro.duracao(
           reduzir: reduzir,
         ),
         transitionsBuilder: (_, animacao, _, tela) =>
             TransicaoComTabuleiro.construir(animacao, tela, reduzir: reduzir),
       );

  /// Lê o movimento reduzido do [context] de quem empurra.
  factory RotaComTabuleiro.de(
    BuildContext context, {
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) => RotaComTabuleiro(
    builder: builder,
    reduzir: MovimentoReduzido.of(context),
    settings: settings,
  );
}

/// A página do go_router para a tela com [TabuleiroHero] (no `pageBuilder`
/// da rota, com o `context` que ele recebe).
class PaginaComTabuleiro<T> extends CustomTransitionPage<T> {
  factory PaginaComTabuleiro({
    required BuildContext context,
    required Widget child,
    LocalKey? key,
    String? name,
    Object? arguments,
  }) => PaginaComTabuleiro._(
    reduzir: MovimentoReduzido.of(context),
    child: child,
    key: key,
    name: name,
    arguments: arguments,
  );

  PaginaComTabuleiro._({
    required bool reduzir,
    required super.child,
    super.key,
    super.name,
    super.arguments,
  }) : super(
         transitionDuration: TransicaoComTabuleiro.duracao(reduzir: reduzir),
         reverseTransitionDuration: TransicaoComTabuleiro.duracao(
           reduzir: reduzir,
         ),
         transitionsBuilder: (_, animacao, _, tela) =>
             TransicaoComTabuleiro.construir(animacao, tela, reduzir: reduzir),
       );
}
