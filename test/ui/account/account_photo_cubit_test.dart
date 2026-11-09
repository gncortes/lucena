import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/data/repositories/photo/photo_repository.dart';
import 'package:lucena/domain/models/avatar_photo.dart';
import 'package:lucena/ui/account/view_models/account_photo_cubit.dart';

import '../../../testing/fakes/fake_account_repository.dart';
import '../../../testing/fakes/fake_avatar_repository.dart';
import '../../../testing/fakes/fake_photo_repository.dart';

void main() {
  late FakeAvatarRepository avatars;
  late AccountPhotoCubit cubit;
  final jpeg = Uint8List.fromList([1, 2, 3]);

  setUp(() {
    avatars = FakeAvatarRepository();
    cubit = AccountPhotoCubit(
      accounts: FakeAccountRepository(account: FakeAccountRepository.google),
      photos: FakePhotoRepository(jpeg),
      avatars: avatars,
    );
  });

  tearDown(() => cubit.close());

  test('a foto escolhida sobe ao salvar', () async {
    await cubit.pick(PhotoSource.gallery);
    final saved = await cubit.save();

    expect(saved?.photo, AvatarPhoto.upload);
    expect(saved?.photoUrl, contains('google-uid'));
    expect(avatars.photos['google-uid'], jpeg);
  });

  test('sem rede, a foto não sobe e a escolha fica na tela', () async {
    avatars.offline = true;
    await cubit.pick(PhotoSource.camera);
    final saved = await cubit.save();

    expect(saved, isNull);
    expect(cubit.state.bytes, jpeg);
    expect(cubit.state.saving, isFalse);
  });
}
