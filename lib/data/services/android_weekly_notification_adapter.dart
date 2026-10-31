import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Versioned native contract: pubspec pins 22.3.2. Only this adapter imports
// the internal mapper; keep its details identical to the public one-shot API.
// ignore: implementation_imports
import 'package:flutter_local_notifications/src/platform_specifics/android/method_channel_mappers.dart';

/// 22.3.2's native Weekly field preserves the first date; matching components
/// would recompute it and could deliver next week's notification today.
/// Native boot recovery may replay overdue weeks; force-stop and prolonged
/// reboot recovery are not guaranteed by this adapter.
class AndroidWeeklyNotificationAdapter {
  const AndroidWeeklyNotificationAdapter();
  static const _notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  static const _timezone = MethodChannel('lucena/notification_timezone');

  Future<String> timeZoneId() async {
    final zone = await _timezone.invokeMethod<String>('getTimeZoneId');
    if (zone == null || zone.isEmpty || zone.trim() != zone) {
      throw StateError('Android did not provide a notification time zone');
    }
    return zone;
  }

  Map<String, Object?> prepare({
    required int id,
    required String title,
    required String body,
    required String payload,
    required DateTime at,
    required DateTime now,
    required String timeZoneId,
    required AndroidNotificationDetails details,
  }) {
    if (id < 0 || id > 0x7fffffff) throw ArgumentError.value(id, 'id');
    if (at.isUtc || !at.isAfter(now)) {
      throw ArgumentError.value(at, 'at', 'Expected a future civil local date');
    }
    if (timeZoneId.isEmpty || timeZoneId.trim() != timeZoneId) {
      throw ArgumentError.value(timeZoneId, 'timeZoneId');
    }
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'scheduledDateTime': at.toIso8601String().split('.').first,
      'timeZoneName': timeZoneId,
      'scheduledNotificationRepeatFrequency': 1,
      'platformSpecifics': {
        ...details.toMap(),
        'scheduleMode': AndroidScheduleMode.inexactAllowWhileIdle.name,
      },
    };
  }

  Future<void> schedule(Map<String, Object?> prepared) =>
      _notifications.invokeMethod<void>('zonedSchedule', prepared);
}
