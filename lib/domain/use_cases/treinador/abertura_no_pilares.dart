import '../../models/training/training_content.dart';
import '../../models/training/training_resources.dart';
import '../../models/training/training_state.dart';
import 'abertura_no_curso.dart';

/// Uma lição (parte) de uma abertura do Pilares.
final class ParteDaAbertura {
  const ParteDaAbertura({
    required this.numero,
    required this.licao,
    required this.feita,
  });

  /// 1, 2, 3… na ordem do curso.
  final int numero;
  final TrainingLesson licao;
  final bool feita;
}

/// As partes de uma abertura no curso e a que o Treinador põe em evidência.
final class AberturaNoPilares {
  const AberturaNoPilares({
    required this.slot,
    required this.partes,
    required this.destaque,
  });

  final String slot;
  final List<ParteDaAbertura> partes;

  /// A parte que trata do ponto fraco: a que o servidor ligou; sem isso, a
  /// primeira por fazer (ou a primeira, se todas estão feitas).
  final ParteDaAbertura destaque;

  /// O repertório da abertura (`solido` ou `agressivo`).
  String get perfil => const {'london', 'caroKann', 'slav'}.contains(slot)
      ? 'solido'
      : 'agressivo';

  bool get todasFeitas => partes.every((p) => p.feita);
}

/// As lições do [slot] no curso, na ordem dele, com a parte em destaque.
/// `null` quando o curso não tem essa abertura.
AberturaNoPilares? aberturaNoPilares({
  required String slot,
  required TrainingResources resources,
  TrainingState? estado,
  int? parteDoServidor,
}) {
  final licoes = [
    for (final l in resources.lessons)
      if (slotDaLicao(l.id) == slot ||
          resources.openings[l.id]?.firstOrNull?.openingId == slot)
        l,
  ];
  if (licoes.isEmpty) return null;
  final feitas = estado?.completedLessons ?? const <String, String>{};
  final partes = [
    for (final (i, l) in licoes.indexed)
      ParteDaAbertura(numero: i + 1, licao: l, feita: feitas.containsKey(l.id)),
  ];
  final doServidor = parteDoServidor == null
      ? null
      : partes.where((p) => p.numero == parteDoServidor).firstOrNull;
  final destaque =
      doServidor ?? partes.where((p) => !p.feita).firstOrNull ?? partes.first;
  return AberturaNoPilares(slot: slot, partes: partes, destaque: destaque);
}
