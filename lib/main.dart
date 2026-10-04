import 'package:flutter/material.dart';

import 'ui/home/widgets/home_screen.dart';

void main() {
  runApp(const LucenaApp());
}

class LucenaApp extends StatelessWidget {
  const LucenaApp({super.key});

  static const _seed = Color(0xFFFF7A1A);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seed),
        scaffoldBackgroundColor: const Color(0xFFF5F7F4),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF14211B),
      ),
      home: const HomeScreen(),
    );
  }
}
