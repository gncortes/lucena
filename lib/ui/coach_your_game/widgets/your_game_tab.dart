import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../config/view_models/coach.dart';
import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/coach/your_game_summary.dart';
import '../../../routing/frentes/coach_your_game_routes.dart';
import '../../core/keys/coach_your_game_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/chip_lucena.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/highlight_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/load_error.dart';
import '../../core/widgets/lucena_card.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/tip_box.dart';
import '../view_models/your_game_cubit.dart';
import 'focus_card.dart';
import 'your_game_parts.dart';
import 'your_game_texts.dart';
import '../../core/theme/app_text.dart';

/// A aba Seu jogo em tela própria (aberta de fora do casco do Treinador).
class YourGameScreen extends StatelessWidget {
  const YourGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: YourGameKeys.screen,
      appBar: LucenaAppBar(title: Text(context.l10n.sjTitulo)),
      body: const YourGameTab(),
    );
  }
}

/// O corpo da aba Seu jogo, sem Scaffold, para o casco de três abas do
/// Treinador. Usa o [YourGameCubit] de cima, se houver; senão cria o seu.
class YourGameTab extends StatelessWidget {
  const YourGameTab({super.key});

  @override
  Widget build(BuildContext context) {
    final hasCubit = context.select<YourGameCubit?, bool>((c) => c != null);
    if (hasCubit) return const _Body();
    return BlocProvider(
      create: (c) => createYourGameCubit(c)..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<YourGameCubit>().state;
    final summary = state.summary;
    return KeyedSubtree(
      key: YourGameKeys.tab,
      child: switch (state.status) {
        YourGameStatus.loading => const Center(
          key: YourGameKeys.loading,
          child: CircularProgressIndicator(),
        ),
        YourGameStatus.error => LoadErrorScreen(
          key: YourGameKeys.error,
          kind: LoadErrorKind.generic,
          onAction: () => context.read<YourGameCubit>().load(),
        ),
        YourGameStatus.ready when summary == null || state.games.isEmpty =>
          _NoGames(),
        YourGameStatus.ready => _List(state: state, summary: summary!),
      },
    );
  }
}

class _NoGames extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          key: YourGameKeys.empty,
          icon: Icons.insights,
          title: t.sjVazioTitulo,
          message: t.sjVazioTexto,
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.state, required this.summary});

  final YourGameState state;
  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final platform = t.platformName(state.platform);
    final noneInTimeControl = summary.games == 0;
    final items = <Widget>[
      _TimeControls(timeControl: state.timeControl),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          noneInTimeControl
              ? t.sjVazioRitmo(t.timeControlName(state.timeControl))
              : summary.few
              ? t.sjBasePoucas(summary.games, platform)
              : t.sjBase(summary.games, platform),
          key: YourGameKeys.base,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
      if (noneInTimeControl)
        const SizedBox.shrink()
      else if (summary.few) ...[
        _StyleCard(state: state, summary: summary),
        _AverageAccuracy(summary: summary),
        TipBox(key: YourGameKeys.fewNotice, text: t.sjPoucasAviso),
      ] else ...[
        _Numbers(summary: summary),
        if (summary.focus case final focus?) FocusCard(focus: focus),
        _Phases(summary: summary),
        _Weeks(summary: summary),
        _StyleCard(state: state, summary: summary),
        if (summary.motifs.isNotEmpty) _Motifs(summary: summary),
        if (summary.timeControls.isNotEmpty)
          _TimeControlsScore(summary: summary),
        _Colors(summary: summary),
        if (summary.openings.isNotEmpty) _Openings(summary: summary),
        if (_modelGamesOpening(summary) case final a?)
          ModelGamesLink(eco: a.eco, name: a.name),
      ],
    ];
    return ListView.separated(
      key: const PageStorageKey('seuJogo.lista'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => items[i],
    );
  }
}

/// As partidas-modelo da abertura do foco; sem foco de abertura, da mais
/// jogada.
OpeningSummary? _modelGamesOpening(YourGameSummary summary) {
  if (summary.focus case OpeningFocus(:final opening)) return opening;
  return summary.openings.firstOrNull;
}

class _TimeControls extends StatelessWidget {
  const _TimeControls({required this.timeControl});

  final TimeControl? timeControl;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    // Uma linha só (canvas DSeuJogo): se não couber, rola na horizontal.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (i, r) in <TimeControl?>[
            null,
            ...TimeControl.values,
          ].indexed) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            ChipLucena(
              key: YourGameKeys.timeControl(r?.wire ?? 'todos'),
              label: Text(t.timeControlName(r)),
              selecionado: r == timeControl,
              aoEscolher: (_) =>
                  context.read<YourGameCubit>().pickTimeControl(r),
            ),
          ],
        ],
      ),
    );
  }
}

