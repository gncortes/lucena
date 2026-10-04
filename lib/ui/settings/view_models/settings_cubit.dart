import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings/settings_repository.dart';
import '../../../domain/models/app_language.dart';
import '../../../domain/models/app_settings.dart';

/// Preferências do app. O estado é nulo até a primeira leitura terminar.
class SettingsCubit extends Cubit<AppSettings?> {
  SettingsCubit(this._repository, {required this.languages}) : super(null);

  final SettingsRepository _repository;

  /// Idiomas oferecidos na tela de idioma.
  final List<AppLanguage> languages;

  Future<void> load() async => emit(await _repository.load());

  /// Troca o idioma do app. Nulo volta a seguir o idioma do sistema.
  Future<void> setLanguage(AppLanguage? language) async {
    final settings = (state ?? const AppSettings()).copyWith(
      languageCode: language?.code,
    );
    emit(settings);
    await _repository.save(settings);
  }
}
