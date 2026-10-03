import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_prefs.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';
import 'onboarding_screen.dart';
import 'welcome_auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.3,
    )..forward();
    _timer = Timer(const Duration(milliseconds: 2400), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    _start().then((next) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => next),
      );
    });
  }

  /// Détermine l'écran d'ouverture.
  ///
  /// Une session valide évite de ressaisir un compte à chaque lancement. Le
  /// jeton est validé auprès du backend plutôt que lu localement : un jeton
  /// révoqué ou expiré doit renvoyer vers l'accueil, sinon l'application
  /// s'ouvre sur une session morte. En revanche une panne réseau ne déconnecte
  /// pas l'utilisatrice — se reconnecter serait impossible sans backend.
  Future<Widget> _start() async {
    if (await ApiService.hasSession()) {
      try {
        await ApiService.getMe();
        return const MainNavigation();
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await ApiService.clearSession();
          return await _apresEchec();
        }
        // Panne réseau : la session est probablement encore valable, mais on ne
        // peut pas le prouver ici. On laisse l'utilisatrice vers la connexion
        // plutôt que d'ouvrir une session morte.
        return await _apresEchec();
      }
    }
    return await _apresEchec();
  }

  Future<Widget> _apresEchec() async {
    return await AppPrefs.onboardingSeen()
        ? const WelcomeAuthScreen()
        : const OnboardingScreen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.plumLight, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              // Logo crème, sur fond crème — la marque telle quelle.
              FadeTransition(
                opacity: _fade,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.plum.withValues(alpha: 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Ton assistante santé, en toute confiance',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.plum, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.plum,
                  backgroundColor: AppColors.plumLight,
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}