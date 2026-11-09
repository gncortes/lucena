import 'package:flutter/material.dart';

import '../motion/opcoes_do_filtro.dart';
import '../theme/app_spacing.dart';
import 'actions_footer.dart';
import 'sheet_header.dart';

/// A estrutura da folha de filtros: título com o "Limpar" ao lado, as opções
/// (rolam, animadas por [OpcoesDoFiltro]) e o botão de baixo. As folhas do
/// histórico e dos finais mudam só o conteúdo e o padding da lista.
class FilterSheetScaffold extends StatelessWidget {
  const FilterSheetScaffold({
    required this.title,
    required this.filterId,
    required this.items,
    required this.applyButton,
    this.clearButton,
    this.listPadding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
    super.key,
  });

  final String title;

  /// O "Limpar" ao lado do título; nulo some.
  final Widget? clearButton;

  /// O id da animação das opções (`OpcoesDoFiltro.id`).
  final String filterId;

  /// As opções, de cima para baixo: [FilterSheetHeading] e
  /// [FilterSheetOptions] em sequência.
  final List<Widget> items;

  final EdgeInsetsGeometry listPadding;

  /// O botão de aplicar/fechar, no rodapé.
  final Widget applyButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: title, trailing: clearButton),
        Flexible(
          child: OpcoesDoFiltro(
            id: filterId,
            montar: (itens) => ListView(
              shrinkWrap: true,
              padding: listPadding,
              children: itens,
            ),
            itens: items,
          ),
        ),
        ActionsFooter(margin: AppSpacing.xl, children: [applyButton]),
      ],
    );
  }
}

/// O título de um grupo de opções da folha de filtros.
class FilterSheetHeading extends StatelessWidget {
  const FilterSheetHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Os chips de um grupo da folha de filtros, quebrando linha.
class FilterSheetOptions extends StatelessWidget {
  const FilterSheetOptions({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: children,
  );
}
