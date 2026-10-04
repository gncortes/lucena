import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/main.dart';
import 'package:lucena/ui/core/keys/home_keys.dart';

void main() {
  testWidgets('abre na tela inicial com o mascote', (tester) async {
    await tester.pumpWidget(const LucenaApp());

    expect(find.byKey(HomeKeys.screen), findsOneWidget);
    expect(find.byKey(HomeKeys.mascot), findsOneWidget);
  });
}
