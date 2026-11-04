import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/frentes/d2_routes.dart';
import '../../core/keys/purchase_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/widgets/character_avatar.dart';
import '../view_models/pilares_before_home_cubit.dart';

/// A oferta antes do Início (H-VEN-15, quadro `PropV2OfertaAntesInicioFolha`):
/// folha sobre o Início, com o X à direita. O X, o voltar e o toque fora
/// fecham e deixam o Início; "Conhecer o plano" abre a venda do plano.
class PilaresBeforeHomeSheet extends StatelessWidget {
  const PilaresBeforeHomeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final teacher = context.watch<PilaresBeforeHomeCubit>().state;
    final cubit = context.read<PilaresBeforeHomeCubit>();
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) cubit.dismissed();
      },
      child: SafeArea(
        key: PurchaseKeys.beforeHomeSheet,
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: IconButton(
                  key: PurchaseKeys.beforeHomeClose,
                  tooltip: l10n.venBeforeHomeClose,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xl,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: AppSpacing.sm,
                    children: [
                      SizedBox.square(
                        dimension: CharacterAvatar.versus,
                        child: teacher == null
                            ? null
                            : CharacterAvatar(
                                character: teacher,
                                size: CharacterAvatar.versus,
                                radius: AppSpacing.xl,
                              ),
                      ),
                      Text(
                        l10n.venCourseName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.venBeforeHomeTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          height: 32 / 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    spacing: AppSpacing.lg,
                    children: [
                      _Item(
                        icon: Icons.edit_calendar,
                        title: l10n.venBeforeHomePlan,
                      ),
                      _Item(
                        icon: Icons.task_alt,
                        title: l10n.venBenefitGoals,
                        text: l10n.venBeforeHomeGoalsText,
                      ),
                      _Item(
                        icon: Icons.menu_book,
                        title: l10n.venBenefitChapters,
                        text: l10n.venBeforeHomeChaptersText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ActionsFooter(
              stacked: true,
              children: [
                BusyButton(
                  buttonKey: PurchaseKeys.beforeHomeLearn,
                  label: l10n.venBeforeHomeLearn,
                  onPressed: () {
                    cubit.learn();
                    final router = GoRouter.of(context);
                    Navigator.of(context).pop();
                    router.push(D2Paths.pilaresPlan);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, this.text});

  final IconData icon;
  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      spacing: AppSpacing.lg,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Icon(icon, size: AppIconSize.standard, color: colors.primary),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (text != null)
                Text(
                  text!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    letterSpacing: 0,
                    color: colors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
