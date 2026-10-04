import 'package:lucena/domain/use_cases/now.dart';

/// Relógio controlado pelo teste: só anda quando o teste manda.
class FakeNow implements Now {
  FakeNow(this.value);

  DateTime value;

  @override
  DateTime call() => value;

  void advance(Duration duration) => value = value.add(duration);
}
