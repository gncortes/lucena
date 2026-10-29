import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/training_keys.dart';
import '../../core/keys/sheet_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_chip.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../core/widgets/sheet_close_button.dart';
import '../view_models/training_plan_cubit.dart';
import 'course_guide_copy.dart';

class TrainingPlanScreen extends StatefulWidget {
  const TrainingPlanScreen({
    required this.onBack,
    required this.onSaved,
    super.key,
  });
  final VoidCallback onBack, onSaved;
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
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: Theme.of(dialogContext).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.trainingPermissionTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(dialogContext).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.trainingPermissionBody,
                      style: Theme.of(dialogContext).textTheme.bodyMedium
                          ?.copyWith(
                            color: Theme.of(dialogContext)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton(
                          key: TrainingKeys.permissionLater,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(110, 48),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(t.trainingPermissionLater),
                        ),
                        FilledButton(
                          key: TrainingKeys.permissionAllow,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(110, 48),
                          ),
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(t.trainingPermissionAllow),
                        ),
                      ],
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

  Widget _card(
    BuildContext context,
    List<Widget> children, {
    bool highlighted = false,
    bool weekdays = false,
    double spacing = 12,
    double inset = 16,
    double? verticalInset,
  }) => Material(
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

  Widget _weekday(
    BuildContext context,
    TrainingPlanState state,
    int day,
    String letter,
  ) {
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

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<TrainingPlanCubit, TrainingPlanState>(
    builder: (context, state) {
      final cubit = context.read<TrainingPlanCubit>();
      final config = cubit.config;
      final t = context.l10n;
      final colors = Theme.of(context).colorScheme;
      final plan = state.draft;
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
      final extraKey = config.planExtraRecommendationKeys[plan.minutes];
      final screenWidth = MediaQuery.of(context).size.width;
      // Seven 48 dp day targets need 336 dp. Retain Canvas gutters whenever
      // space permits, reducing only the compact phone gutters.
      final horizontalPadding = screenWidth < 368 ? 12.0 : 16.0;
      final dayPadding = ((screenWidth - 2 * horizontalPadding - 336) / 2)
          .clamp(0.0, 12.0)
          .toDouble();
      return PopScope(
        canPop: !state.saving,
        child: Scaffold(
          key: TrainingKeys.planScreen,
          appBar: LucenaAppBar(
            centerTitle: true,
            toolbarHeight: 64,
            title: Text(t.trainingPlanTitle),
            leading: BackButton(onPressed: state.busy ? null : widget.onBack),
          ),
          body: SafeArea(
            top: false,
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : !state.ready
                ? Center(
                    child: TextButton(
                      onPressed: cubit.load,
                      child: Text(t.lessonRetry),
                    ),
                  )
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
                        _card(context, [
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
                                      : () =>
                                            cubit.selectMinutes(option.minutes),
                                  child: ExcludeSemantics(
                                    child: SizedBox(
                                      height: 48,
                                      child: InkWell(
                                        key: TrainingKeys.planChip(
                                          option.minutes,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppShape.small,
                                        ),
                                        onTap: state.busy
                                            ? null
                                            : () => cubit.selectMinutes(
                                                option.minutes,
                                              ),
                                        child: Center(
                                          widthFactor: 1,
                                          child: IgnorePointer(
                                            child: ChoiceChip(
                                              visualDensity: AppChip.density,
                                              materialTapTargetSize:
                                                  AppChip.tapTarget,
                                              label: Text(
                                                courseGuideCopy(
                                                  context,
                                                  config.planLabelKeys[option
                                                      .minutes]!,
                                                ),
                                              ),
                                              selected:
                                                  plan.minutes ==
                                                  option.minutes,
                                              onSelected: state.busy
                                                  ? null
                                                  : (_) => cubit.selectMinutes(
                                                      option.minutes,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                        _card(
                          context,
                          [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    t.trainingPlanRecommended,
                                    style: titleStyle,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              courseGuideCopy(
                                context,
                                config.planRecommendationKeys[plan.minutes]!,
                              ),
                            ),
                            if (extraKey != null)
                              Text(courseGuideCopy(context, extraKey)),
                          ],
                          highlighted: true,
                          spacing: 8,
                        ),
                        const SizedBox(height: 12),
                        _card(
                          context,
                          [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                t.trainingPlanDays,
                                style: titleStyle,
                              ),
                            ),
                            // The 40 dp painted circle lives inside a distinct 48 dp hit target.
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: dayPadding,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  for (var i = 0; i < 7; i++)
                                    _weekday(context, state, i, letters[i]),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                t.trainingPlanDaysOff,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                          weekdays: true,
                          spacing: 10,
                        ),
                        const SizedBox(height: 12),
                        _card(
                          context,
                          [
                            SwitchListTile(
                              key: TrainingKeys.reminderSwitch,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              secondary: Icon(
                                state.denied
                                    ? Icons.notifications_off_outlined
                                    : Icons.notifications_outlined,
                              ),
                              title: Text(t.trainingReminderTitle),
                              subtitle: Text(t.trainingReminderSub),
                              value: plan.reminderOn && !state.denied,
                              onChanged: state.busy
                                  ? null
                                  : (on) {
                                      if (on) {
                                        _enableReminder();
                                      } else {
                                        cubit.disableReminder();
                                      }
                                    },
                            ),
                            if (state.denied)
                              _card(context, [
                                Text(t.trainingReminderDenied),
                                OutlinedButton.icon(
                                  key: TrainingKeys.openNotificationSettings,
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  onPressed: state.busy
                                      ? null
                                      : cubit.openSettings,
                                  icon: const Icon(Icons.open_in_new),
                                  label: Text(t.trainingOpenSettings),
                                ),
                              ], highlighted: true)
                            else if (plan.reminderOn) ...[
                              ListTile(
                                key: TrainingKeys.reminderTime,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                leading: const Icon(Icons.schedule),
                                title: Text(t.trainingReminderTime),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      MaterialLocalizations.of(context)
                                          .formatTimeOfDay(
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
                                onTap: state.busy ? null : _pickTime,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  t.trainingReminderSilent,
                                  style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                          spacing: 0,
                          inset: 8,
                          verticalInset: 4,
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
                        const SizedBox(height: 24),
                        FilledButton(
                          key: TrainingKeys.planSave,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontSize: 16,
                                  height: 24 / 16,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          onPressed: state.busy ? null : _save,
                          child: Text(
                            state.editing
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
  );
}
