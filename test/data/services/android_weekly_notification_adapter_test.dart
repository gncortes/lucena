import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lucena/data/services/android_weekly_notification_adapter.dart';
import 'package:lucena/data/services/notification_service.dart';

import '../../../testing/fakes/fake_now.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pluginChannel = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezoneChannel = MethodChannel('lucena/notification_timezone');
  final calls = <MethodCall>[];
  var zone = 'America/Bahia';
  var timezoneFails = false;
  final now = FakeNow(DateTime(2100, 1, 1, 12));
  const channel = NotificationChannelSpec(id: 'training', name: 'Training');
  late DeviceNotificationService service;

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    zone = 'America/Bahia';
    timezoneFails = false;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pluginChannel, (call) async {
      calls.add(call);
      return call.method == 'initialize' ? true : null;
    });
    messenger.setMockMethodCallHandler(timezoneChannel, (call) async {
      calls.add(call);
      if (timezoneFails) throw PlatformException(code: 'timezone');
      return zone;
    });
    service = DeviceNotificationService(FlutterLocalNotificationsPlugin(), now);
    await service.start([channel]);
    calls.clear();
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(pluginChannel, null);
    messenger.setMockMethodCallHandler(timezoneChannel, null);
  });

  ScheduledNotification notification(
    int id,
    DateTime at, {
    bool weekly = false,
  }) => ScheduledNotification(
    id: id,
    channel: channel,
    title: 'Title',
    body: 'Body',
    payload: '/',
    at: at,
    repeatWeekly: weekly,
    action: 'Open',
  );

  test(
    'weekly preserves +7/+14 civil dates and public Android details',
    () async {
      await service.replace([
        notification(600, DateTime(2100, 1, 1, 19)),
        notification(700, DateTime(2100, 1, 8, 19), weekly: true),
        notification(701, DateTime(2100, 1, 15), weekly: true),
      ]);
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .toList();
      expect(scheduled.length, 3);
      final oneShot = Map<String, dynamic>.from(scheduled[0].arguments as Map);
      expect(oneShot['scheduledNotificationRepeatFrequency'], isNull);
      expect(oneShot['timeZoneName'], 'Etc/UTC');
      for (var i = 1; i <= 2; i++) {
        final payload = Map<String, dynamic>.from(
          scheduled[i].arguments as Map,
        );
        expect(payload['scheduledNotificationRepeatFrequency'], 1);
        expect(payload['timeZoneName'], 'America/Bahia');
        expect(
          payload['scheduledDateTime'],
          i == 1 ? '2100-01-08T19:00:00' : '2100-01-15T00:00:00',
        );
        expect(payload.containsKey('matchDateTimeComponents'), isFalse);
        expect(payload.containsKey('repeatInterval'), isFalse);
        expect(payload.containsKey('repeatIntervalMilliseconds'), isFalse);
        expect(payload['platformSpecifics'], oneShot['platformSpecifics']);
      }
      expect(calls.map((c) => c.method).take(2), [
        'getTimeZoneId',
        'cancelAllPendingNotifications',
      ]);
    },
  );

  test(
    'replace rechecks timezone, replaces once, and off cancels all',
    () async {
      final schedule = [
        notification(700, DateTime(2100, 1, 8, 19), weekly: true),
      ];
      await service.replace(schedule);
      zone = 'Europe/Paris';
      await service.replace(schedule);
      final weekly = calls.where((c) => c.method == 'zonedSchedule').toList();
      expect((weekly.last.arguments as Map)['timeZoneName'], 'Europe/Paris');
      expect(calls.where((c) => c.method == 'getTimeZoneId').length, 2);
      await service.replace([]);
      expect(
        calls.where((c) => c.method == 'cancelAllPendingNotifications').length,
        3,
      );
      expect(calls.where((c) => c.method == 'zonedSchedule').length, 2);
    },
  );

  test('timezone and invalid future failures keep existing alarms', () async {
    timezoneFails = true;
    await expectLater(
      service.replace([notification(700, DateTime(2100, 1, 8), weekly: true)]),
      throwsA(isA<PlatformException>()),
    );
    timezoneFails = false;
    await expectLater(
      service.replace([notification(700, DateTime(2099), weekly: true)]),
      throwsArgumentError,
    );
    expect(
      calls.where((c) => c.method == 'cancelAllPendingNotifications'),
      isEmpty,
    );
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test('adapter validates native ID, civil local date and timezone', () {
    const adapter = AndroidWeeklyNotificationAdapter();
    for (final sample in [
      (id: -1, at: DateTime(2100, 1, 8), zone: zone),
      (id: 0x80000000, at: DateTime(2100, 1, 8), zone: zone),
      (id: 700, at: DateTime.utc(2100, 1, 8), zone: zone),
      (id: 700, at: now(), zone: zone),
      (id: 700, at: DateTime(2100, 1, 8), zone: ''),
    ]) {
      expect(
        () => adapter.prepare(
          id: sample.id,
          title: 'Title',
          body: 'Body',
          payload: '/',
          at: sample.at,
          now: now(),
          timeZoneId: sample.zone,
          details: const AndroidNotificationDetails('training', 'Training'),
        ),
        throwsArgumentError,
      );
    }
  });
}
