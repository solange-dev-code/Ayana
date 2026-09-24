import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.switchToTab(5),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: AyanaLogo(mark: true, height: 40),
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.switchToTab(1),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: brandGradient(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Pose-moi ta question…',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600)),
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_forward, size: 16, color: AppColors.plum),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('MES PARCOURS'),
            const SizedBox(height: 12),
            ...parcoursList.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.switchToTab(1),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: p.bg,
                        border: Border.all(color: p.accent.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(p.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(p.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p.accent, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            const SectionLabel('ACCÈS RAPIDE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Bibliothèque',
                    subtitle: 'Fiches & ressources',
                    onTap: () => context.switchToTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Professionnels',
                    subtitle: "Trouver de l'aide",
                    onTap: () => context.switchToTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Rappels',
                    subtitle: 'Mes rendez-vous',
                    onTap: () => context.switchToTab(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Discuter',
                    subtitle: 'Avec AYANA',
                    gradient: true,
                    onTap: () => context.switchToTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.sageLight,
              borderColor: AppColors.sage.withValues(alpha: 0.35),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Le saviez-vous ?',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text(
                          "Le cycle menstruel moyen dure entre 21 et 35 jours. "
                          "Des variations sont tout à fait normales !",
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool gradient;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = gradient
        ? BoxDecoration(gradient: brandGradient())
        : BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          );
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: bg.copyWith(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: gradient ? Colors.white : AppColors.textPrimary)),
            Text(subtitle,
                style: TextStyle(
                    color: gradient
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}