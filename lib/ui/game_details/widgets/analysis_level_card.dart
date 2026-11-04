import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/game_details_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/sheet_header.dart';
import '../view_models/game_details_cubit.dart';
import '../../core/motion/barra_que_enche.dart';

/// O nível da análise da partida (canvas `CompNivelAnalise`): sem análise,
/// com o texto e o botão "Analisar"; a rápida, com o botão de analisar a
/// fundo; a análise a fundo rodando, com o progresso; e a feita, média ou
/// profunda. O botão de aprofundar abre a folha de profundidade.
class AnalysisLevelCard extends StatelessWidget {
  const AnalysisLevelCard({required this.state, super.key});

  final GameDetailsState state;

  /// O tempo que falta, em segundos, pelo orçamento do peso em análise.
  static int secondsLeft(GameDetailsState state) {
    final total = state.moves.length;
    final done = (state.reviewProgress * total).round();
    final budget = GameDetailsCubit.budgets[state.reviewWeight];
    return math
        .max(1, ((total - done) * budget.time.inMilliseconds / 1000))
        .ceil();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final review = state.review;
    final total = state.moves.length;
    final done = (state.reviewProgress * total).round();
    final deepening = state.reviewing && state.reviewWeight >= 2;

    final IconData icon;
    final Color iconColor;
    final String title;
    final String text;
    Widget? action;
    Widget? progress;
    var background = colors.surfaceContainerHigh;

    if (state.reviewing) {
      icon = Icons.hourglass_top;
      iconColor = colors.primary;
      title = deepening
          ? l10n.partidaNivelAnalisando
          : l10n.partidaNivelAnalisandoGeral;
      text = l10n.partidaNivelProgresso(
        math.min(done + 1, total),
        total,
        secondsLeft(state),
      );
      progress = BarraQueEnche(valor: state.reviewProgress);
      background = colors.secondaryContainer;
    } else if (review == null) {
      // Partida de antes das análises automáticas (H-PAR-17).
      icon = Icons.insights;
      iconColor = colors.primary;
      title = l10n.partidaNivelNenhuma;
      text = l10n.partidaAnaliseAntiga;
      action = FilledButton(
        key: GameDetailsKeys.oldAnalysisButton,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kButtonHeight),
        ),
        onPressed: state.moves.isEmpty
            ? null
            : () => context.read<GameDetailsCubit>().review(
                speed: ReviewSpeed.quick,
              ),
        child: OneLine(l10n.partidaAnaliseAnalisar),
      );
    } else if (review.depth <
        GameDetailsCubit.reviewWeights[ReviewSpeed.medium]!) {
      icon = Icons.bolt;
      iconColor = colors.primary;
      title = l10n.partidaNivelRapida;
      text = l10n.partidaNivelRapidaTexto;
      action = FilledButton.tonalIcon(
        key: GameDetailsKeys.levelDeepen,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(kButtonHeight),
        ),
        onPressed: state.moves.isEmpty ? null : () => showDepthSheet(context),
        icon: const Icon(Icons.search, size: AppIconSize.button),
        label: OneLine(l10n.partidaNivelAprofundar),
      );
    } else {
      final medium =
          review.depth < GameDetailsCubit.reviewWeights[ReviewSpeed.deep]!;
      icon = Icons.verified;
      iconColor = colors.primary;
      title = medium ? l10n.partidaNivelMedia : l10n.partidaNivelProfunda;
      text = l10n.partidaNivelProfundidade(
        GameDetailsCubit.budgets[review.depth].depth,
      );
      if (medium) {
        action = FilledButton.tonalIcon(
          key: GameDetailsKeys.levelDeepen,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(kButtonHeight),
          ),
          onPressed: () => showDepthSheet(context),
          icon: const Icon(Icons.search, size: AppIconSize.button),
          label: OneLine(l10n.partidaNivelAprofundar),
        );
      }
    }

    return DecoratedBox(
      key: GameDetailsKeys.levelCard,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppShape.medium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          key: state.reviewing ? GameDetailsKeys.reviewProgress : null,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleSmall),
                      Text(
                        text,
                        key: review == null && !state.reviewing
                            ? GameDetailsKeys.oldAnalysis
                            : null,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              progress,
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

/// A folha "Analisar a fundo": a Média ou a Profunda (a recomendada, já
/// escolhida) e o botão que começa a análise, que segue rodando sem prender
/// a tela.
Future<void> showDepthSheet(BuildContext context) {
  final cubit = context.read<GameDetailsCubit>();
  return showLucenaSheet<void>(
    context,
    sheetKey: GameDetailsKeys.depthSheet,
    closeKey: GameDetailsKeys.depthSheetClose,
    builder: (sheet) => SafeArea(
      top: false,
      child: _DepthSheet(
        onAnalyse: (speed) {
          Navigator.of(sheet).pop();
          cubit.review(speed: speed);
        },
      ),
    ),
  );
}

class _DepthSheet extends StatefulWidget {
  const _DepthSheet({required this.onAnalyse});

  final void Function(ReviewSpeed speed) onAnalyse;

  @override
  State<_DepthSheet> createState() => _DepthSheetState();
}

class _DepthSheetState extends State<_DepthSheet> {
  ReviewSpeed _speed = ReviewSpeed.deep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (
        ReviewSpeed.medium,
        GameDetailsKeys.depthMedium,
        l10n.partidaProfundidadeMedia,
        l10n.partidaProfundidadeMediaTexto,
      ),
      (
        ReviewSpeed.deep,
        GameDetailsKeys.depthDeep,
        l10n.partidaProfundidadeProfunda,
        l10n.partidaProfundidadeProfundaTexto,
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(
          title: l10n.partidaNivelAprofundar,
          hint: l10n.partidaProfundidadeDica,
        ),
        RadioGroup<ReviewSpeed>(
          groupValue: _speed,
          onChanged: (value) => setState(() => _speed = value ?? _speed),
          child: Column(
            children: [
              for (final (speed, key, title, subtitle) in options)
                RadioListTile<ReviewSpeed>(
                  key: key,
                  value: speed,
                  title: Text(title),
                  subtitle: Text(subtitle),
                ),
            ],
          ),
        ),
        ActionsFooter(
          children: [
            FilledButton.icon(
              key: GameDetailsKeys.depthConfirm,
              onPressed: () => widget.onAnalyse(_speed),
              icon: const Icon(Icons.search),
              label: OneLine(l10n.partidaAnaliseAnalisar),
            ),
          ],
        ),
      ],
    );
  }
}
