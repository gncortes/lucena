import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'lucena_motion.dart';
import 'movimento_reduzido.dart';

/// O controle segmentado de escolha única (CompSegmentado, D30: contorno em
/// pílula, 40 de altura, sem ✓), com a troca animada da H-ANI-30: o segmento
/// tocado se enche de cor e o anterior se esvazia em 200 ms (`emphasized`).
/// Com movimento reduzido, troca na hora. Onde o canvas desenha o segmentado
/// no lugar de chips (TelaConquistas), é ele que cumpre a H-ANI-21.
///
/// Existe porque o `SegmentedButton` do Material troca a cor de uma vez. As
/// cores são as do `segmentedButtonTheme` do app (secondaryContainer cheio).
/// [selecionado] nulo: nenhum segmento cheio.
class SegmentadoLucena<T> extends StatelessWidget {
  const SegmentadoLucena({
    required this.valores,
    required this.selecionado,
    required this.rotulo,
    required this.aoEscolher,
    this.chave,
    super.key,
  });

  final List<T> valores;
  final T? selecionado;
  final Widget Function(T valor) rotulo;
  final ValueChanged<T> aoEscolher;

  /// A key de cada segmento (o `Material` que leva a cor), para os testes.
  final Key Function(T valor)? chave;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final contorno = BorderSide(color: cores.outline);
    final duracao = MovimentoReduzido.of(context)
        ? Duration.zero
        : LucenaMotion.selecao;
    return Semantics(
      container: true,
      child: Container(
        height: 40,
        clipBehavior: Clip.antiAlias,
        // A borda transparente guarda o 1 px por fora dos segmentos; a visível
        // vem por cima, para o fundo do segmento cheio não a cobrir na curva.
        decoration: ShapeDecoration(
          shape: StadiumBorder(
            side: contorno.copyWith(color: Colors.transparent),
          ),
        ),
        foregroundDecoration: ShapeDecoration(
          shape: StadiumBorder(side: contorno),
        ),
        child: IntrinsicWidth(
          child: Row(
            children: [
              for (final (i, valor) in valores.indexed)
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(left: contorno),
                    ),
                    child: _Segmento(
                      chave: chave?.call(valor),
                      selecionado: valor == selecionado,
                      duracao: duracao,
                      aoTocar: () => aoEscolher(valor),
                      child: rotulo(valor),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.selecionado,
    required this.duracao,
    required this.aoTocar,
    required this.child,
    this.chave,
  });

  final Key? chave;
  final bool selecionado;
  final Duration duracao;
  final VoidCallback aoTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = tema.colorScheme;
    final vazio = cores.secondaryContainer.withValues(alpha: 0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: selecionado ? 1 : 0),
      duration: duracao,
      curve: LucenaMotion.emphasized,
      builder: (context, t, conteudo) => Semantics(
        selected: selecionado,
        button: true,
        enabled: true,
        inMutuallyExclusiveGroup: true,
        child: Material(
          key: chave,
          color: Color.lerp(vazio, cores.secondaryContainer, t),
          child: InkWell(
            onTap: aoTocar,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DefaultTextStyle.merge(
                  style: tema.textTheme.labelLarge?.copyWith(
                    color: Color.lerp(
                      cores.onSurface,
                      cores.onSecondaryContainer,
                      t,
                    ),
                  ),
                  maxLines: 1,
                  child: conteudo!,
                ),
              ),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
