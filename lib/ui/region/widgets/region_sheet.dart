import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/alerts/region_prompt_repository.dart';
import '../../../domain/models/brazil_states.dart';
import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/keys/region_keys.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../profile/view_models/profile_cubit.dart';

/// Mostra a folha uma vez só, e só depois da primeira tentativa de um final em
/// destaque (nunca antes de jogar).
Future<void> askRegionOnce(BuildContext context) async {
  if (!await context.read<RegionPromptRepository>().pending()) return;
  if (!context.mounted) return;
  await showRegionSheet(context);
}

/// "Quer ver torneios perto de você?" (canvas `PropV1RetencaoRegiao`): estado
/// e cidade do país do perfil. No Brasil o estado é um dos 27 (a sigla vai no
/// tópico de torneios); nos outros países é texto livre. Salvar ou "Agora não"
/// marcam a folha como vista, para a lista de finais não perguntar de novo.
Future<void> showRegionSheet(BuildContext context) {
  final profile = context.read<ProfileCubit>();
  final alerts = context.read<AlertsCubit>();
  final prompt = context.read<RegionPromptRepository>();
  return showLucenaSheet<void>(
    context,
    sheetKey: RegionKeys.sheet,
    builder: (sheet) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: _RegionSheet(
          country: profile.state?.country,
          phoneCountry: profile.phoneCountry,
          state: profile.state?.state,
          city: profile.state?.city,
          onSave: (state, city) async {
            Navigator.of(sheet).pop();
            await prompt.done();
            await profile.setRegion(state: state, city: city);
            await alerts.regionChanged();
          },
          onNotNow: () {
            Navigator.of(sheet).pop();
            prompt.done();
          },
        ),
      ),
    ),
  );
}

/// O estado e a cidade para mostrar ("Paraná · Curitiba"), ou nulo sem estado
/// nem cidade.
String? regionLabel(
  AppLocalizations l10n, {
  String? country,
  String? state,
  String? city,
}) {
  final name = stateName(country: country, state: state);
  if (name != null && city != null) {
    return l10n.profileRegionValue(name, city);
  }
  return name ?? city;
}

/// O nome do estado: no Brasil, da sigla; nos outros, como foi digitado.
String? stateName({String? country, String? state}) =>
    country == BrazilStates.country
    ? BrazilStates.names[state] ?? state
    : state;

class _RegionSheet extends StatefulWidget {
  const _RegionSheet({
    required this.country,
    required this.phoneCountry,
    required this.state,
    required this.city,
    required this.onSave,
    required this.onNotNow,
  });

  final String? country;
  final String? phoneCountry;
  final String? state;
  final String? city;
  final void Function(String? state, String? city) onSave;
  final VoidCallback onNotNow;

  @override
  State<_RegionSheet> createState() => _RegionSheetState();
}

class _RegionSheetState extends State<_RegionSheet> {
  late final _state = TextEditingController(
    text: _brazil ? null : widget.state,
  );
  late final _city = TextEditingController(text: widget.city);
  late String? _uf = _brazil && BrazilStates.names.containsKey(widget.state)
      ? widget.state
      : null;

  bool get _brazil => widget.country == BrazilStates.country;

  @override
  void dispose() {
    _state.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = widget.country;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppShape.large),
                    ),
                    child: SizedBox.square(
                      dimension: 56,
                      child: Icon(
                        Icons.location_on,
                        size: AppIconSize.large,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.regionSheetTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.regionSheetText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_brazil)
                  LayoutBuilder(
                    builder: (context, constraints) => DropdownMenu<String>(
                      key: RegionKeys.state,
                      width: constraints.maxWidth,
                      initialSelection: _uf,
                      label: Text(l10n.regionState),
                      leadingIcon: const Icon(Icons.location_on_outlined),
                      enableFilter: true,
                      requestFocusOnTap: true,
                      menuHeight: 320,
                      onSelected: (uf) => setState(() => _uf = uf),
                      dropdownMenuEntries: [
                        for (final entry in BrazilStates.names.entries)
                          DropdownMenuEntry(
                            value: entry.key,
                            label: entry.value,
                          ),
                      ],
                    ),
                  )
                else
                  TextField(
                    key: RegionKeys.state,
                    controller: _state,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.regionState,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: RegionKeys.city,
                  controller: _city,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.regionCity,
                    prefixIcon: const Icon(Icons.location_city),
                  ),
                ),
                if (country != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    country == widget.phoneCountry
                        ? l10n.regionCountryNote(Countries.name(l10n, country))
                        : l10n.regionCountryNoteChosen(
                            Countries.name(l10n, country),
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ActionsFooter(
            stacked: true,
            children: [
              FilledButton(
                key: RegionKeys.save,
                onPressed: () =>
                    widget.onSave(_brazil ? _uf : _state.text, _city.text),
                child: Text(l10n.regionSave),
              ),
              TextButton(
                key: RegionKeys.notNow,
                onPressed: widget.onNotNow,
                child: Text(l10n.regionNotNow),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
