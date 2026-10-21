/// O que a tabela rei e peão contra rei diz de uma posição (T70).
enum KpkResult {
  /// O lado do peão ganha.
  win,

  /// Empate.
  draw,

  /// A posição não é de rei e peão contra rei (nem coroada): a tabela não
  /// sabe.
  outside,
}

class KpkOutcome {
  const KpkOutcome(this.result, [this.dtm = 0]);

  static const draw = KpkOutcome(KpkResult.draw);
  static const outside = KpkOutcome(KpkResult.outside);

  /// Vitória do lado do peão em [dtm] meios-lances (1–254).
  const KpkOutcome.win(int dtm) : this(KpkResult.win, dtm);

  final KpkResult result;

  /// Meios-lances até a vitória; só vale em [KpkResult.win].
  final int dtm;

  bool get isWin => result == KpkResult.win;
  bool get isDraw => result == KpkResult.draw;
  bool get isOutside => result == KpkResult.outside;

  @override
  bool operator ==(Object other) =>
      other is KpkOutcome && other.result == result && other.dtm == dtm;

  @override
  int get hashCode => Object.hash(result, dtm);

  @override
  String toString() => isWin ? 'win($dtm)' : result.name;
}

/// Como um jogo livre ou uma prática acaba (T70). O `name` é a chave do
/// `livre.fins` dos dados.
enum FreeEnd {
  /// O peão coroou.
  coroa,

  /// O rei sozinho capturou o peão.
  capturado,

  /// O lado que joga ficou sem lances, sem estar em xeque.
  afogado,

  /// A mesma posição pela terceira vez.
  repeticao,

  /// Chegou ao limite de lances.
  limite,

  /// Xeque-mate (objetivo `mate`).
  mate,

  /// Só sobrou material que não dá mate (objetivo `mate`).
  insuficiente,

  /// Sem peões, um lado perdeu a última peça e o outro ficou com uma (T78,
  /// dama contra torre: a torre ganha).
  material;

  /// O fim cumpre o objetivo do aluno: quem quer ganhar precisa coroar (ou
  /// ficar com a peça, que o juiz da tela confere pelo dono); quem quer
  /// empatar cumpre com qualquer outro fim.
  bool meets(bool wantsWin) =>
      wantsWin ? this == coroa : this != coroa && this != material;
}
