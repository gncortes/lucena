import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/keys/update_keys.dart';
import '../../core/l10n/l10n.dart';
import '../view_models/update_cubit.dart';
import 'update_body.dart';

/// "Versão nova do Lucena" (E1.32 §3): tela cheia, só sobre a home. "Agora
/// não" e o voltar do Android voltam à home; "Atualizar" baixa em segundo
/// plano e, no fim, vira "Pronto. Reiniciar o Lucena".
class UpdateRecommendedScreen extends StatelessWidget {
  const UpdateRecommendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<UpdateCubit>();
    return BlocBuilder<UpdateCubit, UpdateState>(
      builder: (context, state) => Scaffold(
        key: UpdateKeys.recommendedScreen,
        body: UpdateBody(
          title: l10n.updateRecommendedTitle,
          body: l10n.updateRecommendedBody,
          actions: [
            if (state.ready)
              FilledButton(
                key: UpdateKeys.restart,
                onPressed: cubit.restart,
                child: Text(l10n.updateReadyRestart),
              )
            else
              FilledButton(
                key: UpdateKeys.recommendedAction,
                onPressed: state.downloading ? null : cubit.updateRecommended,
                child: Text(l10n.updateRecommendedAction),
              ),
            TextButton(
              key: UpdateKeys.recommendedLater,
              onPressed: () {
                cubit.recommendedLater();
                _close(context);
              },
              child: Text(l10n.updateRecommendedLater),
            ),
          ],
        ),
      ),
    );
  }

  static void _close(BuildContext context) {
    if (context.canPop()) return context.pop();
    context.go(Routes.home);
  }
}
