import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/endgame_position.dart';
import '../../../routing/routes.dart';
import '../../core/keys/catalog_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/position_card.dart';
import '../../core/widgets/scroll_padding.dart';
import '../view_models/catalog_cubit.dart';
import 'catalog_ui.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';

/// Os finais de uma categoria, cada um numa seção com as posições dele já
/// abertas em grade: o jogador toca na posição e vai direto para a partida.
/// Quem não quer ver tudo fecha a seção pelo cabeçalho.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = context.select(
      (CatalogCubit cubit) => cubit.state.sections,
    );
    return Scaffold(
      key: CatalogKeys.categoryScreen,
      appBar: AppBar(title: Text(categoryName(l10n, category))),
      body: Column(
        children: [
          const GoalFilterBar(),
          Expanded(
            child: sections == null
                ? const Center(child: CircularProgressIndicator())
                : sections.isEmpty
                ? const CatalogEmpty()
                : ListView.builder(
                    key: CatalogKeys.positionList,
                    padding: scrollPadding(context),
                    itemCount: sections.length,
                    itemBuilder: (context, index) =>
                        _Section(section: sections[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Um final: o cabeçalho que abre e fecha a seção e, aberta, a grade das
/// posições dele.
class _Section extends StatelessWidget {
  const _Section({required this.section});

  final CatalogSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(section: section),
        _Collapsible(
          expanded: section.expanded,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 16),
            child: _PositionGrid(positions: section.positions),
          ),
        ),
      ],
    );
  }
}

/// O nome do final, o material em figurino, a contagem e a seta que mostra
/// se a seção está aberta.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final CatalogSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final subcategory = section.subcategory;
    return Semantics(
      button: true,
      expanded: section.expanded,
      child: InkWell(
        key: CatalogKeys.subcategory(subcategory),
        onTap: () => context.read<CatalogCubit>().toggleSection(subcategory),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      endgameName(l10n, subcategory),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SubcategoryMaterialText(
                          subcategory,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          l10n.catalogPositionCount(section.positions.length),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // A seta gira para baixo com a seção aberta e para cima fechada.
              AnimatedRotation(
                turns: section.expanded ? 0 : 0.5,
                duration: AppMotion.of(context).state,
                child: Icon(Icons.expand_more, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O conteúdo de uma seção: aberto, aparece inteiro; fechado, some. A troca
/// encolhe ou cresce a altura num instante (sem animação com "remover
/// animações" no sistema), e fechado de vez o conteúdo sai da tela.
class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.expanded, required this.child});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: expanded ? 1 : 0),
      duration: AppMotion.of(context).state,
      curve: AppMotion.move,
      child: child,
      builder: (context, factor, child) {
        if (factor == 0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            heightFactor: factor,
            child: child,
          ),
        );
      },
    );
  }
}

/// As posições em grade: duas colunas no celular, três em tela larga; cada
/// cartão com a altura do próprio conteúdo.
class _PositionGrid extends StatelessWidget {
  const _PositionGrid({required this.positions});

  final List<EndgamePosition> positions;

  static const gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final fulfilled = context.select(
      (CatalogCubit cubit) => cubit.state.fulfilled,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 568 ? 3 : 2;
        // Arredondado para baixo: a soma das colunas nunca passa da largura.
        final width = ((constraints.maxWidth - gap * (columns - 1)) / columns)
            .floorToDouble();
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final position in positions)
              SizedBox(
                width: width,
                child: _PositionCell(
                  position: position,
                  fulfilled: fulfilled.contains(position.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Uma posição na grade: o tabuleiro visto pelo lado que joga, o número, o
/// objetivo e quem joga. O tabuleiro voa até a configuração da partida.
class _PositionCell extends StatelessWidget {
  const _PositionCell({required this.position, required this.fulfilled});

  final EndgamePosition position;

  /// O objetivo já foi cumprido nesta posição.
  final bool fulfilled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = context.l10n;
    final turn = position.fen.split(' ')[1] == 'b' ? Side.black : Side.white;
    final goal = GoalStyle.of(context, position.goal);
    return PositionCard(
      key: CatalogKeys.position(position.id),
      fen: position.fen,
      heroTag: catalogBoardTag(position.id),
      doneKey: fulfilled ? CatalogKeys.fulfilled(position.id) : null,
      doneLabel: fulfilled ? l10n.catalogFulfilled : null,
      onTap: () => context.push(
        Routes.setup(
          position.fen,
          goal: position.goal.code,
          position: position.id,
        ),
      ),
      children: [
        Text(
          l10n.catalogPositionNumber(position.number),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          children: [
            _Tag(
              label: goalLabel(l10n, position.goal),
              icon: goal.icon,
              color: goal.container,
              onColor: goal.onContainer,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          turn == Side.white
              ? l10n.freeBoardWhiteToMove
              : l10n.freeBoardBlackToMove,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.color,
    required this.onColor,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppShape.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[
            Icon(icon, size: 14, color: onColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: onColor),
            ),
          ),
        ],
      ),
    );
  }
}
