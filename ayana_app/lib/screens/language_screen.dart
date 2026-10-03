import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'main_navigation.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = ApiService.currentUser;
    _selected = availableLanguages.any((l) => l.code == current?.language)
        ? current!.language
        : 'ewe';
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ApiService.updateMe(language: _selected);
    } on ApiException {
      // La langue reste locale même si la sauvegarde échoue.
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AyanaLogo(mark: true, height: 44),
              const SizedBox(height: 20),
              const Text('Choisis ta langue',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                "AYANA peut t'accompagner dans plusieurs langues adaptées à ton contexte.",
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ...availableLanguages.map((lang) {
                final active = lang.code == _selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selected = lang.code),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: active ? AppColors.plumLight : AppColors.surface,
                        border: Border.all(
                          color: active ? AppColors.plum : AppColors.border,
                          width: active ? 1.6 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(lang.flagEmoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(lang.label,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                          ),
                          if (active)
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                gradient: brandGradient(),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  const Icon(Icons.check, size: 15, color: Colors.white),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              GradientButton(
                label: _saving ? 'Enregistrement…' : 'Continuer →',
                onPressed: _continue,
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text('Tes données restent confidentielles',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}