import 'package:flutter/widgets.dart';
import 'package:lucena/data/repositories/wiki/wiki_links_repository.dart';
import 'package:lucena/domain/models/wiki_links.dart';
import 'package:lucena/ui/core/widgets/web_pages.dart';

/// Um mapa de links em memória.
class FakeWikiLinksRepository implements WikiLinksRepository {
  FakeWikiLinksRepository([this.json = const {}]);

  /// No formato de `assets/lessons/links.json`.
  final Map<String, dynamic> json;

  @override
  Future<WikiLinks> links() async => WikiLinks.fromJson(json);
}

/// Páginas da web sem webview: [online] abre na hora (um texto com o
/// endereço); sem internet, falha na hora.
class FakeWebPages extends WebPages {
  FakeWebPages({this.online = true, this.title});

  bool online;

  /// O título que a página conta ao abrir.
  String? title;

  /// Os endereços pedidos, em ordem.
  final opened = <Uri>[];

  @override
  Widget page(
    Uri url, {
    required ValueChanged<String?> onLoaded,
    required VoidCallback onFailed,
  }) {
    opened.add(url);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => online ? onLoaded(title) : onFailed(),
    );
    return Text('$url', textDirection: TextDirection.ltr);
  }
}
