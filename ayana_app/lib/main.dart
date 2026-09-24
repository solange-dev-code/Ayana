import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AyanaApp());
}

class AyanaApp extends StatelessWidget {
  const AyanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AYANA',
      debugShowCheckedModeBanner: false,
      theme: ayanaTheme(),
      home: const SplashScreen(),
    );
  }
}