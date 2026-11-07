import 'package:flutter/material.dart';
import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/legal_document.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/open_link.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../legal/widgets/legal_sheet.dart';

/// Sobre o Lucena: o site, o código aberto, as licenças, o tour e a versão.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.version = ''});

  /// A versão do app, para quem relata um problema. Vazia: não aparece.
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

  /// A Política de privacidade no site, no idioma de quem usa.
  static Uri privacyFor(String languageCode) =>
      websiteFor(languageCode).resolve(switch (languageCode) {
        'pt' => 'privacidade/',
        'es' => 'privacidad/',
        _ => 'privacy/',
      });

  /// Os Termos de uso no site, no idioma de quem usa.
  static Uri termsFor(String languageCode) =>
      websiteFor(languageCode).resolve(switch (languageCode) {
        'pt' => 'termos/',
        'es' => 'terminos/',
        _ => 'terms/',
      });

  /// O endereço como a linha mostra: sem `https://` e sem a barra do fim.
  static String shown(Uri uri) => shownAddress(uri);

  static final source = Uri.parse('https://github.com/gncortes/lucena');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final language = Localizations.localeOf(context).languageCode;
    return EntradaDaTela(
      id: 'PropV1LegalSobre',
      child: Scaffold(
        key: SettingsKeys.aboutScreen,
        appBar: LucenaAppBar(title: Text(l10n.settingsAbout)),
        body: ListView(
          padding: scrollPadding(context),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: EntradaEmCascata(
                montar: (itens) => Column(children: itens),
                itens: [
                  // O mascote do app: o ícone B2, com o fundo escuro (a figura
                  // clara sumiria no fundo da tela).
                  ItemDaCascata.selo(
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppShape.large),
                      child: Image.asset(
                        'assets/branding/mascote.png',
                        width: 96,
                        height: 96,
                      ),
                    ),
                  ),
                  ItemDaCascata.titulo(
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        l10n.appTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  ItemDaCascata.texto(
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        l10n.aboutTagline,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (version.isNotEmpty)
                    ItemDaCascata.texto(
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          l10n.homeVersion(version),
                          key: SettingsKeys.aboutVersion,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              key: SettingsKeys.aboutWebsite,
              leading: const Icon(Icons.public),
              title: Text(l10n.aboutWebsite),
              trailing: const Icon(Icons.open_in_new, size: AppIconSize.button),
              onTap: () => openLink(context, websiteFor(language)),
            ),
            ListTile(
              key: SettingsKeys.aboutSource,
              leading: const Icon(Icons.code),
              title: Text(l10n.aboutSource),
              subtitle: Text(l10n.aboutSourceHint),
              trailing: const Icon(Icons.open_in_new, size: AppIconSize.button),
              onTap: () => openLink(context, source),
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
              key: SettingsKeys.aboutPrivacy,
              leading: const Icon(Icons.policy_outlined),
              title: Text(l10n.aboutPrivacy),
              subtitle: Text(shown(privacyFor(language))),
              trailing: const Icon(Icons.open_in_new, size: AppIconSize.button),
              onTap: () => openLegal(
                context,
                LegalKind.privacy,
                website: privacyFor(language),
              ),
            ),
            ListTile(
              key: SettingsKeys.aboutTerms,
              leading: const Icon(Icons.gavel),
              title: Text(l10n.aboutTerms),
              subtitle: Text(shown(termsFor(language))),
              trailing: const Icon(Icons.open_in_new, size: AppIconSize.button),
              onTap: () => openLegal(
                context,
                LegalKind.terms,
                website: termsFor(language),
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
      ),
    );
  }
}
