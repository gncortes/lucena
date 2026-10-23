import '../../../domain/models/attempt.dart';
import '../../../domain/models/challenge_result.dart';
import '../../core/l10n/l10n.dart';

/// "Dei mate com a dama em 9 lances, com 4:52 no relógio": a frase do
/// resultado, na imagem e no texto de compartilhar.
String challengeResultSentence(AppLocalizations l10n, ChallengeResult result) {
  final base = switch (result.outcome) {
    AttemptOutcome.win =>
      result.matingPiece == null
          ? l10n.challengeResultWin(result.moves)
          : l10n.challengeResultMate(result.matingPiece!.name, result.moves),
    AttemptOutcome.draw => l10n.challengeResultDraw,
    AttemptOutcome.loss => l10n.challengeResultLoss,
  };
  final remaining = result.remaining;
  if (remaining == null || !result.won) return base;
  return l10n.challengeResultWithClock(
    base,
    ChallengeResult.clockText(remaining),
  );
}

/// O texto que vai junto com a imagem: a frase, o convite e o endereço
/// inteiro do desafio, que funciona sem servidor (E1.01).
String challengeResultShareText(
  AppLocalizations l10n,
  ChallengeResult result,
) => l10n.challengeResultShareText(
  challengeResultSentence(l10n, result),
  l10n.challengeCanYouFaster,
  result.link.uri.toString(),
);

/// O cabeçalho da imagem.
String challengeResultHeader(AppLocalizations l10n, ChallengeResult result) =>
    switch (result.outcome) {
      AttemptOutcome.win => l10n.challengeImageWon,
      AttemptOutcome.draw => l10n.challengeImageDrawn,
      AttemptOutcome.loss => l10n.challengeImageLost,
    };
