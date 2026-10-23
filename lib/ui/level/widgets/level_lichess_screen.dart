import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../core/keys/level_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/level_cubit.dart';
import 'level_ui.dart';

/// "Lichess conectado" (canvas `PropV1PerfilLichessConectado`): os ratings
/// lidos e "Usar esse rating". Com o rating provisório
/// (`PropV1PerfilLichessProvisorio`), o teste vem primeiro.
class LevelLichessScreen extends StatelessWidget {
  const LevelLichessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<LevelCubit>();
    return BlocBuilder<LevelCubit, LevelState>(
      builder: (context, state) {
        final lichess = state.lichess;
        final rating = state.lichessRating;
        if (lichess == null || rating == null) {
          return const Scaffold(key: LevelKeys.lichessScreen);
        }
        final provisional = lichess.main!.provisional;
        final success = AppColors.of(context).success;
        return Scaffold(
          key: LevelKeys.lichessScreen,
          appBar: LucenaAppBar(title: Text(l10n.levelLichessConnectedTitle)),
          body: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  l10n.levelLichessBack,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: AppIconSize.button,
                            color: success,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.levelConnectedAs(lichess.user),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      PlatformRatingsGrid(rating: lichess),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        provisional
                            ? l10n.levelProvisionalText
                            : levelStartsAt(context, state, lichess, rating),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TipBox(
                text: provisional
                    ? l10n.levelProvisionalTip(rating)
                    : l10n.levelLichessTip,
              ),
            ],
          ),
          bottomNavigationBar: ActionsFooter(
            stacked: true,
            children: provisional
                ? [
                    FilledButton(
                      key: LevelKeys.lichessTest,
                      onPressed: () => takeLevelTest(context, finish: true),
                      child: Text(l10n.levelTakeTest),
                    ),
                    TextButton(
                      key: LevelKeys.lichessUseDefault,
                      onPressed: cubit.useLichess,
                      child: Text(l10n.levelUseDefault(rating)),
                    ),
                  ]
                : [
                    FilledButton(
                      key: LevelKeys.lichessUse,
                      onPressed: cubit.useLichess,
                      child: Text(l10n.levelUseRating),
                    ),
                    const PreferTestButton(),
                  ],
          ),
        );
      },
    );
  }
}
