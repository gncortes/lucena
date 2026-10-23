import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/next_steps_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/goal_style.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/next_steps.dart';
import '../../core/widgets/scroll_padding.dart';

/// Os próximos passos (canvas V2 · Ligações, L1 e L2): depois do "Seu nível"
/// ([level], quando há número) ou da Escola concluída ([graduated]). Mostra
/// por onde começar, o que vem aí e, no fim do nível, que o que a pessoa faz
/// ajusta as sugestões.
class NextStepsScreen extends StatelessWidget {
  const NextStepsScreen({this.graduated = false, this.level, super.key});

  final bool graduated;
  final int? level;

  static const _heroSize = 72.0;
  static const _heroIcon = 42.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final level = this.level;
    void go(String route) => context.go(route);
    final lessons = NextStep(
      id: 'lessons',
      icon: Icons.school,
      title: l10n.endgamesTitle,
      body: graduated ? l10n.nextStepsLessonsFirst : l10n.nextStepsLessonsBody,
      badge: graduated ? l10n.nextStepsRecommended : l10n.nextStepsForYou,
      onTap: () => go(Routes.endgames),
    );
    final race = NextStep(
      id: 'race',
      icon: Icons.timer,
      title: l10n.raceTitle,
      body: l10n.nextStepsRaceBody,
      onTap: () => go(Routes.race),
    );
    final train = NextStep(
      id: 'train',
      icon: Icons.sports_esports,
      title: l10n.nextStepsTrainTitle,
      body: l10n.nextStepsTrainBody,
      onTap: () => go(Routes.catalog),
    );
    final journey = NextStep(
      id: 'journey',
      icon: Icons.flag,
      title: l10n.journeyTitle,
      body: l10n.nextStepsJourneyBody,
      onTap: () => go(Routes.journey),
    );
    final heroBackground = graduated
        ? colors.tertiaryContainer
        : ChangeColors.of(context, up: true).withValues(alpha: 0.16);
    final heroColor = graduated
        ? colors.onTertiaryContainer
        : ChangeColors.of(context, up: true);
    return Scaffold(
      key: NextStepsKeys.screen,
      appBar: LucenaAppBar(
        automaticallyImplyLeading: false,
        title: Text(
          graduated ? l10n.nextStepsSchoolBar : l10n.nextStepsReadyBar,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: scrollPadding(
                context,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.sm,
              ),
              children: [
                Column(
                  spacing: AppSpacing.md,
                  children: [
                    Container(
                      width: _heroSize,
                      height: _heroSize,
                      decoration: BoxDecoration(
                        color: heroBackground,
                        borderRadius: BorderRadius.circular(
                          AppShape.extraLarge,
                        ),
                      ),
                      child: Icon(
                        graduated
                            ? Icons.workspace_premium
                            : Icons.check_circle,
                        size: _heroIcon,
                        color: heroColor,
                      ),
                    ),
                    Text(
                      graduated
                          ? l10n.nextStepsSchoolTitle
                          : level == null
                          ? l10n.nextStepsReadyBar
                          : l10n.nextStepsLevel(level),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      graduated
                          ? l10n.nextStepsSchoolBody
                          : l10n.nextStepsReadyBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                NextSteps(
                  title: graduated
                      ? l10n.nextStepsSchoolSection
                      : l10n.nextStepsReadySection,
                  steps: [lessons, race, if (graduated) journey, train],
                ),
                const SizedBox(height: AppSpacing.lg),
                const ComingSoonCard(),
                if (!graduated) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const DataNote(),
                ],
              ],
            ),
          ),
          ActionsFooter(
            children: [
              TextButton(
                key: NextStepsKeys.home,
                onPressed: () => go(Routes.home),
                child: Text(l10n.nextStepsHome),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
