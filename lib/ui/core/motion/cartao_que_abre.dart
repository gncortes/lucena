import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_shape.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// Monta o cartão fechado; [abrir] abre a tela.
typedef CartaoFechadoBuilder = Widget Function(
  BuildContext context,
  VoidCallback abrir,
);

/// Monta a tela aberta; [fechar] volta ao cartão.
typedef CartaoAbertoBuilder = Widget Function(
  BuildContext context,
  VoidCallback fechar,
);

/// O cartão sem tabuleiro que cresce até virar a tela que ele abre
/// (H-ANI-04, container transform com fade): 450 ms. Com [venda], a entrada
/// única de PropV2CursoApresentacao: 560 ms e raio 21.
///
/// A cascata da tela aberta (`EntradaEmCascata`) espera o transform acabar
/// para começar. A curva do transform é a do `OpenContainer`
/// (`fastOutSlowIn`), que o pacote não deixa trocar.
///
/// Com movimento reduzido, a tela abre num fade de 100 ms, sem retângulo
/// intermediário.
class CartaoQueAbre extends StatelessWidget {
  const CartaoQueAbre({
    required this.fechado,
    required this.aberto,
    this.venda = false,
    this.raio,
    this.corFechado = Colors.transparent,
    this.aoFechar,
    super.key,
  });

  final CartaoFechadoBuilder fechado;
  final CartaoAbertoBuilder aberto;

  /// A entrada única da venda: 560 ms e raio 21.
  final bool venda;

  /// Nulo: 21 na venda, o raio do cartão ([AppShape.large]) no resto.
  final double? raio;

  /// O fundo do cartão no começo do transform; transparente deixa o cartão
  /// de dentro com o próprio fundo.
  final Color corFechado;
  final VoidCallback? aoFechar;

  Future<void> _abrirSemMovimento(BuildContext context) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: LucenaMotion.fadeReduzido,
        reverseTransitionDuration: LucenaMotion.fadeReduzido,
        pageBuilder: (context, _, _) => _Aberto(
          key: MotionKeys.cartaoQueAbre,
          aberto: aberto,
          fechar: () => Navigator.of(context).pop(),
        ),
        transitionsBuilder: (context, animacao, _, filho) =>
            FadeTransition(opacity: animacao, child: filho),
      ),
    );
    aoFechar?.call();
  }

  @override
  Widget build(BuildContext context) {
    final raio =
        this.raio ?? (venda ? LucenaMotion.raioDaVenda : AppShape.large);
    return OpenContainer<void>(
      tappable: false,
      closedElevation: 0,
      openElevation: 0,
      closedColor: corFechado,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(raio)),
      ),
      transitionType: ContainerTransitionType.fade,
      transitionDuration: venda
          ? LucenaMotion.cartaoDaVenda
          : LucenaMotion.cartaoAbre,
      onClosed: (_) => aoFechar?.call(),
      closedBuilder: (context, abrir) => fechado(
        context,
        () => MovimentoReduzido.of(context)
            ? _abrirSemMovimento(context)
            : abrir(),
      ),
      openBuilder: (context, fechar) => _Aberto(
        key: MotionKeys.cartaoQueAbre,
        aberto: aberto,
        fechar: () => fechar(),
      ),
    );
  }
}

/// A tela aberta do [CartaoQueAbre].
class _Aberto extends StatelessWidget {
  const _Aberto({required this.aberto, required this.fechar, super.key});

  final CartaoAbertoBuilder aberto;
  final VoidCallback fechar;

  @override
  Widget build(BuildContext context) => aberto(context, fechar);
}
