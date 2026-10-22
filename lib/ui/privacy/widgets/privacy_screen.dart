import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/keys/privacy_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../profile/widgets/profile_rows.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/privacy_cubit.dart';

/// Privacidade e anúncios (canvas `PropV1AnuncioPrivacidade` e
/// `PropV1AnuncioRemovido`). "Apagar minha conta" fecha a tela com `true`:
/// o Perfil abre o diálogo de apagar.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<PrivacyCubit>().state;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      key: PrivacyKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          if (state.adFree)
            _InfoCard(
              key: PrivacyKeys.adFreeCard,
              icon: Icons.hide_source,
              title: l10n.privacyAdFreeTitle,
              text: l10n.privacyAdFreeText,
            )
          else
            _InfoCard(
              key: PrivacyKeys.freeCard,
              icon: Icons.campaign,
              title: l10n.privacyFreeTitle,
              text: l10n.privacyFreeText,
            ),
          const SizedBox(height: AppSpacing.lg),
          ProfileRowGroup(
            children: [
              if (state.showsAdChoices)
                ProfileRow(
                  key: PrivacyKeys.adChoices,
                  icon: Icons.campaign,
                  title: l10n.privacyAdChoices,
                  value: l10n.privacyAdChoicesValue,
                  onTap: context.read<PrivacyCubit>().openAdChoices,
                ),
              ProfileRow(
                key: PrivacyKeys.policy,
                icon: Icons.description,
                title: l10n.privacyPolicy,
                value: l10n.privacyPolicyValue,
                onTap: () => launchUrl(
                  AboutScreen.privacyFor(language),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              if (state.hasAccount)
                ProfileRow(
                  key: PrivacyKeys.deleteAccount,
                  icon: Icons.delete,
                  title: l10n.privacyDelete,
                  value: l10n.privacyDeleteValue,
                  onTap: () => context.pop(true),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
    super.key,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppShape.large),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.insideCard),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(AppShape.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: colors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
