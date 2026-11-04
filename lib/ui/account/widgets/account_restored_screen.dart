import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/characters/character_repository.dart';
import '../../../data/repositories/journey/journey_repository.dart';
import '../../../data/repositories/sync/sync_repository.dart';
import '../../core/keys/account_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/skeleton.dart';
import '../../journey/widgets/journey_ui.dart';
import '../view_models/account_restored_cubit.dart';
import 'account_flow.dart';

/// "Bem-vindo de volta" (canvas `PropV1PerfilRecuperar`): o que a conta
/// trouxe, já junto com o aparelho (vale o maior em cada item). Voltar do
/// sistema é o mesmo que "Continuar" (H-CON-10).
class AccountRestoredScreen extends StatelessWidget {
  const AccountRestoredScreen({
    required this.result,
    required this.from,
    super.key,
  });

  final SyncResult result;
  final String from;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AccountRestoredCubit(
      result.summary,
      context.read<JourneyRepository>(),
      context.read<CharacterRepository>(),
    )..load(),
    child: _RestoredView(result: result, from: from),
  );
}

class _RestoredView extends StatelessWidget {
  const _RestoredView({required this.result, required this.from});

  final SyncResult result;
  final String from;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final summary = result.summary;
    final state = context.watch<AccountRestoredCubit>().state;
    void next() => finishAccount(GoRouter.of(context), from);
    if (state.failed) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) next();
        },
        child: LoadErrorScreen(
          kind: LoadErrorKind.generic,
          onAction: context.read<AccountRestoredCubit>().load,
          onBack: next,
        ),
      );
    }
    final current = state.current;
    final journey = current == null
        ? l10n.accountRestoredJourneyValue(summary.challenges.length)
        : current.completed.isEmpty
        ? l10n.accountRestoredJourneyValue(0)
        : l10n.conVoltaJourneyValue(
            opponentName(l10n, state.characters, current.rung.opponent),
            current.completed.length,
            current.rung.challenges.length,
          );
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
      (Icons.hiking, l10n.accountRestoredJourney, journey),
      (
        Icons.auto_stories,
        l10n.conVoltaLessons,
        l10n.accountRestoredLessonsValue(lessons),
      ),
      (
        Icons.timer,
        l10n.accountRestoredSpeedrun,
        l10n.accountRestoredSpeedrunValue(summary.speedruns.length),
      ),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) next();
      },
      child: Scaffold(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.conVoltaText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!state.ready)
                const SkeletonList()
              else
                Material(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppShape.large),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
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
                l10n.conVoltaMerged,
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
              onPressed: next,
              child: Text(l10n.accountRestoredContinue),
            ),
          ],
        ),
      ),
    );
  }
}
