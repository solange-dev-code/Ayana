import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'login_screen.dart';
import 'language_screen.dart';

class WelcomeAuthScreen extends StatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  State<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends State<WelcomeAuthScreen> {
  bool _creatingGuest = false;

  Future<void> _continueAsGuest() async {
    if (_creatingGuest) return;
    setState(() => _creatingGuest = true);
    try {
      await ApiService.guest();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LanguageScreen()),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _creatingGuest = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 70, bottom: 34),
            decoration: BoxDecoration(gradient: brandGradient()),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 34),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    height: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ton espace santé, en toute confiance',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GradientButton(
                    label: '✨  Créer mon compte',
                    gradient: roseGradient(),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen(isSignup: true)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GradientButton(
                    label: '🔑  Se connecter',
                    outlined: true,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen(isSignup: false)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderLight),
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _creatingGuest ? null : _continueAsGuest,
                      child: Text(
                        _creatingGuest
                            ? 'Création…'
                            : '🔒  Continuer sans compte (anonyme)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "AYANA respecte ta vie privée. Tu peux utiliser un "
                    "pseudonyme. Tes données ne sont jamais partagées sans "
                    "ton accord.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}