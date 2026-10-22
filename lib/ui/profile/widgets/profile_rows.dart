import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_language.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../settings/view_models/settings_cubit.dart';

/// O grupo branco de linhas do Perfil e de "Seus dados" (canvas
/// `CompOpcaoLista`, 64 de altura).
class ProfileRowGroup extends StatelessWidget {
  const ProfileRowGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppShape.large),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// Uma linha do grupo: ícone, título e valor. Sem [onTap], só mostra.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value),
    trailing: onTap == null ? null : const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

/// O nome do país [code] (região do celular), ou "Não informado".
String profileCountryName(AppLocalizations l10n, String? code) =>
    code == null ? l10n.profileCountryNone : l10n.featuredCountry(code);

/// O idioma escolhido nas Configurações, no próprio idioma.
String profileLanguageName(BuildContext context) {
  final code = context.select(
    (SettingsCubit cubit) => cubit.state?.languageCode,
  );
  return AppLanguage.fromCode(code)?.nativeName ??
      context.l10n.settingsLanguageSystem;
}
