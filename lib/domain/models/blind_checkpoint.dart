/// Durable state of a blind game. Values are primitives so the checkpoint
/// stays independent of platform services and presentation objects.
class BlindCheckpoint {
  const BlindCheckpoint({
    required this.setup,
    required this.moves,
    required this.state,
  });

  final Map<String, Object?> setup;
  final List<String> moves;
  final Map<String, Object?> state;

  Map<String, Object?> toJson() => {
    'version': 1,
    'setup': setup,
    'moves': moves,
    'state': state,
  };

  factory BlindCheckpoint.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported blind checkpoint');
    }
    return BlindCheckpoint(
      setup: Map<String, Object?>.from(json['setup'] as Map),
      moves: (json['moves'] as List).cast<String>(),
      state: Map<String, Object?>.from(json['state'] as Map),
    );
  }
}
