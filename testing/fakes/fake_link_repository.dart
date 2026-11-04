import 'package:lucena/data/repositories/links/link_repository.dart';

/// Guarda os endereços pedidos; com [fails], nenhum abre.
class FakeLinkRepository implements LinkRepository {
  FakeLinkRepository({this.fails = false});

  bool fails;

  final opened = <Uri>[];

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return !fails;
  }
}
