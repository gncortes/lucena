import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/domain/models/app_theme_mode.dart';

void main() {
  test('cada tema volta do próprio código', () {
    for (final mode in AppThemeMode.values) {
      expect(AppThemeMode.fromCode(mode.code), mode);
    }
  });

  test('código ausente ou desconhecido segue o aparelho', () {
    expect(AppThemeMode.fromCode(null), AppThemeMode.system);
    expect(AppThemeMode.fromCode('sepia'), AppThemeMode.system);
  });
}
