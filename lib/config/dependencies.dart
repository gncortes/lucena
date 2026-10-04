import '../domain/use_cases/now.dart';

/// Ligado por `--dart-define=E2E=true` nos cenários Patrol.
const isE2E = bool.fromEnvironment('E2E');

/// As implementações que entram no app.
///
/// A composição E2E, com os fakes, fica em `testing/e2e_dependencies.dart`:
/// código de `lib/` não importa `testing/`.
class Dependencies {
  const Dependencies({required this.now});

  const Dependencies.normal() : now = const SystemNow();

  final Now now;
}
