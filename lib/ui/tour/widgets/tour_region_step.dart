import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/brazil_cities.dart';
import '../../../domain/models/brazil_states.dart';
import '../../core/keys/tour_keys.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../region/widgets/region_sheet.dart' show stateName;
import '../view_models/tour_cubit.dart';

/// O passo "Região" do tour (canvas `PropV1AbEstRegiao`): país, estado e
/// cidade, com três linhas do que isso dá. A lista é local: nada de rede nem
/// de localização. Escolher só muda o rascunho; "Continuar" grava.
class TourRegionStep extends StatelessWidget {
  const TourRegionStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TourCubit>();
    final state = context.watch<TourCubit>().state;
    final country = state.country;
    final regionState = state.regionState;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            key: TourKeys.regionCountry,
            label: l10n.tourRegionCountry,
            value: country == null ? null : Countries.name(l10n, country),
            help: state.countryFromPhone ? l10n.tourRegionCountryHelp : null,
            onTap: () async {
              final picked = await _pick(
                context,
                title: l10n.tourRegionCountry,
                options: [
                  for (final entry in Countries.all(l10n))
                    _Option(entry.key, entry.value),
                ],
                selected: country,
                emptyText: l10n.countryNotFound,
              );
              if (picked != null) cubit.setRegionCountry(picked);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            key: TourKeys.regionState,
            label: l10n.tourRegionState,
            value: stateName(country: country, state: regionState),
            enabled: country != null,
            onTap: () async {
              final brazil = country == BrazilStates.country;
              final picked = await _pick(
                context,
                title: l10n.tourRegionStateTitle,
                options: [
                  if (brazil)
                    for (final entry in BrazilStates.names.entries)
                      _Option(entry.key, entry.value),
                ],
                selected: regionState,
                emptyText: l10n.tourRegionNoState,
                allowTyped: !brazil,
              );
              if (picked != null) cubit.setRegionState(picked);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(
            key: TourKeys.regionCity,
            label: l10n.tourRegionCity,
            value: state.regionCity,
            // A cidade espera o estado.
            enabled: regionState != null,
            onTap: () async {
              final picked = await _pick(
                context,
                title: l10n.tourRegionCityTitle,
                options: [
                  for (final city in BrazilCities.byState[regionState] ?? [])
                    _Option(city, city),
                ],
                selected: state.regionCity,
                emptyText: l10n.tourRegionNoCity,
                allowTyped: true,
              );
              if (picked != null) cubit.setRegionCity(picked);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _Benefit(
            icon: Icons.emoji_events,
            text: l10n.tourRegionBenefitCountry,
          ),
          _Benefit(icon: Icons.location_on, text: l10n.tourRegionBenefitLocal),
          _Benefit(
            icon: Icons.notifications,
            text: l10n.tourRegionBenefitAlerts,
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option(this.id, this.label);

  final String id;
  final String label;
}

/// Um campo de escolha (o toque abre a folha de busca).
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
    required this.onTap,
    this.help,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? value;
  final String? help;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = this.value;
    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              labelText: label,
              hintText: l10n.tourRegionChoose,
              helperText: help,
              enabled: enabled,
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: const Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              value ?? '',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: enabled ? null : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.standard, color: colors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// A folha com busca e a lista de [options]; devolve o id escolhido. Com
/// [allowTyped], o texto digitado também serve ("Usar “…”").
Future<String?> _pick(
  BuildContext context, {
  required String title,
  required List<_Option> options,
  required String? selected,
  required String emptyText,
  bool allowTyped = false,
}) => showLucenaSheet<String>(
  context,
  sheetKey: TourKeys.regionSheet,
  builder: (_) => _PickerSheet(
    title: title,
    options: options,
    selected: selected,
    emptyText: emptyText,
    allowTyped: allowTyped,
  ),
);

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.emptyText,
    required this.allowTyped,
  });

  final String title;
  final List<_Option> options;
  final String? selected;
  final String emptyText;
  final bool allowTyped;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final typed = _search.text.trim();
    final wanted = Countries.fold(typed);
    final shown = [
      for (final option in widget.options)
        if (wanted.isEmpty || Countries.fold(option.label).contains(wanted))
          option,
    ];
    final height = MediaQuery.sizeOf(context).height * 0.7;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: TextField(
                  key: TourKeys.regionSearch,
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l10n.tourRegionSearch,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView(
                  children: [
                    if (widget.allowTyped && typed.isNotEmpty)
                      _Row(
                        key: TourKeys.regionOption('typed'),
                        label: l10n.tourRegionUseTyped(typed),
                        selected: false,
                        onTap: () => Navigator.of(context).pop(typed),
                      ),
                    if (shown.isEmpty &&
                        !(widget.allowTyped && typed.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          widget.emptyText,
                          key: TourKeys.regionNone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    for (final option in shown)
                      _Row(
                        key: TourKeys.regionOption(option.id),
                        label: option.label,
                        selected: option.id == widget.selected,
                        onTap: () => Navigator.of(context).pop(option.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uma linha de 56 dp com o rádio no fim.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Semantics(
            selected: selected,
            inMutuallyExclusiveGroup: true,
            child: Row(
              children: [
                Expanded(child: Text(label)),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
