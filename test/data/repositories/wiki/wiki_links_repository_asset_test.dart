import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/wiki/wiki_links_repository_asset.dart';
import 'package:lucena/data/services/asset_service.dart';

class _Bundle extends CachingAssetBundle {
  _Bundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) throw StateError('sem $key');
    return ByteData.sublistView(Uint8List.fromList(text.codeUnits));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = files[key];
    if (text == null) throw StateError('sem $key');
    return text;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lê o contrato de links sem depender do catálogo privado', () async {
    final links = await AssetWikiLinksRepository(
      AssetService(
        _Bundle({
          AssetWikiLinksRepository.path: '{"example":{"en":"https://example.com/reference","pt":"https://example.com/referencia"}}',
        }),
      ),
    ).links();
    expect(links.keys, ['example']);
    expect(
      links.url('example', 'pt').toString(),
      'https://example.com/referencia',
    );
    expect(
      links.url('example', 'xx').toString(),
      'https://example.com/reference',
    );
  });

  test('sem o arquivo ou com ele quebrado: vazio, sem erro', () async {
    final missing = await AssetWikiLinksRepository(AssetService(_Bundle({})))
        .links();
    expect(missing.keys, isEmpty);
    final broken = await AssetWikiLinksRepository(
      AssetService(_Bundle({AssetWikiLinksRepository.path: '{oops'})),
    ).links();
    expect(broken.keys, isEmpty);
  });
}
