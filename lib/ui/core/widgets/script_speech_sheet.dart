import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../keys/lesson_script_keys.dart';
import '../theme/app_spacing.dart';
import 'character_avatar.dart';
import 'script_sheet_route.dart';
import 'speech_balloon.dart';
import 'speech_sheet_fade.dart';

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
  Key? sheetKey,
  VoidCallback? onMainLine,
  VoidCallback? onShowAnswer,
  ValueChanged<String>? onSquareTap,
  WidgetBuilder? headerBuilder,
  Widget? action,
  Color? background,
  double horizontalPadding = 24,
  double headerHeight = 56,
  bool canvasLayout = false,
}) {
  SpeechSheetFade.open.value = true;
  return showScriptSheet(
    context,
    maxHeightFactor: 0.7,
    closeKey: LessonScriptKeys.speechSheetClose,
    color: background,
    closeGap: canvasLayout ? 10 : null,
    closeMargin: canvasLayout ? 14 : null,
    builder: (sheetContext) {
      VoidCallback? closeThen(VoidCallback? action) => action == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              action();
            };
      // A casa tocada fecha a folha (ela cobre o tabuleiro) e a tela a realça.
      final onSquare = onSquareTap;
      return KeyedSubtree(
        key: sheetKey,
        child: SpeechSheetFade.exempt(
          child: ScriptSpeechSheet(
            viktor: viktor,
            title: title,
            texts: texts,
            onMainLine: closeThen(onMainLine),
            onShowAnswer: closeThen(onShowAnswer),
            onSquareTap: onSquare == null
                ? null
                : (square) {
                    Navigator.of(sheetContext).pop();
                    onSquare(square);
                  },
            headerBuilder: headerBuilder,
            action: action,
            horizontalPadding: horizontalPadding,
            headerHeight: headerHeight,
            canvasLayout: canvasLayout,
          ),
        ),
      );
    },
  ).whenComplete(() => SpeechSheetFade.open.value = false);
}

/// O conteúdo da folha da fala inteira (público para os testes).
class ScriptSpeechSheet extends StatelessWidget {
  const ScriptSpeechSheet({
    required this.viktor,
    required this.title,
    required this.texts,
    this.onMainLine,
    this.onShowAnswer,
    this.onSquareTap,
    this.headerBuilder,
    this.action,
    this.horizontalPadding = 24,
    this.headerHeight = 56,
    this.canvasLayout = false,
    super.key,
  });

  final Character viktor;
  final String title;
  final List<String> texts;
  final VoidCallback? onMainLine;
  final VoidCallback? onShowAnswer;
  final ValueChanged<String>? onSquareTap;

  /// O cabeçalho no lugar do retrato e do nome (o exercício leva o mesmo da
  /// faixa, com borrar e som).
  final WidgetBuilder? headerBuilder;

  /// No fim do cabeçalho padrão: o botão de som (T84).
  final Widget? action;

  /// A margem dos lados do cabeçalho e do texto (canvas `PropV2ExA7`: 16).
  final double horizontalPadding;
  final double headerHeight;
  final bool canvasLayout;

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
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.sm,
            horizontalPadding,
            0,
          ),
          child: SizedBox(
            height: headerHeight,
            child: headerBuilder != null
                ? headerBuilder!(context)
                : Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: canvasLayout ? 44 : headerHeight,
                      child: Row(
                        children: [
                          Hero(
                            tag: scriptViktorHeroTag,
                            child: CharacterAvatar(
                              character: viktor,
                              size: CharacterAvatar.lesson,
                              radius: 6,
                            ),
                          ),
                          SizedBox(width: canvasLayout ? 12 : AppSpacing.md),
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                letterSpacing: canvasLayout ? 0 : null,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          ?action,
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              AppSpacing.sm,
              horizontalPadding,
              bottomGap +
                  (canvasLayout ? 0 : MediaQuery.viewPaddingOf(context).bottom),
            ),
            child: SpeechText(
              text: texts.join('\n\n'),
              textHeightBehavior: canvasLayout
                  ? const TextHeightBehavior(applyHeightToLastDescent: false)
                  : null,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontSize: 15,
                height: 1.5,
                letterSpacing: canvasLayout ? 0 : null,
                color: colors.onSurface,
              ),
              onMainLine: onMainLine,
              onShowAnswer: onShowAnswer,
              onSquareTap: onSquareTap,
            ),
          ),
        ),
      ],
    );
  }
}
