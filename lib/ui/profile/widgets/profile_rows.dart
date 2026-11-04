import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/app_language.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
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
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppShape.large),
      side: const BorderSide(color: AppColors.cardOutline),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// Uma linha do grupo: ícone, título e valor (opcional). Sem [onTap], só
/// mostra. [external]: o toque sai do app (ajustes do sistema, e-mail): a
/// seta vira `open_in_new`.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.external = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final bool external;

  @override
  Widget build(BuildContext context) => ListTile(
    // CompOpcaoLista: 72 px com subtítulo, 56 sem.
    minTileHeight: value == null ? 56 : 72,
    leading: Icon(icon),
    title: Text(title),
    subtitle: value == null ? null : Text(value!),
    trailing: onTap == null
        ? null
        : Icon(external ? Icons.open_in_new : Icons.chevron_right),
    onTap: onTap,
  );
}

/// O nome do país [code] (região do celular), ou "Não informado".
String profileCountryName(AppLocalizations l10n, String? code) =>
    code == null ? l10n.profileCountryNone : Countries.name(l10n, code);

/// A bandeira e o nome do país [code], com "· veio do celular" quando é o
/// da região do celular ([phone]); ou "Não informado".
String profileCountryValue(
  AppLocalizations l10n,
  String? code, {
  String? phone,
}) {
  if (code == null) return l10n.profileCountryNone;
  final name = l10n.profileCountryValue(
    Countries.flag(code),
    Countries.name(l10n, code),
  );
  return code == phone ? l10n.accountCountryFromPhone(name) : name;
}

/// O idioma escolhido nas Configurações, no próprio idioma.
String profileLanguageName(BuildContext context) {
  final code = context.select(
    (SettingsCubit? cubit) => cubit?.state?.languageCode,
  );
  return AppLanguage.fromCode(code)?.nativeName ??
      context.l10n.settingsLanguageSystem;
}
