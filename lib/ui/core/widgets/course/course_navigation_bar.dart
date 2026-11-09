import '../../theme/app_colors.dart';

import 'package:flutter/material.dart';

import '../../../../domain/models/training/training_course.dart';
import '../../keys/course_guide_keys.dart';
import '../../l10n/l10n.dart';
import '../../theme/canvas_symbols.dart';

/// The course tabs during entry, downloads and the installed guide: icons
/// only (H-TRE-18). Each tab keeps its name for the screen reader.
class CourseNavigationBar extends StatelessWidget {
  const CourseNavigationBar({
    this.selectedIndex = 0,
    this.remaining = 0,
    this.tabs = CourseGuideTab.values,
    this.onDestinationSelected,
    super.key,
  });

  /// Index inside [tabs].
  final int selectedIndex, remaining;

  /// The tabs shown, in order. The School has no Guide tab.
  final List<CourseGuideTab> tabs;
  final ValueChanged<int>? onDestinationSelected;

  /// The red of the goals badge (canvas #B3261E).
  static const badgeColor = AppColors.trainingDayWrong;

  /// Above this many goals the badge reads "9+".
  static const badgeMax = 9;

  static IconData _icon(CourseGuideTab tab) => switch (tab) {
    CourseGuideTab.lesson => CanvasSymbols.school,
    CourseGuideTab.goals => CanvasSymbols.taskAlt,
    CourseGuideTab.guide => Icons.explore_outlined,
    CourseGuideTab.stats => CanvasSymbols.insights,
    CourseGuideTab.catalog => Icons.menu_book_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = context.l10n;
    String name(CourseGuideTab tab) => switch (tab) {
      CourseGuideTab.lesson => l.courseGuideTabLesson,
      CourseGuideTab.goals =>
        remaining > 0
            ? l.treinoTabGoalsPending(remaining)
            : l.courseGuideTabGoals,
      CourseGuideTab.guide => l.treinoTabGuide,
      CourseGuideTab.stats => l.courseGuideTabProgress,
      CourseGuideTab.catalog => l.courseGuideTabCatalog,
    };
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
              key: CourseGuideKeys.tab(tab.name),
              label: name(tab),
              icon: _TabIcon(
                tab: tab,
                remaining: remaining,
                l: l,
                icon: Icon(
                  _icon(tab),
                  color: i == selectedIndex
                      ? colors.primary
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// O ícone da aba; o das metas leva a bolinha com o que falta.
class _TabIcon extends StatelessWidget {
  const _TabIcon({
    required this.tab,
    required this.icon,
    required this.remaining,
    required this.l,
  });

  final CourseGuideTab tab;
  final Widget icon;
  final int remaining;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    if (tab != CourseGuideTab.goals) return icon;
    return Badge(
      key: CourseGuideKeys.goalsBadge,
      isLabelVisible: remaining > 0,
      backgroundColor: CourseNavigationBar.badgeColor,
      textColor: AppColors.white,
      label: Text(
        remaining > CourseNavigationBar.badgeMax
            ? l.treinoTabBadgeMany(CourseNavigationBar.badgeMax)
            : remaining.toString(),
      ),
      child: icon,
    );
  }
}
