import 'package:flutter/material.dart';

import '../../core/motion/entrada_em_cascata.dart';
import '../../core/widgets/skeleton.dart';

import 'training_load_error.dart';

import '../../core/theme/canvas_symbols.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/training/training_plan.dart';
import '../../../domain/use_cases/training/goal/tournament_rules.dart';
import '../../core/keys/training_goal_keys.dart';
import '../../core/keys/training_keys.dart';
import '../../training_goal/widgets/goal_format.dart';
import '../../core/keys/sheet_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_button.dart';
import '../../core/theme/app_chip.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/sheet_close_button.dart';
import '../view_models/training_plan_cubit.dart';
import 'course_guide_copy.dart';

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({
    required this.onBack,
    required this.onSaved,
    this.tournamentDate,
    this.today,
    this.flow = false,
    super.key,
  });
  final VoidCallback onBack, onSaved;

  /// Data civil do torneio e de hoje: mostram a linha "Até o torneio".
  final String? tournamentDate, today;

  /// No fluxo do objetivo o botão é "Continuar".
  final bool flow;
  @override
  State<TrainingPlanScreen> createState() => _TrainingPlanScreenState();
}

class _TrainingPlanScreenState extends State<TrainingPlanScreen>
    with WidgetsBindingObserver {
  bool _dialogOpen = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<TrainingPlanCubit>().refreshPermission();
    }
  }

  Future<bool> _enableReminder() async {
    if (_dialogOpen) return false;
    final cubit = context.read<TrainingPlanCubit>();
    if (cubit.state.busy) return false;
    if (cubit.state.permissionGranted && await cubit.enableReminder()) {
      return true;
    }
    if (!mounted || cubit.state.failed) return false;
    final t = context.l10n;
    _dialogOpen = true;
    final allow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SheetCloseButton(
                key: SheetKeys.close,
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              key: TrainingKeys.permissionDialog,
              color: Theme.of(dialogContext).colorScheme.surfaceContainerLowest,
              elevation: 6,
              borderRadius: BorderRadius.circular(AppShape.extraLarge),
              child: Padding(
                padding: const EdgeInsets.all(24),
                // H-ANI-16: o aviso entra em cascata a cada abertura.
                child: EntradaEmCascata(
                  animar: true,
                  montar: (itens) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: itens,
                  ),
                  itens: [
                    ItemDaCascata.selo(
                      Icon(
                        CanvasSymbols.notifications,
                        color: Theme.of(dialogContext).colorScheme.secondary,
                      ),
                    ),
                    ItemDaCascata.titulo(
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          t.trainingPermissionTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(dialogContext)
                              .textTheme
                              .headlineSmall,
                        ),
                      ),
                    ),
                    ItemDaCascata.texto(
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          t.trainingPermissionBody,
                          style: Theme.of(dialogContext).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(dialogContext)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ),
                    ItemDaCascata.botao(
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          spacing: 8,
                          children: [
                            TextButton(
                              key: TrainingKeys.permissionLater,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  110,
                                  kButtonHeightCompact,
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(t.trainingPermissionLater),
                            ),
                            FilledButton(
                              key: TrainingKeys.permissionAllow,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(
                                  110,
                                  kButtonHeightCompact,
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(t.trainingPermissionAllow),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Balance the external close strip so the surface stays centered.
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
    _dialogOpen = false;
    if (!mounted || allow == null) return false;
    if (allow) {
      await cubit.allowPermission();
    } else {
      cubit.declinePermission();
      cubit.disableReminder();
    }
    return true;
  }

  Future<void> _save() async {
    if (_dialogOpen) return;
    final cubit = context.read<TrainingPlanCubit>();
    if (cubit.state.busy) return;
    if (cubit.state.draft.reminderOn && !cubit.state.permissionGranted) {
      if (!await _enableReminder()) return;
      if (!mounted || cubit.state.failed) return;
      if (cubit.state.denied) return;
    }
    if (!mounted) return;
    if (await cubit.save() && mounted) widget.onSaved();
  }

  Future<void> _pickTime() async {
    final cubit = context.read<TrainingPlanCubit>();
    final plan = cubit.state.draft;
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: plan.reminderHour,
        minute: plan.reminderMinute,
      ),
      helpText: context.l10n.trainingTimePickerTitle,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: Theme.of(context).timePickerTheme.copyWith(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerLowest,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: SizedBox(
                // The native picker keeps its own 16 dp insets: 328 dp surface.
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SheetCloseButton(
                          key: SheetKeys.close,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    child!,
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) cubit.setTime(result.hour, result.minute);
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.copyWith(
        bodyMedium: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(letterSpacing: 0),
        bodySmall: Theme.of(context).textTheme.bodySmall
            ?.copyWith(letterSpacing: 0),
        titleMedium: Theme.of(context).textTheme.titleMedium
            ?.copyWith(letterSpacing: 0),
      ),
    ),
    child: BlocBuilder<TrainingPlanCubit, TrainingPlanState>(
      builder: (context, state) {
        final cubit = context.read<TrainingPlanCubit>();
        final t = context.l10n;
        final colors = Theme.of(context).colorScheme;
        final plan = state.draft;
        final screenWidth = MediaQuery.sizeOf(context).width;
        // Seven 48 dp day targets need 336 dp. Retain Canvas gutters whenever
        // space permits, reducing only the compact phone gutters.
        final horizontalPadding = screenWidth < 368 ? 12.0 : 16.0;
        final dayPadding = ((screenWidth - 2 * horizontalPadding - 336) / 2)
            .clamp(0.0, 12.0)
            .toDouble();
        if (!state.loading && !state.ready) {
          return trainingLoadError(context, state.failure, cubit.load);
        }
        return PopScope(
          canPop: !state.saving,
          child: Scaffold(
            key: TrainingKeys.planScreen,
            appBar: LucenaAppBar(
              centerTitle: true,
              title: Text(t.trainingPlanTitle),
              leading: IconButton(
                key: TrainingKeys.planBack,
                onPressed: state.busy ? null : widget.onBack,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(CanvasSymbols.arrowBack),
              ),
            ),
            body: SafeArea(
              top: false,
              child: state.loading
                  ? const SkeletonList()
                  : DefaultTextStyle.merge(
                      style: Theme.of(context).textTheme.bodyMedium,
                      child: ListView(
                        key: TrainingKeys.planScroll,
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          24,
                        ),
                        children: [
                          if (!state.editing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(t.trainingPlanIntro),
                            ),
                          _TimeCard(state: state),
                          const SizedBox(height: 12),
                          _RecommendationCard(state: state),
                          const SizedBox(height: 12),
                          _WeekdaysCard(state: state, dayPadding: dayPadding),
                          const SizedBox(height: 12),
                          _ReminderCard(
                            state: state,
                            onEnable: _enableReminder,
                            onPickTime: _pickTime,
                          ),
                          if (state.failed)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                t.trainingPlanSaveError,
                                key: TrainingKeys.planError,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                          if (widget.tournamentDate != null &&
                              widget.today != null)
                            _UntilTournament(
                              plan: plan,
                              today: widget.today!,
                              tournamentDate: widget.tournamentDate!,
                            ),
                          const SizedBox(height: 24),
                          FilledButton(
                            key: TrainingKeys.planSave,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(kButtonHeight),
                              textStyle: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontSize: 16,
                                    height: 24 / 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            onPressed: state.busy ? null : _save,
                            child: Text(
                              widget.flow
                                  ? t.treinoContinue
                                  : state.editing
                                  ? t.trainingPlanSave
                                  : t.trainingPlanStart,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

/// O tempo de estudo até o torneio, sob o plano.
class _UntilTournament extends StatelessWidget {
  const _UntilTournament({
    required this.plan,
    required this.today,
    required this.tournamentDate,
  });

  final TrainingPlan plan;
  final String today;
  final String tournamentDate;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        t.treinoUntilTournament(
          durationText(context, studyMinutesUntil(plan, today, tournamentDate)),
        ),
        key: TrainingGoalKeys.planUntilTournament,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

/// Cartão do plano: superfície arredondada com os filhos em coluna.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.children,
    this.highlighted = false,
    this.weekdays = false,
    this.spacing = 12,
    this.inset = 16,
    this.verticalInset,
  });

  final List<Widget> children;
  final bool highlighted, weekdays;
  final double spacing, inset;
  final double? verticalInset;

  @override
  Widget build(BuildContext context) => Material(
    color: highlighted
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppShape.card),
    child: Padding(
      padding: weekdays
          ? const EdgeInsets.symmetric(vertical: 16)
          : EdgeInsets.symmetric(
              horizontal: inset,
              vertical: verticalInset ?? inset,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: spacing,
        children: children,
      ),
    ),
  );
}

class _Weekday extends StatelessWidget {
  const _Weekday({
    required this.state,
    required this.day,
    required this.letter,
  });

  final TrainingPlanState state;
  final int day;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = state.draft.weekdays & (1 << day) != 0;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.trainingPlanWeekdaySemantic('$day'),
      child: SizedBox(
        width: 48,
        height: 48,
        child: InkWell(
          key: TrainingKeys.weekday(day),
          customBorder: const CircleBorder(),
          onTap: state.busy
              ? null
              : () => context.read<TrainingPlanCubit>().toggleWeekday(day),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.primary : colors.surface,
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pergunta do tempo de estudo por dia, com as opções em chips.
class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.state});

  final TrainingPlanState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingPlanCubit>();
    final config = cubit.config;
    final t = context.l10n;
    final plan = state.draft;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return _PlanCard(
      children: [
        Text(t.trainingPlanTimeQuestion, style: titleStyle),
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: [
            for (final option in config.planOptions)
              Semantics(
                button: true,
                selected: plan.minutes == option.minutes,
                label: courseGuideCopy(
                  context,
                  config.planLabelKeys[option.minutes]!,
                ),
                onTap: state.busy
                    ? null
                    : () => cubit.selectMinutes(option.minutes),
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 48,
                    child: InkWell(
                      key: TrainingKeys.planChip(option.minutes),
                      borderRadius: BorderRadius.circular(AppShape.small),
                      onTap: state.busy
                          ? null
                          : () => cubit.selectMinutes(option.minutes),
                      child: Center(
                        widthFactor: 1,
                        child: IgnorePointer(
                          child: ChoiceChip(
                            showCheckmark: false,
                            avatar: plan.minutes == option.minutes
                                ? const Icon(
                                    CanvasSymbols.check,
                                    size: 20,
                                    opticalSize: 20,
                                  )
                                : null,
                            avatarBoxConstraints: const BoxConstraints.tightFor(
                              width: 20,
                              height: 20,
                            ),
                            padding: EdgeInsets.fromLTRB(
                              plan.minutes == option.minutes ? 8 : 16,
                              6,
                              16,
                              6,
                            ),
                            labelPadding: EdgeInsets.only(
                              left: plan.minutes == option.minutes ? 8 : 0,
                            ),
                            labelStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                  height: 20 / 14,
                                ),
                            visualDensity: AppChip.density,
                            materialTapTargetSize: AppChip.tapTarget,
                            label: Text(
                              courseGuideCopy(
                                context,
                                config.planLabelKeys[option.minutes]!,
                              ),
                            ),
                            selected: plan.minutes == option.minutes,
                            onSelected: state.busy
                                ? null
                                : (_) => cubit.selectMinutes(option.minutes),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// O tempo recomendado para o objetivo.
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.state});

  final TrainingPlanState state;

  @override
  Widget build(BuildContext context) {
    final config = context.read<TrainingPlanCubit>().config;
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final plan = state.draft;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final extraKey = config.planExtraRecommendationKeys[plan.minutes];
    return _PlanCard(
      highlighted: true,
      spacing: 8,
      children: [
        Row(
          children: [
            Icon(CanvasSymbols.lightbulb, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(t.trainingPlanRecommended, style: titleStyle)),
          ],
        ),
        Text(
          courseGuideCopy(
            context,
            config.planRecommendationKeys[plan.minutes]!,
          ),
        ),
        if (extraKey != null) Text(courseGuideCopy(context, extraKey)),
      ],
    );
  }
}

/// Os dias da semana de estudo.
class _WeekdaysCard extends StatelessWidget {
  const _WeekdaysCard({required this.state, required this.dayPadding});

  final TrainingPlanState state;
  final double dayPadding;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    final letters = [
      t.trainingPlanWeekdaySunday,
      t.trainingPlanWeekdayMonday,
      t.trainingPlanWeekdayTuesday,
      t.trainingPlanWeekdayWednesday,
      t.trainingPlanWeekdayThursday,
      t.trainingPlanWeekdayFriday,
      t.trainingPlanWeekdaySaturday,
    ];
    return _PlanCard(
      weekdays: true,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(t.trainingPlanDays, style: titleStyle),
        ),
        // The 40 dp painted circle lives inside a distinct 48 dp hit target.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: dayPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _Weekday(state: state, day: i, letter: letters[i]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            t.trainingPlanDaysOff,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// O lembrete diário: chave, horário e aviso de permissão negada.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.state,
    required this.onEnable,
    required this.onPickTime,
  });

  final TrainingPlanState state;
  final VoidCallback onEnable;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingPlanCubit>();
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final plan = state.draft;
    return _PlanCard(
      spacing: 0,
      inset: 8,
      verticalInset: 4,
      children: [
        SwitchListTile(
          key: TrainingKeys.reminderSwitch,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          secondary: Icon(
            state.denied
                ? Icons.notifications_off_outlined
                : CanvasSymbols.notifications,
          ),
          title: Text(t.trainingReminderTitle),
          subtitle: Text(t.trainingReminderSub),
          value: plan.reminderOn && !state.denied,
          onChanged: state.busy
              ? null
              : (on) {
                  if (on) {
                    onEnable();
                  } else {
                    cubit.disableReminder();
                  }
                },
        ),
        if (state.denied)
          _PlanCard(
            highlighted: true,
            children: [
              Text(t.trainingReminderDenied),
              OutlinedButton.icon(
                key: TrainingKeys.openNotificationSettings,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(kButtonHeight),
                ),
                onPressed: state.busy ? null : cubit.openSettings,
                icon: const Icon(Icons.open_in_new),
                label: Text(t.trainingOpenSettings),
              ),
            ],
          )
        else if (plan.reminderOn) ...[
          ListTile(
            key: TrainingKeys.reminderTime,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: const Icon(CanvasSymbols.schedule),
            title: Text(t.trainingReminderTime),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MaterialLocalizations.of(context).formatTimeOfDay(
                    TimeOfDay(
                      hour: plan.reminderHour,
                      minute: plan.reminderMinute,
                    ),
                    alwaysUse24HourFormat: true,
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: state.busy ? null : onPickTime,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              t.trainingReminderSilent,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}
