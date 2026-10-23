import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/update_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/update_cubit.dart';
import 'update_body.dart';

/// "Atualize o Lucena" (E1.32 §3): por cima de tudo, sem voltar. Ao voltar ao
/// app (da Play, talvez já atualizado), confere de novo.
class UpdateRequiredScreen extends StatefulWidget {
  const UpdateRequiredScreen({super.key});

  @override
  State<UpdateRequiredScreen> createState() => _UpdateRequiredScreenState();
}

class _UpdateRequiredScreenState extends State<UpdateRequiredScreen> {
  late final AppLifecycleListener _listener = AppLifecycleListener(
    onResume: () => context.read<UpdateCubit>().check(),
  );

  @override
  void initState() {
    super.initState();
    _listener;
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      child: Scaffold(
        key: UpdateKeys.requiredScreen,
        body: UpdateBody(
          title: l10n.updateRequiredTitle,
          body: l10n.updateRequiredBody,
          actions: [
            FilledButton.icon(
              key: UpdateKeys.requiredAction,
              onPressed: () => context.read<UpdateCubit>().openStore(),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.updateRequiredAction),
            ),
          ],
        ),
      ),
    );
  }
}
