import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/data_export/data_export_repository.dart';
import 'package:lucena/data/repositories/data_export/data_export_repository_cloud.dart';

import '../../../../testing/fakes/fake_cloud_store_service.dart';
import '../../../../testing/fakes/fake_now.dart';

void main() {
  late Directory base;
  late FakeCloudStoreService store;
  late CloudDataExportRepository repository;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('lucena_export_test');
    store = FakeCloudStoreService()
      ..users['u1'] = {'name': 'Ana', 'email': 'ana@exemplo.com'}
      ..progress['u1'] = {'rating': 1450}
      ..games['u1'] = {
        'g1': {'result': 'win'},
      };
    repository = CloudDataExportRepository(
      store,
      directory: () async => base,
      now: FakeNow(DateTime(2026, 11, 4, 10, 30)),
    );
  });

  tearDown(() async {
    if (base.existsSync()) await base.delete(recursive: true);
  });

  test(
    'grava um JSON legível com a conta, o progresso e as partidas',
    () async {
      final path = await repository.download('u1');

      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(path, endsWith('.json'));
      final text = file.readAsStringSync();
      expect(text, contains('\n  ')); // indentado: legível
      final data = jsonDecode(text) as Map<String, Object?>;
      expect(data['conta'], {'name': 'Ana', 'email': 'ana@exemplo.com'});
      expect(data['progresso'], {'rating': 1450});
      expect(data['partidas'], {
        'g1': {'result': 'win'},
      });
      expect(data['gerado_em'], '2026-11-04T10:30:00.000');
      // Nenhum arquivo parcial fica para trás.
      expect(
        base.listSync(recursive: true).where((f) => f.path.endsWith('.part')),
        isEmpty,
      );
    },
  );

  test('conta sem dados ainda gera o arquivo só com a conta', () async {
    final path = await repository.download('novo');
    final data = jsonDecode(File(path).readAsStringSync()) as Map;
    expect(data['conta'], isNull);
    expect(data['partidas'], isEmpty);
  });

  test('sem internet falha e não grava nada', () async {
    store.offline = true;
    await expectLater(
      repository.download('u1'),
      throwsA(isA<DataExportException>()),
    );
    expect(base.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('apaga o parcial de uma tentativa interrompida', () async {
    final folder = Directory('${base.path}/exports')..createSync();
    File('${folder.path}/lucena-dados.json.part').writeAsStringSync('{');

    await repository.download('u1');

    expect(folder.listSync().map((f) => f.path.split('/').last), [
      'lucena-dados.json',
    ]);
  });

  test('descartar apaga o arquivo', () async {
    final path = await repository.download('u1');
    await repository.discard(path);
    expect(File(path).existsSync(), isFalse);
  });
}
