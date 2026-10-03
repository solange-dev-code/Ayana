import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // L'adresse du backend est lue depuis les préférences avant le premier appel
  // réseau, sinon le premier appel partirait vers la valeur par défaut.
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadBaseUrl();
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