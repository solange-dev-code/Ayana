import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.dangerText.withValues(alpha: 0.4)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🚨 Situation urgente ?',
                    style: TextStyle(
                        color: AppColors.dangerText, fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Text(
                  'Appelle le SAMU : 15 ou contacte un professionnel immédiatement.',
                  style: TextStyle(color: AppColors.dangerText, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('PROFESSIONNELS PARTENAIRES', color: AppColors.textSecondary),
          const SizedBox(height: 12),
          ...professionals.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.role,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary)),
                              Text(p.place,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary, fontSize: 12)),
                              Text(p.distance,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.available
                                ? AppColors.successBg
                                : AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.available ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              color: p.available
                                  ? AppColors.successText
                                  : AppColors.dangerText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      label: p.available
                          ? 'Demander une orientation'
                          : 'Contacter le secrétariat',
                      height: 48,
                      gradient: p.available ? roseGradient() : null,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              p.available
                                  ? 'Orientation demandée auprès de ${p.role}'
                                  : '${p.role} est indisponible pour le moment.',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}