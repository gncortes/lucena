import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/endgame_filter.dart';
import 'package:lucena/domain/models/rating_level.dart';

void main() {
  bool rookOpenIntermediate(EndgameFilter filter) => filter.matches(
    kinds: {EndgameKind.rook},
    level: RatingLevel.intermediate,
    status: EndgameLessonStatus.open,
  );

  test('sem filtro, tudo passa e a ordem é a da trilha', () {
    const filter = EndgameFilter();
    expect(filter.isEmpty, isTrue);
    expect(filter.count, 0);
    expect(rookOpenIntermediate(filter), isTrue);
  });

  test('dentro de um grupo vale qualquer opção; entre grupos, todas', () {
    final filter = const EndgameFilter()
        .toggleKind(EndgameKind.rook)
        .toggleKind(EndgameKind.queen);
    expect(rookOpenIntermediate(filter), isTrue);
    expect(
      rookOpenIntermediate(filter.toggleLevel(RatingLevel.master)),
      isFalse,
    );
    expect(
      rookOpenIntermediate(filter.toggleStatus(EndgameLessonStatus.open)),
      isTrue,
    );
    expect(
      rookOpenIntermediate(filter.toggleStatus(EndgameLessonStatus.passed)),
      isFalse,
    );
    expect(
      rookOpenIntermediate(const EndgameFilter().toggleKind(EndgameKind.pawn)),
      isFalse,
    );
  });

  test('aula sem faixa não passa quando há faixa marcada', () {
    final filter = const EndgameFilter().toggleLevel(RatingLevel.casual);
    expect(
      filter.matches(
        kinds: {EndgameKind.pawn},
        level: null,
        status: EndgameLessonStatus.open,
      ),
      isFalse,
    );
  });

  test('marcar de novo desmarca; a ordem conta como um filtro', () {
    final filter = const EndgameFilter()
        .toggleKind(EndgameKind.rook)
        .withSort(EndgameSort.easiest);
    expect(filter.count, 2);
    expect(filter.toggleKind(EndgameKind.rook).count, 1);
    expect(
      filter.toggleKind(EndgameKind.rook).withSort(EndgameSort.trail).isEmpty,
      isTrue,
    );
  });

  test('o gravado volta igual; lixo vira filtro vazio', () {
    final filter = const EndgameFilter()
        .toggleKind(EndgameKind.minor)
        .toggleLevel(RatingLevel.expert)
        .toggleStatus(EndgameLessonStatus.started)
        .withSort(EndgameSort.easiest);
    expect(EndgameFilter.fromCode(filter.code), filter);
    expect(EndgameFilter.fromCode(null), const EndgameFilter());
    expect(EndgameFilter.fromCode('não é json'), const EndgameFilter());
    expect(EndgameFilter.fromCode('[1]'), const EndgameFilter());
    expect(
      EndgameFilter.fromCode('{"kinds":["rook","dragon"],"sort":"x"}'),
      const EndgameFilter(kinds: {EndgameKind.rook}),
    );
  });
}
