import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales qui ne concernent pas la session d'authentification.
class AppPrefs {
  AppPrefs._();

  static const String _onboardingKey = 'ayana_onboarding_seen';

  /// L'onboarding n'est présenté qu'à la première ouverture de l'application.
  static Future<bool> onboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }
}
