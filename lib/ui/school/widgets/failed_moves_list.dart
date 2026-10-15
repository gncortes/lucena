import 'package:flutter/material.dart';

import '../../../domain/models/failed_alternative.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_spacing.dart';

/// "Alternativas que falham" do estado correto (T70, crit. 7c): uma linha de
/// 48 dp por lance (`1.Re3?`), sem texto; o lance que o aluno já abriu ganha
/// embaixo "Já visto". Toque abre o ramo daquele lance. Sem alternativas, não
/// desenha nada.
class FailedMovesList extends StatelessWidget {
  const FailedMovesList({
    required this.alternatives,
    required this.onOpen,
    super.key,
  });

  /// A altura mínima de cada linha.
  static const rowHeight = 48.0;

  final List<FailedAlternative> alternatives;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    if (alternatives.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.lessonFailedAlternatives,
            style: theme.textTheme.titleSmall,
          ),
        ),
        for (final alternative in alternatives)
          InkWell(
            key: LessonKeys.failedAlternative(alternative.uci),
            onTap: () => onOpen(alternative.uci),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: rowHeight),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A notação de lance é sempre LTR.
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              localizedSan(l10n, alternative.label),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                          if (alternative.seen)
                            Text(
                              l10n.lessonAlreadySeen,
                              key: LessonKeys.alreadySeen(alternative.uci),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
