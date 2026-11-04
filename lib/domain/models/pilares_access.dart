/// Como ter o Pilares (H-VEN-03): o acesso vitalício (pagamento único) ou a
/// assinatura mensal.
enum PilaresPlan {
  lifetime('pilares_vitalicio', 'vitalicio'),
  monthly('pilares_mensal', 'mensal');

  const PilaresPlan(this.itemId, this.analytics);

  /// O `item_id` do evento `purchase` (H-VEN-17).
  final String itemId;

  /// O `plano` do `pilares_plano_escolhido`.
  final String analytics;
}

/// O estado de acesso ao Pilares (H-VEN-16), a fonte única do app para
/// trancar capítulos, pedir anúncio e trocar telas.
enum PilaresAccessKind {
  /// Sem compra: Capítulo 1 com anúncio, o resto trancado.
  demo,
  lifetime,
  monthlyActive,

  /// A loja não conseguiu cobrar e dá um prazo para regularizar.
  monthlyGrace,

  /// A assinatura terminou: igual à demo, com o progresso salvo.
  monthlyEnded,
}

/// De onde veio o acesso: a Google Play ou o site (que chega pela conta).
enum PilaresSource { play, site }

/// A cópia do acesso que o aparelho guarda para abrir sem internet. A loja e
/// a conta são a fonte da verdade.
class PilaresAccess {
  const PilaresAccess({
    this.kind = PilaresAccessKind.demo,
    this.since,
    this.renewsAt,
    this.graceUntil,
    this.source = PilaresSource.play,
    this.endedSeen = false,
  });

  /// Quanto a cópia de uma assinatura vale sem confirmar com a loja depois
  /// da renovação (H-VEN-16: só rebaixa ao confirmar com a loja).
  static const offlineGrace = Duration(days: 3);

  final PilaresAccessKind kind;

  /// A data da compra (ou da assinatura).
  final DateTime? since;

  /// A próxima renovação da assinatura mensal.
  final DateTime? renewsAt;

  /// O prazo para regularizar o pagamento ([PilaresAccessKind.monthlyGrace]).
  final DateTime? graceUntil;
  final PilaresSource source;

  /// "Sua assinatura terminou" já apareceu (H-VEN-10: uma vez só).
  final bool endedSeen;

  /// Comprador: os 20 capítulos, sem anúncio e sem chamadas para o Pilares.
  bool get owns => switch (kind) {
    PilaresAccessKind.lifetime ||
    PilaresAccessKind.monthlyActive ||
    PilaresAccessKind.monthlyGrace => true,
    PilaresAccessKind.demo || PilaresAccessKind.monthlyEnded => false,
  };

  bool get monthly =>
      kind == PilaresAccessKind.monthlyActive ||
      kind == PilaresAccessKind.monthlyGrace;

  /// "Sua assinatura terminou" ainda não apareceu.
  bool get showEnded => kind == PilaresAccessKind.monthlyEnded && !endedSeen;

  /// O capítulo [number] (1 a 20) está liberado: o 1 sempre; os outros, só
  /// para quem tem o curso.
  bool chapterUnlocked(int number) => number == 1 || owns;

  /// Abrir uma lição ou a lista de exercícios pede anúncio (nunca um teste).
  bool get lessonNeedsAd => !owns;

  /// A cópia guardada, lida sem a loja em [now]: a assinatura só rebaixa
  /// sozinha muito depois da renovação (ou do prazo), quando a loja não
  /// respondeu por [offlineGrace].
  PilaresAccess offline(DateTime now) {
    final limit = switch (kind) {
      PilaresAccessKind.monthlyActive => renewsAt,
      PilaresAccessKind.monthlyGrace => graceUntil ?? renewsAt,
      _ => null,
    };
    if (limit == null || now.isBefore(limit.add(offlineGrace))) return this;
    return copyWith(kind: PilaresAccessKind.monthlyEnded);
  }

  /// A assinatura confirmada pela loja como encerrada: rebaixa e guarda que
  /// "Sua assinatura terminou" ainda vai aparecer.
  PilaresAccess ended() => kind == PilaresAccessKind.monthlyEnded
      ? this
      : PilaresAccess(
          kind: PilaresAccessKind.monthlyEnded,
          since: since,
          source: source,
        );

  PilaresAccess copyWith({PilaresAccessKind? kind, bool? endedSeen}) =>
      PilaresAccess(
        kind: kind ?? this.kind,
        since: since,
        renewsAt: renewsAt,
        graceUntil: graceUntil,
        source: source,
        endedSeen: endedSeen ?? this.endedSeen,
      );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (since != null) 'since': since!.toIso8601String(),
    if (renewsAt != null) 'renewsAt': renewsAt!.toIso8601String(),
    if (graceUntil != null) 'graceUntil': graceUntil!.toIso8601String(),
    'source': source.name,
    if (endedSeen) 'endedSeen': true,
  };

  /// Cópia ilegível ou de outra versão: demo (a loja corrige ao abrir).
  static PilaresAccess fromJson(Map<String, Object?> json) {
    DateTime? date(String key) => switch (json[key]) {
      final String value => DateTime.tryParse(value),
      _ => null,
    };
    return PilaresAccess(
      kind:
          PilaresAccessKind.values.asNameMap()[json['kind']] ??
          PilaresAccessKind.demo,
      since: date('since'),
      renewsAt: date('renewsAt'),
      graceUntil: date('graceUntil'),
      source:
          PilaresSource.values.asNameMap()[json['source']] ??
          PilaresSource.play,
      endedSeen: json['endedSeen'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PilaresAccess &&
      other.kind == kind &&
      other.since == since &&
      other.renewsAt == renewsAt &&
      other.graceUntil == graceUntil &&
      other.source == source &&
      other.endedSeen == endedSeen;

  @override
  int get hashCode =>
      Object.hash(kind, since, renewsAt, graceUntil, source, endedSeen);

  @override
  String toString() => 'PilaresAccess(${toJson()})';
}
