import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Baixa uma imagem pequena (a do push, E1.19 3.8). Nulo se não deu: a
/// notificação sai sem ela.
class ImageDownloadService {
  const ImageDownloadService({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  /// Até 1 MB: o Android recusa bitmaps grandes demais numa notificação.
  static const maxBytes = 1024 * 1024;

  Future<Uint8List?> fetch(Uri uri) async {
    if (uri.scheme != 'https' && uri.scheme != 'http') return null;
    try {
      final response = await http.get(uri).timeout(timeout);
      final bytes = response.bodyBytes;
      if (response.statusCode != 200 || bytes.isEmpty) return null;
      return bytes.length > maxBytes ? null : bytes;
    } on Object catch (error) {
      debugPrint('Imagem do push não baixou: $error');
      return null;
    }
  }
}
