import '../../models/coach/coach.dart';

/// A abertura da partida no repertório do Pilares: o "slot" das lições
/// (`pilares.ab1.slav1` → `slav`). Fora do repertório: `null` (a aba mostra
/// só a teoria e as partidas-modelo).
///
/// Vale o que o servidor ligou (`curso.id`, um id de lição ou o próprio
/// slot); sem isso, a faixa de ECO das aberturas do curso, na cor certa.
String? openingSlot({
  required String eco,
  required String name,
  required GameColor color,
  LinkedCourse? course,
}) {
  if (course != null) {
    final lastOne = course.id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
    if (pilaresSlots.contains(lastOne)) return lastOne;
  }
  final letter = eco.isEmpty ? '' : eco[0].toUpperCase();
  final number = int.tryParse(eco.length >= 3 ? eco.substring(1, 3) : '');
  final n = name.toLowerCase();
  bool band(String l, int of, int until) =>
      letter == l && number != null && number >= of && number <= until;
  if (color == GameColor.black) {
    if (band('D', 10, 19) || n.contains('eslava') || n.contains('slav')) {
      return 'slav';
    }
    if (band('B', 10, 19) || n.contains('caro')) return 'caroKann';
    if (band('B', 34, 39) || n.contains('drag')) return 'dragon';
    if (band('E', 60, 99) ||
        n.contains('índia do rei') ||
        n.contains("king's indian")) {
      return 'kingsIndian';
    }
    return null;
  }
  if (n.contains('londres') || n.contains('london')) return 'london';
  return null;
}

/// Os slots de abertura do Pilares, nos dois repertórios.
const pilaresSlots = {
  'london',
  'caroKann',
  'slav',
  'e4White',
  'dragon',
  'kingsIndian',
};

/// O slot de uma lição do curso (`pilares.ab3.slav3` → `slav`).
String lessonSlot(String id) =>
    id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
