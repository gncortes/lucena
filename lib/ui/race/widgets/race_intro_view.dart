import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/race.dart';
import '../../../domain/use_cases/race_rules.dart';
import '../../core/keys/race_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/one_line.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/section_title.dart';
import '../view_models/race_cubit.dart';
import 'race_filter_screen.dart';
import '../../core/motion/entrada_em_cascata.dart';

/// A abertura da Corrida (canvas SugP2CorridaIntroA): o título, a duração (3
/// ou 5 min), três fatos de uma linha, o recorde da duração escolhida, a linha
/// dos filtros (objetivo e finais, em tela cheia) e o "Começar". As regras
/// completas ficam na folha do (i) da barra.
class RaceIntroView extends StatelessWidget {
  const RaceIntroView({required this.state, super.key});

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    if (state.problems.isEmpty) {
      return Center(
        key: RaceKeys.introView,
        child: EmptyState(
          key: RaceKeys.empty,
          icon: Icons.extension,
          message: '${l10n.raceEmptyTitle}\n${l10n.raceEmptyBody}',
        ),
      );
    }
    // H-ANI-16: a explicação se monta em ordem (título, textos, regras) e o
    // "Começar" entra por último; o toque fica liberado desde o início.
    return EntradaEmCascata(
      montar: (itens) => Column(
        key: RaceKeys.introView,
        children: [
          Expanded(
            child: ListView(
              padding: scrollPadding(
                context,
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
              ),
              children: itens.sublist(0, itens.length - 2),
            ),
          ),
          ...itens.sublist(itens.length - 2),
        ],
      ),
      itens: [
        // O título curto e uma linha de apoio (canvas SugP2CorridaIntroA); as
        // regras completas ficam na folha do (i).
        const ItemDaCascata.titulo(_IntroTitle()),
        // Duração em seção própria, acima das regras (E1.33, opção B).
        ItemDaCascata.texto(_DurationPicker(duration: state.duration)),
        // Três fatos de uma linha; os minutos seguem a duração escolhida.
        ItemDaCascata.texto(_Facts(duration: state.duration)),
        ItemDaCascata.texto(
          _RecordCard(record: state.record, duration: state.duration),
        ),
        ItemDaCascata.texto(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(l10n.raceFilters, inset: 0),
              _FilterRow(state: state),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        // A nota fica no pé, sobre o "Começar" (canvas).
        const ItemDaCascata.texto(_Footnote()),
        ItemDaCascata.botao(
          ActionsFooter(
            children: [
              FilledButton.icon(
                key: RaceKeys.start,
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.raceStart),
                onPressed: cubit.start,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// O título curto e uma linha de apoio (canvas SugP2CorridaIntroA); as
/// regras completas ficam na folha do (i).
class _IntroTitle extends StatelessWidget {
  const _IntroTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(
          l10n.raceIntroSubtitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          l10n.raceIntroLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A duração da corrida (3 ou 5 min), em seção própria.
class _DurationPicker extends StatelessWidget {
  const _DurationPicker({required this.duration});

  final RaceDuration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RaceCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionTitle(l10n.raceDuration, inset: 0),
        SegmentedButton<RaceDuration>(
          key: RaceKeys.duration,
          showSelectedIcon: false,
          segments: [
            for (final option in RaceDuration.values)
              ButtonSegment(
                value: option,
                label: OneLine(
                  l10n.raceDurationMinutes(option.minutes),
                  key: RaceKeys.durationOption(option),
                ),
              ),
          ],
          selected: {duration},
          onSelectionChanged: (selection) =>
              unawaited(cubit.selectDuration(selection.single)),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Três fatos de uma linha; os minutos seguem a duração escolhida.
class _Facts extends StatelessWidget {
  const _Facts({required this.duration});

  final RaceDuration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: RaceKeys.facts,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        _Fact(
          icon: Icons.timer,
          lead: l10n.raceRuleTimeTitle(duration.minutes),
          rest: l10n.raceFactTimeRest,
        ),
        _Fact(
          icon: Icons.close,
          lead: l10n.raceFactErrorsLead(RaceRules.maxErrors),
          rest: l10n.raceFactErrorsRest,
        ),
        _Fact(icon: Icons.trending_up, rest: l10n.raceFactLevel),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// A nota do pé, sobre o "Começar" (canvas).
class _Footnote extends StatelessWidget {
  const _Footnote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Text(
        context.l10n.raceFootnote,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A linha "Filtros": o resumo do objetivo e dos finais; abre a tela de
/// filtros e aplica o que voltar dela.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final RaceState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cubit = context.read<RaceCubit>();
    Future<void> open() async {
      final filter = await Navigator.of(context).push<RaceFilter>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) =>
              RaceFilterScreen(problems: state.problems, filter: state.filter),
        ),
      );
      if (filter != null) await cubit.applyFilter(filter);
    }

    return Card(
      key: RaceKeys.filterRow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => unawaited(open()),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            spacing: AppSpacing.md,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.tune,
                  size: AppIconSize.standard,
                  color: colors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  raceFilterSummary(l10n, state.problems, state.filter),
                  key: RaceKeys.filterSummary,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right,
                  size: AppIconSize.standard,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um fato de uma linha: o ícone e o texto, com o começo em negrito.
class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.rest, this.lead});

  final IconData icon;

  /// O começo em negrito ("3 minutos"); nulo, a linha é só texto.
  final String? lead;
  final String rest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = this.lead;
    return Row(
      spacing: AppSpacing.md,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: AppIconSize.notice,
            color: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (lead != null)
                  TextSpan(
                    text: '$lead ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                TextSpan(text: rest),
              ],
            ),
            style: theme.textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// O recorde: acertos e o problema mais difícil, ou o convite do primeiro.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.duration});

  final RaceRecord record;
  final RaceDuration duration;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: RaceKeys.recordCard,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          spacing: AppSpacing.md,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.emoji_events,
                size: AppIconSize.button,
                color: colors.primary,
              ),
            ),
            Expanded(
              child: record.isEmpty
                  ? Text(l10n.raceRecordEmpty)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.raceRecordCorrects(
                            duration.minutes,
                            record.corrects,
                          ),
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l10n.raceRecordHardest(record.hardest),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
