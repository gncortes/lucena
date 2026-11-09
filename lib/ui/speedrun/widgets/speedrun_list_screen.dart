import '../../journey/widgets/challenge_load_error.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_chip.dart';

import 'package:lucena/ui/core/widgets/lucena_app_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/clock.dart';
import '../../../domain/models/pace.dart';
import '../../../domain/models/speedrun.dart';
import '../../../domain/models/speedrun_pace.dart';
import '../../../routing/routes.dart';
import '../../core/keys/speedrun_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/run_time.dart';
import '../../core/pace/pace_ui.dart';
import '../../core/theme/app_icon_size.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/scroll_padding.dart';
import '../../core/widgets/time_display.dart';
import '../../catalog/widgets/catalog_ui.dart';
import '../view_models/speedrun_cubit.dart';
import 'speedrun_ui.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_shape.dart';
import '../../core/widgets/one_line.dart';
import '../../../domain/use_cases/speedrun_category.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/motion/shimmer_conteudo.dart';
import '../../core/motion/entrada_em_cascata.dart';
import '../../core/motion/lista_em_ordem.dart';

/// Os speedruns no ritmo escolhido, com o melhor tempo de cada um.
class SpeedrunListScreen extends StatelessWidget {
  const SpeedrunListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SpeedrunCubit>().state;
    final failure = state.failure;
    if (failure != null) {
      return challengeLoadError(
        context,
        failure,
        context.read<SpeedrunCubit>().retry,
      );
    }

    final all = state.all;
    final marathon = state.marathonMode;
    // Fora da dificuldade escolhida, o speedrun some da lista (o de
    // adversário fica na faixa dele; a Jornada completa aparece sempre).
    bool shown(SpeedrunSummary summary) {
      final category = SpeedrunCategories.of(summary.speedrun);
      return state.category == null ||
          category == null ||
          category == state.category;
    }

