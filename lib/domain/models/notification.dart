/// Um canal do Android (8+): a pessoa liga e desliga cada um nos ajustes.
class NotificationChannelSpec {
  const NotificationChannelSpec({required this.id, required this.name});

  final String id;
  final String name;
}

/// Uma notificação local agendada no aparelho.
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.at,
    required this.payload,
    this.action,
    this.repeatWeekly = false,
  });

  final int id;
  final NotificationChannelSpec channel;
  final String title;
  final String body;

  /// Quando sai (qualquer fuso: vai em UTC para o aparelho).
  final DateTime at;

  /// O que o toque abre (uma rota do app).
  final String payload;

  /// O botão da notificação, que abre o mesmo [payload].
  final String? action;

  /// Repeat in Android's local calendar after the explicit first date.
  final bool repeatWeekly;
}

/// Uma notificação mostrada agora (o push que o app monta, E1.19 3.8).
class ShownNotification {
  const ShownNotification({
    required this.id,
    required this.channel,
    required this.title,
    required this.body,
    required this.payload,
    this.subText,
    this.actions = const [],
  });

  final int id;
  final NotificationChannelSpec channel;
  final String title;
  final String body;
  final String payload;

  /// O texto ao lado do nome do app no cabeçalho ("Lucena · subText").
  final String? subText;

  /// Os botões: id e rótulo.
  final List<({String id, String label})> actions;
}

/// Um toque numa notificação: o [payload] dela e o botão ([action]; nulo no
/// corpo).
class NotificationTap {
  const NotificationTap(this.payload, {this.action});

  final String payload;
  final String? action;
}
