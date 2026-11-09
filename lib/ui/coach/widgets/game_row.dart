import 'package:flutter/material.dart';

import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/coach/coach_rules.dart';
import '../../core/keys/coach_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_text.dart';
import 'coach_texts.dart';

/// Uma partida nas listas do Treinador (Hoje, Partidas e o início): o
/// quadrado do resultado, o adversário, ritmo · cor · quando e o estado.
class GameRow extends StatelessWidget {
  const GameRow({
    required this.game,
    required this.currentTime,
    required this.grant,
    this.onTap,
    this.showSummary = false,
    this.showStatus = true,
    this.showArrow = true,
    super.key,
  });

  final CoachGame game;
  final DateTime currentTime;
  final bool grant;
  final VoidCallback? onTap;

  /// Na terceira linha, a frase do resumo da partida (cartão da aba Hoje)
  /// no lugar do estado, quando a análise está pronta e aberta.
  final bool showSummary;

  /// Terceira linha (resumo ou estado). No resumo da partida some: só nome e
  /// detalhe (canvas `DPartida`).
  final bool showStatus;

  /// A seta à direita: some quando o cartão não leva a lugar nenhum (início e
  /// resumo da partida).
  final bool showArrow;

  static const minHeight = 64.0;
  static const square = 36.0;

  /// O máximo de linhas do detalhe (ritmo, cor, abertura e quando).
  static const detailMaxLines = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final p = game;
    final opened = CoachRules.opens(p, grant: grant);
    final opponent = p.opponent.rating == null
        ? p.opponent.name
        : '${p.opponent.name} (${p.opponent.rating})';
    final timeControlColor = [
      if (p.timeControl != null)
        [?p.cadence, context.timeControl(p.timeControl!)].join(' ')
      else
        ?p.cadence,
      context.color(p.color),
    ];
    final when_ = context.when_(p.moveAt, currentTime);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return InkWell(
      key: CoachKeys.game(p.id),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              _Result(result: p.result),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            opponent,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                        if (p.status == GameStatus.newGame) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    _Detail(
                      timeControlColor: timeControlColor,
                      opening: p.opening?.name,
                      when_: when_,
                      style: muted,
                    ),
                    if (showStatus)
                      if (showSummary &&
                          opened &&
                          p.ready &&
                          (p.summary ?? '').isNotEmpty)
                        // Canvas DHoje: o resumo em 14/400 na cor do texto.
                        Text(p.summary!, style: theme.textTheme.bodyMedium)
                      else
                        _Status(game: p, opened: opened, style: muted),
                  ],
                ),
              ),
              if (showArrow)
                Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// "5+0 Blitz · Pretas · Caro-Kann · Hoje". Se a abertura não cabe na linha,
/// ela vai para uma linha própria (até [GameRow.detailMaxLines]), sem
/// reticências (cobertura 5 do QA: nome longo do Lichess a 411 dp).
class _Detail extends StatelessWidget {
  const _Detail({
    required this.timeControlColor,
    required this.opening,
    required this.when_,
    required this.style,
  });

  final List<String> timeControlColor;
  final String? opening;
  final String when_;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final separator = context.l10n.treinadorListaSeparador;
    final opening = this.opening;
    final isComplete = [...timeControlColor, ?opening, when_].join(separator);
    return LayoutBuilder(
      builder: (context, box) {
        final measure = TextPainter(
          text: TextSpan(text: isComplete, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout(maxWidth: box.maxWidth);
        final fits = !measure.didExceedMaxLines;
        measure.dispose();
        if (fits || opening == null) {
          return Text(
            isComplete,
            maxLines: GameRow.detailMaxLines,
            overflow: TextOverflow.ellipsis,
            style: style,
          );
        }
        // Ordem fixa (ritmo, cor, abertura, quando): se não cabe, quebra depois
        // da cor e a abertura abre a linha de baixo.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeControlColor.join(separator),
              maxLines: GameRow.detailMaxLines,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            Text(
              [opening, when_].join(separator),
              maxLines: GameRow.detailMaxLines + 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ],
        );
      },
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result});

  final GameResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, frente) = switch (result) {
      GameResult.win => (
        AppColors.trainingDayCorrect,
        AppColors.chessWhiteColor,
      ),
      GameResult.loss => (
        AppColors.trainingDayWrong,
        AppColors.chessWhiteColor,
      ),
      GameResult.draw => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
    };
    return Semantics(
      label: context.result(result),
      excludeSemantics: true,
      child: Container(
        width: GameRow.square,
        height: GameRow.square,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        child: Text(
          context.resultLetter(result),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: frente,
            fontWeight: AppWeight.strong,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.game,
    required this.opened,
    required this.style,
  });

  final CoachGame game;
  final bool opened;
  final TextStyle? style;

  // Canvas DPartidasFiltro: o visto verde antes da precisão.
  bool get _completeWithAccuracy {
    final p = game;
    return opened &&
        p.ready &&
        p.accuracy != null &&
        (p.progress ?? GameProgress.empty).isComplete(p.exercises.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = game;
    final colors = Theme.of(context).colorScheme;
    final total = p.exercises.length;
    final progress = p.progress ?? GameProgress.empty;
    final (text, color) = !opened
        ? (l.treinadorEstadoBloqueada, colors.onSurfaceVariant)
        : switch (p.status) {
            GameStatus.newGame => (l.treinadorEstadoNova, colors.primary),
            GameStatus.queued || GameStatus.analyzing => (
              l.treinadorEstadoAnalisando,
              colors.primary,
            ),
            GameStatus.error => (l.treinadorEstadoErro, colors.error),
            GameStatus.ready when total == 0 => (
              l.treinadorEstadoSemExercicios,
              colors.onSurfaceVariant,
            ),
            GameStatus.ready
                when progress.isComplete(total) && p.accuracy != null =>
              (
                l.treinadorListaPrecisao(
                  p.accuracy!.round(),
                  progress.corrects,
                  total,
                ),
                colors.onSurface,
              ),
            GameStatus.ready when progress.isComplete(total) => (
              l.treinadorEstadoCompleta(progress.corrects, total),
              colors.onSurfaceVariant,
            ),
            GameStatus.ready => (
              l.treinadorEstadoExercicios(progress.doneCount, total),
              colors.primary,
            ),
          };
    final line = Text(text, style: style?.copyWith(color: color));
    if (opened && !_completeWithAccuracy) return line;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            opened ? Icons.check_circle_outline : Icons.lock_outline,
            size: AppIconSize.small,
            color: opened ? AppColors.trainingDayCorrect : color,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: line),
      ],
    );
  }
}
