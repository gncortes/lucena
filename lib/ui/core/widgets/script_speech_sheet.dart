import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../keys/lesson_script_keys.dart';
import 'character_avatar.dart';
import 'script_sheet_route.dart';
import 'speech_balloon.dart';

/// A tag do retrato do Viktor, que voa da faixa da lição até a folha.
const scriptViktorHeroTag = 'lessonScript.viktor';

/// Abre a fala inteira de quem fala (o clique no balão, em toda tela; Gabriel,
/// 14/10/2026; canvas `T70-etapa1-estados`): a folha com o mesmo retrato e o
/// nome ([title]), o ✕ fora dela e as falas separadas por uma linha em branco. Os links
/// fecham a folha e fazem o mesmo que o botão.
Future<void> showScriptSpeechSheet(
  BuildContext context, {
  required Character viktor,
  required String title,
  required List<String> texts,
  VoidCallback? onMainLine,
  VoidCallback? onShowAnswer,
}) {
  return showScriptSheet(
    context,
    maxHeightFactor: 0.7,
    closeKey: LessonScriptKeys.speechSheetClose,
    builder: (sheetContext) {
      VoidCallback? closeThen(VoidCallback? action) => action == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              action();
            };
      return ScriptSpeechSheet(
        viktor: viktor,
        title: title,
        texts: texts,
        onMainLine: closeThen(onMainLine),
        onShowAnswer: closeThen(onShowAnswer),
      );
    },
  );
}

/// O conteúdo da folha da fala inteira (público para os testes).
class ScriptSpeechSheet extends StatelessWidget {
  const ScriptSpeechSheet({
    required this.viktor,
    required this.title,
    required this.texts,
    this.onMainLine,
    this.onShowAnswer,
    super.key,
  });

  final Character viktor;
  final String title;
  final List<String> texts;
  final VoidCallback? onMainLine;
  final VoidCallback? onShowAnswer;

  /// A folga embaixo do texto, acima da barra do sistema.
  static const bottomGap = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      key: LessonScriptKeys.speechSheet,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho de 56 dp: retrato 40 (raio 6) e o nome, como na faixa.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                Hero(
                  tag: scriptViktorHeroTag,
                  child: CharacterAvatar(
                    character: viktor,
                    size: 40,
                    radius: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              bottomGap + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: SpeechText(
              text: texts.join('\n\n'),
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 16,
                height: 24 / 16,
                color: colors.onSurface,
              ),
              onMainLine: onMainLine,
              onShowAnswer: onShowAnswer,
            ),
          ),
        ),
      ],
    );
  }
}
