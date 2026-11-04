import 'dart:convert';

import '../../../domain/models/training/training_course.dart';
import '../../../domain/use_cases/now.dart';
import '../../../domain/use_cases/training/demo_offer_rules.dart';
import '../../services/preferences_service.dart';

/// O contador da oferta da demo no fim da lição, gravado no aparelho
/// (H-LIC-51). O tempo vem do [Now] injetado.
abstract interface class DemoOfferRepository {
  Future<DemoOfferState> load(TrainingCourse course);

  /// Registra que a oferta foi mostrada agora e devolve o novo estado.
  Future<DemoOfferState> markShown(TrainingCourse course);
}

class LocalDemoOfferRepository implements DemoOfferRepository {
  LocalDemoOfferRepository(this._preferences, this._now);

  final PreferencesService _preferences;
  final Now _now;

  static String key(TrainingCourse course) =>
      'training.v1.${course.name}.demoOffer';

  @override
  Future<DemoOfferState> load(TrainingCourse course) async {
    final raw = await _preferences.getString(key(course));
    if (raw == null) return const DemoOfferState();
    try {
      final json = jsonDecode(raw);
      return json is Map<String, Object?>
          ? DemoOfferState.fromJson(json)
          : const DemoOfferState();
    } on FormatException {
      return const DemoOfferState();
    } on TypeError {
      return const DemoOfferState();
    }
  }

  @override
  Future<DemoOfferState> markShown(TrainingCourse course) async {
    final next = DemoOfferRules.shown(await load(course), _now());
    await _preferences.setString(key(course), jsonEncode(next.toJson()));
    return next;
  }
}
