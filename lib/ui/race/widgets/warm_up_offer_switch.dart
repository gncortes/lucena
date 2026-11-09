import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/view_models/race.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/warm_up_offer_cubit.dart';

/// Em Configurações › Partida: liga e desliga a oferta de aquecimento antes
/// do desafio (a mesma de "Não perguntar de novo" na folha).
class WarmUpOfferSwitch extends StatelessWidget {
  const WarmUpOfferSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => createWarmUpOfferCubit(context)..load(),
      child: BlocBuilder<WarmUpOfferCubit, bool>(
        builder: (context, value) {
          final l10n = context.l10n;
          return SwitchListTile(
            key: SettingsKeys.warmUpSwitch,
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: Text(l10n.settingsWarmUp),
            subtitle: Text(l10n.settingsWarmUpHint),
            value: value,
            onChanged: (value) =>
                context.read<WarmUpOfferCubit>().setOffers(value: value),
          );
        },
      ),
    );
  }
}