/// Os três números do alto: precisão, aproveitamento e a fase com mais erros.
class _Numbers extends StatelessWidget {
  const _Numbers({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final variation = summary.accuracyChange;
    final phase = summary.phaseMostErrors;
    final edge = BorderSide(color: theme.colorScheme.outlineVariant);
    return KeyedSubtree(
      key: YourGameKeys.numbers,
      child: LucenaCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Number(
                  key: YourGameKeys.accuracy,
                  value: summary.accuracy == null
                      ? t.sjSemValor
                      : t.sjPorcento(summary.accuracy!),
                  label: t.sjNumPrecisao,
                  detail: variation == null || variation == 0
                      ? null
                      : _Variation(points: variation),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(left: edge)),
                  child: _Number(
                    key: YourGameKeys.scoreRate,
                    value: t.sjPorcento(summary.scoreRate.percent),
                    label: t.sjNumAproveitamento,
                    detail: _Small(t.sjNumVitorias(summary.scoreRate.wins)),
                  ),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border(left: edge)),
                  child: _Number(
                    key: YourGameKeys.phaseErrors,
                    value:
                        '${phase == null ? 0 : summary.errorsByPhase[phase]}',
                    label: phase == null
                        ? t.sjNumSemErros
                        : t.sjNumErrosNa(t.keyPhase(phase)),
                    detail: phase == null ? null : _Small(t.sjNumMaisAlto),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Number extends StatelessWidget {
  const _Number({
    required this.value,
    required this.label,
    this.detail,
    super.key,
  });

  final String value, label;
  final Widget? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: AppWeight.medium,
            ),
          ),
          _Small(label),
          ?detail,
        ],
      ),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _Variation extends StatelessWidget {
  const _Variation({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    final rose = points > 0;
    final color = rose
        ? AppColors.successOnSurface
        : AppColors.trainingDayWrong;
    return Row(
      children: [
        Icon(
          rose ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            context.l10n.sjNumVariacao(points.abs()),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: AppWeight.medium),
          ),
        ),
      ],
    );
  }
}

