import 'package:flutter/material.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../../../domain/models/goal_preference.dart';
import '../../core/keys/goal_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/lucena_sheet.dart';
import '../../core/widgets/sheet_header.dart';
import 'goal_ui.dart';

/// Abre a folha "Seu objetivo" do Perfil. Devolve o objetivo salvo, ou nulo
/// se a folha for fechada sem salvar.
Future<GoalPreference?> showGoalSheet(
  BuildContext context, {
  required GoalPreference? selected,
}) {
  return showLucenaSheet<GoalPreference>(
    context,
    builder: (context) => SafeArea(
      top: false,
      child: _GoalSheet(initial: selected ?? GoalPreference.endgames),
    ),
  );
}

class _GoalSheet extends StatefulWidget {
  const _GoalSheet({required this.initial});

  final GoalPreference initial;

  @override
  State<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<_GoalSheet> {
  late GoalPreference _marked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: GoalKeys.sheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SheetHeader(title: l10n.goalSheetTitle, hint: l10n.goalSheetText),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: GoalOptions(
              l10n: l10n,
              selected: _marked,
              onSelected: (goal) => setState(() => _marked = goal),
            ),
          ),
        ),
        ActionsFooter(
          margin: AppSpacing.xl,
          children: [
            FilledButton(
              key: GoalKeys.sheetSave,
              onPressed: () => Navigator.of(context).pop(_marked),
              child: Text(l10n.goalSheetSave),
            ),
          ],
        ),
      ],
    );
  }
}