    return Scaffold(
      key: SpeedrunKeys.listScreen,
      appBar: LucenaAppBar(
        title: Text(l10n.speedrunTitle),
        actions: [
          IconButton(
            key: SpeedrunKeys.help,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.speedrunHelp,
            onPressed: () => _showHelp(context, state),
          ),
        ],
      ),
      body: ShimmerConteudo(
        carregando: all == null,
        esqueleto: const SkeletonList(),
        child: all == null
            ? const SizedBox.shrink()
            // As linhas entram em ordem na primeira carga (H-ANI-17).
            : ListaEmOrdem(
                montar: (itens) => ListView(
                  // Espaço no fim: o último cartão rola até sair da barra do
                  // sistema.
                  padding: scrollPadding(context, bottom: 48),
                  children: itens,
                ),
                itens: [
                  // O modo no alto: cada partida com o seu relógio, ou um
                  // relógio só para todas (a Maratona). Fica gravado.
                  const _ModePicker(),
                  // O ritmo do modo, sempre à vista: a categoria e, dentro
                  // dela, o tempo. Cada ritmo tem os seus recordes, e o último
                  // de cada modo fica gravado.
                  _PaceChooser(state: state, marathon: marathon),
                  // A dificuldade dos finais: abre na do nível do jogador; as
                  // outras ficam a um toque.
                  if (state.category != null &&
                      [...all, ...state.marathons].any(
                        (summary) =>
                            SpeedrunCategories.of(summary.speedrun) != null,
                      ))
                    const _CategoryPicker(),
                  if (![...all, ...state.marathons].any(
                    (summary) =>
                        (marathon
                            ? summary.speedrun.kind == SpeedrunKind.marathon
                            : summary.speedrun.kind != SpeedrunKind.marathon) &&
                        shown(summary),
                  ))
                    const _EmptyList(),
                  if (marathon) ...[
                    _SectionTitle(l10n.speedrunEndingSection),
                    for (final summary in state.marathons)
                      if (shown(summary)) _Card(summary: summary),
                  ] else
                    for (final kind in SpeedrunKind.values)
                      // Modalidade sem speedrun na dificuldade não ganha título.
                      if (all.any(
                        (summary) =>
                            summary.speedrun.kind == kind && shown(summary),
                      )) ...[
                        _SectionTitle(switch (kind) {
                          SpeedrunKind.rung => l10n.speedrunRungSection,
                          SpeedrunKind.ending => l10n.speedrunEndingSection,
                          SpeedrunKind.exercises =>
                            l10n.speedrunExercisesSection,
                          SpeedrunKind.full => l10n.speedrunFullSection,
                          SpeedrunKind.marathon => l10n.marathonSection,
                        }),
                        for (final summary in all)
                          if (summary.speedrun.kind == kind && shown(summary))
                            _Card(summary: summary),
                      ],
                ],
              ),
      ),
    );
  }

  /// Regras dos dois modos e exemplos do catálogo/ritmo realmente carregados.
  void _showHelp(BuildContext context, SpeedrunState state) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final pace = state.marathonMode ? state.marathonPace : state.pace;
    final initial = pace.initial < const Duration(minutes: 1)
        ? l10n.paceSeconds(pace.initial.inSeconds)
        : l10n.setupPaceCustomMinutes(pace.initial.inMinutes);
    Widget section(IconData icon, String title, Widget body) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: AppIconSize.standard,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );
    final levels = <Widget>[];
    for (final (category, label) in [
      (SpeedrunCategory.beginner, l10n.profileLevelBeginner),
      (SpeedrunCategory.intermediate, l10n.profileLevelIntermediate),
      (SpeedrunCategory.advanced, l10n.profileLevelAdvanced),
    ]) {
      // Os mesmos agrupamentos e nomes da lista: não manter outro catálogo
      // nem presumir que todo tipo de série enfrenta os mesmos adversários.
      final names = <String>{
        for (final summary in state.all ?? <SpeedrunSummary>[])
          if (SpeedrunCategories.of(summary.speedrun) == category)
            speedrunName(l10n, state.characters, summary.speedrun),
      };
      if (names.isEmpty) continue;
      levels.addAll([
        const SizedBox(height: AppSpacing.sm),
        Text(label, style: theme.textTheme.titleSmall),
        Text(names.join(', '), style: theme.textTheme.bodyLarge),
      ]);
    }
    // Tela cheia, com o fechar à esquerda (canvas `DesSpeedrunComoFunciona`).
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          key: SpeedrunKeys.helpScreen,
          appBar: LucenaAppBar(
            leading: IconButton(
              key: SpeedrunKeys.helpClose,
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(l10n.speedrunHelp),
          ),
          body: Scrollbar(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: 24 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: EntradaEmCascata(
                      montar: (itens) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: itens,
                      ),
                      itens: [
                        for (final secao in [
                          section(
                            Icons.timer_outlined,
                            l10n.speedrunModeClassic,
                            Text(
                              l10n.speedrunHelpClassic,
                              key: SpeedrunKeys.intro,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          section(
                            Icons.all_inclusive,
                            l10n.marathonSection,
                            Text(
                              l10n.speedrunHelpMarathon,
                              key: SpeedrunKeys.helpText,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          section(
                            Icons.av_timer_outlined,
                            l10n.speedrunPaceLine(paceShort(l10n, pace)),
                            Text(
                              l10n.speedrunHelpClock(
                                initial,
                                pace.increment.inSeconds,
                              ),
                              key: SpeedrunKeys.paceHelp,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          section(
                            Icons.school_outlined,
                            l10n.speedrunHelpLevels,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: levels,
                            ),
                          ),
                          section(
                            Icons.pause_circle_outline,
                            l10n.lessonDemoPause,
                            Text(
                              l10n.speedrunHelpPause,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ])
                          ItemDaCascata.texto(secao),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Um speedrun num cartão: a imagem, o nome, as etapas e o melhor tempo.
class _Card extends StatelessWidget {
  const _Card({required this.summary});

  final SpeedrunSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final characters = context.select(
      (SpeedrunCubit cubit) => cubit.state.characters,
    );
    final speedrun = summary.speedrun;
    final best = summary.records.best;
    return Card(
      key: SpeedrunKeys.item(speedrun.id),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final cubit = context.read<SpeedrunCubit>();
          await context.push(Routes.speedrun(speedrun.id));
          if (context.mounted) await cubit.load();
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SpeedrunPicture(speedrun, characters: characters),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // No modo Maratona o alto já diz o modo: só o final.
                      speedrun.kind == SpeedrunKind.marathon
                          ? endgameName(
                              l10n,
                              speedrun.stages.first.position.subcategory,
                            )
                          : speedrunName(l10n, characters, speedrun),
                      style: context.cardTitle,
                    ),
                    // Sem recorde, o aviso fica embaixo do nome, junto das
                    // etapas: o nome não disputa espaço com ele.
                    Text(
                      best == null
                          ? '${l10n.speedrunStagesCount(speedrun.stages.length)}'
                                ' · ${l10n.speedrunNoRecord}'
                          : l10n.speedrunStagesCount(speedrun.stages.length),
                      key: best == null
                          ? SpeedrunKeys.itemBest(speedrun.id)
                          : null,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // O lado direito é só do melhor tempo, em destaque.
              if (best != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: TimeDisplay(
                    value: runTime(context, recordTime(speedrun, best)),
                    semanticsLabel:
                        '${speedrun.kind == SpeedrunKind.marathon ? l10n.marathonBest : l10n.speedrunBest}: ${runTime(context, recordTime(speedrun, best))}',
                    type: TimeDisplayType.record,
                    size: TimeDisplaySize.inline,
                    textKey: SpeedrunKeys.itemBest(speedrun.id),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// O ritmo numa linha só ("Ritmo: 15 min + 10 s"), para quem está
/// começando: o toque abre o seletor com todos os ritmos.
class _CompactPace extends StatelessWidget {
  const _CompactPace({required this.current, required this.onChosen});

  final TimeControl current;
  final ValueChanged<TimeControl> onChosen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = current.initial < const Duration(minutes: 1)
        ? l10n.paceSeconds(current.initial.inSeconds)
        : l10n.speedrunTimeControl(
            current.initial.inMinutes,
            current.increment.inSeconds,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Card(
        child: ListTile(
          key: SpeedrunKeys.compactPace,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShape.large),
          ),
          leading: Icon(paceIcon(PaceCategory.of(current))),
          title: Text(l10n.speedrunPaceLine(time)),
          trailing: const Icon(Icons.expand_more),
          onTap: () async {
            final choice = await showPaceSheet(context, current: current);
            final time = choice?.time;
            if (time != null) onChosen(time);
          },
        ),
      ),
    );
  }
}

/// Iniciante, intermediário ou avançado: a dificuldade dos finais da lista.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SpeedrunCubit>();
    final category = context.select(
      (SpeedrunCubit cubit) => cubit.state.category,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: SegmentedButton<SpeedrunCategory>(
        key: SpeedrunKeys.category,
        showSelectedIcon: false,
        segments: [
          for (final (value, label) in [
            (SpeedrunCategory.beginner, l10n.profileLevelBeginner),
            (SpeedrunCategory.intermediate, l10n.profileLevelIntermediate),
            (SpeedrunCategory.advanced, l10n.profileLevelAdvanced),
          ])
            ButtonSegment(
              value: value,
              label: OneLine(
                label,
                key: SpeedrunKeys.categoryOption(value.name),
              ),
            ),
        ],
        selected: {?category},
        emptySelectionAllowed: true,
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) cubit.chooseCategory(selection.single);
        },
      ),
    );
  }
}

/// Clássico ou Maratona: o modo da lista, no alto.
class _ModePicker extends StatelessWidget {
  const _ModePicker();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<SpeedrunCubit>();
    final marathon = context.select(
      (SpeedrunCubit cubit) => cubit.state.marathonMode,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: SegmentedButton<bool>(
        key: SpeedrunKeys.mode,
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.timer_outlined),
            label: OneLine(
              l10n.speedrunModeClassic,
              key: SpeedrunKeys.modeOption('classic'),
            ),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.all_inclusive_rounded),
            label: OneLine(
              l10n.marathonSection,
              key: SpeedrunKeys.modeOption('marathon'),
            ),
          ),
        ],
        selected: {marathon},
        onSelectionChanged: (selection) =>
            cubit.chooseMode(marathon: selection.single),
      ),
    );
  }
}

/// Bullet, blitz ou rápido no alto e, embaixo, os ritmos da categoria
/// escolhida. Tocar num ritmo troca a lista.
class _PacePicker extends StatefulWidget {
  const _PacePicker({required this.current, required this.onChosen, super.key});

  final TimeControl current;
  final ValueChanged<TimeControl> onChosen;

  @override
  State<_PacePicker> createState() => _PacePickerState();
}

class _PacePickerState extends State<_PacePicker> {
  late PaceCategory _category = PaceCategory.of(widget.current);

  @override
  void didUpdateWidget(_PacePicker old) {
    super.didUpdateWidget(old);
    if (old.current != widget.current) {
      _category = PaceCategory.of(widget.current);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = SpeedrunPaces.groups;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<PaceCategory>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            ),
            segments: [
              for (final category in groups.keys)
                // Ícone em cima e o rótulo embaixo, numa linha só: lado a
                // lado, quatro segmentos não cabem e as palavras quebravam.
                ButtonSegment(
                  value: category,
                  tooltip: category.label(l10n),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(paceIcon(category), size: AppIconSize.button),
                        const SizedBox(height: AppSpacing.xs),
                        OneLine(
                          category.label(l10n),
                          key: SpeedrunKeys.paceCategory(category.name),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            selected: {_category},
            onSelectionChanged: (selection) =>
                setState(() => _category = selection.single),
          ),
          const SizedBox(height: AppSpacing.md),
          // Os ritmos da categoria, entrando com um fade quando ela muda.
          AnimatedSwitcher(
            duration: AppMotion.of(context).state,
            // Os chips alinhados no começo da linha, como as outras fileiras.
            layoutBuilder: (current, previous) => Stack(
              alignment: AlignmentDirectional.topStart,
              children: [...previous, ?current],
            ),
            child: Wrap(
              key: ValueKey(_category),
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final time in groups[_category] ?? const <TimeControl>[])
                  ChoiceChip(
                    materialTapTargetSize: AppChip.tapTarget,
                    visualDensity: AppChip.density,
                    key: SpeedrunKeys.paceOption(time.code),
                    // O ícone da categoria já está no seletor de cima.
                    label: Text(paceShort(l10n, time)),
                    selected: time == widget.current,
                    onSelected: (_) => widget.onChosen(time),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// O título de uma seção da lista.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: Text(title, style: context.sectionTitle),
  );
}

/// O ritmo do modo, sempre à vista: o compacto ou o seletor inteiro.
class _PaceChooser extends StatelessWidget {
  const _PaceChooser({required this.state, required this.marathon});

  final SpeedrunState state;
  final bool marathon;

  @override
  Widget build(BuildContext context) {
    final current = marathon ? state.marathonPace : state.pace;
    final onChosen = marathon
        ? context.read<SpeedrunCubit>().chooseMarathonPace
        : context.read<SpeedrunCubit>().choosePace;
    return state.compactPace
        ? _CompactPace(current: current, onChosen: onChosen)
        : _PacePicker(
            key: SpeedrunKeys.pace,
            current: current,
            onChosen: onChosen,
          );
  }
}

/// O aviso de que nenhum speedrun cabe na dificuldade escolhida.
class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) => Padding(
    key: SpeedrunKeys.empty,
    padding: const EdgeInsets.all(AppSpacing.xl),
    child: Text(
      context.l10n.desafiosSpeedrunEmpty,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge,
    ),
  );
}
