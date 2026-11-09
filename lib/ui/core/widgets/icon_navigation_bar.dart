import 'package:flutter/material.dart';

/// Uma aba da [IconNavigationBar]: o nome fica para o leitor de tela.
typedef IconTab = ({Key key, String label, IconData icon});

/// A barra de abas só com ícones (H-TRE-18): fundo da tela, sem indicador,
/// a aba escolhida em primária. É a do curso e a do Treinador.
class IconNavigationBar extends StatelessWidget {
  const IconNavigationBar({
    required this.tabs,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.wrap,
    super.key,
  });

  final List<IconTab> tabs;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  /// Envolve o ícone de uma aba (o selo das metas, no curso).
  final Widget Function(int index, Widget icon)? wrap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      // Sem risco em cima: no canvas a barra continua o fundo da tela.
      child: NavigationBar(
        height: 64,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        // A cor do fundo da tela, como no canvas: a barra não forma faixa
        // branca (Gabriel, 05/11).
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        destinations: [
          for (final (i, tab) in tabs.indexed)
            NavigationDestination(
              key: tab.key,
              label: tab.label,
              icon: () {
                final icon = Icon(
                  tab.icon,
                  color: i == selectedIndex
                      ? colors.primary
                      : colors.onSurfaceVariant,
                );
                return wrap?.call(i, icon) ?? icon;
              }(),
            ),
        ],
      ),
    );
  }
}
