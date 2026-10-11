import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/dependencies.dart';
import '../../../domain/models/user_profile.dart';
import '../../../routing/routes.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/rating_level_ui.dart';

/// O menu principal das Configurações: o perfil e os grupos (aparência,
/// partida, som), cada um com a sua tela, e o "Sobre".
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.version = appVersion});

  /// A versão do app, no rodapé, para quem relata um problema. Vazia (build
  /// local, sem versão): não aparece.
  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.select((ProfileCubit cubit) => cubit.state);
    return Scaffold(
      key: SettingsKeys.screen,
      appBar: AppBar(title: Text(l10n.settingsTitle, key: SettingsKeys.title)),
      body: ListView(
        padding: scrollPadding(context),
        children: [
          ListTile(
            key: SettingsKeys.profileTile,
            leading: const Icon(Icons.person_outline),
            title: Text(l10n.settingsProfile),
            subtitle: Text(
              profile == null ? '' : _profileSummary(context, profile),
              key: SettingsKeys.profileValue,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.settingsProfile),
          ),
          const Divider(indent: 16, endIndent: 16),
          _Group(
            tileKey: SettingsKeys.appearanceTile,
            icon: Icons.palette_outlined,
            title: l10n.settingsAppearance,
            hint: l10n.settingsAppearanceHint,
            route: Routes.settingsAppearance,
          ),
          _Group(
            tileKey: SettingsKeys.gameTile,
            icon: Icons.sports_esports_outlined,
            title: l10n.settingsGame,
            hint: l10n.settingsGameHint,
            route: Routes.settingsGame,
          ),
          _Group(
            tileKey: SettingsKeys.soundTile,
            icon: Icons.volume_up_outlined,
            title: l10n.settingsSoundGroup,
            hint: l10n.settingsSoundGroupHint,
            route: Routes.settingsSound,
          ),
          const Divider(indent: 16, endIndent: 16),
          _Group(
            tileKey: SettingsKeys.aboutTile,
            icon: Icons.info_outline,
            title: l10n.settingsAbout,
            hint: l10n.settingsAboutHint,
            route: Routes.settingsAbout,
          ),
          // Só em build de desenvolvimento e de teste.
          if (showsDevTools)
            ListTile(
              key: SettingsKeys.maiaDebugTile,
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.maiaDebugTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Routes.settingsMaia),
            ),
          if (version.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Text(
                l10n.homeVersion(version),
                key: SettingsKeys.version,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// "Apelido · faixa", com o apelido padrão quando o jogador não escolheu um.
  String _profileSummary(BuildContext context, UserProfile profile) {
    final nickname = profile.nickname.isEmpty
        ? context.l10n.profileNicknameDefault
        : profile.nickname;
    return '$nickname · ${profile.level.name(context.l10n)}';
  }
}

/// Um grupo do menu: abre a tela dele.
class _Group extends StatelessWidget {
  const _Group({
    required this.tileKey,
    required this.icon,
    required this.title,
    required this.hint,
    required this.route,
  });

  final Key tileKey;
  final IconData icon;
  final String title;
  final String hint;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    );
  }
}
