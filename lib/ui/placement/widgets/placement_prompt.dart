import '../../../domain/models/board_settings.dart';
import '../../../domain/models/placement.dart';
import '../../core/board/board_settings_ui.dart';
import '../../core/l10n/l10n.dart';

/// O enunciado da pergunta [item], no idioma da tela: a chave do `.arb` e os
/// parâmetros dela vêm do banco (o contrato da T52).
String placementPrompt(AppLocalizations l10n, PlacementItem item) {
  final params = item.params;
  final side = params['side'] ?? 'white';
  final piece = params['piece'] ?? 'pawn';
  return switch (item.prompt) {
    'placementSquares' => l10n.placementSquares(piece),
    'placementCaptureSquares' => l10n.placementCaptureSquares(piece),
    'placementKingEscape' => l10n.placementKingEscape(side),
    'placementTapSquare' => l10n.placementTapSquare(params['square'] ?? ''),
    'placementPlayMove' => l10n.placementPlayMove(
      side,
      _localSan(l10n, params['move'] ?? ''),
    ),
    'placementCheckmate' => l10n.placementCheckmate(side),
    'placementBestMove' => l10n.placementBestMove(side),
    'placementMoveWin' => l10n.placementMoveWin(side),
    'placementMoveDraw' => l10n.placementMoveDraw(side),
    'placementWinMaterial' => l10n.placementWinMaterial(side),
    'placementCheckMateNone' => l10n.placementCheckMateNone(side),
    'placementMateStalemateNone' => l10n.placementMateStalemateNone(side),
    'placementCanCastle' => l10n.placementCanCastle(
      side,
      params['wing'] ?? 'king',
    ),
    'placementCanEnPassant' => l10n.placementCanEnPassant(side),
    'placementInsufficient' => l10n.placementInsufficient,
    'placementCatchPawn' => l10n.placementCatchPawn(
      side,
      params['king'] ?? 'black',
    ),
    'placementResult' => l10n.placementResult(side),
    _ => '',
  };
}

/// O lance em notação algébrica com as letras das peças do idioma
/// (`Nf3` → `Cf3` em português).
String _localSan(AppLocalizations l10n, String san) {
  final letters = MoveNotation.letters.pieceLetters(l10n)!;
  return san.replaceAllMapped(
    RegExp('[KQRBN]'),
    (match) => letters[match[0]] ?? match[0]!,
  );
}

/// O texto de uma opção de pergunta de escolha.
String placementOption(AppLocalizations l10n, String option) =>
    switch (option) {
      'mate' => l10n.placementOptionMate,
      'stalemate' => l10n.placementOptionStalemate,
      'check' => l10n.placementOptionCheck,
      'none' => l10n.placementOptionNone,
      'yes' => l10n.placementOptionYes,
      'no' => l10n.placementOptionNo,
      'whiteWins' => l10n.placementOptionWhiteWins,
      'draw' => l10n.placementOptionDraw,
      'blackWins' => l10n.placementOptionBlackWins,
      _ => option,
    };

/// O nome de um nó do mapa (`rules.bishop` → `skillRulesBishop`).
String skillName(AppLocalizations l10n, String nodeId) =>
    skillNames(l10n)[nodeId] ?? nodeId;

/// O nome de um grupo do mapa.
String skillGroupName(AppLocalizations l10n, SkillGroup group) =>
    switch (group) {
      SkillGroup.rules => l10n.skillGroupRules,
      SkillGroup.mates => l10n.skillGroupMates,
      SkillGroup.pawns => l10n.skillGroupPawns,
      SkillGroup.queenRook => l10n.skillGroupQueenRook,
      SkillGroup.minor => l10n.skillGroupMinor,
      SkillGroup.tactics => l10n.skillGroupTactics,
    };

