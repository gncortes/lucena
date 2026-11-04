/// Data civil `yyyy-MM-dd` do relógio injetado (Treino B).
String trainingGoalToday(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';