class _Phases extends StatelessWidget {
  const _Phases({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final bigger = summary.errorsByPhase.values.fold(
      0,
      (a, b) => a > b ? a : b,
    );
    return YourGameSection(
      key: YourGameKeys.phases,
      title: t.sjFasesTitulo,
      value: t.sjPartidas(summary.games),
      child: Column(
        children: [
          for (final f in GamePhase.values)
            BarRow(
              key: YourGameKeys.phase(t.keyPhase(f)),
              label: t.phaseName(f),
              value: t.sjErros(summary.errorsByPhase[f] ?? 0),
              fraction: bigger == 0
                  ? 0
                  : (summary.errorsByPhase[f] ?? 0) / bigger,
              highlight: f == summary.phaseMostErrors,
            ),
        ],
      ),
    );
  }
}

class _Weeks extends StatelessWidget {
  const _Weeks({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final values = [for (final v in summary.weeksAccuracy) ?v];
    final smaller = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    final bigger = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final last = summary.weeksAccuracy.lastIndexWhere((v) => v != null);
    final weeks = summary.weeksAccuracy;
    return YourGameSection(
      key: YourGameKeys.weeks,
      title: t.sjSemanasTitulo,
      value: t.sjSemanasUltimas(weeks.length),
      child: SizedBox(
        height: 52,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, v) in weeks.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: v == null
                      ? t.sjSemanaSemPartida(weeks.length - i)
                      : t.sjSemanaPrecisao(weeks.length - i, v),
                  child: Container(
                    height: v == null
                        ? 4
                        : bigger == smaller
                        ? 40
                        : 16 + 36 * (v - smaller) / (bigger - smaller),
                    decoration: BoxDecoration(
                      color: v == null
                          ? AppColors.sheetSurface
                          : i == last
                          ? Theme.of(context).colorScheme.primary
                          : softColor(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.xs),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// O cartão do estilo (leitura do servidor) que abre a tela do estilo.
class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.state, required this.summary});

  final YourGameState state;
  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final style = state.stats.style;
    final games = state.stats.analyzedGames > 0
        ? state.stats.analyzedGames
        : summary.games;
    // Canvas DSeuJogoPoucas: com poucas partidas, a frase abre com a ressalva.
    final text = t.styleSummary(style, few: summary.few);
    final colors = theme.colorScheme;
    // Canvas DSeuJogoPoucas/DSeuJogo: o cartão azul de destaque com o medidor
    // de 3 etapas e o link "Ver meu estilo".
    return HighlightCard(
      key: YourGameKeys.style,
      icon: Icons.psychology,
      title: t.sjEstiloTitulo,
      onTap: () => context.push(YourGamePaths.style),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            key: YourGameKeys.styleText,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ConfidenceMeter(
            level: style.level,
            games: games,
            corDoTrilho: colors.outlineVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Text(
                  t.sjVerMeuEstilo,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: AppWeight.medium,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: AppIconSize.button,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Poucas partidas: só a precisão média.
class _AverageAccuracy extends StatelessWidget {
  const _AverageAccuracy({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    return YourGameSection(
      key: YourGameKeys.few,
      title: t.sjPoucasPrecisaoTitulo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.accuracy == null
                ? t.sjSemValor
                : t.sjPorcento(summary.accuracy!),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: AppWeight.medium,
            ),
          ),
          _Small(t.sjPoucasPrecisaoTexto(summary.games)),
        ],
      ),
    );
  }
}

class _Motifs extends StatelessWidget {
  const _Motifs({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final bigger = summary.motifs.fold(
      0,
      (m, e) => e.positions.length > m ? e.positions.length : m,
    );
    return YourGameSection(
      key: YourGameKeys.motifs,
      title: t.sjTemasTitulo,
      child: Column(
        children: [
          for (final motif in summary.motifs)
            InkWell(
              key: YourGameKeys.motif(motif.motif),
              borderRadius: BorderRadius.circular(AppShape.small),
              onTap: () => context.push(YourGamePaths.motifOf(motif.motif)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: BarRow(
                        label: t.motifName(motif.motif),
                        detail: t.sjTemaDescricao(motif.motif).isEmpty
                            ? null
                            : t.sjTemaDescricao(motif.motif),
                        value: '${motif.positions.length}',
                        fraction: bigger == 0
                            ? 0
                            : motif.positions.length / bigger,
                        highlight: motif.positions.length == bigger,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: AppIconSize.button,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeControlsScore extends StatelessWidget {
  const _TimeControlsScore({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final timeControls = [
      for (final r in TimeControl.values)
        if (summary.timeControls[r] case final a?) (r, a),
    ];
    final bigger = timeControls.fold(
      0,
      (m, e) => e.$2.percent > m ? e.$2.percent : m,
    );
    return YourGameSection(
      key: YourGameKeys.timeControls,
      title: t.sjRitmosTitulo,
      subtitle: t.sjRitmosSubtitulo,
      child: Column(
        children: [
          for (final (r, a) in timeControls)
            BarRow(
              label: t.timeControlName(r),
              detail: t.sjPartidas(a.games),
              value: t.sjPorcento(a.percent),
              fraction: a.percent / 100,
              highlight: timeControls.length > 1 && a.percent == bigger,
            ),
        ],
      ),
    );
  }
}

class _Colors extends StatelessWidget {
  const _Colors({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    Widget color(GameColor c, ScoreRate a) => Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sheetSurface,
          borderRadius: BorderRadius.circular(AppShape.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.games == 0 ? t.sjSemValor : t.sjPorcento(a.percent),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              Text(
                t.colorName(c),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: AppWeight.medium,
                ),
              ),
              _Small(t.sjPartidas(a.games)),
            ],
          ),
        ),
      ),
    );
    return YourGameSection(
      key: YourGameKeys.colors,
      title: t.sjCoresTitulo,
      child: Row(
        children: [
          color(GameColor.white, summary.white),
          const SizedBox(width: AppSpacing.sm),
          color(GameColor.black, summary.black),
        ],
      ),
    );
  }
}

class _Openings extends StatelessWidget {
  const _Openings({required this.summary});

  final YourGameSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return YourGameSection(
      key: YourGameKeys.openings,
      title: t.sjAberturasTitulo,
      child: Column(
        children: [
          for (final (i, a) in summary.openings.take(5).indexed)
            Padding(
              key: YourGameKeys.opening(i),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OpeningLine(opening: a),
                  if (a.exit case final s?)
                    InkWell(
                      key: YourGameKeys.openingExit(i),
                      onTap: () =>
                          context.push(YourGamePaths.theoryOf(s.recentGame)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 40),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error,
                              size: AppIconSize.small,
                              color: error,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                t.sjAberturaSaida(s.chessMove, s.times),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: error,
                                  fontWeight: AppWeight.medium,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: AppIconSize.button,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Nome, cor, partidas, aproveitamento e a barra do placar de uma abertura.
class OpeningLine extends StatelessWidget {
  const OpeningLine({required this.opening, super.key});

  final OpeningSummary opening;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final theme = Theme.of(context);
    final a = opening.scoreRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opening.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppWeight.medium,
                    ),
                  ),
                  _Small(
                    t.sjAberturaCorPartidas(
                      t.colorName(opening.color),
                      a.games,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              t.sjPorcento(a.percent),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: AppWeight.medium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ScoreBar(wins: a.wins, draws: a.draws, losses: a.losses),
        const SizedBox(height: AppSpacing.xs),
        _Small(t.sjAberturaPlacar(a.wins, a.draws, a.losses)),
      ],
    );
  }
}

class ModelGamesLink extends StatelessWidget {
  const ModelGamesLink({required this.eco, required this.name, super.key});

  final String eco, name;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return InkWell(
      key: YourGameKeys.modelGamesLink,
      onTap: () => context.push(YourGamePaths.modelGamesOf(eco, name: name)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: AppIconSize.compact,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.l10n.sjModelosDe(name),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: AppWeight.medium,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: AppIconSize.button,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