/// Os nomes dos nós do mapa, pelo id.
Map<String, String> skillNames(AppLocalizations l10n) => {
  'rules.rook': l10n.skillRulesRook,
  'rules.bishop': l10n.skillRulesBishop,
  'rules.queen': l10n.skillRulesQueen,
  'rules.king': l10n.skillRulesKing,
  'rules.knight': l10n.skillRulesKnight,
  'rules.pawn': l10n.skillRulesPawn,
  'rules.capture': l10n.skillRulesCapture,
  'rules.check': l10n.skillRulesCheck,
  'rules.outOfCheck': l10n.skillRulesOutOfCheck,
  'rules.stalemate': l10n.skillRulesStalemate,
  'rules.castling': l10n.skillRulesCastling,
  'rules.enPassant': l10n.skillRulesEnPassant,
  'rules.draws': l10n.skillRulesDraws,
  'rules.pieceValue': l10n.skillRulesPieceValue,
  'notation.squares': l10n.skillNotationSquares,
  'notation.moves': l10n.skillNotationMoves,
  'mate.inOne': l10n.skillMateInOne,
  'mate.twoRooks': l10n.skillMateTwoRooks,
  'mate.queen': l10n.skillMateQueen,
  'mate.rook': l10n.skillMateRook,
  'mate.patterns': l10n.skillMatePatterns,
  'mate.twoBishops': l10n.skillMateTwoBishops,
  'mate.bishopKnight': l10n.skillMateBishopKnight,
  'mate.twoKnightsPawn': l10n.skillMateTwoKnightsPawn,
  'pawns.square': l10n.skillPawnsSquare,
  'pawns.opposition': l10n.skillPawnsOpposition,
  'pawns.kingPawn': l10n.skillPawnsKingPawn,
  'pawns.rookPawnDraw': l10n.skillPawnsRookPawnDraw,
  'pawns.keySquares': l10n.skillPawnsKeySquares,
  'pawns.distantOpposition': l10n.skillPawnsDistantOpposition,
  'pawns.race': l10n.skillPawnsRace,
  'pawns.triangulation': l10n.skillPawnsTriangulation,
  'pawns.reti': l10n.skillPawnsReti,
  'pawns.shoulder': l10n.skillPawnsShoulder,
  'pawns.breakthrough': l10n.skillPawnsBreakthrough,
  'pawns.outsidePasser': l10n.skillPawnsOutsidePasser,
  'pawns.protectedPasser': l10n.skillPawnsProtectedPasser,
  'pawns.trebuchet': l10n.skillPawnsTrebuchet,
  'pawns.spareTempi': l10n.skillPawnsSpareTempi,
  'pawns.correspondingSquares': l10n.skillPawnsCorrespondingSquares,
  'queen.vsPawn': l10n.skillQueenVsPawn,
  'queen.vsPawnDraws': l10n.skillQueenVsPawnDraws,
  'queen.vsRook': l10n.skillQueenVsRook,
  'queen.vsRookPawn': l10n.skillQueenVsRookPawn,
  'queen.pawnVsQueen': l10n.skillQueenPawnVsQueen,
  'rook.vsPawn': l10n.skillRookVsPawn,
  'rook.saavedra': l10n.skillRookSaavedra,
  'rook.vsTwoPawns': l10n.skillRookVsTwoPawns,
  'rook.lucena': l10n.skillRookLucena,
  'rook.philidor': l10n.skillRookPhilidor,
  'rook.backRank': l10n.skillRookBackRank,
  'rook.shortSide': l10n.skillRookShortSide,
  'rook.cutOff': l10n.skillRookCutOff,
  'rook.frontal': l10n.skillRookFrontal,
  'rook.rookPawn': l10n.skillRookRookPawn,
  'rook.vancura': l10n.skillRookVancura,
  'rook.behindPasser': l10n.skillRookBehindPasser,
  'rook.twoPawns': l10n.skillRookTwoPawns,
  'rook.practical': l10n.skillRookPractical,
  'minor.wrongBishop': l10n.skillMinorWrongBishop,
  'minor.knightVsPawn': l10n.skillMinorKnightVsPawn,
  'minor.bishopVsPawns': l10n.skillMinorBishopVsPawns,
  'minor.oppositeBishops': l10n.skillMinorOppositeBishops,
  'minor.centurini': l10n.skillMinorCenturini,
  'minor.knightEndings': l10n.skillMinorKnightEndings,
  'minor.bishopVsKnight': l10n.skillMinorBishopVsKnight,
  'rookMinor.vsMinor': l10n.skillRookMinorVsMinor,
  'rookMinor.exchange': l10n.skillRookMinorExchange,
  'rookMinor.vsRook': l10n.skillRookMinorVsRook,
  'school.minorMates': l10n.skillSchoolMinorMates,
  'tactics.basic': l10n.skillTacticsBasic,
  'tactics.endgame': l10n.skillTacticsEndgame,
};
