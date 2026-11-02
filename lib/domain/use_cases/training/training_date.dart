/// Local civil date. Never convert a training day to UTC.
String trainingDate(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-${at.day.toString().padLeft(2, '0')}';

DateTime civilDate(String date) => DateTime.parse(date);
