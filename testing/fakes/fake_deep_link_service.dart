import 'dart:async';

import 'package:lucena/data/services/deep_link_service.dart';

/// Um sistema que entrega os endereços que o teste mandar.
class FakeDeepLinkService implements DeepLinkService {
  FakeDeepLinkService({this.initial});

  /// O endereço que abriu o app.
  Uri? initial;
  final _controller = StreamController<Uri>.broadcast();

  /// Chega um endereço com o app aberto.
  void open(Uri uri) => _controller.add(uri);

  @override
  Future<Uri?> initialUri() async => initial;

  @override
  Stream<Uri> get uris => _controller.stream;
}
