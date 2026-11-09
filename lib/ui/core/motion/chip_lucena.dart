import 'package:flutter/material.dart';

import '../theme/app_chip.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O chip de filtro do app (H-ANI-21): o escolhido se enche de cor e ganha o
/// ✓ em 200 ms; o que deixa de ser escolhido se esvazia no mesmo tempo.
/// Anima sempre, salvo com movimento reduzido, quando troca sem transição.
///
/// Por dentro é o `FilterChip` do tema (densidade e alvo de toque de
/// [AppChip]). A cor do fundo anima aqui (`emphasized`): no Material 3 o
/// `RawChip` troca a cor na hora ao desmarcar. O ✓ entra no tempo da
/// história com a curva do `RawChip` (`fastOutSlowIn`), que não se troca.
class ChipLucena extends StatelessWidget {
  const ChipLucena({
    required this.label,
    required this.selecionado,
    required this.aoEscolher,
    this.avatar,
    this.tooltip,
    super.key,
  });

  final Widget label;
  final bool selecionado;

  /// Nulo: o chip fica desabilitado.
  final ValueChanged<bool>? aoEscolher;
  final Widget? avatar;
  final String? tooltip;

  static final _anima = ChipAnimationStyle(
    selectAnimation: const AnimationStyle(duration: LucenaMotion.selecao),
    avatarDrawerAnimation: const AnimationStyle(duration: LucenaMotion.selecao),
  );

  static final _semAnimacao = ChipAnimationStyle(
    enableAnimation: AnimationStyle.noAnimation,
    selectAnimation: AnimationStyle.noAnimation,
    avatarDrawerAnimation: AnimationStyle.noAnimation,
    deleteDrawerAnimation: AnimationStyle.noAnimation,
  );

  @override
  Widget build(BuildContext context) {
    final reduzido = MovimentoReduzido.of(context);
    final tema = Theme.of(context);
    final cheio =
        tema.chipTheme.selectedColor ?? tema.colorScheme.secondaryContainer;
    final fundo = tema.chipTheme.backgroundColor ?? Colors.transparent;
    // Transparente esvazia no mesmo tom, sem escurecer no meio.
    final vazio = fundo.a == 0 ? cheio.withValues(alpha: 0) : fundo;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selecionado ? 1 : 0),
      duration: reduzido ? Duration.zero : LucenaMotion.selecao,
      curve: LucenaMotion.emphasized,
      builder: (context, t, _) => _Chip(
        owner: this,
        reduzido: reduzido,
        cor: aoEscolher == null ? null : Color.lerp(vazio, cheio, t),
      ),
    );
  }
}

/// O `FilterChip` do tema, com a cor do fundo do instante da animação.
class _Chip extends StatelessWidget {
  const _Chip({required this.owner, required this.reduzido, required this.cor});

  final ChipLucena owner;
  final bool reduzido;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: owner.label,
      color: cor == null ? null : WidgetStatePropertyAll(cor),
      avatar: owner.avatar,
      tooltip: owner.tooltip,
      selected: owner.selecionado,
      onSelected: owner.aoEscolher,
      showCheckmark: true,
      materialTapTargetSize: AppChip.tapTarget,
      visualDensity: AppChip.density,
      chipAnimationStyle: reduzido
          ? ChipLucena._semAnimacao
          : ChipLucena._anima,
    );
  }
}
