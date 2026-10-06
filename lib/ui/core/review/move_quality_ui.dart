import 'package:flutter/material.dart';

import '../../../domain/models/game_review.dart';
import '../../../l10n/app_localizations.dart';

/// Como cada qualidade de lance aparece: o símbolo do xadrez, a cor (a dos
/// grandes sites de análise) e o nome.
extension MoveQualityUi on MoveQuality {
  /// O símbolo, de no máximo dois caracteres (cabe na anotação do tabuleiro).
  String get symbol => switch (this) {
    MoveQuality.forced => '□',
    MoveQuality.great => '!',
    MoveQuality.best => '★',
    MoveQuality.excellent => '✓',
    MoveQuality.good => '✓',
    MoveQuality.inaccuracy => '?!',
    MoveQuality.mistake => '?',
    MoveQuality.miss => '✗',
    MoveQuality.blunder => '??',
  };

  Color get color => switch (this) {
    MoveQuality.forced => const Color(0xFF8B9A87),
    MoveQuality.great => const Color(0xFF5C8BB0),
    MoveQuality.best => const Color(0xFF81B64C),
    MoveQuality.excellent => const Color(0xFF96BC4B),
    MoveQuality.good => const Color(0xFF8FA87B),
    MoveQuality.inaccuracy => const Color(0xFFE6B422),
    MoveQuality.mistake => const Color(0xFFF08A3C),
    MoveQuality.miss => const Color(0xFFEE6A5C),
    MoveQuality.blunder => const Color(0xFFD9372A),
  };

  String label(AppLocalizations l10n) => switch (this) {
    MoveQuality.forced => l10n.qualityForced,
    MoveQuality.great => l10n.qualityGreat,
    MoveQuality.best => l10n.qualityBest,
    MoveQuality.excellent => l10n.qualityExcellent,
    MoveQuality.good => l10n.qualityGood,
    MoveQuality.inaccuracy => l10n.qualityInaccuracy,
    MoveQuality.mistake => l10n.qualityMistake,
    MoveQuality.miss => l10n.qualityMiss,
    MoveQuality.blunder => l10n.qualityBlunder,
  };
}

/// O símbolo da qualidade num círculo da cor dela.
class MoveQualityBadge extends StatelessWidget {
  const MoveQualityBadge(this.quality, {this.size = 20, super.key});

  final MoveQuality quality;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: quality.color, shape: BoxShape.circle),
    child: Text(
      quality.symbol,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        color: Colors.white,
        fontSize: size * (quality.symbol.length > 1 ? 0.5 : 0.62),
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    ),
  );
}

/// A avaliação como os sites mostram: `+1,2`, `−0,4`, `M3`, `−M2`, `#`.
String formatScore(EngineScore score, String locale) {
  if (score.mated != null) return '#';
  final mate = score.mate;
  if (mate != null) return mate > 0 ? 'M$mate' : '−M${-mate}';
  final cp = score.centipawns ?? 0;
  final pawns = (cp.abs() / 100).toStringAsFixed(1);
  final text = locale.startsWith('en') ? pawns : pawns.replaceAll('.', ',');
  if (cp == 0) return text;
  return cp > 0 ? '+$text' : '−$text';
}
