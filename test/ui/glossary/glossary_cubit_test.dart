import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/glossary/view_models/glossary_cubit.dart';

import '../../../testing/fakes/fake_glossary.dart';

void main() {
  GlossaryCubit cubit({bool online = true}) => GlossaryCubit(
    FakeGlossaryRepository(),
    FakeConnectivityRepository(online: online),
  );

  test('carrega todos os termos', () async {
    final c = cubit();
    await c.load();
    expect(c.state.loading, isFalse);
    expect(c.state.results, hasLength(3));
    expect(c.state.empty, isFalse);
  });

  test('carrega já filtrado pelo termo tocado', () async {
    final c = cubit();
    await c.load(query: 'ponte');
    expect(c.state.results.map((t) => t.id), ['ponte']);
  });

  test('busca sem resultado fica vazia; limpar volta a lista toda', () async {
    final c = cubit();
    await c.load();
    c.search('roque');
    expect(c.state.empty, isTrue);
    c.clear();
    expect(c.state.query, '');
    expect(c.state.results, hasLength(3));
  });

  blocTest<GlossaryCubit, GlossaryState>(
    'sem internet, checkOnline marca offline',
    build: () => cubit(online: false),
    act: (c) => c.checkOnline(),
    verify: (c) => expect(c.state.online, isFalse),
  );

  test('termById acha o termo ou devolve nulo', () async {
    final c = cubit();
    await c.load();
    expect(c.state.termById('zugzwang')?.name, 'Zugzwang');
    expect(c.state.termById('nada'), isNull);
  });
}
