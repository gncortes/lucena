import 'package:flutter/material.dart';

import '../../../../domain/models/training/training_course.dart';
import '../../keys/course_guide_keys.dart';
import '../../l10n/l10n.dart';
import '../../theme/canvas_symbols.dart';

/// The same course tabs during entry, downloads and the installed guide.
class CourseNavigationBar extends StatelessWidget {
  const CourseNavigationBar({
    this.selectedIndex = 0,
    this.remaining = 0,
    this.onDestinationSelected,
    super.key,
  });
  final int selectedIndex, remaining;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l = context.l10n;
    final labels = [
      l.courseGuideTabLesson,
      l.courseGuideTabGoals,
      l.courseGuideTabProgress,
      l.courseGuideTabCatalog,
    ];
    return SafeArea(
      top: false,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: NavigationBar(
          height: 79,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: colors.surfaceContainerLowest,
          indicatorColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).textTheme.labelMedium?.copyWith(
              color: states.contains(WidgetState.selected)
                  ? colors.primary
                  : colors.onSurfaceVariant,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w600
                  : FontWeight.w500,
              letterSpacing: 0,
              height: 14 / 12,
            ),
          ),
          destinations: [
            for (final (i, icon) in [
              CanvasSymbols.school,
              CanvasSymbols.taskAlt,
              CanvasSymbols.insights,
              Icons.menu_book_outlined,
            ].indexed)
              NavigationDestination(
                key: CourseGuideKeys.tab(CourseGuideTab.values[i].name),
                label: labels[i],
                icon: i == 1
                    ? Badge(
                        key: CourseGuideKeys.goalsBadge,
                        isLabelVisible: remaining > 0,
                        label: Text(remaining.toString()),
                        child: Icon(
                          icon,
                          color: i == selectedIndex
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        icon,
                        color: i == selectedIndex
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
