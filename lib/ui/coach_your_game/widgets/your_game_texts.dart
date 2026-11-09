import 'package:intl/intl.dart';

import '../../../domain/models/coach/coach.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/coach/your_game_summary.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/board/board_settings_ui.dart';

/// Frase do servidor que entra no meio de outra: sem o ponto final dela.
String? _inMiddle(String? text) {
  final t = text?.trim();
  if (t == null || t.isEmpty) return null;
  return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
}

/// Os textos que as telas do Seu jogo montam a partir dos dados.
extension YourGameTexts on AppLocalizations {
  String platformName(Platform? p) => switch (p) {
    Platform.chesscom => sjPlataformaChesscom,
    _ => sjPlataformaLichess,
  };

  String timeControlName(TimeControl? r) => switch (r) {
    null => sjRitmoTodos,
    TimeControl.bullet => sjRitmoBullet,
    TimeControl.blitz => sjRitmoBlitz,
    TimeControl.rapid => sjRitmoRapida,
  };

  String colorName(GameColor c) =>
      c == GameColor.white ? sjCorBrancas : sjCorPretas;

  String phaseName(GamePhase f) => switch (f) {
    GamePhase.opening => sjFaseAbertura,
    GamePhase.middlegame => sjFaseMeio,
    GamePhase.ending => sjFaseFinal,
  };

  String keyPhase(GamePhase f) => switch (f) {
    GamePhase.opening => 'abertura',
    GamePhase.middlegame => 'meio',
    GamePhase.ending => 'final',
  };

  String levelName(StyleLevel n) => switch (n) {
    StyleLevel.first => sjNivelPrimeira,
    StyleLevel.forming => sjNivelFormacao,
    StyleLevel.solid => sjNivelFirme,
  };

  /// A frase do estilo: o ponto forte e o que acertar, o que houver. Com
  /// [few] partidas (canvas DSeuJogoPoucas), abre com a ressalva "Ainda é
  /// cedo para falar de estilo."
  String styleSummary(PlayerStyle style, {bool few = false}) {
    final strong = _inMiddle(style.strengths.firstOrNull?.text);
    final solve = _inMiddle(style.solve.firstOrNull?.text);
    final summary = switch ((strong, solve)) {
      (final f?, final a?) => sjEstiloResumo(f, a),
      (final f?, null) => sjEstiloSoForte(f),
      (null, final a?) => sjEstiloSoAcertar(a),
      (null, null) => null,
    };
    if (summary == null) return sjEstiloSemLeitura;
    return few ? sjEstiloPoucas(summary) : summary;
  }

  /// O nome do tema; chave que o app ainda não conhece sai legível
  /// (`peca_presa` → "Peca presa").
  String motifName(String motif) {
    final name = sjTemaNome(motif);
    if (name != motif) return name;
    final text = motif.replaceAll('_', ' ').trim();
    if (text.isEmpty) return motif;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// "8...Bg4" ou "8.Cf3", com as letras das peças do idioma.
  String fullMove({
    required int chessMove,
    required bool black,
    required String san,
  }) {
    final local = localizedSan(this, san);
    return black
        ? sjJogadaPretas(chessMove, local)
        : sjJogadaBrancas(chessMove, local);
  }

  /// A jogada do meio-lance [ply] (0 = 1º das brancas).
  String moveOfPly(int ply, String san) =>
      fullMove(chessMove: ply ~/ 2 + 1, black: ply.isOdd, san: san);

  /// "Hoje", "Ontem" ou "8 de nov.".
  String shortDate(DateTime data, Now now) {
    final currentTime = now();
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final local = data.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final days = today.difference(day).inDays;
    if (days <= 0) return sjHoje;
    if (days == 1) return sjOntem;
    return DateFormat.MMMd(localeName).format(local);
  }
}
