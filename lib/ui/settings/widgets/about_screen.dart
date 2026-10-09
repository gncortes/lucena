import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/dependencies.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/scroll_padding.dart';

/// Sobre o Lucena: o site, o código aberto, as licenças, o tour e a versão.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.version = appVersion});

  /// A versão do app, para quem relata um problema. Vazia (build local, sem
  /// versão): não aparece.
  final String version;

  /// O site do app, no idioma de quem usa (pt na raiz; en e es com prefixo;
  /// os outros idiomas vão para o inglês).
  static Uri websiteFor(String languageCode) {
    const base = 'https://gncortes.github.io/lucena/';
    return Uri.parse(switch (languageCode) {
      'pt' => base,
      'es' => '${base}es/',
      _ => '${base}en/',
    });
  }

  static final source = Uri.parse('https://github.com/gncortes/lucena');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      key: SettingsKeys.aboutScreen,
      appBar: AppBar(title: Text(l10n.settingsAbout)),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                // O mascote do app, na versão do tema.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppShape.large),
                  child: Image.asset(
                    theme.brightness == Brightness.dark
                        ? 'assets/branding/mascot_dark.png'
                        : 'assets/branding/mascot_light.png',
                    width: 96,
                    height: 96,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.appTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.aboutTagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                if (version.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.homeVersion(version),
                    key: SettingsKeys.aboutVersion,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ListTile(
            key: SettingsKeys.aboutWebsite,
            leading: const Icon(Icons.public),
            title: Text(l10n.aboutWebsite),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => launchUrl(
              websiteFor(language),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            key: SettingsKeys.aboutSource,
            leading: const Icon(Icons.code),
            title: Text(l10n.aboutSource),
            subtitle: Text(l10n.aboutSourceHint),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                launchUrl(source, mode: LaunchMode.externalApplication),
          ),
          ListTile(
            key: SettingsKeys.aboutLicenses,
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.aboutLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: version.isEmpty ? null : version,
            ),
          ),
          ListTile(
            key: SettingsKeys.tourTile,
            leading: const Icon(Icons.tour_outlined),
            title: Text(l10n.settingsTour),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.tour),
          ),
        ],
      ),
    );
  }
}
