import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/alert_settings.dart';
import 'package:lucena/domain/models/reminder.dart';
import 'package:lucena/domain/models/week_summary.dart';
import 'package:lucena/ui/core/l10n/l10n.dart';
import 'package:lucena/ui/reminders/view_models/reminders_cubit.dart';
import 'package:lucena/ui/reminders/widgets/l10n_reminder_texts.dart';

import '../../../testing/fakes/fake_activity_repository.dart';
import '../../../testing/fakes/fake_now.dart';
import '../../../testing/fakes/fake_reminders_repository.dart';

void main() {
  // Quinta, 22 de outubro de 2026, 9h.
  late FakeNow now;
  late FakeRemindersRepository reminders;
  late FakeActivityRepository activity;
  late StreamController<void> changes;
  final texts = L10nReminderTexts(lookupAppLocalizations(const Locale('pt')));
  final week = WeekSummary(
    monday: DateTime(2026, 10, 19),
    finals: 12,
    perDay: const [2, 1, 3, 1, 2, 2, 1],
    ratingFrom: 1152,
    ratingTo: 1192,
    streakDays: 12,
    firstTry: 9,
  );

  setUp(() {
    now = FakeNow(DateTime(2026, 10, 22, 9));
    reminders = FakeRemindersRepository();
    activity = FakeActivityRepository(
      days: {DateTime(2026, 10, 20, 18), DateTime(2026, 10, 21, 18)},
      now: now,
    );
    changes = StreamController<void>.broadcast();
  });

  RemindersCubit build() {
    final cubit = RemindersCubit(
      reminders: reminders,
      activity: activity,
      week: FakeWeekRepository(week),
      now: now,
      changes: changes.stream,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  test('agenda a sequência hoje e o resumo no domingo, com textos', () async {
    final cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);

    expect(reminders.channels.map((c) => c.name), [
      'Lembretes',
      'Resumo da semana',
    ]);
    final [streak, sunday] = reminders.scheduled;
    expect(streak.id, RemindersCubit.firstId);
    expect(streak.at, DateTime(2026, 10, 22, 19));
    expect(streak.title, 'Sua sequência de 2 dias acaba hoje');
    expect(streak.action, 'Jogar o final do dia');
    expect(streak.payload, '/daily');
    expect(streak.channel.id, 'lembretes_quieto');

    expect(sunday.id, RemindersCubit.firstId + 3);
    expect(sunday.title, 'Seu resumo da semana');
    expect(
      sunday.body,
      'Esta semana você jogou 12 finais e subiu 40 pontos. Veja como foi.',
    );
    expect(sunday.payload, '/week');
    expect(sunday.channel.id, 'resumo_semana_quieto');
    expect(sunday.action, isNull);
    expect(cubit.state.map((r) => r.kind), [
      ReminderKind.streak,
      ReminderKind.week,
    ]);
  });

  test('a aula parada abre no passo salvo', () async {
    reminders.lesson = const PausedLesson(
      lessonId: 'lucena',
      title: 'A posição de Lucena',
      chapter: 3,
      total: 6,
      partId: 'ponte',
      stage: 2,
    );
    activity.marked.clear();
    final cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);

    final today = reminders.scheduled.first;
    expect(today.title, 'Continue a lição');
    expect(
      today.body,
      'Falta pouco para fechar "A posição de Lucena": você parou no capítulo '
      '3 de 6.',
    );
    expect(today.action, 'Continuar');
    expect(today.payload, contains('/endgames/lucena'));
    expect(today.payload, contains('part=ponte'));
  });

  test('chave desligada ou sem permissão: cancela tudo', () async {
    final cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    expect(reminders.scheduled, isNotEmpty);

    await cubit.update(
      settings: const AlertSettings(daily: false),
      texts: texts,
    );
    expect(reminders.scheduled, isEmpty);

    await cubit.update(settings: const AlertSettings(), texts: texts);
    reminders.allowed = false;
    await cubit.refresh();
    expect(reminders.scheduled, isEmpty);
  });

  test('jogou: o de hoje sai e o de amanhã entra', () async {
    final cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    expect(reminders.scheduled.first.at.day, 22);

    await activity.markToday();
    changes.add(null);
    await pumpEventQueue();

    expect(reminders.scheduled.first.at, DateTime(2026, 10, 23, 19));
    expect(reminders.scheduled.first.id, RemindersCubit.firstId + 1);
  });

  test('a hora nova reagenda', () async {
    final cubit = build();
    await cubit.update(settings: const AlertSettings(), texts: texts);
    await cubit.update(
      settings: const AlertSettings(reminderMinutes: 8 * 60),
      texts: texts,
    );
    // 8h já passou hoje: só o domingo.
    expect(reminders.scheduled.map((n) => n.at), [DateTime(2026, 10, 25, 8)]);
  });

  test('antes de Avisos carregar, não agenda', () async {
    final cubit = build();
    await cubit.refresh();
    changes.add(null);
    await pumpEventQueue();
    expect(reminders.replaces, 0);
  });
}
