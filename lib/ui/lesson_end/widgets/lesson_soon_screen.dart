import 'package:flutter/material.dart';

import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/canvas_symbols.dart';
import '../../core/widgets/actions_footer.dart';
import '../../core/widgets/busy_button.dart';
import 'lesson_end_parts.dart';

/// "Lição em breve" (H-LIC-58): o aluno terminou o que está publicado.
class LessonSoonScreen extends StatelessWidget {
  const LessonSoonScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: LessonEndKeys.soon,
      appBar: LessonEndClose(
        buttonKey: LessonEndKeys.soonClose,
        onClose: onBack,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CanvasSymbols.schedule,
                  size: 64,
                  fill: 0,
                  weight: 300,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l.licaoEmBreveTitle,
                  textAlign: TextAlign.center,
                  style: endTitleStyle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  l.licaoEmBreveBody,
                  textAlign: TextAlign.center,
                  style: endSubtitleStyle(context),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ActionsFooter(
        children: [
          BusyButton(
            buttonKey: LessonEndKeys.soonBack,
            label: l.licaoEmBreveVoltar,
            onPressed: onBack,
          ),
        ],
      ),
    );
  }
}
