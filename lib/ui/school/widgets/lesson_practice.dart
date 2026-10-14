import 'package:flutter/material.dart';

import '../../../domain/models/character.dart';
import '../../../domain/use_cases/wiki_markup.dart';
import '../../core/keys/school_keys.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/character_speech.dart';
import '../../core/widgets/exercise_actions.dart';
import '../../core/widgets/exercise_frame.dart';

/// O convite e o passo prático (`move`/`play`) da lição, no layout da tela de
/// exercício (T70, pg. 3.1 e 4.x): o Viktor no alto com o balão, o tabuleiro
/// centralizado e o rodapé. Sem view model: a tela da lição traduz o estado
/// do cubit nestes parâmetros (`practiceGate`, `practiceComment`,
/// `speechMode`, `typing`, `canUndo`/`canRedo`).
class LessonPractice extends StatelessWidget {
  const LessonPractice({
    required this.viktor,
    required this.board,
    required this.expanded,
    required this.onExpandedChanged,
    this.invite = false,
    this.comment,
    this.hint = false,
    this.typing = false,
    this.onStart,
    this.onInviteBack,
    this.onHint,
    this.onBack,
    this.onContinue,
    super.key,
  });

  final Character viktor;

  /// O tabuleiro, com o lado calculado pela regra do centro.
  final Widget Function(BuildContext context, double size) board;

  /// O balão grande aberto (estado do cubit: `speechMode`).
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  /// O convite "Vamos praticar" (antes do 1º lance da parte).
  final bool invite;

  /// A fala do Viktor (enunciado, comentário do último lance ou Dica).
  final String? comment;

  /// A fala é a Dica: leva o selo "Dica".
  final bool hint;

  /// A máquina está respondendo: três pontinhos no balão.
  final bool typing;

  /// Convite: "Vamos praticar" e "Voltar" ao último passo de aprendizado.
  final VoidCallback? onStart;
  final VoidCallback? onInviteBack;

  /// Prático: a Dica (sempre), "Voltar" (desfaz o par; na vez inicial leva ao
  /// convite) e "Continuar" (só com ação: refaz o par ou vai à próxima
  /// parte). Nulo some o botão.
  final VoidCallback? onHint;
  final VoidCallback? onBack;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final said = comment;
    final text = invite
        ? l10n.lessonPracticeInvite
        : said == null
        ? null
        : WikiMarkup.parse(said).text;
    return ExerciseFrame(
      boardKey: LessonKeys.practiceBoard,
      board: board,
      character: KeyedSubtree(
        key: LessonKeys.practiceViktor,
        child: CharacterSpeech(
          character: viktor,
          text: text,
          typing: typing,
          lead: hint && !invite ? l10n.lessonHint : null,
          expanded: expanded,
          onExpandedChanged: onExpandedChanged,
          bubbleKey: invite
              ? LessonKeys.practiceInvite
              : LessonKeys.practiceSpeech,
          closeKey: LessonKeys.practiceSpeechClose,
          scrollKey: LessonKeys.practiceSpeechScroll,
          typingKey: LessonKeys.practiceTyping,
        ),
      ),
      footer: invite
          ? ExerciseActions(
              fill: true,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
              actions: [
                ExerciseAction(
                  label: l10n.lessonFooterBack,
                  onPressed: onInviteBack,
                  key: LessonKeys.practiceInviteBack,
                ),
                ExerciseAction(
                  label: l10n.lessonPracticeStart,
                  onPressed: onStart,
                  key: LessonKeys.practiceButton,
                  primary: true,
                ),
              ],
            )
          : ExerciseActions(
              hint: KeyedSubtree(
                key: LessonKeys.hintButton,
                child: ExerciseHintButton(
                  label: l10n.lessonHint,
                  onPressed: onHint,
                ),
              ),
              actions: [
                if (onBack != null)
                  ExerciseAction(
                    label: l10n.lessonFooterBack,
                    onPressed: onBack,
                    key: LessonKeys.practiceBack,
                  ),
                if (onContinue != null)
                  ExerciseAction(
                    label: l10n.lessonContinue,
                    onPressed: onContinue,
                    key: LessonKeys.practiceContinue,
                    primary: true,
                  ),
              ],
            ),
    );
  }
}
