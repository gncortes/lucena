import 'dart:async';

import 'package:lucena/data/repositories/reminders/reminders_repository.dart';
import 'package:lucena/data/repositories/week/week_repository.dart';
import 'package:lucena/data/services/notification_service.dart';
import 'package:lucena/domain/models/reminder.dart';
import 'package:lucena/domain/models/week_summary.dart';

/// Guarda o que seria agendado no aparelho.
class FakeRemindersRepository implements RemindersRepository {
  FakeRemindersRepository({this.allowed = true, this.lesson, this.launch});

  bool allowed;
  PausedLesson? lesson;
  String? launch;

  List<NotificationChannelSpec> channels = const [];

  /// O que está agendado agora (cada [replace] troca tudo).
  List<ScheduledNotification> scheduled = const [];
  int replaces = 0;

  final tapsController = StreamController<String>.broadcast();

  @override
  Future<void> start(List<NotificationChannelSpec> channels) async =>
      this.channels = channels;

  @override
  Future<bool> permitted() async => allowed;

  @override
  Future<void> replace(List<ScheduledNotification> notifications) async {
    scheduled = notifications;
    replaces++;
  }

  @override
  Future<String?> launchRoute() async => launch;

  @override
  Stream<String> get taps => tapsController.stream;

  @override
  Future<PausedLesson?> pausedLesson(String language) async => lesson;
}

class FakeWeekRepository implements WeekRepository {
  FakeWeekRepository(this.week);

  WeekSummary week;

  @override
  Future<WeekSummary> summary() async => week;
}
