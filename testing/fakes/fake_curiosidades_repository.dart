import 'package:lucena/data/repositories/treinador/curiosidades_repository.dart';
import 'package:lucena/domain/models/treinador/curiosidade.dart';

/// Três curiosidades fixas (a primeira é a do canvas).
final class FakeCuriosidadesRepository implements CuriosidadesRepository {
  FakeCuriosidadesRepository([List<Curiosidade>? todas])
    : _todas = todas ?? padrao;

  static const padrao = [
    Curiosidade(
      id: 'cm-01',
      tema: 'Campeões do mundo',
      texto:
          'Você sabia quem foi o primeiro campeão do mundo? Foi Wilhelm '
          'Steinitz, em 1886.',
    ),
    Curiosidade(
      id: 'cm-02',
      tema: 'Campeões do mundo',
      texto: 'Mikhail Tal ficou conhecido como o Mago de Riga.',
    ),
    Curiosidade(
      id: 'fi-01',
      tema: 'Finais',
      texto: 'A posição de Lucena ensina a construir a ponte.',
    ),
  ];

  final List<Curiosidade> _todas;

  @override
  Future<List<Curiosidade>> todas() async => _todas;
}
