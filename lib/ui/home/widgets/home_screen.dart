import 'package:flutter/material.dart';

import '../../core/keys/home_keys.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: HomeKeys.screen,
      body: SafeArea(
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.6,
            child: Image.asset(
              isDark
                  ? 'assets/branding/mascot_dark.png'
                  : 'assets/branding/mascot_light.png',
              key: HomeKeys.mascot,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
