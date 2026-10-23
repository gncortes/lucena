import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/race/race_repository.dart';
import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';

/// Em Configurações › Partida: liga e desliga a oferta de aquecimento antes
/// do desafio (a mesma de "Não perguntar de novo" na folha).
class WarmUpOfferSwitch extends StatefulWidget {
  const WarmUpOfferSwitch({super.key});

  @override
  State<WarmUpOfferSwitch> createState() => _WarmUpOfferSwitchState();
}

class _WarmUpOfferSwitchState extends State<WarmUpOfferSwitch> {
  bool _value = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await context.read<RaceRepository>().offersWarmUp();
    if (mounted) setState(() => _value = value);
  }

  Future<void> _set(bool value) async {
    setState(() => _value = value);
    await context.read<RaceRepository>().setOffersWarmUp(value: value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SwitchListTile(
      key: SettingsKeys.warmUpSwitch,
      secondary: const Icon(Icons.local_fire_department_outlined),
      title: Text(l10n.settingsWarmUp),
      subtitle: Text(l10n.settingsWarmUpHint),
      value: _value,
      onChanged: _set,
    );
  }
}
