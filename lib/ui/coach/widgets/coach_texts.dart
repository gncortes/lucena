import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/coach/coach.dart';
import '../../core/l10n/l10n.dart';

/// Os nomes das coisas do Treinador nas telas (ritmo, cor, resultado, site).
extension CoachTexts on BuildContext {
  String platform(Platform p) => switch (p) {
    Platform.lichess => l10n.treinadorLichess,
    Platform.chesscom => l10n.treinadorChesscom,
  };

  String timeControl(TimeControl r) => switch (r) {
    TimeControl.bullet => l10n.treinadorRitmoBullet,
    TimeControl.blitz => l10n.treinadorRitmoBlitz,
    TimeControl.rapid => l10n.treinadorRitmoRapida,
  };

  String color(GameColor c) => switch (c) {
    GameColor.white => l10n.treinadorCorBrancas,
    GameColor.black => l10n.treinadorCorPretas,
  };

  String result(GameResult r) => switch (r) {
    GameResult.win => l10n.treinadorVitoria,
    GameResult.loss => l10n.treinadorDerrota,
    GameResult.draw => l10n.treinadorEmpate,
  };

  String resultLetter(GameResult r) => switch (r) {
    GameResult.win => l10n.treinadorLetraVitoria,
    GameResult.loss => l10n.treinadorLetraDerrota,
    GameResult.draw => l10n.treinadorLetraEmpate,
  };

  /// "Hoje", "Ontem", "Há 3 dias" (até 6) ou a data curta ("3 de nov.").
  String when_(DateTime moveAt, DateTime currentTime) {
    final local = moveAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );
    final days = today.difference(day).inDays;
    if (days <= 0) return l10n.treinadorQuandoHoje;
    if (days == 1) return l10n.treinadorQuandoOntem;
    if (days < 7) return l10n.treinadorQuandoDias(days);
    return DateFormat.MMMd(Localizations.localeOf(this).toString()).format(day);
  }
}
