import 'package:flutter/material.dart';

import '../keys/motion_keys.dart';
import '../theme/app_shape.dart';
import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// A opção de escolha única do tour, do objetivo e do nível (H-ANI-30): o
/// fundo, a borda e o rádio passam ao estado novo em 200 ms (`emphasized`),
/// sempre. Com movimento reduzido, trocam sem transição. Onde o canvas desenha
/// opções no lugar de chips (PropV1PerfilObjetivo), é ela que cumpre a
/// seleção da H-ANI-21.
///
/// É a casca do `ChoiceCard`: o [child] é o conteúdo (ícone, título e
/// texto) e o rádio vem no fim.
class OpcaoSelecionavel extends StatelessWidget {
  const OpcaoSelecionavel({
    required this.selecionada,
    required this.aoTocar,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final bool selecionada;
  final VoidCallback? aoTocar;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Semantics(
      selected: selecionada,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selecionada ? 1 : 0),
        duration: MovimentoReduzido.of(context)
            ? Duration.zero
            : LucenaMotion.selecao,
        curve: LucenaMotion.emphasized,
        builder: (context, t, conteudo) => Material(
          color: Color.lerp(
            cores.surfaceContainerLowest,
            cores.primaryContainer,
            t,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.medium),
            side: BorderSide(
              color: Color.lerp(cores.outlineVariant, cores.primary, t)!,
              width: 1 + t,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: aoTocar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: padding,
                child: Row(
                  children: [
                    Expanded(child: conteudo!),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      key: MotionKeys.radioDaOpcao,
                      selecionada
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: Color.lerp(
                        cores.onSurfaceVariant,
                        cores.primary,
                        t,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
