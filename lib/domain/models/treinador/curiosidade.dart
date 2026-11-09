/// Uma curiosidade de xadrez da tela de espera da análise.
final class Curiosidade {
  const Curiosidade({
    required this.id,
    required this.tema,
    required this.texto,
  });

  final String id;
  final String tema;
  final String texto;

  static Curiosidade? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'], texto = json['texto'];
    if (id is! String || texto is! String || texto.isEmpty) return null;
    final tema = json['tema'];
    return Curiosidade(id: id, tema: tema is String ? tema : '', texto: texto);
  }
}
