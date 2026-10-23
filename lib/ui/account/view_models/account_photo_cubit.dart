import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/account/account_repository.dart';
import '../../../data/repositories/account/avatar_repository.dart';
import '../../../data/repositories/photo/photo_repository.dart';
import '../../../data/services/firebase/file_store_service.dart';
import '../../../domain/models/avatar_photo.dart';
import '../../../domain/models/user_profile.dart';

/// O avatar escolhido em "Seu perfil", ainda sem salvar.
class AccountPhotoState {
  const AccountPhotoState({
    this.photo = AvatarPhoto.none,
    this.color = 0,
    this.photoUrl,
    this.bytes,
    this.saving = false,
  });

  final AvatarPhoto photo;
  final int color;

  /// A foto já enviada (com [AvatarPhoto.upload] e sem [bytes]).
  final String? photoUrl;

  /// A foto tirada ou escolhida agora: sobe ao salvar.
  final Uint8List? bytes;
  final bool saving;
}

/// A foto de "Seu perfil" (§2.12): tirar, escolher da galeria, a do Google
/// ou a inicial numa das cores. A foto nova só sobe ao salvar; trocar a
/// enviada por outra coisa apaga a do Storage.
class AccountPhotoCubit extends Cubit<AccountPhotoState> {
  AccountPhotoCubit({
    required this._accounts,
    required this._photos,
    required this._avatars,
  }) : super(const AccountPhotoState());

  final AccountRepository _accounts;
  final PhotoRepository _photos;
  final AvatarRepository _avatars;
  AvatarPhoto _saved = AvatarPhoto.none;

  /// Tirar ou escolher foto pede conta (a foto fica no Storage dela).
  bool get canUpload => _accounts.current != null;

  /// A foto da conta do Google, quando há.
  String? get googleUrl => _accounts.current?.photoUrl;

  /// Começa pelo que está gravado.
  void load(UserProfile profile) {
    _saved = profile.photo;
    final photo = switch (profile.photo) {
      AvatarPhoto.google when googleUrl == null => AvatarPhoto.none,
      AvatarPhoto.upload when !canUpload => AvatarPhoto.none,
      final photo => photo,
    };
    emit(
      AccountPhotoState(
        photo: photo,
        color: profile.avatarColor,
        photoUrl: profile.photoUrl,
      ),
    );
  }

  /// Abre a câmera ou a galeria. Desistir não muda nada.
  Future<void> pick(PhotoSource source) async {
    final bytes = await _photos.pick(source);
    if (bytes == null || isClosed) return;
    emit(
      AccountPhotoState(
        photo: AvatarPhoto.upload,
        color: state.color,
        bytes: bytes,
      ),
    );
  }

  void useGoogle() =>
      emit(AccountPhotoState(photo: AvatarPhoto.google, color: state.color));

  void useInitial(int color) => emit(AccountPhotoState(color: color));

  void remove() => emit(AccountPhotoState(color: state.color));

  /// Sobe a foto nova (ou apaga a antiga). Devolve o que gravar no perfil,
  /// ou nulo se a foto não subiu (sem rede).
  Future<AccountPhotoState?> save() async {
    final chosen = state;
    final uid = _accounts.current?.uid;
    emit(_copy(chosen, saving: true));
    try {
      final bytes = chosen.bytes;
      if (bytes != null && uid != null) {
        final url = await _avatars.upload(uid, bytes);
        final saved = AccountPhotoState(
          photo: AvatarPhoto.upload,
          color: chosen.color,
          photoUrl: url.toString(),
        );
        _saved = AvatarPhoto.upload;
        emit(saved);
        return saved;
      }
    } on FileStoreException {
      emit(chosen);
      return null;
    }
    if (_saved == AvatarPhoto.upload &&
        chosen.photo != AvatarPhoto.upload &&
        uid != null) {
      try {
        await _avatars.delete(uid);
      } on FileStoreException {
        // Sem rede, a foto antiga fica no Storage; o perfil já não a mostra.
      }
    }
    _saved = chosen.photo;
    emit(chosen);
    return chosen;
  }

  static AccountPhotoState _copy(AccountPhotoState s, {required bool saving}) =>
      AccountPhotoState(
        photo: s.photo,
        color: s.color,
        photoUrl: s.photoUrl,
        bytes: s.bytes,
        saving: saving,
      );
}
