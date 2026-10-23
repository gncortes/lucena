import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../routing/routes.dart';
import '../../core/keys/daily_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../view_models/daily_game_cubit.dart';
import 'daily_crowd_card.dart';

/// O fim da partida do final do dia: o "quantos acertaram" e, embaixo, jogar
/// de novo (sem mudar o resultado, que é o da primeira tentativa) ou ver o
/// resultado.
class DailyEndBar extends StatelessWidget {
  const DailyEndBar({required this.onAgain, super.key});

  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          child: DailyCrowdCard(),
        ),
        ActionsFooter(
          children: [
            OutlinedButton.icon(
              key: DailyKeys.playAgain,
              onPressed: onAgain,
              icon: const Icon(Icons.replay),
              label: Text(l10n.featuredPlayAgain),
            ),
            FilledButton.icon(
              key: DailyKeys.openResult,
              onPressed: () => unawaited(_open(context)),
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.dailyOpenResult),
            ),
          ],
        ),
      ],
    );
  }

  // O resultado lê a primeira tentativa gravada: espera a gravação.
  Future<void> _open(BuildContext context) async {
    final daily = context.read<DailyGameCubit>();
    await daily.settle();
    if (!context.mounted) return;
    unawaited(context.push(Routes.dailyResultOf(daily.date)));
  }
}
