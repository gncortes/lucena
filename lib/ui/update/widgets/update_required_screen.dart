import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/update_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/busy_button.dart';
import '../../core/motion/entradas_vistas.dart';
import '../../core/widgets/load_error.dart';
import '../view_models/update_cubit.dart';
import 'update_body.dart';

/// "Atualização necessária" (E1.32 §3): por cima de tudo, sem voltar. Ao voltar ao
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
    final cubit = context.read<UpdateCubit>();
    return PopScope(
      canPop: false,
      child: BlocBuilder<UpdateCubit, UpdateState>(
        buildWhen: (a, b) => a.offline != b.offline,
        builder: (context, state) {
          if (state.offline) {
            return KeyedSubtree(
              key: UpdateKeys.requiredOfflineScreen,
              child: EntradaDaTela(
                id: 'PropV1AbEstAtualizarObrigatoriaSemRede',
                child: LoadErrorScreen(
                  kind: LoadErrorKind.offline,
                  message: l10n.updateOfflineMessage,
                  actionKey: UpdateKeys.requiredRetry,
                  onAction: cubit.retry,
                ),
              ),
            );
          }
          return Scaffold(
            key: UpdateKeys.requiredScreen,
            body: UpdateBody(
              title: l10n.updateRequiredTitle,
              body: l10n.updateRequiredBody,
              actions: [
                BusyButton(
                  buttonKey: UpdateKeys.requiredAction,
                  label: l10n.updateRequiredAction,
                  onPressed: cubit.openStore,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
