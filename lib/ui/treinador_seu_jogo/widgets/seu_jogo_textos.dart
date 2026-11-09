import 'package:intl/intl.dart';

import '../../../domain/models/treinador/treinador.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/treinador/resumo_seu_jogo.dart';
import '../../../l10n/app_localizations.dart';
import '../../core/board/board_settings_ui.dart';

/// Os textos que as telas do Seu jogo montam a partir dos dados.
extension SeuJogoTextos on AppLocalizations {
  String plataformaNome(Plataforma? p) => switch (p) {
    Plataforma.chesscom => sjPlataformaChesscom,
    _ => sjPlataformaLichess,
  };

  String ritmoNome(Ritmo? r) => switch (r) {
    null => sjRitmoTodos,
    Ritmo.bullet => sjRitmoBullet,
    Ritmo.blitz => sjRitmoBlitz,
    Ritmo.rapida => sjRitmoRapida,
  };

  String corNome(CorPartida c) =>
      c == CorPartida.brancas ? sjCorBrancas : sjCorPretas;

  String faseNome(FaseDoJogo f) => switch (f) {
    FaseDoJogo.abertura => sjFaseAbertura,
    FaseDoJogo.meio => sjFaseMeio,
    FaseDoJogo.finalDaPartida => sjFaseFinal,
  };

  String faseChave(FaseDoJogo f) => switch (f) {
    FaseDoJogo.abertura => 'abertura',
    FaseDoJogo.meio => 'meio',
    FaseDoJogo.finalDaPartida => 'final',
  };

  String nivelNome(NivelEstilo n) => switch (n) {
    NivelEstilo.primeira => sjNivelPrimeira,
    NivelEstilo.formacao => sjNivelFormacao,
    NivelEstilo.firme => sjNivelFirme,
  };

  /// A frase do estilo: o ponto forte e o que acertar, o que houver.
  String estiloResumo(EstiloJogador estilo) {
    final forte = estilo.fortes.firstOrNull?.texto;
    final acertar = estilo.acertar.firstOrNull?.texto;
    return switch ((forte, acertar)) {
      (final f?, final a?) => sjEstiloResumo(f, a),
      (final f?, null) => sjEstiloSoForte(f),
      (null, final a?) => sjEstiloSoAcertar(a),
      (null, null) => sjEstiloSemLeitura,
    };
  }

  /// O nome do tema; chave que o app ainda não conhece sai legível
  /// (`peca_presa` → "Peca presa").
  String temaNome(String tema) {
    final nome = sjTemaNome(tema);
    if (nome != tema) return nome;
    final texto = tema.replaceAll('_', ' ').trim();
    if (texto.isEmpty) return tema;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  /// "8...Bg4" ou "8.Cf3", com as letras das peças do idioma.
  String jogada({
    required int lance,
    required bool pretas,
    required String san,
  }) {
    final local = localizedSan(this, san);
    return pretas
        ? sjJogadaPretas(lance, local)
        : sjJogadaBrancas(lance, local);
  }

  /// A jogada do meio-lance [ply] (0 = 1º das brancas).
  String jogadaDoPly(int ply, String san) =>
      jogada(lance: ply ~/ 2 + 1, pretas: ply.isOdd, san: san);

  /// "Hoje", "Ontem" ou "8 de nov.".
  String dataCurta(DateTime data, Now now) {
    final agora = now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final local = data.toLocal();
    final dia = DateTime(local.year, local.month, local.day);
    final dias = hoje.difference(dia).inDays;
    if (dias <= 0) return sjHoje;
    if (dias == 1) return sjOntem;
    return DateFormat.MMMd(localeName).format(local);
  }
}
