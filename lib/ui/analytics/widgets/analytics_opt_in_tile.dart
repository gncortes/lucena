import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/analytics/analytics_context.dart';
import '../../core/keys/analytics_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/analytics_opt_in_cubit.dart';

/// "Ajudar a melhorar o Lucena" (quadro `PropV1EventosPrivacidade`): a chave
/// das estatísticas, para a tela Privacidade e anúncios. Traz o próprio view
/// model.
class AnalyticsOptInTile extends StatelessWidget {
  const AnalyticsOptInTile({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => AnalyticsOptInCubit(context.analytics)..load(),
    child: const _OptInSwitch(),
  );
}

class _OptInSwitch extends StatelessWidget {
  const _OptInSwitch();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = context.watch<AnalyticsOptInCubit>().state;
    return SwitchListTile(
      key: AnalyticsKeys.optInSwitch,
      secondary: const Icon(Icons.insights),
      title: Text(l10n.analyticsOptInTitle),
      subtitle: Text(l10n.analyticsOptInBody),
      value: enabled ?? true,
      onChanged: enabled == null
          ? null
          : (value) => context.read<AnalyticsOptInCubit>().setEnabled(value),
    );
  }
}
