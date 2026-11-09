import '../../models/treinador/treinador.dart';

/// A abertura da partida no repertório do Pilares: o "slot" das lições
/// (`pilares.ab1.slav1` → `slav`). Fora do repertório: `null` (a aba mostra
/// só a teoria e as partidas-modelo).
///
/// Vale o que o servidor ligou (`curso.id`, um id de lição ou o próprio
/// slot); sem isso, a faixa de ECO das aberturas do curso, na cor certa.
String? slotDaAbertura({
  required String eco,
  required String nome,
  required CorPartida cor,
  CursoLigado? curso,
}) {
  if (curso != null) {
    final ultimo = curso.id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
    if (slotsDoPilares.contains(ultimo)) return ultimo;
  }
  final letra = eco.isEmpty ? '' : eco[0].toUpperCase();
  final numero = int.tryParse(eco.length >= 3 ? eco.substring(1, 3) : '');
  final n = nome.toLowerCase();
  bool faixa(String l, int de, int ate) =>
      letra == l && numero != null && numero >= de && numero <= ate;
  if (cor == CorPartida.pretas) {
    if (faixa('D', 10, 19) || n.contains('eslava') || n.contains('slav')) {
      return 'slav';
    }
    if (faixa('B', 10, 19) || n.contains('caro')) return 'caroKann';
    if (faixa('B', 34, 39) || n.contains('drag')) return 'dragon';
    if (faixa('E', 60, 99) ||
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
const slotsDoPilares = {
  'london',
  'caroKann',
  'slav',
  'e4White',
  'dragon',
  'kingsIndian',
};

/// O slot de uma lição do curso (`pilares.ab3.slav3` → `slav`).
String slotDaLicao(String id) =>
    id.split('.').last.replaceAll(RegExp(r'\d+$'), '');
