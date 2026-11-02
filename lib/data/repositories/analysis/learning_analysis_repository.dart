import 'dart:convert';

import '../../../domain/models/learning_analysis.dart';
import '../../services/preferences_service.dart';

/// Stores the complete move tree and cursor separately from engine preferences.
class LearningAnalysisRepository {
  LearningAnalysisRepository(this.preferences);
  final PreferencesService preferences;
  String _key(String id) =>
      'learning.analysis.session.${Uri.encodeComponent(id)}';
  Future<LearningAnalysisSession?> load(String id) async {
    final raw = await preferences.getString(_key(id));
    if (raw == null) return null;
    try {
      return LearningAnalysisSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(String id, LearningAnalysisSession session) =>
      preferences.setString(_key(id), jsonEncode(session.toJson()));
  Future<LearningAnalysisSettings> settings() async {
    final raw = await preferences.getString('learning.analysis.settings');
    if (raw == null) return const LearningAnalysisSettings();
    try {
      return LearningAnalysisSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return const LearningAnalysisSettings();
    } on TypeError {
      return const LearningAnalysisSettings();
    }
  }

  Future<void> saveSettings(LearningAnalysisSettings settings) => preferences
      .setString('learning.analysis.settings', jsonEncode(settings.toJson()));
}
