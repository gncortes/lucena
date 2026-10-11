import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/share/share_repository.dart';
import 'package:lucena/ui/core/share/share_cubit.dart';

import '../../../../testing/fakes/fake_share_repository.dart';

/// Segura o menu aberto até o teste mandar fechar.
class _SlowShare implements ShareRepository {
  final closed = Completer<bool>();
  var calls = 0;

  @override
  Future<bool> shareImage(Uint8List png, {required String name, String? text}) {
    calls++;
    return closed.future;
  }
}

void main() {
  final png = Uint8List.fromList([1, 2, 3]);

  test('manda a imagem e o texto', () async {
    final share = FakeShareRepository();
    final cubit = ShareCubit(share);
    addTearDown(cubit.close);
    await cubit.share(png, name: 'a.png', text: 'oi');
    expect(share.shared.single.name, 'a.png');
    expect(share.shared.single.text, 'oi');
    expect(cubit.state, isFalse);
  });

  test('com o menu aberto, o segundo toque não abre outro', () async {
    final share = _SlowShare();
    final cubit = ShareCubit(share);
    addTearDown(cubit.close);
    final first = cubit.share(png, name: 'a.png');
    expect(cubit.state, isTrue);
    await cubit.share(png, name: 'a.png');
    expect(share.calls, 1);
    share.closed.complete(true);
    await first;
    expect(cubit.state, isFalse);
  });
}
