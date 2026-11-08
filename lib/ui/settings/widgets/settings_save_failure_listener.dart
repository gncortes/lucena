import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/settings_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/lucena_snack_bar.dart';
import '../view_models/settings_cubit.dart';

/// Avisa, em qualquer tela, quando uma preferência não foi gravada (Gap 1 dos
/// Ajustes). O valor na tela já voltou ao que está no disco; o aviso só conta.
/// Fica no `builder` do app, abaixo do `ScaffoldMessenger`.
class SettingsSaveFailureListener extends StatefulWidget {
  const SettingsSaveFailureListener({super.key, required this.child});

  final Widget child;

  @override
  State<SettingsSaveFailureListener> createState() =>
      _SettingsSaveFailureListenerState();
}

class _SettingsSaveFailureListenerState
    extends State<SettingsSaveFailureListener> {
  StreamSubscription<void>? _failures;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_failures?.cancel());
    _failures = context.read<SettingsCubit>().saveFailures.listen((_) {
      if (!mounted) return;
      showLucenaSnackBar(
        context,
        context.l10n.ajuSaveError,
        icon: Icons.error_outline,
        key: SettingsKeys.saveFailure,
      );
    });
  }

  @override
  void dispose() {
    unawaited(_failures?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
