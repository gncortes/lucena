import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/course_guide/view_models/push_permission_cubit.dart';

import '../../../../testing/fakes/fake_push_repository.dart';

void main() {
  test('começa permitido e lê a permissão do aparelho', () async {
    final push = FakePushRepository(allowed: false);
    final cubit = PushPermissionCubit(push);
    expect(cubit.state, isTrue);
    await cubit.check();
    expect(cubit.state, isFalse);
    await cubit.close();
  });

  test('sem push na árvore o aviso não aparece', () async {
    final cubit = PushPermissionCubit(null);
    await cubit.check();
    expect(cubit.state, isTrue);
    await cubit.close();
  });

  test('pedido negado abre os ajustes do sistema', () async {
    final push = FakePushRepository(granted: false);
    final cubit = PushPermissionCubit(push);
    await cubit.enable();
    expect(push.permissionRequests, 1);
    expect(push.settingsOpened, 1);
    expect(cubit.state, isFalse);
    await cubit.close();
  });

  test('pedido aceito não abre os ajustes e libera o aviso', () async {
    final push = FakePushRepository(granted: true);
    final cubit = PushPermissionCubit(push);
    await cubit.enable();
    expect(push.settingsOpened, 0);
    expect(cubit.state, isTrue);
    await cubit.close();
  });
}
