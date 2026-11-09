import 'package:lucena/data/repositories/coach/trivia_repository.dart';
import 'package:lucena/domain/models/coach/trivia.dart';

/// Três curiosidades fixas (a primeira é a do canvas).
final class FakeTriviaRepository implements TriviaRepository {
  FakeTriviaRepository([List<Trivia>? all]) : _all = all ?? standard;

  static const standard = [
    Trivia(
      id: 'cm-01',
      motif: 'Campeões do mundo',
      text:
          'Você sabia quem foi o primeiro campeão do mundo? Foi Wilhelm '
          'Steinitz, em 1886.',
    ),
    Trivia(
      id: 'cm-02',
      motif: 'Campeões do mundo',
      text: 'Mikhail Tal ficou conhecido como o Mago de Riga.',
    ),
    Trivia(
      id: 'fi-01',
      motif: 'Finais',
      text: 'A posição de Lucena ensina a construir a ponte.',
    ),
  ];

  final List<Trivia> _all;

  @override
  Future<List<Trivia>> all() async => _all;
}
