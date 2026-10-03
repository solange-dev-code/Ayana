import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/app_prefs.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'welcome_auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _goNext() {
    if (_index < onboardingPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await AppPrefs.markOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = onboardingPages[_index];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(gradient: page.gradient),
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final p = onboardingPages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(p.emoji, style: const TextStyle(fontSize: 48)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          p.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(onboardingPages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? page.gradient.colors.first : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: page.buttonLabel,
                    gradient: page.gradient,
                    onPressed: _goNext,
                  ),
                  const SizedBox(height: 12),
                  if (_index < onboardingPages.length - 1)
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Passer →',
                          style: TextStyle(color: AppColors.textSecondary)),
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