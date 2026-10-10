import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Desenha uma página da web e conta se ela abriu (com o título dela) ou
/// falhou. Nos testes, um falso de `testing/` (a webview não existe fora do
/// aparelho).
abstract class WebPages {
  const WebPages();

  Widget page(
    Uri url, {
    required ValueChanged<String?> onLoaded,
    required VoidCallback onFailed,
  });

  /// As páginas do app ou, sem nenhuma dada, a webview do aparelho.
  static WebPages of(BuildContext context) {
    try {
      return context.read<WebPages>();
    } on ProviderNotFoundException {
      return const WebViewPages();
    }
  }
}

/// A página numa webview do aparelho (`webview_flutter`).
class WebViewPages extends WebPages {
  const WebViewPages();

  @override
  Widget page(
    Uri url, {
    required ValueChanged<String?> onLoaded,
    required VoidCallback onFailed,
  }) => _WebViewPage(url: url, onLoaded: onLoaded, onFailed: onFailed);
}

class _WebViewPage extends StatefulWidget {
  const _WebViewPage({
    required this.url,
    required this.onLoaded,
    required this.onFailed,
  });

  final Uri url;
  final ValueChanged<String?> onLoaded;
  final VoidCallback onFailed;

  @override
  State<_WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<_WebViewPage> {
  late final WebViewController _controller;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            if (_failed || !mounted) return;
            final title = await _controller.getTitle();
            if (!_failed && mounted) widget.onLoaded(title);
          },
          // Sem internet (ou a página não abriu): só o erro da página
          // principal conta; uma imagem que falha não.
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) _fail();
          },
          onHttpError: (error) {
            if ((error.response?.statusCode ?? 0) >= 400 &&
                error.request?.uri == widget.url) {
              _fail();
            }
          },
        ),
      );
    _controller.loadRequest(widget.url).catchError((Object _) => _fail());
  }

  void _fail() {
    if (_failed || !mounted) return;
    _failed = true;
    widget.onFailed();
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
