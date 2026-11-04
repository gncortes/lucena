import 'package:flutter/material.dart';

import '../../core/keys/lesson_end_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/motion/entrada_de_estado.dart';
import '../../core/motion/entradas_vistas.dart';
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
    // H-ANI-24: na primeira vez da sessão, o ícone escala e o texto sobe.
    return EntradaDaTela(
      id: 'PropV1TreinoAulaEmBreve',
      child: Scaffold(
        key: LessonEndKeys.soon,
        appBar: LessonEndClose(
          buttonKey: LessonEndKeys.soonClose,
          onClose: onBack,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: EntradaDeEstado(
                espaco: 24,
                icone: Icon(
                  CanvasSymbols.schedule,
                  size: 64,
                  fill: 0,
                  weight: 300,
                  color: theme.colorScheme.primary,
                ),
                texto: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Text(
                      l.licaoEmBreveTitle,
                      textAlign: TextAlign.center,
                      style: endTitleStyle(context),
                    ),
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
      ),
    );
  }
}
