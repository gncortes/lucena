import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../alerts/view_models/alerts_cubit.dart';
import '../../core/keys/region_keys.dart';
import '../../core/l10n/countries.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../profile/view_models/profile_cubit.dart';
import '../../profile/widgets/profile_rows.dart';

/// "Seu país" (canvas `PropV1ContaPais`): busca, o país do celular em cima e
/// todos os outros em ordem alfabética, cada um com a bandeira. Escolher grava,
/// reinscreve os avisos de torneio e volta.
class CountryScreen extends StatefulWidget {
  const CountryScreen({super.key});

  @override
  State<CountryScreen> createState() => _CountryScreenState();
}

class _CountryScreenState extends State<CountryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(String code) async {
    final navigator = Navigator.of(context);
    final alerts = context.read<AlertsCubit>();
    await context.read<ProfileCubit>().setCountry(code);
    await alerts.regionChanged();
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profile = context.read<ProfileCubit>();
    final selected = context.select((ProfileCubit c) => c.state?.country);
    final phone = profile.phoneCountry;
    final query = _search.text.trim();
    final others = [
      for (final country in Countries.search(l10n, query))
        if (query.isNotEmpty || country.key != phone) country,
    ];
    final showPhone = query.isEmpty && phone != null;
    return Scaffold(
      key: RegionKeys.countryScreen,
      appBar: LucenaAppBar(title: Text(l10n.countryTitle)),
      body: ListView(
        padding: scrollPadding(context, left: 16, right: 16),
        children: [
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: RegionKeys.countrySearch,
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l10n.countrySearch,
              hintText: l10n.countrySearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          if (showPhone) ...[
            SectionTitle(l10n.countryFromPhone, inset: AppSpacing.xs),
            ProfileRowGroup(
              children: [
                _CountryRow(
                  code: phone,
                  note: l10n.countryFromPhoneNote,
                  selected: selected == phone,
                  onTap: () => _pick(phone),
                ),
              ],
            ),
          ],
          SectionTitle(l10n.countryAll, inset: AppSpacing.xs),
          if (others.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(
                l10n.countryNotFound,
                key: RegionKeys.countryNotFound,
              ),
            )
          else
            ProfileRowGroup(
              children: [
                for (final country in others)
                  _CountryRow(
                    code: country.key,
                    selected: selected == country.key,
                    onTap: () => _pick(country.key),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.code,
    required this.selected,
    required this.onTap,
    this.note,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = this.note;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      child: InkWell(
        key: RegionKeys.countryOption(code),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs + 2,
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(
                    Countries.flag(code),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Countries.name(context.l10n, code),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : null,
                          color: selected ? colors.primary : null,
                        ),
                      ),
                      if (note != null)
                        Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle,
                    size: AppIconSize.standard,
                    color: colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
