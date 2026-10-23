import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../../routing/routes.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';

/// "Bem-vindo de volta" (canvas `PropV1PerfilRecuperar`): o que a conta
/// trouxe, já junto com o aparelho (vale o maior em cada item).
class AccountRestoredScreen extends StatelessWidget {
  const AccountRestoredScreen({
    required this.result,
    required this.from,
    super.key,
  });

  final SyncResult result;
  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = result.summary;
    final nickname = summary.profile.nickname;
    final name = nickname.isNotEmpty
        ? nickname
        : context.read<AccountRepository>().current?.name ??
              l10n.profileNicknameDefault;
    final lessons = summary.lessons.values.where((l) => l.lessonDone).length;
    final items = [
      (
        Icons.show_chart,
        l10n.accountRestoredRating,
        '${summary.rating?.rating.round() ?? summary.profile.rating}',
      ),
      (
        Icons.hiking,
        l10n.accountRestoredJourney,
        l10n.accountRestoredJourneyValue(summary.challenges.length),
      ),
      (
        Icons.auto_stories,
        l10n.accountRestoredLessons,
        l10n.accountRestoredLessonsValue(lessons),
      ),
      (
        Icons.timer,
        l10n.accountRestoredSpeedrun,
        l10n.accountRestoredSpeedrunValue(summary.speedruns.length),
      ),
    ];
    return Scaffold(
      key: AccountKeys.restoredScreen,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.goalWinBg,
                  borderRadius: BorderRadius.circular(AppShape.extraLarge),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Icon(
                    Icons.cloud_done,
                    size: AppIconSize.illustration,
                    color: AppColors.record,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.accountRestoredTitle(name),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.accountRestoredText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppShape.large),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Column(
                  children: [
                    for (final (icon, title, value) in items)
                      ListTile(
                        leading: Icon(icon, color: colors.primary),
                        title: Text(title),
                        trailing: Text(
                          value,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.accountRestoredMerged,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        children: [
          FilledButton(
            key: AccountKeys.restoredContinue,
            onPressed: () => context.go(Routes.afterAccount(from)),
            child: Text(l10n.accountRestoredContinue),
          ),
        ],
      ),
    );
  }
}
