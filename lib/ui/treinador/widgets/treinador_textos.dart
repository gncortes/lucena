import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../core/l10n/l10n.dart';

/// Os nomes das coisas do Treinador nas telas (ritmo, cor, resultado, site).
extension TreinadorTextos on BuildContext {
  String plataforma(Plataforma p) => switch (p) {
    Plataforma.lichess => l10n.treinadorLichess,
    Plataforma.chesscom => l10n.treinadorChesscom,
  };

  /// O site da partida pelo prefixo do id (`lichess_...`, `chesscom_...`).
  String plataformaDaPartida(PartidaTreinador p) =>
      plataforma(Plataforma.parse(p.plataforma) ?? Plataforma.lichess);

  String ritmo(Ritmo r) => switch (r) {
    Ritmo.bullet => l10n.treinadorRitmoBullet,
    Ritmo.blitz => l10n.treinadorRitmoBlitz,
    Ritmo.rapida => l10n.treinadorRitmoRapida,
  };

  String cor(CorPartida c) => switch (c) {
    CorPartida.brancas => l10n.treinadorCorBrancas,
    CorPartida.pretas => l10n.treinadorCorPretas,
  };

  String resultado(Resultado r) => switch (r) {
    Resultado.vitoria => l10n.treinadorVitoria,
    Resultado.derrota => l10n.treinadorDerrota,
    Resultado.empate => l10n.treinadorEmpate,
  };

  String letraDoResultado(Resultado r) => switch (r) {
    Resultado.vitoria => l10n.treinadorLetraVitoria,
    Resultado.derrota => l10n.treinadorLetraDerrota,
    Resultado.empate => l10n.treinadorLetraEmpate,
  };

  /// "Hoje", "Ontem", "Há 3 dias" (até 6) ou a data curta ("3 de nov.").
  String quando(DateTime jogadaEm, DateTime agora) {
    final local = jogadaEm.toLocal();
    final dia = DateTime(local.year, local.month, local.day);
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dias = hoje.difference(dia).inDays;
    if (dias <= 0) return l10n.treinadorQuandoHoje;
    if (dias == 1) return l10n.treinadorQuandoOntem;
    if (dias < 7) return l10n.treinadorQuandoDias(dias);
    return DateFormat.MMMd(Localizations.localeOf(this).toString()).format(dia);
  }
}
