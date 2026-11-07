import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/privacy/view_models/data_export_cubit.dart';

import '../../../testing/fakes/fake_analytics_repository.dart';
import '../../../testing/fakes/fake_data_export_repository.dart';

void main() {
  late FakeDataExportRepository exports;
  late FakeAnalyticsRepository analytics;
  late DataExportCubit cubit;

  setUp(() {
    exports = FakeDataExportRepository();
    analytics = FakeAnalyticsRepository();
    cubit = DataExportCubit(uid: 'u1', exports: exports, analytics: analytics);
  });

  tearDown(() => cubit.close());

  group('H-CON-21 · Baixar meus dados', () {
    test('começa na pergunta', () {
      expect(cubit.state.step, DataExportStep.ask);
    });

    test('Baixar passa por Baixando e termina pronto', () async {
      exports.gate = Completer<void>();
      final done = cubit.download();
      expect(cubit.state.step, DataExportStep.downloading);
      exports.gate!.complete();
      await done;

      expect(cubit.state.step, DataExportStep.ready);
      expect(exports.downloads, ['u1']);
      expect(exports.saved, {FakeDataExportRepository.path});
      expect(analytics.names, ['dados_baixados']);
      expect(analytics.events.single.params['resultado'], 'ok');
    });

    test('a falha mostra o erro e Tentar de novo refaz', () async {
      exports.fails = true;
      await cubit.download();
      expect(cubit.state.step, DataExportStep.error);
      expect(exports.saved, isEmpty);
      expect(analytics.events.single.params['resultado'], 'erro');

      exports.fails = false;
      await cubit.download();
      expect(cubit.state.step, DataExportStep.ready);
      expect(exports.downloads, ['u1', 'u1']);
    });

    test('Cancelar durante Baixando descarta o arquivo', () async {
      exports.gate = Completer<void>();
      final done = cubit.download();
      cubit.cancel();
      exports.gate!.complete();
      await done;

      expect(cubit.state.step, DataExportStep.cancelled);
      expect(exports.saved, isEmpty);
      expect(exports.discarded, [FakeDataExportRepository.path]);
      expect(analytics.events.single.params['resultado'], 'cancelado');
    });

    test('Abrir arquivo abre o arquivo pronto', () async {
      await cubit.download();
      await cubit.open();
      expect(exports.opened, [FakeDataExportRepository.path]);
    });

    test('fechar a folha durante Baixando também descarta', () async {
      exports.gate = Completer<void>();
      final done = cubit.download();
      await cubit.close();
      exports.gate!.complete();
      await done;

      expect(exports.saved, isEmpty);
      expect(exports.discarded, [FakeDataExportRepository.path]);
    });
  });
}
