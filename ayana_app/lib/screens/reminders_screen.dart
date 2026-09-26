import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: TabHeader(title: 'Mes rappels'),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: brandGradient(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Ajouter',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: brandGradient(),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.plum.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text('Prochain rendez-vous',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                const SizedBox(height: 6),
                const Text('Consultation prénatale',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const Text('15 septembre 2026 • 10h00',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Dans 5 jours',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionLabel('TOUS LES RAPPELS'),
          const SizedBox(height: 12),
          ...reminders.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration:
                              r.done ? TextDecoration.lineThrough : null,
                          color: r.done
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        )),
                    Text(r.subtitle,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: r.tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r.tag,
                          style: TextStyle(color: r.tagColor, fontSize: 11)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}