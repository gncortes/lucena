import '../../core/theme/app_button.dart';
import '../../core/theme/app_shape.dart';
import '../../core/theme/app_icon_size.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/keys/training_profile_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/lucena_app_bar.dart';
import '../../course_guide/view_models/course_guide_cubit.dart';

/// The draft selection stays local; only the primary action saves it.
class TrainingProfileScreen extends StatefulWidget {
  const TrainingProfileScreen({
    required this.onBack,
    required this.onChosen,
    required this.onWhyLondon,
    this.onWhyUnavailable,
    this.startPart,
    super.key,
  });
  final VoidCallback onBack, onChosen, onWhyLondon;
  final ValueChanged<String>? onWhyUnavailable;
  final String? startPart;

  @override
  State<TrainingProfileScreen> createState() => _TrainingProfileScreenState();
}

class _TrainingProfileScreenState extends State<TrainingProfileScreen> {
  String _selected = 'solido';
  bool _busy = false;

  Future<void> _choose() async {
    setState(() => _busy = true);
    final success = await context.read<CourseGuideCubit>().selectOpeningProfile(
      _selected,
      startPart: widget.startPart,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) widget.onChosen();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return BlocConsumer<CourseGuideCubit, CourseGuideState>(
      listenWhen: (before, after) => !before.failed && after.failed,
      listener: (context, state) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.trainingExerciseSaveError))),
      builder: (context, state) => Scaffold(
        key: TrainingProfileKeys.screen,
        appBar: LucenaAppBar(
          toolbarHeight: 64,
          centerTitle: true,
          title: Text(t.trainingProfileChoiceTitle),
          leading: IconButton(
            key: TrainingProfileKeys.back,
            onPressed: _busy ? null : widget.onBack,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(CanvasSymbols.arrowBack),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: [
                    Text(
                      t.trainingProfileChoiceIntro,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 20 / 14),
                    ),
                    const SizedBox(height: 12),
                    _card(context, solid: true),
                    const SizedBox(height: 12),
                    _card(context, solid: false),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FilledButton(
                  key: TrainingProfileKeys.choose,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(kButtonHeight),
                  ),
                  onPressed: _busy || state.loading || state.saving
                      ? null
                      : _choose,
                  child: Text(
                    _selected == 'solido'
                        ? t.trainingProfileChooseSolid
                        : t.trainingProfileChooseAggressive,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, {required bool solid}) {
    final t = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final profile = solid ? 'solido' : 'agressivo';
    final selected = _selected == profile;
    final chips = solid
        ? [
            t.trainingOpeningChipLondon,
            t.trainingProfileCaroKann,
            t.trainingOpeningChipSlav,
            t.trainingProfileAgainstOthers,
          ]
        : [
            t.trainingProfileE4,
            t.trainingProfileDragon,
            t.trainingProfileKingsIndian,
            t.trainingProfileAgainstOthers,
          ];
    return Semantics(
      checked: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? colors.primaryContainer
            : colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppShape.card),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: TrainingProfileKeys.card(profile),
          onTap: _busy ? null : () => setState(() => _selected = profile),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 12,
                  children: [
                    Icon(
                      solid
                          ? CanvasSymbols.shield
                          : CanvasSymbols.localFireDepartment,
                      color: colors.primary,
                    ),
                    Expanded(
                      child: Text(
                        solid
                            ? t.trainingProfileSolid
                            : t.trainingProfileAggressive,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (solid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(AppShape.small),
                        ),
                        child: Text(
                          t.trainingProfileRecommended,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onPrimary),
                        ),
                      ),
                    Icon(
                      selected
                          ? CanvasSymbols.radioButtonChecked
                          : CanvasSymbols.radioButtonUnchecked,
                      color: selected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ],
                ),
                Text(
                  solid
                      ? t.trainingProfileSolidDescription
                      : t.trainingProfileAggressiveDescription,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 20 / 14,
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (index, label) in chips.indexed)
                      _chip(
                        context,
                        profile,
                        index,
                        label,
                        solid && index == 0
                            ? widget.onWhyLondon
                            : () => widget.onWhyUnavailable?.call(label),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    String profile,
    int index,
    String label,
    VoidCallback? onTap,
  ) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      key: TrainingProfileKeys.chip(profile, index),
      onTap: _busy ? null : onTap,
      borderRadius: BorderRadius.circular(AppShape.small),
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 12, right: 10),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(AppShape.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.primary),
            ),
            if (onTap != null)
              Icon(
                CanvasSymbols.chevronRight,
                size: AppIconSize.compact,
                color: colors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
