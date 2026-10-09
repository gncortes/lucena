import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucena/ui/core/theme/app_motion.dart';

void main() {
  Future<MotionDurations> motionWith(
    WidgetTester tester, {
    required bool disable,
  }) async {
    late MotionDurations motion;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(disableAnimations: disable),
        child: Builder(
          builder: (context) {
            motion = AppMotion.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return motion;
  }

  test('os tokens são os do Material 3', () {
    expect(AppMotion.tap, Durations.short2);
    expect(AppMotion.state, Durations.short4);
    expect(AppMotion.component, Durations.medium2);
    expect(AppMotion.screen, Durations.long2);
    expect(AppMotion.celebrate, Durations.extralong2);
    expect(AppMotion.stagger, Durations.short1);
    expect(AppMotion.enter, Easing.emphasizedDecelerate);
    expect(AppMotion.exit, Easing.emphasizedAccelerate);
  });

  testWidgets('com animações: as durações dos tokens', (tester) async {
    final motion = await motionWith(tester, disable: false);
    expect(motion.disabled, isFalse);
    expect(motion.tap, AppMotion.tap);
    expect(motion.screen, AppMotion.screen);
    expect(motion.celebrate, AppMotion.celebrate);
  });

  testWidgets('"remover animações" ligado: tudo zerado', (tester) async {
    final motion = await motionWith(tester, disable: true);
    expect(motion.disabled, isTrue);
    for (final duration in [
      motion.tap,
      motion.state,
      motion.component,
      motion.screen,
      motion.celebrate,
      motion.stagger,
    ]) {
      expect(duration, Duration.zero);
    }
  });
}
