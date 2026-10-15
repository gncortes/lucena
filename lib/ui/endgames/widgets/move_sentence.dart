import '../../../domain/use_cases/move_words.dart';
import '../../../l10n/app_localizations.dart';

/// A frase do balão para um lance sem comentário escrito: descreve o lance em
/// palavras (sem notação, a casa entre [colchetes]) e fecha com a avaliação
/// quando o lance é bom (`!`), ruim (`?`) ou perdedor (`??`).
String moveSentence(
  AppLocalizations l10n, {
  required String fenBefore,
  required String uci,
  String? symbol,
}) {
  final words = MoveWords.of(fenBefore, uci);
  final tail = switch (symbol) {
    '??' => l10n.exerciseNodeLosesTail,
    '?' => l10n.exerciseNodeBadTail,
    '!' => l10n.exerciseNodeGoodTail,
    _ => null,
  };
  if (words == null) return tail ?? '';
  final promo = words.promotion;
  final sentence = switch ((promo, words.capture)) {
    (final promo?, true) => l10n.exerciseMovePromoteCapture(words.to, promo),
    (final promo?, false) => l10n.exerciseMovePromote(words.to, promo),
    (null, true) => l10n.exerciseMoveCapture(words.piece, words.to),
    (null, false) => l10n.exerciseMoveGo(words.piece, words.to),
  };
  return tail == null ? sentence : '$sentence $tail';
}
