import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependencies.dart' show activeTrainingCourses;
import '../../../domain/models/home_layout.dart';
import '../../../domain/models/home_shortcut.dart';
import '../../../domain/models/training/training_course_config.dart';
import '../../../routing/routes.dart';
import '../../core/keys/home_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import 'home_path_ui.dart';

/// Como cada atalho da grade aparece: o ícone e as cores dele, o nome, a
/// frase, a tela que abre e a key.
extension HomeShortcutUi on HomeShortcut {
  IconData get icon => switch (this) {
    HomeShortcut.school => HomePath.learn.icon,
    HomeShortcut.journey => HomePath.journey.icon,
    HomeShortcut.endgames => HomePath.endgames.icon,
    HomeShortcut.train => HomePath.train.icon,
    HomeShortcut.speedrun => HomePath.speedrun.icon,
    HomeShortcut.race => HomePath.race.icon,
    HomeShortcut.stars => HomePath.stars.icon,
  };

  /// O fundo e a cor do ícone (canvas `CompModoTile`).
  ({Color background, Color foreground}) tone(ColorScheme colors) =>
      switch (this) {
        HomeShortcut.journey => (
          background: colors.primaryContainer,
          foreground: colors.onPrimaryContainer,
        ),
        HomeShortcut.endgames => (
          background: colors.tertiaryContainer,
          foreground: AppColors.goldInk,
        ),
        HomeShortcut.train => (
          background: AppColors.tilePurple,
          foreground: AppColors.tilePurpleOn,
        ),
        HomeShortcut.school || HomeShortcut.stars => (
          background: AppColors.tileGreen,
          foreground: AppColors.tileGreenOn,
        ),
        HomeShortcut.speedrun || HomeShortcut.race => (
          background: colors.surfaceContainerHighest,
          foreground: colors.onSurface,
        ),
      };

  String title(AppLocalizations l10n) => switch (this) {
    HomeShortcut.school => HomePath.learn.title(l10n),
    HomeShortcut.journey => l10n.homeJourney,
    HomeShortcut.endgames => l10n.homeEndgames,
    HomeShortcut.train => l10n.homeTrain,
    HomeShortcut.speedrun => l10n.homeSpeedrun,
    HomeShortcut.race => l10n.homeRace,
    HomeShortcut.stars => l10n.homeShortcutStars,
  };

  String body(AppLocalizations l10n) => switch (this) {
    HomeShortcut.school => HomePath.learn.body(l10n, null),
    HomeShortcut.journey => l10n.homeShortcutJourneyBody,
    HomeShortcut.endgames => l10n.homeShortcutEndgamesBody,
    HomeShortcut.train => l10n.homeShortcutTrainBody,
    HomeShortcut.speedrun => l10n.homeShortcutSpeedrunBody,
    HomeShortcut.race => l10n.homeShortcutRaceBody,
    HomeShortcut.stars => l10n.homeShortcutStarsBody,
  };

  String get route => switch (this) {
    HomeShortcut.school =>
      activeTrainingCourses.contains(TrainingCourseConfig.escola)
          ? Routes.school
          : HomePath.learn.route,
    HomeShortcut.journey => HomePath.journey.route,
    HomeShortcut.endgames => HomePath.endgames.route,
    HomeShortcut.train => HomePath.train.route,
    HomeShortcut.speedrun => HomePath.speedrun.route,
    HomeShortcut.race => HomePath.race.route,
    HomeShortcut.stars => HomePath.stars.route,
  };

  /// A mesma key dos cartões de caminho de antes.
  Key get key => switch (this) {
    HomeShortcut.school => HomeKeys.schoolButton,
    HomeShortcut.journey => HomeKeys.journeyButton,
    HomeShortcut.endgames => HomeKeys.endgamesButton,
    HomeShortcut.train => HomeKeys.catalogButton,
    HomeShortcut.speedrun => HomeKeys.speedrunButton,
    HomeShortcut.race => HomeKeys.raceButton,
    HomeShortcut.stars => HomeKeys.starsButton,
  };
}

/// Um atalho da grade da tela inicial (canvas `CompModoTile`): o ícone na
/// caixa colorida no alto e, embaixo, o nome e a frase de duas linhas. Todos
/// com a mesma altura.
class ModeTile extends StatelessWidget {
  const ModeTile({required this.shortcut, super.key});

  /// A altura de todo atalho.
  static const height = 144.0;

  /// A caixa do ícone.
  static const iconBox = 44.0;

  final HomeShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tone = shortcut.tone(colors);
    final body = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
      letterSpacing: 0,
    );
    return SizedBox(
      height: height,
      child: Material(
        key: shortcut.key,
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppShape.large),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(shortcut.route),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: tone.background,
                    borderRadius: BorderRadius.circular(AppShape.large),
                  ),
                  child: Icon(
                    shortcut.icon,
                    fill: 1,
                    size: AppIconSize.standard,
                    color: tone.foreground,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortcut.title(l10n),
                      maxLines: 1,
                      style: context.cardTitle?.copyWith(
                        fontWeight: AppWeight.heavy,
                        letterSpacing: 0,
                      ),
                    ),
                    // Sempre a altura de duas linhas: o título fica na
                    // mesma altura em todos os atalhos.
                    SizedBox(
                      height: _twoLines(context, body),
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Text(
                          shortcut.body(l10n),
                          maxLines: 2,
                          style: body,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A altura de duas linhas de [style], com a escala de texto da tela.
double _twoLines(BuildContext context, TextStyle? style) {
  final painter = TextPainter(
    text: TextSpan(text: '\n', style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 2,
  )..layout();
  final height = painter.height;
  painter.dispose();
  return height;
}

/// O título de uma seção da tela inicial com o "Ver mais" sublinhado ao
/// lado.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    required this.onSeeMore,
    this.titleKey,
    this.seeMoreKey,
    super.key,
  });

  final String title;
  final VoidCallback onSeeMore;
  final Key? titleKey;
  final Key? seeMoreKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              key: titleKey,
              maxLines: 1,
              style: context.cardTitle?.copyWith(color: colors.onSurface),
            ),
          ),
        ),
        InkWell(
          key: seeMoreKey,
          onTap: onSeeMore,
          borderRadius: BorderRadius.circular(AppShape.small),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Text(
              context.l10n.homeSeeMore,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: colors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
