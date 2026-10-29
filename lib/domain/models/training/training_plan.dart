/// Weekday bits start on Sunday, as in Analytics. 62 = Monday–Friday.
final class TrainingPlan {
  const TrainingPlan({
    this.minutes = 30,
    this.weekdays = 62,
    this.reminderOn = true,
    this.reminderHour = 19,
    this.reminderMinute = 0,
  }) : assert(minutes > 0),
       assert(weekdays >= 0 && weekdays <= 127),
       assert(reminderHour >= 0 && reminderHour < 24),
       assert(reminderMinute >= 0 && reminderMinute < 60);

  final int minutes, weekdays, reminderHour, reminderMinute;
  final bool reminderOn;
  bool studiesOn(DateTime date) => weekdays & (1 << (date.weekday % 7)) != 0;
  String get weekdayMask =>
      List.generate(7, (i) => weekdays & (1 << i) == 0 ? '0' : '1').join();
  TrainingPlan copyWith({
    int? minutes,
    int? weekdays,
    bool? reminderOn,
    int? reminderHour,
    int? reminderMinute,
  }) => TrainingPlan(
    minutes: minutes ?? this.minutes,
    weekdays: weekdays ?? this.weekdays,
    reminderOn: reminderOn ?? this.reminderOn,
    reminderHour: reminderHour ?? this.reminderHour,
    reminderMinute: reminderMinute ?? this.reminderMinute,
  );
  Map<String, Object?> toJson() => {
    'minutes': minutes,
    'weekdays': weekdays,
    'reminderOn': reminderOn,
    'reminderHour': reminderHour,
    'reminderMinute': reminderMinute,
  };
  factory TrainingPlan.fromJson(Map<String, dynamic> j) => TrainingPlan(
    minutes: j['minutes'] as int,
    weekdays: j['weekdays'] as int,
    reminderOn: j['reminderOn'] as bool,
    reminderHour: j['reminderHour'] as int,
    reminderMinute: j['reminderMinute'] as int,
  );
}
