import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_colors.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O cartão de um plano na compra (H-ANI-26, clipe 06): rádio à esquerda e o
/// conteúdo ([child]) ao lado. Ao trocar de plano, o contorno (1 → 2 px,
/// neutro → primário) e o fundo cruzam em 250 ms (`emphasized`) e o ponto do
/// rádio escala. Com movimento reduzido, troca sem transição.
///
/// O rótulo do botão de compra troca com [RotuloQueCruza].
class CartaoDePlano extends StatelessWidget {
  const CartaoDePlano({
    required this.selecionado,
    required this.aoTocar,
    required this.child,
    this.fundoMarcado,
    super.key,
  });

  final bool selecionado;
  final VoidCallback? aoTocar;
  final Widget child;

  /// O fundo do plano marcado (padrão: o mesmo do cartão).
  final Color? fundoMarcado;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final raio = BorderRadius.circular(AppShape.card);
    return Semantics(
      selected: selecionado,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selecionado ? 1 : 0),
        duration: MovimentoReduzido.of(context)
            ? Duration.zero
            : LucenaMotion.selecaoDoPlano,
        curve: LucenaMotion.emphasized,
        child: child,
        builder: (context, t, filho) => Material(
          key: MotionKeys.contornoDoPlano,
          color: Color.lerp(
            AppColors.cardSurface,
            fundoMarcado ?? AppColors.cardSurface,
            t,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: raio,
            side: BorderSide(
              color: Color.lerp(AppColors.cardOutline, cores.primary, t)!,
              width: 1 + t,
            ),
          ),
          child: InkWell(
            borderRadius: raio,
            onTap: aoTocar,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: _Radio(t: t),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: filho!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color.lerp(cores.outline, cores.primary, t)!,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Transform.scale(
        key: MotionKeys.pontoDoPlano,
        scale: t.clamp(0.0, 1.0),
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cores.primary,
          ),
        ),
      ),
    );
  }
}

/// O rótulo do botão que troca cruzando (H-ANI-26): o antigo sai em 120 ms e
/// o novo entra em 160 ms, depois. Com movimento reduzido, troca na hora.
class RotuloQueCruza extends StatelessWidget {
  const RotuloQueCruza(this.texto, {this.estilo, super.key});

  final String texto;
  final TextStyle? estilo;

  static final _total = LucenaMotion.rotuloSai + LucenaMotion.rotuloEntra;

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    final chave = ValueKey(texto);
    return AnimatedSwitcher(
      duration: reduzido ? Duration.zero : _total,
      reverseDuration: reduzido ? Duration.zero : LucenaMotion.rotuloSai,
      transitionBuilder: (filho, animacao) => FadeTransition(
        opacity: filho.key == chave
            ? CurvedAnimation(
                parent: animacao,
                curve: Interval(
                  LucenaMotion.rotuloSai.inMicroseconds / _total.inMicroseconds,
                  1,
                ),
              )
            : animacao,
        child: filho,
      ),
      child: Text(texto, key: chave, style: estilo),
    );
  }
}
