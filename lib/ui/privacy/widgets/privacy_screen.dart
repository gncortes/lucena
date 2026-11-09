import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/legal_document.dart';
import '../../../routing/routes.dart';
import '../../analytics/widgets/analytics_opt_in_tile.dart';
import '../../core/analytics/analytics_context.dart';
import '../../core/keys/privacy_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/open_link.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../../legal/widgets/legal_sheet.dart';
import '../../profile/widgets/account_delete_sheet.dart';
import '../../profile/widgets/profile_rows.dart';
import '../../settings/widgets/about_screen.dart';
import '../view_models/privacy_cubit.dart';
import 'data_export_sheet.dart';

/// Privacidade e dados (canvas `PropV1ContaPrivacidade` e
/// `PropV1ContaPrivacidadeRolado`, H-CON-20 e H-CON-24).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  /// O encarregado de dados (Política, seção 1).
  static final dataOfficer = Uri.parse('mailto:gncortes.apps@gmail.com');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PrivacyCubit>();
    final state = context.watch<PrivacyCubit>().state;
    if (state.failure case final failure?) {
      return LoadErrorScreen(
        kind: LoadErrorKind.fromFailure(failure),
        onAction: cubit.load,
        onBack: () =>
            context.canPop() ? context.pop() : context.go(Routes.home),
      );
    }
    final language = Localizations.localeOf(context).languageCode;
    final terms = AboutScreen.termsFor(language);
    final policy = AboutScreen.privacyFor(language);
    return Scaffold(
      key: PrivacyKeys.screen,
      appBar: LucenaAppBar(title: Text(l10n.privacyTitle)),
      body: ListView(
        padding: scrollPadding(
          context,
          left: AppSpacing.screen,
          top: AppSpacing.sm,
          right: AppSpacing.screen,
        ),
        children: [
          _InfoCard(
            key: PrivacyKeys.lgpdCard,
            icon: CanvasSymbols.shieldPerson,
            title: l10n.conPrivLgpdTitle,
            text: l10n.conPrivLgpdText,
          ),
          SectionTitle(l10n.conPrivSectionUse, inset: AppSpacing.xs),
          ProfileRowGroup(
            children: [
              // As estatísticas (E1.03); sem elas no build (F-Droid), nada.
              if (context.analytics.measures) const AnalyticsOptInTile(),
              // H-CON-24: só informa; não abre nada.
              ProfileRow(
                key: PrivacyKeys.ads,
                icon: Icons.campaign_outlined,
                title: l10n.conPrivAdsTitle,
                value: l10n.conPrivAdsText,
              ),
            ],
          ),
          SectionTitle(l10n.conPrivSectionPermissions, inset: AppSpacing.xs),
          const _PermissionsGroup(),
          SectionTitle(l10n.conPrivSectionData, inset: AppSpacing.xs),
          _DataGroup(state: state),
          SectionTitle(l10n.conPrivSectionDocuments, inset: AppSpacing.xs),
          _DocumentsGroup(terms: terms, policy: policy),
          if (state.hasAccount) ...[
            SectionTitle(l10n.conPrivSectionAccount, inset: AppSpacing.xs),
            ProfileRowGroup(
              children: [
                ProfileRow(
                  key: PrivacyKeys.deleteAccount,
                  icon: Icons.delete_outline,
                  title: l10n.privacyDelete,
                  value: l10n.privacyDeleteValue,
                  onTap: () => showAccountDeleteSheet(
                    context,
                    uid: state.account!.uid,
                    from: 'privacy',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// As permissões do aparelho, que abrem os ajustes do sistema.
class _PermissionsGroup extends StatelessWidget {
  const _PermissionsGroup();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PrivacyCubit>();
    return ProfileRowGroup(
      children: [
        ProfileRow(
          key: PrivacyKeys.notifications,
          icon: Icons.notifications_outlined,
          title: l10n.conPrivNotifications,
          value: l10n.conPrivNotificationsText,
          external: true,
          onTap: cubit.openNotifications,
        ),
        ProfileRow(
          key: PrivacyKeys.microphone,
          icon: Icons.mic_none,
          title: l10n.conPrivMicrophone,
          value: l10n.conPrivMicrophoneText,
          external: true,
          onTap: cubit.openMicrophone,
        ),
      ],
    );
  }
}

/// Os dados: baixar o que o app guarda e falar com o encarregado.
class _DataGroup extends StatelessWidget {
  const _DataGroup({required this.state});

  final PrivacyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProfileRowGroup(
      children: [
        if (state.account case final account?)
          ProfileRow(
            key: PrivacyKeys.download,
            icon: Icons.download,
            title: l10n.conPrivDownload,
            value: l10n.conPrivDownloadText,
            onTap: () => showDataExportSheet(context, uid: account.uid),
          ),
        ProfileRow(
          key: PrivacyKeys.talk,
          icon: Icons.mail_outline,
          title: l10n.conPrivTalk,
          value: l10n.conPrivTalkText,
          external: true,
          onTap: () => openLink(context, PrivacyScreen.dataOfficer),
        ),
      ],
    );
  }
}

/// Os documentos: os termos e a política de privacidade.
class _DocumentsGroup extends StatelessWidget {
  const _DocumentsGroup({required this.terms, required this.policy});

  final Uri terms;
  final Uri policy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ProfileRowGroup(
      children: [
        ProfileRow(
          key: PrivacyKeys.terms,
          icon: Icons.gavel,
          title: l10n.aboutTerms,
          value: shownAddress(terms),
          external: true,
          onTap: () => openLegal(context, LegalKind.terms, website: terms),
        ),
        ProfileRow(
          key: PrivacyKeys.policy,
          icon: Icons.policy_outlined,
          title: l10n.aboutPrivacy,
          value: shownAddress(policy),
          external: true,
          onTap: () => openLegal(context, LegalKind.privacy, website: policy),
        ),
      ],
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
                child: Icon(icon, fill: 1, color: colors.primary),
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
