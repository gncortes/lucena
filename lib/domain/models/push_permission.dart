/// A permissão de notificação deste aparelho, como o painel lê em
/// `users/{uid}/push/device.permissao` (H-R5-60, A11).
enum PushPermission {
  /// Pode mostrar avisos.
  allowed('permitida'),

  /// A pessoa recusou (no pedido do app ou nos ajustes do Android).
  denied('negada'),

  /// O app ainda não perguntou.
  never('nunca');

  const PushPermission(this.wire);

  /// O valor gravado no Firestore.
  final String wire;
}

/// O estado do push do aparelho gravado a cada abertura do app.
final class PushDeviceStatus {
  const PushDeviceStatus({
    required this.permission,
    required this.checkedAt,
    required this.openedAt,
  });

  final PushPermission permission;

  /// Quando a permissão foi conferida.
  final DateTime checkedAt;

  /// A última abertura do app neste aparelho.
  final DateTime openedAt;

  Map<String, Object?> toFirestore() => {
    'permissao': permission.wire,
    'conferidoEm': checkedAt,
    'ultimaAbertura': openedAt,
  };
}
