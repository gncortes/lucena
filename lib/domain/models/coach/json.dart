/// Leitura tolerante dos documentos do treinador (T87). O servidor é dono do
/// formato; um campo que falta ou vem com outro tipo vira o padrão em vez de
/// derrubar a tela.
library;

String? text(Object? value) => value is String ? value : null;

int integer(Object? value, [int fallback = 0]) => switch (value) {
  final int i => i,
  final num n => n.round(),
  final String s => int.tryParse(s) ?? fallback,
  _ => fallback,
};

int? intOrNull(Object? value) => switch (value) {
  final int i => i,
  final num n => n.round(),
  _ => null,
};

double? number(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};

bool logical(Object? value) => value == true;

/// `DateTime` (o serviço já troca o Timestamp), texto ISO 8601 ou
/// milissegundos.
DateTime? data(Object? value) => switch (value) {
  final DateTime d => d,
  final String s => DateTime.tryParse(s),
  final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
  _ => null,
};

Map<String, Object?> asMap(Object? value) =>
    value is Map ? value.cast<String, Object?>() : const {};

List<Object?> list(Object? value) =>
    value is List ? value.cast<Object?>() : const [];

List<String> texts(Object? value) => [
  for (final v in list(value))
    if (v is String) v,
];

T? byWire<T extends Enum>(List<T> values, String Function(T) wire, Object? v) {
  for (final value in values) {
    if (wire(value) == v) return value;
  }
  return null;
}
